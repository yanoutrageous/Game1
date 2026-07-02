# ART-21R1 UE Parity Comparison

## Scope

This comparison uses Computer Use screenshots from:

- UE reference: `screenshots/ue_main_menu.png`, `screenshots/ue_area_select.png`, `screenshots/ue_difficulty_select.png`, `screenshots/ue_run_hud.png`, `screenshots/ue_map_overlay.png`
- Godot before: `screenshots/godot_*_before.png`
- Godot after: `screenshots/godot_main_menu_after.png`, `screenshots/godot_deploy_prep_after.png`, `screenshots/godot_run_hud_after.png`, `screenshots/godot_map_overlay_after.png`, `screenshots/godot_inventory_after.png`, `screenshots/godot_result_after.png`

UE inventory / loot / event was not naturally triggered from the sampled UE initial run. Godot ground loot was not naturally triggered from the sampled Godot run. These are not claimed as passed live parity.

User correction after the first ART-21R1 repair pass: Godot should preserve the existing click contract. Clicking `出发探索` on the main menu must go directly to the Deploy Prep screen. Area, difficulty, and map choice belong inside Deploy Prep, not as extra main-menu pages. UE area/difficulty screenshots remain reference observations only and are not Godot acceptance targets in this pass.

## Comparison Table

| Area | UE floor observed | Godot after | Status | Remaining gap |
| --- | --- | --- | --- | --- |
| main_menu | Full scene background, left hanging board, right physical board, plank-like options, no generic tooltip layer. | Uses the same imported background family at high visibility; removes the old left line-frame overlays; right board holds large options and disables tooltips. Clicking `出发探索` keeps the original direct route to Deploy Prep. | PARTIAL_PASS | Right options still read as terminal buttons more than authored wooden planks. Settings / exit remain generic menu entries. |
| deploy_prep route | UE has richer selection states, but the Godot product contract keeps map/difficulty/config inside Deploy Prep. | Main menu `deploy` entry emits the model-defined `TARGET_DEPLOY`; no extra area/difficulty main-menu pages are added. | PASS | Deploy Prep itself remains contract-era and needs a later visual page-family rebuild. |
| run_hud | Room/player/object world layer is primary; left rail fixed; right top card compact; bottom key bar overlays without cutting the room away. | Keeps the real `RoomLayer/PlayerLayer` as the only world rendering authority, hides RunSurface's former UI room/player duplicate layers, removes permanent room text masks, hides the right fill layer, and suppresses large success feedback. | PARTIAL_PASS | Left minimap is larger and more table-like than UE. Bottom key bar remains heavy. Real player placement still depends on RunScene gameplay/local-position state. |
| map_overlay | Modal dim layer over run HUD, centered map grid, clear cells and markers. | Adds stronger dimmer, centered panel, square cell sizing, and denser marker styling. | PARTIAL_PASS | Cells are still abstract UI squares and less readable than UE map tiles/markers. |
| modal inventory/result | Modal overlays are acceptable; focus should return to run HUD. | Inventory and result modal screenshots captured. Result is reachable from confirmed pause exit. | PARTIAL_PASS | Inventory has no dedicated key route in `RunSceneInputRouter`; it was opened through the bottom Q-labeled button. |
| text/backplate policy | Text sits on physical surfaces where possible; modal text remains in modal frames. | Main menu tooltips removed, run room top text mask hidden, command feedback is state-triggered, map/inventory/result remain modal. | PARTIAL_PASS | Deploy / long-term still contain many nested generic frames outside the main ART-21R1 code changes. |
| input/focus | Main menu and run overlays are clickable and keyboard-assisted; modals close cleanly. | Main menu deploy click opens Deploy Prep directly; M opens map; inventory button opens modal; pause exit confirms result. | PARTIAL_PASS | Q label does not correspond to a keyboard inventory action in the runtime router. Ground loot was not naturally triggered. |

## Objective Judgment

ART-21R1 improves the most severe visual failure: Run HUD no longer treats the room as a background behind a generated UI frame, and a follow-up correction removes the duplicated UI room/player layers so the real `RoomLayer/PlayerLayer` remains authoritative. Main menu is cleaner while preserving its original deploy click route. Map and modals are usable.

The stage should not be called a full UE parity pass because MapOverlay is still visually below UE, Deploy / Long-term were not rebuilt in this pass, and the inventory key path is inconsistent with its Q label.

Closeout classification:

```text
PARTIAL: ue_parity_floor_partial / blockers_listed
```
