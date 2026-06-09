# GODOT_LUA_UX_FLOW_PARITY_G7_REPORT

## Summary

G7 adds Lua UX / flow parity P2 shell behavior on top of the G6 playable rules. It fixes the run-screen overlap problem and adds a main menu, deploy shell, bottom action bar, event option panel, loot result panel, and extraction confirmation panel without adding persistence or full meta progression.

## Implemented

- Added MainMenuPanel with exploration, tutorial, gear/talent, and settings entry points.
- Added DeployShellPanel with static warehouse, requisition, loadout, recovery, and talent tabs.
- Rebuilt the run overlay into left HUD/MiniMap, center room, right protocol/debug rail, and bottom action bar.
- Added EventOptionPanel wired to `CommandBus.select_event_option`.
- Added LootResultPanel for search, combat, and event reward summaries.
- Added ExtractConfirmPanel before `CommandBus.confirm_extract`.
- Resized HUD and ResultPanel surfaces to avoid covering the room view.
- Added `validate_lua_ux_flow_parity_g7.ps1`.

## Boundaries

- No changes to Lua prototype source files.
- No changes to UE project files.
- No merge to `main`.
- No force push.
- No Godot editor/import/runtime execution.
- No persistence writes or save-system implementation.
- No full MetaProgress, action combat, video, music, or font migration.
- UI remains snapshot/ViewModel-driven; UI scripts do not directly read `TruthMap`.

## Validation Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
```

## Local Static Validation Result

- `validate_project_structure.ps1`: PASS
- `validate_lua_parity_p0.ps1`: PASS
- `validate_playable_graybox_v0_1.ps1`: PASS
- `validate_asset_ui_parity_g5.ps1`: PASS
- `validate_lua_playable_parity_g6.ps1`: PASS
- `validate_lua_ux_flow_parity_g7.ps1`: PASS

Godot/editor/import/runtime was not run.
