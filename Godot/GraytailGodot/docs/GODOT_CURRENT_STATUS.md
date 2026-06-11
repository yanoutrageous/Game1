# GODOT_CURRENT_STATUS

## Updated

`2026-06-11`

## Branch

Current stage: Pre-G10 Project Baseline Consolidation.

Current main HEAD: `eb9f5d6a9df18bd019b424b1fca3000e56e20f3b`.

Current remote main HEAD: `eb9f5d6a9df18bd019b424b1fca3000e56e20f3b`.

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

G9 UI core flow baseline is in `main`. It is not a complete final UI, not complete MetaProgress, not complete Deploy persistence, and not complete long-term system completion.

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

The recommended follow-up UI shell branch should only consume ViewModel/snapshot data and dispatch commands. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private run-rule state.

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
```

Do not run Godot/editor/game/import unless separately authorized.

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

G10 is reserved for stability analysis, BUG fixes, UI readability optimization, interaction blocker triage, validation-chain trust checks, code convergence, documentation clarity, and future content planning.

G10 does not include complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping unless a later approved plan changes that boundary.
