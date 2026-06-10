# Godot G8 Rules Asset Ledger Core Report

## Scope

Branch: `godot/g8-rules-asset-ledger-core`

G8-Rules adds a run-scoped rules foundation for assets, inventory, ground loot, settlement, and UI/ViewModel outputs. `G8-A: Ground Loot & Item Location Foundation` is included as the central submodule.

This stage does not implement full MetaProgress, Deploy persistence, a full Warehouse UI, consignment, insurance, lottery pools, action combat, or final economy balance.

## Implemented

- `RunAssetLedger` is attached to `RunContext` as the single run asset rules entry.
- Currency definitions support `black_coin` and `gold_coin` with scope and settlement metadata.
- Legacy mirrors remain available: `pending_gold`, `safe_gold`, `parts`, and `carried_items`.
- Item instances include `instance_id`, `item_id`, `display_name`, `item_type`, `rarity`, `weight`, `value_state`, `base_value`, `tags`, `source`, `location_state`, and `room_pos`.
- `location_state` supports `inventory`, `equipped`, `room_floor`, `warehouse`, `settlement_pool`, and `lost`.
- `room_floor_items` records ground loot by room coordinate.
- Search, combat, and events route rewards through `RunRuleService`.
- Minimal pickup/drop commands are exposed through `CommandBus`.
- Pickup checks capacity and returns `blocked_capacity` when full.
- Dropping moves an inventory item to the current room floor.
- Equipped items do not count against backpack capacity.
- Consumables are modeled as run-scoped items that clear at settlement.
- Buff/Debuff records support `effect_id`, `duration_type`, `remaining`, and `tags`.
- Seven rarity tiers are reserved, including `unique`; unique items are not sellable by default.
- Success settlement converts black coin to gold coin and sends eligible inventory/equipped items to Warehouse Lite.
- Failure settlement loses black coin, retains gold coin, moves inventory/equipped candidates through a salvage pool, and loses room floor items by default.
- HUD/ViewModel and ResultPanel expose black coin, gold coin, capacity, floor counts, encounter type, blocked reason, Warehouse Lite output, and settlement log counts.

## Validation

The new G8 validator is:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
```

It checks ledger fields, location states, room floor lists, pickup/drop commands, capacity blocking, settlement exits, compatibility mirrors, UI boundaries, and absence of persistence APIs.

Existing G7 and earlier validations must still pass.

## Runtime Notes

Godot/editor/game/import is intentionally not run by this implementation step. Manual runtime acceptance should be done only after static validations pass and the user authorizes opening Godot.
