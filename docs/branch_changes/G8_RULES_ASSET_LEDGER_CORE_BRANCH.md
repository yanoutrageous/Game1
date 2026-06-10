# Branch Change: G8 Rules Asset Ledger Core

## Branch

- Branch: `godot/g8-rules-asset-ledger-core`
- Base: `main`
- Stage: G8-Rules

## Summary

This branch introduces the run-scoped asset ledger and default rule service for inventory, ground loot, item location states, black/gold currency, settlement, and UI/ViewModel outputs.

`G8-A: Ground Loot & Item Location Foundation` is included as a core submodule, not as a separate full G8 plan.

## Boundaries

- No full MetaProgress or Deploy persistence.
- No full Warehouse UI.
- No drag/drop replacement UI.
- No consignment, insurance, lottery pool, or action-combat implementation.
- No Godot/editor/game/import run as part of this static implementation pass.

## Key Files

- `Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd`
- `Godot/GraytailGodot/scripts/core/run/run_rule_service.gd`
- `Godot/GraytailGodot/scripts/core/run/run_context.gd`
- `Godot/GraytailGodot/scripts/core/command/command_bus.gd`
- `Godot/GraytailGodot/scripts/core/run/event_service.gd`
- `Godot/GraytailGodot/scripts/core/run/room_resolver.gd`
- `Godot/GraytailGodot/scripts/core/run/combat_state.gd`
- `Godot/GraytailGodot/scripts/ui/hud/hud_view_model.gd`
- `Godot/GraytailGodot/scripts/ui/result/result_panel.gd`
- `Godot/GraytailGodot/tools/validate_asset_rules_g8.ps1`

## Validation

Run the six existing static validators plus:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
```
