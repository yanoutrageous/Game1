# Audit: G8.1 Architecture Hardening

## Summary

G8.1 hardens the G8 rules core without adding new gameplay. It absorbs the UE refactor direction by adding explicit query, rule-result, effect, command, and content-definition boundaries around the already playable Godot rules layer.

## Implemented Boundary

- `RunAssetLedger` remains the single owner of run asset state.
- `RunQueryFacade` builds read-only status/result snapshots for UI and presentation.
- `RunRuleService` returns normalized `RuleResult` dictionaries and creates `EffectSpec` dictionaries.
- `RunAssetEffectHandler` applies the asset-related EffectSpec subset to the ledger.
- `CommandBus` wraps commands with `command_id`, `actor_id`, `source`, `payload`, and `sequence`.
- `RunRuleContent` provides minimal fallback content definitions for current rewards.
- `SaveAdapter` and `MetaProgressAdapter` reserve contract-only persistence boundaries.
- HUD ViewModel can consume a snapshot directly.

## Non-Goals

- No full MetaProgress.
- No Deploy persistence.
- No full Warehouse UI.
- No drag/drop or replacement inventory UI.
- No consignment, insurance, lottery pool, or action combat.
- No Godot/editor/game/import.

## Validation

- Existing G8 validation remains active through `validate_asset_rules_g8.ps1`.
- G8.1 architecture checks are added in `validate_architecture_hardening_g8_1.ps1`.
- The G8.1 validator checks Query/Snapshot boundary, RuleResult/EffectSpec, command envelope, content fallback, Save/Meta adapter contracts, UI boundary, and no persistence API.
