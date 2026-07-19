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


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def main() -> int:
    errors: list[str] = []
    for required in [REPORT_CSV, REPORT_JSON, MANIFEST, ASSET_ROOT]:
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

    manifest_rows = [row for row in read_csv(MANIFEST) if row["asset_id"].startswith("ui.art25.")]
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
