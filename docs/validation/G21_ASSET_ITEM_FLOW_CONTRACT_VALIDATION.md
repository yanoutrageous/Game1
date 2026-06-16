# G21 Asset & Item Flow Contract Foundation Validation

## Scope

G21-R3 adds an asset and item flow contract foundation only.

Implemented code files:

- `Godot/GraytailGodot/scripts/core/asset/asset_contract.gd`
- `Godot/GraytailGodot/scripts/core/asset/item_schema.gd`
- `Godot/GraytailGodot/scripts/core/asset/asset_event_schema.gd`
- `Godot/GraytailGodot/scripts/core/asset/asset_projection_schema.gd`

This stage defines schema, constants, default helpers, normalize helpers, validate helpers, and read-only projection schema. It does not implement a real asset system.

## Contract Boundary

G21-R3 keeps the four asset categories:

- 通用资产 / 资源
- 实体物品
- 外观解锁
- 记录与功能解锁

G21-R3 keeps the four entity item main types:

- 装备
- 消耗品
- 藏品
- 特殊物

G21-R3 records that unique is not an item main type. Unique remains a collectible rarity or special kind. Cosmetic is a cosmetic unlock, not an inventory item main type. Codex entries are records. Research unlocks are function unlocks.

Policy fields describe rule choices. Tag fields are metadata for display, filtering, source records, and routing hints. G21-R3 does not implement a Policy or Tag rule engine.

## Explicit Non-Goals

G21-R3 does not implement:

- real warehouse
- real inventory
- real sell flow
- real equip flow
- real gacha
- real probability
- real settlement report
- real history storage
- real objective reward
- real red dot state
- real reward claim
- real persistence
- real MetaProgress
- real item content table
- real item content list
- real numeric balance
- real icon or art reference
- real event bus
- real RewardBundle grant
- real AssetEvent write
- real ItemInstance persistence
- real Policy / Tag rule engine

G21-R3 does not start RunScene, does not dispatch CommandBus, and does not read RunContext / Encounter / Combat / Ledger / TruthMap private state.

G21-R3 does not modify DeployPrepShell, DeployConfig, LongTermShell, LongTermSnapshot, RunAssetLedger, AssetCatalog, run_scene, CommandBus, project.godot, scenes, resources, import products, `.uid`, `.translation`, or Base Docs.

## Static Validation Commands

Run from repository root:

```bat
git diff --stat
git diff --check
git status --short
git diff --name-only

rg -n "FileAccess|user://|ResourceLoader|CommandBus\.dispatch|command_bus\.dispatch|RunContext|Encounter|Combat|Ledger|TruthMap|MetaProgress|save|persist|grant_reward|claim_reward|clear_red_dot|roll_gacha|gacha_roll|equip|warehouse write|inventory write|AssetCatalog|RunAssetLedger" Godot/GraytailGodot/scripts/core/asset Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs

rg -n "AssetContract|ItemSchema|AssetEventSchema|AssetProjectionSchema|schema_version|default_|normalize_|validate_|ItemDefinition|ItemInstance|ItemStack|AssetEvent|ResourceEvent|ItemEvent|UnlockEvent|HistoryRecordEvent|Policy|Tag|projection|unique_duplicate_policy|identification_state|CosmeticUnlock" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
```

Negative grep hits in docs are allowed only when they state non-goals or boundaries. Negative grep hits in `Godot/GraytailGodot/scripts/core/asset` for forbidden runtime dependencies must be treated as blockers.

## Godot Runtime Boundary

G21-R3 does not run Godot.

If G21-R4 is authorized, run Godot headless project-load/parser smoke with:

```text
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

Project path:

```text
D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
```

Any future G21-R4 smoke may only be recorded as Godot headless project-load/parser smoke PASS. It must not be recorded as complete gameplay runtime PASS or manual playtest PASS.
