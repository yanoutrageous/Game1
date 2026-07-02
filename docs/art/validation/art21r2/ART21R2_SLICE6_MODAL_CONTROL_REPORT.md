# ART21R2 Slice 6 Modal Control Report

## Status

PARTIAL. This pass moves visible modal row/button boundaries away from default
Godot button styling and onto draw-sliced Zujian3 runtime assets. It does not
complete modal information hierarchy, non-empty inventory/ground-loot row
validation, or final button contrast.

## Source And Cutting Path

- Source sheet: `D:\AGAME1\sources\draw\Zujian3.png`.
- Normal row/button source: `Zujian3_candidate_005.png`.
- Danger button source: `Zujian3_candidate_008.png`.
- Staging manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_staging_manifest.csv`.
- Dry-run plan:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_cut_dry_run_plan.csv`.
- Cut manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_cut_manifest.csv`.
- Cut summary:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_cut_summary.json`.
- Script: `tools/art21r2_cut_modal_control_assets.py`.

Dry-run was executed before runtime write. Candidate 005 cleaned from 1297
purple-like pixels to 0; candidate 008 cleaned from 1184 purple-like pixels to
0.

## Runtime Assets

- `ui.art21r2.modal.item_row.normal` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_item_row_normal.png`.
- `ui.art21r2.modal.button.primary` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_button_primary.png`.
- `ui.art21r2.modal.button.secondary` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_button_secondary.png`.
- `ui.art21r2.modal.button.danger` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_button_danger.png`.

## Godot Changes

- `art21_ui_placement_contract.gd` maps the modal control visual keys and
  exposes `style_box_for_visual_key()` for image-owned button skins.
- `InventoryPanel` uses ART21R2 modal image assets for close, item row, use,
  and drop buttons.
- `GroundLootPanel` uses ART21R2 modal image assets for close, item row,
  pickup, and replace buttons.
- `ResultPanel` uses ART21R2 modal image assets for return buttons and moves the
  action row upward so it is not clipped by the modal frame.

## Live Evidence

- Inventory via existing Q route:
  `screenshots/slice6/godot_inventory_zujian3_modal_controls_pass29_smoke.png`.
- GroundLoot via existing G route:
  `screenshots/slice6/godot_ground_loot_zujian3_modal_controls_pass29_smoke.png`.
- Result via existing Pause -> Exit current run double-confirm abandon route:
  `screenshots/slice6/godot_result_zujian3_modal_controls_pass30_smoke.png`.

## Remaining Gaps

- The current live run has no non-empty inventory or ground-loot item rows, so
  item-row image assets are registered and wired but not visually proven in a
  non-empty live row screenshot.
- Result action buttons are no longer default Godot buttons, but the dark
  control asset still has weak contrast against the modal bottom band.
- The title plate, summary text hierarchy, and reward/item sections still need a
  dedicated image-boundary pass.
