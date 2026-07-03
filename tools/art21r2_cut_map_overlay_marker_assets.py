#!/usr/bin/env python3
"""Stage ART21R2 Map Overlay marker assets from draw game-ready outputs."""

from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from art21r2_cut_modal_assets import (
    GAME_ROOT,
    REPO_ROOT,
    clean_magenta_to_alpha,
    image_stats,
    png_bytes,
    rel,
    sha256_bytes,
    sha256_file,
    trim_to_alpha,
    write_png_if_same_or_missing,
)


SOURCE_SHEET = GAME_ROOT / "sources" / "draw" / "Zujian2.png"
GAME_READY_ROOT = GAME_ROOT / "sources" / "draw" / "30_game_ready" / "map_icon"
ART_ROOT = GAME_ROOT / "sources" / "art" / "ART-21R2"
MANIFEST_ROOT = ART_ROOT / "_manifest"
CUT_ROOT = ART_ROOT / "03_cut_output" / "map_overlay"
RUNTIME_ROOT = REPO_ROOT / "Godot" / "GraytailGodot" / "assets" / "ui" / "art21r2" / "map_overlay"


STAGING_FIELDS = [
    "staging_id",
    "screen",
    "slot",
    "source_path",
    "source_relative_path",
    "source_candidate_path",
    "source_candidate_relative_path",
    "source_sha256",
    "candidate_sha256",
    "candidate_width",
    "candidate_height",
    "opaque_pixels",
    "purple_like_pixels",
    "purple_like_ratio",
    "source_status",
    "allowed_next_action",
    "reason",
]

PLAN_FIELDS = [
    "cut_id",
    "screen",
    "slot",
    "asset_id",
    "visual_key",
    "source_candidate_relative_path",
    "crop_rect",
    "output_relative_path",
    "runtime_relative_path",
    "stretch_or_9slice",
    "texture_margin",
    "content_margin",
    "magenta_cleanup_rule",
    "source_sha256",
    "candidate_sha256",
    "purple_like_before",
    "purple_like_after",
    "alpha_bounds",
    "output_width",
    "output_height",
    "status",
    "note",
]

CUT_FIELDS = PLAN_FIELDS + [
    "cut_sha256",
    "runtime_sha256",
    "cut_write_status",
    "runtime_write_status",
]


@dataclass(frozen=True)
class MapMarkerCut:
    slot: str
    asset_id: str
    visual_key: str
    role: str
    candidate_name: str
    output_name: str

    @property
    def cut_id(self) -> str:
        return f"art21r2_map_overlay_{self.role}"

    @property
    def candidate_path(self) -> Path:
        return GAME_READY_ROOT / self.candidate_name


MARKER_CUTS = [
    MapMarkerCut(
        "map_marker_event",
        "ui.art21r2.map_overlay.marker.event",
        "art21r2.map_overlay.marker.event",
        "marker_event",
        "map_icon_event.png",
        "ui_art21r2_map_overlay_marker_event.png",
    ),
    MapMarkerCut(
        "map_marker_flag",
        "ui.art21r2.map_overlay.marker.flag",
        "art21r2.map_overlay.marker.flag",
        "marker_flag",
        "map_icon_marker_flag.png",
        "ui_art21r2_map_overlay_marker_flag.png",
    ),
]


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def clean_marker(path: Path) -> tuple[Image.Image, dict[str, object], dict[str, object], str]:
    source = Image.open(path).convert("RGBA")
    before = image_stats(source)
    cleaned = trim_to_alpha(clean_magenta_to_alpha(source))
    after = image_stats(cleaned)
    alpha_bounds = cleaned.getchannel("A").getbbox()
    alpha_bounds_text = "" if alpha_bounds is None else ",".join(str(value) for value in alpha_bounds)
    return cleaned, before, after, alpha_bounds_text


def build_rows(write_runtime: bool, force: bool) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]], dict[str, object]]:
    if not SOURCE_SHEET.exists():
        raise FileNotFoundError(SOURCE_SHEET)
    source_sha = sha256_file(SOURCE_SHEET)
    staging_rows: list[dict[str, object]] = []
    plan_rows: list[dict[str, object]] = []
    cut_rows: list[dict[str, object]] = []
    summary_rows: list[dict[str, object]] = []

    for item in MARKER_CUTS:
        candidate_path = item.candidate_path
        if not candidate_path.exists():
            raise FileNotFoundError(candidate_path)
        candidate_sha = sha256_file(candidate_path)
        with Image.open(candidate_path) as candidate_source:
            candidate_width, candidate_height = candidate_source.size
        cleaned, before_stats, after_stats, alpha_bounds_text = clean_marker(candidate_path)
        data = png_bytes(cleaned)
        cut_sha = sha256_bytes(data)
        output_path = CUT_ROOT / item.output_name
        runtime_path = RUNTIME_ROOT / item.output_name

        staging_rows.append(
            {
                "staging_id": item.cut_id,
                "screen": "map_overlay",
                "slot": item.slot,
                "source_path": str(SOURCE_SHEET),
                "source_relative_path": rel(SOURCE_SHEET),
                "source_candidate_path": str(candidate_path),
                "source_candidate_relative_path": rel(candidate_path),
                "source_sha256": source_sha,
                "candidate_sha256": candidate_sha,
                "candidate_width": candidate_width,
                "candidate_height": candidate_height,
                **before_stats,
                "source_status": "game_ready_draw_output_requires_fringe_cleanup",
                "allowed_next_action": "dry_run_then_write_runtime",
                "reason": "Zujian2 root sheet has purple background; use the selected 30_game_ready transparent map icon and clean purple fringe before runtime import.",
            }
        )

        row = {
            "cut_id": item.cut_id,
            "screen": "map_overlay",
            "slot": item.slot,
            "asset_id": item.asset_id,
            "visual_key": item.visual_key,
            "source_candidate_relative_path": rel(candidate_path),
            "crop_rect": f"0,0,{candidate_width},{candidate_height}",
            "output_relative_path": rel(output_path),
            "runtime_relative_path": rel(runtime_path),
            "stretch_or_9slice": "icon",
            "texture_margin": 0,
            "content_margin": 0,
            "magenta_cleanup_rule": "ART21R2 map marker purple/fringe alpha cleanup; trim alpha bbox with 2px padding",
            "source_sha256": source_sha,
            "candidate_sha256": candidate_sha,
            "purple_like_before": before_stats["purple_like_pixels"],
            "purple_like_after": after_stats["purple_like_pixels"],
            "alpha_bounds": alpha_bounds_text,
            "output_width": cleaned.size[0],
            "output_height": cleaned.size[1],
            "status": "ready_for_runtime_write",
            "note": "Draw game-ready marker cleaned from Zujian2 lineage; does not change map click or flagging logic.",
        }
        plan_rows.append(row)

        if write_runtime:
            output_sha, output_status = write_png_if_same_or_missing(output_path, data, force)
            runtime_sha, runtime_status = write_png_if_same_or_missing(runtime_path, data, force)
            cut_rows.append(
                {
                    **row,
                    "status": "runtime_written",
                    "cut_sha256": output_sha,
                    "runtime_sha256": runtime_sha,
                    "cut_write_status": output_status,
                    "runtime_write_status": runtime_status,
                }
            )
            summary_rows.append(
                {
                    "asset_id": item.asset_id,
                    "visual_key": item.visual_key,
                    "candidate_sha256": candidate_sha,
                    "cut_sha256": output_sha,
                    "runtime_sha256": runtime_sha,
                    "purple_like_before": before_stats["purple_like_pixels"],
                    "purple_like_after": after_stats["purple_like_pixels"],
                    "output_size": [cleaned.size[0], cleaned.size[1]],
                    "cut_write_status": output_status,
                    "runtime_write_status": runtime_status,
                }
            )

    summary = {
        "slice": "ART21R2 Slice 6 Map Overlay marker cut",
        "source_sheet": str(SOURCE_SHEET),
        "source_status": "root sheet has purple background and is not imported directly",
        "write_runtime": write_runtime,
        "rows": summary_rows,
    }
    return staging_rows, plan_rows, cut_rows, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-runtime", action="store_true", help="write cut outputs and Godot runtime PNGs")
    parser.add_argument("--force", action="store_true", help="allow overwriting PNGs with different hashes")
    args = parser.parse_args()

    staging_rows, plan_rows, cut_rows, summary = build_rows(args.write_runtime, args.force)
    write_csv(MANIFEST_ROOT / "map_overlay_marker_staging_manifest.csv", staging_rows, STAGING_FIELDS)
    write_csv(MANIFEST_ROOT / "map_overlay_marker_cut_dry_run_plan.csv", plan_rows, PLAN_FIELDS)
    if args.write_runtime:
        write_csv(MANIFEST_ROOT / "map_overlay_marker_cut_manifest.csv", cut_rows, CUT_FIELDS)
        (MANIFEST_ROOT / "map_overlay_marker_cut_summary.json").write_text(
            json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    print(
        json.dumps(
            {
                "staging_rows": len(staging_rows),
                "plan_rows": len(plan_rows),
                "cut_rows": len(cut_rows),
                "write_runtime": args.write_runtime,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
