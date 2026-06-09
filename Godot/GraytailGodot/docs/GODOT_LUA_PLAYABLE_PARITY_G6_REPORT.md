# GODOT_LUA_PLAYABLE_PARITY_G6_REPORT

## Summary

G6 adds Lua playable parity P1 core behavior on top of the G5 asset/UI baseline. The main gameplay change is the room-local movement foundation: formal WASD/arrow input moves the player inside the current room, and map room coordinates change only through door, boundary, exit, or MapOverlay teleport commands.

## Implemented

- Added room-local player coordinates and local movement in `PlayerController`.
- Kept `RunContext.player_pos/current_pos` as map room coordinates.
- Routed formal room transitions through `CommandBus.attempt_room_transition`.
- Kept Debug grid movement separate and labelled as `Debug / Grid Move`.
- Added explored-cell MapOverlay teleport and hidden-cell flag toggling.
- Added P1 event outcomes for trader, dice, altar, and trap rooms.
- Added deterministic monster state snapshots and fight result details.
- Added search/chest reward details, failure salvage, and richer result snapshots.
- Added once/blocking tutorial popup semantics with formal input locking.
- Added `validate_lua_playable_parity_g6.ps1`.

## Boundaries

- No changes to Lua prototype source files.
- No changes to UE project files.
- No merge to `main`.
- No force push.
- No Godot editor/import/runtime execution.
- UI remains snapshot/ViewModel-driven; UI scripts do not directly read `TruthMap`.
- Presentation resources remain behind `PresentationMapping`, `PresentationTheme`, `AssetCatalog`, and `ContentDB`.

## Validation Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
```

## Local Static Validation Result

- `validate_project_structure.ps1`: PASS
- `validate_lua_parity_p0.ps1`: PASS
- `validate_playable_graybox_v0_1.ps1`: PASS
- `validate_asset_ui_parity_g5.ps1`: PASS
- `validate_lua_playable_parity_g6.ps1`: PASS

Godot/editor/import/runtime was not run.
