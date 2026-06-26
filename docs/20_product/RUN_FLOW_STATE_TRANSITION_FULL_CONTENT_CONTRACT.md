# G32 Run Flow / State Transition Full Content Contract

## 中文摘要（DOC-GOV-001）

G32 记录局内流程与状态流转 full content preview。它说明 RunLifecycle、RunState、RunFlowSnapshot、RoomTransition、RoomActionResult、RunIntent、结算触发预览和 RunResult draft 的边界；不实现 active-run persistence、真实 continue/abandon、仓库写入、奖励发放、目标进度、RoomLoot runtime、CommandBus command-list change、gameplay runtime PASS 或 manual playtest PASS。

本摘要只解释既有英文 contract 内容，不新增玩法规则，不扩大验证结论。


Stage: G32-R2 Run Flow & State Transition Full Content Implementation.

Primary source: `D:\AGAME1\Base Docs\局内流程与状态流转规则策划案.md`.

G32 defines the run lifecycle and state-transition contract that connects the existing RunContext / CommandBus / RoomResolver route, G31 map facts, DeployPrep start intent, RunSurface / HUD display, and Settlement preview handoff. It is not a SaveManager, RoomLoot, Objective, Reward, Rule/Modifier, or persistence stage.

## Stage Positioning

G32 lands the current project-supported run lifecycle layer:

- public run lifecycle naming
- public run state snapshot
- room transition preview
- room action result preview
- run start / continue / abandon intent boundaries
- settlement trigger preview
- run outcome preview
- RunResult draft interface

All new surfaces remain:

```text
read_only
display_only
preview
no_persistence
```

## Run Lifecycle

The lifecycle vocabulary is:

- `initialized`
- `active`
- `running`
- `locked`
- `confirm_extract`
- `extracted`
- `failed`
- `abandoned`
- `settlement_pending`

The current code maps existing `RunContext` fields into this vocabulary:

- `run_started`
- `run_active`
- `phase`
- `extracted`
- `failed`
- `outcome`
- tutorial blocking popup state

`settlement_pending` is a preview handoff state only. G32 does not perform settlement persistence or warehouse writes.

## Room Flow

Room flow is represented as:

```text
arrive -> observe -> handle -> leave
```

This maps to existing run behavior:

- `arrive`: current room entered or restored from current run state
- `observe`: public snapshot consumes KnownMap / HUD / RunSurface data
- `handle`: search / interact / fight / event option / chest / exit confirm route
- `leave`: adjacent move or fast_return eligibility intent

G32 does not rewrite complete RunFlow or RoomResolver logic.

## Player Action Flow

G32 describes existing action results through `RoomActionResult`:

- enter room
- search
- interact
- fight
- event option
- chest open
- exit confirm

The contract wraps existing action result semantics into read-only preview fields. It does not add CommandBus commands and does not modify `scripts/core/command`.

## Movement / Transition Boundary

Movement and transition states reserve:

- adjacent move
- return
- fast_return
- illegal target
- unknown target
- scanned target
- explored target
- cleared target

G32 consumes G31 `RunMapSnapshot`, `RoomState`, and `return_eligibility` as read-only facts. It does not change map generation, map mutation rules, or fast-return runtime.

## Public Output Schemas

The G32 public output set is:

- `RunLifecycle`
- `RunState`
- `RunFlowSnapshot`
- `RoomTransition`
- `RoomActionResult`
- `RunIntent`
- `SettlementTriggerPreview`
- `RunOutcomePreview`
- `RunResult` draft

These are intended for RunSurface, HUD, DeployPrep route preview, Settlement preview, and later audit gates.

## G31 Map Input

G31 remains the map fact source:

- `RunMapSnapshot`
- `MapResult`
- `RoomState`
- `RoomPolicy`
- `RoomTag`
- `return_eligibility`

G32 reads these as inputs and adds lifecycle context. It must not directly expose TruthMap to UI.

## DeployPrep Start Bridge

DeployPrep may emit a bounded `RunIntent` to the existing run route:

- target route: `run`
- fallback route mode: `demo_run`
- boundary: existing route only
- no real deploy-config bootstrapper
- no persistence
- no loadout legality mutation
- no reward or settlement effect

Continue and abandon remain:

- disabled / preview when no active persistence exists
- strong-confirm preview for abandon
- no real abandon settlement
- no true continue recovery

## Handoff Reservations

G32 reserves context placeholders only for:

- Objective
- Reward
- Pool
- Modifier
- RoomLoot
- Settlement
- History

They are not listeners, rules, rewards, or writes in this stage.

## Explicit Non-Goals

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
- settlement warehouse write
- FileAccess / user:// persistence
- AssetLedger / RunAssetLedger mutation expansion
- CommandBus command-list change
- project.godot, scene, resource, import metadata changes
- Base Docs or Connection writes
