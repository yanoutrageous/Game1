#!/usr/bin/env python3
"""Build ART-21 UI placement contract assets and manifests.

The script is intentionally deterministic: the same component declaration drives
the external ART-21 staging/cut workspace, Godot runtime PNGs, manifest rows,
and the UI placement contract CSV.
"""

from __future__ import annotations

import csv
import hashlib
import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


REPO_ROOT = Path(__file__).resolve().parents[1]
EXTERNAL_ART21_ROOT = Path(r"D:\AGAME1\sources\art\ART-21")
STAGING_ROOT = EXTERNAL_ART21_ROOT / "01_staging_generated"
CUT_ROOT = EXTERNAL_ART21_ROOT / "03_cut_output"
MANIFEST_ROOT = EXTERNAL_ART21_ROOT / "_manifest"
RUNTIME_ROOT = REPO_ROOT / "Godot" / "GraytailGodot" / "assets" / "ui" / "art21"
ASSET_MANIFEST = REPO_ROOT / "Godot" / "GraytailGodot" / "data" / "assets" / "asset_manifest.csv"
CONTRACT_CSV = REPO_ROOT / "docs" / "art" / "validation" / "art21" / "ui_placement_contract.csv"


MANIFEST_FIELDS = [
    "asset_id",
    "source_repo_path",
    "godot_path",
    "type",
    "category",
    "usage",
    "import_preset",
    "license_status",
    "replacement_needed",
    "linked_scene",
    "linked_data",
    "note",
    "theme_key",
    "presentation_role",
    "state",
    "variant",
    "source_status",
]

CONTRACT_FIELDS = [
    "screen",
    "layer",
    "slot",
    "interaction_owner",
    "state",
    "visibility_rule",
    "input_rule",
    "intended_visual",
    "source_candidate",
    "cut_output",
    "runtime_asset",
    "asset_id",
    "visual_key",
    "consumer",
    "stretch_or_9slice",
    "fallback",
    "blocked_reason",
    "validation_screenshot",
]

VALIDATION_SCREENSHOT_BY_SCREEN = {
    "shared": "art21_cu_main_menu.png;art21_cu_deploy_prep.png;art21_cu_run_hud.png",
    "main_menu": "art21_cu_main_menu.png",
    "deploy_prep": "art21_cu_deploy_prep.png",
    "long_term": "art21_cu_long_term.png",
    "run_hud": "art21_cu_run_hud.png",
    "map_overlay": "art21_cu_map_overlay.png",
    "inventory": "art21_cu_inventory.png",
    "ground_loot": "art21_cu_ground_loot_not_triggered.png",
    "result": "art21_cu_result.png",
}


@dataclass(frozen=True)
class Component:
    screen: str
    layer: str
    slot: str
    visual_key: str
    asset_id: str
    runtime_rel: str
    size: tuple[int, int]
    kind: str
    state: str = "normal"
    variant: str = "art21"
    category: str = "ui_panel"
    role: str = "art21_component"
    usage: str = ""
    interaction_owner: str = "none"
    visibility_rule: str = "always_when_screen_visible"
    input_rule: str = "none"
    intended_visual: str = ""
    consumer: str = ""
    stretch: str = "9slice"
    fallback: str = "StyleBoxFlat fallback"
    blocked_reason: str = ""


COMPONENTS: list[Component] = [
    Component("shared", "content_panel", "page_frame", "shared.panel.page_frame.normal", "ui.art21.shared.panel.page_frame.normal", "shared/panels/ui_art21_shared_panel_page_frame_normal.png", (192, 192), "panel", usage="ART21 reusable page frame", role="art21_panel", intended_visual="Reusable page frame with heavy pixel edge and warm highlight", consumer="Art10UISkinKit"),
    Component("shared", "content_panel", "card_frame", "shared.panel.card.normal", "ui.art21.shared.panel.card.normal", "shared/panels/ui_art21_shared_panel_card_normal.png", (160, 120), "panel", usage="ART21 reusable card frame", role="art21_panel", intended_visual="Compact card frame for route/archive/inventory rows", consumer="Art10UISkinKit"),
    Component("shared", "content_panel", "slot_frame", "shared.panel.slot.normal", "ui.art21.shared.panel.slot.normal", "shared/panels/ui_art21_shared_panel_slot_normal.png", (96, 96), "slot", usage="ART21 reusable slot frame", role="art21_slot", intended_visual="Square slot frame for inventory/equipment/map module cells", consumer="Art10UISkinKit"),
    Component("shared", "status_card", "status_card", "shared.panel.status_card.normal", "ui.art21.shared.panel.status_card.normal", "shared/panels/ui_art21_shared_panel_status_card_normal.png", (180, 96), "status", usage="ART21 reusable status card", role="art21_panel", intended_visual="Small top-right status card plate", consumer="Art10UISkinKit"),
    Component("shared", "modal", "modal_frame", "shared.panel.modal.normal", "ui.art21.shared.panel.modal.normal", "shared/panels/ui_art21_shared_panel_modal_normal.png", (224, 160), "modal", usage="ART21 reusable modal frame", role="art21_modal", intended_visual="Blocking modal frame with stronger edge and readable center", consumer="InventoryPanel/GroundLootPanel/ResultPanel"),
    Component("shared", "floating_info", "tooltip_frame", "shared.panel.tooltip.normal", "ui.art21.shared.panel.tooltip.normal", "shared/panels/ui_art21_shared_panel_tooltip_normal.png", (160, 72), "tooltip", usage="ART21 reusable tooltip frame", role="art21_tooltip", intended_visual="Small object tooltip frame", consumer="RunSurface"),
    Component("shared", "action_bar", "button_primary_normal", "shared.button.primary.normal", "ui.art21.shared.button.primary.normal", "shared/buttons/ui_art21_shared_button_primary_normal.png", (220, 72), "button_primary", usage="ART21 primary button normal", role="art21_button", intended_visual="Large primary action plate", consumer="Art10UISkinKit", stretch="9slice"),
    Component("shared", "action_bar", "button_primary_hover", "shared.button.primary.hover", "ui.art21.shared.button.primary.hover", "shared/buttons/ui_art21_shared_button_primary_hover.png", (220, 72), "button_primary_hover", state="hover", usage="ART21 primary button hover", role="art21_button", intended_visual="Primary action hover state", consumer="Art10UISkinKit"),
    Component("shared", "action_bar", "button_primary_pressed", "shared.button.primary.pressed", "ui.art21.shared.button.primary.pressed", "shared/buttons/ui_art21_shared_button_primary_pressed.png", (220, 72), "button_primary_pressed", state="pressed", usage="ART21 primary button pressed", role="art21_button", intended_visual="Primary action pressed state", consumer="Art10UISkinKit"),
    Component("shared", "action_bar", "button_primary_disabled", "shared.button.primary.disabled", "ui.art21.shared.button.primary.disabled", "shared/buttons/ui_art21_shared_button_primary_disabled.png", (220, 72), "button_disabled", state="disabled", usage="ART21 primary button disabled", role="art21_button", intended_visual="Primary action disabled state", consumer="Art10UISkinKit"),
    Component("shared", "action_bar", "button_secondary_normal", "shared.button.secondary.normal", "ui.art21.shared.button.secondary.normal", "shared/buttons/ui_art21_shared_button_secondary_normal.png", (170, 52), "button_secondary", usage="ART21 secondary button normal", role="art21_button", intended_visual="Compact secondary button plate", consumer="Art10UISkinKit"),
    Component("shared", "action_bar", "button_secondary_selected", "shared.button.secondary.selected", "ui.art21.shared.button.secondary.selected", "shared/buttons/ui_art21_shared_button_secondary_selected.png", (170, 52), "button_selected", state="selected", usage="ART21 secondary button selected", role="art21_button", intended_visual="Selected compact button/tab plate", consumer="Art10UISkinKit"),
    Component("shared", "content_text", "tab_normal", "shared.tab.normal", "ui.art21.shared.tab.normal", "shared/buttons/ui_art21_shared_tab_normal.png", (150, 48), "tab", usage="ART21 tab normal", role="art21_tab", intended_visual="Top tab normal state", consumer="Art10UISkinKit"),
    Component("shared", "content_text", "tab_selected", "shared.tab.selected", "ui.art21.shared.tab.selected", "shared/buttons/ui_art21_shared_tab_selected.png", (150, 48), "tab_selected", state="selected", usage="ART21 tab selected", role="art21_tab", intended_visual="Top tab selected state", consumer="Art10UISkinKit"),
    Component("main_menu", "content_panel", "action_deck_frame", "main_menu.action_deck.frame", "ui.art21.main_menu.action_deck.frame", "main_menu/ui_art21_main_menu_action_deck_frame.png", (300, 420), "panel_tall", usage="ART21 main menu action deck frame", role="main_menu_action_deck", intended_visual="Solid right-side physical menu board", consumer="main_menu_shell.gd"),
    Component("deploy_prep", "character_display", "left_character_frame", "deploy.left_character_frame.replaced", "ui.art21.deploy.left_character_frame", "deploy/ui_art21_deploy_left_character_frame.png", (280, 596), "character_frame", usage="ART21 deploy left character frame", role="deploy_character_frame", intended_visual="Left character/readiness frame replacing ART20 blocked slot", consumer="deploy_prep_shell.gd", blocked_reason="ART20 deploy_left_character_frame replaced"),
    Component("deploy_prep", "content_panel", "center_route_wall", "deploy.route_wall.frame", "ui.art21.deploy.route_wall.frame", "deploy/ui_art21_deploy_route_wall_frame.png", (590, 380), "panel_wide", usage="ART21 deploy route wall", role="deploy_route_wall", intended_visual="Center map/route/mission wall", consumer="deploy_prep_shell.gd"),
    Component("deploy_prep", "status_card", "right_summary_panel", "deploy.summary_panel.frame", "ui.art21.deploy.summary_panel.frame", "deploy/ui_art21_deploy_summary_panel_frame.png", (286, 396), "panel_summary", usage="ART21 deploy summary panel", role="deploy_summary_panel", intended_visual="Right equipment/consumable/risk summary panel", consumer="deploy_prep_shell.gd"),
    Component("long_term", "character_display", "left_profile_frame", "long_term.profile_frame.replaced", "ui.art21.long_term.profile_frame", "long_term/ui_art21_long_term_profile_frame.png", (280, 596), "character_frame", usage="ART21 long term left profile frame", role="longterm_profile_frame", intended_visual="Left archive/profile frame replacing ART20 blocked slot", consumer="long_term_shell.gd", blocked_reason="ART20 longterm_left_character_profile replaced"),
    Component("long_term", "content_panel", "collection_wall", "long_term.collection_wall.frame", "ui.art21.long_term.collection_wall.frame", "long_term/ui_art21_long_term_collection_wall_frame.png", (590, 520), "panel_grid", usage="ART21 long term collection wall", role="longterm_collection_wall", intended_visual="Center collection wall/archive grid frame", consumer="long_term_shell.gd"),
    Component("long_term", "status_card", "right_detail_panel", "long_term.detail_panel.frame", "ui.art21.long_term.detail_panel.frame", "long_term/ui_art21_long_term_detail_panel_frame.png", (286, 548), "panel_summary", usage="ART21 long term detail panel", role="longterm_detail_panel", intended_visual="Right resource/reward/detail module frame", consumer="long_term_shell.gd"),
    Component("run_hud", "gameplay_viewport", "gameplay_viewport_background", "run.gameplay_viewport.background.replaced", "ui.art21.run.gameplay_viewport.background", "run/ui_art21_run_gameplay_viewport_background.png", (720, 720), "gameplay_bg", usage="ART21 run gameplay viewport background", role="run_gameplay_background", intended_visual="Large nearly square game stage background replacing ART20 blocked slot", consumer="run_surface.gd", stretch="cover", blocked_reason="ART20 run_gameplay_viewport_background replaced"),
    Component("run_hud", "status_card", "top_right_status_card", "run.status_card.frame", "ui.art21.run.status_card.frame", "run/ui_art21_run_status_card_frame.png", (244, 120), "status", usage="ART21 run status card frame", role="run_status_card", intended_visual="Small top-right protocol/status card", consumer="run_surface.gd"),
    Component("run_hud", "action_bar", "bottom_overlay", "run.bottom_overlay.frame", "ui.art21.run.bottom_overlay.frame", "run/ui_art21_run_bottom_overlay_frame.png", (940, 64), "bar", usage="ART21 run bottom action overlay", role="run_bottom_overlay", intended_visual="Bottom key/action overlay that does not shrink gameplay viewport", consumer="run_surface.gd"),
    Component("map_overlay", "overlay", "cell_unknown", "map_overlay.cell.unknown.replaced", "ui.art21.map.cell.unknown", "map/ui_art21_map_cell_unknown.png", (64, 64), "map_cell_unknown", usage="ART21 map unknown cell", category="ui_icon", role="map_overlay_cell", state="unknown", intended_visual="Unknown map cell in ART21 set", consumer="map_overlay_panel.gd", stretch="fixed_64", blocked_reason="ART20 map_overlay_cell_64_set replaced"),
    Component("map_overlay", "overlay", "cell_explored", "map_overlay.cell.explored.replaced", "ui.art21.map.cell.explored", "map/ui_art21_map_cell_explored.png", (64, 64), "map_cell_explored", usage="ART21 map explored cell", category="ui_icon", role="map_overlay_cell", state="explored", intended_visual="Explored map cell in ART21 set", consumer="map_overlay_panel.gd", stretch="fixed_64", blocked_reason="ART20 map_overlay_cell_64_set replaced"),
    Component("map_overlay", "overlay", "cell_scanned", "map_overlay.cell.scanned.replaced", "ui.art21.map.cell.scanned", "map/ui_art21_map_cell_scanned.png", (64, 64), "map_cell_scanned", usage="ART21 map scanned cell", category="ui_icon", role="map_overlay_cell", state="scanned", intended_visual="Scanned/number map cell in ART21 set", consumer="map_overlay_panel.gd", stretch="fixed_64", blocked_reason="ART20 map_overlay_cell_64_set replaced"),
    Component("map_overlay", "overlay", "cell_flagged", "map_overlay.cell.flagged.replaced", "ui.art21.map.cell.flagged", "map/ui_art21_map_cell_flagged.png", (64, 64), "map_cell_flagged", usage="ART21 map flagged cell", category="ui_icon", role="map_overlay_cell", state="flagged", intended_visual="Flagged map cell in ART21 set", consumer="map_overlay_panel.gd", stretch="fixed_64", blocked_reason="ART20 map_overlay_cell_64_set replaced"),
    Component("map_overlay", "overlay", "marker_event", "map_overlay.marker.event.replaced", "ui.art21.map.marker.event", "map/ui_art21_map_marker_event.png", (64, 64), "map_marker_event", usage="ART21 map event marker", category="ui_icon", role="map_overlay_marker", state="event", intended_visual="Dedicated event marker replacing ART19 scanned alias", consumer="map_overlay_panel.gd", stretch="fixed_64", blocked_reason="ART20 map_overlay_event_marker_64 replaced"),
    Component("map_overlay", "overlay", "marker_player", "map_overlay.marker.player", "ui.art21.map.marker.player", "map/ui_art21_map_marker_player.png", (64, 64), "map_marker_player", usage="ART21 map player marker", category="ui_icon", role="map_overlay_marker", state="player", intended_visual="Player marker in ART21 map set", consumer="map_overlay_panel.gd", stretch="fixed_64"),
    Component("map_overlay", "overlay", "marker_exit", "map_overlay.marker.exit", "ui.art21.map.marker.exit", "map/ui_art21_map_marker_exit.png", (64, 64), "map_marker_exit", usage="ART21 map exit marker", category="ui_icon", role="map_overlay_marker", state="exit", intended_visual="Exit marker in ART21 map set", consumer="map_overlay_panel.gd", stretch="fixed_64"),
    Component("map_overlay", "overlay", "marker_mine", "map_overlay.marker.mine", "ui.art21.map.marker.mine", "map/ui_art21_map_marker_mine.png", (64, 64), "map_marker_mine", usage="ART21 map mine marker", category="ui_icon", role="map_overlay_marker", state="mine", intended_visual="Mine marker in ART21 map set", consumer="map_overlay_panel.gd", stretch="fixed_64"),
    Component("map_overlay", "overlay", "marker_chest", "map_overlay.marker.chest", "ui.art21.map.marker.chest", "map/ui_art21_map_marker_chest.png", (64, 64), "map_marker_chest", usage="ART21 map chest marker", category="ui_icon", role="map_overlay_marker", state="chest", intended_visual="Chest marker in ART21 map set", consumer="map_overlay_panel.gd", stretch="fixed_64"),
    Component("inventory", "modal", "inventory_panel_frame", "inventory.panel.frame", "ui.art21.inventory.panel.frame", "inventory/ui_art21_inventory_panel_frame.png", (420, 440), "modal", usage="ART21 inventory overlay frame", role="inventory_panel", intended_visual="Inventory modal/overlay panel frame", consumer="inventory_panel.gd"),
    Component("ground_loot", "modal", "ground_loot_panel_frame", "ground_loot.panel.frame", "ui.art21.ground_loot.panel.frame", "ground_loot/ui_art21_ground_loot_panel_frame.png", (420, 420), "modal", usage="ART21 ground loot overlay frame", role="ground_loot_panel", intended_visual="Ground loot modal frame", consumer="ground_loot_panel.gd"),
    Component("result", "modal", "result_modal_frame", "result.modal.frame", "ui.art21.result.modal.frame", "result/ui_art21_result_modal_frame.png", (620, 440), "modal", usage="ART21 result modal frame", role="result_modal", intended_visual="Result modal frame", consumer="result_panel.gd"),
]


def ensure_dirs() -> None:
    for root in [STAGING_ROOT, CUT_ROOT, MANIFEST_ROOT, RUNTIME_ROOT, CONTRACT_CSV.parent]:
        root.mkdir(parents=True, exist_ok=True)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def rel_for_manifest(path: Path) -> str:
    try:
        return path.relative_to(Path(r"D:\AGAME1")).as_posix()
    except ValueError:
        return path.as_posix()


def draw_component(component: Component, output_path: Path) -> None:
    width, height = component.size
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if component.kind == "gameplay_bg":
        draw_gameplay_background(draw, width, height)
    elif component.kind.startswith("map_cell"):
        draw_map_cell(draw, width, height, component.kind)
    elif component.kind.startswith("map_marker"):
        draw_map_marker(draw, width, height, component.kind)
    elif component.kind.startswith("button") or component.kind.startswith("tab"):
        draw_button(draw, width, height, component.kind)
    elif component.kind == "bar":
        draw_panel(draw, width, height, fill=(18, 27, 31, 224), edge=(222, 170, 80, 230), accent=(81, 204, 180, 180), radius=10, cut=12)
        for x in range(20, width - 20, 52):
            draw.line((x, 12, x + 20, height - 12), fill=(81, 204, 180, 44), width=1)
    elif component.kind in {"character_frame", "panel_tall", "panel_wide", "panel_grid", "panel_summary", "modal", "tooltip", "status", "slot", "panel"}:
        palette = palette_for(component.kind)
        draw_panel(draw, width, height, **palette)
        if component.kind == "character_frame":
            draw_character_plate(draw, width, height)
        elif component.kind == "panel_grid":
            draw_collection_grid(draw, width, height)
        elif component.kind == "panel_wide":
            draw_route_wall(draw, width, height)
        elif component.kind == "panel_summary":
            draw_summary_modules(draw, width, height)
        elif component.kind == "slot":
            draw.line((14, height - 14, width - 14, 14), fill=(222, 170, 80, 72), width=2)
    else:
        draw_panel(draw, width, height, **palette_for("panel"))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path)


def palette_for(kind: str) -> dict:
    palettes = {
        "panel": dict(fill=(17, 27, 30, 226), edge=(87, 178, 158, 220), accent=(222, 170, 80, 180), radius=12, cut=12),
        "status": dict(fill=(22, 28, 32, 232), edge=(222, 170, 80, 230), accent=(87, 178, 158, 180), radius=10, cut=10),
        "slot": dict(fill=(24, 30, 33, 228), edge=(87, 178, 158, 220), accent=(222, 170, 80, 160), radius=8, cut=8),
        "modal": dict(fill=(20, 23, 29, 238), edge=(222, 170, 80, 238), accent=(161, 88, 72, 150), radius=12, cut=14),
        "tooltip": dict(fill=(18, 28, 30, 232), edge=(87, 178, 158, 220), accent=(222, 170, 80, 130), radius=8, cut=8),
        "character_frame": dict(fill=(18, 30, 30, 224), edge=(87, 178, 158, 232), accent=(222, 170, 80, 180), radius=14, cut=14),
        "panel_tall": dict(fill=(25, 26, 29, 230), edge=(222, 170, 80, 232), accent=(87, 178, 158, 160), radius=12, cut=14),
        "panel_wide": dict(fill=(18, 29, 31, 228), edge=(87, 178, 158, 226), accent=(222, 170, 80, 150), radius=12, cut=14),
        "panel_grid": dict(fill=(20, 30, 33, 228), edge=(87, 178, 158, 226), accent=(222, 170, 80, 150), radius=12, cut=14),
        "panel_summary": dict(fill=(25, 28, 31, 230), edge=(222, 170, 80, 228), accent=(87, 178, 158, 140), radius=12, cut=12),
    }
    return palettes.get(kind, palettes["panel"])


def draw_panel(draw: ImageDraw.ImageDraw, width: int, height: int, fill: tuple[int, int, int, int], edge: tuple[int, int, int, int], accent: tuple[int, int, int, int], radius: int, cut: int) -> None:
    draw.rounded_rectangle((0, 0, width - 1, height - 1), radius=radius, fill=fill, outline=edge, width=3)
    draw.rounded_rectangle((6, 6, width - 7, height - 7), radius=max(2, radius - 4), outline=(edge[0], edge[1], edge[2], 120), width=1)
    draw.line((cut, 2, width - cut, 2), fill=accent, width=2)
    draw.line((cut, height - 3, width - cut, height - 3), fill=(accent[0], accent[1], accent[2], 105), width=2)
    for x, y in [(0, 0), (width - cut, 0), (0, height - cut), (width - cut, height - cut)]:
        draw.line((x + 2, y + cut, x + cut, y + 2), fill=(accent[0], accent[1], accent[2], 165), width=2)


def draw_button(draw: ImageDraw.ImageDraw, width: int, height: int, kind: str) -> None:
    if "primary" in kind:
        fill = (78, 52, 24, 236)
        edge = (232, 178, 86, 242)
        accent = (92, 200, 176, 130)
    elif "selected" in kind:
        fill = (36, 48, 45, 232)
        edge = (95, 211, 181, 238)
        accent = (232, 178, 86, 190)
    else:
        fill = (28, 34, 38, 228)
        edge = (105, 122, 132, 214)
        accent = (92, 200, 176, 125)
    if "hover" in kind:
        fill = tuple(min(255, c + 18) if i < 3 else c for i, c in enumerate(fill))
    if "pressed" in kind:
        fill = tuple(max(0, c - 22) if i < 3 else c for i, c in enumerate(fill))
    if "disabled" in kind:
        fill = (34, 36, 39, 172)
        edge = (72, 78, 84, 172)
        accent = (112, 112, 112, 90)
    draw_panel(draw, width, height, fill, edge, accent, 10, 10)
    draw.polygon([(16, height // 2), (28, height // 2 - 8), (28, height // 2 + 8)], fill=accent)
    draw.polygon([(width - 16, height // 2), (width - 28, height // 2 - 8), (width - 28, height // 2 + 8)], fill=accent)


def draw_gameplay_background(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    draw.rectangle((0, 0, width, height), fill=(16, 24, 25, 255))
    step = max(32, width // 12)
    for x in range(0, width + step, step):
        draw.line((x, 0, x - height, height), fill=(48, 72, 72, 76), width=2)
        draw.line((x, 0, x + height, height), fill=(34, 44, 48, 66), width=1)
    draw.rounded_rectangle((22, 22, width - 23, height - 23), radius=18, outline=(92, 200, 176, 160), width=4)
    draw.rounded_rectangle((48, 48, width - 49, height - 49), radius=10, outline=(232, 178, 86, 88), width=2)
    for y in range(96, height - 80, 96):
        draw.line((80, y, width - 80, y), fill=(92, 200, 176, 32), width=1)
    draw.ellipse((width // 2 - 96, height // 2 - 96, width // 2 + 96, height // 2 + 96), outline=(232, 178, 86, 58), width=3)


def draw_character_plate(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    cx = width // 2
    draw.ellipse((cx - 42, 92, cx + 42, 176), fill=(52, 74, 66, 190), outline=(92, 200, 176, 160), width=3)
    draw.rounded_rectangle((cx - 56, 178, cx + 56, 360), radius=42, fill=(42, 58, 54, 180), outline=(232, 178, 86, 105), width=2)
    draw.line((56, height - 126, width - 56, height - 126), fill=(232, 178, 86, 120), width=3)
    for i in range(3):
        y = height - 92 + i * 24
        draw.rounded_rectangle((48, y, width - 48, y + 12), radius=4, fill=(92, 200, 176, 34), outline=(92, 200, 176, 70), width=1)


def draw_route_wall(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    for index, (x, y, w, h) in enumerate([(32, 62, 160, 82), (216, 134, 172, 82), (402, 214, 150, 78)]):
        color = (92, 200, 176, 42) if index != 1 else (232, 178, 86, 48)
        draw.rounded_rectangle((x, y, x + w, y + h), radius=8, fill=color, outline=(92, 200, 176, 105), width=2)
    for x1, y1, x2, y2 in [(192, 103, 216, 174), (388, 175, 402, 253)]:
        draw.line((x1, y1, x2, y2), fill=(232, 178, 86, 120), width=3)


def draw_collection_grid(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    cell_w = (width - 72) // 3
    cell_h = (height - 104) // 3
    for row in range(3):
        for col in range(3):
            x = 28 + col * (cell_w + 14)
            y = 56 + row * (cell_h + 14)
            draw.rounded_rectangle((x, y, x + cell_w, y + cell_h), radius=8, fill=(34, 48, 48, 116), outline=(92, 200, 176, 100), width=2)
            draw.line((x + 10, y + cell_h - 14, x + cell_w - 10, y + cell_h - 14), fill=(232, 178, 86, 70), width=2)


def draw_summary_modules(draw: ImageDraw.ImageDraw, width: int, height: int) -> None:
    y = 42
    while y < height - 52:
        draw.rounded_rectangle((20, y, width - 20, y + 48), radius=6, fill=(36, 45, 45, 100), outline=(92, 200, 176, 85), width=1)
        draw.rectangle((28, y + 10, 70, y + 38), fill=(232, 178, 86, 58))
        y += 66


def draw_map_cell(draw: ImageDraw.ImageDraw, width: int, height: int, kind: str) -> None:
    fill = {
        "map_cell_unknown": (38, 45, 54, 255),
        "map_cell_explored": (28, 54, 50, 255),
        "map_cell_scanned": (54, 48, 30, 255),
        "map_cell_flagged": (74, 33, 35, 255),
    }.get(kind, (38, 45, 54, 255))
    draw.rounded_rectangle((2, 2, width - 3, height - 3), radius=6, fill=fill, outline=(92, 200, 176, 190), width=2)
    draw.rectangle((10, 10, width - 10, height - 10), outline=(232, 178, 86, 90), width=1)
    if kind == "map_cell_flagged":
        draw.polygon([(22, 17), (46, 25), (22, 34)], fill=(232, 178, 86, 220))
        draw.line((22, 16, 22, 48), fill=(232, 178, 86, 220), width=3)


def draw_map_marker(draw: ImageDraw.ImageDraw, width: int, height: int, kind: str) -> None:
    draw_map_cell(draw, width, height, "map_cell_explored")
    cx = width // 2
    cy = height // 2
    if kind == "map_marker_player":
        draw.ellipse((cx - 13, cy - 13, cx + 13, cy + 13), fill=(92, 200, 176, 236), outline=(240, 245, 220, 220), width=2)
    elif kind == "map_marker_event":
        draw.polygon([(cx, cy - 18), (cx + 16, cy + 14), (cx - 16, cy + 14)], fill=(232, 178, 86, 230), outline=(240, 245, 220, 180))
        draw.line((cx, cy - 8, cx, cy + 5), fill=(38, 32, 24, 230), width=3)
    elif kind == "map_marker_exit":
        draw.rectangle((cx - 15, cy - 15, cx + 15, cy + 15), outline=(104, 220, 126, 236), width=4)
        draw.line((cx - 8, cy, cx + 10, cy), fill=(104, 220, 126, 236), width=3)
    elif kind == "map_marker_mine":
        draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(190, 60, 52, 232))
        draw.line((cx - 20, cy, cx + 20, cy), fill=(232, 178, 86, 210), width=2)
        draw.line((cx, cy - 20, cx, cy + 20), fill=(232, 178, 86, 210), width=2)
    elif kind == "map_marker_chest":
        draw.rounded_rectangle((cx - 18, cy - 10, cx + 18, cy + 14), radius=4, fill=(96, 68, 34, 236), outline=(232, 178, 86, 230), width=3)
        draw.line((cx - 18, cy - 2, cx + 18, cy - 2), fill=(232, 178, 86, 220), width=2)


def write_csv(path: Path, fields: list[str], rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})


def build_assets() -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    manifest_rows: list[dict[str, str]] = []
    staging_rows: list[dict[str, str]] = []
    contract_rows: list[dict[str, str]] = []
    for component in COMPONENTS:
        staging_path = STAGING_ROOT / component.runtime_rel
        cut_path = CUT_ROOT / component.runtime_rel
        runtime_path = RUNTIME_ROOT / component.runtime_rel
        draw_component(component, staging_path)
        cut_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(staging_path, cut_path)
        runtime_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(cut_path, runtime_path)

        source_hash = sha256(staging_path)
        cut_hash = sha256(cut_path)
        godot_path = "res://assets/ui/art21/%s" % component.runtime_rel.replace("\\", "/")
        source_path = rel_for_manifest(cut_path)
        manifest_rows.append({
            "asset_id": component.asset_id,
            "source_repo_path": source_path,
            "godot_path": godot_path,
            "type": "texture",
            "category": component.category,
            "usage": component.usage,
            "import_preset": "pixel_ui",
            "license_status": "internal_generated",
            "replacement_needed": "false",
            "linked_scene": component.consumer,
            "linked_data": component.visual_key,
            "note": "ART21 generated component; source_sha256=%s; cut_sha256=%s; visual_key=%s" % (source_hash, cut_hash, component.visual_key),
            "theme_key": "art21.%s" % component.visual_key,
            "presentation_role": component.role,
            "state": component.state,
            "variant": component.variant,
            "source_status": "art21_generated_contract_component",
        })
        staging_rows.append({
            "screen": component.screen,
            "slot": component.slot,
            "asset_id": component.asset_id,
            "visual_key": component.visual_key,
            "staging_path": rel_for_manifest(staging_path),
            "cut_output": rel_for_manifest(cut_path),
            "runtime_asset": godot_path,
            "source_sha256": source_hash,
            "cut_sha256": cut_hash,
            "status": "ready_for_runtime_import",
            "blocked_resolution": "replaced" if component.blocked_reason else "completed",
        })
        contract_rows.append({
            "screen": component.screen,
            "layer": component.layer,
            "slot": component.slot,
            "interaction_owner": component.interaction_owner,
            "state": component.state,
            "visibility_rule": component.visibility_rule,
            "input_rule": component.input_rule,
            "intended_visual": component.intended_visual,
            "source_candidate": rel_for_manifest(staging_path),
            "cut_output": rel_for_manifest(cut_path),
            "runtime_asset": godot_path,
            "asset_id": component.asset_id,
            "visual_key": component.visual_key,
            "consumer": component.consumer,
            "stretch_or_9slice": component.stretch,
            "fallback": component.fallback,
            "blocked_reason": component.blocked_reason,
            "validation_screenshot": VALIDATION_SCREENSHOT_BY_SCREEN.get(component.screen, "pending_slice6"),
        })
    return manifest_rows, staging_rows, contract_rows


def update_asset_manifest(new_rows: list[dict[str, str]]) -> None:
    existing: list[dict[str, str]] = []
    if ASSET_MANIFEST.exists():
        with ASSET_MANIFEST.open("r", encoding="utf-8-sig", newline="") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if not row.get("asset_id", "").startswith("ui.art21."):
                    existing.append(row)
    existing.extend(new_rows)
    write_csv(ASSET_MANIFEST, MANIFEST_FIELDS, existing)


def write_manifests(manifest_rows: list[dict[str, str]], staging_rows: list[dict[str, str]], contract_rows: list[dict[str, str]]) -> None:
    write_csv(MANIFEST_ROOT / "staging_manifest.csv", [
        "screen", "slot", "asset_id", "visual_key", "staging_path", "cut_output",
        "runtime_asset", "source_sha256", "cut_sha256", "status", "blocked_resolution",
    ], staging_rows)
    write_csv(MANIFEST_ROOT / "runtime_import_manifest.csv", MANIFEST_FIELDS, manifest_rows)
    write_csv(CONTRACT_CSV, CONTRACT_FIELDS, contract_rows)
    blocked_rows = [row for row in staging_rows if row["blocked_resolution"] == "replaced"]
    write_csv(MANIFEST_ROOT / "blocked_resolution.csv", [
        "screen", "slot", "asset_id", "visual_key", "staging_path", "cut_output",
        "runtime_asset", "source_sha256", "cut_sha256", "status", "blocked_resolution",
    ], blocked_rows)
    summary = {
        "component_rows": len(staging_rows),
        "runtime_rows": len(manifest_rows),
        "contract_rows": len(contract_rows),
        "art20_blocked_replaced": len(blocked_rows),
        "screens": sorted({row["screen"] for row in contract_rows}),
    }
    (MANIFEST_ROOT / "cut_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


def main() -> None:
    ensure_dirs()
    manifest_rows, staging_rows, contract_rows = build_assets()
    write_manifests(manifest_rows, staging_rows, contract_rows)
    update_asset_manifest(manifest_rows)
    print("ART21_ASSET_BUILD=PASS")
    print("components=%d" % len(manifest_rows))
    print("contract=%s" % CONTRACT_CSV)
    print("runtime=%s" % RUNTIME_ROOT)


if __name__ == "__main__":
    main()
