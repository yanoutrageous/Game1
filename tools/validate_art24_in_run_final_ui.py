#!/usr/bin/env python3
"""Objective static and matrix gate for the ART24 art-only delivery."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import subprocess
from collections import Counter
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "Godot/GraytailGodot"
VALIDATION = ROOT / "docs/art/validation/art24"
EXPECTED_BRANCH = "art/art24-in-run-final-ui"
PROTECTED_HASHES = {
    "Godot/GraytailGodot/project.godot": "dc7ca7bf717c847f47735624bd6ad82b36ae4b936da186ec716d16422b473d6d",
    "Godot/GraytailGodot/data/assets/asset_manifest.csv": "73c7b2e687d96f1b79235cb6c179996eafadfa0ab567ba3a2cc71f641b3673d4",
    "Godot/GraytailGodot/scripts/core/run/run_scene.gd": "aff0634fc25f445fb3887f900ed68c67e9a42951e9da13be0df81d7719863646",
    "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd": "773f8f2aea6780202e198dc4b04525569a57c6c523a0ba2089bdc0b498d461e5",
    "Godot/GraytailGodot/scripts/ui/run_surface/run_surface_model.gd": "1dfc882f2375fa263ddc7291e0a8b35a9101db98d9ecd06e2246ae46c912fb3a",
    "Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd": "ad3c9da89ae6d47ff702962f9fd38a8313ef072bc4539f5e85d11f1fcd7a7f74",
    "Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd": "3da654cb42843ee2fa47f762a45058a858571d93ff497b54ef76434abf5098cd",
    "Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd": "f3e74eba00cd7c8fc77c374fd4f3e4b1c4f431b0c24f1e888ad7fa1727c2f7a1",
}
RESOLUTIONS = ["1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440"]
FORBIDDEN_SUFFIXES = (".import", ".uid", ".translation")


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as stream:
        return list(csv.DictReader(stream))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-matrix", action="store_true")
    args = parser.parse_args()
    failures: list[str] = []

    branch = subprocess.check_output(["git", "branch", "--show-current"], cwd=ROOT, text=True).strip()
    if branch != EXPECTED_BRANCH:
        failures.append(f"branch={branch!r}, expected={EXPECTED_BRANCH!r}")

    for relative, expected in PROTECTED_HASHES.items():
        path = ROOT / relative
        if not path.is_file():
            failures.append(f"protected_missing={relative}")
        elif digest(path) != expected:
            failures.append(f"protected_hash_changed={relative}")

    global_manifest = (GODOT / "data/assets/asset_manifest.csv").read_text(encoding="utf-8", errors="replace").lower()
    if "art24" in global_manifest:
        failures.append("global_manifest_contains_art24")

    status = subprocess.check_output(["git", "status", "--porcelain=v1", "-uall"], cwd=ROOT, text=True, encoding="utf-8", errors="replace")
    for line in status.splitlines():
        path_text = line[3:].replace("\\", "/")
        if path_text.endswith(FORBIDDEN_SUFFIXES):
            failures.append(f"forbidden_side_effect={path_text}")
        if path_text in PROTECTED_HASHES:
            failures.append(f"protected_status_dirty={path_text}")

    matrix_rows = read_csv(VALIDATION / "art24_acceptance_state_matrix.csv")
    if len(matrix_rows) != 54:
        failures.append(f"state_count={len(matrix_rows)}")
    if len({row["primary_id"] for row in matrix_rows}) != 8:
        failures.append("primary_module_count_mismatch")
    state_ids = [row["secondary_id"] for row in matrix_rows]
    if len(set(state_ids)) != len(state_ids):
        failures.append("duplicate_secondary_state")

    report_rows = read_csv(VALIDATION / "art24_runtime_asset_report.csv")
    if len(report_rows) != 142:
        failures.append(f"runtime_asset_count={len(report_rows)}")
    for field in ("asset_id", "visual_key", "runtime_path"):
        values = [row[field] for row in report_rows]
        duplicates = [value for value, count in Counter(values).items() if count > 1]
        if duplicates:
            failures.append(f"duplicate_{field}={duplicates[:3]}")

    total_decoded = 0
    by_group: Counter[str] = Counter()
    for row in report_rows:
        runtime_path = GODOT / row["runtime_path"].removeprefix("res://")
        if not runtime_path.is_file():
            failures.append(f"runtime_missing={row['runtime_path']}")
            continue
        if digest(runtime_path) != row["sha256"]:
            failures.append(f"runtime_hash_mismatch={row['visual_key']}")
        with Image.open(runtime_path) as image:
            rgba = image.convert("RGBA")
            if (rgba.width, rgba.height) != (int(row["width"]), int(row["height"])):
                failures.append(f"runtime_dimension_mismatch={row['visual_key']}")
            alpha_extrema = rgba.getchannel("A").getextrema()
            if row["role"] not in {"hud_panel", "protocol_panel", "map_overlay", "modal_panel", "item_row", "item_slot", "tooltip", "toast", "result_banner", "keycap", "map_tile"} and alpha_extrema == (255, 255):
                failures.append(f"alpha_missing={row['visual_key']}")
            magenta = sum(1 for red, green, blue, alpha in rgba.get_flattened_data() if alpha > 16 and red > 240 and green < 24 and blue > 240)
            if magenta:
                failures.append(f"magenta_contamination={row['visual_key']}:{magenta}")
        decoded = int(row["decoded_bytes"])
        total_decoded += decoded
        by_group[row["load_group"]] += decoded

    if total_decoded > 32 * 1024 * 1024:
        failures.append(f"decoded_budget={total_decoded}")
    for group, decoded in by_group.items():
        if decoded > 14 * 1024 * 1024:
            failures.append(f"load_group_budget={group}:{decoded}")

    reuse_rows = read_csv(VALIDATION / "art24_reused_asset_report.csv")
    if len(reuse_rows) != 14:
        failures.append(f"reuse_asset_count={len(reuse_rows)}")
    for row in reuse_rows:
        runtime_path = GODOT / row["godot_path"].removeprefix("res://")
        if row["exists"] != "true" or not runtime_path.is_file() or digest(runtime_path) != row["sha256"]:
            failures.append(f"reuse_invalid={row['asset_id']}")

    report_summary = json.loads((VALIDATION / "art24_runtime_asset_report.json").read_text(encoding="utf-8"))
    if report_summary.get("manifest_policy") != "fragment_only_no_global_manifest_edit":
        failures.append("manifest_policy_invalid")

    if args.require_matrix:
        matrix_root = VALIDATION / "matrix/final"
        for resolution in RESOLUTIONS:
            folder = matrix_root / resolution
            expected_names = {state_id.replace(".", "_") + f"__{resolution}.png" for state_id in state_ids}
            actual_names = {path.name for path in folder.glob("*.png")} if folder.is_dir() else set()
            if actual_names != expected_names:
                failures.append(f"matrix_inventory={resolution}:expected54_actual{len(actual_names)}")
                continue
            width, height = (int(value) for value in resolution.split("x"))
            for image_path in folder.glob("*.png"):
                with Image.open(image_path) as image:
                    if image.size != (width, height):
                        failures.append(f"matrix_dimension={resolution}/{image_path.name}:{image.size}")

    if failures:
        for failure in failures:
            print(f"ART24_GATE_ERROR {failure}")
        print(f"ART24_STATIC_VALIDATION=FAIL failures={len(failures)}")
        return 2
    print(f"ART24_STATIC_VALIDATION=PASS assets={len(report_rows)} reused={len(reuse_rows)} states={len(matrix_rows)} decoded_mib={total_decoded / (1024 * 1024):.2f} matrix={'required' if args.require_matrix else 'not_required'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
