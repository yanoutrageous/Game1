# ENGINEERING_STATUS

## Stage

G13 Fixed Resolution Layout Adaptation closeout. G13-R3 is complete, pushed, and statically validated for fixed 16:9 resolution tiers, runtime-only display selection, resize locking, and small layout adaptations. G13-R5 records docs-only handoff/status closeout. G10, G11, and G12 are complete and closed; G14 is not started.

## Time

`2026-06-13`

## Repository State

- Current repository path: `D:\AGAME1\_repo_cache\Game1_work`
- Current remote: `https://github.com/yanoutrageous/Game1.git`
- Base branch: `main`
- Current main HEAD: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`
- Current remote live main HEAD: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`
- Closed G10 branch: `godot/g10-progress-art-smoke-foundation` at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`
- G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`
- G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`
- G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G13 baseline commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`
- Current fact source: `docs/PROJECT_BASELINE.md`
- Next-chat entry: `docs/NEXT_HANDOFF.md`
- Docs navigation: `docs/DOCS_INDEX.md`
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

G9 UI core flow baseline is in `main`. It is not a complete final UI, not complete MetaProgress, not complete Deploy persistence, and not complete long-term system completion.

## Implemented In G10

- Baseline BUG backlog at `docs/bugs/G10_BASELINE_BUG_BACKLOG.md`.
- ResultPanel return actions to main menu and expedition shell.
- In-run pause/settings overlay that does not write preferences or core state.
- MiniMapPanel direct click opens MapOverlay through the existing `open_map` command path.
- MapOverlay selected-cell/action feedback.
- MapOverlay minimal open-source hint.
- Blocked CommandResult visual pulse.
- Dev diagnostics panel with build-channel/UIVisibilityPolicy gating; default player channel hides and disables the entry.
- G10 art smoke registry using manifest asset IDs and fallback IDs only.
- `UILayoutProfile` responsive/mobile reservation and key panel hooks for desktop/narrow profiles.
- G10 audit, handoff, branch change, art smoke, and future planning docs.
- G10 closeout validation transcript at `docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md`.

## Current Baseline Documents

- `docs/PROJECT_BASELINE.md` is the current engineering fact source.
- `docs/NEXT_HANDOFF.md` is the minimum next Codex/ChatGPT context entry.
- `docs/DOCS_INDEX.md` is the document navigation and historical index.
- `docs/MILESTONES.md` maps historical G labels to stable milestone names.
- `docs/handoff/HANDOFF_TEMPLATE.md` is required for future branch, closure, promotion, BUG-fix, and runtime-smoke handoffs.
- G11 documents must keep `PROJECT_BASELINE.md`, `NEXT_HANDOFF.md`, `DOCS_INDEX.md`, `MILESTONES.md`, `ENGINEERING_STATUS.md`, and `GODOT_CURRENT_STATUS.md` aligned with the actual main and remote live status.
- G11 validation checklist: `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`.
- G11 handoff: `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`.
- G12 validation checklist: `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`.
- G12 handoff: `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`.
- G13 validation checklist: `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`.
- G13 handoff: `docs/handoff/HANDOFF_G13_RESOLUTION_LAYOUT_ADAPTATION.md`.

## Implemented In G11

- G11-R3 is complete and pushed at `e261ac7d8671b59e7e72750122e6581af6ea6644`.
- During G11-R3, fact-source documents were calibrated to main `e261ac7d8671b59e7e72750122e6581af6ea6644`.
- Manual playtest guidance covers MiniMap click-to-map, MapOverlay feedback, Inventory/GroundLoot, ResultPanel return routes, Pause/Settings overlay, and hidden dev diagnostics.
- UI readability changes are limited to text, tooltip, empty-state, disabled-reason, and return-path wording.
- G11-R4 is docs-only closeout. It does not continue UI repair and does not modify runtime/UI/resource files.

## Implemented In G12

- G12-R3 is complete and pushed at `2855ca9889e394fb79d22c468b1355cd3871fd39`.
- G12 updated current fact-source docs, G12 validation, and manual playtest guidance.
- G12 improved player-visible text, Chinese readability, local typography/readability settings, MiniMap/MapOverlay scan feedback, HUD protocol/pressure wording, Inventory/GroundLoot capacity and loot explanations, ResultPanel settlement readability, and presentation mapping.
- G12-R3 did not run Godot/editor/game/import.
- G12-R3 did not add, download, copy, or commit font files.
- G12-R3 did not add resources or import products.
- G12-R3 did not modify `run_scene.gd`.
- G12-R3 did not commit the existing Godot dirty whitelist.
- G12 is complete, pushed, and closed. It is not a 1:1 legacy Demo remake, not G13, and not a new gameplay/system/persistence/art-migration stage.

## Implemented In G13

- G13-R3 is complete and pushed at `5afdb05fefe65031da1486507b0b39bdd2f1cea7`.
- G13 supports only these fixed 16:9 resolution tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.
- G13 added startup auto recommendation, runtime-only display selection, manual apply/reset, runtime window resize locking, fixed-tier `UILayoutProfile` fields, and small layout adaptations for existing HUD, MiniMap, MapOverlay, Inventory, GroundLoot, and ResultPanel UI.
- G13 updated validation and manual checklist documentation.
- G13-R3 did not run Godot/editor/game/import.
- G13-R3 did not submit `project.godot`, resources, import products, font files, or the existing Godot dirty whitelist.
- G13 closeout is static-validation only and does not claim runtime PASS.
- G13 does not modify core rules, CommandBus, ledger, TruthMap, save/persistence, MetaProgress, or Deploy persistence.
- G13 is not arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full DPI parity, complete final UI, complete settings, new gameplay, runtime PASS, or G14.

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

## G10 Boundary

G10 was reserved for stability analysis, BUG fixes, UI readability optimization, interaction blocker triage, validation-chain trust checks, code convergence, documentation clarity, and future content planning.

G10 is now closed. It is not a complete MetaProgress phase, Deploy persistence phase, complete long-term system phase, action combat phase, new gameplay phase, large real-art migration, or broad architecture reshaping pass unless a later separately approved plan changes that boundary.

G10 art work is smoke/foundation only: no loose assets, no direct core resource-path coupling, no Chinese UI text baked into images, and no full art replacement.

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
- `docs/PROJECT_BASELINE.md`
- `docs/NEXT_HANDOFF.md`
- `docs/DOCS_INDEX.md`
- `docs/MILESTONES.md`
- `docs/handoff/HANDOFF_TEMPLATE.md`
- `docs/bugs/G10_BASELINE_BUG_BACKLOG.md`
- `docs/audits/AUDIT_G10_PROGRESS_ART_SMOKE_FOUNDATION.md`
- `docs/handoff/HANDOFF_G10_PROGRESS_ART_SMOKE_FOUNDATION.md`
- `docs/branch_changes/G10_PROGRESS_ART_SMOKE_FOUNDATION_BRANCH.md`
- `Godot/GraytailGodot/docs/GODOT_G10_PROGRESS_ART_SMOKE_REPORT.md`
- `docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md`
- `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`
- `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`
- `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
- `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`
- `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`
- `docs/handoff/HANDOFF_G13_RESOLUTION_LAYOUT_ADAPTATION.md`

## Follow-Up Boundary

G13 is closing as a bounded fixed-resolution layout pass. Any G14 work, runtime smoke, five-tier manual verification, broader UI/system branch, mobile/ultrawide/4K support, or gameplay/system expansion requires separate approval.

Any future UI branch should only consume ViewModel/snapshot outputs and dispatch CommandBus commands. It should use `PresentationLayerContracts` and future ThemeProfile/CharacterPresentationConfig data to resolve visual layers. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private rule state.

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
- `validate_project_baseline_docs_pre_g10.ps1`
- `validate_g10_progress_art_smoke.ps1`

G10 runtime smoke is limited to parser/project launch and bounded UI sanity checks. Do not use it for broad resource import, persistence work, or full art migration without separate authorization.
