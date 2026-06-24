# Handoff: G31 Run Map Domain / Room State Foundation

Stage: G31-R2 Run Map Domain / Room State Foundation Full Content Implementation.

Branch: `godot/g31-run-map-room-state-foundation`

## Product Contract

Primary contract:

- `docs/20_product/RUN_MAP_DOMAIN_ROOM_STATE_FOUNDATION_CONTRACT.md`

## Implementation Summary

G31 establishes the map and room-state source-of-truth foundation:

- `TruthMap` now carries map generation profile, generation log, mutation log, validation, FinalMapSnapshot, RunMapSnapshot, MapResult, RoomState, RoomPolicy, RoomTag, and return_eligibility helpers.
- `IntelMap` now carries KnownMap, ScanLayer, MarkMap, and InfoReliabilityLayer public snapshot output.
- `RunQueryFacade` exposes `run_map_snapshot`, `map_result`, `current_room_detail`, and context placeholders for Objective / Modifier / RoomLoot / RunResult.
- `MiniMapViewModel`, `RunSurfaceModel`, and `HUDViewModel` consume display-only snapshot fields.
- `SettlementSnapshotSchema` reserves map-facing summary preview fields.

## Boundaries

All G31 map surfaces remain:

```text
read_only
display_only
preview
no_persistence
```

G31 does not implement:

- real active run persistence
- SaveManager
- complete RunFlow state machine
- real battle Encounter expansion
- real event chain
- RoomLoot / GroundLoot runtime
- in-run backpack redesign
- objective progress runtime
- reward grant
- settlement warehouse write
- full Modifier / Rule engine
- full minimap art interaction
- hex / multi-layer / special-rule maps
- complete fast-return teleport runtime
- event-driven map mutation runtime
- post-settlement map replay
- AssetLedger / RunAssetLedger mutation
- CommandBus mutation expansion
- FileAccess / user:// persistence
- resource or art import

## Validation Record

- Static validation PASS.
- `git diff --check` PASS; only LF/CRLF working-copy warnings were reported.
- Negative grep safe-hit review PASS; hits were existing runtime/preload/UI construction code, display text, and preview/no_persistence fields.
- Positive grep evidence PASS for the G31 map layers, room state contracts, snapshot outputs, and display-only flags.
- Godot headless project-load/parser smoke PASS after a local `IntelMap.build_public_cell` explicit `Dictionary` type hotfix.
- Godot smoke produced no new metadata dirty side effects.

The Godot smoke only represents project-load/parser validation. It is not gameplay runtime PASS and not manual playtest PASS.

## Next Recommended Gate

Run unified G31-R3 audit / release confirmation. Do not merge main until that gate confirms branch state, remote state, validation record, and no forbidden path changes.
