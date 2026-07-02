#!/usr/bin/env python3
"""Cut ART21R2 modal panel assets from draw-source UI sheets.

The default mode writes only staging and dry-run manifests. Runtime PNGs are
written only with --write-runtime so the slice path stays reviewable.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[1]
GAME_ROOT = Path(r"D:\AGAME1")
SOURCE_SHEET = GAME_ROOT / "sources" / "draw" / "Zujian3.png"
CANDIDATE_ROOT = GAME_ROOT / "sources" / "draw" / "10_working" / "candidates" / "Zujian3"
SOURCE_CANDIDATE = CANDIDATE_ROOT / "Zujian3_candidate_001.png"
ART_ROOT = GAME_ROOT / "sources" / "art" / "ART-21R2"
MANIFEST_ROOT = ART_ROOT / "_manifest"
CUT_ROOT = ART_ROOT / "03_cut_output" / "modal"
RUNTIME_ROOT = REPO_ROOT / "Godot" / "GraytailGodot" / "assets" / "ui" / "art21r2" / "modal"


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
class ModalCut:
    screen: str
    slot: str
    asset_id: str
    visual_key: str
    output_name: str
    texture_margin: int = 38
    content_margin: int = 30

    @property
    def cut_id(self) -> str:
        return f"art21r2_{self.screen}_{self.slot}"


MODAL_CUTS = [
    ModalCut(
        "inventory",
        "inventory_panel_frame",
        "ui.art21r2.modal.inventory.frame",
        "art21r2.modal.inventory.frame",
        "ui_art21r2_modal_inventory_frame.png",
    ),
    ModalCut(
        "ground_loot",
        "ground_loot_panel_frame",
        "ui.art21r2.modal.ground_loot.frame",
        "art21r2.modal.ground_loot.frame",
        "ui_art21r2_modal_ground_loot_frame.png",
    ),
    ModalCut(
        "result",
        "result_modal_frame",
        "ui.art21r2.modal.result.frame",
        "art21r2.modal.result.frame",
        "ui_art21r2_modal_result_frame.png",
    ),
]


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest().upper()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def rel(path: Path) -> str:
    try:
        return path.resolve(strict=False).relative_to(GAME_ROOT).as_posix()
    except ValueError:
        return path.resolve(strict=False).as_posix()


def write_csv(path: Path, rows: Iterable[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def purple_like(r: int, g: int, b: int, a: int) -> bool:
    if a <= 0:
        return False
    strong_magenta = r >= 170 and b >= 170 and g <= 120
    dark_purple_fringe = r >= 60 and b >= 60 and g <= 110 and r > g * 1.65 and b > g * 1.65 and abs(r - b) <= 95
    return strong_magenta or dark_purple_fringe


def image_stats(image: Image.Image) -> dict[str, object]:
    rgba = image.convert("RGBA")
    data = rgba.tobytes()
    opaque = 0
    purple = 0
    for index in range(0, len(data), 4):
        r, g, b, a = data[index : index + 4]
        if a > 0:
            opaque += 1
            if purple_like(r, g, b, a):
                purple += 1
    return {
        "opaque_pixels": opaque,
        "purple_like_pixels": purple,
        "purple_like_ratio": f"{(purple / max(opaque, 1)):.6f}",
    }


def clean_magenta_to_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    cleaned = bytearray(rgba.tobytes())
    for index in range(0, len(cleaned), 4):
        r, g, b, a = cleaned[index : index + 4]
        if purple_like(r, g, b, a):
            cleaned[index + 3] = 0
    return Image.frombytes("RGBA", rgba.size, bytes(cleaned))


def trim_to_alpha(image: Image.Image, padding: int = 2) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return image
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.size[0], bbox[2] + padding)
    bottom = min(image.size[1], bbox[3] + padding)
    return image.crop((left, top, right, bottom))


def png_bytes(image: Image.Image) -> bytes:
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def write_png_if_same_or_missing(path: Path, data: bytes, force: bool = False) -> tuple[str, str]:
    digest = sha256_bytes(data)
    if path.exists():
        current = sha256_file(path)
        if current != digest and not force:
            raise RuntimeError(f"refusing to overwrite existing PNG with different hash: {path}")
        if current == digest:
            return digest, "already_present_same_hash"
        path.write_bytes(data)
        return digest, "overwritten_by_force"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return digest, "written"


def ensure_required_sources() -> None:
    for path in [SOURCE_SHEET, SOURCE_CANDIDATE]:
        if not path.exists():
            raise FileNotFoundError(path)


def build_rows(write_runtime: bool, force: bool) -> tuple[list[dict[str, object]], list[dict[str, object]], list[dict[str, object]], dict[str, object]]:
    ensure_required_sources()
    source_sha = sha256_file(SOURCE_SHEET)
    candidate_sha = sha256_file(SOURCE_CANDIDATE)
    candidate = Image.open(SOURCE_CANDIDATE).convert("RGBA")
    before_stats = image_stats(candidate)
    cleaned = trim_to_alpha(clean_magenta_to_alpha(candidate))
    after_stats = image_stats(cleaned)
    alpha_bounds = cleaned.getchannel("A").getbbox()
    alpha_bounds_text = "" if alpha_bounds is None else ",".join(str(value) for value in alpha_bounds)
    data = png_bytes(cleaned)
    cut_sha = sha256_bytes(data)

    staging_rows: list[dict[str, object]] = []
    plan_rows: list[dict[str, object]] = []
    cut_rows: list[dict[str, object]] = []
    for item in MODAL_CUTS:
        staging_rows.append(
            {
                "staging_id": item.cut_id,
                "screen": item.screen,
                "slot": item.slot,
                "source_path": str(SOURCE_SHEET),
                "source_relative_path": rel(SOURCE_SHEET),
                "source_candidate_path": str(SOURCE_CANDIDATE),
                "source_candidate_relative_path": rel(SOURCE_CANDIDATE),
                "source_sha256": source_sha,
                "candidate_sha256": candidate_sha,
                "candidate_width": candidate.size[0],
                "candidate_height": candidate.size[1],
                **before_stats,
                "source_status": "draw_candidate_requires_cleanup",
                "allowed_next_action": "dry_run_then_write_runtime",
                "reason": "Zujian3 candidate 001 is a physical modal frame but keeps purple edge pixels until chroma cleanup.",
            }
        )
        output_path = CUT_ROOT / item.output_name
        runtime_path = RUNTIME_ROOT / item.output_name
        row = {
            "cut_id": item.cut_id,
            "screen": item.screen,
            "slot": item.slot,
            "asset_id": item.asset_id,
            "visual_key": item.visual_key,
            "source_candidate_relative_path": rel(SOURCE_CANDIDATE),
            "crop_rect": f"0,0,{candidate.size[0]},{candidate.size[1]}",
            "output_relative_path": rel(output_path),
            "runtime_relative_path": rel(runtime_path),
            "stretch_or_9slice": "9slice",
            "texture_margin": item.texture_margin,
            "content_margin": item.content_margin,
            "magenta_cleanup_rule": "alpha=0 where r>=170,b>=170,g<=120,a>0; trim alpha bbox with 2px padding",
            "source_sha256": source_sha,
            "candidate_sha256": candidate_sha,
            "purple_like_before": before_stats["purple_like_pixels"],
            "purple_like_after": after_stats["purple_like_pixels"],
            "alpha_bounds": alpha_bounds_text,
            "output_width": cleaned.size[0],
            "output_height": cleaned.size[1],
            "status": "ready_for_runtime_write" if write_runtime else "dry_run_only",
            "note": "Shared Zujian3 physical modal frame cleaned for ART21R2 modal family; does not claim row/button completion.",
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

    summary = {
        "source_sheet": str(SOURCE_SHEET),
        "source_candidate": str(SOURCE_CANDIDATE),
        "source_sha256": source_sha,
        "candidate_sha256": candidate_sha,
        "cut_sha256": cut_sha,
        "rows": len(MODAL_CUTS),
        "write_runtime": write_runtime,
        "force": force,
        "purple_like_before": before_stats["purple_like_pixels"],
        "purple_like_after": after_stats["purple_like_pixels"],
        "output_size": f"{cleaned.size[0]}x{cleaned.size[1]}",
        "result": "runtime_written" if write_runtime else "dry_run_only",
    }
    return staging_rows, plan_rows, cut_rows, summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-runtime", action="store_true", help="Write cut PNGs and Godot runtime PNGs.")
    parser.add_argument("--force", action="store_true", help="Overwrite PNGs produced by this tool when the cleaned output hash changes.")
    args = parser.parse_args()

    staging_rows, plan_rows, cut_rows, summary = build_rows(args.write_runtime, args.force)
    write_csv(MANIFEST_ROOT / "modal_staging_manifest.csv", staging_rows, STAGING_FIELDS)
    write_csv(MANIFEST_ROOT / "modal_cut_dry_run_plan.csv", plan_rows, PLAN_FIELDS)
    write_csv(MANIFEST_ROOT / "modal_cut_manifest.csv", cut_rows, CUT_FIELDS)
    summary_path = MANIFEST_ROOT / "modal_cut_summary.json"
    summary_path.parent.mkdir(parents=True, exist_ok=True)
    summary_path.write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
