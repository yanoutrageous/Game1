# G31 Run Map Domain / Room State Foundation Contract

Status: G31-R2 implementation contract.

Primary read-only planning source:

- `D:\AGAME1\Base Docs\局内地图本体与生成规则策划案.md`

Supplemental read-only sources:

- `D:\AGAME1\Base Docs\房间类型、标签与遭遇通用规则策划案.md`
- `D:\AGAME1\Base Docs\局内流程与状态流转规则策划案.md`
- `D:\AGAME1\Base Docs\规则、效果、Modifier 与内容投放通用系统策划案.md`
- `D:\AGAME1\Base Docs\战斗房与怪物遭遇通用规则策划案.md`
- `D:\AGAME1\Base Docs\本局结算报告与历史战绩系统.md`
- `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划修正案.md`
- `D:\AGAME1\Base Docs\物品资产模型与内容映射规则策划案.md`

## Stage Positioning

G31 implements the foundation for `局内地图本体 / 房间状态承载`.

The map is the run-local source of truth for:

- spatial structure
- information reasoning
- risk distribution
- event carrier slots
- exploration records
- player-known room state
- map-facing result summaries

G31 is not a complete RunFlow, battle, event-chain, RoomLoot, Objective, Reward, Settlement, or persistence implementation.

All new surfaces must stay:

```text
read_only
display_only
preview
no_persistence
```

## Map Layers

G31 formalizes these layers:

```text
TruthMap
KnownMap
ScanLayer
MarkMap
RunMapState
InfoReliabilityLayer
```

`TruthMap` is internal only. UI and presentation code must consume `KnownMap`, `RunMapSnapshot`, `MapResult`, or view models.

`KnownMap` stores public room knowledge.

`ScanLayer` stores limited scan hints. A scanned room is not explored.

`MarkMap` stores player-facing marks and risk flags.

`RunMapState` stores current map-facing run state such as current room detail, mutation log count, and return eligibility preview.

`InfoReliabilityLayer` records how trustworthy a visible piece of map information is.

## Current Map Type

Current implemented map type:

```text
classic_rect_minesweeper
```

This is a classic rectangular minesweeper-style map with 8-neighbor mine count semantics.

Future map interfaces reserved:

- hex map
- multi-layer map
- special-rule map
- node graph map
- mixed topology map

G31 does not implement those future map types.

## Generation Contract

G31 generation output is described by:

```text
MapGenProfile
MapGenerationLog
FinalMapSnapshot
RunMapSnapshot
MapResult
```

`MapGenProfile` includes:

- map kind
- seed
- width / height
- generation mode
- constraints
- modifiers
- validation policy

`MapGenerationLog` records generation milestones and validation summaries.

`FinalMapSnapshot` is an internal read-only truth-facing snapshot. It is not a player UI payload.

Generation must record:

- seed/profile values
- constraints
- room counts
- validation result
- repair/retry policy placeholder

G31 only records repair/retry policy as preview. It does not add a full map generator repair runtime.

## Base Room Identity

Current mutually exclusive base room types:

```text
spawn
normal
mine
monster
chest
event
exit
```

A room may have tags, policies, and state, but the base type remains singular.

Examples:

- `event` + tag `rule.entry`
- `monster` + tag `encounter.combat`
- `chest` + tag `loot.container`

Not allowed in the current foundation:

- `event + monster` as two base types
- `mine + chest` as two base types
- multi-base room settlement ordering

## RoomTag / RoomPolicy / RoomState

Each room exposes:

```text
RoomTag
RoomPolicy
RoomState
```

`RoomTag` supports filtering and content matching.

`RoomPolicy` describes behavior:

- `return_policy`
- `search_policy`
- `loot_policy`
- `repeat_policy`
- `visibility_policy`

`RoomState` describes run-local facts:

- `unknown`
- `scanned`
- `explored`
- `cleared`
- `triggered`
- `blocked`

Room state must remain local to the current run and must not write persistence.

## Room Detail Preview

Room detail preview must distinguish:

```text
unknown
scanned
explored
cleared
```

`unknown` has no revealed identity.

`scanned` has limited information and cannot trigger a room event.

`explored` means the player entered or revealed the room through public flow.

`cleared` means the major room content has been handled.

Room detail preview may include:

- public position
- public room type
- adjacent mine count when known
- tags
- policies
- known state
- visibility
- return eligibility

Room detail preview must not expose hidden TruthMap data.

## Minimap / Expanded Map

The minimap and expanded map are display-only consumers.

They may show:

- known rooms
- scanned rooms
- marked rooms
- current room
- public risk hints
- return eligibility / reason code

They must not:

- read TruthMap directly
- reveal unknown room truth
- trigger scan runtime
- execute fast return
- load resources or scenes dynamically
- mutate map facts

## Return / Fast Return Eligibility

G31 supports eligibility preview only:

```text
return_eligibility
fast_return
reason_code
intent_state
```

Allowed reason codes include:

- `eligible`
- `room_unknown`
- `room_scanned_only`
- `run_state_locked`
- `outside_map`

Rules:

- explored or cleared public rooms can be eligible
- unknown rooms are not eligible
- scanned-only rooms are not eligible
- combat/event/extraction locks may block future runtime

G31 does not implement complete teleport runtime.

## MapMutationLog

Map facts and known information are append-only from the consumer perspective.

`MapMutationLog` records:

- explored room updates
- cleared room updates
- triggered room updates
- room type preview changes when explicitly called by tools/tests

Known information must not be silently rewritten.

G31 does not implement event-driven map mutation runtime.

## RunMapSnapshot

`RunMapSnapshot` is the main display/query payload.

It contains:

- `RunMap`
- `TruthMap` metadata with internal-only access
- `KnownMap`
- `ScanLayer`
- `MarkMap`
- `RunMapState`
- `InfoReliabilityLayer`
- `FinalMapSnapshot` reference
- `map_summary_preview`
- `objective_context_preview`
- `modifier_context_preview`
- `room_loot_context_preview`
- `run_result_context_preview`

It is read-only and display-only.

## MapResult

`MapResult` is a map-facing output placeholder for later RunResult, Settlement, History, and Objective consumers.

It includes:

- dimensions
- room counts
- known summary
- player position
- map summary preview
- history reference preview
- settlement context preview

G31 does not generate full RunResult or write settlement records.

## Handoff Contexts

G31 reserves fields for:

- RunFlow
- Settlement
- History
- Objective
- Reward
- Pool
- Modifier
- RoomLoot
- RunResult

These are context placeholders only.

No Objective listener, Reward grant, Pool roll, Modifier engine, RoomLoot runtime, or Settlement warehouse write is implemented in G31.

## Current Landed Scope

G31 lands:

- TruthMap generation profile/log/snapshot helpers
- KnownMap / ScanLayer / MarkMap / InfoReliabilityLayer public snapshot
- RoomState / RoomPolicy / RoomTag display schema
- return_eligibility / fast_return intent preview
- RunMapSnapshot / MapResult query facade output
- minimap / run surface / HUD display-only alignment
- Settlement map-facing preview fields
- validation and handoff records

## Deferred Scope

G31 does not implement:

- real active run persistence
- SaveManager
- complete RunFlow state machine
- real battle Encounter expansion
- real event chains
- RoomLoot / GroundLoot runtime
- in-run backpack redesign
- objective progress runtime
- reward grant
- settlement warehouse write
- map editor
- full Modifier / Rule engine
- full minimap art interaction
- hex/multi-layer/special-rule maps
- complex teleport runtime
- event-driven map mutation runtime
- full post-settlement map replay
- AssetLedger / RunAssetLedger mutation
- CommandBus mutation expansion
- FileAccess / user:// persistence
- resource or art import
