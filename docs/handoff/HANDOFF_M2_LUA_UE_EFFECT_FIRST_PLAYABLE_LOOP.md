# Handoff M2 Lua / UE Effect-First Playable Loop

中文摘要：M2-R2 已将现有 M1 标准局闭环整理为 effect-first 骨架。下一轮可以审计、补测并决定是否进入 commit / merge gate，但不得把本阶段误读为完整玩法系统完成。

## Delivered

- Standard `standard_10x10` route remains the playable entry.
- Placeholder numbers, content IDs, and text are centralized in run catalogs.
- HP damage, protocol pressure, mine trigger, explore pressure, event HP / pressure, and runtime terminal intents route through `RunEffectApplier` or existing runtime authority.
- Search / event / combat / settlement asset changes continue through `RunAssetLedger` and `RunAssetEffectHandler`.
- Result snapshot now exposes `RunResult` and `SettlementInput` from `RunResultBuilder`.
- LongTerm remains display-only and consumes MetaProgress / latest run summary without writing state.

## Important Boundaries

- No full Objective / Reward / Pool.
- No full LongTerm, Warehouse, equipment, consumable, research, codex, collection, or gacha.
- No full Rule Engine or large content pool.
- No formal art import.
- No Godot metadata commit.
- No manual playtest PASS unless a later visible test actually covers it.

## Follow-up

- Visible Computer Use smoke was PARTIAL: F1 entered `standard_10x10`, but follow-up key coverage still needs reliable foreground QA.
- Run full visible standard route smoke when GUI control is available.
- Continue tuning Lua / UE parity numbers in `RunBalanceCatalog`.
- Replace placeholder content IDs through a future content-table phase.
- Keep result UI and MetaProgress reading `RunResult` / result snapshot only.
