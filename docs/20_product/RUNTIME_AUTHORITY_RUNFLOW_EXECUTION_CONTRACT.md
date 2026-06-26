# G37 Runtime Authority / RunFlow Execution Consolidation Contract

Document status: product / engineering contract
Stage: G37-R2 Runtime Authority / RunFlow Execution Consolidation
Date: 2026/06/26

## 1. Stage Position

G37 consolidates the current M1 RunFlow execution authority. It is an engineering runtime-authority stage, not a new preview/schema-only stage.

The goal is to reduce split ownership around `RunContext`, `CommandBus`, run lifecycle transitions, extraction, forced result transitions, and scene orchestration.

## 2. Authority Model

- `RunRuntimeController` owns the active `RunContext` and the active `CommandBus`.
- `RunStateMachine` owns lifecycle transitions: run start, extraction request/confirm/cancel, forced extraction, and failure transition.
- `CommandBus` remains the command surface but delegates lifecycle transitions to `RunRuntimeController`.
- `RunScene` orchestrates UI and scene signals; it no longer constructs independent `RunContext` / `CommandBus` instances.
- `RunFlowStateContract` remains projection-only vocabulary and must not execute transitions.
- `GameKernel` remains hard-disabled as a runtime driver until a later ownership migration gate.

## 3. Runtime Boundaries

G37 may consolidate current M1 runtime wiring, but it does not implement:

- new gameplay systems
- complete RunFlow rewrite
- active-run persistence
- SaveManager ownership migration
- Objective / Reward / Pool runtime
- warehouse or asset mutation
- new settlement economy behavior
- new scene/resource/import metadata

## 4. Command Path

The intended command path is:

```text
RunScene / UI
  -> CommandBus.dispatch(...)
  -> RunRuntimeController
  -> RunStateMachine for lifecycle transitions
  -> RunContext internal primitives for existing result snapshot construction
```

`CommandBus` must not write lifecycle phase state directly. It may read phase for compatibility routing, but writes are centralized in `RunStateMachine` and existing `RunContext` primitives.

## 5. Validation Contract

Required validation for G37:

- `tools/validate_g35_runtime_safety.ps1`
- `tools/validate_g36_runtime_architecture.ps1`
- `tools/validate_g37_runtime_authority.ps1`
- Godot headless project-load / parser smoke
- command-sequence regression through `tools/godot_g37_command_sequence_runner.gd`

These validations do not claim gameplay runtime PASS or manual playtest PASS.

## 6. Metadata Boundary

G37 must not commit:

- `Godot/GraytailGodot/project.godot`
- `*.tscn`
- `*.tres`
- `*.res`
- `*.uid`
- `*.translation`
- `*.import`
- generated asset or resource imports

Godot-generated metadata dirt is handled as a preflight cleanup item only when it is exactly identifiable and outside the G37 staged diff.
