# Godot G8.1 Architecture Hardening Report

## Summary

G8.1 hardens the Godot G8 rules core by absorbing UE-side architecture patterns without copying UE code or adding new gameplay. The stage keeps the G7/G8 playable loop intact and adds clearer boundaries for query/snapshot reads, rule results, asset effects, command envelopes, content definitions, and future persistence adapters.

## Implemented

- `RunQueryFacade` builds read-only status/result snapshots.
- `RunContext` delegates snapshot construction to `RunQueryFacade`.
- `RunRuleService` now exposes `RuleResult` and `EffectSpec` helper shapes.
- `RunAssetEffectHandler` applies asset-related effects while `RunAssetLedger` remains the single asset state owner.
- `RunRuleContent` provides minimal content-definition fallback for current reward rules.
- `CommandBus` normalizes commands with `command_id`, `actor_id`, `source`, `payload`, and `sequence`.
- `SaveAdapter` and `MetaProgressAdapter` reserve contract-only persistence boundaries and do not write storage.
- HUD ViewModel can consume public snapshots directly.

## Boundaries

- No full MetaProgress.
- No Deploy persistence.
- No full Warehouse UI.
- No drag/drop or replacement inventory UI.
- No action combat.
- No Godot/editor/game/import run in this stage.

## Validation

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_architecture_hardening_g8_1.ps1
```
