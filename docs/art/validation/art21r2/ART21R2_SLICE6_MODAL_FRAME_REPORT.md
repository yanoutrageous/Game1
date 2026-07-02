# ART21R2 Slice 6 Modal Frame Report

## Status

PARTIAL. This pass replaces the Inventory, GroundLoot, and Result modal frame
asset source from ART-21 generated frames to a draw-sliced Zujian3 physical
modal frame. It does not complete item rows, command buttons, title plates, or
overall modal typography.

## Source And Cutting Path

- Source sheet: `D:\AGAME1\sources\draw\Zujian3.png`.
- Source candidate: `D:\AGAME1\sources\draw\10_working\candidates\Zujian3\Zujian3_candidate_001.png`.
- Staging manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_staging_manifest.csv`.
- Dry-run plan:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_cut_dry_run_plan.csv`.
- Cut manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_cut_manifest.csv`.
- Cut summary:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_cut_summary.json`.
- Script: `tools/art21r2_cut_modal_assets.py`.

Dry-run was executed before runtime write. The candidate purple/fringe count
was 3690 before cleanup and 0 after cleanup under the script rule. Runtime PNG
write was then executed with `--write-runtime --force` only to replace the
first same-turn incorrect cleanup output.

## Runtime Assets

- `ui.art21r2.modal.inventory.frame` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_inventory_frame.png`.
- `ui.art21r2.modal.ground_loot.frame` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_ground_loot_frame.png`.
- `ui.art21r2.modal.result.frame` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_result_frame.png`.

All three assets share cut hash
`7CBB46D500EE5E620BD10152BC7F6FDA9D0199958C5A7666482035CFCD1F1104`
because they currently use the same approved modal frame family crop.

## Godot Changes

- `art21_ui_placement_contract.gd` now maps the three modal slots to
  `ui.art21r2.modal.*` asset ids.
- `InventoryPanel` and `GroundLootPanel` use 38px texture margins and 30px
  content margins for the Zujian3 frame.
- `ResultPanel` hides the legacy `Backdrop` ColorRect if present and uses a
  `NinePatchRect` for `ResultModalFrame`.

## Live Evidence

- Inventory via existing Q route:
  `screenshots/slice6/godot_inventory_zujian3_modal_frame_pass28_smoke.png`.
- GroundLoot via existing G route:
  `screenshots/slice6/godot_ground_loot_zujian3_modal_frame_pass28_smoke.png`.
- Result via existing Pause -> Exit current run double-confirm abandon route:
  `screenshots/slice6/godot_result_zujian3_modal_frame_pass28_smoke.png`.

The T extraction route was also tested from the spawn room and correctly did
not open Result because extraction was not available there. That blocked T path
was not used as Result evidence.

## Remaining Gaps

- Inventory and GroundLoot row/button surfaces are still not image-owned enough.
- Result title art, summary typography, and return buttons still need a
  dedicated image-boundary pass.
- The Run HUD underneath these modals still has visual-density issues and must
  not be marked complete.
- This pass improves frame material only. It does not establish final product
  composition for Inventory, GroundLoot, or Result.
