# GODOT_CURRENT_STATUS

## Updated

`2026-06-10`

## Branch

Current G8.1 hardening branch: `godot/g8-1-architecture-hardening`.

G8 rules branch: `godot/g8-rules-asset-ledger-core`.

Base branch: `main`.

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

## UI Boundary

Future UI work should consume:

- `RunContext.get_status_snapshot()`
- result snapshots
- HUD/ViewModel fields
- CommandBus commands

The recommended follow-up branch `godot/player-ui-g8` should only consume ViewModel/snapshot data and dispatch commands. It must not directly read or write `RunAssetLedger`, `TruthMap`, or private run-rule state.

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
