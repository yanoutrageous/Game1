# Handoff G21 Asset & Item Flow Contract Foundation

## Status

G21-R3 implements the Asset & Item Flow Contract Foundation on branch `godot/g21-asset-item-flow-contract`.

G21-R3 commit: `29a68e7b093ae653be212e32eb97042c0a7c0a4c`.

G21-R4 acceptance passed with Godot headless project-load/parser smoke PASS. The smoke run left the working tree clean with no dirty side effects.

G21-R4B closeout commit and first main commit containing G21: `fdadd78ccdf1d61378ac93a74cfe26449e47c411`.

G21 is fast-forward merged to `main`. G22 has not started.

This is a contract foundation only. It provides schema, constants, default helpers, normalize helpers, validate helpers, and read-only projection schema.

## Added Code

- `Godot/GraytailGodot/scripts/core/asset/asset_contract.gd`
- `Godot/GraytailGodot/scripts/core/asset/item_schema.gd`
- `Godot/GraytailGodot/scripts/core/asset/asset_event_schema.gd`
- `Godot/GraytailGodot/scripts/core/asset/asset_projection_schema.gd`

## Contract Summary

Asset categories:

- resource
- item
- cosmetic_unlock
- record_or_function_unlock

Item main types:

- equipment
- consumable
- collectible
- special

Non-main-type boundaries:

- unique is a collectible rarity or special kind, not a main type.
- cosmetic is a cosmetic unlock, not an item main type.
- gacha item is a source, not a main type.
- task item is special with metadata.
- commission item is special or collectible with source metadata.
- sample is a special item subtype.
- unidentified value is an identification state.
- codex entry is a record.
- research unlock is a function unlock.

Policy describes rule choices. Tag is metadata for display, filtering, source records, and routing hints. G21-R3 does not add a Policy or Tag rule engine.

## Projection Boundary

G21-R3 reserves read-only projection schemas for:

- warehouse_projection
- deploy_prep_projection
- settlement_projection
- history_projection
- codex_projection
- research_projection
- gacha_projection
- objective_projection
- long_term_projection

These projections describe future read boundaries. They do not implement future systems.

## Existing System Boundaries

`AssetCatalog` remains a presentation resource manifest and lookup layer. G21-R3 does not depend on it.

`RunAssetLedger` remains a run-scoped ledger. G21-R3 does not read, write, replace, or wrap it.

`DeployConfig` and `LongTermSnapshot` keep their existing preview semantics. G21-R3 does not modify DeployPrepShell, DeployConfig, LongTermShell, or LongTermSnapshot.

## Non-Goals

G21 does not implement real warehouse, inventory, sell, equip, gacha, probability, settlement report, history storage, objective reward, red dot state, reward claim, persistence, MetaProgress, item content tables, numeric balance, art references, event bus, RewardBundle grant, AssetEvent write, ItemInstance persistence, or Policy / Tag rule engine.

G21 does not start RunScene, dispatch CommandBus, or read RunContext / Encounter / Combat / Ledger / TruthMap private state.

G21-R4B does not modify project.godot, scenes, resources, fonts, import products, `.uid`, `.translation`, Base Docs, or the wrong external Godot path.

## Validation

Use `docs/validation/G21_ASSET_ITEM_FLOW_CONTRACT_VALIDATION.md`.

G21-R3 did not run Godot. G21-R4 ran Godot headless project-load/parser smoke and recorded PASS.

Do not claim full gameplay runtime PASS or manual playtest PASS for G21.

## PATCH_MODE

Current execution environment remains `PATCH_MODE=AGAME1_ROOT`. Future apply_patch writes must use `_repo_cache/Game1_work/` prefixes unless a fresh probe proves otherwise.
