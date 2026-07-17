#!/usr/bin/env python3
"""Build deterministic ART22 Deploy Prep runtime assets from audited sources."""

from __future__ import annotations

import csv
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "docs/art/validation/art22/sources"
RUNTIME_ROOT = ROOT / "Godot/GraytailGodot/assets/ui/art22/deploy_prep"
VALIDATION_ROOT = ROOT / "docs/art/validation/art22"
MANIFEST_PATH = ROOT / "Godot/GraytailGodot/data/assets/asset_manifest.csv"
CONTRACT_PATH = VALIDATION_ROOT / "deploy_prep_runtime_asset_contract.csv"
REPORT_CSV_PATH = VALIDATION_ROOT / "deploy_prep_runtime_asset_report.csv"
REPORT_JSON_PATH = VALIDATION_ROOT / "deploy_prep_runtime_asset_report.json"

MAGENTA = (255, 0, 255)


@dataclass(frozen=True)
class RuntimeAsset:
    visual_key: str
    relative_path: str
    image: Image.Image
    source_name: str
    source_rect: str
    runtime_rect: str
    layer: str
    slot: str
    state: str
    load_group: str
    default_load: bool
    source_status: str = "art22_generated_audited"

    @property
    def asset_id(self) -> str:
        return f"ui.art22.{self.visual_key}"

    @property
    def godot_path(self) -> str:
        return f"res://assets/ui/art22/deploy_prep/{self.relative_path}"


def open_source(name: str) -> Image.Image:
    path = SOURCE_ROOT / name
    if not path.is_file():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def chroma_alpha(image: Image.Image, threshold: int = 38) -> Image.Image:
    """Remove the exact magenta stage while preserving crisp pixel-art edges."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = pixels[x, y]
            distance = max(abs(r - MAGENTA[0]), abs(g - MAGENTA[1]), abs(b - MAGENTA[2]))
            if distance <= threshold:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (r, g, b, 255)
    bbox = rgba.getbbox()
    if bbox is None:
        raise ValueError("chroma extraction produced an empty image")
    return rgba.crop(bbox)


def trim_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    bbox = rgba.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("alpha extraction produced an empty image")
    return rgba.crop(bbox)


def fit_rgba(image: Image.Image, size: tuple[int, int], padding: int = 0) -> Image.Image:
    target = Image.new("RGBA", size, (0, 0, 0, 0))
    inner = (max(1, size[0] - padding * 2), max(1, size[1] - padding * 2))
    fitted = ImageOps.contain(image.convert("RGBA"), inner, Image.Resampling.LANCZOS)
    target.alpha_composite(fitted, ((size[0] - fitted.width) // 2, (size[1] - fitted.height) // 2))
    return target


def resize_exact(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.convert("RGBA").resize(size, Image.Resampling.LANCZOS)


def nine_slice(image: Image.Image, size: tuple[int, int], border: int) -> Image.Image:
    src = image.convert("RGBA")
    border = min(border, src.width // 3, src.height // 3, size[0] // 3, size[1] // 3)
    dst = Image.new("RGBA", size, (0, 0, 0, 0))
    sx = [0, border, src.width - border, src.width]
    sy = [0, border, src.height - border, src.height]
    dx = [0, border, size[0] - border, size[0]]
    dy = [0, border, size[1] - border, size[1]]
    for row in range(3):
        for col in range(3):
            piece = src.crop((sx[col], sy[row], sx[col + 1], sy[row + 1]))
            width = dx[col + 1] - dx[col]
            height = dy[row + 1] - dy[row]
            if piece.size != (width, height):
                piece = piece.resize((width, height), Image.Resampling.LANCZOS)
            dst.alpha_composite(piece, (dx[col], dy[row]))
    return dst


def parchment_control(parchment: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Build a quiet parchment segment so labels sit inside a stable field."""
    source = trim_alpha(parchment)
    left = source.width // 4
    top = source.height // 4
    patch = source.crop((left, top, source.width - left, source.height - top))
    texture = ImageOps.fit(patch, size, Image.Resampling.LANCZOS)
    mask = Image.new("L", size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((1, 1, size[0] - 2, size[1] - 2), radius=3, fill=238)
    texture.putalpha(mask)
    draw = ImageDraw.Draw(texture)
    draw.rounded_rectangle((1, 1, size[0] - 2, size[1] - 2), radius=3, outline=(91, 61, 32, 255), width=2)
    draw.line((6, 4, size[0] - 7, 4), fill=(239, 210, 152, 150), width=1)
    return texture


def clean_dark_frame(frame_source: Image.Image, size: tuple[int, int], border: int) -> Image.Image:
    """Keep source-made metal edges but replace the noisy center with a text-safe matte."""
    frame = nine_slice(frame_source, size, border)
    result = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(result)
    draw.rounded_rectangle((2, 3, size[0] - 3, size[1] - 4), radius=4, fill=(7, 27, 30, 248), outline=(126, 91, 49, 255), width=2)
    draw.rounded_rectangle((8, 8, size[0] - 9, size[1] - 9), radius=2, outline=(27, 118, 121, 205), width=1)

    edge_mask = Image.new("L", size, 0)
    edge_draw = ImageDraw.Draw(edge_mask)
    edge = max(8, border // 2)
    edge_draw.rectangle((0, 0, size[0], edge), fill=255)
    edge_draw.rectangle((0, size[1] - edge - 1, size[0], size[1]), fill=255)
    edge_draw.rectangle((0, 0, edge, size[1]), fill=255)
    edge_draw.rectangle((size[0] - edge - 1, 0, size[0], size[1]), fill=255)
    edge_draw.rectangle((size[0] // 2 - 32, 0, size[0] // 2 + 32, edge + 2), fill=0)
    edge_draw.rectangle((size[0] // 2 - 32, size[1] - edge - 2, size[0] // 2 + 32, size[1]), fill=0)
    frame.putalpha(ImageChops.multiply(frame.getchannel("A"), edge_mask))
    return Image.alpha_composite(result, frame)


def parchment_state_variant(image: Image.Image, state: str) -> Image.Image:
    if state == "selected":
        selected = color_overlay(ImageEnhance.Brightness(image).enhance(0.78), (0, 69, 70, 205))
        return add_outline(selected, (39, 211, 198, 240), 2)
    return state_variant(image, state)


def color_overlay(image: Image.Image, color: tuple[int, int, int, int]) -> Image.Image:
    rgba = image.convert("RGBA")
    overlay = Image.new("RGBA", rgba.size, color)
    overlay.putalpha(ImageChops.multiply(rgba.getchannel("A"), overlay.getchannel("A")))
    return Image.alpha_composite(rgba, overlay)


def add_outline(image: Image.Image, color: tuple[int, int, int, int], width: int = 3) -> Image.Image:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    expanded = alpha.filter(ImageFilter.MaxFilter(width * 2 + 1))
    outline_alpha = ImageChops.subtract(expanded, alpha)
    outline = Image.new("RGBA", rgba.size, color)
    outline.putalpha(ImageChops.multiply(outline_alpha, Image.new("L", rgba.size, color[3])))
    return Image.alpha_composite(outline, rgba)


def state_variant(image: Image.Image, state: str) -> Image.Image:
    rgba = image.convert("RGBA")
    if state == "normal":
        return rgba
    if state == "focused":
        return add_outline(ImageEnhance.Brightness(rgba).enhance(1.12), (58, 224, 214, 230), 3)
    if state == "pressed":
        return color_overlay(ImageEnhance.Brightness(rgba).enhance(0.82), (116, 64, 18, 42))
    if state == "disabled":
        gray = ImageOps.grayscale(rgba).convert("RGBA")
        gray.putalpha(rgba.getchannel("A").point(lambda value: int(value * 0.56)))
        return color_overlay(gray, (18, 28, 30, 72))
    if state == "selected":
        return add_outline(color_overlay(ImageEnhance.Brightness(rgba).enhance(1.04), (8, 92, 96, 72)), (42, 224, 205, 255), 3)
    if state == "locked":
        gray = ImageOps.grayscale(rgba).convert("RGBA")
        gray.putalpha(rgba.getchannel("A"))
        return color_overlay(ImageEnhance.Brightness(gray).enhance(0.72), (16, 24, 28, 96))
    if state == "warning":
        return add_outline(color_overlay(rgba, (120, 18, 18, 80)), (231, 92, 48, 240), 3)
    raise ValueError(f"unknown state: {state}")


def crop(source: Image.Image, rect: tuple[int, int, int, int], chroma: bool = False) -> Image.Image:
    result = source.crop(rect)
    return chroma_alpha(result) if chroma else result.convert("RGBA")


def build_assets() -> list[RuntimeAsset]:
    background_source = open_source("art22_deploy_background_clean_source.png")
    parchment_source = open_source("art22_parchment_alpha_source.png")
    ui_source = open_source("art22_ui_component_atlas_alpha_source.png")
    route_source = open_source("art22_route_thumbnail_atlas_source.png")
    icon_source = open_source("art22_semantic_icon_atlas_alpha_source.png")

    assets: list[RuntimeAsset] = []

    def add(
        visual_key: str,
        relative_path: str,
        image: Image.Image,
        source_name: str,
        source_rect: str,
        runtime_rect: str,
        layer: str,
        slot: str,
        state: str,
        load_group: str,
        default_load: bool,
    ) -> None:
        assets.append(RuntimeAsset(
            visual_key,
            relative_path,
            image,
            source_name,
            source_rect,
            runtime_rect,
            layer,
            slot,
            state,
            load_group,
            default_load,
        ))

    background = ImageOps.fit(background_source, (1280, 720), Image.Resampling.LANCZOS)
    add(
        "deploy_prep.scene.background.clean_plate",
        "background/scene_clean_plate.png",
        background,
        "art22_deploy_background_clean_source.png",
        "full:1672x941->1280x720",
        "0,0,1280,720",
        "background",
        "clean_plate",
        "normal",
        "deploy_default",
        True,
    )

    parchment_object = trim_alpha(parchment_source)
    parchment = resize_exact(parchment_object, (688, 692))
    add(
        "deploy_prep.panel.parchment",
        "panels/parchment.png",
        parchment,
        "art22_parchment_alpha_source.png",
        "alpha_bbox->688x692",
        "254,14,688,692",
        "content",
        "parchment",
        "normal",
        "deploy_default",
        True,
    )

    ui_crops = {
        "nav": (42, 268, 474, 478),
        "summary": (548, 34, 971, 671),
        "action": (1013, 218, 1520, 510),
        "danger": (42, 742, 481, 916),
        "handle": (556, 748, 884, 899),
        "card": (958, 671, 1491, 987),
        "chain": (593, 35, 641, 159),
    }
    extracted = {name: trim_alpha(crop(ui_source, rect)) for name, rect in ui_crops.items()}

    summary_board = resize_exact(extracted["summary"], (252, 494))
    modal_board = nine_slice(extracted["summary"], (520, 268), 46)
    add("deploy_prep.panel.summary_board", "panels/summary_board.png", summary_board, "art22_ui_component_atlas_alpha_source.png", str(ui_crops["summary"]), "984,54,252,494", "status", "summary_board", "normal", "deploy_default", True)
    add("deploy_prep.panel.modal_board", "panels/modal_board.png", modal_board, "art22_ui_component_atlas_alpha_source.png", str(ui_crops["summary"]), "380,220,520,268", "modal", "cancel_modal", "normal", "deploy_modal", False)

    chain = fit_rgba(extracted["chain"], (24, 86), 1)
    add("deploy_prep.decoration.chain.vertical", "decoration/chain_vertical.png", chain, "art22_ui_component_atlas_alpha_source.png", str(ui_crops["chain"]), "dynamic", "decoration", "chain", "normal", "deploy_default", True)

    control_specs = {
        "nav": (resize_exact(extracted["nav"], (176, 46)), ("normal", "focused", "pressed", "disabled"), "deploy_default", "art22_ui_component_atlas_alpha_source.png", str(ui_crops["nav"])),
        "action": (resize_exact(extracted["action"], (252, 82)), ("normal", "focused", "pressed", "disabled"), "deploy_default", "art22_ui_component_atlas_alpha_source.png", str(ui_crops["action"])),
        "danger": (resize_exact(extracted["danger"], (224, 44)), ("normal", "focused", "pressed", "disabled"), "deploy_active_run", "art22_ui_component_atlas_alpha_source.png", str(ui_crops["danger"])),
        "handle": (resize_exact(extracted["handle"], (156, 40)), ("normal", "focused", "pressed"), "deploy_default", "art22_ui_component_atlas_alpha_source.png", str(ui_crops["handle"])),
        "tab": (parchment_control(parchment_source, (116, 44)), ("normal", "focused", "pressed", "disabled", "selected"), "deploy_default", "art22_parchment_alpha_source.png", "interior_texture+drawn_border"),
        "filter": (parchment_control(parchment_source, (104, 34)), ("normal", "focused", "pressed", "disabled", "selected"), "deploy_default", "art22_parchment_alpha_source.png", "interior_texture+drawn_border"),
        "card": (clean_dark_frame(extracted["card"], (632, 112), 24), ("normal", "focused", "pressed", "selected", "locked", "warning"), "deploy_default", "art22_ui_component_atlas_alpha_source.png", f"{ui_crops['card']}+text_safe_matte"),
        "slot": (clean_dark_frame(extracted["card"], (58, 58), 16), ("normal", "selected", "locked", "warning"), "deploy_default", "art22_ui_component_atlas_alpha_source.png", f"{ui_crops['card']}+text_safe_matte"),
    }
    for control_id, (base, states, load_group, source_name, source_rect) in control_specs.items():
        for state in states:
            image = parchment_state_variant(base, state) if control_id in {"tab", "filter"} else state_variant(base, state)
            add(
                f"deploy_prep.control.{control_id}.{state}",
                f"controls/{control_id}_{state}.png",
                image,
                source_name,
                source_rect,
                "dynamic",
                "control",
                control_id,
                state,
                load_group,
                load_group == "deploy_default",
            )

    route_rects = [
        (28, 131, 499, 467),
        (535, 131, 1001, 467),
        (1038, 131, 1509, 467),
        (28, 528, 499, 868),
        (535, 528, 1001, 868),
        (1038, 528, 1509, 868),
    ]
    route_ids = ["graytail_edge", "classic_grid", "honeycomb", "fog_rule", "locked_gate", "objective_cache"]
    for route_id, rect in zip(route_ids, route_rects):
        image = ImageOps.fit(crop(route_source, rect), (144, 92), Image.Resampling.LANCZOS)
        add(
            f"deploy_prep.route.{route_id}",
            f"routes/{route_id}.png",
            image,
            "art22_route_thumbnail_atlas_source.png",
            str(rect),
            "dynamic:144x92",
            "content",
            "route_thumbnail",
            "normal",
            "deploy_map",
            False,
        )

    icon_rects = [
        (28, 91, 364, 412),
        (392, 91, 704, 412),
        (720, 91, 1050, 412),
        (1062, 91, 1407, 412),
        (1417, 91, 1750, 412),
        (26, 456, 365, 807),
        (386, 456, 708, 807),
        (719, 456, 1049, 807),
        (1055, 456, 1408, 807),
        (1415, 456, 1754, 807),
    ]
    icon_ids = [
        "claim_purchase",
        "claim_receive",
        "claim_recycle",
        "claim_locked",
        "claim_recommended",
        "objective_recover",
        "objective_scan",
        "objective_map_match",
        "objective_locked",
        "objective_reward",
    ]
    for icon_id, rect in zip(icon_ids, icon_rects):
        extracted_icon = trim_alpha(crop(icon_source, rect))
        image = fit_rgba(extracted_icon, (72, 72), 2)
        group = "deploy_claim" if icon_id.startswith("claim_") else "deploy_objective"
        add(
            f"deploy_prep.icon.{icon_id}",
            f"icons/{icon_id}.png",
            image,
            "art22_semantic_icon_atlas_alpha_source.png",
            str(rect),
            "dynamic:72x72",
            "content",
            "semantic_icon",
            "normal",
            group,
            False,
        )

    fallback = state_variant(fit_rgba(trim_alpha(crop(icon_source, icon_rects[3])), (72, 72), 2), "locked")
    add(
        "deploy_prep.icon.fallback",
        "icons/fallback.png",
        fallback,
        "art22_semantic_icon_atlas_alpha_source.png",
        str(icon_rects[3]),
        "dynamic:72x72",
        "content",
        "semantic_icon",
        "fallback",
        "deploy_default",
        True,
    )

    return assets


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_assets(assets: Iterable[RuntimeAsset]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for asset in assets:
        output = RUNTIME_ROOT / asset.relative_path
        output.parent.mkdir(parents=True, exist_ok=True)
        asset.image.save(output, "PNG", optimize=True)
        source_path = SOURCE_ROOT / asset.source_name
        rows.append({
            "screen": "deploy_prep",
            "layer": asset.layer,
            "slot": asset.slot,
            "state": asset.state,
            "visibility_rule": f"load_group:{asset.load_group}",
            "source_candidate": f"docs/art/validation/art22/sources/{asset.source_name}",
            "source_rect": asset.source_rect,
            "runtime_asset": asset.godot_path,
            "asset_id": asset.asset_id,
            "visual_key": asset.visual_key,
            "consumer": "scripts/ui/deploy_prep/deploy_prep_shell.gd",
            "runtime_rect": asset.runtime_rect,
            "anchor": "top_left",
            "pivot": "0,0",
            "z_layer": asset.layer,
            "runtime_status": "live_or_interaction_reachable",
            "load_group": asset.load_group,
            "default_load": str(asset.default_load).lower(),
            "decoded_bytes": str(asset.image.width * asset.image.height * 4),
            "source_status": asset.source_status,
            "source_sha256": sha256(source_path),
            "runtime_sha256": sha256(output),
            "width": str(asset.image.width),
            "height": str(asset.image.height),
        })
    return rows


CONTRACT_FIELDS = [
    "screen", "layer", "slot", "state", "visibility_rule", "source_candidate",
    "source_rect", "runtime_asset", "asset_id", "visual_key", "consumer",
    "runtime_rect", "anchor", "pivot", "z_layer", "runtime_status", "load_group",
    "default_load", "decoded_bytes", "source_status", "source_sha256",
    "runtime_sha256", "width", "height",
]


def write_contract(rows: list[dict[str, str]]) -> None:
    VALIDATION_ROOT.mkdir(parents=True, exist_ok=True)
    for path in (CONTRACT_PATH, REPORT_CSV_PATH):
        with path.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=CONTRACT_FIELDS)
            writer.writeheader()
            writer.writerows(rows)

    total_decoded = sum(int(row["decoded_bytes"]) for row in rows)
    default_decoded = sum(int(row["decoded_bytes"]) for row in rows if row["default_load"] == "true")
    report = {
        "stage": "ART22",
        "screen": "deploy_prep",
        "runtime_assets": len(rows),
        "default_assets": sum(1 for row in rows if row["default_load"] == "true"),
        "total_decoded_bytes": total_decoded,
        "total_decoded_mib": round(total_decoded / (1024 * 1024), 2),
        "default_decoded_bytes": default_decoded,
        "default_decoded_mib": round(default_decoded / (1024 * 1024), 2),
        "load_groups": sorted({row["load_group"] for row in rows}),
        "source_files": sorted({row["source_candidate"] for row in rows}),
    }
    REPORT_JSON_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def update_manifest(rows: list[dict[str, str]]) -> None:
    with MANIFEST_PATH.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        fieldnames = list(reader.fieldnames or [])
        existing = [row for row in reader if not row.get("asset_id", "").startswith("ui.art22.deploy_prep.")]

    if not fieldnames:
        raise ValueError("asset manifest header is missing")

    additions = []
    for row in rows:
        additions.append({
            "asset_id": row["asset_id"],
            "source_repo_path": row["source_candidate"],
            "godot_path": row["runtime_asset"],
            "type": "texture",
            "category": "ui_art",
            "usage": f"ART22 Deploy Prep {row['slot']} {row['state']}",
            "import_preset": "pixel_ui",
            "license_status": "internal_generated",
            "replacement_needed": "false",
            "linked_scene": "scripts/ui/deploy_prep/deploy_prep_shell.gd",
            "linked_data": "DeployPrepModel",
            "note": f"ART22 audited source; sha256={row['runtime_sha256']}",
            "theme_key": row["visual_key"],
            "presentation_role": row["slot"],
            "state": row["state"],
            "variant": row["load_group"],
            "source_status": row["source_status"],
        })

    with MANIFEST_PATH.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(existing + additions)


def main() -> int:
    assets = build_assets()
    rows = write_assets(assets)
    write_contract(rows)
    update_manifest(rows)
    print(f"ART22_DEPLOY_ASSETS={len(rows)}")
    print(REPORT_JSON_PATH.read_text(encoding="utf-8").strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
