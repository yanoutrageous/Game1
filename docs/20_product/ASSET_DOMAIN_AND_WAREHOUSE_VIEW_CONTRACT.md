# Asset Domain And Warehouse View Contract

Document status: G27A docs-only contract foundation.
Last updated: 2026-06-23.

This document defines the product boundary between the asset domain and the warehouse view. G27A is documentation only. It does not implement runtime asset storage, warehouse operations, reward delivery, gacha, settlement mutation, persistence, or UI behavior.

## 1. Positioning

The warehouse is an independent asset view. It displays owned or known assets through read-only snapshots, but it does not define the core item ontology by itself.

The asset domain remains responsible for shared naming, references, tags, policies, and preview contracts that can be consumed by DeployPrep, Settlement, History, LongTerm, Reward, and future Warehouse UI slices.

## 2. Core Product Vocabulary

`AssetRef`:
Stable product-level reference for an asset, item, unlock, collectible, appearance, or future asset-like record. It is an identifier contract, not a storage record.

`AssetDescriptor`:
Display descriptor for an asset reference. It may include display name keys, icon keys, rarity keys, source labels, category links, and short effect text. It is not a live inventory object.

`AssetCategory`:
High-level product grouping used for display and filtering. Warehouse categories may reference item-type concepts, but category membership does not create a new item ontology.

`AssetTag`:
Additional marker for source, state, policy, identity, feature unlock, event origin, or future system routing. Tags are descriptive metadata.

`AssetPolicy`:
Read-only rule descriptor for visibility, carry eligibility, claimability, sellability, protection, identification state, settlement handling, and future UI affordances. G27A only documents policy vocabulary; it does not implement a rule engine.

## 3. Read-Only Snapshots

`OwnedAssetSnapshot` is a read-only, display-only, preview snapshot of an owned or known asset. It must not write inventory, grant rewards, remove assets, sell assets, equip assets, carry assets, or persist changes.

`WarehouseViewSnapshot` is a read-only, display-only, preview projection over asset snapshots for warehouse-like browsing. It may group, filter, summarize, and mark candidate actions, but it must not become the real warehouse system.

All G27A snapshots must carry equivalent boundary flags:

```text
read_only = true
display_only = true
preview = true
```

## 4. Event And Source Preview

`AssetEventPreview` describes a possible or historical asset-domain change. It is a preview record only. It must not dispatch events, mutate ledgers, write inventory, or grant rewards.

`AssetSourceContext` describes where an asset reference or snapshot came from, such as deploy prep, settlement, history, claim preview, gacha preview, objective preview, or manual product fixture. It is source context, not an execution channel.

## 5. Deploy Boundary

`DeployAssetView` is the display-only projection used by DeployPrep or future start-flow screens to show candidate carry/equip state. It must not equip or move assets.

`CarryIntent` reserves the product boundary for "would carry into a run" state. It is an intent preview, not a real loadout write and not a RunStartConfig mutation.

## 6. Settlement And History Boundary

`SettlementAssetDelta` reserves a preview shape for returned, lost, cleared, rescued, converted, or referenced assets at settlement time. G27A does not implement settlement mutation or reward delivery.

`HistoryAssetReference` preserves what a past run result displayed. It does not depend on the current warehouse state. If a run once displayed an asset, later sale or mutation must not rewrite that historical reference.

## 7. LongTerm, Collection, Appearance, And Gacha Boundary

LongTerm collection, appearance, profile, codex, research, and gacha previews may reference assets through `AssetRef` and `AssetDescriptor`.

Those systems do not merge into the warehouse. Warehouse view, collection view, appearance view, gacha pool view, and objective/reward preview remain separate consumers over shared asset vocabulary.

## 8. Explicit Non-Goals

G27A does not implement:

- real warehouse storage
- real asset write or mutation
- sale, equip, carry, remove, convert, claim, or grant operations
- reward delivery
- gacha probability, pity, cost, draw, or result delivery
- settlement asset mutation
- objective progress or completion
- SaveManager or persistence
- AssetLedger or CommandBus mutation
- Godot scene, resource, import, UID, or project configuration changes

## 9. Recommended Next Slices

G27B may consider a Godot asset / warehouse view schema foundation if a separate gate approves code changes.

G27C may consider a display-only UI consumer for the warehouse view if a separate gate approves UI changes.

Objective / Reward / Pool contract work remains deferred to G28 or later unless a separate gate changes the roadmap.
