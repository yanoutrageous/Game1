# ENGINEERING_STATUS

## Stage

G8.2 Kernel Protocol Hardening: Command, Query, Event, Effect, Modifier, and ContentDef closure.

## Time

`2026-06-10`

## Repository State

- Current repository path: `D:\AGAME1\_repo_cache\Game1_work`
- Current remote: `https://github.com/yanoutrageous/Game1.git`
- Base branch: `main`
- G8 branch: `godot/g8-rules-asset-ledger-core`
- G8.1 branch: `godot/g8-1-architecture-hardening`
- G8.2 branch: `godot/g8-2-kernel-protocol-hardening`
- G8.2 base main commit: `91ddf591b04923520834e72eab99a8b6d8702aa4`
- Implementation baseline commit before documentation closure: `f2dd365cca153793883960caa3ba26f5b959ba9b`
- G8 documentation closure commit: `717728087eea2bdabd3a9c031b0f2698cdb5737e`
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
- Design source normalized from `D:\AGAME1\Base Docs\主模块修改策划案.txt` into `docs/design/G8_ASSET_LEDGER_INVENTORY_SETTLEMENT_CORE_PLAN.md`.
- G8 audit and handoff docs for the next UI branch.

## Implemented In G8.1

- `RunQueryFacade` provides the read-only run snapshot boundary.
- `RunContext` now delegates status/result snapshot construction to the query facade.
- `RunRuleService` exposes a normalized `RuleResult` and `EffectSpec` shape.
- `RunAssetEffectHandler` applies the asset-related EffectSpec subset while `RunAssetLedger` remains the single asset state owner.
- `CommandBus` normalizes command envelopes with `command_id`, `actor_id`, `source`, `payload`, and `sequence`.
- `RunRuleContent` provides the minimal content-definition fallback for search, monster trophy, and item definition data.
- `SaveAdapter` and `MetaProgressAdapter` reserve contract-only persistence boundaries without storage writes.
- HUD ViewModel can build directly from public snapshots.
- `validate_architecture_hardening_g8_1.ps1`.

## Implemented In G8.2

- Formal UI/debug command entry through `CommandBus.dispatch`.
- `CommandResult` with `accepted`, `reason_code`, `message_key`, `command_id`, `produced_events`, `produced_transactions`, and `snapshot_delta`.
- `RunEventLog` for fact-only domain events.
- `RunTransactionLog` for asset transaction audit entries.
- EffectSpec correlation fields: `effect_id`, `command_id`, and `rule_request_id`.
- `RunRulePipeline` for RuleRequest, RuleContext, DefaultRuleResult, ModifierSpec application, Final RuleResult, produced EffectSpec, produced Event, and produced Transaction hooks.
- `RunModifierSpec` with stable phase + priority + sequence ordering.
- `ContentDefRegistry` for CurrencyDef, ItemDef, EncounterDef, EffectDef, ModifierDef, and LootTableDef.
- `RunQueryFacade` snapshots for event log, transaction log, and content definitions.
- `validate_kernel_protocol_g8_2.ps1`.

## Not Implemented

- Full MetaProgress persistence.
- Full Deploy persistence.
- Full Warehouse UI.
- Drag/drop or replacement inventory UI.
- Consignment, insurance, lottery pool, or special rule-room systems.
- Final economy tuning.
- Action combat.

## Documentation

- `docs/design/G8_ASSET_LEDGER_INVENTORY_SETTLEMENT_CORE_PLAN.md`
- `docs/audits/AUDIT_G8_ASSET_LEDGER_RULES_CORE.md`
- `docs/handoff/HANDOFF_G8_ASSET_LEDGER_RULES_CORE.md`
- `docs/branch_changes/G8_RULES_ASSET_LEDGER_CORE_BRANCH.md`
- `Godot/GraytailGodot/docs/GODOT_ASSET_RULES_G8_REPORT.md`
- `Godot/GraytailGodot/docs/GODOT_ARCHITECTURE_HARDENING_G8_1_REPORT.md`
- `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
- `docs/audits/AUDIT_G8_1_ARCHITECTURE_HARDENING.md`
- `docs/handoff/HANDOFF_G8_1_ARCHITECTURE_HARDENING.md`
- `docs/branch_changes/G8_1_ARCHITECTURE_HARDENING_BRANCH.md`
- `docs/branch_changes/G8_2_KERNEL_PROTOCOL_HARDENING_BRANCH.md`
- `docs/audits/AUDIT_G8_2_KERNEL_PROTOCOL_HARDENING.md`
- `docs/handoff/HANDOFF_G8_2_KERNEL_PROTOCOL_HARDENING.md`
- `Godot/GraytailGodot/docs/GODOT_KERNEL_PROTOCOL_G8_2_REPORT.md`

## Follow-Up Boundary

Recommended UI branch: `godot/player-ui-g8`.

That branch should only consume ViewModel/snapshot outputs and dispatch CommandBus commands. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private rule state.

## Validation

Expected local static validations:

- `validate_project_structure.ps1`
- `validate_lua_parity_p0.ps1`
- `validate_playable_graybox_v0_1.ps1`
- `validate_asset_ui_parity_g5.ps1`
- `validate_lua_playable_parity_g6.ps1`
- `validate_lua_ux_flow_parity_g7.ps1`
- `validate_asset_rules_g8.ps1`
- `validate_architecture_hardening_g8_1.ps1`
- `validate_kernel_protocol_g8_2.ps1`

Godot editor/runtime/import is not run in this stage.
