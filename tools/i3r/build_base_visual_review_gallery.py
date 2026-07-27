#!/usr/bin/env python3
"""Render auditable contact sheets for unresolved Base/runtime visual matches.

This tool is deliberately read-only with respect to production assets and the
immutable ``sources/base`` tree.  It consumes the generated runtime crosswalk
and writes review-only PNG/CSV/JSON evidence beneath a caller supplied output
directory (normally ``.tmp/i3r/base_visual_review``).
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
from collections import Counter
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


PENDING_DECISION = "existing_stage_evidence_visual_review_pending"
REVIEWED_DECISION_PREFIX = "visual_reviewed_"
DEFAULT_CROSSWALK = "docs/00_governance/I3R_BASE_RUNTIME_CROSSWALK.csv"
CELL_WIDTH = 384
CELL_HEIGHT = 260
IMAGE_RECT = (18, 18, 366, 188)
ROWS_PER_PAGE = 4
COLUMNS_PER_PAGE = 4
ENTRIES_PER_PAGE = ROWS_PER_PAGE * COLUMNS_PER_PAGE


def repo_root(explicit: str | None) -> Path:
    cwd = Path(explicit).resolve() if explicit else Path.cwd()
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    )
    resolved = Path(result.stdout.strip()).resolve()
    if explicit and resolved != cwd:
        raise RuntimeError(f"--repo-root is not the active worktree: {cwd} != {resolved}")
    return resolved


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def load_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as stream:
        return [
            row
            for row in csv.DictReader(stream)
            if (
                row.get("crosswalk_decision") == PENDING_DECISION
                or row.get("crosswalk_decision", "").startswith(
                    REVIEWED_DECISION_PREFIX
                )
            )
        ]


def checkerboard(width: int, height: int, tile: int = 12) -> Image.Image:
    image = Image.new("RGB", (width, height), "#22262b")
    draw = ImageDraw.Draw(image)
    colors = ("#30363d", "#454c55")
    for y in range(0, height, tile):
        for x in range(0, width, tile):
            draw.rectangle(
                (x, y, min(x + tile - 1, width - 1), min(y + tile - 1, height - 1)),
                fill=colors[(x // tile + y // tile) % 2],
            )
    return image


def fit_nearest(source: Image.Image, width: int, height: int) -> Image.Image:
    if source.width <= 0 or source.height <= 0:
        raise RuntimeError("image has zero extent")
    scale = min(width / source.width, height / source.height)
    target = (
        max(1, int(round(source.width * scale))),
        max(1, int(round(source.height * scale))),
    )
    return source.resize(target, Image.Resampling.NEAREST)


def clipped(value: str, length: int) -> str:
    return value if len(value) <= length else value[: length - 3] + "..."


def write_index(path: Path, rows: list[dict[str, object]]) -> None:
    fields = [
        "review_index",
        "page",
        "cell",
        "asset_id",
        "runtime_path",
        "runtime_sha256",
        "base_source_member",
        "width",
        "height",
        "mode",
        "alpha_coverage",
        "content_bbox",
        "consumer",
        "review_status",
        "review_note",
    ]
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def render(root: Path, output: Path) -> dict[str, object]:
    crosswalk = root / DEFAULT_CROSSWALK
    rows = load_rows(crosswalk)
    output.mkdir(parents=True, exist_ok=True)
    font = ImageFont.load_default()
    index_rows: list[dict[str, object]] = []
    page_count = (len(rows) + ENTRIES_PER_PAGE - 1) // ENTRIES_PER_PAGE
    for page_index in range(page_count):
        page = Image.new(
            "RGB",
            (CELL_WIDTH * COLUMNS_PER_PAGE, CELL_HEIGHT * ROWS_PER_PAGE),
            "#101317",
        )
        page_draw = ImageDraw.Draw(page)
        page_rows = rows[
            page_index * ENTRIES_PER_PAGE : (page_index + 1) * ENTRIES_PER_PAGE
        ]
        for cell_index, row in enumerate(page_rows):
            column = cell_index % COLUMNS_PER_PAGE
            row_index = cell_index // COLUMNS_PER_PAGE
            origin_x = column * CELL_WIDTH
            origin_y = row_index * CELL_HEIGHT
            page_draw.rectangle(
                (
                    origin_x + 4,
                    origin_y + 4,
                    origin_x + CELL_WIDTH - 5,
                    origin_y + CELL_HEIGHT - 5,
                ),
                outline="#6b7785",
                width=2,
            )
            runtime_path = root / row["runtime_path"]
            if not runtime_path.is_file():
                raise RuntimeError(f"runtime image is missing: {runtime_path}")
            actual_sha = sha256(runtime_path)
            if actual_sha != row["runtime_sha256"]:
                raise RuntimeError(
                    f"runtime SHA drift: {row['runtime_path']} {actual_sha} != {row['runtime_sha256']}"
                )
            with Image.open(runtime_path) as opened:
                source = opened.convert("RGBA")
            image_left, image_top, image_right, image_bottom = IMAGE_RECT
            image_width = image_right - image_left
            image_height = image_bottom - image_top
            background = checkerboard(image_width, image_height)
            scaled = fit_nearest(source, image_width - 12, image_height - 12)
            paste_x = (image_width - scaled.width) // 2
            paste_y = (image_height - scaled.height) // 2
            background.paste(scaled, (paste_x, paste_y), scaled)
            page.paste(background, (origin_x + image_left, origin_y + image_top))
            alpha = source.getchannel("A")
            alpha_nonzero = sum(alpha.histogram()[1:])
            alpha_coverage = alpha_nonzero / float(max(1, source.width * source.height))
            bbox = alpha.getbbox()
            text_lines = [
                f"{page_index * ENTRIES_PER_PAGE + cell_index + 1:03d}  {clipped(row['asset_id'], 48)}",
                f"{source.width}x{source.height} {source.mode} alpha={alpha_coverage:.3f}",
                clipped(Path(row["base_source_member"]).name, 54),
                clipped(row["declared_consumer"], 54),
            ]
            for line_index, line in enumerate(text_lines):
                page_draw.text(
                    (origin_x + 18, origin_y + 194 + line_index * 15),
                    line,
                    fill="#edf1f4" if line_index == 0 else "#b7c1ca",
                    font=font,
                )
            index_rows.append(
                {
                    "review_index": page_index * ENTRIES_PER_PAGE + cell_index + 1,
                    "page": page_index + 1,
                    "cell": cell_index + 1,
                    "asset_id": row["asset_id"],
                    "runtime_path": row["runtime_path"],
                    "runtime_sha256": row["runtime_sha256"],
                    "base_source_member": row["base_source_member"],
                    "width": source.width,
                    "height": source.height,
                    "mode": source.mode,
                    "alpha_coverage": f"{alpha_coverage:.6f}",
                    "content_bbox": "" if bbox is None else ",".join(map(str, bbox)),
                    "consumer": row["declared_consumer"],
                    "review_status": row["crosswalk_decision"],
                    "review_note": row["decision_note"],
                }
            )
        page_path = output / f"i3r_base_visual_review_{page_index + 1:02d}.png"
        page.save(page_path)
    index_path = output / "i3r_base_visual_review_index.csv"
    write_index(index_path, index_rows)
    decision_counts = Counter(
        row["review_status"] for row in index_rows
    )
    summary = {
        "schema": "i3r_base_visual_review_v1",
        "source_crosswalk": DEFAULT_CROSSWALK,
        "source_crosswalk_sha256": sha256(crosswalk),
        "pending_decision": PENDING_DECISION,
        "decision_counts": dict(sorted(decision_counts.items())),
        "entry_count": len(index_rows),
        "page_count": page_count,
        "entries_per_page": ENTRIES_PER_PAGE,
        "index": str(index_path),
        "pages": [
            str(output / f"i3r_base_visual_review_{index + 1:02d}.png")
            for index in range(page_count)
        ],
    }
    summary_path = output / "i3r_base_visual_review_summary.json"
    summary_path.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return summary


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root")
    parser.add_argument("--output", default=".tmp/i3r/base_visual_review")
    args = parser.parse_args()
    root = repo_root(args.repo_root)
    output = Path(args.output)
    if not output.is_absolute():
        output = root / output
    summary = render(root, output.resolve())
    print(
        "I3R_BASE_VISUAL_GALLERY=PASS "
        f"entries={summary['entry_count']} pages={summary['page_count']} "
        f"output={Path(summary['index']).parent}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
