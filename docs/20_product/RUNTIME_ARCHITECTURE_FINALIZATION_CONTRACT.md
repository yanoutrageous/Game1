# G38 Runtime Architecture Consolidation Finalization Contract

Stage: G38-R2 Runtime Architecture Consolidation Finalization

G38 finalizes the runtime architecture boundary after G35-G37. It narrows `RunScene` to scene lifecycle, node wiring, signal coordination, and UI orchestration while moving route handoff, input routing, command feedback, result/meta commit orchestration, and debug meta operations behind small runtime helpers.

## Runtime Ownership

- `RunRuntimeController` owns the active `RunContext` and `CommandBus`.
- `RunStateMachine` owns lifecycle transitions and the internal `context.fail_run(...)` primitive call path.
- `CommandBus` remains the command surface and delegates lifecycle commands to `RunRuntimeController`.
- `RunScene` does not create a second `RunContext` / `CommandBus` pair.
- `RunScene` does not write `context.phase`, call `context.fail_run(...)`, or decide result/meta commit inline.

## RunScene Responsibility Budget

`RunScene` may instantiate scene/UI nodes, wire signals, coordinate viewport visibility and modal visibility, and call bridge/controller helpers for input, routes, command feedback, result display, and debug panels.

`RunScene` must not own runtime state, bypass `RunRuntimeController` / `RunStateMachine`, write save/result/core lifecycle directly, bypass `DebugGate`, become a new RunBootstrapper, or own active-run persistence.

## Helper Boundaries

- `RunSceneInputRouter` converts raw input into action ids.
- `RunSceneRouteController` converts route intents into existing run route commands.
- `RunSceneCommandFeedback` centralizes command result display fanout.
- `RunSceneResultController` owns result snapshot display preparation and `MetaProgress` settlement commit orchestration.
- `RunSceneDebugBridge` remains the debug gate bridge and wraps debug meta operations.
- `RunSceneResponsibilityBudget` exposes the boundary as a read-only snapshot.

## GameKernel Decision

Because G38 does not modify `project.godot`, `GameKernel` is retained as an inactive compatibility facade. It is not a runtime owner and does not bypass `RunRuntimeController` / `RunStateMachine`. Removing the autoload is deferred to a future project metadata gate.

## Explicit Non-Goals

G38 does not implement Modifier / Effect real execution, TruthMap split, LFS/binary policy, Loot/Inventory expansion, Settlement/economy expansion, Objective/Reward/Pool, complete warehouse, complete Rule engine, complete Save UI, runtime profile switching, active-run persistence, new gameplay content, project/scene/resource/import metadata changes, Base Docs writes, or Connection writes.

G38 validation is parser/static/runtime-architecture validation only. It does not claim gameplay runtime PASS or manual playtest PASS.
