# Handoff: G31 Run Map Domain / Room State Foundation

## 中文交接摘要（DOC-GOV-001）

G31 记录局内地图与房间状态 foundation 的 preview / display-only 内容。它说明 TruthMap、KnownMap、扫描层、标记层、RunMapState、房间状态和地图结果快照的边界；不实现完整 RunFlow、真实持久化、战斗 runtime、事件链、RoomLoot runtime、奖励发放、仓库写入、SaveManager、AssetLedger / RunAssetLedger mutation、gameplay runtime PASS 或 manual playtest PASS。

本交接摘要只帮助阅读 handoff，不授权后续实现，不替代下一阶段 gate。


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
