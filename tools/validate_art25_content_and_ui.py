#!/usr/bin/env python3
"""Validate ART25 incremental art, bindings, budgets, and repository hygiene."""

from __future__ import annotations

import csv
import hashlib
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
REPORT_CSV = ROOT / "docs/art/validation/art25/art25_runtime_asset_report.csv"
REPORT_JSON = ROOT / "docs/art/validation/art25/art25_runtime_asset_report.json"
MANIFEST = ROOT / "Godot/GraytailGodot/data/assets/asset_manifest.csv"
ASSET_ROOT = ROOT / "Godot/GraytailGodot/assets/ui/art25/content"
GODOT_ROOT = ROOT / "Godot/GraytailGodot"
ART24_FRAGMENT = ROOT / "docs/art/validation/art24/art24_asset_manifest_fragment.csv"
ART10_SKIN = GODOT_ROOT / "scripts/presentation/art10_ui_skin_kit.gd"
NOTO_LICENSE = GODOT_ROOT / "assets/licenses/NotoSansCJK-OFL.txt"

PRODUCTION_FONT_ASSET_ID = "ui.art23.long_term.font.body"
QUARANTINED_FONT_ASSET_ID = "ui.font.fusion_pixel"
PRODUCTION_LICENSE_STATUSES = {
    "internal_generated",
    "internal_generated_from_audited_sources",
    "same_project_audited",
    "verified_ofl_1_1",
}
ART25_MONSTER_SOURCES = {
    "slime": "assets/art24/actors/slime/ue_idle.png",
    "slimeling": "assets/art24/actors/slime/ue_slimeling_idle.png",
    "bat": "assets/art24/actors/bat/ue_idle_0.png",
    "drone": "assets/art24/actors/drone/ue_idle_0.png",
}
SEMANTIC_DISTINCT_GROUPS = {
    "long_term_monsters": [
        "ui.art25.long_term.monster.slime",
        "ui.art25.long_term.monster.slimeling",
        "ui.art25.long_term.monster.bat",
        "ui.art25.long_term.monster.drone",
    ],
    "long_term_profiles": [f"ui.art25.long_term.profile.{index}" for index in range(1, 6)],
    "long_term_rules": [
        "ui.art25.long_term.rule.mines_and_movement",
        "ui.art25.long_term.rule.extraction_right",
        "ui.art25.long_term.rule.protocol_pressure",
        "ui.art25.long_term.rule.backpack_and_salvage",
        "ui.art25.long_term.rule.settlement_outcomes",
    ],
}


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def resolve_declared_source(source: str) -> Path | None:
    normalized = source.replace("\\", "/")
    if normalized.startswith("assets/"):
        return GODOT_ROOT / normalized
    if normalized.startswith(("Godot/", "tools/")):
        return ROOT / normalized
    return None


def validate_production_lifecycle(errors: list[str], row: dict[str, str], label: str) -> None:
    if row.get("license_status", "") not in PRODUCTION_LICENSE_STATUSES:
        fail(errors, f"production_license={label}:{row.get('license_status', '')}")
    if row.get("replacement_needed", "").lower() != "false":
        fail(errors, f"production_replacement={label}:{row.get('replacement_needed', '')}")
    source_status = row.get("source_status", "").lower()
    if not source_status or any(token in source_status for token in ("pending", "unknown", "quarantin")):
        fail(errors, f"production_source_status={label}:{source_status}")


def main() -> int:
    errors: list[str] = []
    for required in [REPORT_CSV, REPORT_JSON, MANIFEST, ASSET_ROOT, ART24_FRAGMENT, ART10_SKIN, NOTO_LICENSE]:
        if not required.exists():
            fail(errors, f"missing={required.relative_to(ROOT)}")
    if errors:
        return finish(errors)

    rows = read_csv(REPORT_CSV)
    summary = json.loads(REPORT_JSON.read_text(encoding="utf-8"))
    if len(rows) != 107 or int(summary.get("runtime_assets", 0)) != 107:
        fail(errors, f"runtime_asset_count rows={len(rows)} summary={summary.get('runtime_assets')}")

    ids = [row["asset_id"] for row in rows]
    keys = [row["visual_key"] for row in rows]
    paths = [row["runtime_path"] for row in rows]
    for label, values in [("asset_id", ids), ("visual_key", keys), ("runtime_path", paths)]:
        if len(set(values)) != len(values):
            fail(errors, f"duplicate_{label}")

    decoded_by_group: dict[str, int] = {}
    decoded_total = 0
    for row in rows:
        declared_source = resolve_declared_source(row["source"])
        if declared_source is None:
            fail(errors, f"unsupported_declared_source={row['asset_id']}:{row['source']}")
        elif not declared_source.is_file():
            fail(errors, f"missing_declared_source={row['asset_id']}:{row['source']}")
        if row["role"] == "long_term_monster":
            expected_source = ART25_MONSTER_SOURCES.get(row["state"])
            if row["source"] != expected_source:
                fail(errors, f"monster_source={row['asset_id']}:{row['source']} expected={expected_source}")
        relative = row["runtime_path"].removeprefix("res://")
        path = ROOT / "Godot/GraytailGodot" / relative
        if not path.exists():
            fail(errors, f"missing_runtime_asset={row['runtime_path']}")
            continue
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != row["sha256"]:
            fail(errors, f"sha256={row['asset_id']}")
        with Image.open(path) as image:
            rgba = image.convert("RGBA")
            width, height = rgba.size
            alpha_min, alpha_max = rgba.getchannel("A").getextrema()
        if (width, height) != (int(row["width"]), int(row["height"])):
            fail(errors, f"dimensions={row['asset_id']} actual={width}x{height}")
        decoded = width * height * 4
        if decoded != int(row["decoded_bytes"]):
            fail(errors, f"decoded_bytes={row['asset_id']}")
        if alpha_max == 0 or alpha_min == 255:
            fail(errors, f"alpha_contract={row['asset_id']} min={alpha_min} max={alpha_max}")
        decoded_total += decoded
        group = row["load_group"]
        decoded_by_group[group] = decoded_by_group.get(group, 0) + decoded

    report_by_id = {row["asset_id"]: row for row in rows}
    for group, asset_ids in SEMANTIC_DISTINCT_GROUPS.items():
        missing = [asset_id for asset_id in asset_ids if asset_id not in report_by_id]
        if missing:
            fail(errors, f"semantic_group_missing={group}:{','.join(missing)}")
            continue
        hashes = [report_by_id[asset_id]["sha256"] for asset_id in asset_ids]
        if len(set(hashes)) != len(hashes):
            fail(errors, f"semantic_hash_collision={group}")

    if decoded_total != int(summary.get("total_decoded_bytes", -1)):
        fail(errors, f"decoded_total report={summary.get('total_decoded_bytes')} actual={decoded_total}")
    deploy_total = sum(value for group, value in decoded_by_group.items() if group.startswith("art25_deploy_"))
    long_term_total = sum(value for group, value in decoded_by_group.items() if group.startswith("art25_long_term_"))
    if deploy_total > int(0.75 * 1024 * 1024):
        fail(errors, f"deploy_budget={deploy_total / 1048576:.3f}MiB")
    if long_term_total > int(1.25 * 1024 * 1024):
        fail(errors, f"long_term_budget={long_term_total / 1048576:.3f}MiB")

    role_counts: dict[str, int] = {}
    for row in rows:
        role_counts[row["role"]] = role_counts.get(row["role"], 0) + 1
    expected_roles = {
        "deploy_map_thumbnail": 8,
        "deploy_commission_icon": 6,
        "deploy_shop_icon": 10,
        "long_term_item": 42,
    }
    for role, expected in expected_roles.items():
        if role_counts.get(role, 0) != expected:
            fail(errors, f"role_count={role}:{role_counts.get(role, 0)} expected={expected}")

    all_manifest_rows = read_csv(MANIFEST)
    all_manifest_by_id = {row["asset_id"]: row for row in all_manifest_rows}
    if len(all_manifest_by_id) != len(all_manifest_rows):
        fail(errors, "global_manifest_duplicate_asset_id")

    manifest_rows = [row for row in all_manifest_rows if row["asset_id"].startswith("ui.art25.")]
    manifest_by_id = {row["asset_id"]: row for row in manifest_rows}
    if len(manifest_rows) != 107 or set(manifest_by_id) != set(ids):
        fail(errors, f"manifest_art25_rows={len(manifest_rows)}")
    for row in rows:
        manifest_row = manifest_by_id.get(row["asset_id"])
        if manifest_row is None:
            continue
        if manifest_row["godot_path"] != row["runtime_path"]:
            fail(errors, f"manifest_path={row['asset_id']}")
        if manifest_row["theme_key"] != row["visual_key"]:
            fail(errors, f"manifest_visual_key={row['asset_id']}")
        if row["sha256"] not in manifest_row["note"]:
            fail(errors, f"manifest_hash_note={row['asset_id']}")
        if manifest_row["source_repo_path"] != row["source"]:
            fail(errors, f"manifest_source={row['asset_id']}")
        validate_production_lifecycle(errors, manifest_row, row["asset_id"])

    art24_rows = read_csv(ART24_FRAGMENT)
    art24_ids = [row["asset_id"] for row in art24_rows]
    art24_paths = [row["godot_path"] for row in art24_rows]
    if len(set(art24_ids)) != len(art24_ids):
        fail(errors, "art24_fragment_duplicate_asset_id")
    if len(set(art24_paths)) != len(art24_paths):
        fail(errors, "art24_fragment_duplicate_godot_path")
    missing_art24_manifest = sorted(set(art24_ids) - set(all_manifest_by_id))
    if missing_art24_manifest:
        fail(errors, f"art24_fragment_missing_from_global_manifest={len(missing_art24_manifest)}")
    for row in art24_rows:
        runtime = GODOT_ROOT / row["godot_path"].removeprefix("res://")
        if not runtime.is_file():
            fail(errors, f"art24_runtime_missing={row['asset_id']}")
            continue
        digest = hashlib.sha256(runtime.read_bytes()).hexdigest()
        if digest not in row["note"]:
            fail(errors, f"art24_fragment_hash={row['asset_id']}")
        manifest_row = all_manifest_by_id.get(row["asset_id"])
        if manifest_row is None:
            continue
        for field in row:
            if manifest_row.get(field, "") != row.get(field, ""):
                fail(errors, f"art24_manifest_{field}={row['asset_id']}")
        validate_production_lifecycle(errors, manifest_row, row["asset_id"])

    skin_text = ART10_SKIN.read_text(encoding="utf-8")
    expected_font_declaration = f'const FONT_ASSET_ID := &"{PRODUCTION_FONT_ASSET_ID}"'
    if expected_font_declaration not in skin_text:
        fail(errors, f"production_font_binding={PRODUCTION_FONT_ASSET_ID}")
    production_font = all_manifest_by_id.get(PRODUCTION_FONT_ASSET_ID)
    if production_font is None:
        fail(errors, f"production_font_manifest={PRODUCTION_FONT_ASSET_ID}")
    else:
        validate_production_lifecycle(errors, production_font, PRODUCTION_FONT_ASSET_ID)
        if production_font.get("license_status") != "verified_ofl_1_1":
            fail(errors, f"production_font_license={production_font.get('license_status', '')}")
        if "res://assets/licenses/NotoSansCJK-OFL.txt" not in production_font.get("note", ""):
            fail(errors, "production_font_license_evidence")
        font_runtime = GODOT_ROOT / production_font.get("godot_path", "").removeprefix("res://")
        font_source = resolve_declared_source(production_font.get("source_repo_path", ""))
        if not font_runtime.is_file():
            fail(errors, f"production_font_runtime={production_font.get('godot_path', '')}")
        if font_source is None or not font_source.is_file():
            fail(errors, f"production_font_source={production_font.get('source_repo_path', '')}")
        license_text = NOTO_LICENSE.read_text(encoding="utf-8", errors="replace")
        if "SIL OPEN FONT LICENSE" not in license_text or "Version 1.1" not in license_text:
            fail(errors, "production_font_license_content")
    quarantined_font = all_manifest_by_id.get(QUARANTINED_FONT_ASSET_ID)
    if quarantined_font is None:
        fail(errors, f"quarantined_font_manifest={QUARANTINED_FONT_ASSET_ID}")
    else:
        if quarantined_font.get("replacement_needed", "").lower() != "true":
            fail(errors, "quarantined_font_replacement_needed")
        if "quarantin" not in quarantined_font.get("source_status", "").lower():
            fail(errors, "quarantined_font_source_status")
    fusion_consumers = []
    for script in (GODOT_ROOT / "scripts").rglob("*.gd"):
        script_text = script.read_text(encoding="utf-8", errors="replace")
        if QUARANTINED_FONT_ASSET_ID in script_text or "FusionPixel.otf" in script_text:
            fusion_consumers.append(script.relative_to(ROOT).as_posix())
    if fusion_consumers:
        fail(errors, "quarantined_font_consumers=" + ",".join(fusion_consumers))

    disk_pngs = sorted(ASSET_ROOT.rglob("*.png"))
    if len(disk_pngs) != 107:
        fail(errors, f"disk_png_count={len(disk_pngs)}")

    contract = (ROOT / "Godot/GraytailGodot/scripts/presentation/art25_content_asset_contract.gd").read_text(encoding="utf-8")
    deploy_view = (ROOT / "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_card_view.gd").read_text(encoding="utf-8")
    long_term_shell = (ROOT / "Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd").read_text(encoding="utf-8")
    long_term_card = (ROOT / "Godot/GraytailGodot/scripts/ui/long_term/long_term_content_card_view.gd").read_text(encoding="utf-8")
    for token in ["m7_map_", "m7_shop_", "m7_commission_", "long_term_card_ref", "texture_for_long_term_card"]:
        if token not in contract:
            fail(errors, f"contract_token={token}")
    if "Art25ContentAssetContractScript.deploy_card_ref" not in deploy_view:
        fail(errors, "deploy_binding_missing")
    if "LongTermContentCardViewScript.new()" not in long_term_shell:
        fail(errors, "long_term_component_missing")
    for token in ["ReadableFont", "clip_contents = true", "PRESET_FULL_RECT"]:
        if token not in long_term_card:
            fail(errors, f"long_term_card_contract={token}")

    git = subprocess.run(
        ["git", "status", "--porcelain"], cwd=ROOT, check=True, capture_output=True, text=True, encoding="utf-8"
    ).stdout.splitlines()
    forbidden = [line for line in git if Path(line[3:]).suffix.lower() in {".import", ".uid", ".translation"}]
    if forbidden:
        fail(errors, "generated_sidecars=" + ",".join(line[3:] for line in forbidden))

    return finish(errors, deploy_total, long_term_total)


def finish(errors: list[str], deploy_total: int = 0, long_term_total: int = 0) -> int:
    if errors:
        for error in errors:
            print(f"ART25_CONTENT_UI_ERROR {error}")
        print(f"ART25_CONTENT_UI=FAIL errors={len(errors)}")
        return 2
    print(
        "ART25_CONTENT_UI=PASS "
        f"assets=107 deploy={deploy_total / 1048576:.3f}MiB long_term={long_term_total / 1048576:.3f}MiB "
        "maps=8 commissions=6 shop=10 items=42"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
