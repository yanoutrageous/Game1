#!/usr/bin/env python3
"""Build compact ART22 primary/secondary filter evidence sheets from full captures."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


TAB_FILTERS = {
    "map": [
        "all",
        "map_classic_minesweeper",
        "map_honeycomb_minesweeper",
        "map_special_rule",
        "map_unlocked",
        "map_recommended",
    ],
    "warehouse": [
        "all",
        "warehouse_equipment",
        "warehouse_consumable",
        "warehouse_collectible",
        "warehouse_special",
        "warehouse_status",
    ],
    "claim": [
        "all",
        "claim_purchase",
        "claim_receive",
        "claim_recycle",
        "claim_locked",
        "claim_recommended",
    ],
    "objective": [
        "all",
        "objective_available",
        "objective_commission",
        "objective_map_match",
        "objective_locked",
        "objective_reward",
    ],
    "loadout": [
        "all",
        "loadout_map",
        "loadout_objective",
        "loadout_equipment",
        "loadout_consumable",
        "loadout_special",
        "loadout_bag",
        "loadout_validity",
        "loadout_intent",
        "loadout_permission_interface",
    ],
}


def build_sheet(source_dir: Path, output_dir: Path, tab: str, filters: list[str]) -> Path:
    tile_size = (640, 360)
    label_height = 28
    columns = 2
    rows = (len(filters) + columns - 1) // columns
    sheet = Image.new("RGB", (tile_size[0] * columns, (tile_size[1] + label_height) * rows), "#11171a")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default(size=16)

    for index, filter_id in enumerate(filters):
        source = source_dir / f"{tab}__{filter_id}.png"
        if not source.is_file():
            raise FileNotFoundError(source)
        with Image.open(source) as raw:
            tile = raw.convert("RGB").resize(tile_size, Image.Resampling.LANCZOS)
        column = index % columns
        row = index // columns
        x = column * tile_size[0]
        y = row * (tile_size[1] + label_height)
        sheet.paste(tile, (x, y))
        label = f"{tab} / {filter_id}"
        draw.rectangle((x, y + tile_size[1], x + tile_size[0], y + tile_size[1] + label_height), fill="#172326")
        draw.text((x + 10, y + tile_size[1] + 5), label, font=font, fill="#e5c47d")

    output_dir.mkdir(parents=True, exist_ok=True)
    output = output_dir / f"art22_filter_matrix_{tab}.png"
    sheet.save(output, optimize=True)
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    outputs = [build_sheet(args.source_dir, args.output_dir, tab, filters) for tab, filters in TAB_FILTERS.items()]
    print(f"ART22_FILTER_MATRIX_SHEETS=PASS states={sum(map(len, TAB_FILTERS.values()))} sheets={len(outputs)}")
    for output in outputs:
        print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
