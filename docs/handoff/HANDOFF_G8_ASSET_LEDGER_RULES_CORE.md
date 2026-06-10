# Handoff: G8 Asset Ledger Rules Core

## Current State

- Branch: `godot/g8-rules-asset-ledger-core`
- Implementation commit before documentation closure: `f2dd365cca153793883960caa3ba26f5b959ba9b`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Base: current `main` G7 playable baseline

## Implemented

- Run-scoped `RunAssetLedger`.
- Default `RunRuleService`.
- `black_coin` and `gold_coin` currency definitions.
- Item instances with `location_state`.
- Room floor loot through `room_floor_items`.
- Backpack capacity and `blocked_capacity` pickup result.
- Equipment, consumable, Buff/Debuff, rarity, and `unique` hooks.
- Success/failure settlement.
- Warehouse Lite settlement output.
- G7 compatibility mirrors for `pending_gold`, `safe_gold`, `parts`, and `carried_items`.
- HUD/ViewModel and ResultPanel snapshot outputs for G8 data.
- Static validator: `validate_asset_rules_g8.ps1`.

## Verification Commands

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
```

## Known Limits

- No full MetaProgress.
- No full Deploy persistence.
- No full Warehouse UI.
- No drag/drop or replacement inventory UI.
- No consignment, insurance, lottery pool, or action combat implementation.
- No final economy balance.
- No Godot/editor/game/import run in this stage.

## UI Consumption Guidance

Future UI work should consume data through:

- `RunContext.get_status_snapshot()`
- result snapshots
- HUD/ViewModel fields
- `CommandBus` commands

The recommended follow-up branch is:

- `godot/player-ui-g8`

That branch should only consume ViewModel/snapshot data and dispatch commands. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private run-rule state.

## Suggested Next Checks

- Manual Godot runtime acceptance only after user authorization.
- UI inventory/ground-loot presentation in a separate UI branch.
- Later MetaProgress/Deploy persistence in a separate persistence stage.
