# GODOT_LUA_PARITY_P0_REPORT

## Summary

G3 implements the first Godot Lua Parity P0 slice: Tutorial 5x5, Standard 10x10, core move/search/fight/extract loop, public IntelMap state, CommandBus-only commands, and fallback UI status.

## Implemented P0

- `RunConfig.tutorial_5x5()` and `RunConfig.standard_10x10()`.
- Tutorial fixed Lua map converted from 1-based Lua coordinates to 0-based Godot coordinates.
- Standard generated map with required room counts and hidden random exits.
- TruthMap owns real cell data; IntelMap owns revealed/flagged/public cell data.
- CommandBus commands for tutorial, standard, move, flag, search, interact, fight, extract request/confirm/cancel, and restart.
- RoomResolver handles first mine damage only once, one-time search/chest rewards, event placeholder completion, deterministic monster fight, and exit-only extraction.
- HUD/MiniMap/ResultPanel consume snapshots or IntelMap-derived ViewModels.

## Validation

- `validate_project_structure.ps1`: required.
- `validate_lua_parity_p0.ps1`: required.
- Godot headless editor/runtime smoke: run if an approved local Godot executable is available without installation or global config writes.

## Known Limits

- P0 event rooms use accessible placeholder behavior; full trader/dice/altar/trap option parity remains future work.
- Monster combat is deterministic only; action combat remains future work.
- No real art assets were migrated.
- No full MetaProgress or Deploy UI was implemented.

## Next Stage

Do not start automatically. Candidate follow-up work includes P1 event options, MapOverlay parity, failure salvage details, tutorial popup text polish, and richer content presentation.
