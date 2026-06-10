# Audit: G8 Asset Ledger Rules Core

## Scope

- Branch: `godot/g8-rules-asset-ledger-core`
- Implementation commit before documentation closure: `f2dd365cca153793883960caa3ba26f5b959ba9b`
- Remote: `https://github.com/yanoutrageous/Game1.git`

This audit records the implemented G8-Rules boundary and verifies that the stage remains a rules-core foundation, not a UI polish, MetaProgress, Deploy persistence, or action combat stage.

## Implemented Components

### RunAssetLedger

`Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd`

- Owns run-scoped currency, item instances, room floor lists, status effects, settlement logs, and Warehouse Lite snapshots.
- Exposes compatibility sync for G7 fields.
- Performs no persistence writes.

### RunRuleService

`Godot/GraytailGodot/scripts/core/run/run_rule_service.gd`

- Provides the default rule interface for search, combat, events, pickup, drop, success settlement, and failure settlement.
- Produces structured rule result dictionaries.
- Keeps EventService and room logic from directly scattering asset writes.

### Black Coin / Gold Coin

- `black_coin` is the run-scoped currency.
- `gold_coin` is the meta-facing settlement currency snapshot.
- Currency definitions include scope, gain/spend flags, persistence flag, and settlement rule.
- G7 compatibility mirrors map `pending_gold` to black coin and `safe_gold` to gold coin.

### Item Instance

Item instances include:

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

Additional rule fields include sell/store/equip/consume/unique/visual flags.

### Location State

Implemented location states:

- `inventory`
- `equipped`
- `room_floor`
- `warehouse`
- `settlement_pool`
- `lost`

### Room Floor Items

`room_floor_items` records ground loot by room coordinate. Search, combat, and events can route rewards through ledger item creation and can leave items on the current room floor when inventory capacity is insufficient or when a rule asks for floor placement.

### Backpack Capacity

- Capacity is weight-based.
- Default capacity is `10`.
- Inventory items count by weight.
- Equipped items do not count against capacity.
- Black coin, gold coin, buffs, and debuffs do not count against capacity.
- Pickup returns `blocked_capacity` when the item cannot fit.

### Equipment / Consumables / Buffs

- Equipment state is represented by `location_state`.
- `inventory` equipment is inactive and counts against capacity.
- `equipped` equipment is active and does not count against capacity.
- Consumables are cleared during success/failure settlement by default.
- Buff/Debuff status effects reserve `effect_id`, `duration_type`, `remaining`, and `tags`.

### Encounter / Default Rule Interface

- `RoomResolver` records `encounter_type` and `encounter_tags`.
- `EventService` produces event choices and delegates asset effects to `RunRuleService`.
- `RunRuleService` is the default rule entry for asset effects.

### Success / Failure Settlement

Success:

- converts black coin to gold coin
- moves eligible inventory/equipped items to Warehouse Lite
- clears consumables
- loses room floor items by default
- emits settlement log data

Failure:

- loses black coin
- retains gold coin
- moves eligible inventory/equipped items through a salvage pool
- applies salvage capacity
- clears consumables
- loses room floor items by default
- emits settlement log data

### Warehouse Lite

Warehouse Lite is implemented as a settlement snapshot output. It is not persistent storage and is not a complete warehouse UI.

### G7 Compatibility Mirror

Compatibility fields remain available:

- `pending_gold`
- `safe_gold`
- `parts`
- `carried_items`

These are synchronized from the ledger and retained for older HUD/result validation paths.

## Non-Goals Confirmed

G8-Rules does not implement:

- full MetaProgress persistence
- full Deploy persistence
- full Warehouse UI
- drag/drop or replacement inventory UI
- consignment
- insurance
- lottery pools
- action combat
- final economy balance

## Validation Coverage

Expected static validators:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
```

Godot/editor/game/import must not be run as part of this documentation closure.
