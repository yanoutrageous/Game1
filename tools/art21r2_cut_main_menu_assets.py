#!/usr/bin/env python3
"""Cut ART21R2 Main Menu board/plank assets from Main.png."""

from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

from art21r2_cut_modal_assets import (
    GAME_ROOT,
    REPO_ROOT,
    image_stats,
    png_bytes,
    rel,
    sha256_bytes,
    sha256_file,
    write_png_if_same_or_missing,
)


SOURCE_SHEET = GAME_ROOT / "sources" / "draw" / "Main.png"
ART_ROOT = GAME_ROOT / "sources" / "art" / "ART-21R2"
MANIFEST_ROOT = ART_ROOT / "_manifest"
CUT_ROOT = ART_ROOT / "03_cut_output" / "main_menu"
RUNTIME_ROOT = REPO_ROOT / "Godot" / "GraytailGodot" / "assets" / "ui" / "art21r2" / "main_menu"


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
class MainMenuCut:
    slot: str
    asset_id: str
    visual_key: str
    crop_rect: tuple[int, int, int, int]
    output_name: str
    texture_margin: int
    content_margin: int
    note: str
    alpha_polygon: tuple[tuple[int, int], ...] | None = None

    @property
    def cut_id(self) -> str:
        return f"art21r2_main_menu_{self.slot}"


MAIN_MENU_CUTS = [
    MainMenuCut(
        "title_board",
        "ui.art21r2.main_menu.title_board",
        "art21r2.main_menu.title_board",
        (58, 88, 690, 190),
        "ui_art21r2_main_menu_title_board.png",
        0,
        18,
        "Dedicated Main.png title board crop with source-silhouette alpha mask; does not include final title lettering.",
        (
            (0, 42),
            (24, 14),
            (86, 0),
            (180, 8),
            (330, 24),
            (500, 42),
            (640, 58),
            (690, 86),
            (690, 190),
            (0, 190),
        ),
    ),
    MainMenuCut(
        "board_header",
        "ui.art21r2.main_menu.board_header",
        "art21r2.main_menu.board_header",
        (1170, 78, 388, 184),
        "ui_art21r2_main_menu_board_header.png",
        0,
        14,
        "Dedicated Main.png top company-board crop for the main menu header.",
    ),
    MainMenuCut(
        "entry_plank_deploy",
        "ui.art21r2.main_menu.entry_plank.deploy",
        "art21r2.main_menu.entry_plank.deploy",
        (1178, 282, 382, 138),
        "ui_art21r2_main_menu_entry_plank_deploy.png",
        0,
        12,
        "Dedicated Main.png first plank crop for Start Exploration.",
    ),
    MainMenuCut(
        "entry_plank_long_term",
        "ui.art21r2.main_menu.entry_plank.long_term",
        "art21r2.main_menu.entry_plank.long_term",
        (1190, 424, 368, 132),
        "ui_art21r2_main_menu_entry_plank_long_term.png",
        0,
        12,
        "Dedicated Main.png second plank crop for Long Term.",
    ),
    MainMenuCut(
        "entry_plank_settings",
        "ui.art21r2.main_menu.entry_plank.settings",
        "art21r2.main_menu.entry_plank.settings",
        (1208, 562, 348, 132),
        "ui_art21r2_main_menu_entry_plank_settings.png",
        0,
        12,
        "Dedicated Main.png third plank crop for Settings.",
    ),
    MainMenuCut(
        "entry_plank_exit",
        "ui.art21r2.main_menu.entry_plank.exit",
        "art21r2.main_menu.entry_plank.exit",
        (1226, 704, 328, 128),
        "ui_art21r2_main_menu_entry_plank_exit.png",
        0,
        12,
        "Dedicated Main.png fourth plank crop for Exit.",
    ),
]


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def crop_source(source: Image.Image, crop_rect: tuple[int, int, int, int]) -> Image.Image:
    x, y, width, height = crop_rect
    return source.crop((x, y, x + width, y + height)).convert("RGBA")


def apply_alpha_polygon(image: Image.Image, polygon: tuple[tuple[int, int], ...] | None) -> Image.Image:
    if polygon is None:
        return image
    masked = image.copy()
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).polygon(list(polygon), fill=255)
    alpha = masked.getchannel("A")
    masked.putalpha(Image.composite(alpha, Image.new("L", image.size, 0), mask))
    return masked


def build_rows(write_runtime: bool, force: bool) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]], dict[str, object]]:
    if not SOURCE_SHEET.exists():
        raise FileNotFoundError(SOURCE_SHEET)
    source_sha = sha256_file(SOURCE_SHEET)
    source = Image.open(SOURCE_SHEET).convert("RGBA")
    staging_rows: list[dict[str, object]] = []
    plan_rows: list[dict[str, object]] = []
    cut_rows: list[dict[str, object]] = []
    summary_rows: list[dict[str, object]] = []

    for item in MAIN_MENU_CUTS:
        image = apply_alpha_polygon(crop_source(source, item.crop_rect), item.alpha_polygon)
        data = png_bytes(image)
        candidate_sha = sha256_bytes(data)
        before_stats = image_stats(image)
        after_stats = image_stats(image)
        alpha_bounds = image.getchannel("A").getbbox()
        alpha_bounds_text = "" if alpha_bounds is None else ",".join(str(value) for value in alpha_bounds)
        output_path = CUT_ROOT / item.output_name
        runtime_path = RUNTIME_ROOT / item.output_name
        crop_rect_text = ",".join(str(value) for value in item.crop_rect)

        staging_rows.append(
            {
                "staging_id": item.cut_id,
                "screen": "main_menu",
                "slot": item.slot,
                "source_path": str(SOURCE_SHEET),
                "source_relative_path": rel(SOURCE_SHEET),
                "source_candidate_path": str(SOURCE_SHEET),
                "source_candidate_relative_path": rel(SOURCE_SHEET),
                "source_sha256": source_sha,
                "candidate_sha256": candidate_sha,
                "candidate_width": image.size[0],
                "candidate_height": image.size[1],
                **before_stats,
                "source_status": "main_png_no_text_no_magenta_direct_crop",
                "allowed_next_action": "dry_run_then_write_runtime",
                "reason": "Main.png is the approved no-text main-menu background; crop only board/plank regions and keep text/runtime routing separate.",
            }
        )

        row = {
            "cut_id": item.cut_id,
            "screen": "main_menu",
            "slot": item.slot,
            "asset_id": item.asset_id,
            "visual_key": item.visual_key,
            "source_candidate_relative_path": rel(SOURCE_SHEET),
            "crop_rect": crop_rect_text,
            "output_relative_path": rel(output_path),
            "runtime_relative_path": rel(runtime_path),
            "stretch_or_9slice": "direct_texture_crop",
            "texture_margin": item.texture_margin,
            "content_margin": item.content_margin,
            "magenta_cleanup_rule": (
                "none; Main.png has no magenta sheet background; source-silhouette alpha mask removes non-board sky"
                if item.alpha_polygon is not None
                else "none; Main.png has no magenta sheet background and is not purple-cleaned"
            ),
            "source_sha256": source_sha,
            "candidate_sha256": candidate_sha,
            "purple_like_before": before_stats["purple_like_pixels"],
            "purple_like_after": after_stats["purple_like_pixels"],
            "alpha_bounds": alpha_bounds_text,
            "output_width": image.size[0],
            "output_height": image.size[1],
            "status": "ready_for_runtime_write" if write_runtime else "dry_run_only",
            "note": item.note,
        }
        plan_rows.append(row)

        cut_row = dict(row)
        cut_row.update(
            {
                "cut_sha256": sha256_bytes(data),
                "runtime_sha256": "",
                "cut_write_status": "not_requested",
                "runtime_write_status": "not_requested",
            }
        )
        if write_runtime:
            cut_sha, cut_status = write_png_if_same_or_missing(output_path, data, force)
            runtime_sha, runtime_status = write_png_if_same_or_missing(runtime_path, data, force)
            cut_row.update(
                {
                    "cut_sha256": cut_sha,
                    "runtime_sha256": runtime_sha,
                    "cut_write_status": cut_status,
                    "runtime_write_status": runtime_status,
                    "status": "runtime_written",
                }
            )
        cut_rows.append(cut_row)
        summary_rows.append(
            {
                "asset_id": item.asset_id,
                "visual_key": item.visual_key,
                "crop_rect": list(item.crop_rect),
                "cut_sha256": cut_row["cut_sha256"],
                "runtime_sha256": cut_row["runtime_sha256"],
                "purple_like_after": after_stats["purple_like_pixels"],
                "output_size": [image.size[0], image.size[1]],
                "cut_write_status": cut_row["cut_write_status"],
                "runtime_write_status": cut_row["runtime_write_status"],
            }
        )

    summary = {
        "slice": "ART21R2 Slice 9 Main Menu source cut",
        "source_sheet": str(SOURCE_SHEET),
        "source_status": "Main.png no-text background; direct crop source, not generated",
        "write_runtime": write_runtime,
        "count": len(MAIN_MENU_CUTS),
        "rows": summary_rows,
    }
    return staging_rows, plan_rows, cut_rows, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-runtime", action="store_true", help="write cut outputs and Godot runtime PNGs")
    parser.add_argument("--force", action="store_true", help="allow overwriting PNGs with different hashes")
    args = parser.parse_args()

    staging_rows, plan_rows, cut_rows, summary = build_rows(args.write_runtime, args.force)
    write_csv(MANIFEST_ROOT / "main_menu_staging_manifest.csv", staging_rows, STAGING_FIELDS)
    write_csv(MANIFEST_ROOT / "main_menu_cut_dry_run_plan.csv", plan_rows, PLAN_FIELDS)
    if args.write_runtime:
        write_csv(MANIFEST_ROOT / "main_menu_cut_manifest.csv", cut_rows, CUT_FIELDS)
        (MANIFEST_ROOT / "main_menu_cut_summary.json").write_text(
            json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
