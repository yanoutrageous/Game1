# Handoff M3 Minimum Item Pack & Drop Loop

中文摘要：M3 完成最小物品包与掉落闭环实现后，下一步应进入审计 / commit gate。审计重点是验证 GroundLoot-first、背包、消耗品、三层收益、成功/失败/放弃结算、MetaProgress 写回与 UI 只读边界。

## 1. Implemented

- `M3ItemCatalog` provides minimum equipment, consumable, collectible, monster drop, and special item records.
- Search, chest, monster, event, and altar rewards are aligned to GroundLoot-first semantics.
- Backpack pickup, drop, repick, capacity blocking, and consumable use are routed through runtime services.
- Trader sale produces `safe_yield`.
- Success settlement converts run black coin plus safe_yield to long-term gold.
- Failure loses run black coin, retains safe_yield, and treats unused consumables as salvage candidates.
- Abandon is a distinct settlement outcome with black coin lost and safe_yield pending future rule.
- Inventory / GroundLoot / result / menu / DeployPrep text now distinguishes GroundLoot, backpack, run_black_coin, safe_yield, long_term_gold, and warehouse-lite.
- M2 validation runner was updated to accept M3 GroundLoot-first reward behavior.
- M3 validation script and headless runner were added.

## 2. Not Implemented

- No `demo_7x7`.
- No full warehouse UI or warehouse management.
- No complete equipment / loadout system.
- No full Objective / Reward / Pool.
- No complete Rule Engine.
- No large content pool expansion.
- No project metadata / scene / resource / uid / translation / import changes.
- No gameplay runtime PASS or manual playtest PASS claimed by this document.

## 3. Audit Checklist

Recommended audit checks:

- diff contains only M3 allowlist files plus documentation and validation tools;
- `git diff --check` passes;
- G35/G36/G37/G37S/G38 validators still pass;
- M2 validator and runner pass with GroundLoot-first semantics;
- M3 validator and runner pass;
- Godot project-load/parser smoke passes;
- settlement UI reads `RunResult` / `SettlementInput` and does not recalculate income;
- MetaProgress writes only after settlement.

## 4. Next Gate

Proceed to M3 audit / commit gate when validation is green. Commit should be limited to the M3 code, tools, and docs in this branch. Do not push or merge main without a separate gate.

## 5. Validation Notes

Current implementation validation status:

- G35, G36, G37, G38, M2, and M3 static validators passed.
- G37S supplement validator is stage-specific and rejected active M3 diff paths after its base G37 checks passed; do not report it as a runtime authority failure.
- Godot project-load/parser, G37 command sequence, M2 runner, and M3 runner passed.
- Godot shutdown resource-leak warnings were observed; no project/scene/resource/uid/translation/import metadata dirty side effects were observed.
- Manual playtest was not run.
