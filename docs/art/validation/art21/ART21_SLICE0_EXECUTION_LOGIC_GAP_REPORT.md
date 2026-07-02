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

## Constraints Kept

- No Lua or UE source was modified.
- No gameplay core, command semantics, run save/load, or persistence behavior was changed.
- No external source root was treated as canonical runtime path.
- Existing Godot/editor generated dirty was not reset, cleaned, or stashed.

## Residual Risks

- Current local `project.godot` still has pre-existing actual config differences and remains marked as needing separate audit.
- Computer Use could not naturally trigger `ground_loot` in the sampled run because the room had no floor items; the evidence screenshot is explicitly marked `not_triggered`.
- `--script` screenshot runner was rejected because project Autoload globals are not available in that mode; Computer Use screenshots are the authoritative visual evidence for this slice.
