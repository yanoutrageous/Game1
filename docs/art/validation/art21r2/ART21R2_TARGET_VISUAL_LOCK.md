# ART21R2 Target Visual Lock

Stage: ART-21R2 - image-boundary driven core UI visual rework

Status: NOT_COMPLETE_BASELINE

This document locks the visual target before execution. It is not a closeout and
does not mark the ART21 visual goal complete.

## Repository Baseline

- Branch at capture: `art/art21r2-image-boundary-ui-rework`
- Baseline HEAD: `3dbb843e34f16a9a10b7122a0e094c457a7057c6`
- Expected pre-existing dirty files: Godot/editor generated `project.godot` and
  `asset_manifest.*.translation`
- New R2 evidence path: `docs/art/validation/art21r2/screenshots`
- No dirty cleanup, reset, stash, main push, or UE asset import is part of this
  stage.

## Source Boundary

- Active docs entry is under `docs/`.
- External sources are references only. UE is read-only at
  `D:\A GAME\26.6\UE\Graytail`; UE paths and assets are not canonical runtime
  paths.
- Current source roots are the roots registered by governance:
  `D:\AGAME1\sources\docs`, `D:\AGAME1\sources\docs_governance`,
  `D:\AGAME1\sources\art`, `D:\AGAME1\sources\draw`, and
  `D:\AGAME1\handoff\connection`.

## Locked Product Constraints

- Main menu `Start Exploration` must route directly to Deploy Prep. ART21R2 must
  not add an area, map, or difficulty selection screen between main menu and
  Deploy Prep.
- The map is already part of Deploy Prep. ART21R2 must not require an extra main
  menu click to reach a map-selection screen.
- Run HUD target remains: fixed left information rail, large near-square room
  playfield on the right, compact top-right status card, and bottom overlay.
- Generated `PanelContainer`, `ColorRect`, `StyleBoxFlat`, or green line frames
  must not be the primary visible UI boundary for P0 slots.
- Code may own layout, text, icons, state, input, and interaction. Image assets
  must own visible panel, button, slot, and modal boundaries.
- Runtime mapping must remain slot based through `screen`, `layer`, `slot`,
  `visual_key`, `asset_id`, and consumer script/function references.

## Reference Targets

| Evidence | File | Use |
| --- | --- | --- |
| UE main menu reference | `screenshots/baseline/ue_main_menu_reference.png` | Physical board and plank-menu target floor |
| UE run HUD reference | `screenshots/baseline/ue_run_hud_reference.png` | Fullscreen overlay layering and focus priority |
| UE map overlay reference | `screenshots/baseline/ue_map_overlay_reference.png` | Modal grid target floor |
| Godot main menu baseline | `screenshots/baseline/godot_main_menu_baseline.png` | R1 baseline for R2 comparison |
| Godot deploy prep baseline | `screenshots/baseline/godot_deploy_prep_baseline.png` | R1 baseline for R2 comparison |
| Godot long term baseline | `screenshots/baseline/godot_long_term_baseline.png` | R1 baseline for R2 comparison |
| Godot run HUD baseline | `screenshots/baseline/godot_run_hud_baseline.png` | R1 baseline for R2 comparison |
| Godot map overlay baseline | `screenshots/baseline/godot_map_overlay_baseline.png` | R1 baseline for R2 comparison |
| Godot inventory baseline | `screenshots/baseline/godot_inventory_button_baseline.png` | R1 baseline for R2 comparison |
| Godot result baseline | `screenshots/baseline/godot_result_baseline.png` | R1 baseline for R2 comparison |

UE was attempted from the specified local project. The visible Computer Use
capture exposed only a launch/message window, so R2 baseline also copies the R1
UE reference screenshots for comparison continuity. This limitation must stay
visible in closeout evidence.

## Baseline Verdict

The baseline is PARTIAL, not PASS.

- Main menu has a strong background and direct deploy route, but the right menu
  is still dominated by a rectangular terminal frame rather than the UE physical
  board/plank target.
- Deploy Prep has the correct high-level three-column product structure, but
  many visible cards, tabs, slots, and buttons are still generated UI frames.
- Long Term is in the same page family as Deploy Prep, but still reads as a
  generated dashboard instead of a complete archive/product surface.
- Run HUD uses the real room/player layers after R1, but left rail, right status,
  and bottom key bar remain visibly code-framed.
- Map overlay uses runtime map cells and modal behavior, but the modal panel and
  cell/button states remain too code-generated.
- Inventory, Ground Loot, and Result have frame images, but item rows and command
  buttons still need stronger image-boundary treatment.

## Acceptance Lock

ART21R2 may close only when:

- Every P0 slot in `ui_placement_contract_v3.csv` has an image-owned visible
  boundary or a documented modal scrim exception.
- Baseline screenshots are paired with after screenshots for main menu, deploy
  prep, long term, run HUD, map overlay, inventory, ground loot, and result.
- Main menu still routes directly to Deploy Prep with no new area/map/difficulty
  intermediate screen.
- Run HUD contains no duplicate fake room/player/image layers over the real
  room scene.
- Keyboard prompts shown in the bottom HUD match actual input behavior.
- Validator passes structurally, while visual status is reported honestly as
  PASS, PARTIAL, or FAIL in closeout.
