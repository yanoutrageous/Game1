# ENGINEERING_STATUS

## Stage

G19 LongTermShell foundation branch work is in progress on top of G18 mainline. G19 is limited to a six-module long-term shell, placeholder / preview / disabled states, and display-only interface preview fields; it does not implement real long-term systems, asset systems, item models, gacha, history storage, rewards, red-dot clearing, persistence, RunScene startup, CommandBus dispatch, or private run-state reads. G18 DeployPrepShell / DeployConfig / RunStartConfig foundation has R4 acceptance, Godot headless project-load/parser smoke PASS, docs-only closeout, fast-forward main merge, and post-merge docs calibration complete.

## Time

`2026-06-15`

## Repository State

- Current repository path: `D:\AGAME1\_repo_cache\Game1_work`
- Current remote: `https://github.com/yanoutrageous/Game1.git`
- Base branch: `main`
- Current working branch for this handoff: `godot/g19-long-term-shell-foundation`
- G19 branch: `godot/g19-long-term-shell-foundation`
- G19 baseline main HEAD: `0e44c261f399a197d6e6eec277eb51ce72e1ba8c docs: mark G18 merged to main`
- G19 scope: LongTermShell foundation, six module placeholder, and display-only interface preview only
- G18-R3 baseline main HEAD: `eeffe5800864c05f8b000e406609fa7ca3323cb5 docs: mark G17 merged to main`
- G18-R3 implementation commit: `59ea57caf1baa977e727da2697cac014cbd7429e feat(godot): add deploy prep shell foundation`
- G18 closeout / merge baseline: `285695cda0141322b0672d65998f3d3f9aa32654 docs: close G18 deploy prep foundation`
- G18 merged to main: yes, by fast-forward
- G18 validation and closeout record: `docs/validation/G18_DEPLOY_PREP_FOUNDATION_VALIDATION.md`
- Source branch for G17: `godot/g17-app-shell-main-menu`
- G17-R2 commit: `368a7be5c2fb919db47421a026ddf417df9c1b1c feat(godot): add app shell main menu foundation`
- G17-R3 closeout commit: `baa57fa41167c86ad226b5b8be4d540ff114269f docs: close G17 app shell main menu foundation`
- G17 merged to main: yes, by fast-forward
- Main HEAD after G17 fast-forward and before this post-merge status commit: `baa57fa41167c86ad226b5b8be4d540ff114269f`
- Main HEAD at start of Post-G16 architecture direction import: `9af74aeefd3a28b6b417fa0667532737cddc916b docs: mark G16 merged to main`
- G16-R3 baseline main HEAD: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`
- G16-R3 branch: `godot/g16-combat-encounter-foundation`
- G16-R3 commit: `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a feat(godot): add combat encounter foundation`
- G16-R4 status: accepted
- G16-R5 status: docs-only branch closeout
- G16 parser blocker fix commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071 fix(godot): expose encounter parser classes`
- G16 merged to main: yes, by fast-forward
- Main HEAD after G16 fast-forward and before this post-merge status commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071`
- Current remote main before G16 final push: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`
- G15 post-merge status commit: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`
- Current branch HEAD before G15-R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`
- G15 branch closeout commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad docs: close G15 encounter framework foundation`
- Main HEAD after G15 fast-forward and before post-merge status commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad`
- Current main HEAD / G15 branch baseline: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a`
- Current remote live main HEAD before G15-R3: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a`
- G15-R3 commit: `aca5b958a588879a16da97616484424da795da7f feat(godot): add encounter contract foundation`
- G15-R4 commit: `1887385af81624ebcd84342ca765d75e6fbf20eb feat(godot): add encounter slot surface adapter`
- G15 merged to main: yes, by fast-forward
- G14-R3 baseline before implementation: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`
- Closed G10 branch: `godot/g10-progress-art-smoke-foundation` at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`
- G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`
- G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`
- G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G13 baseline commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`
- G13 closeout commit: `8878bd3 docs: close G13 resolution layout adaptation pass`
- G14-R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`
- G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`
- G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`
- G14 parser hotfix commit: `fc2b86b fix(godot): resolve RunSurface parser type inference`
- G14 closeout commit: `d6c03c6 docs: close G14 legacy demo UI surface pass`
- Current fact source: `docs/PROJECT_BASELINE.md`
- Next-chat entry: `docs/NEXT_HANDOFF.md`
- Docs navigation: `docs/DOCS_INDEX.md`
- Planning source files now live under `D:\AGAME1\Base Docs`; `docs/可行性判断.md` and `docs/难度判断.md` were moved there by the user and their repository deletions are authorized docs relocation deletions.
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
- G14 validation checklist: `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`.
- G14 handoff: `docs/handoff/HANDOFF_G14_LEGACY_DEMO_UI_SURFACE.md`.
- G15 validation checklist: `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`.
- G15 handoff: `docs/handoff/HANDOFF_G15_ENCOUNTER_FRAMEWORK.md`.
- G16 validation checklist: `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md`.
- G16 handoff: `docs/handoff/HANDOFF_G16_COMBAT_ENCOUNTER_FOUNDATION.md`.
- Post-G16 architecture direction baseline: `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`.
- G17 validation checklist: `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md`.
- G17 handoff: `docs/handoff/HANDOFF_G17_APP_SHELL_MAIN_MENU.md`.
- G18 validation and closeout record: `docs/validation/G18_DEPLOY_PREP_FOUNDATION_VALIDATION.md`.

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

## Implemented In G14

- G14-R3 adds `RunSurfaceModel`, a display-only adapter from public snapshot data, `MiniMapViewModel`, `UILayoutProfile`, and latest command result.
- G14-R3 adds `RunSurface`, a lightweight run-screen composition layer for left scanner, center room/objective, right protocol/danger/status, bottom actions, lower-left resources, overlay slot, modal slot, and feedback slot.
- `run_scene.gd` remains the run orchestration owner: it still handles CommandBus dispatch, event/loot/extract decisions, screen routing, and existing panel control.
- Existing HUD, MiniMap, MapOverlay, Inventory, GroundLoot, ResultPanel, TutorialPopup, event, loot, extract, pause, and diagnostics paths remain reusable.
- G14-R3 does not run Godot/editor/game/import and does not claim runtime PASS.
- G14-R3 is complete, committed, and pushed at `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5`.
- G14-R3 acceptance follow-up is complete, committed, and pushed at `39b51f165b548cc28fef072675f846413513f2ed`.
- G14-R4 is complete, committed, and pushed at `cc652e5a616359d7d6857c87da5f76c6aca25c28`. It refines scanner legend/detail, right-side protocol/danger/status lines, bottom action hints, button visual states, legacy-style modal chrome, and event / loot / extract display text without moving decisions out of `run_scene.gd`.
- G14 parser hotfix is complete, committed, and pushed at `fc2b86b6b6b2af9a6c249230621482617b594775`. It only resolves GDScript type inference in `run_surface.gd`.
- G14-R5 is docs-only closeout / handoff / status alignment and does not modify Godot runtime/UI code.
- `RunSurface` is UI surface composition only, and `RunSurfaceModel` is display-only.
- `RunSurface` and `RunSurfaceModel` do not directly read `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state, do not dispatch CommandBus, and do not add rules.
- G14 does not change rules, snapshot schema, CommandBus semantics, TruthMap, Ledger, AssetLedger, MetaProgress, Deploy persistence, resources, fonts, import products, or project metadata.
- G14 did not run Godot/editor/game/import and does not claim runtime PASS.

## G14-R3 Safety Event Record

- During G14-R3, execution reported that two temporary script files were mistakenly created outside `D:\AGAME2\repo\Game1`.
- Execution reported that the two outside-repository temporary scripts were cleaned as necessary deletion and that no outside-repository change remains in the repository commit.
- This follow-up does not scan or clean outside-repository paths.
- Future CodeX instructions must keep explicitly forbidding outside-repository temporary scripts, logs, caches, or derived files.
- If outside-repository residue confirmation is required, the user must provide the exact path and explicit authorization; CodeX must not independently search parent, sibling, user, system, or other repository directories.
- Computer-two protective stash remains expected and must not be apply/pop/drop: `stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`.

## Implemented In G15

- G15-R3 adds `EncounterContract` and `EncounterResolver` as rules-layer public/display helpers.
- G15-R3 exposes `encounter_view_model` and `encounter_result_summary` through `RunQueryFacade`.
- G15-R3 adds additive CommandBus command `select_encounter_option`, which delegates search/chest to existing `search_current_room()` and event options to existing `select_event_option()`.
- G15-R4 adds `RunSurfaceModel` display-only Encounter section consumption from public snapshot fields.
- G15-R4 adds a lightweight `RunSurface` EncounterSlot.
- G15-R4 adds minimal `run_scene.gd` wiring from `RunSurface.encounter_option_selected` to `_dispatch_command(&"select_encounter_option", payload)`.
- G15-R3/R4 do not change old `search_current_room`, `select_event_option`, `request_extract`, or `confirm_extract` semantics.
- G15-R3/R4 do not implement full combat rooms, action combat, lottery, out-of-run progression, MetaProgress, Deploy persistence, unique collectibles, warehouse, codex, appearance library, or record systems.
- `lottery` is reserved only as a later encounter type name and remains deferred.
- G15-R3/R4/R5 do not run Godot/editor/game/import and do not claim runtime PASS.
- G15 is fast-forward merged to main.

## Implemented In G16

- G16-R3 starts from `main @ a28ae4c0c96f0b964602fd6fe7b88fa254354763` on `godot/g16-combat-encounter-foundation`.
- G16-R3 is complete and pushed at `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a`.
- G16-R4 acceptance passed.
- G16-R5 is docs-only branch closeout.
- G16 parser blocker fix is complete and pushed at `4637e8fa0eeec6859df4eab26d5a961868e4c071`.
- G16 is fast-forward merged to `main` after Godot headless project-load/parser smoke PASS.
- G16-R3 adds the first `combat_basic` / `monster_basic` public encounter foundation on top of the G15 encounter contract.
- Monster rooms expose a public `monster_summary`, `combat_encounter_state`, `attack_basic` option, deterministic risk summary, reward preview, and combat result summary.
- `select_encounter_option` delegates Monster `attack_basic` to the existing deterministic `fight_current_enemy` command path.
- G16-R3 does not change `CombatState.fight_enemy()`, `RoomResolver.fight_current_enemy()`, or `RunRuleService.apply_combat_reward()` settlement semantics.
- G16-R3 does not modify `RunSurface` or `run_scene.gd`; UI changes are limited to `RunSurfaceModel` display-only mapping.
- G16 does not implement Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restriction, combat animation, full drop economy, codex, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, Deploy persistence, complete gameplay runtime PASS, or manual playtest PASS.
- G16 is merged to `main`. Later work must branch from the latest `main`.

## Post-G16 Architecture Direction

- Current architecture has not lost control.
- G15/G16 in-run Encounter / Combat foundations should be retained and extended additively only.
- The next structural pressure is top-level app ownership, not more run-level encounter work.
- G17 should be `AppShell / NavigationIntent / PageRouter / MainMenuShell`, not a plain main-menu implementation.
- Main menu should only provide navigation, atmosphere, light notices, and shortcuts. It must not directly start or continue RunScene.
- Expedition prep should output `RunStartConfig / DeployConfig`.
- Long-term systems should output `PlayerProfileSnapshot / LongTermSnapshot / UnlockSnapshot`.
- Run should consume deploy config only, and settlement should return through `RunResultSummary / SettlementAdapter`.

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
- `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`
- `docs/handoff/HANDOFF_G14_LEGACY_DEMO_UI_SURFACE.md`
- `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`
- `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md`
- `docs/handoff/HANDOFF_G16_COMBAT_ENCOUNTER_FOUNDATION.md`

## Follow-Up Boundary

G15 final integration closes the bounded Encounter Contract Foundation stage on main. R3 defines the public contract and rule bridge; R4 adds the first UI EncounterSlot adapter; R5 is docs-only closeout. G16 has now completed its first combat encounter foundation and is fast-forward merged to main after parser smoke.

Any future UI branch should only consume ViewModel/snapshot outputs and dispatch CommandBus commands. It should use `PresentationLayerContracts` and future ThemeProfile/CharacterPresentationConfig data to resolve visual layers. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private rule state.

G16 final merged the first Monster combat option foundation to `main` after Godot headless project-load/parser smoke PASS. G17 then established `AppShell / NavigationIntent / PageRouter / MainMenuShell` and is fast-forward merged to `main`. Any next stage requires separate authorization. If UI and rules work proceed in parallel, branch from the latest `main` into separate branches and do not push directly to `main` from two computers in parallel. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, `RunSurfaceModel`, and global status / handoff / validation docs.

G17 adds a formal AppShell, NavigationIntent, PageRouter, MainMenuShell, and static MainMenuModel while keeping expedition, long-term, and settings pages as placeholder routes. G17-R3 acceptance and Godot headless project-load/parser smoke PASS are complete, and G17 is fast-forward merged to `main`. It does not implement formal DeployConfig, LongTermSnapshot, warehouse, codex, lottery, MetaProgress, Deploy persistence, full settings, complete gameplay runtime PASS, or manual playtest PASS.

G18-R3 adds the first DeployPrepShell foundation and is now fast-forward merged to `main`. It is not a full expedition-prep implementation: it only provides five placeholder tabs, right-side summary sections, AppShell deploy route integration, and public DeployConfig / RunStartConfig preview dictionaries. It does not dispatch CommandBus, start or continue RunScene, modify run state, generate real maps, implement warehouse/requisition/permit rules, settlement reports/history, MetaProgress, Deploy persistence, complete gameplay runtime PASS, or manual playtest PASS.

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

## G18 R4 Acceptance Note

G18-R4 accepted the branch foundation on `godot/g18-deploy-prep-foundation` and ran Godot headless project-load/parser smoke PASS. This is not complete gameplay runtime PASS and not manual playtest PASS. G18 is now fast-forward merged to main, G19 has not started, and the stage still does not start RunScene, dispatch run CommandBus, modify RunContext, generate real maps, implement warehouse/requisition/permit rules, implement settlement reports/history, or write persistence.
