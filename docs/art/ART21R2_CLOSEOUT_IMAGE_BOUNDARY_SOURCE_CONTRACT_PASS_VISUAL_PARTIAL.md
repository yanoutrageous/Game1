# ART21R2 Closeout - Image Boundary Source Contract Pass / Visual Partial

Status: `CLOSED_PARTIAL`

Branch: `art/art21r2-image-boundary-ui-rework`

Implementation evidence head before closeout: `d89d34debf8ac2db7b0578f351d1c5326d14652e`

Validator: `tools/validate_art21r2_image_boundary_ui.ps1`

Validator result at closeout: `ART21R2_IMAGE_BOUNDARY_VALIDATION=PASS_STRUCTURAL_OPEN`

Visual closeout state: `NOT_COMPLETE_R2_PARTIAL`

## 0. Closeout Boundary

ART21R2 is closed only as an image-boundary and source-contract partial rebuild pass. It does not claim final UI visual completion, Base/UE visual parity, or high-resolution QA completion.

This closeout does not clean or classify away generated/editor dirty state. `Godot/GraytailGodot/project.godot` still needs separate review because it contains real Godot rewrite/config differences, not only harmless generated output.

## 1. What ART21R2 Proved

- P0 visible UI boundaries can be moved away from primary `PanelContainer` / `ColorRect` / `StyleBoxFlat` surfaces and toward image-backed slot assets.
- `ui_placement_contract_v3.csv`, `ART21R2_SOURCE_SLOT_CUTTING_MATRIX.csv`, and `ART21R2_SLOT_GAP_MATRIX.csv` now provide a source-to-slot audit trail for the current R2 pass.
- Main Menu received `Main.png`-lineage title/header/entry plank cuts, replacing the previous modal-control borrowing for the right-side action deck.
- Main Menu still preserves the required route: `Start Exploration` enters Deploy Prep directly, without a map/difficulty selection page.
- Map Overlay received draw-derived event/flag marker cuts from `Zujian2.png`, with sparse live evidence for marker visibility and click-to-unflag behavior.
- Modal family work introduced `Zujian3.png`-lineage modal frame/control/section assets and kept modal presentation inside the main gameplay area rather than covering the left rail.
- Long Term hierarchy was corrected toward the requested family shape: left character area, center content/detail area, and right player/archive status area.
- Run HUD retained the real room/player layer and guarded the existing `Q/G/M` input routes.

## 2. Primary Evidence

- Main Menu source plank evidence:
  - `docs/art/validation/art21r2/screenshots/slice9/godot_main_menu_main_png_planks_pass48_smoke.png`
  - `docs/art/validation/art21r2/screenshots/slice9/godot_deploy_prep_direct_from_main_pass49_smoke.png`
- Map Overlay marker evidence:
  - `docs/art/validation/art21r2/screenshots/slice6/godot_map_overlay_art21r2_sparse_event_flag_pass39_smoke.png`
  - `docs/art/validation/art21r2/screenshots/slice6/godot_map_overlay_art21r2_sparse_flag_click_pass40_smoke.png`
- Slice reports:
  - `docs/art/validation/art21r2/ART21R2_DRAW_SLICE_AUDIT.md`
  - `docs/art/validation/art21r2/ART21R2_SLICE7_SOURCE_INVENTORY_AND_CUTTING_PLAN.md`
  - `docs/art/validation/art21r2/ART21R2_SLICE8_CORE_SCREEN_PRODUCT_HIERARCHY_REPORT.md`
  - `docs/art/validation/art21r2/ART21R2_SLICE9_MAIN_MENU_SOURCE_CUT_REPORT.md`
- Contract and matrices:
  - `docs/art/validation/art21r2/ui_placement_contract_v3.csv`
  - `docs/art/validation/art21r2/ART21R2_SLOT_GAP_MATRIX.csv`
  - `docs/art/validation/art21r2/ART21R2_SOURCE_SLOT_CUTTING_MATRIX.csv`

## 3. Remaining Visual Gaps

- Main Menu title lettering is still runtime text over an image-backed board. It is not yet a final authored title graphic.
- Main Menu button typography, state treatment, selection feedback, and high-resolution fit are still partial.
- Deploy Prep has the correct direct route and broad page family, but left character equipment, center route cards/details, and right summary/action stack still need stronger product-level treatment.
- Long Term now follows the corrected left-character / center-content-detail / right-player-profile structure, but card content, selected-state hierarchy, and profile/detail density remain partial.
- Run HUD still needs refinement of the left rail, minimap density, right status card, bottom command overlay, and modal readability.
- Map Overlay marker cuts are improved, but title/footer/detail panel hierarchy and grid readability remain partial.
- Inventory, GroundLoot, and Result modal family work is still partial. GroundLoot still needs reliable live-path evidence where applicable.
- Most visual evidence is `856x511` smoke evidence. It proves live display and route behavior, not final `1280/1600/1920` QA.

## 4. Dirty / Generated State at Closeout

Do not clean or reset as part of this closeout:

- `Godot/GraytailGodot/data/assets/asset_manifest.*.translation` remains generated/editor dirty.
- `Godot/GraytailGodot/project.godot` remains dirty and requires separate audit.
- `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd` may still appear modified despite no effective text diff in the closeout audit.
- Old failed Result smoke screenshots and `tools/__pycache__/` may remain untracked.

## 5. Closeout Conclusion

ART21R2 can be closed as `image-boundary source-contract pass / visual partial`.

It should not be presented as final UI completion. The next phase should start from the R2 source/slot contract, retain the proven direct routes and real runtime layer behavior, and focus on product-level visual hierarchy, authored title/label assets, high-resolution QA, and per-screen polish against the selected reference targets.
