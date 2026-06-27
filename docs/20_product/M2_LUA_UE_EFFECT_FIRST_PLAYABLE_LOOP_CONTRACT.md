# M2 Lua / UE Effect-First Playable Loop Contract

中文摘要：M2-R2 将 M1 已有可玩闭环对齐到 Lua demo / UE 原型的“先有真实效果，再展示反馈”骨架。它允许 placeholder 数值、文案和内容 ID，但玩家看到的 HP、协议压力、黑币、背包、地面物、房间状态、撤离、失败、结算和 MetaProgress 必须来自真实运行状态或 result snapshot。

## Source Placement

- 仓库文档入口遵循 `docs/README.md`、`docs/INDEX.md` 和 `docs/00_governance/DOC_PLACEMENT_STANDARD.md`。
- Base Docs 是用户原始注入策划来源，只登记来源，不复制正文、不改写、不参与仓库去重。
- Connection 是外部交接区，不复制内容入库。

## Planning / Prototype Sources

- `D:\AGAME1\Base Docs` latest planning drafts, read-only.
- Lua prototype code, read-only reference for HP, pressure, black coin, inventory, event, combat, extraction, and meta settlement behavior.
- UE prototype code, read-only reference for command flow, loot rules, settlement, and meta progress.

## Scope

M2 effect-first covers the current Godot standard run route:

1. MainMenu / DeployPrep start the existing playable `standard_10x10` route.
2. RunScene keeps TruthMap / IntelMap separation and exposes UI snapshots.
3. Search, chest, event, monster, mine, extract, fail, settlement, and MetaProgress remain real M1 state flow.
4. `RunBalanceCatalog`, `RunContentCatalog`, and `RunTextCatalog` centralize placeholder numbers, content IDs, and player-facing copy.
5. `RunEffectApplier` routes HP, pressure, room marks, event completion, run fail/extract intent, debug markers, and asset-effect handoff through one auditable runtime boundary.
6. `RunResultBuilder` exposes `RunResult` / `SettlementInput`; result UI and MetaProgress consume snapshots instead of recalculating rewards.
7. LongTerm consumes MetaProgress / latest run summary as display-only context only.

## Required Effect Types

- `hp_delta`
- `protocol_pressure_delta`
- `pending_gold_delta`
- `safe_gold_delta`
- `ground_loot_add`
- `ground_loot_remove`
- `backpack_item_add`
- `backpack_item_remove`
- `room_mark_explored`
- `room_mark_cleared`
- `event_mark_completed`
- `monster_mark_defeated`
- `mine_mark_triggered`
- `run_fail`
- `run_extract`
- `debug_marker`

## Non-goals

- No full Objective / Reward / Pool system.
- No full LongTerm, Warehouse, equipment, consumable loadout, research, codex, collection, or gacha.
- No full Rule Engine, expression language, AI Director, or large content pool.
- No formal art import, scene/resource rewrite, or Godot metadata commit.
- No Lua/UE direct port; prototypes are behavior references only.

## Boundaries

- UI does not directly write saves.
- Result UI does not recalculate rewards.
- Debug remains command-gated and must not directly edit UI labels.
- Settlement reads `RunResult` / result snapshot as the single input.
- MetaProgress writes only through existing save adapter flow.
- Metadata dirty such as `project.godot`, `.translation`, `.uid`, and `.import` is outside this contract unless separately authorized.
