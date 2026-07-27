#!/usr/bin/env python3
"""Build current I3R LongTerm runtime art from frozen ART23 source material."""

from __future__ import annotations

import csv
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ROOT = ROOT / "docs/art/validation/art23/sources"
ART22_UI_ROOT = ROOT / "Godot/GraytailGodot/assets/ui/art22/deploy_prep"
RUNTIME_ROOT = ROOT / "Godot/GraytailGodot/assets/ui/art23/long_term"
CURRENT_VALIDATION_ROOT = ROOT / "docs/40_validation/i3r_long_term_current"
CURRENT_SOURCE_ROOT = CURRENT_VALIDATION_ROOT / "sources"
MANIFEST_PATH = ROOT / "Godot/GraytailGodot/data/assets/asset_manifest.csv"
REPORT_CSV_PATH = CURRENT_VALIDATION_ROOT / "long_term_runtime_asset_report.csv"
REPORT_JSON_PATH = CURRENT_VALIDATION_ROOT / "long_term_runtime_asset_report.json"
CONTRACT_PATH = CURRENT_VALIDATION_ROOT / "long_term_runtime_asset_contract.csv"

# Current production exposes task_archive through the audited "goals" visual
# alias. Gacha remains frozen ART23 evidence and is deliberately absent here.
CURRENT_MODULE_TABLE = (
    ("task_archive", "goals"),
    ("codex", "codex"),
    ("research", "research"),
    ("talent", "talent"),
    ("profile", "profile"),
    ("collection_appearance", "collection_appearance"),
)
CURRENT_MODULE_ASSET_IDS = tuple(asset_id for _, asset_id in CURRENT_MODULE_TABLE)
TALENT_FURNITURE_SOURCE_RELATIVE = "docs/40_validation/i3r_long_term_current/sources/talent_furniture_alpha_source.png"
TALENT_FURNITURE_SOURCE_SHA256 = "bb341cbeb85cba1606fdbe9abe731cfc8a8730e2236f5b0d831d009ba54e9336"
RETIRED_GACHA_RUNTIME_PATHS = (
    "furniture/gacha.png",
    "controls/module_gacha_normal.png",
    "controls/module_gacha_focused.png",
    "controls/module_gacha_pressed.png",
    "controls/module_gacha_selected.png",
    "controls/module_gacha_locked.png",
)

MAGENTA = (255, 0, 255)
WOOD = (50, 27, 14, 255)
WOOD_LIGHT = (91, 52, 25, 255)
WOOD_DARK = (23, 14, 10, 255)
BRASS = (171, 116, 43, 255)
BRASS_LIGHT = (239, 182, 72, 255)
BRASS_DARK = (84, 49, 20, 255)
TEAL = (39, 205, 196, 255)
PARCHMENT = (204, 164, 105, 255)


@dataclass(frozen=True)
class RuntimeAsset:
    visual_key: str
    relative_path: str
    image: Image.Image
    source_name: str
    source_rect: str
    layer: str
    slot: str
    state: str
    load_group: str
    default_load: bool

    @property
    def asset_id(self) -> str:
        return f"ui.art23.{self.visual_key}"

    @property
    def godot_path(self) -> str:
        return f"res://assets/ui/art23/long_term/{self.relative_path}"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def open_rgba(name: str) -> Image.Image:
    path = SOURCE_ROOT / name
    if not path.is_file():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def open_project_rgba(relative_path: str) -> Image.Image:
    path = ROOT / relative_path
    if not path.is_file():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def load_talent_furniture_source() -> Image.Image:
    source_path = ROOT / TALENT_FURNITURE_SOURCE_RELATIVE
    if sha256(source_path) != TALENT_FURNITURE_SOURCE_SHA256:
        raise ValueError("dedicated talent furniture source SHA256 mismatch")
    with Image.open(source_path) as source:
        if source.mode != "RGBA":
            raise ValueError(f"dedicated talent furniture source must be RGBA, got {source.mode}")
        rgba = source.copy()
    alpha_min, alpha_max = rgba.getchannel("A").getextrema()
    if alpha_min != 0 or alpha_max != 255:
        raise ValueError("dedicated talent furniture source must contain transparent and opaque pixels")
    return rgba


def trim_alpha(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("empty alpha image")
    return image.crop(bbox)


def chroma_alpha(image: Image.Image, transparent_threshold: int = 14, opaque_threshold: int = 205) -> Image.Image:
    """Remove the flat imagegen magenta stage with a soft matte and mild despill."""
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, _ = pixels[x, y]
            distance = max(abs(r - 255), abs(g), abs(b - 255))
            if distance <= transparent_threshold:
                pixels[x, y] = (0, 0, 0, 0)
                continue
            if distance >= opaque_threshold:
                alpha = 255
            else:
                alpha = int(255 * (distance - transparent_threshold) / (opaque_threshold - transparent_threshold))
            if alpha < 255:
                excess = max(0, min(r, b) - g)
                r = max(0, r - excess)
                b = max(0, b - excess)
            pixels[x, y] = (r, g, b, alpha)
    alpha = rgba.getchannel("A")
    alpha = alpha.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.35))
    rgba.putalpha(alpha)
    return trim_alpha(rgba)


def contain(image: Image.Image, size: tuple[int, int], padding: int = 0) -> Image.Image:
    result = Image.new("RGBA", size, (0, 0, 0, 0))
    inner = (max(1, size[0] - 2 * padding), max(1, size[1] - 2 * padding))
    fitted = ImageOps.contain(image, inner, Image.Resampling.LANCZOS)
    result.alpha_composite(fitted, ((size[0] - fitted.width) // 2, (size[1] - fitted.height) // 2))
    return result


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def nine_slice_resize(
    image: Image.Image,
    size: tuple[int, int],
    borders: tuple[int, int, int, int],
) -> Image.Image:
    """Resize audited UI art without stretching corners or chain anchors."""
    left, top, right, bottom = borders
    source_w, source_h = image.size
    target_w, target_h = size
    if left + right >= source_w or top + bottom >= source_h:
        raise ValueError(f"invalid nine-slice borders {borders} for {image.size}")
    if left + right >= target_w or top + bottom >= target_h:
        return image.resize(size, Image.Resampling.LANCZOS)

    result = Image.new("RGBA", size, (0, 0, 0, 0))
    source_x = (0, left, source_w - right, source_w)
    source_y = (0, top, source_h - bottom, source_h)
    target_x = (0, left, target_w - right, target_w)
    target_y = (0, top, target_h - bottom, target_h)
    for row in range(3):
        for column in range(3):
            crop = image.crop((source_x[column], source_y[row], source_x[column + 1], source_y[row + 1]))
            target_size = (target_x[column + 1] - target_x[column], target_y[row + 1] - target_y[row])
            if crop.size != target_size:
                crop = crop.resize(target_size, Image.Resampling.LANCZOS)
            result.alpha_composite(crop, (target_x[column], target_y[row]))
    return result


def art22_path(relative_path: str) -> str:
    return f"Godot/GraytailGodot/assets/ui/art22/deploy_prep/{relative_path}"


def art22_ui(relative_path: str) -> Image.Image:
    return open_project_rgba(art22_path(relative_path))


def teal_selected_surface(image: Image.Image) -> Image.Image:
    """Apply ART22's oxidized-teal selection language while keeping the source frame."""
    overlay = Image.new("RGBA", image.size, (9, 111, 109, 118))
    overlay.putalpha(ImageChops.multiply(image.getchannel("A"), overlay.getchannel("A")))
    return outline(Image.alpha_composite(image, overlay), TEAL, 2)


def wood_texture(size: tuple[int, int], seed: int = 0) -> Image.Image:
    image = Image.new("RGBA", size, WOOD)
    draw = ImageDraw.Draw(image)
    for y in range(5 + seed % 7, size[1], 9):
        color = WOOD_LIGHT if (y // 9 + seed) % 3 == 0 else BRASS_DARK
        draw.line((4, y, size[0] - 5, y + ((y + seed) % 3 - 1)), fill=(*color[:3], 72), width=1)
    for x in range(13 + seed % 5, size[0], 37):
        draw.line((x, 6, x + ((x + seed) % 5 - 2), size[1] - 7), fill=(18, 10, 8, 45), width=1)
    return image


def brass_frame(image: Image.Image, inset: int = 2, radius: int = 7, bolts: bool = True) -> Image.Image:
    draw = ImageDraw.Draw(image)
    w, h = image.size
    draw.rounded_rectangle((inset, inset, w - inset - 1, h - inset - 1), radius=radius, outline=BRASS_DARK, width=5)
    draw.rounded_rectangle((inset + 4, inset + 4, w - inset - 5, h - inset - 5), radius=max(1, radius - 3), outline=BRASS, width=2)
    draw.line((inset + 9, inset + 7, w - inset - 10, inset + 7), fill=BRASS_LIGHT, width=1)
    if bolts:
        for x, y in ((inset + 9, inset + 9), (w - inset - 10, inset + 9), (inset + 9, h - inset - 10), (w - inset - 10, h - inset - 10)):
            draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=BRASS, outline=BRASS_DARK, width=1)
    return image


def plate(size: tuple[int, int], state: str, seed: int = 0, radius: int = 7) -> Image.Image:
    image = wood_texture(size, seed)
    image.putalpha(rounded_mask(size, radius))
    image = brass_frame(image, 1, radius)
    if state == "focused":
        image = ImageEnhance.Brightness(image).enhance(1.12)
        image = outline(image, TEAL, 3)
    elif state == "pressed":
        image = ImageEnhance.Brightness(image).enhance(0.78)
    elif state == "selected":
        overlay = Image.new("RGBA", size, (0, 95, 96, 88))
        overlay.putalpha(ImageChops.multiply(image.getchannel("A"), overlay.getchannel("A")))
        image = Image.alpha_composite(image, overlay)
        image = outline(image, TEAL, 3)
    elif state == "locked":
        gray = ImageOps.grayscale(image).convert("RGBA")
        gray.putalpha(image.getchannel("A"))
        image = ImageEnhance.Brightness(gray).enhance(0.62)
    return image


def outline(image: Image.Image, color: tuple[int, int, int, int], width: int) -> Image.Image:
    alpha = image.getchannel("A")
    expanded = alpha.filter(ImageFilter.MaxFilter(width * 2 + 1))
    edge = ImageChops.subtract(expanded, alpha)
    layer = Image.new("RGBA", image.size, color)
    layer.putalpha(ImageChops.multiply(edge, Image.new("L", image.size, color[3])))
    return Image.alpha_composite(layer, image)


def draw_icon(image: Image.Image, icon_id: str, selected: bool = False) -> None:
    draw = ImageDraw.Draw(image)
    cx, cy = image.width // 2, 31
    color = TEAL if selected else BRASS_LIGHT
    shadow = BRASS_DARK
    if icon_id == "goals":
        draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), outline=shadow, width=5)
        draw.ellipse((cx - 15, cy - 15, cx + 15, cy + 15), outline=color, width=3)
        points = [(cx, cy - 13), (cx + 5, cy - 4), (cx + 13, cy), (cx + 5, cy + 4), (cx, cy + 13), (cx - 5, cy + 4), (cx - 13, cy), (cx - 5, cy - 4)]
        draw.polygon(points, fill=color, outline=shadow)
    elif icon_id == "codex":
        draw.polygon([(cx - 23, cy - 14), (cx - 3, cy - 10), (cx - 3, cy + 16), (cx - 23, cy + 12)], fill=(115, 79, 38), outline=shadow)
        draw.polygon([(cx + 23, cy - 14), (cx + 3, cy - 10), (cx + 3, cy + 16), (cx + 23, cy + 12)], fill=(115, 79, 38), outline=shadow)
        draw.line((cx, cy - 10, cx, cy + 17), fill=color, width=3)
        draw.line((cx - 19, cy - 6, cx - 7, cy - 4), fill=color, width=2)
        draw.line((cx + 7, cy - 4, cx + 19, cy - 6), fill=color, width=2)
    elif icon_id == "research":
        draw.line((cx - 6, cy - 19, cx + 6, cy - 19), fill=color, width=4)
        draw.line((cx - 3, cy - 17, cx - 3, cy - 2), fill=color, width=3)
        draw.line((cx + 3, cy - 17, cx + 3, cy - 2), fill=color, width=3)
        draw.polygon([(cx - 3, cy - 3), (cx - 17, cy + 17), (cx + 17, cy + 17), (cx + 3, cy - 3)], fill=(23, 98, 101), outline=color)
        draw.ellipse((cx - 5, cy + 3, cx + 2, cy + 10), fill=color)
    elif icon_id == "talent":
        # A three-branch progression tree: unlike the research flask or the
        # retired gacha machine, each node has an explicit parent relation.
        branches = [
            (cx, cy + 17, cx, cy - 1),
            (cx, cy - 1, cx - 17, cy - 12),
            (cx, cy - 1, cx, cy - 20),
            (cx, cy - 1, cx + 17, cy - 12),
        ]
        for branch in branches:
            draw.line(branch, fill=shadow, width=7)
            draw.line(branch, fill=color, width=3)
        for node_x, node_y in ((cx - 17, cy - 12), (cx, cy - 20), (cx + 17, cy - 12)):
            draw.rectangle((node_x - 5, node_y - 5, node_x + 5, node_y + 5), fill=WOOD_DARK, outline=shadow, width=3)
            draw.rectangle((node_x - 3, node_y - 3, node_x + 3, node_y + 3), fill=color)
        draw.polygon(
            [(cx, cy + 9), (cx + 7, cy + 17), (cx + 3, cy + 17), (cx + 10, cy + 23),
             (cx, cy + 19), (cx - 10, cy + 23), (cx - 3, cy + 17), (cx - 7, cy + 17)],
            fill=color,
            outline=shadow,
        )
    elif icon_id == "profile":
        draw.ellipse((cx - 11, cy, cx + 11, cy + 18), fill=color, outline=shadow)
        for dx, dy in ((-17, -10), (-6, -16), (6, -16), (17, -10)):
            draw.ellipse((cx + dx - 5, cy + dy - 5, cx + dx + 5, cy + dy + 5), fill=color, outline=shadow)
    elif icon_id == "collection_appearance":
        draw.rectangle((cx - 20, cy - 18, cx + 20, cy + 18), fill=(72, 39, 20), outline=color, width=3)
        draw.line((cx, cy - 16, cx, cy + 16), fill=color, width=2)
        draw.ellipse((cx - 5, cy - 1, cx - 1, cy + 3), fill=color)
        draw.ellipse((cx + 1, cy - 1, cx + 5, cy + 3), fill=color)


def module_button(icon_id: str, state: str) -> Image.Image:
    source_state = {
        "normal": "normal",
        "focused": "focused",
        "pressed": "pressed",
        "selected": "normal",
        "locked": "disabled",
    }[state]
    image = nine_slice_resize(art22_ui(f"controls/nav_{source_state}.png"), (126, 90), (18, 16, 18, 16))
    if state == "selected":
        image = teal_selected_surface(image)
    draw_icon(image, icon_id, state == "selected")
    draw = ImageDraw.Draw(image)
    draw.line((18, 59, 108, 59), fill=TEAL if state == "selected" else (84, 87, 82, 255), width=2)
    if icon_id == "research":
        draw.ellipse((100, 9, 116, 25), fill=WOOD_DARK, outline=BRASS, width=2)
        draw.rectangle((104, 16, 112, 24), fill=BRASS_DARK, outline=BRASS)
    return image


def profile_frame() -> Image.Image:
    source = art22_ui("panels/summary_board.png")
    image = nine_slice_resize(source, (258, 704), (34, 82, 34, 42))
    draw = ImageDraw.Draw(image)
    draw.rectangle((24, 80, 234, 314), fill=(4, 24, 25, 206), outline=(12, 132, 127, 255), width=2)
    # Ground the fixed character inside the dossier instead of presenting it
    # as a floating sticker; the sprite itself remains the shared ART21/22 set.
    draw.ellipse((64, 274, 194, 307), fill=(2, 8, 8, 170), outline=(15, 92, 88, 150), width=2)
    draw.rectangle((24, 326, 234, 620), fill=(6, 25, 26, 222), outline=(12, 132, 127, 255), width=2)
    for y in (390, 436, 482, 528, 574):
        draw.line((34, y, 224, y), fill=(25, 112, 108, 190), width=1)
    return image


def parchment_panel(size: tuple[int, int]) -> Image.Image:
    return nine_slice_resize(art22_ui("panels/parchment.png"), size, (34, 34, 34, 34))


def art22_control(control_id: str, state: str, size: tuple[int, int]) -> tuple[Image.Image, str]:
    state_map = {
        "nav": {
            "normal": "nav_normal.png", "focused": "nav_focused.png", "pressed": "nav_pressed.png",
            "selected": "nav_focused.png", "locked": "nav_disabled.png",
        },
        "secondary": {
            "normal": "tab_normal.png", "focused": "tab_focused.png", "pressed": "tab_pressed.png",
            "selected": "filter_selected.png", "locked": "tab_disabled.png",
        },
        "card": {
            "normal": "card_normal.png", "focused": "card_focused.png", "pressed": "card_pressed.png",
            "selected": "card_selected.png", "locked": "card_locked.png",
        },
    }
    filename = state_map[control_id][state]
    source = art22_ui(f"controls/{filename}")
    borders = (18, 12, 18, 12) if control_id != "card" else (20, 14, 20, 14)
    image = nine_slice_resize(source, size, borders)
    if control_id == "nav" and state == "selected":
        image = teal_selected_surface(image)
    return image, art22_path(f"controls/{filename}")


def lever(expanded: bool) -> Image.Image:
    image = Image.new("RGBA", (152, 100), (0, 0, 0, 0))
    base = nine_slice_resize(art22_ui("controls/nav_normal.png"), (152, 36), (18, 12, 18, 12))
    image.alpha_composite(base, (0, 62))
    draw = ImageDraw.Draw(image)
    # A compact archive drawer and direction arrow reads as “fold/unfold the
    # dossier”; the former long rod plus round knob resembled a magnifying glass.
    draw.rectangle((10, 10, 64, 59), fill=WOOD_DARK, outline=BRASS_DARK, width=3)
    draw.rectangle((15, 15, 59, 33), fill=(72, 39, 20, 255), outline=BRASS, width=2)
    draw.rectangle((15, 36, 59, 54), fill=(72, 39, 20, 255), outline=BRASS, width=2)
    draw.rectangle((31, 22, 43, 25), fill=BRASS_LIGHT, outline=BRASS_DARK, width=1)
    draw.rectangle((31, 43, 43, 46), fill=BRASS_LIGHT, outline=BRASS_DARK, width=1)
    arrow_shadow = (23, 38, 38, 255)
    arrow_color = TEAL
    if expanded:
        shadow_points = [(82, 19), (126, 19), (104, 57)]
        points = [(88, 23), (120, 23), (104, 51)]
    else:
        shadow_points = [(104, 10), (126, 48), (82, 48)]
        points = [(104, 16), (120, 44), (88, 44)]
    draw.polygon(shadow_points, fill=arrow_shadow, outline=BRASS_DARK)
    draw.polygon(points, fill=arrow_color, outline=BRASS_LIGHT)
    return image


def rail() -> Image.Image:
    image = Image.new("RGBA", (820, 20), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((2, 6, 817, 15), radius=4, fill=(24, 29, 29, 255), outline=(102, 112, 106, 255), width=2)
    draw.line((8, 8, 811, 8), fill=(13, 109, 105, 210), width=1)
    for x in range(16, 810, 52):
        draw.rectangle((x, 4, x + 8, 17), fill=(31, 36, 35, 255), outline=(113, 121, 113, 255), width=1)
    return image


def chain() -> Image.Image:
    image = Image.new("RGBA", (20, 70), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for y in range(-2, 72, 14):
        draw.ellipse((5, y, 15, y + 18), outline=BRASS_DARK, width=4)
        draw.ellipse((7, y + 2, 13, y + 16), outline=BRASS_LIGHT, width=1)
    return image


def build_assets() -> list[RuntimeAsset]:
    assets: list[RuntimeAsset] = []

    def add(key: str, path: str, image: Image.Image, source: str, source_rect: str, layer: str, slot: str, state: str, group: str, default: bool) -> None:
        assets.append(RuntimeAsset(key, path, image, source, source_rect, layer, slot, state, group, default))

    room = ImageOps.fit(open_rgba("long_term_room_unified_source.png"), (1280, 720), Image.Resampling.LANCZOS)
    add("long_term.scene.background.clean_plate", "background/scene_clean_plate.png", room, "long_term_room_unified_source.png", "full->1280x720", "background", "clean_plate", "normal", "long_term_default", True)

    script_source = "tools/art23_build_long_term_runtime.py"
    furniture_specs = {
        "goals": ("goals_furniture_chroma_source.png", (820, 536), 8),
        "codex": ("codex_furniture_chroma_source.png", (820, 526), 8),
        "research": ("research_furniture_chroma_source.png", (820, 526), 8),
        "profile": ("profile_furniture_chroma_source.png", (820, 526), 8),
        "collection_appearance": ("collection_appearance_furniture_chroma_source.png", (820, 526), 8),
    }
    for module_id in CURRENT_MODULE_ASSET_IDS:
        if module_id == "talent":
            source = TALENT_FURNITURE_SOURCE_RELATIVE
            image = contain(trim_alpha(load_talent_furniture_source()), (820, 526), 8)
            source_rect = "alpha_bbox+contain_centered_padding8->820x526"
        else:
            source, size, padding = furniture_specs[module_id]
            image = contain(chroma_alpha(open_rgba(source)), size, padding)
            source_rect = "chroma_alpha_bbox"
        add(
            f"long_term.furniture.{module_id}",
            f"furniture/{module_id}.png",
            image,
            source,
            source_rect,
            "content",
            "module_furniture",
            "open",
            f"long_term_{module_id}",
            False,
        )

    add("long_term.decoration.rail", "decoration/module_rail.png", rail(), script_source, "generated", "decoration", "module_rail", "normal", "long_term_default", True)
    art22_chain_source = art22_path("decoration/chain_vertical.png")
    add("long_term.decoration.chain", "decoration/chain_vertical.png", nine_slice_resize(art22_ui("decoration/chain_vertical.png"), (20, 70), (4, 10, 4, 10)), art22_chain_source, "nine_slice->20x70", "decoration", "chain", "normal", "long_term_default", True)
    art22_profile_source = art22_path("panels/summary_board.png")
    add("long_term.panel.profile", "panels/profile_frame.png", profile_frame(), art22_profile_source, "nine_slice+teal_interior->258x704", "status", "profile_frame", "normal", "long_term_default", True)
    art22_parchment_source = art22_path("panels/parchment.png")
    add("long_term.panel.content", "panels/content_parchment.png", parchment_panel((560, 248)), art22_parchment_source, "nine_slice->560x248", "content", "content_panel", "normal", "long_term_default", True)
    add("long_term.control.lever.expanded", "controls/lever_expanded.png", lever(True), script_source, "generated", "control", "archive_lever", "expanded", "long_term_default", True)
    add("long_term.control.lever.collapsed", "controls/lever_collapsed.png", lever(False), script_source, "generated", "control", "archive_lever", "collapsed", "long_term_default", True)

    for state in ("normal", "focused", "pressed", "selected", "locked"):
        nav_image, nav_source = art22_control("nav", state, (142, 50))
        secondary_image, secondary_source = art22_control("secondary", state, (112, 36))
        card_image, card_source = art22_control("card", state, (260, 86))
        add(f"long_term.control.nav.{state}", f"controls/nav_{state}.png", nav_image, nav_source, "nine_slice->142x50", "control", "navigation", state, "long_term_default", True)
        add(f"long_term.control.secondary.{state}", f"controls/secondary_{state}.png", secondary_image, secondary_source, "nine_slice->112x36", "control", "secondary_tab", state, "long_term_default", True)
        add(f"long_term.control.card.{state}", f"controls/card_{state}.png", card_image, card_source, "nine_slice->260x86", "control", "content_card", state, "long_term_default", True)
        for module_id in CURRENT_MODULE_ASSET_IDS:
            module_source_state = "normal" if state == "selected" else ("disabled" if state == "locked" else state)
            module_source = art22_path(f"controls/nav_{module_source_state}.png")
            add(
                f"long_term.control.module.{module_id}.{state}",
                f"controls/module_{module_id}_{state}.png",
                module_button(module_id, state),
                module_source,
                "nine_slice+semantic_icon->126x90",
                "control",
                "primary_module",
                state,
                "long_term_default",
                True,
            )
    return assets


FIELDS = [
    "screen", "layer", "slot", "state", "visibility_rule", "source_candidate", "source_rect",
    "runtime_asset", "asset_id", "visual_key", "consumer", "runtime_rect", "anchor", "pivot",
    "z_layer", "runtime_status", "load_group", "default_load", "decoded_bytes", "source_status",
    "source_sha256", "runtime_sha256", "width", "height",
]


def write_assets(assets: list[RuntimeAsset]) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for asset in assets:
        output = RUNTIME_ROOT / asset.relative_path
        output.parent.mkdir(parents=True, exist_ok=True)
        should_write = True
        if output.is_file():
            with Image.open(output) as existing:
                existing_rgba = existing.convert("RGBA")
                should_write = (
                    existing_rgba.size != asset.image.size
                    or ImageChops.difference(existing_rgba, asset.image).getbbox() is not None
                )
        if should_write:
            asset.image.save(output, "PNG", optimize=True)
        source_path = ROOT / asset.source_name if asset.source_name.startswith(("tools/", "Godot/", "docs/")) else SOURCE_ROOT / asset.source_name
        rows.append({
            "screen": "long_term",
            "layer": asset.layer,
            "slot": asset.slot,
            "state": asset.state,
            "visibility_rule": f"load_group:{asset.load_group}",
            "source_candidate": asset.source_name if asset.source_name.startswith(("tools/", "Godot/", "docs/")) else f"docs/art/validation/art23/sources/{asset.source_name}",
            "source_rect": asset.source_rect,
            "runtime_asset": asset.godot_path,
            "asset_id": asset.asset_id,
            "visual_key": asset.visual_key,
            "consumer": "scripts/ui/long_term/long_term_shell.gd",
            "runtime_rect": "contract",
            "anchor": "top_left",
            "pivot": "0,0",
            "z_layer": asset.layer,
            "runtime_status": "current_production_reachable",
            "load_group": asset.load_group,
            "default_load": str(asset.default_load).lower(),
            "decoded_bytes": str(asset.image.width * asset.image.height * 4),
            "source_status": "i3r_current_generated_from_audited_source",
            "source_sha256": sha256(source_path),
            "runtime_sha256": sha256(output),
            "width": str(asset.image.width),
            "height": str(asset.image.height),
        })
    return rows


def write_reports(rows: list[dict[str, str]]) -> None:
    CURRENT_VALIDATION_ROOT.mkdir(parents=True, exist_ok=True)
    for path in (CONTRACT_PATH, REPORT_CSV_PATH):
        with path.open("w", encoding="utf-8", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=FIELDS)
            writer.writeheader()
            writer.writerows(rows)
    total = sum(int(row["decoded_bytes"]) for row in rows)
    default = sum(int(row["decoded_bytes"]) for row in rows if row["default_load"] == "true")
    report = {
        "stage": "I3R",
        "screen": "long_term",
        "authority": "current_production",
        "primary_modules": 6,
        "secondary_pages": 25,
        "runtime_assets": len(rows),
        "default_assets": sum(1 for row in rows if row["default_load"] == "true"),
        "total_decoded_bytes": total,
        "total_decoded_mib": round(total / (1024 * 1024), 2),
        "default_decoded_bytes": default,
        "default_decoded_mib": round(default / (1024 * 1024), 2),
        "load_groups": sorted({row["load_group"] for row in rows}),
        "source_files": sorted({row["source_candidate"] for row in rows}),
    }
    REPORT_JSON_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def verify_talent_furniture_output(rows: list[dict[str, str]]) -> None:
    matches = [row for row in rows if row["asset_id"] == "ui.art23.long_term.furniture.talent"]
    if len(matches) != 1:
        raise ValueError(f"expected one dedicated talent furniture row, got {len(matches)}")
    row = matches[0]
    if row["source_candidate"] != TALENT_FURNITURE_SOURCE_RELATIVE:
        raise ValueError("dedicated talent furniture source path drifted")
    if row["source_sha256"] != TALENT_FURNITURE_SOURCE_SHA256:
        raise ValueError("dedicated talent furniture row source hash drifted")
    output_path = RUNTIME_ROOT / "furniture/talent.png"
    with Image.open(output_path) as output:
        if output.mode != "RGBA" or output.size != (820, 526):
            raise ValueError(f"dedicated talent furniture output must be RGBA 820x526, got {output.mode} {output.size}")
        alpha = output.getchannel("A")
        alpha_min, alpha_max = alpha.getextrema()
        alpha_bbox = alpha.getbbox()
    if alpha_min != 0 or alpha_max != 255 or alpha_bbox is None:
        raise ValueError("dedicated talent furniture output lost its transparent/opaque composition")
    if alpha_bbox[0] <= 0 or alpha_bbox[1] <= 0 or alpha_bbox[2] >= 820 or alpha_bbox[3] >= 526:
        raise ValueError(f"dedicated talent furniture output lost centered transparent margins: {alpha_bbox}")
    if sha256(output_path) != row["runtime_sha256"]:
        raise ValueError("dedicated talent furniture output hash drifted after write")


def update_manifest(rows: list[dict[str, str]]) -> None:
    with MANIFEST_PATH.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        fieldnames = list(reader.fieldnames or [])
        existing = list(reader)
    additions = []
    for row in rows:
        additions.append({
            "asset_id": row["asset_id"],
            "source_repo_path": row["source_candidate"],
            "godot_path": row["runtime_asset"],
            "type": "texture",
            "category": "ui_art",
            "usage": f"I3R current LongTerm {row['slot']} {row['state']}",
            "import_preset": "pixel_ui",
            "license_status": "internal_generated",
            "replacement_needed": "false",
            "linked_scene": "scripts/ui/long_term/long_term_shell.gd",
            "linked_data": "LongTermModel",
            "note": f"I3R current runtime generated from audited source; sha256={row['runtime_sha256']}",
            "theme_key": row["visual_key"],
            "presentation_role": row["slot"],
            "state": row["state"],
            "variant": row["load_group"],
            "source_status": row["source_status"],
        })
    additions.append({
        "asset_id": "ui.art23.long_term.font.body",
        "source_repo_path": "Godot/GraytailGodot/assets/fonts/NotoSansCJKsc-Regular.otf",
        "godot_path": "res://assets/fonts/NotoSansCJKsc-Regular.otf",
        "type": "font",
        "category": "ui_font",
        "usage": "Glyph fallback behind the FusionPixel player UI font stack",
        "import_preset": "font_default",
        "license_status": "verified_ofl_1_1",
        "replacement_needed": "false",
        "linked_scene": "scripts/presentation/art10_ui_skin_kit.gd",
        "linked_data": "Art10UISkinKit",
        "note": "Noto Sans CJK SC Regular; glyph fallback only; SIL Open Font License 1.1; license at res://assets/licenses/NotoSansCJK-OFL.txt",
        "theme_key": "long_term.font.body",
        "presentation_role": "glyph_fallback_font",
        "state": "normal",
        "variant": "long_term_default",
        "source_status": "verified_upstream_open_font",
    })
    merged = [row for row in existing if not row.get("asset_id", "").startswith("ui.art23.long_term.")]
    art22_indices = [
        index for index, row in enumerate(merged)
        if row.get("asset_id", "").startswith("ui.art22.")
    ]
    insert_at = art22_indices[-1] + 1 if art22_indices else len(merged)
    merged[insert_at:insert_at] = additions
    with MANIFEST_PATH.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(merged)


def main() -> int:
    retired_paths = [RUNTIME_ROOT / relative_path for relative_path in RETIRED_GACHA_RUNTIME_PATHS]
    remaining_retired = [path for path in retired_paths if path.exists()]
    if remaining_retired:
        names = ", ".join(path.relative_to(ROOT).as_posix() for path in remaining_retired)
        raise RuntimeError(f"Retired gacha runtime assets require audited removal before generation: {names}")
    assets = build_assets()
    rows = write_assets(assets)
    verify_talent_furniture_output(rows)
    write_reports(rows)
    update_manifest(rows)
    print(f"I3R_LONG_TERM_CURRENT_ASSETS={len(rows)}")
    print(REPORT_JSON_PATH.read_text(encoding="utf-8").strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
