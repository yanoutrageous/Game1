from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "build_base_governance_overlay.py"
SPEC = importlib.util.spec_from_file_location("base_governance_overlay", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
OVERLAY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(OVERLAY)


class BaseGovernanceOverlayTest(unittest.TestCase):
    def test_verify_outputs_accepts_checkout_newline_materialization(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "overlay.csv"
            output.write_bytes(b"key,value\r\none,two\r\n")

            diagnostics = OVERLAY.verify_outputs(
                {output: b"key,value\none,two\n"},
                [],
            )

            self.assertEqual([], diagnostics)

            output.write_bytes(b"key,value\r\none,changed\r\n")
            diagnostics = OVERLAY.verify_outputs(
                {output: b"key,value\none,two\n"},
                [],
            )
            self.assertEqual(1, len(diagnostics))
            self.assertIn("OVERLAY_DRIFT", diagnostics[0])

    def test_semantic_family_is_independent_from_lifecycle(self) -> None:
        fixtures = {
            "sources/art/05_export_runtime_candidates/map_tile_icon/map_tile_explored.png": "map",
            "sources/art/05_export_runtime_candidates/item_consumable/item_consumable_medkit.png": "item",
            "sources/draw/30_game_ready/props/00_baoxiang_kai.png": "world_prop",
            "sources/art/05_export_runtime_candidates/ui_deploy_button/ui_button_nav_warehouse.png": "deploy",
            "sources/art/ART-20/03_cut_output/run_hud/run_bottom_key_bar_button/run_bottom_key_bar_button_ui_button_blank_dark.png": "ui_component",
        }
        for path, expected in fixtures.items():
            with self.subTest(path=path):
                actual = OVERLAY.semantic_family([path], ".png")
                self.assertEqual(expected, actual)
                self.assertNotEqual("actor_animation_source", actual)

        self.assertEqual(
            "game_ready_source;runtime_candidate",
            OVERLAY.lifecycle_role(
                [
                    {"source_layer": "05_export_runtime_candidates"},
                    {"source_layer": "30_game_ready"},
                ]
            ),
        )

    def test_semicolon_consumers_are_independent_entries(self) -> None:
        self.assertEqual(
            ["first.gd", "second.gd", "third.gd"],
            OVERLAY.split_declared_consumers(
                "first.gd; second.gd ;third.gd"
            ),
        )

    def test_mapping_requires_a_production_consumer(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary)
            project = repo / "Godot" / "GraytailGodot"
            mapping = project / "scripts" / "presentation" / "sample_mapping.gd"
            consumer = project / "scripts" / "ui" / "real_panel.gd"
            direct_consumer = project / "scripts" / "ui" / "direct_panel.gd"
            scene_consumer = project / "scenes" / "ui" / "icon_panel.tscn"
            test_only = project / "tests" / "fake_runner.gd"
            manifest = project / "data" / "assets" / "asset_manifest.csv"
            for path in (
                mapping,
                consumer,
                direct_consumer,
                scene_consumer,
                test_only,
                manifest,
            ):
                path.parent.mkdir(parents=True, exist_ok=True)
            mapping.write_text(
                "extends RefCounted\n"
                "class_name SampleMapping\n"
                'const ICON := &"icon.sample"\n',
                encoding="utf-8",
            )
            consumer.write_text(
                "extends Control\n"
                "func draw_icon() -> void:\n"
                "\tvar value = SampleMapping.ICON\n",
                encoding="utf-8",
            )
            direct_consumer.write_text(
                'const ICON := &"icon.direct"\n', encoding="utf-8"
            )
            scene_consumer.write_text(
                '[ext_resource type="Texture2D" '
                'path="res://scene.png" id="1"]\n',
                encoding="utf-8",
            )
            test_only.write_text(
                'const SELF_PROOF := &"icon.sample"\n'
                'const STAGED_ONLY := &"icon.staged"\n',
                encoding="utf-8",
            )
            manifest.write_text(
                "asset_id,godot_path\nicon.sample,res://sample.png\n",
                encoding="utf-8",
            )

            index = OVERLAY.load_runtime_text_index(project)
            kind, evidence, resolution = OVERLAY.consumer_binding(
                repo,
                project,
                index,
                {
                    "asset_id": "icon.sample",
                    "godot_path": "res://sample.png",
                    "theme_key": "",
                    "linked_scene": "scripts/presentation/sample_mapping.gd",
                },
                False,
            )
            self.assertEqual("dynamic_contract", kind)
            self.assertIn("scripts/ui/real_panel.gd:3->", evidence)
            self.assertNotIn("/tests/", evidence)
            self.assertNotIn("asset_manifest.csv", evidence)
            self.assertIn("[contract]", resolution)

            direct_kind, direct_evidence, _ = OVERLAY.consumer_binding(
                repo,
                project,
                index,
                {
                    "asset_id": "icon.direct",
                    "godot_path": "res://direct.png",
                    "theme_key": "",
                    "linked_scene": "scripts/ui/direct_panel.gd",
                },
                False,
            )
            self.assertEqual("direct_token", direct_kind)
            self.assertIn("scripts/ui/direct_panel.gd:1", direct_evidence)

            scene_kind, scene_evidence, _ = OVERLAY.consumer_binding(
                repo,
                project,
                index,
                {
                    "asset_id": "icon.scene",
                    "godot_path": "res://scene.png",
                    "theme_key": "",
                    "linked_scene": "scenes/ui/icon_panel.tscn",
                },
                False,
            )
            self.assertEqual("scene_resource", scene_kind)
            self.assertIn("scenes/ui/icon_panel.tscn:1", scene_evidence)

            staged_kind, staged_evidence, _ = OVERLAY.consumer_binding(
                repo,
                project,
                index,
                {
                    "asset_id": "icon.staged",
                    "godot_path": "res://staged.png",
                    "theme_key": "",
                    "linked_scene": "tests/fake_runner.gd",
                },
                True,
            )
            self.assertEqual("staging_no_consumer", staged_kind)
            self.assertEqual(
                "no_production_consumer_proven", staged_evidence
            )


if __name__ == "__main__":
    unittest.main()
