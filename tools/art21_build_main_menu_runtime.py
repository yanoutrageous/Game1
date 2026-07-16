#!/usr/bin/env python3
"""Build audited, runtime-sized ART21 main-menu assets from the handoff pack.

The source pack is intentionally external. This script writes only to the active
repository worktree, records every crop/resize, and upserts the generated assets
into the repository asset manifest. It does not copy the seven preview fallback
files wholesale into the runtime tree.

The pack's audited composite reference is promoted as the default static scene
master. Split assets remain available for focus, modal, transition, and future
animation work, but are not all stacked in the default frame; this hybrid
strategy prevents visible collage seams between independently authored cuts.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from collections import deque
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Sequence

from PIL import Image, ImageEnhance


CANVAS = (1280, 720)
ASSET_PREFIX = "ui.art21.main_menu.scene."
VISUAL_PREFIX = "main_menu.scene."
DEFAULT_LIVE_ROLES = {
    "background_clean_plate",
    "character_shadow",
    "character_idle_frame",
    "character_focus_frame",
    "menu_board_explore",
    "menu_board_long_term",
    "menu_board_settings",
    "menu_board_exit",
    "dungeon_flag",
    "company_banner",
    "company_side_banner",
    "lantern_flame",
    "smoke",
    "birds",
    "leaves",
    "cave_focus_fx",
    "company_focus_fx",
    "focus_outline_explore",
    "menu_modal_panel",
    "menu_modal_button",
}
DEFAULT_LIVE_VISUAL_KEYS = {
    "main_menu.scene.menu.settings_control.1.1",
    "main_menu.scene.menu.settings_control.2.1",
    "main_menu.scene.menu.settings_control.2.2",
}


@dataclass
class RuntimeAsset:
    asset_id: str
    visual_key: str
    role: str
    state: str
    source_file: str
    source_rect: str
    runtime_path: str
    width: int
    height: int
    file_bytes: int
    decoded_bytes: int
    sha256: str
    load_group: str
    source_status: str = "canonical"


class Builder:
    def __init__(self, source_root: Path, repo_root: Path) -> None:
        self.source_root = source_root
        self.repo_root = repo_root
        self.godot_root = repo_root / "Godot" / "GraytailGodot"
        self.output_root = self.godot_root / "assets" / "ui" / "art21" / "main_menu" / "scene"
        self.validation_root = repo_root / "docs" / "art" / "validation" / "art21"
        self.records: list[RuntimeAsset] = []
        self.output_root.mkdir(parents=True, exist_ok=True)
        self.validation_root.mkdir(parents=True, exist_ok=True)

    def clean_generated_outputs(self) -> None:
        resolved = self.output_root.resolve()
        resolved.relative_to(self.repo_root.resolve())
        for path in sorted(self.output_root.rglob("*.png")):
            path.unlink()

    def source(self, relative: str) -> Image.Image:
        path = self.source_root / relative
        if not path.is_file():
            raise FileNotFoundError(path)
        return Image.open(path).convert("RGBA")

    @staticmethod
    def crop_xywh(image: Image.Image, rect: Sequence[int]) -> Image.Image:
        x, y, width, height = (int(value) for value in rect)
        return image.crop((x, y, x + width, y + height))

    @staticmethod
    def trim(image: Image.Image) -> Image.Image:
        alpha = image.getchannel("A")
        bbox = alpha.getbbox()
        return image.crop(bbox) if bbox else Image.new("RGBA", (1, 1), (0, 0, 0, 0))

    @staticmethod
    def resize_exact(image: Image.Image, size: tuple[int, int]) -> Image.Image:
        # Source candidates are authored far above the 1280x720 runtime scale.
        # Use one audited high-quality downsample here, then let Godot keep the
        # resulting runtime texture pixel-perfect with nearest filtering.
        resample = Image.Resampling.LANCZOS if image.width > size[0] or image.height > size[1] else Image.Resampling.NEAREST
        return image.resize(size, resample)

    @staticmethod
    def contain_bottom(image: Image.Image, size: tuple[int, int], padding: int = 0) -> Image.Image:
        image = Builder.strip_separator_border(image)
        image = Builder.trim(image)
        max_w = max(1, size[0] - padding * 2)
        max_h = max(1, size[1] - padding * 2)
        ratio = min(max_w / image.width, max_h / image.height)
        target = (max(1, round(image.width * ratio)), max(1, round(image.height * ratio)))
        resample = Image.Resampling.LANCZOS if image.width > target[0] or image.height > target[1] else Image.Resampling.NEAREST
        resized = image.resize(target, resample)
        canvas = Image.new("RGBA", size, (0, 0, 0, 0))
        x = (size[0] - resized.width) // 2
        y = size[1] - resized.height - padding
        canvas.alpha_composite(resized, (x, y))
        return canvas

    @staticmethod
    def strip_separator_border(image: Image.Image, border: int = 8) -> Image.Image:
        """Remove generator separator pixels touching an explicit frame edge."""
        image = image.copy().convert("RGBA")
        pixels = image.load()
        width, height = image.size
        for y in range(height):
            for x in range(width):
                if x >= border and x < width - border and y >= border and y < height - border:
                    continue
                red, green, blue, _alpha = pixels[x, y]
                pixels[x, y] = (red, green, blue, 0)
        return image

    @staticmethod
    def remove_border_checkerboard(
        image: Image.Image,
        *,
        minimum_channel: int = 135,
        maximum_spread: int = 48,
    ) -> Image.Image:
        """Make only the pale neutral background connected to an edge transparent.

        The generated ART21 atlases contain an opaque white/grey checkerboard.
        A global colour key would also remove the raccoon's pale face. Flooding
        from the image boundary keeps enclosed pale artwork intact while
        removing the connected checkerboard and its antialiased edge pixels.
        """
        result = image.copy().convert("RGBA")
        pixels = result.load()
        width, height = result.size
        visited = bytearray(width * height)
        pending: deque[int] = deque()

        def is_background(x: int, y: int) -> bool:
            red, green, blue, alpha = pixels[x, y]
            return (
                alpha > 0
                and min(red, green, blue) >= minimum_channel
                and max(red, green, blue) - min(red, green, blue) <= maximum_spread
            )

        def seed(x: int, y: int) -> None:
            index = y * width + x
            if visited[index] or not is_background(x, y):
                return
            visited[index] = 1
            pending.append(index)

        for x in range(width):
            seed(x, 0)
            seed(x, height - 1)
        for y in range(height):
            seed(0, y)
            seed(width - 1, y)

        while pending:
            index = pending.popleft()
            y, x = divmod(index, width)
            red, green, blue, _alpha = pixels[x, y]
            pixels[x, y] = (red, green, blue, 0)
            if x > 0:
                seed(x - 1, y)
            if x + 1 < width:
                seed(x + 1, y)
            if y > 0:
                seed(x, y - 1)
            if y + 1 < height:
                seed(x, y + 1)
            if x > 0 and y > 0:
                seed(x - 1, y - 1)
            if x + 1 < width and y > 0:
                seed(x + 1, y - 1)
            if x > 0 and y + 1 < height:
                seed(x - 1, y + 1)
            if x + 1 < width and y + 1 < height:
                seed(x + 1, y + 1)

        # Pillow resampling operates on straight RGBA values. Retaining white
        # RGB under zero alpha would bleed a pale fringe back into the scaled
        # runtime texture, so transparent pixels are normalised to clear black.
        for y in range(height):
            for x in range(width):
                if pixels[x, y][3] == 0:
                    pixels[x, y] = (0, 0, 0, 0)
        return result

    @staticmethod
    def state_variant(image: Image.Image, state: str) -> Image.Image:
        if state == "focused":
            rgb = ImageEnhance.Color(image.convert("RGB")).enhance(1.10)
            rgb = ImageEnhance.Brightness(rgb).enhance(1.16)
            result = rgb.convert("RGBA")
            result.putalpha(image.getchannel("A"))
            return result
        if state == "pressed":
            rgb = ImageEnhance.Brightness(image.convert("RGB")).enhance(0.86)
            result = rgb.convert("RGBA")
            result.putalpha(image.getchannel("A"))
            return result
        if state == "disabled":
            rgb = ImageEnhance.Color(image.convert("RGB")).enhance(0.18)
            rgb = ImageEnhance.Brightness(rgb).enhance(0.72)
            result = rgb.convert("RGBA")
            result.putalpha(image.getchannel("A").point(lambda value: round(value * 0.82)))
            return result
        return image.copy()

    def save(
        self,
        image: Image.Image,
        relative_output: str,
        *,
        key: str,
        role: str,
        state: str = "normal",
        source_file: str,
        source_rect: str,
        load_group: str = "main_menu_default",
        source_status: str = "canonical",
    ) -> Path:
        output = self.output_root / relative_output
        output.parent.mkdir(parents=True, exist_ok=True)
        image = image.convert("RGBA")
        image.save(output, format="PNG", optimize=True)
        data = output.read_bytes()
        godot_path = "res://" + output.relative_to(self.godot_root).as_posix()
        self.records.append(
            RuntimeAsset(
                asset_id=ASSET_PREFIX + key,
                visual_key=VISUAL_PREFIX + key,
                role=role,
                state=state,
                source_file=source_file,
                source_rect=source_rect,
                runtime_path=godot_path,
                width=image.width,
                height=image.height,
                file_bytes=len(data),
                decoded_bytes=image.width * image.height * 4,
                sha256=hashlib.sha256(data).hexdigest().upper(),
                load_group=load_group,
                source_status=source_status,
            )
        )
        return output

    def build_full_canvas_layers(self) -> None:
        recipes = [
            ("backgrounds/ui_main_menu_rework_sky_base.png", "background/sky.png", "background.sky", "background_sky"),
            ("backgrounds/ui_main_menu_rework_clouds_far.png", "background/clouds_far.png", "background.clouds_far", "background_clouds"),
            ("backgrounds/ui_main_menu_rework_clouds_near.png", "background/clouds_near.png", "background.clouds_near", "background_clouds"),
            ("backgrounds/ui_main_menu_rework_mountains_treeline.png", "background/mountains.png", "background.mountains", "background_mountains"),
            ("backgrounds/ui_main_menu_rework_ground_road_base.png", "background/ground.png", "background.ground", "background_ground"),
        ]
        for source_file, output, key, role in recipes:
            image = self.resize_exact(self.source(source_file), CANVAS)
            self.save(image, output, key=key, role=role, source_file=source_file, source_rect="full", load_group="main_menu_default")

    def build_integrated_scene_master(self) -> None:
        source_file = "reference/ui_main_menu_rework_composite_reference.png"
        source = self.source(source_file)
        image = source.resize(CANVAS, Image.Resampling.LANCZOS)
        self.save(
            image,
            "background/scene_master.png",
            key="background.scene_master",
            role="integrated_scene_master",
            state="normal",
            source_file=source_file,
            source_rect="full->1280x720",
            load_group="main_menu_evidence",
            source_status="promoted_composite_master",
        )

    def build_clean_plate(self, clean_plate_source: Path) -> None:
        if not clean_plate_source.is_file():
            raise FileNotFoundError(clean_plate_source)
        source = Image.open(clean_plate_source).convert("RGBA")
        image = source.resize(CANVAS, Image.Resampling.LANCZOS)
        self.save(
            image,
            "background/scene_clean_plate.png",
            key="background.scene_clean_plate",
            role="background_clean_plate",
            state="normal",
            source_file="generated/art21_main_menu_clean_plate_source.png",
            source_rect=f"full:{source.width}x{source.height}->1280x720",
            load_group="main_menu_master",
            source_status="generated_master_matched_clean_plate",
        )

    def build_architecture(self) -> None:
        singles = [
            ("architecture/ui_main_menu_rework_dungeon_base.png", (233, 41, 1192, 845), (610, 604), "architecture/dungeon_base.png", "architecture.dungeon_base", "dungeon_architecture"),
            ("architecture/ui_main_menu_rework_company_base.png", (440, 50, 814, 805), (460, 500), "architecture/company_base.png", "architecture.company_base", "company_architecture"),
            ("architecture/ui_main_menu_rework_company_guardian_statue.png", (269, 119, 645, 1062), (52, 72), "architecture/company_guardian.png", "architecture.company_guardian", "company_guardian"),
        ]
        for source_file, rect, size, output, key, role in singles:
            image = self.resize_exact(self.crop_xywh(self.source(source_file), rect), size)
            self.save(image, output, key=key, role=role, source_file=source_file, source_rect=str(rect))

        atlas_recipes = [
            (
                "architecture/ui_main_menu_rework_cave_interior_states_4x1.png",
                [(0, 0, 496, 793), (496, 0, 496, 793), (992, 0, 495, 793), (1487, 0, 496, 793)],
                (230, 286),
                "architecture/cave_{state}.png",
                "architecture.cave.{state}",
                ["normal", "focused", "lit", "transition"],
                "cave_interior",
            ),
            (
                "architecture/ui_main_menu_rework_company_door_states_4x1.png",
                [(index * 543, 0, 543, 724) for index in range(4)],
                (96, 140),
                "architecture/company_door_{state}.png",
                "architecture.company_door.{state}",
                ["normal", "focused", "opening", "open"],
                "company_door",
            ),
            (
                "architecture/ui_main_menu_rework_dungeon_gate_states_4x1.png",
                [(5, 6, 535, 713), (547, 6, 535, 713), (1083, 6, 541, 713), (1631, 6, 535, 713)],
                (218, 232),
                "architecture/dungeon_gate_{state}.png",
                "architecture.dungeon_gate.{state}",
                ["normal", "focused", "opening", "open"],
                "dungeon_gate",
            ),
        ]
        for source_file, rects, size, output_pattern, key_pattern, states, role in atlas_recipes:
            atlas = self.source(source_file)
            for rect, state in zip(rects, states):
                frame = self.contain_bottom(self.crop_xywh(atlas, rect), size)
                self.save(
                    frame,
                    output_pattern.format(state=state),
                    key=key_pattern.format(state=state),
                    role=role,
                    state=state,
                    source_file=source_file,
                    source_rect=str(rect),
                )

    def build_character(self, character_atlas_source: Path) -> None:
        if not character_atlas_source.is_file():
            raise FileNotFoundError(character_atlas_source)
        idle_source = "generated/art21_main_menu_character_atlas_source.png"
        idle_atlas = self.remove_border_checkerboard(Image.open(character_atlas_source).convert("RGBA"))
        idle_rects: list[tuple[int, int, int, int]] = []
        for row in range(2):
            y0 = round(row * idle_atlas.height / 2)
            y1 = round((row + 1) * idle_atlas.height / 2)
            for column in range(4):
                x0 = round(column * idle_atlas.width / 4)
                x1 = round((column + 1) * idle_atlas.width / 4)
                idle_rects.append((x0, y0, x1 - x0, y1 - y0))

        idle_frames: list[Image.Image] = []
        for index, rect in enumerate(idle_rects):
            frame = self.contain_bottom(self.crop_xywh(idle_atlas, rect), (190, 216), padding=2)
            idle_frames.append(frame)
            self.save(
                frame,
                f"character/idle_{index:02d}.png",
                key=f"character.idle.{index:02d}",
                role="character_idle_frame",
                state=f"frame_{index:02d}",
                source_file=idle_source,
                source_rect=str(rect),
                load_group="main_menu_character_idle",
                source_status="generated_master_matched_character_atlas",
            )

        # Frame 6 and 7 carry the authored directional focus poses. Frame 0 is
        # the neutral fallback and frame 3 is the closed-eye utility response.
        for output_index, source_index in enumerate((0, 6, 7, 3)):
            self.save(
                idle_frames[source_index],
                f"character/focus_{output_index:02d}.png",
                key=f"character.focus.{output_index:02d}",
                role="character_focus_frame",
                state=f"frame_{output_index:02d}",
                source_file=idle_source,
                source_rect=str(idle_rects[source_index]),
                load_group="main_menu_character_focus",
                source_status="generated_master_matched_character_atlas",
            )

        nav_source = "character/ui_main_menu_rework_character_navigation_4x3.png"
        nav_atlas = self.source(nav_source)
        rows = ["walk_dungeon", "walk_company"]
        for row, row_name in enumerate(rows, start=1):
            for column in range(4):
                rect = (column * 362, row * 362, 362, 362)
                frame = self.contain_bottom(self.crop_xywh(nav_atlas, rect), (190, 216), padding=2)
                self.save(
                    frame,
                    f"character/{row_name}_{column:02d}.png",
                    key=f"character.{row_name}.{column:02d}",
                    role=f"character_{row_name}_frame",
                    state=f"frame_{column:02d}",
                    source_file=nav_source,
                    source_rect=str(rect),
                    load_group=f"main_menu_character_{row_name}",
                )

        shadow_source = "character/ui_main_menu_rework_character_shadow.png"
        rect = (508, 445, 642, 70)
        shadow = self.resize_exact(self.crop_xywh(self.source(shadow_source), rect), (196, 24))
        self.save(shadow, "character/shadow.png", key="character.shadow", role="character_shadow", source_file=shadow_source, source_rect=str(rect))

    def build_environment(self) -> None:
        singles = [
            ("environment/ui_main_menu_rework_dungeon_title_sign_blank.png", (132, 158, 1449, 649), (382, 171), "environment/dungeon_title_sign.png", "environment.dungeon_title_sign", "dungeon_title_sign"),
            ("environment/ui_main_menu_rework_foreground_foliage.png", (0, 587, 1672, 354), (1280, 142), "environment/foreground_foliage.png", "environment.foreground", "foreground_foliage"),
            ("environment/ui_main_menu_rework_lantern_wall_unlit.png", (362, 112, 461, 1104), (76, 131), "environment/lantern_wall.png", "environment.lantern_wall", "lantern_fixture"),
            ("environment/ui_main_menu_rework_lantern_hanging_unlit.png", (382, 90, 411, 1093), (82, 158), "environment/lantern_hanging.png", "environment.lantern_hanging", "lantern_fixture"),
        ]
        for source_file, rect, size, output, key, role in singles:
            image = self.resize_exact(self.crop_xywh(self.source(source_file), rect), size)
            self.save(image, output, key=key, role=role, source_file=source_file, source_rect=str(rect))

        notice_source = "environment/ui_main_menu_rework_notice_board_parts_2x1.png"
        notice = self.source(notice_source)
        frame_rect = (2, 2, 884, 885)
        paper_rect = (888, 2, 886, 885)
        frame = self.contain_bottom(self.crop_xywh(notice, frame_rect), (236, 286))
        paper = self.contain_bottom(self.crop_xywh(notice, paper_rect), (140, 158))
        self.save(frame, "environment/notice_frame.png", key="environment.notice.frame", role="notice_frame", source_file=notice_source, source_rect=str(frame_rect))
        self.save(paper, "environment/notice_paper.png", key="environment.notice.paper", role="notice_paper", source_file=notice_source, source_rect=str(paper_rect))

    def build_menu(self, menu_board_atlas_source: Path) -> None:
        sign_source = "menu/ui_main_menu_rework_signpost_structure.png"
        sign_rect = (174, 105, 647, 1469)
        sign = self.resize_exact(self.crop_xywh(self.source(sign_source), sign_rect), (196, 628))
        self.save(sign, "menu/signpost.png", key="menu.signpost", role="menu_support_structure", source_file=sign_source, source_rect=str(sign_rect))

        if not menu_board_atlas_source.is_file():
            raise FileNotFoundError(menu_board_atlas_source)
        atlas_source = "generated/art21_main_menu_board_atlas_source.png"
        atlas = self.remove_border_checkerboard(Image.open(menu_board_atlas_source).convert("RGBA"))
        states = ["normal", "focused", "pressed", "disabled"]
        board_targets = {
            "explore": (370, 146),
            "long_term": (249, 96),
            "settings": (221, 84),
            "exit": (211, 75),
        }
        source_regions = {
            "explore": (0, 0, 630, atlas.height),
            "long_term": (630, 0, 480, atlas.height),
            "settings": (1110, 0, 360, atlas.height),
            "exit": (1470, 0, atlas.width - 1470, atlas.height),
        }
        for board, rect in source_regions.items():
            base = self.resize_exact(self.trim(self.crop_xywh(atlas, rect)), board_targets[board])
            for state in states:
                frame = self.state_variant(base, state)
                self.save(
                    frame,
                    f"menu/{board}_{state}.png",
                    key=f"menu.{board}.{state}",
                    role=f"menu_board_{board}",
                    state=state,
                    source_file=atlas_source,
                    source_rect=str(rect),
                    source_status="generated_master_matched_board_atlas",
                )

        modal_recipes = [
            ("menu/ui_main_menu_rework_modal_panel_9slice.png", (63, 66, 1492, 829), (816, 436), "menu/modal_panel.png", "menu.modal.panel", "menu_modal_panel"),
            ("menu/ui_main_menu_rework_modal_button_9slice.png", (417, 276, 837, 389), (190, 58), "menu/modal_button.png", "menu.modal.button", "menu_modal_button"),
        ]
        for source_file, rect, size, output, key, role in modal_recipes:
            image = self.resize_exact(self.crop_xywh(self.source(source_file), rect), size)
            self.save(image, output, key=key, role=role, source_file=source_file, source_rect=str(rect), load_group="main_menu_modal")

        controls_source = "menu/ui_main_menu_rework_settings_controls_4x4.png"
        controls = self.source(controls_source)
        boundaries = [0, 314, 627, 941, 1254]
        target_sizes = [(190, 58), (104, 46), (300, 42), (48, 48)]
        for row in range(4):
            for column in range(4):
                rect = (
                    boundaries[column], boundaries[row],
                    boundaries[column + 1] - boundaries[column],
                    boundaries[row + 1] - boundaries[row],
                )
                frame = self.contain_bottom(self.crop_xywh(controls, rect), target_sizes[row])
                self.save(
                    frame,
                    f"menu/settings_control_{row}_{column}.png",
                    key=f"menu.settings_control.{row}.{column}",
                    role="settings_control",
                    state=f"row_{row}_column_{column}",
                    source_file=controls_source,
                    source_rect=str(rect),
                    load_group="main_menu_settings",
                )

    def build_fx(self) -> None:
        singles = [
            ("fx/ui_main_menu_rework_fx_cave_activation.png", (288, 183, 673, 856), (218, 286), "fx/cave_activation.png", "fx.cave_activation", "cave_focus_fx"),
            ("fx/ui_main_menu_rework_fx_company_activation.png", (608, 329, 454, 255), (224, 126), "fx/company_activation.png", "fx.company_activation", "company_focus_fx"),
            ("fx/ui_main_menu_rework_fx_focus_explore.png", (128, 171, 1444, 588), (382, 158), "fx/focus_explore.png", "fx.focus_explore", "focus_outline_explore"),
            ("fx/ui_main_menu_rework_fx_focus_rect.png", (341, 127, 993, 608), (261, 108), "fx/focus_rect.png", "fx.focus_rect", "focus_outline_rect"),
        ]
        for source_file, rect, size, output, key, role in singles:
            image = self.resize_exact(self.crop_xywh(self.source(source_file), rect), size)
            self.save(image, output, key=key, role=role, source_file=source_file, source_rect=str(rect), load_group="main_menu_focus")

        atlas_specs = [
            ("fx/ui_main_menu_rework_fx_company_banner_sheet.png", [(i * 543, 0, 543, 724) for i in range(4)], (92, 174), "company_banner", "company_banner", "main_menu_environment"),
            ("fx/ui_main_menu_rework_fx_company_side_banner_sheet_4x1.png", [(0, 0, 496, 793), (496, 0, 496, 793), (992, 0, 495, 793), (1487, 0, 496, 793)], (42, 112), "company_side_banner", "company_side_banner", "main_menu_environment"),
            ("fx/ui_main_menu_rework_fx_company_window_sheet_4x1.png", [(i * 543, 0, 543, 724) for i in range(4)], (18, 54), "company_window", "company_window", "main_menu_focus"),
            ("fx/ui_main_menu_rework_fx_dungeon_flag_sheet.png", [(i * 543, 0, 543, 724) for i in range(4)], (112, 94), "dungeon_flag", "dungeon_flag", "main_menu_environment"),
            ("fx/ui_main_menu_rework_fx_lantern_flame_sheet.png", [(i * 543, 0, 543, 724) for i in range(4)], (54, 54), "lantern_flame", "lantern_flame", "main_menu_environment"),
            ("fx/ui_main_menu_rework_fx_notice_paper_sheet_4x1.png", [(i * 543, 0, 543, 724) for i in range(4)], (140, 158), "notice_paper", "notice_paper", "main_menu_environment"),
        ]
        for source_file, rects, size, name, role, load_group in atlas_specs:
            atlas = self.source(source_file)
            for index, rect in enumerate(rects):
                frame = self.contain_bottom(self.crop_xywh(atlas, rect), size)
                self.save(
                    frame,
                    f"fx/{name}_{index:02d}.png",
                    key=f"fx.{name}.{index:02d}",
                    role=role,
                    state=f"frame_{index:02d}",
                    source_file=source_file,
                    source_rect=str(rect),
                    load_group=load_group,
                )

        ivy_source = "fx/ui_main_menu_rework_fx_dungeon_ivy_sheet_4x2.png"
        ivy = self.source(ivy_source)
        ivy_rects = [
            [(3, 3, 440, 439), (446, 3, 439, 439), (888, 3, 439, 439), (1330, 3, 440, 439)],
            [(3, 445, 440, 438), (446, 445, 439, 438), (888, 445, 439, 438), (1330, 445, 440, 438)],
        ]
        for row, name, size in [(0, "ivy_back", (430, 166)), (1, "ivy_front", (126, 208))]:
            for index, rect in enumerate(ivy_rects[row]):
                frame = self.contain_bottom(self.crop_xywh(ivy, rect), size)
                self.save(frame, f"fx/{name}_{index:02d}.png", key=f"fx.{name}.{index:02d}", role=name, state=f"frame_{index:02d}", source_file=ivy_source, source_rect=str(rect), load_group="main_menu_environment")

        canopy_source = "fx/ui_main_menu_rework_fx_tree_canopy_sheet_4x1.png"
        canopy = self.source(canopy_source)
        canopy_bounds = [0, 496, 992, 1487, 1983]
        for index in range(4):
            rect = (canopy_bounds[index], 0, canopy_bounds[index + 1] - canopy_bounds[index], 793)
            frame = self.contain_bottom(self.crop_xywh(canopy, rect), (350, 150))
            self.save(frame, f"fx/tree_canopy_{index:02d}.png", key=f"fx.tree_canopy.{index:02d}", role="tree_canopy", state=f"frame_{index:02d}", source_file=canopy_source, source_rect=str(rect), load_group="main_menu_environment")

        self._build_grid_fx(
            "fx/ui_main_menu_rework_fx_ambient_loops_4x2.png",
            [0, 444, 887, 1331, 1774], [0, 444, 887],
            [(128, 128), (120, 120)], ["smoke", "leaves"],
        )
        self._build_grid_fx(
            "fx/ui_main_menu_rework_fx_nature_loops_4x2.png",
            [0, 418, 836, 1254, 1672], [0, 471, 941],
            [(160, 80), (160, 70)], ["birds", "grass_wind"],
        )
        self._build_grid_fx(
            "fx/ui_main_menu_rework_fx_prop_loops_4x2.png",
            [0, 444, 887, 1331, 1774], [0, 444, 887],
            [(180, 40)], ["puddle"],
        )

    def _build_grid_fx(
        self,
        source_file: str,
        x_bounds: list[int],
        y_bounds: list[int],
        target_sizes: list[tuple[int, int]],
        row_names: list[str],
    ) -> None:
        atlas = self.source(source_file)
        for row, (target_size, row_name) in enumerate(zip(target_sizes, row_names)):
            for column in range(4):
                inset = 4 if "ambient" in source_file or "prop" in source_file else 0
                x0 = x_bounds[column] + (inset if column > 0 else 0)
                x1 = x_bounds[column + 1] - (inset if column < 3 else 0)
                y0 = y_bounds[row] + (inset if row > 0 else 0)
                y1 = y_bounds[row + 1] - (inset if row < len(y_bounds) - 2 else 0)
                rect = (x0, y0, x1 - x0, y1 - y0)
                frame = self.contain_bottom(self.crop_xywh(atlas, rect), target_size)
                load_group = "main_menu_ambient_active" if row_name in {"smoke", "leaves", "birds", "puddle"} else "main_menu_environment"
                self.save(frame, f"fx/{row_name}_{column:02d}.png", key=f"fx.{row_name}.{column:02d}", role=row_name, state=f"frame_{column:02d}", source_file=source_file, source_rect=str(rect), load_group=load_group)

    def build_transitions(self) -> None:
        specs = [
            (
                "transitions/ui_main_menu_rework_transition_cave_4x1.png",
                [(0, 0, 444, 887), (444, 0, 443, 887), (887, 0, 444, 887), (1331, 0, 443, 887)],
                "cave",
            ),
            (
                "transitions/ui_main_menu_rework_transition_company_4x1.png",
                [(5, 5, 536, 714), (546, 5, 537, 714), (1088, 5, 537, 714), (1630, 5, 537, 714)],
                "company",
            ),
        ]
        for source_file, rects, name in specs:
            atlas = self.source(source_file)
            for index, rect in enumerate(rects):
                frame = self.resize_exact(self.crop_xywh(atlas, rect), CANVAS)
                self.save(frame, f"transition/{name}_{index:02d}.png", key=f"transition.{name}.{index:02d}", role=f"transition_{name}", state=f"frame_{index:02d}", source_file=source_file, source_rect=str(rect), load_group=f"main_menu_transition_{name}")

    def write_reports(self) -> None:
        csv_path = self.validation_root / "main_menu_runtime_asset_report.csv"
        json_path = self.validation_root / "main_menu_runtime_asset_report.json"
        contract_path = self.validation_root / "main_menu_runtime_asset_contract.csv"
        rows = []
        for record in self.records:
            row = asdict(record)
            row["default_load"] = str(self._is_default_live(record)).lower()
            rows.append(row)
        with csv_path.open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
            writer.writeheader()
            writer.writerows(rows)

        groups: dict[str, dict[str, int]] = {}
        for record in self.records:
            group = groups.setdefault(record.load_group, {"asset_count": 0, "decoded_bytes": 0, "file_bytes": 0})
            group["asset_count"] += 1
            group["decoded_bytes"] += record.decoded_bytes
            group["file_bytes"] += record.file_bytes
        default_records = [record for record in self.records if self._is_default_live(record)]
        default_decoded = sum(record.decoded_bytes for record in default_records)
        payload = {
            "schema_version": 3,
            "canvas": list(CANVAS),
            "asset_count": len(self.records),
            "file_bytes": sum(record.file_bytes for record in self.records),
            "decoded_bytes_all": sum(record.decoded_bytes for record in self.records),
            "decoded_bytes_default_load": default_decoded,
            "decoded_mib_default_load": round(default_decoded / 1024 / 1024, 2),
            "budget_mib": 128,
            "target_mib": 96,
            "budget_pass": default_decoded <= 128 * 1024 * 1024,
            "default_load_policy": "asset_level_live_and_interaction_reachable_worst_case",
            "default_load_asset_count": len(default_records),
            "groups": groups,
            "render_strategy": "master_matched_clean_plate_plus_interactive_overlays",
            # The external pack is an audited build input, not active path
            # authority. Keep reports portable and avoid leaking a machine- or
            # user-specific absolute path into versioned evidence.
            "source_pack_id": "main_menu_asset_pack/ready_to_migrate",
            "source_scope": "external_explicit_input_not_runtime_authority",
            "runtime_root": "res://assets/ui/art21/main_menu/scene",
        }
        json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        contract_fields = [
            "screen", "layer", "slot", "state", "visibility_rule", "source_candidate",
            "source_rect", "runtime_asset", "asset_id", "visual_key", "consumer",
            "runtime_rect", "anchor", "pivot", "z_layer", "runtime_status",
            "load_group", "default_load", "decoded_bytes", "source_status",
        ]
        with contract_path.open("w", encoding="utf-8-sig", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=contract_fields)
            writer.writeheader()
            for record in self.records:
                placement = self._placement_metadata(record)
                default_load = self._is_default_live(record)
                writer.writerow(
                    {
                        "screen": "main_menu",
                        "layer": self._layer_for_role(record.role),
                        "slot": record.role,
                        "state": record.state,
                        "visibility_rule": "load_group:" + record.load_group,
                        "source_candidate": "external/main_menu_asset_pack/" + record.source_file,
                        "source_rect": record.source_rect,
                        "runtime_asset": record.runtime_path,
                        "asset_id": record.asset_id,
                        "visual_key": record.visual_key,
                        "consumer": "main_menu_shell.gd/AppShell",
                        "runtime_rect": placement["runtime_rect"],
                        "anchor": placement["anchor"],
                        "pivot": placement["pivot"],
                        "z_layer": placement["z_layer"],
                        "runtime_status": "live_or_interaction_reachable" if default_load else ("evidence_only" if record.role == "integrated_scene_master" else "deferred_not_mounted"),
                        "load_group": record.load_group,
                        "default_load": str(default_load).lower(),
                        "decoded_bytes": record.decoded_bytes,
                        "source_status": record.source_status,
                    }
                )

    @staticmethod
    def _is_default_live(record: RuntimeAsset) -> bool:
        return record.role in DEFAULT_LIVE_ROLES or record.visual_key in DEFAULT_LIVE_VISUAL_KEYS

    @staticmethod
    def _placement_metadata(record: RuntimeAsset) -> dict[str, str]:
        role = record.role
        if role == "settings_control":
            settings_placements = {
                "main_menu.scene.menu.settings_control.1.1": ("830,250,104,46", "center", "52,23", "OverlayRoot"),
                "main_menu.scene.menu.settings_control.2.1": ("580,390,300,42", "center", "150,21", "OverlayRoot"),
                "main_menu.scene.menu.settings_control.2.2": ("580,326,300,42", "center", "150,21", "OverlayRoot"),
            }
            if record.visual_key in settings_placements:
                runtime_rect, anchor, pivot, z_layer = settings_placements[record.visual_key]
                return {"runtime_rect": runtime_rect, "anchor": anchor, "pivot": pivot, "z_layer": z_layer}
        placements: dict[str, tuple[str, str, str, str]] = {
            "background_clean_plate": ("0,0,1280,720", "top_left", "0,0", "BackgroundRoot:1"),
            "character_shadow": ("286,594,196,24", "bottom_center", "98,12", "CharacterRoot:0"),
            "character_idle_frame": ("286,408,190,216", "bottom_center", "95,216", "CharacterRoot:1"),
            "character_focus_frame": ("286,408,190,216", "bottom_center", "95,216", "CharacterRoot:1"),
            "menu_board_explore": ("790,181,370,146", "right_center", "370,73", "PrimaryActionRoot:1"),
            "menu_board_long_term": ("865,329,249,96", "top_center", "124,0", "PrimaryActionRoot:1"),
            "menu_board_settings": ("887,434,221,84", "top_center", "110,0", "PrimaryActionRoot:1"),
            "menu_board_exit": ("897,528,211,75", "top_center", "105,0", "PrimaryActionRoot:1"),
            "dungeon_flag": ("398,18,112,94", "left_center", "0,47", "DecorationRoot:7"),
            "company_banner": ("794,88,92,174", "top_center", "46,0", "DecorationRoot:7"),
            "company_side_banner": ("674,174,42,112|930,174,42,112", "top_center", "21,0", "DecorationRoot:7"),
            "lantern_flame": ("212,329,36,36|435,331,36,36|1214,289,36,36", "center", "18,18", "DecorationRoot:10"),
            "smoke": ("958,32,128,128", "bottom_center", "64,128", "FloatingInfoRoot:1"),
            "birds": ("606,66,160,80", "center", "80,40", "FloatingInfoRoot:1"),
            "leaves": ("1040,286,120,120", "top_center", "60,0", "FloatingInfoRoot:1"),
            "cave_focus_fx": ("230,245,218,286", "center", "109,143", "FloatingInfoRoot:1"),
            "company_focus_fx": ("687,287,224,126", "center", "112,63", "FloatingInfoRoot:1"),
            "focus_outline_explore": ("784,175,382,158", "center", "191,79", "FloatingInfoRoot:3"),
            "menu_modal_panel": ("232,142,816,436", "center", "408,218", "OverlayRoot/ModalRoot"),
            "menu_modal_button": ("392,444,190,58|698,444,190,58|796,476,190,58", "center", "95,29", "OverlayRoot/ModalRoot"),
        }
        runtime_rect, anchor, pivot, z_layer = placements.get(role, ("not_mounted", "n/a", "n/a", Builder._layer_for_role(role) + ":deferred"))
        return {
            "runtime_rect": runtime_rect,
            "anchor": anchor,
            "pivot": pivot,
            "z_layer": z_layer,
        }

    @staticmethod
    def _layer_for_role(role: str) -> str:
        if role.startswith("background"):
            return "background"
        if role.startswith("character"):
            return "character"
        if role.startswith("menu") or role == "settings_control":
            return "primary_action"
        if role.startswith("transition"):
            return "overlay"
        if "focus" in role or role in {"smoke", "leaves", "birds", "grass_wind", "puddle"}:
            return "floating_info"
        return "decoration"

    def update_asset_manifest(self) -> None:
        manifest = self.godot_root / "data" / "assets" / "asset_manifest.csv"
        with manifest.open("r", encoding="utf-8-sig", newline="") as handle:
            reader = csv.DictReader(handle)
            fieldnames = list(reader.fieldnames or [])
            rows = [row for row in reader if not row.get("asset_id", "").startswith(ASSET_PREFIX)]
        for record in self.records:
            rows.append(
                {
                    "asset_id": record.asset_id,
                    "source_repo_path": "external/main_menu_asset_pack/" + record.source_file,
                    "godot_path": record.runtime_path,
                    "type": "texture",
                    "category": "ui_main_menu_scene",
                    "usage": record.role,
                    "import_preset": "pixel_ui",
                    "license_status": "internal_generated",
                    "replacement_needed": "false",
                    "linked_scene": "scripts/ui/main_menu/main_menu_shell.gd",
                    "linked_data": record.visual_key,
                    "note": f"ART21 runtime cut; source_rect={record.source_rect}; sha256={record.sha256}; decoded_bytes={record.decoded_bytes}; load_group={record.load_group}",
                    "theme_key": "art21." + record.visual_key,
                    "presentation_role": record.role,
                    "state": record.state,
                    "variant": "art21_main_menu_scene",
                    "source_status": "art21_main_menu_runtime_" + record.source_status,
                }
            )
        with manifest.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fieldnames, lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)

    def write_runtime_contract_script(self) -> None:
        output = self.godot_root / "scripts" / "presentation" / "art21_main_menu_asset_contract.gd"
        lines = [
            "extends RefCounted",
            "class_name Art21MainMenuAssetContract",
            "",
            "# Generated by tools/art21_build_main_menu_runtime.py.",
            "# Do not hand-edit asset rows; change the audited builder recipe instead.",
            'const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")',
            "",
            "const ASSET_ID_BY_VISUAL_KEY := {",
        ]
        for record in sorted(self.records, key=lambda item: item.visual_key):
            lines.append(f'\t&"{record.visual_key}": &"{record.asset_id}",')
        lines.extend(["}", "", "const LOAD_GROUP_BY_VISUAL_KEY := {"])
        for record in sorted(self.records, key=lambda item: item.visual_key):
            lines.append(f'\t&"{record.visual_key}": &"{record.load_group}",')
        lines.extend(
            [
                "}",
                "",
                'static func component_ref(visual_key: StringName, role: StringName = &"main_menu_scene") -> Dictionary:',
                "\treturn Art09ManifestAssetMappingScript.asset_ref(",
                '\t\tASSET_ID_BY_VISUAL_KEY.get(visual_key, &""),',
                '\t\t&"ui.main_menu.background.no_text",',
                "\t\trole,",
                "\t\tvisual_key,",
                "\t\ttrue",
                "\t)",
                "",
                "",
                "static func texture(visual_key: StringName) -> Texture2D:",
                "\treturn Art09ManifestAssetMappingScript.resolve_texture(component_ref(visual_key))",
                "",
                "",
                "static func load_group(visual_key: StringName) -> StringName:",
                '\treturn LOAD_GROUP_BY_VISUAL_KEY.get(visual_key, &"")',
                "",
            ]
        )
        output.write_text("\n".join(lines), encoding="utf-8")

def locate_source_root(source_pack: Path) -> Path:
    candidates = [
        source_pack,
        source_pack / "Godot" / "GraytailGodot" / "assets" / "ui" / "main_menu" / "rework",
    ]
    for candidate in candidates:
        if (candidate / "handoff" / "ui_main_menu_rework_full_content_placement.json").is_file():
            return candidate
    raise FileNotFoundError("Unable to locate main_menu/rework handoff root under " + str(source_pack))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-pack", required=True, type=Path)
    parser.add_argument("--clean-plate", required=True, type=Path)
    parser.add_argument("--character-atlas", required=True, type=Path)
    parser.add_argument("--menu-board-atlas", required=True, type=Path)
    parser.add_argument("--repo-root", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = (args.repo_root or Path(__file__).resolve().parents[1]).resolve()
    source_root = locate_source_root(args.source_pack.resolve())
    builder = Builder(source_root, repo_root)
    builder.clean_generated_outputs()
    builder.build_integrated_scene_master()
    builder.build_clean_plate(args.clean_plate.resolve())
    builder.build_full_canvas_layers()
    builder.build_architecture()
    builder.build_character(args.character_atlas.resolve())
    builder.build_environment()
    builder.build_menu(args.menu_board_atlas.resolve())
    builder.build_fx()
    builder.build_transitions()
    builder.write_reports()
    builder.update_asset_manifest()
    builder.write_runtime_contract_script()
    summary = json.loads((builder.validation_root / "main_menu_runtime_asset_report.json").read_text(encoding="utf-8"))
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0 if summary["budget_pass"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
