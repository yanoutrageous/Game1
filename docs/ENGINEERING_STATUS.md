# ENGINEERING_STATUS

## Stage

G8 Rules: Asset Ledger / Inventory / Settlement Core.

## Time

`2026-06-10`

## Repository State

- Current repository path: `D:\AGAME1\_repo_cache\Game1_work`
- Current remote: `https://github.com/yanoutrageous/Game1.git`
- Base branch: `main`
- G8 branch: `godot/g8-rules-asset-ledger-core`
- `lua-prototype-main` modified or overwritten: no

## Implemented In G8-Rules

- Run-scoped `RunAssetLedger`.
- Default `RunRuleService` for search, combat, event rewards, pickup/drop, and settlement.
- Black coin and gold coin definitions.
- Item instances with location state and room position.
- Ground loot lists per room.
- Backpack capacity and `blocked_capacity` pickup result.
- Inventory/equipped capacity rules.
- Consumable and Buff/Debuff data hooks.
- Seven rarity tiers with `unique` reserved as not sellable by default.
- Success and failure settlement outputs.
- Warehouse Lite snapshot output.
- Legacy field mirrors for G7 HUD/result compatibility.
- HUD/ViewModel and ResultPanel G8 exports.
- `validate_asset_rules_g8.ps1`.

## Not Implemented

- Full MetaProgress persistence.
- Full Deploy persistence.
- Full Warehouse UI.
- Drag/drop or replacement inventory UI.
- Consignment, insurance, lottery pool, or special rule-room systems.
- Final economy tuning.
- Action combat.

## Validation

Expected local static validations:

- `validate_project_structure.ps1`
- `validate_lua_parity_p0.ps1`
- `validate_playable_graybox_v0_1.ps1`
- `validate_asset_ui_parity_g5.ps1`
- `validate_lua_playable_parity_g6.ps1`
- `validate_lua_ux_flow_parity_g7.ps1`
- `validate_asset_rules_g8.ps1`

Godot editor/runtime/import is not run in this stage.
