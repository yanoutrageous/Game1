# ART21R2 Slice 3 Run Input And Layer Report

Status: PARTIAL

This report covers the first ART21R2 execution slice applied after the baseline
lock. It does not mark the overall ART21R2 visual goal complete.

## Scope

- Preserve the existing main menu click flow: `Start Exploration` routes directly
  to Deploy Prep.
- Do not add area, map, or difficulty selection screens.
- Reduce meaningless in-run generated layers.
- Make HUD key prompts match keyboard behavior.
- Keep real `RoomLayer` / `PlayerLayer` world rendering from ART21R1.

## Code Changes

- `run_scene_input_router.gd`
  - Added `Q` -> inventory, `G` -> ground loot, and `T` -> request extract.
- `run_scene.gd`
  - Routed the new run actions to the existing inventory, ground loot, and extract
    UI handlers.
- `art10_ui_skin_kit.gd`
  - Added transparent button style helpers for image-backed hitboxes.
- `run_surface.gd`
  - Hid generated stat/backpack/status glow subpanels that were adding extra
    in-run layers.
  - Changed bottom HUD action buttons to transparent hitboxes over the ART21
    bottom overlay image.
  - Removed the no-action placeholder panel; the encounter/action prompt is now
    hidden when there is no executable option.
- `map_overlay_panel.gd`
  - Removed generated Button `StyleBoxFlat` borders from map cells so the cell
    image assets own the visible boundary.

## Evidence

| Evidence | File | Result |
| --- | --- | --- |
| Window click path | `screenshots/slice3/godot_deploy_prep_after_slice3.png` | Main menu click reached Deploy Prep directly; no extra area/map/difficulty screen was inserted. |
| Logic main menu | `screenshots/slice3/godot_main_menu_after_slice3_logic.png` | Full 1280x720 viewport reference after code changes. |
| Logic deploy prep | `screenshots/slice3/godot_deploy_prep_after_slice3_logic.png` | Full deploy prep remains the direct target screen. |
| Logic long term | `screenshots/slice3/godot_long_term_after_slice3_logic.png` | Long-term page captured for family comparison; still not visually complete. |
| Logic run HUD | `screenshots/slice3/godot_run_hud_after_slice3_logic.png` | No no-action floating placeholder; real room/player layer preserved. |
| Logic Q inventory | `screenshots/slice3/godot_inventory_q_after_slice3_logic.png` | Inventory opens from the run screen. |
| Logic map overlay | `screenshots/slice3/godot_map_overlay_after_slice3_logic.png` | Map cells use image-backed hitboxes without generated Button borders. |

## Current Verdict

PASS for this slice:

- `Q` now opens inventory.
- `G` and `T` are routed to their existing UI handlers.
- Main menu deploy route remains direct to Deploy Prep.
- The no-action in-run placeholder panel is removed.
- Map cell generated Button borders are removed.
- R1 duplicate fake room/player layer guards remain intact.

PARTIAL for the larger ART21R2 target:

- Run HUD still reads below the UE visual floor.
- Bottom key text is less noisy but still weak in contrast/readability.
- Inventory modal opens but overlaps the left HUD rail and still uses generated
  row/button treatment.
- Deploy Prep and Long Term remain mostly baseline visual quality after this
  slice.
- Main menu still uses a flat terminal action deck rather than the UE physical
  board/plank target.

## Validation

- Godot headless: exit code `0`; pre-existing resource-leak warnings still appear
  on exit.
- `tools/validate_art21r2_image_boundary_ui.ps1`: expected to remain
  `PASS_STRUCTURAL_OPEN`, not visual closeout.
