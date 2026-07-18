#!/usr/bin/env python3
"""Build compact ART23 evidence from the five-resolution 6x27 capture matrix."""

from __future__ import annotations

import csv
import hashlib
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
VALIDATION_ROOT = ROOT / "docs/art/validation/art23"
RAW_ROOT = VALIDATION_ROOT / "final_matrix_raw"
CONTACT_ROOT = VALIDATION_ROOT / "matrix_contact_sheets"
REPRESENTATIVE_ROOT = VALIDATION_ROOT / "screenshots/final_representative"
REPORT_PATH = VALIDATION_ROOT / "long_term_screenshot_matrix.csv"

RESOLUTIONS = [(1280, 720), (1366, 768), (1600, 900), (1920, 1080), (2560, 1440)]
MATRIX = [
    ("goals", ["task", "achievement", "commission_record"]),
    ("codex", ["map", "monster", "collectible", "equipment", "consumable", "event", "rule", "lore"]),
    ("research", ["unlock_interface", "research_entry"]),
    ("profile", ["qualification_level", "history", "statistics", "milestone", "title", "badge"]),
    ("gacha", ["pool", "cost", "result_entry"]),
    ("collection_appearance", ["unique_display", "appearance_config", "display_content", "badge_title", "settlement_display"]),
]
REPRESENTATIVES = {
    (1280, 720): ("goals", "task"),
    (1366, 768): ("codex", "lore"),
    (1600, 900): ("research", "unlock_interface"),
    (1920, 1080): ("profile", "statistics"),
    (2560, 1440): ("collection_appearance", "unique_display"),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def entries() -> list[tuple[str, str]]:
    return [(module, secondary) for module, secondaries in MATRIX for secondary in secondaries]


def main() -> int:
    CONTACT_ROOT.mkdir(parents=True, exist_ok=True)
    REPRESENTATIVE_ROOT.mkdir(parents=True, exist_ok=True)
    for old in CONTACT_ROOT.glob("art23_long_term_*_27_page_matrix.png"):
        old.unlink()
    for old in REPRESENTATIVE_ROOT.glob("art23_long_term_*.png"):
        old.unlink()

    rows: list[dict[str, str]] = []
    thumb_size = (256, 144)
    cell_size = (264, 174)
    columns = 5
    page_entries = entries()
    for width, height in RESOLUTIONS:
        resolution = f"{width}x{height}"
        raw_dir = RAW_ROOT / resolution
        sheet_rows = (len(page_entries) + columns - 1) // columns
        sheet = Image.new("RGB", (columns * cell_size[0], sheet_rows * cell_size[1]), (12, 15, 15))
        draw = ImageDraw.Draw(sheet)
        for index, (module, secondary) in enumerate(page_entries):
            source = raw_dir / f"{module}__{secondary}__{resolution}.png"
            if not source.is_file():
                raise FileNotFoundError(source)
            with Image.open(source) as opened:
                image = opened.convert("RGB")
            if image.size != (width, height):
                raise ValueError(f"dimension mismatch: {source} -> {image.size}")
            column = index % columns
            row = index // columns
            x = column * cell_size[0] + 4
            y = row * cell_size[1] + 24
            thumb = ImageOps.fit(image, thumb_size, Image.Resampling.LANCZOS)
            sheet.paste(thumb, (x, y))
            draw.text((x, y - 18), f"{module}/{secondary}", fill=(219, 202, 154))

            retained = "contact_sheet"
            if REPRESENTATIVES[(width, height)] == (module, secondary):
                retained = "full_resolution_representative+contact_sheet"
                output = REPRESENTATIVE_ROOT / f"art23_long_term_{resolution}_{module}__{secondary}__{resolution}.png"
                image.save(output, "PNG", optimize=True)
            rows.append({
                "resolution": resolution,
                "module": module,
                "secondary": secondary,
                "width": str(width),
                "height": str(height),
                "captured_sha256": sha256(source),
                "retained_as": retained,
            })
        contact = CONTACT_ROOT / f"art23_long_term_{resolution}_27_page_matrix.png"
        sheet.save(contact, "PNG", optimize=True)

    with REPORT_PATH.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)
    if len(rows) != 135:
        raise RuntimeError(f"expected 135 rows, got {len(rows)}")
    print(f"ART23_SCREENSHOT_EVIDENCE=PASS rows={len(rows)} contacts=5 representatives=5")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
