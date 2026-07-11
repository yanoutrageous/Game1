#!/usr/bin/env python3
"""ART-20 UI asset cutting dry-run planner.

This tool intentionally defaults to dry-run behavior. It reads the ART-20
staging manifest and ART19R1 cutting/import plans, inspects image metadata, and
writes planning CSV/JSON only. It does not create PNG outputs.
"""

from __future__ import annotations

import argparse
import csv
import fnmatch
import hashlib
import io
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image


DEFAULT_REPO = Path(r"D:\AGAME1\active\Game1_work")
DEFAULT_STAGING_MANIFEST = Path(r"D:\AGAME1\sources\art\ART-20\_manifest\staging_manifest.csv")
DEFAULT_CUTTING_SPEC = DEFAULT_REPO / "docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.csv"
DEFAULT_IMPORT_PLAN = DEFAULT_REPO / "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv"
DEFAULT_PLAN_OUT = DEFAULT_REPO / "docs/art/validation/art20/art20_slice2_cutting_dry_run_plan.csv"
DEFAULT_SUMMARY_OUT = DEFAULT_REPO / "docs/art/validation/art20/art20_slice2_cutting_dry_run_summary.json"
DEFAULT_CUT_OUTPUT_ROOT = Path(r"D:\AGAME1\sources\art\ART-20\03_cut_output")
DEFAULT_CUT_MANIFEST_OUT = Path(r"D:\AGAME1\sources\art\ART-20\_manifest\cut_manifest.csv")
DEFAULT_CUT_BLOCKED_OUT = Path(r"D:\AGAME1\sources\art\ART-20\_manifest\cut_blocked_or_review.csv")
DEFAULT_CUT_SUMMARY_OUT = Path(r"D:\AGAME1\sources\art\ART-20\_manifest\cut_summary.json")
DEFAULT_GALLERY_OUT = DEFAULT_REPO / "docs/art/validation/art20/art20_slice3_component_gallery.md"


BLOCKED_STATUSES = {
    "needs_source_selection",
    "needs_visual_fit_review",
    "reference_only",
    "reject_or_archive",
}


@dataclass(frozen=True)
class StagedAsset:
    staging_id: str
    source_path: Path
    source_relative_path: str
    staged_path: Path
    staged_relative_path: str
    source_sha256: str
    staged_sha256: str
    source_status: str
    allowed_next_action: str
    reason: str


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def sanitize_name(value: str) -> str:
    value = value.strip().lower()
    value = re.sub(r"[^a-z0-9_./-]+", "_", value)
    value = value.replace(".", "_").replace("/", "_").replace("-", "_")
    value = re.sub(r"_+", "_", value).strip("_")
    return value or "unnamed"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def normalize_slashes(value: str) -> str:
    return value.replace("\\", "/").strip()


def candidate_tokens(value: str) -> list[str]:
    tokens: list[str] = []
    for part in re.split(r"[;\n]", value or ""):
        part = part.strip()
        if not part:
            continue
        for match in re.findall(r"sources/(?:draw|art)/[^\s,;]+", normalize_slashes(part)):
            tokens.append(match.strip(" ,;"))
        if not part.startswith("sources/"):
            for match in re.findall(r"[\w./*-]+\.png", normalize_slashes(part)):
                tokens.append(match.strip(" ,;"))
    return list(dict.fromkeys(tokens))


def build_staged_assets(rows: Iterable[dict[str, str]]) -> list[StagedAsset]:
    assets: list[StagedAsset] = []
    for row in rows:
        assets.append(
            StagedAsset(
                staging_id=row.get("staging_id", ""),
                source_path=Path(row.get("source_path", "")),
                source_relative_path=normalize_slashes(row.get("source_relative_path", "")),
                staged_path=Path(row.get("staged_path", "")),
                staged_relative_path=normalize_slashes(row.get("staged_relative_path", "")),
                source_sha256=(row.get("source_sha256", "") or "").upper(),
                staged_sha256=(row.get("staged_sha256", "") or "").upper(),
                source_status=row.get("source_status", ""),
                allowed_next_action=row.get("allowed_next_action", ""),
                reason=row.get("reason", ""),
            )
        )
    return assets


def matches_token(asset: StagedAsset, token: str) -> bool:
    token = normalize_slashes(token)
    rel = asset.source_relative_path
    base = Path(rel).name
    if token.startswith("sources/"):
        return fnmatch.fnmatch(rel, token)
    if "/" in token:
        return fnmatch.fnmatch(rel, f"sources/draw/30_game_ready/{token}")
    return fnmatch.fnmatch(base, token)


def match_assets(assets: list[StagedAsset], candidate: str) -> list[StagedAsset]:
    tokens = candidate_tokens(candidate)
    matched: list[StagedAsset] = []
    for asset in assets:
        if any(matches_token(asset, token) for token in tokens):
            matched.append(asset)
    return sorted({asset.source_relative_path: asset for asset in matched}.values(), key=lambda item: item.source_relative_path)


def import_plan_matches(asset: StagedAsset, plan_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    matched: list[dict[str, str]] = []
    for row in plan_rows:
        if row.get("priority") != "P0":
            continue
        if any(matches_token(asset, token) for token in candidate_tokens(row.get("source_candidate", ""))):
            matched.append(row)
    return matched


def extract_output_size(value: str) -> tuple[str, str, str]:
    matches = re.findall(r"(\d+)\s*x\s*(\d+)", value or "")
    if not matches:
        return "", "", ""
    width, height = matches[-1]
    return width, height, f"{width}x{height}"


def parse_rect(value: str) -> tuple[int, int, int, int] | None:
    parts = [part.strip() for part in (value or "").split(",")]
    if len(parts) != 4:
        return None
    try:
        x0, y0, x1, y1 = [int(part) for part in parts]
    except ValueError:
        return None
    if x1 <= x0 or y1 <= y0:
        return None
    return x0, y0, x1, y1


def infer_output_filename(row: dict[str, object]) -> str:
    page = sanitize_name(str(row.get("page", "")))
    component = sanitize_name(str(row.get("component_id", "")))
    source = sanitize_name(Path(str(row.get("source_relative_path", ""))).stem)

    if component == "ui_tab_selected_generic":
        return "ui_shared_tab_primary_selected.png"
    if component == "ui_keycap_prompt_set":
        key_name = source.replace("ui_key_", "")
        return f"ui_shared_keycap_{key_name}_normal.png"
    if component in {"deploy_primary_tab_row", "longterm_top_switch_tabs"}:
        source_clean = source
        source_clean = source_clean.replace("ui_button_nav_", "")
        source_clean = source_clean.replace("talent_selected", "selected")
        return f"ui_{page}_tab_primary_{source_clean}.png"
    if component in {
        "deploy_equipment_slot",
        "main_menu_entry_button_large",
        "run_bottom_key_bar_button",
        "longterm_collection_card",
        "longterm_right_archive_modules",
        "run_left_info_rail_frame",
    }:
        return f"{component}_{source}.png"
    target = str(row.get("target_runtime_path_candidate", "") or "")
    if target and "|" not in target:
        basename = target.rsplit("/", 1)[-1]
        if basename.endswith(".png"):
            return sanitize_name(basename[:-4]) + ".png"
    return f"{component}_{source}.png"


def png_bytes_for_cut(staged_path: Path, rect: tuple[int, int, int, int], output_size: str, nine_slice: str) -> tuple[bytes, int, int]:
    with Image.open(staged_path) as image:
        rgba = image.convert("RGBA")
        crop = rgba.crop(rect)
        if nine_slice.lower() != "yes" and output_size:
            width, height = [int(value) for value in output_size.split("x", 1)]
            crop = crop.resize((width, height), Image.Resampling.LANCZOS)
        buffer = io.BytesIO()
        crop.save(buffer, format="PNG")
        data = buffer.getvalue()
        return data, crop.size[0], crop.size[1]


def write_png_if_safe(path: Path, data: bytes) -> tuple[str, str]:
    digest = hashlib.sha256(data).hexdigest().upper()
    if path.exists():
        current = sha256_file(path)
        if current != digest:
            raise RuntimeError(f"refusing to overwrite existing output with different hash: {path}")
        return digest, "already_present_same_hash"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return digest, "written"


def ensure_within_root(path: Path, root: Path) -> Path:
    resolved_root = root.resolve(strict=False)
    resolved_path = path.resolve(strict=False)
    try:
        resolved_path.relative_to(resolved_root)
    except ValueError as exc:
        raise RuntimeError(f"output path escapes cut output root: {resolved_path}") from exc
    return resolved_path


def image_metadata(path: Path) -> dict[str, object]:
    with Image.open(path) as image:
        rgba = image.convert("RGBA")
        width, height = rgba.size
        alpha = rgba.getchannel("A")
        bbox = alpha.getbbox()
        alpha_bounds = "" if bbox is None else f"{bbox[0]},{bbox[1]},{bbox[2]},{bbox[3]}"
        has_alpha = image.mode in {"RGBA", "LA"} or ("transparency" in image.info)
        nontransparent_pixels = 0
        if bbox is not None:
            nontransparent_pixels = sum(1 for value in alpha.tobytes() if value > 0)
        magenta_pixels = 0
        raw_rgba = rgba.tobytes()
        for index in range(0, len(raw_rgba), 4):
            r, g, b, a = raw_rgba[index : index + 4]
            if a > 0 and r >= 240 and g <= 20 and b >= 240:
                magenta_pixels += 1
        return {
            "source_width": width,
            "source_height": height,
            "has_alpha": str(bool(has_alpha)).lower(),
            "alpha_bounds": alpha_bounds,
            "nontransparent_pixels": nontransparent_pixels,
            "magenta_pixels": magenta_pixels,
        }


def dry_run_status(asset: StagedAsset, spec_row: dict[str, str], import_rows: list[dict[str, str]]) -> tuple[str, str]:
    blockers: list[str] = []
    if not asset.source_path.exists():
        blockers.append("source_missing")
    if not asset.staged_path.exists():
        blockers.append("staged_missing")
    if asset.source_sha256 != asset.staged_sha256:
        blockers.append("source_staged_hash_mismatch")
    if asset.source_status in BLOCKED_STATUSES:
        blockers.append(f"blocked_source_status:{asset.source_status}")
    action_values = {asset.allowed_next_action}
    action_values.update(row.get("action", "") for row in import_rows)
    if any("rename" in value or "recut" in value for value in action_values):
        blockers.append("governance_recut_or_rename_required")
    if blockers:
        return "dry_run_governance_review", "|".join(blockers)
    if spec_row.get("nine_slice", "").lower() == "yes":
        return "dry_run_ready_9slice_plan", ""
    return "dry_run_ready_crop_plan", ""


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate ART-20 UI cutting dry-run plan.")
    parser.add_argument("--repo-root", type=Path, default=DEFAULT_REPO)
    parser.add_argument("--staging-manifest", type=Path, default=DEFAULT_STAGING_MANIFEST)
    parser.add_argument("--cutting-spec", type=Path, default=DEFAULT_CUTTING_SPEC)
    parser.add_argument("--import-plan", type=Path, default=DEFAULT_IMPORT_PLAN)
    parser.add_argument("--plan-out", type=Path, default=DEFAULT_PLAN_OUT)
    parser.add_argument("--summary-out", type=Path, default=DEFAULT_SUMMARY_OUT)
    parser.add_argument("--cut-output-root", type=Path, default=DEFAULT_CUT_OUTPUT_ROOT)
    parser.add_argument("--cut-manifest-out", type=Path, default=DEFAULT_CUT_MANIFEST_OUT)
    parser.add_argument("--cut-blocked-out", type=Path, default=DEFAULT_CUT_BLOCKED_OUT)
    parser.add_argument("--cut-summary-out", type=Path, default=DEFAULT_CUT_SUMMARY_OUT)
    parser.add_argument("--gallery-out", type=Path, default=DEFAULT_GALLERY_OUT)
    parser.add_argument("--include-priority", default="P0")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--write-cut-output", action="store_true", default=False)
    args = parser.parse_args()

    staged_assets = build_staged_assets(read_csv(args.staging_manifest))
    spec_rows = [row for row in read_csv(args.cutting_spec) if row.get("priority") == args.include_priority]
    import_rows = [row for row in read_csv(args.import_plan) if row.get("priority") == args.include_priority]

    rows: list[dict[str, object]] = []
    for spec_row in spec_rows:
        matched_assets = match_assets(staged_assets, spec_row.get("source_candidate", ""))
        if not matched_assets:
            rows.append(
                {
                    "dry_run_id": f"art20_dry_{len(rows) + 1:03d}",
                    "page": spec_row.get("page", ""),
                    "component_id": spec_row.get("component_id", ""),
                    "source_match_status": "no_staged_source_match",
                    "source_relative_path": "",
                    "staged_relative_path": "",
                    "source_sha256": "",
                    "staged_sha256": "",
                    "source_width": "",
                    "source_height": "",
                    "has_alpha": "",
                    "alpha_bounds": "",
                    "nontransparent_pixels": "",
                    "magenta_pixels": "",
                    "crop_mode": "blocked_no_source",
                    "crop_rect_preview": "",
                    "output_size_spec": spec_row.get("output_size", ""),
                    "output_size_preview": "",
                    "nine_slice": spec_row.get("nine_slice", ""),
                    "stretchable": spec_row.get("stretchable", ""),
                    "states": spec_row.get("states", ""),
                    "target_godot_dir": spec_row.get("target_godot_dir", ""),
                    "target_runtime_path_candidate": "",
                    "asset_id_candidate": spec_row.get("asset_id_candidate", ""),
                    "visual_key_candidate": spec_row.get("visual_key_candidate", ""),
                    "allowed_next_action": "",
                    "dry_run_status": "blocked_no_staged_source_match",
                    "blockers": "source_not_in_slice1_staging",
                    "notes": spec_row.get("notes", ""),
                }
            )
            continue

        for asset in matched_assets:
            plan_matches = import_plan_matches(asset, import_rows)
            meta = image_metadata(asset.staged_path)
            out_w, out_h, out_size = extract_output_size(spec_row.get("output_size", ""))
            alpha_bounds = str(meta["alpha_bounds"])
            if spec_row.get("nine_slice", "").lower() == "yes":
                crop_mode = "full_source_9slice_preview"
                crop_rect = f"0,0,{meta['source_width']},{meta['source_height']}"
            elif alpha_bounds:
                crop_mode = "transparent_bbox_preview"
                crop_rect = alpha_bounds
            else:
                crop_mode = "full_source_preview"
                crop_rect = f"0,0,{meta['source_width']},{meta['source_height']}"
            status, blockers = dry_run_status(asset, spec_row, plan_matches)
            target_paths = sorted({row.get("target_runtime_path", "") for row in plan_matches if row.get("target_runtime_path", "")})
            asset_ids = sorted({row.get("asset_id", "") for row in plan_matches if row.get("asset_id", "")})
            visual_keys = sorted({row.get("visual_key", "") for row in plan_matches if row.get("visual_key", "")})
            rows.append(
                {
                    "dry_run_id": f"art20_dry_{len(rows) + 1:03d}",
                    "page": spec_row.get("page", ""),
                    "component_id": spec_row.get("component_id", ""),
                    "source_match_status": "matched_staged_source",
                    "source_relative_path": asset.source_relative_path,
                    "staged_relative_path": asset.staged_relative_path,
                    "source_sha256": asset.source_sha256,
                    "staged_sha256": asset.staged_sha256,
                    "source_width": meta["source_width"],
                    "source_height": meta["source_height"],
                    "has_alpha": meta["has_alpha"],
                    "alpha_bounds": alpha_bounds,
                    "nontransparent_pixels": meta["nontransparent_pixels"],
                    "magenta_pixels": meta["magenta_pixels"],
                    "crop_mode": crop_mode,
                    "crop_rect_preview": crop_rect,
                    "output_size_spec": spec_row.get("output_size", ""),
                    "output_size_preview": out_size or f"{out_w}x{out_h}",
                    "nine_slice": spec_row.get("nine_slice", ""),
                    "stretchable": spec_row.get("stretchable", ""),
                    "states": spec_row.get("states", ""),
                    "target_godot_dir": spec_row.get("target_godot_dir", ""),
                    "target_runtime_path_candidate": "|".join(target_paths),
                    "asset_id_candidate": "|".join(asset_ids) or spec_row.get("asset_id_candidate", ""),
                    "visual_key_candidate": "|".join(visual_keys) or spec_row.get("visual_key_candidate", ""),
                    "allowed_next_action": asset.allowed_next_action,
                    "dry_run_status": status,
                    "blockers": blockers,
                    "notes": spec_row.get("notes", ""),
                }
            )

    staged_relatives = {asset.source_relative_path for asset in staged_assets}
    for plan_row in import_rows:
        if plan_row.get("source_status") not in BLOCKED_STATUSES:
            continue
        matched = match_assets(staged_assets, plan_row.get("source_candidate", ""))
        if matched:
            continue
        rows.append(
            {
                "dry_run_id": f"art20_dry_{len(rows) + 1:03d}",
                "page": "unresolved_import_plan",
                "component_id": plan_row.get("item", ""),
                "source_match_status": "excluded_or_not_staged",
                "source_relative_path": "",
                "staged_relative_path": "",
                "source_sha256": "",
                "staged_sha256": "",
                "source_width": "",
                "source_height": "",
                "has_alpha": "",
                "alpha_bounds": "",
                "nontransparent_pixels": "",
                "magenta_pixels": "",
                "crop_mode": "blocked_source_selection",
                "crop_rect_preview": "",
                "output_size_spec": "",
                "output_size_preview": "",
                "nine_slice": "",
                "stretchable": "",
                "states": "",
                "target_godot_dir": "",
                "target_runtime_path_candidate": plan_row.get("target_runtime_path", ""),
                "asset_id_candidate": plan_row.get("asset_id", ""),
                "visual_key_candidate": plan_row.get("visual_key", ""),
                "allowed_next_action": plan_row.get("action", ""),
                "dry_run_status": "blocked_pending_source_selection",
                "blockers": plan_row.get("source_status", ""),
                "notes": plan_row.get("notes", ""),
            }
        )

    fields = [
        "dry_run_id",
        "page",
        "component_id",
        "source_match_status",
        "source_relative_path",
        "staged_relative_path",
        "source_sha256",
        "staged_sha256",
        "source_width",
        "source_height",
        "has_alpha",
        "alpha_bounds",
        "nontransparent_pixels",
        "magenta_pixels",
        "crop_mode",
        "crop_rect_preview",
        "output_size_spec",
        "output_size_preview",
        "nine_slice",
        "stretchable",
        "states",
        "target_godot_dir",
        "target_runtime_path_candidate",
        "asset_id_candidate",
        "visual_key_candidate",
        "allowed_next_action",
        "dry_run_status",
        "blockers",
        "notes",
    ]
    write_csv(args.plan_out, rows, fields)

    summary = {
        "dry_run": True,
        "generated_png_count": 0,
        "staged_asset_count": len(staged_assets),
        "spec_p0_count": len(spec_rows),
        "import_plan_p0_count": len(import_rows),
        "dry_run_plan_rows": len(rows),
        "matched_rows": sum(1 for row in rows if row["source_match_status"] == "matched_staged_source"),
        "blocked_rows": sum(1 for row in rows if str(row["dry_run_status"]).startswith("blocked")),
        "governance_review_rows": sum(1 for row in rows if row["dry_run_status"] == "dry_run_governance_review"),
        "ready_crop_rows": sum(1 for row in rows if row["dry_run_status"] == "dry_run_ready_crop_plan"),
        "ready_9slice_rows": sum(1 for row in rows if row["dry_run_status"] == "dry_run_ready_9slice_plan"),
        "distinct_staged_sources_in_plan": len({row["staged_relative_path"] for row in rows if row.get("staged_relative_path")}),
        "unstaged_slice1_sources": sorted(staged_relatives - {row["source_relative_path"] for row in rows if row.get("source_relative_path")}),
        "plan_out": str(args.plan_out),
        "summary_out": str(args.summary_out),
    }
    args.summary_out.parent.mkdir(parents=True, exist_ok=True)
    args.summary_out.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if args.write_cut_output:
        cut_rows: list[dict[str, object]] = []
        blocked_rows: list[dict[str, object]] = []
        for row in rows:
            status = str(row.get("dry_run_status", ""))
            if status.startswith("blocked"):
                blocked_rows.append(row)
                continue
            if status not in {"dry_run_ready_crop_plan", "dry_run_ready_9slice_plan", "dry_run_governance_review"}:
                blocked_rows.append(row)
                continue
            rect = parse_rect(str(row.get("crop_rect_preview", "")))
            staged_relative = str(row.get("staged_relative_path", ""))
            if rect is None or not staged_relative:
                blocked = dict(row)
                blocked["slice3_blocker"] = "missing_crop_rect_or_staged_path"
                blocked_rows.append(blocked)
                continue
            staged_abs = Path(r"D:\AGAME1") / staged_relative.replace("/", "\\")
            if not staged_abs.exists():
                blocked = dict(row)
                blocked["slice3_blocker"] = "staged_abs_missing"
                blocked_rows.append(blocked)
                continue

            page = sanitize_name(str(row.get("page", "")))
            component = sanitize_name(str(row.get("component_id", "")))
            filename = infer_output_filename(row)
            output_path = ensure_within_root(args.cut_output_root / page / component / filename, args.cut_output_root)
            png_data, width, height = png_bytes_for_cut(
                staged_abs,
                rect,
                str(row.get("output_size_preview", "")),
                str(row.get("nine_slice", "")),
            )
            output_hash, write_status = write_png_if_safe(output_path, png_data)
            cut_rows.append(
                {
                    "cut_id": f"art20_cut_{len(cut_rows) + 1:03d}",
                    "dry_run_id": row.get("dry_run_id", ""),
                    "page": row.get("page", ""),
                    "component_id": row.get("component_id", ""),
                    "source_relative_path": row.get("source_relative_path", ""),
                    "staged_relative_path": staged_relative,
                    "source_sha256": row.get("source_sha256", ""),
                    "staged_sha256": row.get("staged_sha256", ""),
                    "crop_mode": row.get("crop_mode", ""),
                    "crop_rect": row.get("crop_rect_preview", ""),
                    "output_path": str(output_path),
                    "output_relative_path": output_path.relative_to(Path(r"D:\AGAME1")).as_posix(),
                    "output_sha256": output_hash,
                    "width": width,
                    "height": height,
                    "alpha_bounds": row.get("alpha_bounds", ""),
                    "nine_slice": row.get("nine_slice", ""),
                    "nine_slice_margin": "manual_review_required" if str(row.get("nine_slice", "")).lower() == "yes" else "",
                    "states": row.get("states", ""),
                    "asset_id_candidate": row.get("asset_id_candidate", ""),
                    "visual_key_candidate": row.get("visual_key_candidate", ""),
                    "cut_status": "cut_governance_review" if status == "dry_run_governance_review" else "cut_ready_for_review",
                    "write_status": write_status,
                    "notes": row.get("notes", ""),
                }
            )

        cut_fields = [
            "cut_id",
            "dry_run_id",
            "page",
            "component_id",
            "source_relative_path",
            "staged_relative_path",
            "source_sha256",
            "staged_sha256",
            "crop_mode",
            "crop_rect",
            "output_path",
            "output_relative_path",
            "output_sha256",
            "width",
            "height",
            "alpha_bounds",
            "nine_slice",
            "nine_slice_margin",
            "states",
            "asset_id_candidate",
            "visual_key_candidate",
            "cut_status",
            "write_status",
            "notes",
        ]
        write_csv(args.cut_manifest_out, cut_rows, cut_fields)

        blocked_fields = fields + ["slice3_blocker"]
        write_csv(args.cut_blocked_out, blocked_rows, blocked_fields)

        gallery_lines = [
            "# ART-20 Slice 3 Component Gallery",
            "",
            "This gallery references external cut outputs under `D:\\AGAME1\\sources\\art\\ART-20\\03_cut_output`.",
            "",
        ]
        for cut in cut_rows:
            image_path = str(cut["output_path"]).replace("\\", "/")
            gallery_lines.extend(
                [
                    f"## {cut['cut_id']} - {cut['component_id']}",
                    "",
                    f"- page: `{cut['page']}`",
                    f"- status: `{cut['cut_status']}`",
                    f"- size: `{cut['width']}x{cut['height']}`",
                    f"- output: `{cut['output_path']}`",
                    "",
                    f"![{cut['cut_id']}]({image_path})",
                    "",
                ]
            )
        args.gallery_out.parent.mkdir(parents=True, exist_ok=True)
        args.gallery_out.write_text("\n".join(gallery_lines) + "\n", encoding="utf-8")

        cut_summary = {
            "write_cut_output": True,
            "cut_output_root": str(args.cut_output_root),
            "cut_manifest_out": str(args.cut_manifest_out),
            "cut_blocked_out": str(args.cut_blocked_out),
            "gallery_out": str(args.gallery_out),
            "cut_rows": len(cut_rows),
            "blocked_or_skipped_rows": len(blocked_rows),
            "written_rows": sum(1 for row in cut_rows if row["write_status"] == "written"),
            "already_present_same_hash_rows": sum(1 for row in cut_rows if row["write_status"] == "already_present_same_hash"),
            "governance_review_cut_rows": sum(1 for row in cut_rows if row["cut_status"] == "cut_governance_review"),
            "ready_for_review_cut_rows": sum(1 for row in cut_rows if row["cut_status"] == "cut_ready_for_review"),
            "generated_png_count": len(cut_rows),
            "blocked_component_ids": sorted({str(row.get("component_id", "")) for row in blocked_rows if row.get("component_id", "")}),
        }
        args.cut_summary_out.parent.mkdir(parents=True, exist_ok=True)
        args.cut_summary_out.write_text(json.dumps(cut_summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        summary["cut_output"] = cut_summary

    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
