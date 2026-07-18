#!/usr/bin/env python3
"""Build deterministic modular ART24 in-run art from audited sources.

This script never edits the global asset manifest. It emits a mergeable fragment,
runtime PNGs and a hash/dimension/alpha report for the art-only branch.
"""

from __future__ import annotations

import csv
import hashlib
import json
import math
import random
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "Godot/GraytailGodot"
ASSET_ROOT = GODOT / "assets/art24"
ACTOR_ROOT = ASSET_ROOT / "actors"
ITEM_ROOT = ASSET_ROOT / "items"
UI_ROOT = ASSET_ROOT / "ui"
FX_ROOT = ASSET_ROOT / "fx"
VALIDATION = ROOT / "docs/art/validation/art24"
REPORT_CSV = VALIDATION / "art24_runtime_asset_report.csv"
REPORT_JSON = VALIDATION / "art24_runtime_asset_report.json"
MANIFEST_FRAGMENT = VALIDATION / "art24_asset_manifest_fragment.csv"
REUSE_REPORT = VALIDATION / "art24_reused_asset_report.csv"
STATE_MATRIX_SOURCE = VALIDATION / "art24_acceptance_state_matrix.csv"
STATE_MATRIX_RUNTIME = ASSET_ROOT / "contracts/art24_acceptance_state_matrix.csv"
STATE_CATALOG_GD = GODOT / "scripts/presentation/art24/art24_state_catalog.gd"

IRON = (17, 24, 25, 255)
IRON_DEEP = (6, 13, 16, 255)
IRON_LIGHT = (57, 68, 65, 255)
WOOD = (55, 31, 18, 255)
WOOD_LIGHT = (100, 58, 28, 255)
BRASS = (175, 116, 42, 255)
BRASS_LIGHT = (238, 180, 72, 255)
BRASS_DARK = (76, 43, 19, 255)
TEAL = (39, 204, 194, 255)
TEAL_DARK = (16, 85, 84, 255)
AMBER = (239, 149, 52, 255)
RED = (209, 62, 44, 255)
ORANGE = (230, 101, 39, 255)
GREEN = (83, 174, 117, 255)
MUTED = (134, 139, 128, 255)


@dataclass(frozen=True)
class AssetRecord:
    asset_id: str
    visual_key: str
    path: Path
    source: str
    role: str
    state: str
    variant: str
    load_group: str
    source_status: str


REUSED = [
    ("room.background.normal", "res://assets/rooms/room_normal.png", "room_background", "normal"),
    ("room.background.mine", "res://assets/rooms/room_mine.png", "room_background", "mine"),
    ("room.background.chest", "res://assets/rooms/room_chest.png", "room_background", "chest"),
    ("room.background.event", "res://assets/rooms/room_event.png", "room_background", "event"),
    ("room.background.monster", "res://assets/rooms/room_monster.png", "room_background", "monster"),
    ("room.background.exit", "res://assets/rooms/room_exit.png", "room_background", "exit"),
    ("prop.chest.closed", "res://assets/props/chest_closed.png", "room_prop", "closed"),
    ("prop.mine.trap", "res://assets/props/mine_trap.png", "room_prop", "triggered"),
    ("prop.art07.00_baoxiang_kai", "res://assets/props/art07/00_baoxiang_kai.png", "room_prop", "open"),
    ("prop.art07.01_cheli_zhuangzhi_an", "res://assets/props/art07/01_cheli_zhuangzhi_an.png", "room_prop", "inactive"),
    ("prop.art07.02_cheli_zhuangzhi_liang", "res://assets/props/art07/02_cheli_zhuangzhi_liang.png", "room_prop", "active"),
    ("prop.art07.04_shangren_tai", "res://assets/props/art07/04_shangren_tai.png", "room_prop", "merchant"),
    ("prop.art07.05_yichang_hexin", "res://assets/props/art07/05_yichang_hexin.png", "room_prop", "event"),
    ("ui.art23.long_term.font.body", "res://assets/fonts/NotoSansCJKsc-Regular.otf", "body_font", "normal"),
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("empty alpha image")
    return bbox


def contain_trimmed(image: Image.Image, size: tuple[int, int], padding: int) -> Image.Image:
    image = image.crop(alpha_bbox(image))
    inner = (max(1, size[0] - padding * 2), max(1, size[1] - padding * 2))
    fitted = ImageOps.contain(image, inner, Image.Resampling.LANCZOS)
    result = Image.new("RGBA", size, (0, 0, 0, 0))
    result.alpha_composite(fitted, ((size[0] - fitted.width) // 2, size[1] - padding - fitted.height))
    return result


def grid_cells(image: Image.Image, columns: int, rows: int) -> list[Image.Image]:
    cells: list[Image.Image] = []
    for row in range(rows):
        top = round(row * image.height / rows)
        bottom = round((row + 1) * image.height / rows)
        for column in range(columns):
            left = round(column * image.width / columns)
            right = round((column + 1) * image.width / columns)
            cells.append(image.crop((left, top, right, bottom)))
    return cells


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def panel(size: tuple[int, int], accent: tuple[int, int, int, int] = BRASS, alpha: int = 244, radius: int = 10) -> Image.Image:
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((1, 1, size[0] - 2, size[1] - 2), radius=radius, fill=(*IRON_DEEP[:3], alpha), outline=BRASS_DARK, width=6)
    draw.rounded_rectangle((7, 7, size[0] - 8, size[1] - 8), radius=max(2, radius - 4), outline=(*accent[:3], 220), width=2)
    draw.line((18, 11, size[0] - 19, 11), fill=(*BRASS_LIGHT[:3], 110), width=1)
    draw.line((18, size[1] - 12, size[0] - 19, size[1] - 12), fill=(*IRON_LIGHT[:3], 170), width=1)
    for x, y in ((12, 12), (size[0] - 13, 12), (12, size[1] - 13), (size[0] - 13, size[1] - 13)):
        draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=BRASS, outline=BRASS_DARK, width=1)
    return image


def state_surface(size: tuple[int, int], state: str, radius: int = 8) -> Image.Image:
    accents = {
        "normal": BRASS,
        "selected": TEAL,
        "blocked": RED,
        "rare": AMBER,
        "unique": TEAL,
        "warning": ORANGE,
        "pressed": BRASS_LIGHT,
        "disabled": MUTED,
    }
    accent = accents.get(state, BRASS)
    image = panel(size, accent=accent, alpha=238, radius=radius)
    draw = ImageDraw.Draw(image)
    if state in {"selected", "unique"}:
        draw.rounded_rectangle((9, 9, size[0] - 10, size[1] - 10), radius=max(2, radius - 3), fill=(*TEAL_DARK[:3], 70))
        draw.rounded_rectangle((3, 3, size[0] - 4, size[1] - 4), radius=radius, outline=TEAL, width=2)
    elif state in {"blocked", "warning"}:
        draw.rounded_rectangle((9, 9, size[0] - 10, size[1] - 10), radius=max(2, radius - 3), fill=(*accent[:3], 52))
    elif state == "pressed":
        image = ImageEnhance.Brightness(image).enhance(0.78)
    elif state == "disabled":
        gray = ImageOps.grayscale(image).convert("RGBA")
        gray.putalpha(image.getchannel("A"))
        image = ImageEnhance.Brightness(gray).enhance(0.62)
    return image


def save(records: list[AssetRecord], image: Image.Image, relative: str, visual_key: str, source: str, role: str, state: str, variant: str, load_group: str) -> None:
    path = ASSET_ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)
    asset_id = "ui.art24." + visual_key.removeprefix("visual.art24.")
    records.append(AssetRecord(asset_id, visual_key, path, source, role, state, variant, load_group, "art24_generated"))


def build_actor_and_loot(records: list[AssetRecord]) -> None:
    player_atlas = Image.open(ACTOR_ROOT / "player_action_atlas.png").convert("RGBA")
    player_cells = grid_cells(player_atlas, 6, 4)
    facings = ["down", "left", "right", "up"]
    motions = ["idle_a", "idle_b", "walk_a", "walk_b", "hit", "interact"]
    for row, facing in enumerate(facings):
        for column, motion in enumerate(motions):
            image = contain_trimmed(player_cells[row * 6 + column], (160, 160), 5)
            key = f"visual.art24.actor.player.{facing}.{motion}"
            save(records, image, f"actors/player/{facing}_{motion}.png", key, "imagegen player atlas + chroma removal", "player_actor", motion, facing, "art24_actor")

    combat_atlas = Image.open(ACTOR_ROOT / "player_combat_atlas.png").convert("RGBA")
    combat_cells = grid_cells(combat_atlas, 4, 4)
    combat_motions = ["attack_windup", "attack_swing", "attack_impact", "attack_recover"]
    for row, facing in enumerate(facings):
        for column, motion in enumerate(combat_motions):
            image = contain_trimmed(combat_cells[row * 4 + column], (176, 176), 4)
            key = f"visual.art24.actor.player.{facing}.{motion}"
            save(records, image, f"actors/player/{facing}_{motion}.png", key, "imagegen player combat atlas + chroma removal", "player_actor", motion, facing, "art24_actor")

    monster_atlas = Image.open(ACTOR_ROOT / "ironback_action_atlas.png").convert("RGBA")
    monster_cells = grid_cells(monster_atlas, 4, 2)
    monster_states = ["idle_a", "idle_b", "appear", "attack_windup", "attack_impact", "hit", "defeated", "remains"]
    for index, state in enumerate(monster_states):
        image = contain_trimmed(monster_cells[index], (260, 200), 4)
        key = f"visual.art24.actor.ironback.{state}"
        save(records, image, f"actors/ironback/{state}.png", key, "imagegen ironback atlas + chroma removal", "monster_actor", state, "ironback", "art24_monster")

    loot_atlas = Image.open(ITEM_ROOT / "world_loot_atlas.png").convert("RGBA")
    loot_cells = grid_cells(loot_atlas, 4, 2)
    loot_states = ["emergency_bandage", "copper_coil", "scanner_probe", "armor_plate", "coin_cache", "anomaly_shard", "access_key", "salvage_satchel"]
    for index, state in enumerate(loot_states):
        image = contain_trimmed(loot_cells[index], (112, 112), 5)
        key = f"visual.art24.item.world_loot.{state}"
        save(records, image, f"items/world/{state}.png", key, "imagegen world-loot atlas + chroma removal", "world_loot", state, "default", "art24_loot")


def build_ui(records: list[AssetRecord]) -> None:
    save(records, panel((300, 648), TEAL, 246, 0), "ui/left_rail.png", "visual.art24.ui.left_rail", "deterministic ART24 generator", "hud_panel", "normal", "default", "art24_hud")
    save(records, panel((1280, 72), BRASS, 248, 0), "ui/bottom_bar.png", "visual.art24.ui.bottom_bar", "deterministic ART24 generator", "hud_panel", "normal", "default", "art24_hud")
    protocol_colors = {5: TEAL, 4: GREEN, 3: AMBER, 2: ORANGE, 1: RED}
    for level, accent in protocol_colors.items():
        image = panel((230, 118), accent, 246, 7)
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle((10, 10, 220, 108), radius=4, fill=(*accent[:3], 18))
        save(records, image, f"ui/protocol/level_{level}.png", f"visual.art24.ui.protocol.level_{level}", "deterministic ART24 generator", "protocol_panel", f"level_{level}", "default", "art24_hud")

    save(records, panel((720, 600), TEAL, 250, 10), "ui/map_frame.png", "visual.art24.ui.map_frame", "deterministic ART24 generator", "map_overlay", "normal", "default", "art24_map")
    save(records, panel((760, 560), BRASS, 250, 10), "ui/modal_frame.png", "visual.art24.ui.modal_frame", "deterministic ART24 generator", "modal_panel", "normal", "default", "art24_modal")

    for state in ("normal", "selected", "blocked"):
        save(records, state_surface((620, 60), state, 6), f"ui/item_row_{state}.png", f"visual.art24.ui.item_row.{state}", "deterministic ART24 generator", "item_row", state, "default", "art24_modal")
    for state in ("normal", "selected", "blocked", "rare", "unique"):
        save(records, state_surface((72, 72), state, 6), f"ui/item_slot_{state}.png", f"visual.art24.ui.item_slot.{state}", "deterministic ART24 generator", "item_slot", state, "default", "art24_modal")
    for state in ("normal", "warning"):
        save(records, state_surface((620, 100), state, 7), f"ui/tooltip_{state}.png", f"visual.art24.ui.tooltip.{state}", "deterministic ART24 generator", "tooltip", state, "default", "art24_modal")
    for state in ("info", "success", "warning", "danger"):
        surface_state = {"info": "selected", "success": "selected", "warning": "warning", "danger": "blocked"}[state]
        image = state_surface((480, 52), surface_state, 7)
        save(records, image, f"ui/toast_{state}.png", f"visual.art24.ui.toast.{state}", "deterministic ART24 generator", "toast", state, "default", "art24_feedback")
    for state, accent in (("success", TEAL), ("failure", RED), ("abandoned", AMBER)):
        save(records, panel((520, 120), accent, 252, 9), f"ui/result_banner_{state}.png", f"visual.art24.ui.result_banner.{state}", "deterministic ART24 generator", "result_banner", state, "default", "art24_result")
    for state in ("normal", "pressed", "disabled"):
        save(records, state_surface((56, 40), state, 6), f"ui/keycap_{state}.png", f"visual.art24.ui.keycap.{state}", "deterministic ART24 generator", "keycap", state, "default", "art24_hud")

    tile_states = {
        "unknown": (48, 50, 46, 255),
        "scanned": (24, 82, 82, 255),
        "explored": (42, 100, 96, 255),
        "selected": (25, 152, 148, 255),
        "flagged": (110, 69, 32, 255),
        "danger": (116, 42, 34, 255),
        "player": (73, 130, 117, 255),
    }
    for state, fill in tile_states.items():
        image = Image.new("RGBA", (42, 42), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        accent = TEAL if state in {"selected", "player"} else (RED if state == "danger" else BRASS)
        draw.rounded_rectangle((1, 1, 40, 40), radius=3, fill=fill, outline=BRASS_DARK, width=3)
        draw.rounded_rectangle((5, 5, 36, 36), radius=2, outline=accent, width=1)
        if state == "flagged":
            draw.polygon(((14, 10), (29, 16), (14, 22)), fill=AMBER)
            draw.line((14, 10, 14, 31), fill=BRASS_LIGHT, width=2)
        elif state == "danger":
            draw.ellipse((12, 12, 29, 29), fill=RED, outline=(255, 135, 73, 255), width=2)
        elif state == "player":
            draw.polygon(((21, 8), (32, 21), (21, 34), (10, 21)), fill=TEAL, outline=(185, 255, 235, 255))
        save(records, image, f"ui/map_tile_{state}.png", f"visual.art24.ui.map_tile.{state}", "deterministic ART24 generator", "map_tile", state, "default", "art24_map")


def build_fx(records: list[AssetRecord]) -> None:
    for index in range(8):
        image = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        radius = 46 + index * 6
        alpha = max(18, 150 - index * 16)
        draw.ellipse((96 - radius, 96 - radius, 96 + radius, 96 + radius), outline=(*TEAL[:3], alpha), width=max(2, 5 - index // 3))
        save(records, image, f"fx/scan_ring_{index}.png", f"visual.art24.fx.scan_ring.{index}", "deterministic ART24 generator", "scan_fx", str(index), "default", "art24_fx")

    for index in range(6):
        image = Image.new("RGBA", (256, 192), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        progress = index / 5.0
        end_angle = -58 + int(progress * 128)
        alpha = int(80 + 165 * (1.0 - abs(progress - 0.6)))
        for inset, width, color in ((0, 8, TEAL), (10, 4, BRASS_LIGHT), (18, 2, (245, 247, 231, 255))):
            draw.arc((18 + inset, -28 + inset, 244 - inset, 218 - inset), -70, end_angle, fill=(*color[:3], min(255, alpha)), width=width)
        if index >= 3:
            impact = (215, 94)
            for ray in range(8):
                angle = ray * math.pi / 4.0
                length = 10 + (index - 2) * 7
                draw.line((impact[0], impact[1], impact[0] + math.cos(angle) * length, impact[1] + math.sin(angle) * length), fill=(*BRASS_LIGHT[:3], max(70, 230 - index * 22)), width=3)
        save(records, image, f"fx/combat_slash_{index}.png", f"visual.art24.fx.combat_slash.{index}", "deterministic ART24 generator", "combat_fx", str(index), "default", "art24_fx")

    for index in range(6):
        image = Image.new("RGBA", (176, 176), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        progress = (index + 1) / 6.0
        center = 88
        radius = 30 + index * 9
        alpha = int(95 + 120 * (1.0 - abs(progress - 0.65)))
        draw.ellipse((center - radius, center - radius, center + radius, center + radius), outline=(*AMBER[:3], alpha), width=max(3, 8 - index))
        draw.ellipse((center - radius // 2, center - radius // 2, center + radius // 2, center + radius // 2), fill=(*BRASS_LIGHT[:3], 18 + index * 7))
        for ray in range(8):
            angle = ray * math.pi / 4.0
            inner = radius + 4
            outer = radius + 14 + index * 2
            draw.line((center + math.cos(angle) * inner, center + math.sin(angle) * inner, center + math.cos(angle) * outer, center + math.sin(angle) * outer), fill=(*BRASS_LIGHT[:3], max(60, alpha - 20)), width=3)
        save(records, image, f"fx/chest_opening_{index}.png", f"visual.art24.fx.chest_opening.{index}", "deterministic ART24 generator", "chest_fx", str(index), "default", "art24_fx")

    for index in range(8):
        image = Image.new("RGBA", (96, 144), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        phase = index / 7.0
        width = 10 + int(8 * (1.0 - abs(phase - 0.5) * 2.0))
        alpha = int(80 + 120 * (1.0 - abs(phase - 0.5) * 2.0))
        draw.polygon(((48 - width, 132), (48 + width, 132), (55, 26), (41, 26)), fill=(*AMBER[:3], alpha // 2))
        draw.ellipse((38 - index, 14 - index, 58 + index, 34 + index), fill=(*BRASS_LIGHT[:3], alpha), outline=(*AMBER[:3], min(255, alpha + 30)), width=2)
        save(records, image, f"fx/pickup_beam_{index}.png", f"visual.art24.fx.pickup_beam.{index}", "deterministic ART24 generator", "pickup_fx", str(index), "default", "art24_fx")

    for index in range(6):
        image = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        radius = 24 + index * 19
        alpha = max(25, 230 - index * 38)
        draw.ellipse((128 - radius, 128 - radius, 128 + radius, 128 + radius), outline=(*ORANGE[:3], alpha), width=max(2, 10 - index))
        for ray in range(8):
            dx = (ray % 3 - 1) * radius
            dy = ((ray * 2) % 3 - 1) * radius
            draw.line((128, 128, 128 + dx, 128 + dy), fill=(*RED[:3], alpha), width=4)
        save(records, image, f"fx/mine_burst_{index}.png", f"visual.art24.fx.mine_burst.{index}", "deterministic ART24 generator", "mine_fx", str(index), "default", "art24_fx")

    for index in range(8):
        image = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        radius = 54 + (index % 4) * 9
        alpha = 130 - (index % 4) * 20
        draw.ellipse((128 - radius, 128 - radius, 128 + radius, 128 + radius), outline=(*TEAL[:3], alpha), width=6)
        draw.ellipse((96, 96, 160, 160), fill=(*TEAL[:3], 22 + (index % 4) * 8))
        save(records, image, f"fx/beacon_pulse_{index}.png", f"visual.art24.fx.beacon_pulse.{index}", "deterministic ART24 generator", "beacon_fx", str(index), "default", "art24_fx")

    rng = random.Random(240724)
    dust_points = [(rng.randrange(20, 620), rng.randrange(10, 350), rng.randrange(1, 4), rng.randrange(35, 105)) for _ in range(34)]
    for index in range(8):
        image = Image.new("RGBA", (640, 360), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        for x, y, radius, alpha in dust_points:
            px = (x + index * (radius + 1) * 2) % 640
            py = (y - index * (radius + 1)) % 360
            color = TEAL if (x + y) % 5 == 0 else BRASS_LIGHT
            draw.ellipse((px - radius, py - radius, px + radius, py + radius), fill=(*color[:3], alpha))
        image = image.filter(ImageFilter.GaussianBlur(0.45))
        save(records, image, f"fx/ambient_dust_{index}.png", f"visual.art24.fx.ambient_dust.{index}", "deterministic ART24 generator", "ambient_fx", str(index), "default", "art24_fx")


def write_reports(records: list[AssetRecord]) -> None:
    VALIDATION.mkdir(parents=True, exist_ok=True)
    report_fields = ["asset_id", "visual_key", "runtime_path", "source", "role", "state", "variant", "load_group", "width", "height", "decoded_bytes", "alpha_coverage", "sha256", "source_status"]
    report_rows: list[dict[str, str]] = []
    for record in records:
        with Image.open(record.path) as image:
            rgba = image.convert("RGBA")
            alpha = rgba.getchannel("A")
            nontransparent = sum(1 for value in alpha.get_flattened_data() if value > 0)
            total_pixels = rgba.width * rgba.height
            report_rows.append({
                "asset_id": record.asset_id,
                "visual_key": record.visual_key,
                "runtime_path": "res://" + record.path.relative_to(GODOT).as_posix(),
                "source": record.source,
                "role": record.role,
                "state": record.state,
                "variant": record.variant,
                "load_group": record.load_group,
                "width": str(rgba.width),
                "height": str(rgba.height),
                "decoded_bytes": str(total_pixels * 4),
                "alpha_coverage": f"{nontransparent / total_pixels:.6f}",
                "sha256": sha256(record.path),
                "source_status": record.source_status,
            })
    with REPORT_CSV.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=report_fields)
        writer.writeheader()
        writer.writerows(report_rows)

    manifest_fields = ["asset_id", "source_repo_path", "godot_path", "type", "category", "usage", "import_preset", "license_status", "replacement_needed", "linked_scene", "linked_data", "note", "theme_key", "presentation_role", "state", "variant", "source_status"]
    manifest_rows = []
    for row in report_rows:
        manifest_rows.append({
            "asset_id": row["asset_id"],
            "source_repo_path": row["source"],
            "godot_path": row["runtime_path"],
            "type": "texture",
            "category": "ui_art" if row["role"].endswith(("panel", "row", "slot", "toast", "tile", "keycap", "banner")) else "sprite",
            "usage": f"ART24 {row['role']} {row['state']}",
            "import_preset": "pixel_ui",
            "license_status": "internal_generated",
            "replacement_needed": "false",
            "linked_scene": "scripts/presentation/art24/art24_in_run_preview.gd",
            "linked_data": "ART24_RUN_PRESENTATION_INTERFACE_V1",
            "note": f"ART24 modular art fragment; sha256={row['sha256']}",
            "theme_key": row["visual_key"],
            "presentation_role": row["role"],
            "state": row["state"],
            "variant": row["load_group"],
            "source_status": row["source_status"],
        })
    with MANIFEST_FRAGMENT.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=manifest_fields)
        writer.writeheader()
        writer.writerows(manifest_rows)

    reuse_rows = []
    for asset_id, godot_path, role, state in REUSED:
        runtime_path = GODOT / godot_path.removeprefix("res://")
        reuse_rows.append({
            "asset_id": asset_id,
            "godot_path": godot_path,
            "role": role,
            "state": state,
            "exists": str(runtime_path.is_file()).lower(),
            "sha256": sha256(runtime_path) if runtime_path.is_file() else "",
            "decision": "reuse_audited_for_art24",
        })
    with REUSE_REPORT.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=["asset_id", "godot_path", "role", "state", "exists", "sha256", "decision"])
        writer.writeheader()
        writer.writerows(reuse_rows)

    total_decoded = sum(int(row["decoded_bytes"]) for row in report_rows)
    by_group: dict[str, int] = {}
    for row in report_rows:
        by_group[row["load_group"]] = by_group.get(row["load_group"], 0) + int(row["decoded_bytes"])
    summary = {
        "stage": "ART24",
        "new_runtime_assets": len(report_rows),
        "reused_runtime_assets": len(reuse_rows),
        "total_decoded_bytes": total_decoded,
        "total_decoded_mib": round(total_decoded / (1024 * 1024), 2),
        "decoded_mib_by_load_group": {key: round(value / (1024 * 1024), 2) for key, value in sorted(by_group.items())},
        "all_reused_exist": all(row["exists"] == "true" for row in reuse_rows),
        "manifest_policy": "fragment_only_no_global_manifest_edit",
    }
    REPORT_JSON.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_runtime_state_contract() -> None:
    with STATE_MATRIX_SOURCE.open("r", encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    STATE_MATRIX_RUNTIME.parent.mkdir(parents=True, exist_ok=True)
    STATE_MATRIX_RUNTIME.write_text(STATE_MATRIX_SOURCE.read_text(encoding="utf-8"), encoding="utf-8")
    lines = [
        "extends RefCounted",
        "class_name Art24StateCatalog",
        "",
        "const STATES := [",
    ]
    for row in rows:
        lines.append(
            "\t{\"primary_id\": &\"%s\", \"secondary_id\": &\"%s\", \"room_type\": &\"%s\", \"visual_state\": &\"%s\", \"active_modal\": &\"%s\", \"protocol_level\": %d, \"reduce_motion\": %s},"
            % (
                row["primary_id"], row["secondary_id"], row["room_type"], row["visual_state"], row["active_modal"],
                int(row["protocol_level"]), "true" if row["reduce_motion"].lower() == "true" else "false",
            )
        )
    lines.extend([
        "]",
        "",
        "static func state_ids() -> Array[StringName]:",
        "\tvar result: Array[StringName] = []",
        "\tfor entry: Dictionary in STATES:",
        "\t\tresult.append(StringName(entry.secondary_id))",
        "\treturn result",
        "",
        "static func state_for(state_id: StringName) -> Dictionary:",
        "\tfor entry: Dictionary in STATES:",
        "\t\tif StringName(entry.secondary_id) == state_id:",
        "\t\t\treturn entry.duplicate(true)",
        "\treturn (STATES[0] as Dictionary).duplicate(true)",
        "",
        "static func first_index_for_primary(primary_id: StringName) -> int:",
        "\tfor index in range(STATES.size()):",
        "\t\tif StringName((STATES[index] as Dictionary).primary_id) == primary_id:",
        "\t\t\treturn index",
        "\treturn 0",
        "",
    ])
    STATE_CATALOG_GD.parent.mkdir(parents=True, exist_ok=True)
    STATE_CATALOG_GD.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    records: list[AssetRecord] = []
    build_actor_and_loot(records)
    build_ui(records)
    build_fx(records)
    write_reports(records)
    write_runtime_state_contract()
    print(f"ART24_ART_PACK_ASSETS={len(records)}")
    print(REPORT_JSON.read_text(encoding="utf-8").strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
