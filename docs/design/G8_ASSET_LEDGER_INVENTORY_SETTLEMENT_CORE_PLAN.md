# G8-Rules: Asset Ledger / Inventory / Settlement Core Plan

## Design Source

This document normalizes the user-provided `主模块修改策划案` into the repository design record for G8-Rules.

Source note:

- External source file read-only reference: `D:\AGAME1\Base Docs\主模块修改策划案.txt`
- Stage mapping: the original plan describes a G5.1/P1-style module change; in this repository it is integrated as `G8-Rules: Asset Ledger / Inventory / Settlement Core`.
- `G8-A: Ground Loot & Item Location Foundation` is treated as a core submodule of this G8 rules plan, not as the whole G8 scope.

## Stage Goal

G8-Rules establishes a run-scoped, extensible rules layer for assets, inventory, item location, settlement, and UI/ViewModel outputs.

The goal is not UI polish, full MetaProgress, full Deploy persistence, full Warehouse UI, action combat, final economy balance, consignment, insurance, or lottery pools.

## Design Principles

- Default rules must keep the run playable without special events, equipment, buffs, debuffs, or map modifiers.
- Special rules must be able to read and modify rule results through explicit interfaces.
- Rooms provide trigger context; Encounter content carries concrete behavior.
- UI must consume snapshots/ViewModels and commands, not directly mutate run assets.
- Settlement must produce logs and structured results that explain gained, lost, salvaged, converted, and stored assets.

## Currency

G8 uses a two-layer currency model:

- `black_coin`: run-scoped currency gained and spent in-run; converts to gold on successful extraction; is lost by default on failure.
- `gold_coin`: meta-facing currency snapshot retained after settlement; direct in-run gain is reserved for explicit special rules.

Currency definitions reserve:

- `currency_id`
- `display_name`
- `scope`
- `can_gain_in_run`
- `can_spend_in_run`
- `can_persist_to_meta`
- `settlement_rule`

Legacy G7 mirrors remain available for compatibility:

- `pending_gold` maps to `black_coin`
- `safe_gold` maps to `gold_coin`
- `parts` and `carried_items` are derived from ledger items

## Item Instance

Each item is an independent instance, not a generic part count.

Required item instance fields:

- `instance_id`
- `item_id`
- `display_name`
- `item_type`
- `rarity`
- `weight`
- `value_state`
- `base_value`
- `tags`
- `source`
- `location_state`
- `room_pos`

Additional rule fields are reserved:

- `can_sell`
- `can_store`
- `can_equip`
- `can_consume`
- `is_unique`
- `visual_only`

## G8-A: Ground Loot & Item Location Foundation

Item `location_state` must distinguish at least:

- `inventory`
- `equipped`
- `room_floor`
- `warehouse`
- `settlement_pool`
- `lost`

Run asset state must record ground loot by room coordinate through `room_floor_items`.

Rewards from search, chests, monsters, and events may either:

- enter inventory directly, subject to capacity checks
- spawn on the current room floor

Minimal command interfaces:

- pick up a room floor item
- drop an inventory item to the current room floor

Pickup must check backpack capacity. If capacity is insufficient, it must return `blocked_capacity`.

Successful extraction settles only `inventory` and `equipped` by default. `room_floor` does not leave the run by default. On failure, `inventory` and `equipped` enter the salvage pool, while `room_floor` is lost by default unless a future special rule overrides it.

## Backpack Capacity

Backpack capacity is weight-based.

Default G8 assumptions:

- `backpack_capacity = 10`
- default item `weight = 1`
- `failure_salvage_capacity = 1`
- `black_to_gold_rate = 1.0`

Capacity rules:

- black coin, gold coin, buffs, and debuffs do not consume capacity
- consumables consume capacity
- unequipped equipment consumes capacity
- equipped equipment does not consume capacity
- recovered items, collectibles, and special items consume capacity by weight

## Equipment

Equipment behavior is based on current state:

- `equipped`: active and not counted against backpack capacity
- `inventory`: inactive and counted against backpack capacity

Success settlement carries out both inventory equipment and equipped equipment. Failure settlement sends both inventory equipment and equipped equipment into the salvage pool by default.

Future hooks may include equipment slots, cursed equipment, protected equipment, break-on-failure, repair requirements, and insurance eligibility.

## Consumables

Consumables are run-scoped resources by default:

- can be carried into or gained during a run
- consume backpack capacity
- are consumed when used
- are cleared at success or failure settlement unless a special rule overrides this
- do not enter Warehouse Lite by default

## Buff / Debuff

Buffs and debuffs are independent status effects, not inventory items by default.

Reserved fields:

- `effect_id`
- `duration_type`
- `remaining`
- `tags`

Reserved duration types:

- `current_run`
- `run_count`
- `trigger_count`
- `until_removed`
- `permanent_flag`

G8 reserves cross-run duration data but does not write MetaProgress or persistence.

## Collectible Rarity

G8 reserves seven rarity tiers:

- `common`
- `good`
- `rare`
- `epic`
- `legendary`
- `mythic`
- `unique`

`unique` is the reserved top tier:

- not sellable by default
- may enter Warehouse Lite or later collection/index outputs
- does not provide permanent combat growth
- does not become mainline progression gating

## Encounter And Default Rule Interface

The map keeps stable basic room types. Concrete content is separated into Encounter data:

- `room_type`
- `encounter_type`
- `encounter_tags`

Search, chest, monster, event, pickup, drop, success settlement, and failure settlement must flow through a default rule interface such as `RunRuleService`.

Events should return structured rule results. They must not scatter writes across legacy asset fields.

Special rule hooks are reserved for future merchant rooms, curse rooms, altar rooms, lottery rooms, consignment rooms, insurance, map modifiers, equipment modifiers, tasks, and editor/mod content.

## Settlement

Success settlement default:

- black coin converts to gold coin
- gold coin is retained
- non-consumable `inventory` and `equipped` items enter Warehouse Lite
- consumables are cleared
- `room_floor` items are left behind/lost
- settlement log records conversion and item movement

Failure settlement default:

- black coin is lost
- gold coin is retained
- consumables are cleared
- non-consumable `inventory` and `equipped` items enter a salvage pool
- salvage is limited by capacity
- unsalvaged items are lost
- `room_floor` items are lost by default

## Warehouse Lite

Warehouse Lite is a settlement output and snapshot structure only in G8.

It is not a complete persistent warehouse, filtering system, sale UI, equipment enhancement system, repair system, codex research system, or MetaProgress economy.

## UI And ViewModel Outputs

HUD/ViewModel and Result outputs must expose enough data for later UI stages:

- black coin
- gold coin
- backpack capacity
- current room floor item count
- inventory/equipped summaries
- buff/debuff summaries
- encounter type
- blocked reason
- carried, salvaged, lost, floor-left, converted, and warehouse outputs
- settlement log summaries

Future UI branch recommendation:

- `godot/player-ui-g8` should consume ViewModel/snapshot and dispatch commands.
- It must not directly read or mutate `RunAssetLedger`.

## Validation Requirements

G8 validation must prove:

- ledger and rule service exist
- currency definitions exist
- item instance fields exist
- `location_state` and all required states exist
- `room_floor_items` exists
- pickup/drop commands exist
- capacity blocking returns `blocked_capacity`
- equipment, consumable, buff/debuff, rarity, and `unique` hooks exist
- success and failure settlement outputs exist
- Warehouse Lite output exists
- legacy mirror fields exist
- UI does not directly read/write ledger or TruthMap
- no `FileAccess`, `user://`, `MetaProgress`, or persistence write path is introduced

## Open Questions

- Final black coin to gold coin rate.
- Whether failure has any base black coin retention.
- Final backpack capacity and salvage capacity values.
- Official rarity display names.
- Whether any rare story exception can make a unique item progression-relevant.
- When consignment, insurance, lottery pools, and full Warehouse UI enter implementation.
