# GODOT_CURRENT_STATUS

## Updated

`2026-06-16`

## Branch

Current stage: G19 LongTermShell foundation branch work is in progress on top of G18 mainline. Scope is limited to six fixed long-term modules, placeholder / preview / disabled states, and display-only interface preview fields. G19-R3 does not run Godot, does not claim headless project-load/parser smoke, does not claim complete gameplay runtime PASS, and does not claim manual playtest PASS.

G18 DeployPrepShell / DeployConfig / RunStartConfig foundation has R4 acceptance, Godot headless project-load/parser smoke PASS, docs-only closeout, fast-forward main merge, and post-merge docs calibration complete. Scope remains deploy prep placeholder tabs, right-side summary, public config preview, and AppShell deploy route integration; it does not start RunScene or write persistence. G17 AppShell / NavigationIntent / PageRouter / MainMenuShell foundation is complete, parser-smoke checked, and fast-forward merged to `main`.

Main HEAD at start of Post-G16 architecture direction import: `9af74aeefd3a28b6b417fa0667532737cddc916b docs: mark G16 merged to main`.

Current main HEAD after G17 fast-forward and before this post-merge status commit: `baa57fa41167c86ad226b5b8be4d540ff114269f`.

G18-R3 baseline main HEAD: `eeffe5800864c05f8b000e406609fa7ca3323cb5 docs: mark G17 merged to main`.

G18-R3 implementation commit: `59ea57caf1baa977e727da2697cac014cbd7429e feat(godot): add deploy prep shell foundation`.

G18 closeout / merge baseline: `285695cda0141322b0672d65998f3d3f9aa32654 docs: close G18 deploy prep foundation`.

G18 merged to main: yes, by fast-forward.

G19 branch: `godot/g19-long-term-shell-foundation`.

G19 baseline main HEAD: `0e44c261f399a197d6e6eec277eb51ce72e1ba8c docs: mark G18 merged to main`.

G19 modules: 目标、图鉴、研究、个人资历、抽奖、收藏 / 外观.

G17-R2 commit: `368a7be5c2fb919db47421a026ddf417df9c1b1c feat(godot): add app shell main menu foundation`.

G17-R3 closeout commit: `baa57fa41167c86ad226b5b8be4d540ff114269f docs: close G17 app shell main menu foundation`.

G17 merged to main: yes, by fast-forward.

G16 baseline main HEAD before R3: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`.

G16-R3 branch: `godot/g16-combat-encounter-foundation`.

G16-R3 commit: `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a feat(godot): add combat encounter foundation`.

G16-R4 status: accepted.

G16-R5 status: docs-only branch closeout.

G16 parser blocker fix commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071 fix(godot): expose encounter parser classes`.

G16 merged to main: yes, by fast-forward.

G15 post-merge status commit: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`.

Current G15 branch HEAD before R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`.

G15 branch closeout commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad docs: close G15 encounter framework foundation`.

Main HEAD after G15 fast-forward and before post-merge status commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad`.

G15-R3 commit: `aca5b95 feat(godot): add encounter contract foundation`.

G15-R4 commit: `1887385 feat(godot): add encounter slot surface adapter`.

G15 branch merged to main: yes, by fast-forward.

G14-R3 baseline before implementation: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`.

Closed G10 branch: `godot/g10-progress-art-smoke-foundation` at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.

G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.

G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.

G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`.

G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`.

G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`.

G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`.

G13 baseline commit: `e90bd27 docs: close G12 legacy demo parity pass`.

G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`.

G13 closeout commit: `8878bd3 docs: close G13 resolution layout adaptation pass`.

G14-R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`.

G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`.

G14 parser hotfix commit: `fc2b86b fix(godot): resolve RunSurface parser type inference`.

G14 closeout commit: `d6c03c6 docs: close G14 legacy demo UI surface pass`.

Current fact source: `docs/PROJECT_BASELINE.md`.

Next-chat entry: `docs/NEXT_HANDOFF.md`.

Docs index: `docs/DOCS_INDEX.md`.

Milestone map: `docs/MILESTONES.md`.

Planning source files now live under `D:\AGAME1\Base Docs`; `docs/可行性判断.md` and `docs/难度判断.md` were moved there by the user and their repository deletions are authorized docs relocation deletions.

G9 UI final integration branch: `godot/g9-ui-final-integration`.

G8.2 hardening branch: `godot/g8-2-kernel-protocol-hardening`.

G8.1 hardening branch: `godot/g8-1-architecture-hardening`.

G8 rules branch: `godot/g8-rules-asset-ledger-core`.

Base branch: `main`.

G8.2 base main commit: `91ddf591b04923520834e72eab99a8b6d8702aa4`.

Implementation baseline commit before documentation closure: `f2dd365cca153793883960caa3ba26f5b959ba9b`.

G8 documentation closure commit: `717728087eea2bdabd3a9c031b0f2698cdb5737e`.

## Current Capability

- Tutorial P0 mode remains a 5x5 fixed Lua-derived map.
- Standard P0 mode remains a 10x10 generated map.
- TruthMap stores real map state.
- IntelMap stores player-known public state only.
- CommandBus remains the only player and Debug UI command entry.
- HUD, MiniMap, MapOverlay, TutorialPopup, and ResultPanel consume snapshots/ViewModels.
- AssetCatalog and ContentDB load assets through `data/assets/asset_manifest.csv`.
- PresentationMapping and PresentationTheme isolate asset ids, labels, hints, colors, and visual roles from core rules.
- G5 migrated a first audited asset batch for minimap icons, HUD panels, player idle sprites, room backgrounds, and room props.
- G6 separates map room coordinates from room-local player coordinates.
- G7 adds the main menu shell, read-only deploy shell foundation, run layout, event option panel, loot result panel, and extraction confirmation panel.
- G8 adds a run-scoped `RunAssetLedger` and `RunRuleService` for asset rules.
- `black_coin` and `gold_coin` are available through ledger currency definitions and snapshot outputs.
- Item instances carry `location_state`, `room_pos`, rarity, weight, value state, and source data.
- Ground loot is tracked per room through `room_floor_items`.
- Pickup/drop commands are exposed through CommandBus.
- Pickup checks backpack capacity and returns `blocked_capacity` when full.
- Equipment, consumable, Buff/Debuff, rarity, and `unique` hooks are reserved in the rules layer.
- Success settlement converts black coin to gold coin and routes eligible inventory/equipped items to Warehouse Lite.
- Failure settlement loses black coin, keeps gold coin, sends eligible inventory/equipped items through salvage, and loses room floor items by default.
- G7 compatibility mirrors remain available through `pending_gold`, `safe_gold`, `parts`, and `carried_items`.
- G8.1 adds `RunQueryFacade` as the status/result snapshot boundary.
- G8.1 routes asset-related effects through `RunAssetEffectHandler`; `RunAssetLedger` remains the single asset state owner.
- G8.1 normalizes `RunRuleService` results as `RuleResult` dictionaries with `EffectSpec` entries.
- G8.1 normalizes CommandBus command envelopes with `command_id`, `actor_id`, `source`, `payload`, and `sequence`.
- G8.1 adds `RunRuleContent` as the minimal content-definition fallback for rule rewards.
- G8.1 reserves `SaveAdapter` and `MetaProgressAdapter` as contract-only boundaries without storage writes.
- G8.2 makes `CommandBus.dispatch` the formal UI/debug command entry.
- G8.2 adds `CommandResult` for accepted/rejected command output and blocked reason propagation.
- G8.2 adds `RunEventLog` for fact-only domain events.
- G8.2 adds `RunTransactionLog` for asset transaction audit records.
- G8.2 standardizes EffectSpec correlation fields: `effect_id`, `command_id`, and `rule_request_id`.
- G8.2 reserves `RunRulePipeline` and `RunModifierSpec` for deterministic rule modification.
- G8.2 reserves `ContentDefRegistry` for CurrencyDef, ItemDef, EncounterDef, EffectDef, ModifierDef, and LootTableDef.
- G8.2 exposes event log, transaction log, and ContentDef snapshots through `RunQueryFacade`.
- G9 UI presentation layering revision reserves a fixed base background plus independent Presentation Overlay layers.
- G9 keeps map theme, character outfit, scene props, foreground effects, and panel skins outside the baked base background.
- `PresentationLayerContracts` provides contract-only schemas and placeholder examples for ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, OutfitPresentationDef, PanelState, UIVisibilityPolicy, NavigationEntry, ShortcutEntry, ExpeditionSummaryViewModel, and LongTermSummaryViewModel.
- G9 final integration adds a playable three-page UI shell.
- The main page exposes `出发探索`, `长期系统`, and `设置`.
- The expedition page exposes map, warehouse, claim, loadout, talent, character/outfit placeholders, tutorial, standard, and confirm deploy entries.
- The long-term page exposes the G19 six-module shell: 目标、图鉴、研究、个人资历、抽奖、收藏 / 外观. It is placeholder / preview / disabled only and uses display-only interface preview fields.
- InventoryPanel and GroundLootPanel provide formal player pickup/drop flow.
- ResultPanel explains success/failure settlement with EventLog and TransactionLog summaries.
- G10 adds ResultPanel return actions, a run pause/settings overlay, MiniMapPanel click-to-map, MapOverlay action feedback, blocked-reason pulse feedback, dev-only diagnostics gating, manifest/fallback art smoke, and `UILayoutProfile` responsive reservation.
- G11-R3 improves mainline testability and UX readability through manual playtest coverage, clearer MapOverlay feedback, inventory/ground-loot hints, result return tooltips, and Pause/Settings wording. G11-R4 is docs-only closeout and does not continue UI repair.
- G12-R3 aligned the current UI with legacy Demo core-loop feel through Chinese readability, scan/map feedback, protocol/pressure text, loot/settlement wording, and local typography/readability tweaks on existing UI only.
- G13-R3 completed fixed 16:9 resolution tiers, runtime-only display selection, manual apply/reset, resize locking, fixed-tier `UILayoutProfile` fields, and bounded layout adaptation.
- G14 is complete, committed, pushed, and closed by R5. G14-R3 adds `RunSurfaceModel` and `RunSurface` for the first low-fidelity legacy Demo-style run surface while preserving existing panel, routing, and CommandBus paths.
- G14-R4 refines the display surface only: scanner legend/detail, right-side protocol/danger/status lines, bottom action hints, button visual states, legacy-style modal chrome, event / loot / extract display text, and feedback hierarchy.
- G14 parser hotfix `fc2b86b` resolves a `run_surface.gd` GDScript type inference parser error without changing UI behavior or rules.
- G15-R3 adds a rules-layer Encounter contract foundation: `EncounterContract`, `EncounterResolver`, public `encounter_view_model`, public `encounter_result_summary`, and additive `select_encounter_option` for search/chest/event only.
- G15-R4 adds a UI EncounterSlot surface adapter: `RunSurfaceModel` consumes only public encounter snapshot fields, `RunSurface` displays options and emits public option signals, and `run_scene.gd` performs minimal CommandBus wiring for `select_encounter_option`.
- G16-R3 adds the first combat encounter foundation: Monster rooms expose `monster_basic` / `combat_basic` public encounter data, `attack_basic` option data, monster summary, risk/reward preview, and combat result summary. `attack_basic` routes through `select_encounter_option` into the existing deterministic `fight_current_enemy` chain.
- G16-R5 closes branch docs/status; parser blocker fix `4637e8f` makes encounter helper references parser-safe.
- Post-G16 architecture direction baseline records that current architecture has not lost control, G15/G16 Encounter / Combat foundations should be retained, and G17 should focus on `AppShell / NavigationIntent / PageRouter / MainMenuShell` rather than plain main-menu implementation.

Current `main` includes G10 Progress & Art Smoke Foundation, the completed G11 mainline UX readability pass, G11 closeout, the completed G12 lightweight legacy Demo readability/typography pass, G13 fixed resolution layout support and closeout, completed G14 run surface work, G15 Encounter Contract Foundation, G16 Combat Encounter Foundation, G17 AppShell / MainMenuShell foundation, and G18 DeployPrepShell / DeployConfig / RunStartConfig foundation. G18 is not a complete final UI, not complete MetaProgress, not complete Deploy persistence, not complete long-term system completion, not complete 1:1 legacy Demo reproduction, not true RunScene launch, not real maps, not warehouse/requisition/work permit rules, not settlement report/history, not Boss, not action combat, and not complete gameplay runtime PASS or manual playtest PASS.

Post-G17 next structural work requires separate authorization. Main menu should only navigate and present atmosphere/light hints; it must not directly start or continue RunScene. Expedition prep should later output `RunStartConfig / DeployConfig`; long-term systems should later output `PlayerProfileSnapshot / LongTermSnapshot / UnlockSnapshot`; settlement should later return through `RunResultSummary / SettlementAdapter`.

G17 establishes the first AppShell / NavigationIntent / PageRouter / MainMenuShell slice and is fast-forward merged to main. The formal main menu exposes only `出发探索`, `长期系统`, `设置`, and `退出游戏`; expedition, long-term, and settings are placeholder routes in this slice, and exit uses a confirm layer. G17-R3 acceptance and Godot headless project-load/parser smoke PASS are complete. G17 does not implement formal expedition prep, long-term systems, warehouse, codex, lottery, MetaProgress, Deploy persistence, full settings, complete gameplay runtime PASS, or manual playtest PASS.

G18 is fast-forward merged to main. It adds `DeployPrepShell`, `DeployConfig`, and `RunStartConfig` preview support only. The deploy page has five placeholder tabs, right-side summary/config/effect/risk sections, AppShell deploy route integration, and preview-only start intent. Godot headless project-load/parser smoke PASS is recorded, but this is not complete gameplay runtime PASS or manual playtest PASS. G18 does not start or continue RunScene, dispatch run CommandBus, generate real maps, implement warehouse/requisition/work permit rules, settlement reports/history, long-term systems, lottery, MetaProgress, or Deploy persistence. G19 has not started and should begin only in a new CodeX execution conversation after workspace/root, shell cwd, git root, apply_patch root, patch-root probe, probe deletion, and clean status calibration.

G19 branch work replaces the old long-term placeholder route with `LongTermShell`. It does not implement real goals, task progress, achievement checks, commission acceptance, codex data, research, profile progression, history storage, gacha, collection / appearance equipment, warehouse, asset events, item models, RewardBundle, Policy / Tag rules, red-dot clearing, reward claiming, persistence, MetaProgress, RunScene startup, CommandBus dispatch, or private RunContext / Encounter / Combat / Ledger / TruthMap reads.

G10 was a bounded stabilization and smoke-foundation stage. It is complete, merged to main, and closed. It does not represent complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.

## UI Boundary

Future UI work should consume:

- `RunContext.get_status_snapshot()`
- result snapshots
- HUD/ViewModel fields
- CommandBus commands
- `CommandResult.reason_code` / `message_key`
- Event and transaction snapshots when audit/debug panels need them
- G9 presentation contract fields for visual layer resolution
- semantic ids such as `theme_id`, `character_id`, `outfit_id`, `risk_level`, and `tracked_objective_id`
- InventoryPanel and GroundLootPanel snapshots
- ResultPanel EventLog and TransactionLog summaries

G14 UI work consumes ViewModel/snapshot data, `MiniMapViewModel`, latest command result data, and existing `UILayoutProfile` data. It must not directly read or write `RunAssetLedger`, `TruthMap`, `RunRuleService`, Ledger private state, or private run-rule state. G14 does not start G15 or any new gameplay/system branch.

If future UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. The rules line must not directly modify UI surface code, and the UI line must not directly read rules private state. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.

G15 UI boundary: R4 consumes `encounter_view_model` and `encounter_result_summary` through `RunSurfaceModel` display-only data. `RunSurface` only displays EncounterSlot state and emits public option signals; `run_scene.gd` uses minimal CommandBus wiring. UI must not read `TruthMap`, `RunRuleService`, Ledger, `AssetLedger`, `RunAssetLedger`, `RunContext`, or any private rule state, and must not bypass CommandBus.

Presentation work should map semantic ids into ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, panel skins, and fallback asset ids. Core gameplay should not directly build image paths.

Rules work should extend `RunRulePipeline`, `RunModifierSpec`, and `RunAssetEffectHandler`. Content work should register declarative ContentDef entries. Later persistence work should attach through `SaveAdapter` and `MetaProgressAdapter`.

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
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_kernel_protocol_g8_2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_presentation_layering_g9.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_final_g9.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_baseline_docs_pre_g10.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_g10_progress_art_smoke.ps1
```

G16 final ran Godot headless project-load/parser smoke and passed; this must not be reported as complete gameplay runtime PASS or manual playtest PASS. G16 did not submit `project.godot`, resources, import products, font files, `.uid`, `.translation`, or the existing Godot dirty whitelist. Do not use Godot/editor/game/import for broad resource import, persistence work, full font pipeline, or full art migration.

## G15 Boundary

G15 is limited to the Encounter Contract Foundation. R3 adds public/display dictionaries for encounter type, state, options, result summaries, effect summaries, and log entries. R4 adds a first UI EncounterSlot adapter that consumes the public snapshot only. The first adapters cover search/chest and existing event options only.

G15-R3/R4 do not migrate event / loot / extract decisions, do not implement full combat rooms or action combat, do not implement out-of-run progression, and do not implement lottery. `lottery` may exist only as a reserved encounter type name until progression, warehouse, codex, appearance library, and record systems exist.

G15-R3 keeps existing command semantics. `select_encounter_option` is additive and delegates to existing `search_current_room()` or `select_event_option()` paths. G15-R4 routes UI option clicks to that bridge without direct rule-state reads. Existing `request_extract` and `confirm_extract` are unchanged.

## G16 Boundary

G16-R3 is limited to the first `combat_basic` / `monster_basic` encounter foundation on top of the G15 public encounter framework. Monster rooms expose public `monster_summary`, `combat_encounter_state`, `attack_basic` option data, deterministic risk/reward preview, and combat result summary. `select_encounter_option` routes Monster `attack_basic` to existing deterministic `fight_current_enemy`.

G16-R3 does not change `CombatState.fight_enemy()`, `RoomResolver.fight_current_enemy()`, or `RunRuleService.apply_combat_reward()` settlement semantics. UI changes are display-only through `RunSurfaceModel`; the later parser blocker fix only removes dependency on parser-visible global class references.

G16-R5 is docs-only branch closeout. G16 is fast-forward merged to `main` after Godot headless project-load/parser smoke PASS.

G16 does not implement Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restriction, combat animation, full drop economy, codex, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, Deploy persistence, full event library, complete gameplay runtime PASS, or manual playtest PASS.

G14-R3 safety event record: execution reported that two temporary script files were mistakenly created outside the then-active Game1 worktree and were then cleaned as necessary deletion. The repository commit contains no outside-repository path. Current computer-two G15 worktree safety scope is `D:\AGAME1\_repo_cache\Game1_work`; future CodeX work must forbid outside-repository temporary files and must not scan or clean outside-repository directories unless the user provides the exact path and explicit authorization.

## G14 Boundary

G14 is limited to a visible legacy Demo-style run UI surface sprint and is complete after R5 docs-only closeout. R3 adds a minimal `RunSurface` / `RunSurfaceModel` cut and first shell: left scanner rail, center room/objective surface, right protocol/danger/status rail, bottom action bar, resource pocket, and reusable overlay/modal slots.

G14-R4 adds low-fidelity presentation refinement for scanner legend, action hints, button states, modal chrome, event / loot / extract display text, right rail status, and feedback hierarchy. It does not move decisions into UI.

G14 keeps event, loot, extract, command decisions, and screen routing in `run_scene.gd`. It does not change rules, CommandBus semantics, snapshot schema, TruthMap, Ledger, AssetLedger, MetaProgress, Deploy persistence, resources, fonts, import products, project metadata, action combat, full event library, full talent/card systems, full art migration, G15, or runtime PASS.

`RunSurface` is UI surface composition only. `RunSurfaceModel` is display-only. They do not directly read `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state, and they do not dispatch CommandBus.

## G13 Boundary

G13 is limited to fixed 16:9 resolution tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`. G13-R3 added startup auto recommendation, runtime-only display selection, manual apply/reset, window resize locking, fixed-tier `UILayoutProfile` fields, and small layout adaptations for existing UI.

G13 does not include arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full platform DPI parity, complete final UI, complete settings, Deploy persistence, MetaProgress, action combat, new gameplay, new resources, full art migration, broad UI rewrite, broad architecture reshaping, or runtime PASS.

## G12 Boundary

G12 was limited to lightweight legacy Demo core-loop feel, Chinese visible text, scan/map feedback, protocol/pressure readability, reward/loot/settlement wording, local tooltip/autowrap/color/font-size/line-spacing tweaks, and validation/manual checklist updates. It is complete, pushed, and closed.

G12 did not run Godot/editor/game/import, did not add font files/resources/import products, did not modify `run_scene.gd`, and did not commit the existing Godot dirty whitelist. It does not include 1:1 legacy Demo remake, complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, new events library, new resources, downloaded/copied/source-unknown fonts, complete font system, full art migration, full UI rewrite, or G13.

## Current Unfinished Items

- No full MetaProgress.
- No full Deploy persistence.
- No full Warehouse UI.
- No drag/drop or replacement inventory UI.
- No consignment, insurance, or lottery pool implementation.
- No action combat.
- No final event economy tuning.
- No persistence-backed deploy economy.
- No real art import.
- No complete character or outfit system.
- No complete Inventory, GroundLoot, or Settlement UI.
- No final UI polish pass.
- No complete long-term backend.

## G10 Boundary

G10 was reserved for stability analysis, BUG fixes, UI readability optimization, interaction blocker triage, validation-chain trust checks, code convergence, documentation clarity, and future content planning.

G10 is now closed. It does not include complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping unless a later separately approved plan changes that boundary.
