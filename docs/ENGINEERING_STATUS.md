# ENGINEERING_STATUS

## Stage

G9 UI Final Integration: three-page shell, inventory/ground loot flow, and settlement explanation baseline.

## Time

`2026-06-11`

## Repository State

- Current repository path: `D:\AGAME1\_repo_cache\Game1_work`
- Current remote: `https://github.com/yanoutrageous/Game1.git`
- Base branch: `main`
- G8 branch: `godot/g8-rules-asset-ledger-core`
- G8.1 branch: `godot/g8-1-architecture-hardening`
- G8.2 branch: `godot/g8-2-kernel-protocol-hardening`
- G9 branch: `godot/g9-ui-presentation-layering-revision`
- G9 final branch: `godot/g9-ui-final-integration`
- G8.2 base main commit: `91ddf591b04923520834e72eab99a8b6d8702aa4`
- G9 base main commit: `c5fa0622f98be5b8cb61eedefdfa9990027c00e7`
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

## Implemented In G9

- G9 UI Presentation Layering Revision completed before final integration.
- G9 UI presentation layering architecture for a fixed base background plus independent overlay layers.
- `PresentationLayerContracts` as a contract-only GDScript schema and placeholder example source.
- Reserved ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, OutfitPresentationDef, PanelState, UIVisibilityPolicy, NavigationEntry, ShortcutEntry, ExpeditionSummaryViewModel, and LongTermSummaryViewModel.
- UI planning correction: map theme, character outfit, props, atmosphere, foreground effects, and panel skins are not baked into the main background.
- Art import boundary: future art replaces asset ids, catalog entries, layer config, theme profiles, character presentation config, and panel skin definitions.
- `validate_ui_presentation_layering_g9.ps1`.

## Implemented In G9 Final Integration

- Three-page shell for main page, expedition page, and long-term system page.
- Product title correction to `灰尾回收`; `五四三二一` remains the project subtitle.
- Formal player InventoryPanel and GroundLootPanel.
- Pickup/drop flow through CommandBus from player UI.
- CommandResult reason display for blocked operations.
- ResultPanel explanation of success/failure settlement using EventLog and TransactionLog summaries.
- Debug panel remains folded and dev-only.
- `validate_ui_final_g9.ps1`.

## Not Implemented

- Full MetaProgress persistence.
- Full Deploy persistence.
- Full Warehouse UI.
- Drag/drop or replacement inventory UI.
- Consignment, insurance, lottery pool, or special rule-room systems.
- Final economy tuning.
- Action combat.
- Real art import.
- Complete character or outfit system.
- Final UI polish and animation pass.
- Complete long-term system backends.

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
- `docs/design/G9_UI_PRESENTATION_LAYERING_ARCHITECTURE.md`
- `docs/audits/AUDIT_G9_UI_PRESENTATION_LAYERING_REVISION.md`
- `docs/handoff/HANDOFF_G9_UI_PRESENTATION_LAYERING_REVISION.md`
- `docs/branch_changes/G9_UI_PRESENTATION_LAYERING_REVISION_BRANCH.md`
- `Godot/GraytailGodot/docs/GODOT_UI_FINAL_G9_REPORT.md`
- `docs/audits/AUDIT_G9_UI_FINAL_INTEGRATION.md`
- `docs/handoff/HANDOFF_G9_UI_FINAL_INTEGRATION.md`
- `docs/branch_changes/G9_UI_FINAL_INTEGRATION_BRANCH.md`

## Follow-Up Boundary

Recommended follow-up UI shell branch: `godot/g9-ui-shell`.

That branch should only consume ViewModel/snapshot outputs and dispatch CommandBus commands. It should use `PresentationLayerContracts` and future ThemeProfile/CharacterPresentationConfig data to resolve visual layers. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private rule state.

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
- `validate_ui_presentation_layering_g9.ps1`
- `validate_ui_final_g9.ps1`

Godot runtime smoke is allowed in this stage for UI verification only. Do not use it for resource import or persistence work.
