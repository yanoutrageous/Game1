# BRANCH_CHANGE_G4_PLAYABLE_GRAYBOX_V0_1

## Summary

Branch `godot/lua-parity-p0` advances from G3 Lua parity P0 into G3.5 runtime repair and G4 playable graybox v0.1.

## Base

- Repository: `D:\AGAME2\repo\Game1`
- Branch: `godot/lua-parity-p0`
- Prior commit: `3cb79bc feat: implement Godot Lua parity P0`
- Godot console: `D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe`
- Godot version: `4.6.3.stable.official.7d41c59c4`

## Changes

- Fixed Godot 4.6 GDScript type inference errors in runtime parity scripts.
- Kept Tutorial 5x5 and Standard 10x10 parity rules intact.
- Added clear player-facing mode entry buttons for `Start Tutorial 5x5` and `Start Standard 10x10`.
- Made keyboard `E` usable for normal room search, chest search, event interaction, and exit request/confirm.
- Preserved Debug buttons as auxiliary controls only.
- Added playable graybox validation and manual playtest documentation.

## Validation

- `validate_project_structure.ps1`
- `validate_lua_parity_p0.ps1`
- `validate_playable_graybox_v0_1.ps1`
- Godot headless editor
- Godot runtime smoke

## Boundaries

- No real art assets were migrated.
- No full MetaProgress was implemented.
- No action combat was implemented.
- No Deploy UI was implemented.
- No branch merge was performed.
- No push to `main` or `lua-prototype-main`.
- No force push.
