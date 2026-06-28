# M3 Minimum Item Pack & Drop Loop Contract

中文摘要：M3 落地“最小物品包与掉落闭环”。本阶段把 M1/M2 已有可玩闭环中的搜索、宝箱、怪物、事件、交易、消耗品、背包、GroundLoot、结算和 MetaProgress 写回统一到最小可验证规则。M3 不是完整仓库、完整装备、完整 Objective / Reward / Pool、完整 Rule Engine 或长期系统扩展。

## 1. Scope

M3 establishes the minimum runtime contract for:

- item taxonomy: equipment, consumable, collectible, special;
- deterministic item catalog and drop tables;
- GroundLoot-first reward placement for search, chest, monster, event, altar, and debug test drops;
- backpack pickup, drop, repick, capacity blocking, and consumable use;
- income split between `run_black_coin`, `safe_yield`, and `long_term_gold`;
- success, failure, and abandon settlement behavior;
- minimal DeployPrep / inventory / GroundLoot / result / menu-summary display wording.

## 2. Item Taxonomy

The minimum item pack uses four main types only:

- `equipment`: player-facing equipment records for future loadout and warehouse views;
- `consumable`: active use items consumed from backpack through command/rule/effect paths;
- `collectible`: ordinary salvage / collection items with collectible levels 1-6;
- `special`: event / altar / commission style special references.

Unique items are not ordinary drops in M3. Unique behavior remains a future explicit gate.

## 3. Minimum Content Pack

M3 provides:

- 6 equipment items;
- 6 consumable items;
- 24 collectibles across levels 1-6;
- 5 monster-drop items;
- special event / altar descriptors.

Each item carries display name, short description, fallback icon key, tags, source, weight, base value, storage/sell/consume/equip flags, and source label.

## 4. Drop Loop

Reward item placement is GroundLoot-first:

- search / chest rewards create room-floor items;
- monster trophies create room-floor items;
- event and altar item rewards create room-floor items unless an explicit future audited rule says otherwise;
- debug spawn can still target inventory or room floor by command, but ordinary test drops remain marked as debug-sourced.

Pickup moves GroundLoot into backpack only after capacity validation. Drop moves backpack items back to GroundLoot. Unpicked GroundLoot is lost at settlement.

## 5. Consumable Use

Consumables are used through `use_consumable` / `use_item` command intent and `RunRuleService.use_consumable`.

Minimum supported effect directions:

- heal;
- scan adjacent rooms;
- mine immunity;
- protocol pressure reduction;
- failure salvage capacity increase;
- safe_yield grant.

Consumable use consumes the backpack item and records a ledger transaction. Unused consumables no longer default-clear at run end: success moves them to warehouse-lite; failure treats them as salvage candidates.

## 6. Income Layers

M3 separates three income layers:

- `run_black_coin`: in-run pending currency; converted only by success settlement;
- `safe_yield`: retained settlement yield from explicit safe sources such as trader sale;
- `long_term_gold`: MetaProgress-visible gold after settlement writeback.

Success converts black coin plus safe_yield into long-term gold. Failure loses black coin but retains safe_yield into long-term gold. Abandon explicitly does not convert safe_yield in M3 and marks it as pending future rule.

## 7. Settlement Rules

Success:

- inventory / equipped equipment, collectibles, special items, and unused consumables enter warehouse-lite;
- unpicked GroundLoot is lost;
- black coin plus safe_yield becomes long-term gold.

Failure:

- black coin is lost;
- safe_yield is retained into long-term gold;
- backpack/equipped items, including unused consumables, enter salvage candidate selection;
- unpicked GroundLoot is lost.

Abandon:

- black coin is lost;
- backpack, equipped, and floor items are lost;
- safe_yield remains explicit pending/undecided;
- no long-term gold is granted in M3.

## 8. Display Consumers

Inventory, GroundLoot, result summary, menu summary, DeployPrep preview text, and debug command feedback may display M3 fields. UI must not recalculate settlement values and must not write save data directly.

## 9. Non-Goals

M3 does not implement:

- complete warehouse UI or warehouse management;
- real equipment loadout system;
- full Objective / Reward / Pool;
- complete Rule Engine;
- large new event / monster / chest content packs;
- complete LongTerm expansion;
- project metadata, scenes, resources, imports, uid, or translation changes;
- gameplay runtime PASS or manual playtest PASS unless separately validated.
