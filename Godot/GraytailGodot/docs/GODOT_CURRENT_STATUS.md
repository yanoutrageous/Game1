# GODOT_CURRENT_STATUS

## Updated

`2026-06-13`

## Branch

Current stage: G13 Fixed Resolution Layout Adaptation active.

Current main HEAD: `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f`.

Current remote live main HEAD: `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f`.

Closed G10 branch: `godot/g10-progress-art-smoke-foundation` at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.

G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.

G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.

G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`.

G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`.

G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`.

G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`.

Current fact source: `docs/PROJECT_BASELINE.md`.

Next-chat entry: `docs/NEXT_HANDOFF.md`.

Docs index: `docs/DOCS_INDEX.md`.

Milestone map: `docs/MILESTONES.md`.

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
- The long-term page exposes task, codex, achievement, profile, and research placeholders.
- InventoryPanel and GroundLootPanel provide formal player pickup/drop flow.
- ResultPanel explains success/failure settlement with EventLog and TransactionLog summaries.
- G10 adds ResultPanel return actions, a run pause/settings overlay, MiniMapPanel click-to-map, MapOverlay action feedback, blocked-reason pulse feedback, dev-only diagnostics gating, manifest/fallback art smoke, and `UILayoutProfile` responsive reservation.
- G11-R3 improves mainline testability and UX readability through manual playtest coverage, clearer MapOverlay feedback, inventory/ground-loot hints, result return tooltips, and Pause/Settings wording. G11-R4 is docs-only closeout and does not continue UI repair.
- G12-R3 aligned the current UI with legacy Demo core-loop feel through Chinese readability, scan/map feedback, protocol/pressure text, loot/settlement wording, and local typography/readability tweaks on existing UI only.
- G13 is active for fixed 16:9 resolution tiers, runtime-only display selection, resize locking, and bounded layout adaptation.

Current `main` includes G10 Progress & Art Smoke Foundation, the completed G11 mainline UX readability pass, G11 closeout, and the completed G12 lightweight legacy Demo readability/typography pass. G13 is active for fixed 16:9 resolution tiers and bounded layout adaptation. It is not a complete final UI, not complete MetaProgress, not complete Deploy persistence, and not complete long-term system completion.

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

G13 UI work should only consume ViewModel/snapshot data, `SettingsManager` runtime display state, and existing `UILayoutProfile` data. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private run-rule state. G13 does not start G14 or any new gameplay/system branch.

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

G13-R3 does not run Godot/editor/game/import by default and must not be reported as runtime PASS unless a later authorized runtime/manual smoke records it. G12-R3 and G12-R4 did not run Godot/editor/game/import. Do not use Godot/editor/game/import for broad resource import, persistence work, full font pipeline, or full art migration.

## G13 Boundary

G13 is limited to fixed 16:9 resolution tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`. It may add startup auto recommendation, runtime-only display selection, window resize locking, fixed-tier `UILayoutProfile` fields, and small layout adaptations for existing UI.

G13 does not include arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full platform DPI parity, complete final UI, complete settings, Deploy persistence, MetaProgress, action combat, new gameplay, new resources, full art migration, broad UI rewrite, or broad architecture reshaping.

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
