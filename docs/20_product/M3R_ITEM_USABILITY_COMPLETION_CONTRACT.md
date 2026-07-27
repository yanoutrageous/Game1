# M3R Item Usability Completion Contract

中文摘要：M3R 是 M3 Minimum Item Pack & Drop Loop 的返工补足阶段，不是 M4。它把 M3 已经完成的 GroundLoot、背包、消耗、结算和 MetaProgress 入仓闭环继续补齐到“玩家可用”的最小物品包闭环：Warehouse Lite、Codex Lite、Equipment Loadout、Consumable Carry-In、DeployPrep 最小真实出发配置，以及 Talent/Profile/Permission/Protocol 的最小接口。

## 1. Stage Position

M3R completes the minimum usable item pack loop on top of M3:

```text
item obtained in run
-> stored through settlement into MetaProgress warehouse_items
-> visible in Warehouse Lite / Codex Lite
-> selectable for DeployPrep loadout
-> carried into the next standard run
-> equipment / consumables affect runtime state
-> success or failure settlement preserves or removes items by M3 rules
```

M3R is not a complete Warehouse, complete LongTerm system, complete Codex research, complete equipment upgrade, full Objective / Reward / Pool, or complete Rule Engine.

## 2. Source Basis

External sources were read as read-only planning references. Their body text is not copied into the repository:

- `sources/base/原始策划案/最小物品包与掉落闭环内容策划案.md`
- `sources/base/原始策划案/出发探索界面与出勤准备规则策划修正案.md`
- `sources/base/原始策划案/物品资产模型与内容映射规则策划案.md`
- `sources/base/原始策划案/长期系统整合与资产接口规则策划案.md`
- `sources/base/原始策划案/长期系统内容补全策划案.md`
- `sources/base/原始策划案/本局结算报告与历史战绩系统.md`
- `sources/base/原始策划案/规则、效果、Modifier 与内容投放通用系统策划案.md`

The M3 minimum item pack document has priority for this stage when item category, warehouse, carry-in, salvage, unique item, safe yield, and minimum talent/interface rules conflict with older references.

## 3. Warehouse Lite

Warehouse Lite reads real `MetaProgressAdapter.get_summary().warehouse_items` data. It groups and exposes items as:

- operation equipment
- operation consumables
- collectibles
- special items

Each normalized card keeps stable `item_id`, name, item type, weight, base value, source, collectible level, and capability flags such as `can_equip`, `can_consume`, `can_carry`, and `can_sell`.

Warehouse Lite is intentionally limited:

- It is a real read consumer of stored items.
- It provides selected equipment and selected consumable candidates for DeployPrep.
- It does not implement full warehouse economy, sale confirmation, sorting/filtering depth, drag/drop, item upgrade, or permanent asset mutation UI.

## 4. Codex Lite

Codex Lite derives discovery entries from `warehouse_items` instead of showing a future-jump placeholder only.

Minimum coverage:

- collectible entries discovered through stored collectible items
- equipment and consumable entries discovered through warehouse ownership
- special / monster-sample style entries when matching stored item metadata exists
- undiscovered placeholders for the minimal M3R category set

Codex Lite is read-only. It does not implement complete research, reward claims, red dots, collection scoring, or full content archive behavior.

## 5. Equipment / Loadout

M3R makes equipment minimally usable:

- `equip_item` and `unequip_item` are routed through `CommandBus`.
- UI is not allowed to directly mutate the ledger arrays.
- DeployPrep derives `selected_equipment_items` from Warehouse Lite data.
- `RunStartConfig` and `RunConfig` carry selected equipment into the next run.
- Runtime setup places carry-in equipment in the equipped location and applies supported passive context.

Minimum real effects include capacity, salvage capacity, mine damage reduction, scan/display hooks, or protocol-pressure-related hooks. Items found during a run remain unregistered equipment until settlement stores them; they do not become active immediately.

## 6. Consumable Carry-In

M3R makes operation consumables cross-run usable:

- Warehouse Lite can select operation consumables for the next run.
- `RunStartConfig` and `RunConfig` carry selected consumables.
- Runtime setup places carry-in consumables in the inventory/backpack.
- Consumable use is routed through the existing command / ledger flow.
- Used consumables are removed and recorded by ledger transactions.
- Unused carry-in consumables can return through success settlement.
- Failure settlement treats unused consumables as salvage candidates by M3 weight/value rules.

M3R does not implement a complete consumable shop economy.

## 7. Settlement / MetaProgress Boundary

M3R must preserve M3 settlement rules:

- successful extraction converts `run_black_coin` to long-term gold
- failed runs lose `run_black_coin`
- `safe_yield` writes to long-term gold on success or failure
- successful carried backpack/equipped/unused consumables enter warehouse
- failed items use salvage capacity and base value, not a fixed one-item rule
- unpicked GroundLoot is lost
- unique items do not enter ordinary drops

MetaProgress remains the storage boundary for the minimal warehouse list. Result UI and menu summaries may read snapshots but must not recalculate settlement.

## 8. Talent / Profile / Permission / Protocol Minimal Interfaces

M3R provides minimal data/interface hooks only:

- profile level / exp fields
- permit level field
- protocol difficulty field
- talent point / talent flag fields
- talent hooks for carry capacity, failure salvage capacity, mine damage tolerance, trader/safe-yield, scan, and protocol pressure

Only a small subset has live hooks. M3R does not implement a full 50-level profile table, full permit table, full talent tree UI, complete protocol matrix, or complete difficulty system.

## 9. Forbidden Expansion

M3R explicitly does not complete:

- full LongTerm system
- full Warehouse economy
- full Codex research
- full equipment upgrade
- full Objective / Reward / Pool
- full Rule Engine
- full active run persistence
- new large event / monster / chest content set
- formal art replacement or import
- project metadata / scene / resource / import changes

Godot headless parser/runtime runners and visible checks must not be reported as complete gameplay runtime PASS or manual long playtest PASS.
