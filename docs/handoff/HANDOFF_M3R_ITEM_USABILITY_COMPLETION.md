# Handoff M3R Item Usability Completion

中文摘要：M3R 完成 M3 的最小物品包可用性补足后，下一步应进入审计 / commit gate 或后续 M4 规划。审计重点是确认 Warehouse Lite、Codex Lite、出勤装备/消耗品带入、下一局 runtime 生效、结算和 MetaProgress 不回退，并确认未误声明完整长期、完整仓库、完整图鉴研究或完整装备强化。

## 1. Stage

```text
Stage: M3R-R2 Minimum Item Pack Usability Completion
Branch: godot/m3r-item-usability-completion
Commit: recorded in final execution report after commit
```

M3R is a supplement to M3, not M4.

## 2. Implemented Boundary

Implemented / aligned:

- Warehouse Lite model reading real `MetaProgressAdapter` warehouse items
- Codex Lite model deriving discovery state from stored item data
- DeployPrep dynamic warehouse/loadout cards from meta summary
- non-preview minimal `RunStartConfig` path for selected equipment and selected consumables
- runtime carry-in setup for equipment and consumables
- `CommandBus` equipment commands delegated to run asset authority
- settlement writeback path that removes selected carry-in items before upserting returned/salvaged items
- minimal profile / permit / protocol / talent fields and hooks
- M3R validation script and Godot runner

## 3. Still Not Implemented

Not implemented by M3R:

- complete Warehouse economy
- sale confirmation and full transaction UI
- complete Codex research or rewards
- complete LongTerm system
- complete equipment strengthening
- complete consumable shop
- complete Objective / Reward / Pool
- complete Rule Engine
- complete active-run persistence
- formal art/resource import
- gameplay runtime PASS
- manual long playtest PASS

## 4. Audit Focus

Audit should verify:

- `warehouse_items` are the source for Warehouse Lite and Codex Lite
- DeployPrep no longer drops selected equipment/consumables before starting the standard run
- equipment effects are visible through runtime state or snapshot
- carry-in consumables enter inventory and used consumables are removed
- M3 settlement rules still hold for black coin, safe yield, success warehouse writeback, and failure salvage
- unique items remain excluded from ordinary M3 drops
- UI remains a consumer and does not directly write save or ledger state
- forbidden metadata/project/scene/resource/import paths are absent from staged diff

## 5. Recommended Next Gate

Recommended next gate:

```text
M3R-R3 audit / validation / commit gate
```

If accepted, later M4 planning can decide whether to expand into complete warehouse UX, claim/purchase economy, full codex/research, equipment strengthening, or Objective / Reward / Pool. Those are not part of M3R.
