# ART-21 Slice 0: Execution Logic Gap Report

## Scope

This report compares the Lua prototype, the UE prototype, and the current Godot UI implementation before ART-21 runtime placement work.

## Findings

| Area | Lua / UE fact | Godot pre-ART21 gap | ART-21 action |
| --- | --- | --- | --- |
| Run HUD layout | Lua HUD separates left info, center play area, right protocol, and bottom command bar. UE GameHud layers room view underneath left rail, top-right protocol, bottom keys, overlays, and modals. | `RunSurface.apply_layout_profile` hid the gameplay viewport by setting core room rects to zero and `visible=false`. | Restore a large near-square gameplay viewport, keep the left rail, add a small top-right status card, and use bottom overlay without shrinking the viewport. |
| UI asset registry | Lua `UITheme` is key-to-image with fallback. UE uses style helpers and 9-slice brushes. | ART-20 proved visual_key to runtime asset import, but no authoritative placement index existed. | Add `ui_placement_contract.csv` plus `Art21UIPlacementContract` runtime mirror. |
| Page family structure | UE DeployTerminal uses left context, center content, right summary, bottom action. Long-term user target shares that family. | Godot deploy and long-term shells used ART-19 generic panel textures and hard-coded placement without screen-slot authority. | Bind deploy and long-term page slots to ART-21 slot refs. |
| Main menu | UE main menu uses a background with anchored hot zones; selection state is independent from the background. | Godot main menu had real background and buttons, but action deck remained a generic ART-19 panel. | Replace the action deck frame through ART-21 contract while preserving existing input. |
| Map overlay | Lua and UE map overlays split layout/draw/click and support close, flag, and return. | Godot MapOverlay still used ART-19 map64 aliases; event markers fell back to scanned cells. | Add ART-21 unknown/explored/scanned/flagged cells and player/exit/mine/chest/event markers. |
| Modals | UE loot/result are modal layers above the HUD. | Inventory/ground loot/result panels did not consume screen-specific ART-21 modal frames. | Add slot-backed frames for inventory, ground loot, and result. |

## Required Screen Matrix

| screen | current Godot owner | Lua owner | UE owner | layer model | input / focus model | state model | visual gap | code coupling gap | asset gap |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| main_menu | `scripts/ui/main_menu/main_menu_shell.gd` | no direct Lua shell; Lua theme registry pattern only | `GT_MainMenuWidget.cpp` | standalone full-screen shell | menu navigation intent; UE has anchored hot-zone selection | button enabled / selected / notice state | action deck was generic ART-19 panel over background | screen used direct ART-19 refs without placement contract | needed `main_menu.action_deck_frame` runtime slot |
| deploy_prep | `scripts/ui/deploy_prep/deploy_prep_shell.gd` | no direct Lua page; HUD loadout facts inform left/info layout | `GT_DeployTerminalWidget.cpp` | left character, center route, right summary, bottom action | deploy intent buttons; UE separates navigation and confirm | preview / continue / abandon / risk summary | missing Base-like page-family product frame | hard-coded ART-19 panels and button texture refs | ART-20 blocked `deploy_left_character_frame` needed replacement |
| long_term | `scripts/ui/long_term/long_term_shell.gd` | no direct Lua page; theme/fallback pattern applies | no exact UE long-term page; DeployTerminal page family is the closest structural reference | left profile, center collection wall, right details | tab and back navigation | selected tab / detail context | profile and collection surfaces lacked page-family framing | generic panels were not bound to semantic slots | ART-20 blocked `longterm_left_character_profile` needed replacement |
| run_hud | `scripts/ui/run_surface/run_surface.gd` | `HUD.lua` | `GT_GameHudWidget.cpp` | left fixed info, near-square room view, top-right status, bottom overlay | run input router plus overlays; UE focus priority keeps modals above HUD | room snapshot, command feedback, protocol/status | gameplay viewport was effectively hidden and layout read as left/middle/right rails | room visuals were resolved ad hoc instead of slot-backed | ART-20 blocked `run_gameplay_viewport_background` needed replacement |
| map_overlay | `scripts/ui/map_overlay/map_overlay_panel.gd` | `MapOverlay.lua` | `GT_MapOverlayWidget.cpp` | modal mask plus centered scalable grid | close / flag / teleport or return; modal focus | unknown / explored / scanned / flagged / marker states | event and cell states fell back through ART-19 aliases | marker visual state mapping was not contract-owned | ART-20 blocked `map_overlay_cell_64_set` and `map_overlay_event_marker_64` needed replacement |
| inventory | `scripts/ui/inventory/inventory_panel.gd` | HUD modal overlay pattern only | `GT_LootResultWidget.cpp` modal layering reference | HUD overlay modal | item actions should not resize run HUD | list selection / empty / capacity state | modal frame was generic and not a screen slot | panel style was local rather than contract-backed | needed inventory modal frame |
| ground_loot | `scripts/ui/ground_loot/ground_loot_panel.gd` | HUD modal overlay pattern only | `GT_LootResultWidget.cpp` modal layering reference | HUD overlay modal | pickup / replace / close should return focus to run HUD | loot list / replace / blocked capacity | live visual modal was not naturally triggered in sampled run | code can consume slot, but validation path lacks stable floor-item fixture | needed ground-loot modal frame and later live trigger evidence |
| result | `scripts/ui/result/result_panel.gd` | no direct Lua page; run completion feedback pattern only | `GT_LootResultWidget.cpp` | result modal above run shell | return main / return deploy focus | success / abandon / lost result state | backdrop and title existed but modal frame was not slot-backed | result art partly came from legacy title assets | needed result modal frame |

## Constraints Kept

- No Lua or UE source was modified.
- No gameplay core, command semantics, run save/load, or persistence behavior was changed.
- No external source root was treated as canonical runtime path.
- Existing Godot/editor generated dirty was not reset, cleaned, or stashed.

## Residual Risks

- Current local `project.godot` still has pre-existing actual config differences and remains marked as needing separate audit.
- Computer Use could not naturally trigger `ground_loot` in the sampled run because the room had no floor items; the evidence screenshot is explicitly marked `not_triggered`.
- `--script` screenshot runner was rejected because project Autoload globals are not available in that mode; Computer Use screenshots are the authoritative visual evidence for this slice.
