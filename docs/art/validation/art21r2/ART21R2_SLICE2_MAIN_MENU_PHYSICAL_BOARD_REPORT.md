# ART21R2 Slice 2 Main Menu Physical Board Report

Status: PARTIAL

This report records the Slice 2 main menu change only. It does not mark
ART21R2 complete.

## Scope

- Replace the active main menu right-side terminal rectangle with the physical
  wooden board already present in the background image.
- Preserve the existing `Start Exploration` click route.
- Do not add area, map, or difficulty selection screens.
- Keep the map/route content inside Deploy Prep.

## Code Changes

- `main_menu_shell.gd`
  - `_build_menu_panel()` now delegates to `_build_physical_menu_panel()` in the
    active path.
  - Physical menu entries are positioned over the right-side wooden planks.
  - Entry buttons use transparent hitboxes and still call `_emit_entry(entry)`.
  - The deploy entry signal path was not replaced by a direct `show_deploy`
    call.

## Evidence

| Evidence | File | Result |
| --- | --- | --- |
| Main menu after Slice 2 | `screenshots/slice2/godot_main_menu_after_slice2_logic.png` | Terminal rectangle is removed from the active path; actions sit on the building board. |
| Deploy click route | `screenshots/slice2/godot_deploy_prep_from_main_click_slice2_logic.png` | Triggering the deploy button `pressed` signal reaches Deploy Prep directly. |
| Run HUD blocker | `screenshots/slice2/godot_run_hud_extra_layers_blocker_slice2_logic.png` | In-run HUD still has visible old/code-owned layer boundaries and remains incomplete. |

## Current Verdict

PASS for the route guard:

- `Start Exploration` still opens Deploy Prep directly.
- No new area, map, or difficulty selection page was inserted.
- Deploy map/route content remains inside Deploy Prep.

PARTIAL for Slice 2 visuals:

- The active right-side terminal overlay is gone.
- The building plank art now owns the main visible boundary.
- Text and icons are still not well fitted to the plank surfaces.
- The main title remains runtime text rather than integrated sign art.

FAIL/PARTIAL for the larger ART21R2 target:

- Run HUD still shows old/code-owned visible layers, including the left rail,
  compact protocol/status card, and bottom hotkey overlay.
- Deploy Prep still has substantial generated panel/card/button boundaries.
- Therefore ART21R2 cannot be marked as visual target complete.

## Validation

- Godot headless: exit code `0`; pre-existing resource-leak warnings still
  appear on exit.
- Screenshot route evidence used the deploy button `pressed` signal, not a
  direct test-only `show_deploy` call.
