"""Bake the approved prototype's VQ12 rectangle layers; never import characters.

Usage: python tools/i4/import_main_menu_environment.py --source <living_v4>
Requires Pillow only for this offline import, not for the game.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

from PIL import Image


def sha(data):
    return hashlib.sha256(data).hexdigest()


def bake(source, output, entry, expected_hash):
    data = source.read_bytes()
    assert data[:4] == b"VQ12" and sha(data) == expected_hash, source
    width, height, count = struct.unpack_from("<III", data, 8)
    assert (width, height) == (entry["width"], entry["height"])
    assert len(data) == 20 + count * 12
    pixels = bytearray(width * height * 4)
    for x, y, w, h, r, g, b, a in struct.iter_unpack("<HHHHBBBB", data[20:]):
        assert w and h and x + w <= width and y + h <= height
        row = bytes((r, g, b, a)) * w
        for py in range(y, y + h):
            start = (py * width + x) * 4
            pixels[start:start + len(row)] = row
    image = Image.frombytes("RGBA", (width, height), bytes(pixels))
    image.save(output, optimize=True)
    assert Image.open(output).convert("RGBA").tobytes() == pixels
    return {"source": source.name, "source_sha256": sha(data),
            "png_sha256": sha(output.read_bytes()), "rgba_sha256": sha(pixels)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    args = parser.parse_args()
    destination = Path(__file__).resolve().parents[2] / "Godot/GraytailGodot/assets/ui/i5/main_menu/environment"
    destination.mkdir(parents=True, exist_ok=True)
    scene = json.loads((args.source / "assets/scene_layers.json").read_text(encoding="utf-8"))
    approved_ids = {"sky", "castle_mountains", "fixed_near_world", "canopy_left", "canopy_right", "foreground_left", "foreground_right"}
    approved_ids.update("cloud_" + suffix for suffix in ("00", "01", "07", "09", "13", "14", "21", "23", "27", "34", "38"))
    assert {entry["id"] for entry in scene["layers"]} == approved_ids
    result = {"version": 1, "source": "living_v4 environment and isolated flag cloth (2026-11-06)",
              "source_scene_sha256": scene["source_sha256"],
              "import": "Exact RGBA reconstruction from VQ12 rectangles; nearest sampling; no character or font imports.", "layers": []}
    for entry in scene["layers"]:
        asset = {key: entry[key] for key in ("id", "width", "height", "x", "y", "z", "kind", "depth")}
        asset["png"] = entry["id"] + ".png"
        asset.update(bake(args.source / "assets" / entry["bin"], destination / asset["png"], entry, entry["sha256"]))
        result["layers"].append(asset)
    flag = json.loads((args.source / "flag_patch/flag_patch.json").read_text(encoding="utf-8"))
    cloth = {key: flag[key] for key in ("width", "height", "x", "y", "z")}
    cloth["png"] = "dungeon_flag_cloth.png"
    cloth.update(bake(args.source / "flag_patch" / flag["bin"], destination / cloth["png"], flag, flag["binary_sha256"]))
    result["flag_cloth"] = cloth
    (destination / "manifest.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Baked {len(result['layers'])} environment layers and isolated flag cloth; exact RGBA roundtrip verified.")


if __name__ == "__main__":
    main()
