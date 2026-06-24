# G33 Room Type / Tag / Encounter Common Rule Contract

Stage: G33-R2 Room Type / Tag / Encounter Common Rule Full Content Implementation.

Primary source: `D:\AGAME1\Base Docs\房间类型、标签与遭遇通用规则策划案.md`

## Positioning

G33 establishes the unified room content carrier layer between G31 RunMap / RoomState and G32 RunFlow / RunResult draft. It defines room base identity, tags, policy, state, encounter entry, room content slots, rule previews, condition previews, resolution previews, and result handoff surfaces.

G33 is not complete battle runtime, event-chain runtime, RoomLoot/GroundLoot runtime, Rule/Modifier engine, Objective/Reward/Pool runtime, or real settlement.

## Room Type

Current base room types are mutually exclusive:

- `spawn`
- `normal`
- `mine`
- `monster` / `combat`
- `chest`
- `event`
- `exit`
- `boss` preview placeholder
- `special_rule` preview placeholder

Composite behavior must be expressed through tags, encounter payload, condition preview, modifier context, or future map mutation preview rather than multiple base types on one room.

## Room Tag

Tags are classification and matching hints. They do not execute behavior by themselves.

Reserved namespaces:

- `function.*`
- `trigger.*`
- `repeat.*`
- `risk.*`
- `reward.*`
- `objective.*`
- `settlement.*`

Common tags include safe, danger, combat, loot, event, exit, locked, repeatable, and one-shot equivalents.

## Room Policy

RoomPolicy determines behavior boundaries and is separate from tags:

- `entry_policy`
- `trigger_policy`
- `search_policy`
- `return_policy`
- `loot_policy`
- `clear_policy`
- `repeat_policy`
- `settlement_policy`
- `objective_policy`
- `map_mutation_policy`

G33 only records these policies as read-only preview data. It does not implement a full rule engine.

## Room State

RoomState records what happened inside the current run:

- `unknown`
- `scanned`
- `explored`
- `searched`
- `triggered`
- `opened`
- `cleared`
- `depleted`
- `locked`
- `blocked`
- `failed`
- `exhausted`

G33 aligns these flags with public room snapshots but does not add persistence.

## Encounter Entry And Preview

Encounter is room content, not room identity. Current preview encounter types include:

- `combat`
- `treasure`
- `event_choice`
- `merchant`
- `recycle_terminal`
- `evacuation`
- `rule_modifier`
- `boss`
- `search_result`
- `mine_hazard`
- `empty`

Merchant and recycle terminal are event encounter previews only. They do not perform real trade, sell, recycle, or asset writes in G33.

## Room Content And Resolution

G33 reserves:

- `RoomContentSlot`
- `RoomRulePreview`
- `RoomCondition`
- `RoomResolutionPreview`
- `RoomResultPreview`
- `GroundLoot`
- `RoomLootContainer`

GroundLoot and RoomLootContainer mean room-local item presence or room-local generated content. They are not player backpack, not long-term warehouse, and not settlement grant runtime.

Room resolution output is reserved for:

- `room_state_delta`
- `encounter_state_delta`
- `loot_generated`
- `objective_delta`
- `map_mutation`
- `failure_trigger`
- `evacuation_trigger`
- `run_log_entry`

## G31 / G32 Interface

G31 remains the authoritative map and room-state fact source. G33 enriches public room snapshots with common rule preview fields.

G32 remains the run flow and RunResult draft boundary. G33 feeds it room content and resolution preview data without adding new CommandBus behavior.

## Non-Goals

G33 does not implement:

- full battle Encounter runtime
- monster AI
- full event-chain runtime
- real RoomLoot / GroundLoot runtime
- real in-run backpack
- complete Rule / Modifier engine
- objective progress mutation
- reward grant
- settlement warehouse write
- SaveManager / active-run persistence
- AssetLedger / RunAssetLedger mutation expansion
- CommandBus mutation expansion
- FileAccess / user:// persistence
- real resources or art imports

All new contract data must remain:

```text
read_only
display_only
preview
no_persistence
```
