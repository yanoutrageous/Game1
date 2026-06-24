# Handoff: G32 Run Flow / State Transition Full Content

Stage: G32-R2 Run Flow & State Transition Full Content Implementation.

Branch: `godot/g32-run-flow-state-transition-full-content`

## Product Contract

Primary contract:

- `docs/20_product/RUN_FLOW_STATE_TRANSITION_FULL_CONTENT_CONTRACT.md`

## Implementation Summary

G32 establishes the run lifecycle / state transition foundation:

- `RunFlowStateContract` defines `RunLifecycle`, `RunState`, `RunFlowSnapshot`, `RoomTransition`, `RoomActionResult`, `RunIntent`, `SettlementTriggerPreview`, `RunOutcomePreview`, and `RunResult` draft schemas.
- `RunQueryFacade` exposes run-flow snapshot fields in status and result snapshots.
- `RunContext` exposes `get_run_flow_snapshot()` as a read-only query helper.
- `DeployPrep` emits a bounded start bridge to the existing run route while keeping real deploy-config bootstrap deferred.
- `AppShell` forwards only bounded existing-route run intents from DeployPrep.
- `RunSurfaceModel` and `HUDViewModel` display lifecycle, room transition, and settlement trigger preview.
- `SettlementSnapshotSchema` reserves settlement trigger, run outcome, and RunResult draft preview fields.

## Boundaries

All G32 surfaces remain:

```text
read_only
display_only
preview
no_persistence
```

G32 does not implement:

- complete SaveManager / active run persistence
- real continue recovery
- real abandon settlement
- real warehouse write
- real reward grant
- real objective progress
- complete Rule / Modifier engine
- complete RoomLoot / GroundLoot runtime
- complete in-run backpack redesign
- complete event-chain runtime
- expanded battle Encounter runtime
- FileAccess / user:// persistence
- AssetLedger / RunAssetLedger mutation expansion
- CommandBus command-list change
- scene/resource/import metadata changes

## Validation Record

- Static validation PASS.
- `git diff --check` PASS with LF/CRLF conversion warnings only and no whitespace errors.
- Negative grep safe-hit review PASS; hits were existing runtime/preload/UI construction code, existing run systems outside the G32 delta, display text, and preview/no_persistence fields.
- Positive grep evidence PASS for run lifecycle, room transition, run intent, settlement trigger, run outcome, RunResult, and preview/display-only/read-only fields.
- Godot headless project-load/parser smoke PASS.
- Godot smoke produced no new metadata dirty side effects.

The Godot smoke only represents project-load/parser validation. It is not gameplay runtime PASS and not manual playtest PASS.

## Next Recommended Gate

Run unified G32-R3 audit / release confirmation. Do not merge main until that gate confirms branch state, remote state, validation record, and no forbidden path changes.
