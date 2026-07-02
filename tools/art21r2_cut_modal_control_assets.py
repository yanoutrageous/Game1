#!/usr/bin/env python3
"""Cut ART21R2 modal row/button assets from Zujian3 candidates."""

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
    SOURCE_SHEET,
    clean_magenta_to_alpha,
    image_stats,
    png_bytes,
    rel,
    sha256_bytes,
    sha256_file,
    trim_to_alpha,
    write_png_if_same_or_missing,
)


CANDIDATE_ROOT = GAME_ROOT / "sources" / "draw" / "10_working" / "candidates" / "Zujian3"
ART_ROOT = GAME_ROOT / "sources" / "art" / "ART-21R2"
MANIFEST_ROOT = ART_ROOT / "_manifest"
CUT_ROOT = ART_ROOT / "03_cut_output" / "modal_controls"
RUNTIME_ROOT = REPO_ROOT / "Godot" / "GraytailGodot" / "assets" / "ui" / "art21r2" / "modal"


STAGING_FIELDS = [
    "staging_id",
    "asset_id",
    "visual_key",
    "role",
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
    "asset_id",
    "visual_key",
    "role",
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
class ControlCut:
    role: str
    asset_id: str
    visual_key: str
    candidate_name: str
    output_name: str
    texture_margin: int
    content_margin: int

    @property
    def cut_id(self) -> str:
        return f"art21r2_modal_control_{self.role}"

    @property
    def candidate_path(self) -> Path:
        return CANDIDATE_ROOT / self.candidate_name


CONTROL_CUTS = [
    ControlCut(
        "item_row_normal",
        "ui.art21r2.modal.item_row.normal",
        "art21r2.modal.item_row.normal",
        "Zujian3_candidate_005.png",
        "ui_art21r2_modal_item_row_normal.png",
        18,
        10,
    ),
    ControlCut(
        "button_primary",
        "ui.art21r2.modal.button.primary",
        "art21r2.modal.button.primary",
        "Zujian3_candidate_005.png",
        "ui_art21r2_modal_button_primary.png",
        18,
        8,
    ),
    ControlCut(
        "button_secondary",
        "ui.art21r2.modal.button.secondary",
        "art21r2.modal.button.secondary",
        "Zujian3_candidate_005.png",
        "ui_art21r2_modal_button_secondary.png",
        18,
        8,
    ),
    ControlCut(
        "button_danger",
        "ui.art21r2.modal.button.danger",
        "art21r2.modal.button.danger",
        "Zujian3_candidate_008.png",
        "ui_art21r2_modal_button_danger.png",
        18,
        8,
    ),
]


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def cut_control_image(path: Path) -> tuple[Image.Image, dict[str, object], dict[str, object]]:
    source = Image.open(path).convert("RGBA")
    before = image_stats(source)
    cleaned = trim_to_alpha(clean_magenta_to_alpha(source))
    after = image_stats(cleaned)
    return cleaned, before, after


def build_rows(write_runtime: bool, force: bool) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]], dict[str, object]]:
    if not SOURCE_SHEET.exists():
        raise FileNotFoundError(SOURCE_SHEET)
    source_sha = sha256_file(SOURCE_SHEET)
    staging_rows: list[dict[str, object]] = []
    plan_rows: list[dict[str, object]] = []
    cut_rows: list[dict[str, object]] = []
    summary_rows: list[dict[str, object]] = []

    for item in CONTROL_CUTS:
        candidate_path = item.candidate_path
        if not candidate_path.exists():
            raise FileNotFoundError(candidate_path)
        candidate_sha = sha256_file(candidate_path)
        with Image.open(candidate_path) as candidate_source:
            candidate_width, candidate_height = candidate_source.size
        cleaned, before_stats, after_stats = cut_control_image(candidate_path)
        alpha_bounds = cleaned.getchannel("A").getbbox()
        alpha_bounds_text = "" if alpha_bounds is None else ",".join(str(value) for value in alpha_bounds)
        data = png_bytes(cleaned)
        cut_sha = sha256_bytes(data)
        output_path = CUT_ROOT / item.output_name
        runtime_path = RUNTIME_ROOT / item.output_name

        staging_rows.append(
            {
                "staging_id": item.cut_id,
                "asset_id": item.asset_id,
                "visual_key": item.visual_key,
                "role": item.role,
                "source_path": str(SOURCE_SHEET),
                "source_relative_path": rel(SOURCE_SHEET),
                "source_candidate_path": str(candidate_path),
                "source_candidate_relative_path": rel(candidate_path),
                "source_sha256": source_sha,
                "candidate_sha256": candidate_sha,
                "candidate_width": candidate_width,
                "candidate_height": candidate_height,
                **before_stats,
                "source_status": "draw_candidate_requires_cleanup",
                "allowed_next_action": "dry_run_then_write_runtime",
                "reason": "Zujian3 modal control candidate requires purple-fringe cleanup before runtime import.",
            }
        )

        row = {
            "cut_id": item.cut_id,
            "asset_id": item.asset_id,
            "visual_key": item.visual_key,
            "role": item.role,
            "source_candidate_relative_path": rel(candidate_path),
            "crop_rect": f"0,0,{candidate_width},{candidate_height}",
            "output_relative_path": rel(output_path),
            "runtime_relative_path": rel(runtime_path),
            "stretch_or_9slice": "9slice",
            "texture_margin": item.texture_margin,
            "content_margin": item.content_margin,
            "magenta_cleanup_rule": "shared ART21R2 purple/fringe alpha cleanup; trim alpha bbox with 2px padding",
            "source_sha256": source_sha,
            "candidate_sha256": candidate_sha,
            "purple_like_before": before_stats["purple_like_pixels"],
            "purple_like_after": after_stats["purple_like_pixels"],
            "alpha_bounds": alpha_bounds_text,
            "output_width": cleaned.size[0],
            "output_height": cleaned.size[1],
            "status": "ready_for_runtime_write" if write_runtime else "dry_run_only",
            "note": "Draw-sliced modal control surface; does not claim final modal composition.",
        }
        plan_rows.append(row)

        cut_row = dict(row)
        cut_row.update(
            {
                "cut_sha256": cut_sha,
                "runtime_sha256": "",
                "cut_write_status": "not_requested",
                "runtime_write_status": "not_requested",
            }
        )
        if write_runtime:
            written_cut_sha, cut_status = write_png_if_same_or_missing(output_path, data, force)
            written_runtime_sha, runtime_status = write_png_if_same_or_missing(runtime_path, data, force)
            cut_row.update(
                {
                    "cut_sha256": written_cut_sha,
                    "runtime_sha256": written_runtime_sha,
                    "cut_write_status": cut_status,
                    "runtime_write_status": runtime_status,
                    "status": "runtime_written",
                }
            )
        cut_rows.append(cut_row)
        summary_rows.append(
            {
                "asset_id": item.asset_id,
                "candidate": item.candidate_name,
                "cut_sha256": cut_sha,
                "purple_like_before": before_stats["purple_like_pixels"],
                "purple_like_after": after_stats["purple_like_pixels"],
                "output_size": f"{cleaned.size[0]}x{cleaned.size[1]}",
            }
        )

    summary = {
        "source_sheet": str(SOURCE_SHEET),
        "rows": len(CONTROL_CUTS),
        "write_runtime": write_runtime,
        "force": force,
        "result": "runtime_written" if write_runtime else "dry_run_only",
        "controls": summary_rows,
    }
    return staging_rows, plan_rows, cut_rows, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-runtime", action="store_true", help="Write cut PNGs and Godot runtime PNGs.")
    parser.add_argument("--force", action="store_true", help="Overwrite PNGs produced by this tool when the cleaned output hash changes.")
    args = parser.parse_args()

    staging_rows, plan_rows, cut_rows, summary = build_rows(args.write_runtime, args.force)
    write_csv(MANIFEST_ROOT / "modal_control_staging_manifest.csv", staging_rows, STAGING_FIELDS)
    write_csv(MANIFEST_ROOT / "modal_control_cut_dry_run_plan.csv", plan_rows, PLAN_FIELDS)
    write_csv(MANIFEST_ROOT / "modal_control_cut_manifest.csv", cut_rows, CUT_FIELDS)
    summary_path = MANIFEST_ROOT / "modal_control_cut_summary.json"
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
