#!/usr/bin/env python3
"""Build the incremental ART25 M7 content-art pack.

The builder keeps ART22/ART23 accepted source packs immutable. It creates small,
semantic runtime images under assets/ui/art25, emits a deterministic report and
manifest fragment, then replaces only ui.art25.* rows in the global manifest.
"""

from __future__ import annotations

import csv
import hashlib
import json
from dataclasses import asdict, dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / "Godot/GraytailGodot"
ASSET_ROOT = GODOT / "assets/ui/art25/content"
VALIDATION_ROOT = ROOT / "docs/art/validation/art25"
MANIFEST = GODOT / "data/assets/asset_manifest.csv"
FRAGMENT = VALIDATION_ROOT / "art25_asset_manifest_fragment.csv"
REPORT_CSV = VALIDATION_ROOT / "art25_runtime_asset_report.csv"
REPORT_JSON = VALIDATION_ROOT / "art25_runtime_asset_report.json"
CONTACT_SHEET = VALIDATION_ROOT / "art25_asset_contact_sheet.png"

MANIFEST_FIELDS = [
    "asset_id", "source_repo_path", "godot_path", "type", "category", "usage",
    "import_preset", "license_status", "replacement_needed", "linked_scene",
    "linked_data", "note", "theme_key", "presentation_role", "state", "variant",
    "source_status",
]

MAPS = [
    ("classic_7x7_simple", 7, "simple"),
    ("classic_7x7_normal", 7, "normal"),
    ("classic_10x10_easy", 10, "easy"),
    ("classic_10x10_standard", 10, "standard"),
    ("classic_10x10_hard", 10, "hard"),
    ("classic_13x13_normal", 13, "normal"),
    ("classic_13x13_hard", 13, "hard"),
    ("classic_13x13_hell", 13, "hell"),
]

COMMISSIONS = [
    ("commission_recover_supply", "crate"),
    ("commission_route_survey", "route"),
    ("commission_anomaly_cleanup", "claw"),
    ("commission_open_crates", "key"),
    ("commission_event_evidence", "document"),
    ("commission_critical_extract", "beacon"),
]

SHOP_SOURCES = {
    "con_ration": "assets/items/recovered/data_disk.png",
    "con_tape_roll": "assets/items/recovered/broken_copper_wire.png",
    "con_scan_pin": "assets/items/consumable/item_consumable_syringe.png",
    "con_med_patch": "assets/items/consumable/item_consumable_medkit.png",
    "con_calm_candy": "assets/items/loadout/lucky_coin.png",
    "con_stabilizer": "assets/items/recovered/dim_capacitor.png",
    "eq_goggles": "assets/items/equipment/item_equipment_goggles.png",
    "eq_insulated_sleeve": "assets/items/recovered/static_lens.png",
    "eq_old_vest": "assets/items/loadout/company_badge.png",
    "eq_recovery_bag": "assets/items/loadout/overload_parts_box.png",
}

TASKS = [
    "task_first_survey", "task_risk_mark", "task_supply_recovery",
    "task_clear_anomaly", "task_complete_commission", "task_prepared_deploy",
    "task_sample_research", "task_failure_salvage",
]

TASK_GLYPHS = {
    "task_first_survey": "route",
    "task_risk_mark": "event",
    "task_supply_recovery": "crate",
    "task_clear_anomaly": "claw",
    "task_complete_commission": "document",
    "task_prepared_deploy": "key",
    "task_sample_research": "research",
    "task_failure_salvage": "beacon",
}

ACHIEVEMENTS = [
    "achievement_first_return", "achievement_clean_route",
    "achievement_critical_return", "achievement_low_hp_return",
    "achievement_chest_expert", "achievement_anomaly_sweep",
    "achievement_measured_greed", "achievement_four_events",
]

ACHIEVEMENT_GLYPHS = {
    "achievement_first_return": "beacon",
    "achievement_clean_route": "route",
    "achievement_critical_return": "extract",
    "achievement_low_hp_return": "event",
    "achievement_chest_expert": "chest",
    "achievement_anomaly_sweep": "claw",
    "achievement_measured_greed": "collection",
    "achievement_four_events": "document",
}

RESEARCH = [
    "research_anomaly_structure", "research_protocol_formula",
    "research_extraction_signal",
]

PROFILE = ["1", "2", "3", "4", "5"]
COLLECTIONS = ["collection_old_work", "collection_anomaly_machine", "collection_deep_protocol"]
RULES = [
    "mines_and_movement", "extraction_right", "protocol_pressure",
    "backpack_and_salvage", "settlement_outcomes",
]
EVENTS = ["trader", "dice", "altar", "trap"]
MONSTERS = ["slime", "slimeling", "bat", "drone"]

MONSTER_SOURCES = {
    "slime": "assets/art24/actors/slime/ue_idle.png",
    "slimeling": "assets/art24/actors/slime/ue_slimeling_idle.png",
    "bat": "assets/art24/actors/bat/ue_idle.png",
    "drone": "assets/art24/actors/drone/ue_idle.png",
}

ITEM_SOURCE_POOL = [
    "assets/items/recovered/old_gear.png",
    "assets/items/recovered/old_gauge.png",
    "assets/items/recovered/dead_battery.png",
    "assets/items/recovered/data_disk.png",
    "assets/items/recovered/damaged_circuit.png",
    "assets/items/recovered/broken_terminal.png",
    "assets/items/recovered/fluorescent_shard.png",
    "assets/items/recovered/anomaly_core_shard.png",
    "assets/items/recovered/whisper_wick.png",
    "assets/items/recovered/static_lens.png",
    "assets/items/recovered/sealed_core_shard.png",
    "assets/items/recovered/blackbox_tag.png",
    "assets/items/recovered/broken_copper_wire.png",
    "assets/items/recovered/dim_capacitor.png",
    "assets/items/recovered/item_recovered_ore.png",
]

ALL_ITEM_IDS = [
    "eq_old_vest", "eq_edge_opener", "eq_recovery_bag", "eq_goggles",
    "eq_signal_pin", "eq_insulated_sleeve", "con_ration", "con_med_patch",
    "con_tape_roll", "con_scan_pin", "con_calm_candy", "con_stabilizer",
] + [f"col_{index:02d}" for index in range(1, 25)] + [
    "mon_old_gear_set", "mon_broken_patrol_badge", "mon_overheated_core",
    "mon_loader_black_box", "mon_abnormal_instruction", "sp_altar_residue",
]

PALETTE = {
    "ink": (5, 15, 17, 255),
    "panel": (11, 31, 32, 244),
    "panel_2": (20, 50, 48, 245),
    "brass": (192, 126, 26, 255),
    "gold": (240, 184, 64, 255),
    "teal": (25, 183, 169, 255),
    "cyan": (89, 229, 211, 255),
    "danger": (190, 53, 35, 255),
    "paper": (204, 180, 126, 255),
}

DIFFICULTY_ACCENT = {
    "simple": (72, 190, 144, 255),
    "easy": (72, 190, 144, 255),
    "normal": (59, 174, 190, 255),
    "standard": (225, 167, 55, 255),
    "hard": (218, 92, 38, 255),
    "hell": (178, 45, 61, 255),
}


@dataclass(frozen=True)
class AssetRecord:
    asset_id: str
    visual_key: str
    runtime_path: str
    source: str
    role: str
    state: str
    load_group: str
    width: int
    height: int
    decoded_bytes: int
    sha256: str


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def fit_source(relative: str, size: tuple[int, int], tint: tuple[int, int, int] | None = None) -> Image.Image:
    source = Image.open(GODOT / relative).convert("RGBA")
    bbox = source.getchannel("A").getbbox()
    if bbox:
        source = source.crop(bbox)
    source.thumbnail(size, Image.Resampling.LANCZOS)
    if tint is not None:
        gray = ImageOps.grayscale(source)
        color = ImageOps.colorize(gray, black=(18, 22, 25), white=tint).convert("RGBA")
        color.putalpha(source.getchannel("A"))
        source = color
    return source


def frame_icon(subject: Image.Image | None, accent: tuple[int, int, int, int], glyph: str, badge: int = 0) -> Image.Image:
    image = Image.new("RGBA", (72, 72), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((3, 3, 68, 68), radius=7, fill=PALETTE["ink"], outline=PALETTE["brass"], width=2)
    draw.rounded_rectangle((8, 8, 63, 63), radius=5, fill=PALETTE["panel_2"], outline=accent, width=1)
    draw.line((12, 58, 59, 58), fill=(112, 75, 24, 255), width=2)
    for x, y in ((5, 5), (62, 5), (5, 62), (62, 62)):
        draw.rectangle((x, y, x + 4, y + 4), fill=PALETTE["gold"])
    if subject is not None:
        x = (72 - subject.width) // 2
        y = 8 + (48 - subject.height) // 2
        image.alpha_composite(subject, (x, y))
    else:
        draw_glyph(draw, glyph, accent)
    if badge:
        draw.ellipse((51, 49, 66, 64), fill=PALETTE["ink"], outline=accent, width=2)
        for offset in range(min(badge, 4)):
            draw.rectangle((55 + (offset % 2) * 5, 54 + (offset // 2) * 5, 57 + (offset % 2) * 5, 56 + (offset // 2) * 5), fill=accent)
    return image


def draw_glyph(draw: ImageDraw.ImageDraw, glyph: str, accent: tuple[int, int, int, int]) -> None:
    gold = PALETTE["gold"]
    if glyph in {"route", "survey"}:
        points = [(19, 48), (28, 32), (39, 39), (52, 19)]
        draw.line(points, fill=accent, width=5, joint="curve")
        for x, y in points:
            draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=PALETTE["ink"], outline=gold, width=2)
    elif glyph in {"crate", "chest"}:
        draw.rectangle((18, 27, 54, 51), fill=(88, 54, 27, 255), outline=gold, width=3)
        draw.rectangle((16, 21, 56, 31), fill=(110, 67, 31, 255), outline=accent, width=2)
        draw.rectangle((32, 29, 40, 39), fill=gold)
    elif glyph == "claw":
        for x in (22, 32, 42):
            draw.arc((x - 7, 16, x + 12, 54), 258, 75, fill=accent, width=4)
        draw.ellipse((24, 42, 48, 56), fill=(92, 39, 34, 255), outline=gold, width=2)
    elif glyph == "key":
        draw.ellipse((17, 20, 37, 40), outline=gold, width=5)
        draw.line((33, 36, 54, 55), fill=accent, width=6)
        draw.line((45, 47, 51, 41), fill=accent, width=4)
    elif glyph == "document":
        draw.polygon([(20, 14), (45, 14), (54, 23), (54, 57), (20, 57)], fill=(190, 169, 115, 255), outline=gold)
        draw.line((45, 14, 45, 24, 54, 24), fill=PALETTE["ink"], width=2)
        for y in (31, 39, 47):
            draw.line((26, y, 47, y), fill=(57, 81, 74, 255), width=2)
    elif glyph in {"beacon", "extract"}:
        draw.polygon([(36, 13), (49, 50), (23, 50)], fill=(77, 58, 31, 255), outline=gold)
        draw.ellipse((31, 18, 41, 28), fill=accent)
        draw.arc((17, 14, 55, 50), 205, 335, fill=accent, width=3)
    elif glyph == "research":
        draw.ellipse((27, 17, 45, 35), outline=accent, width=4)
        draw.line((36, 35, 36, 52), fill=gold, width=4)
        draw.line((24, 52, 48, 52), fill=gold, width=4)
        draw.arc((17, 10, 55, 49), 205, 335, fill=accent, width=2)
    elif glyph == "profile":
        draw.ellipse((27, 15, 45, 33), fill=accent, outline=gold, width=2)
        draw.polygon([(18, 55), (23, 38), (36, 33), (49, 38), (54, 55)], fill=(51, 101, 92, 255), outline=gold)
    elif glyph == "collection":
        draw.polygon([(36, 13), (43, 28), (59, 31), (47, 42), (50, 58), (36, 50), (22, 58), (25, 42), (13, 31), (29, 28)], fill=accent, outline=gold)
    elif glyph == "rule":
        draw.ellipse((17, 17, 55, 55), outline=gold, width=3)
        draw.line((36, 20, 36, 51), fill=accent, width=4)
        draw.line((20, 36, 51, 36), fill=accent, width=4)
    elif glyph == "event":
        draw.polygon([(36, 13), (57, 51), (15, 51)], fill=(87, 47, 38, 255), outline=gold)
        draw.rectangle((33, 25, 39, 39), fill=accent)
        draw.rectangle((33, 44, 39, 49), fill=accent)
    elif glyph == "achievement":
        draw.ellipse((20, 15, 52, 47), fill=(94, 59, 21, 255), outline=gold, width=3)
        draw.polygon([(36, 20), (40, 31), (52, 31), (42, 38), (46, 49), (36, 42), (26, 49), (30, 38), (20, 31), (32, 31)], fill=accent)
        draw.polygon([(26, 45), (22, 59), (34, 53)], fill=gold)
        draw.polygon([(46, 45), (50, 59), (38, 53)], fill=gold)
    else:
        draw.ellipse((20, 20, 52, 52), outline=gold, width=3)
        draw.line((27, 36, 45, 36), fill=accent, width=4)


def build_map(map_id: str, size: int, difficulty: str) -> Image.Image:
    base = Image.open(GODOT / "assets/ui/art22/deploy_prep/routes/classic_grid.png").convert("RGBA")
    base = ImageEnhance.Brightness(base).enhance(0.62)
    image = base.copy()
    draw = ImageDraw.Draw(image)
    accent = DIFFICULTY_ACCENT[difficulty]
    draw.rounded_rectangle((4, 4, 139, 87), radius=6, outline=accent, width=2)
    left, top, right, bottom = 17, 13, 101, 79
    cells = 7 if size == 7 else (9 if size == 10 else 11)
    step_x = max(5, (right - left) // cells)
    step_y = max(4, (bottom - top) // cells)
    grid_w = step_x * cells
    grid_h = step_y * cells
    gx = left + (right - left - grid_w) // 2
    gy = top + (bottom - top - grid_h) // 2
    draw.rectangle((gx - 3, gy - 3, gx + grid_w + 3, gy + grid_h + 3), fill=(4, 17, 18, 210), outline=PALETTE["brass"])
    for index in range(cells + 1):
        draw.line((gx + index * step_x, gy, gx + index * step_x, gy + grid_h), fill=(50, 86, 79, 220))
        draw.line((gx, gy + index * step_y, gx + grid_w, gy + index * step_y), fill=(50, 86, 79, 220))
    route = []
    for index in range(cells):
        route.append((gx + index * step_x + step_x // 2, gy + ((index * 3 + size) % cells) * step_y + step_y // 2))
    draw.line(route, fill=accent, width=2, joint="curve")
    for x, y in route[::max(1, cells // 4)]:
        draw.rectangle((x - 2, y - 2, x + 2, y + 2), fill=PALETTE["gold"])
    danger_count = {"simple": 1, "easy": 1, "normal": 2, "standard": 3, "hard": 4, "hell": 5}[difficulty]
    for index in range(danger_count):
        x = gx + ((index * 5 + 2) % cells) * step_x + step_x // 2
        y = gy + ((index * 7 + 1) % cells) * step_y + step_y // 2
        draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=PALETTE["danger"])
    draw.rectangle((111, 16, 130, 66), fill=(5, 16, 17, 235), outline=PALETTE["brass"])
    for index in range(3):
        y = 23 + index * 14
        color = accent if index < (1 + danger_count // 2) else (63, 75, 70, 255)
        draw.rectangle((116, y, 125, y + 7), fill=color, outline=PALETTE["gold"] if index == 0 else color)
    return image


def save_asset(records: list[AssetRecord], image: Image.Image, relative: str, asset_id: str, visual_key: str, source: str, role: str, state: str, load_group: str) -> None:
    output = ASSET_ROOT / relative
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, optimize=True)
    width, height = image.size
    records.append(AssetRecord(
        asset_id=asset_id,
        visual_key=visual_key,
        runtime_path="res://" + output.relative_to(GODOT).as_posix(),
        source=source,
        role=role,
        state=state,
        load_group=load_group,
        width=width,
        height=height,
        decoded_bytes=width * height * 4,
        sha256=sha256(output),
    ))


def symbolic_series(records: list[AssetRecord], kind: str, ids: list[str], glyph: str, load_group: str, accent: tuple[int, int, int, int]) -> None:
    for index, item_id in enumerate(ids):
        image = frame_icon(None, accent, glyph, (index % 4) + 1).resize((56, 56), Image.Resampling.LANCZOS)
        save_asset(records, image, f"long_term/{kind}/{item_id}.png", f"ui.art25.long_term.{kind}.{item_id}", f"art25.long_term.{kind}.{item_id}", "tools/art25_build_content_art.py", f"long_term_{kind}", item_id, load_group)


def semantic_series(records: list[AssetRecord], kind: str, glyphs: dict[str, str], load_group: str, accent: tuple[int, int, int, int]) -> None:
    for index, (item_id, glyph) in enumerate(glyphs.items()):
        image = frame_icon(None, accent, glyph, (index % 4) + 1).resize((56, 56), Image.Resampling.LANCZOS)
        save_asset(records, image, f"long_term/{kind}/{item_id}.png", f"ui.art25.long_term.{kind}.{item_id}", f"art25.long_term.{kind}.{item_id}", "tools/art25_build_content_art.py", f"long_term_{kind}", item_id, load_group)


def build() -> list[AssetRecord]:
    records: list[AssetRecord] = []
    for map_id, size, difficulty in MAPS:
        image = build_map(map_id, size, difficulty)
        save_asset(records, image, f"deploy/maps/{map_id}.png", f"ui.art25.deploy.map.{map_id}", f"art25.deploy.map.{map_id}", "assets/ui/art22/deploy_prep/routes/classic_grid.png", "deploy_map_thumbnail", difficulty, "art25_deploy_map")

    for commission_id, glyph in COMMISSIONS:
        image = frame_icon(None, PALETTE["teal"], glyph)
        save_asset(records, image, f"deploy/commissions/{commission_id}.png", f"ui.art25.deploy.commission.{commission_id}", f"art25.deploy.commission.{commission_id}", "tools/art25_build_content_art.py", "deploy_commission_icon", commission_id, "art25_deploy_commission")

    for index, (item_id, source) in enumerate(SHOP_SOURCES.items()):
        tint = None if item_id in {"con_med_patch", "eq_goggles"} else DIFFICULTY_ACCENT[["simple", "normal", "standard", "hard"][index % 4]][:3]
        subject = fit_source(source, (48, 48), tint)
        image = frame_icon(subject, PALETTE["gold"] if item_id.startswith("eq_") else PALETTE["teal"], "item", (index % 3) + 1)
        save_asset(records, image, f"deploy/shop/{item_id}.png", f"ui.art25.deploy.shop.{item_id}", f"art25.deploy.shop.{item_id}", source, "deploy_shop_icon", item_id, "art25_deploy_shop")

    semantic_series(records, "task", TASK_GLYPHS, "art25_long_term_goals", PALETTE["teal"])
    semantic_series(records, "achievement", ACHIEVEMENT_GLYPHS, "art25_long_term_goals", PALETTE["gold"])
    symbolic_series(records, "research", RESEARCH, "research", "art25_long_term_research", PALETTE["cyan"])
    symbolic_series(records, "profile", PROFILE, "profile", "art25_long_term_profile", PALETTE["gold"])
    symbolic_series(records, "collection", COLLECTIONS, "collection", "art25_long_term_collection", PALETTE["teal"])
    symbolic_series(records, "rule", RULES, "rule", "art25_long_term_codex", PALETTE["gold"])
    symbolic_series(records, "event", EVENTS, "event", "art25_long_term_codex", PALETTE["danger"])

    for monster_id in MONSTERS:
        source = MONSTER_SOURCES[monster_id]
        source_path = GODOT / source
        if source_path.is_file():
            subject = fit_source(source, (50, 50))
            image = frame_icon(subject, PALETTE["danger"], "claw")
        else:
            image = frame_icon(None, PALETTE["danger"], "claw")
        image = image.resize((56, 56), Image.Resampling.LANCZOS)
        save_asset(records, image, f"long_term/monster/{monster_id}.png", f"ui.art25.long_term.monster.{monster_id}", f"art25.long_term.monster.{monster_id}", source if source_path.is_file() else "tools/art25_build_content_art.py", "long_term_monster", monster_id, "art25_long_term_codex")

    for index, item_id in enumerate(ALL_ITEM_IDS):
        if item_id in SHOP_SOURCES:
            source = SHOP_SOURCES[item_id]
        else:
            source = ITEM_SOURCE_POOL[index % len(ITEM_SOURCE_POOL)]
        tint = DIFFICULTY_ACCENT[["simple", "normal", "standard", "hard", "hell"][index % 5]][:3]
        subject = fit_source(source, (48, 48), tint if item_id.startswith("col_") else None)
        image = frame_icon(subject, DIFFICULTY_ACCENT[["simple", "normal", "standard", "hard", "hell"][index % 5]], "item", (index % 4) + 1)
        image = image.resize((56, 56), Image.Resampling.LANCZOS)
        save_asset(records, image, f"long_term/item/{item_id}.png", f"ui.art25.long_term.item.{item_id}", f"art25.long_term.item.{item_id}", source, "long_term_item", item_id, "art25_long_term_codex")

    unknown = frame_icon(None, (97, 112, 108, 255), "unknown").resize((56, 56), Image.Resampling.LANCZOS)
    save_asset(records, unknown, "long_term/unknown.png", "ui.art25.long_term.unknown", "art25.long_term.unknown", "tools/art25_build_content_art.py", "long_term_unknown", "unknown", "art25_long_term_default")
    return records


def write_reports(records: list[AssetRecord]) -> None:
    VALIDATION_ROOT.mkdir(parents=True, exist_ok=True)
    fields = list(AssetRecord.__dataclass_fields__.keys())
    with REPORT_CSV.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(asdict(record) for record in records)

    groups: dict[str, int] = {}
    for record in records:
        groups[record.load_group] = groups.get(record.load_group, 0) + record.decoded_bytes
    summary = {
        "stage": "ART25",
        "runtime_assets": len(records),
        "total_decoded_bytes": sum(record.decoded_bytes for record in records),
        "total_decoded_mib": round(sum(record.decoded_bytes for record in records) / (1024 * 1024), 2),
        "decoded_mib_by_load_group": {key: round(value / (1024 * 1024), 3) for key, value in sorted(groups.items())},
        "manifest_policy": "incremental_ui_art25_rows_only",
    }
    REPORT_JSON.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    write_contact_sheet(records)


def write_contact_sheet(records: list[AssetRecord]) -> None:
    columns = 8
    cell_w, cell_h = 164, 126
    rows = (len(records) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * cell_w, rows * cell_h), (8, 16, 18))
    draw = ImageDraw.Draw(sheet)
    for index, record in enumerate(records):
        x = (index % columns) * cell_w
        y = (index // columns) * cell_h
        draw.rectangle((x + 2, y + 2, x + cell_w - 3, y + cell_h - 3), outline=(98, 69, 25), width=2)
        runtime = GODOT / record.runtime_path.removeprefix("res://")
        art = Image.open(runtime).convert("RGBA")
        art.thumbnail((144, 82), Image.Resampling.LANCZOS)
        sheet.paste(art, (x + (cell_w - art.width) // 2, y + 7), art)
        label = record.asset_id.removeprefix("ui.art25.")
        while len(label) > 23:
            draw.text((x + 8, y + 92), label[:23], fill=(225, 190, 95))
            label = label[23:]
            y += 12
        draw.text((x + 8, y + 92), label, fill=(225, 190, 95))
    sheet.save(CONTACT_SHEET, optimize=True)


def manifest_rows(records: list[AssetRecord]) -> list[dict[str, str]]:
    result: list[dict[str, str]] = []
    for record in records:
        result.append({
            "asset_id": record.asset_id,
            "source_repo_path": record.source,
            "godot_path": record.runtime_path,
            "type": "texture",
            "category": "ui_art25_content",
            "usage": f"ART25 {record.role} {record.state}",
            "import_preset": "pixel_ui",
            "license_status": "internal_generated_from_audited_sources",
            "replacement_needed": "false",
            "linked_scene": "scripts/presentation/art25_content_asset_contract.gd",
            "linked_data": "M7ContentCatalog",
            "note": f"ART25 incremental content art; sha256={record.sha256}; decoded_bytes={record.decoded_bytes}; load_group={record.load_group}",
            "theme_key": record.visual_key,
            "presentation_role": record.role,
            "state": record.state,
            "variant": record.load_group,
            "source_status": "art25_generated_audited_reuse",
        })
    return result


def write_manifest(records: list[AssetRecord]) -> None:
    additions = manifest_rows(records)
    with FRAGMENT.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=MANIFEST_FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(additions)

    with MANIFEST.open("r", encoding="utf-8", newline="") as stream:
        existing = [row for row in csv.DictReader(stream) if not row["asset_id"].startswith("ui.art25.")]
    merged = existing + sorted(additions, key=lambda row: row["asset_id"])
    with MANIFEST.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=MANIFEST_FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(merged)


def main() -> int:
    records = build()
    write_reports(records)
    write_manifest(records)
    print(f"ART25_CONTENT_ASSETS={len(records)}")
    print(f"ART25_CONTENT_DECODED_MIB={sum(record.decoded_bytes for record in records) / (1024 * 1024):.2f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
