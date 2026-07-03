# ART21R2 Slice 6 Modal Main-Game-Center Report

## Status

PARTIAL. Pass34 proves that Inventory, GroundLoot, and Result can render from
image-backed modal assets inside the main gameplay region without covering the
left information rail. It also proves non-empty Inventory and GroundLoot rows
through an explicit debug-smoke seed. This is not ART21R2 visual closeout and is
not natural loot progression completion.

## Scope

- Preserve the existing main-menu click path: `Start Exploration` still routes
  directly to Deploy Prep. No extra map, area, or difficulty selection screen was
  introduced.
- Preserve existing runtime input: `Q` opens Inventory and `G` opens GroundLoot.
- Keep item actions on the existing Inventory/GroundLoot signals and CommandBus
  paths. No new player-facing item click flow was added.
- Reposition runtime modals so they are centered in the main gameplay area,
  similar to the expanded map overlay, instead of occupying the left information
  rail.

## Implementation Notes

- `run_scene.gd` adds `--art21r2-seed-modal-items` as a debug/editor-only smoke
  flag. When and only when that flag is present after a successful run start, it
  reuses existing CommandBus debug commands:
  `debug_spawn_test_item_floor` and `debug_spawn_test_item_backpack`.
- `inventory_panel.gd`, `ground_loot_panel.gd`, and `result_panel.gd` now compute
  modal position from `UILayerContract.run_left_width(profile)` and center within
  the remaining main gameplay region.
- The modal visual boundary remains the existing Zujian3 draw-sliced ART21R2
  image family. Code only changes layout placement and smoke seeding.

## Live Evidence

- Direct main-menu route to Deploy Prep:
  `screenshots/slice6/godot_deploy_prep_direct_from_main_pass34_smoke.png`.
- Run HUD after standard start with explicit smoke seed:
  `screenshots/slice6/godot_run_hud_modal_seed_pass34_smoke.png`.
- Inventory via existing `Q` route, non-empty seeded row, main-game centered:
  `screenshots/slice6/godot_inventory_nonempty_main_game_center_pass34_smoke.png`.
- GroundLoot via existing `G` route, non-empty seeded floor rows, main-game
  centered:
  `screenshots/slice6/godot_ground_loot_nonempty_main_game_center_pass34_smoke.png`.
- Result via existing Pause -> Exit current run double-confirm route, main-game
  centered:
  `screenshots/slice6/godot_result_main_game_center_pass34_smoke.png`.

All pass34 screenshots are 856x511 smoke evidence only. They must not be used as
high-resolution QA proof.

Validator phrase: without covering the left information rail.

## Result

- Inventory item rows: `PARTIAL`. Non-empty row rendering is now proven through a
  debug-smoke seed and uses image-backed row/button assets, but detail hierarchy
  and text fit remain below the UE floor.
- GroundLoot item rows: `PARTIAL`. Non-empty floor rows are now proven through a
  debug-smoke seed and use image-backed row/button assets, but natural gameplay
  discovery is still not the evidence path for this pass.
- Result modal: `PARTIAL`. The modal no longer covers the left rail and the
  image-backed frame/sections/actions are visible, but reward hierarchy and
  button contrast remain below the UE floor.
- Runtime placement: `PASS_FOR_LAYOUT_GUARD`. The left information rail remains
  visible while modals are open.

## Remaining Gaps

- Replace debug-smoke seed with natural deterministic loot progression evidence
  before claiming full GroundLoot completion.
- Improve typography, title/close placement, and action contrast in the modal
  family.
- Broaden screenshot QA beyond 856x511 smoke captures before any closeout claim.
- ART21R2 remains `NOT_COMPLETE_R2_PARTIAL`.
