# Current State

文档状态：当前事实摘要
适用范围：DOC-GOV-002 文档治理阶段与 G38 / G37S / G37 最新仓库文档证据摘要
最后更新：2026/06/27

本文件只汇总当前事实入口，不替代验证记录、历史 handoff、产品契约或外部策划来源。

## 1. 当前文档治理阶段

```text
当前执行阶段：DOC-GOV-002 仓库 docs 入口、索引、README 与历史层归属治理
阶段性质：docs-only governance / documentation standardization
当前仓库分支观测：main
staged 观测：empty
```

DOC-GOV-002 只处理仓库文档入口、索引、README、历史层归属和后续文档落位规则。DOC-GOV-001 已完成并作为历史治理证据保留。

## 2. 当前工程文档证据链

| 阶段 | 当前索引状态 | 证据入口 |
| --- | --- | --- |
| G38 | current runtime architecture finalization / release gate pending | `docs/20_product/RUNTIME_ARCHITECTURE_FINALIZATION_CONTRACT.md`、`docs/validation/G38_RUNTIME_ARCHITECTURE_FINALIZATION_VALIDATION.md`、`docs/handoff/HANDOFF_G38_RUNTIME_ARCHITECTURE_FINALIZATION.md` |
| G37S | current validation / handoff supplement | `docs/validation/G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md`、`docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md` |
| G37 | current engineering evidence / release gate pending | `docs/20_product/RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_CONTRACT.md`、`docs/validation/G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_VALIDATION.md`、`docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION.md` |
| G36 | earlier runtime architecture / save profile evidence | `docs/20_product/RUNTIME_ARCHITECTURE_SAVE_PROFILE_FOUNDATION_CONTRACT.md`、`docs/validation/G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE_VALIDATION.md`、`docs/handoff/HANDOFF_G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE.md` |

G38 / G37S / G37 / G36 不声明 gameplay runtime PASS，也不声明 manual playtest PASS。

## 3. G38 边界摘要

G38 记录 RunScene responsibility boundary finalization：input routing、route handoff、command feedback、result/meta commit orchestration、debug meta operations 等 helper controller 边界。`RunRuntimeController` / `RunStateMachine` 仍是 runtime authority，`GameKernel` 仅保留 inactive compatibility facade，直到未来 project metadata gate。

G38 不实现 complete RunFlow、active-run persistence、Objective / Reward / Pool、complete settlement / economy、complete warehouse、complete Rule engine、gameplay runtime PASS 或 manual playtest PASS。

## 4. G37 / G37S 边界摘要

G37 记录 runtime authority / RunFlow execution consolidation：`RunRuntimeController` owns active `RunContext` and `CommandBus`，`RunStateMachine` owns lifecycle transitions，`RunScene` 降为 runtime construction orchestration。G37S 只补充 validation / handoff evidence，不修改 runtime code。

未实现 / 未声明：complete RunFlow rewrite、active-run persistence、SaveManager ownership migration、new gameplay systems、gameplay runtime PASS、manual playtest PASS。

## 5. 当前文档入口

```text
docs/README.md
docs/INDEX.md
docs/10_current/NEXT_ACTION.md
docs/10_current/CAPABILITY_MATRIX.yaml
docs/40_validation/VALIDATION_INDEX.md
docs/50_stages/active/STAGE_INDEX.md
docs/50_stages/closed/STAGE_INDEX.md
docs/00_governance/DOC_PLACEMENT_STANDARD.md
docs/00_governance/DUPLICATE_DOC_LEDGER.md
docs/00_governance/SOURCE_REGISTRY.md
```

## 6. 外部来源边界

```text
Base Docs = 外部策划原件 / 用户留档，不参与仓库去重。
Base Docs_Governance = 外部治理快照区，不替代当前仓库事实源。
Connection = 外部并行交接区，不复制内容入库。
Godot/GraytailGodot/docs = 工程历史 / 环境证据，不作为当前文档治理入口。
```
## M2 Lua / UE Effect-First Playable Loop

Status: implementation in progress on `godot/m2-lua-ue-effect-first-playable-loop`.

Current M2 scope: align the existing M1 playable loop to Lua / UE prototype effect-first behavior. DeployPrep starts the existing `standard_10x10` route through RunStartConfig / route adapter; RunScene keeps TruthMap / IntelMap separation; HP / pressure / room state / rewards route through effect and ledger boundaries; RunResult is SettlementInput; LongTerm consumes MetaProgress and latest result display-only.

Non-goals: no `demo_7x7`, no full Objective / Reward / Pool, no full LongTerm, no full warehouse, no full equipment/consumable system, no full Rule Engine, no metadata/resource import.

## M3 Minimum Item Pack & Drop Loop

Status: implementation in progress on `godot/m3-minimum-item-drop-loop`.

Current M3 scope: minimum item taxonomy and content pack, GroundLoot-first reward placement, backpack pickup/drop/repick, consumable use, three income layers (`run_black_coin`, `safe_yield`, `long_term_gold`), success/failure/abandon settlement boundaries, and read-only UI display alignment.

Contract: `docs/20_product/M3_MINIMUM_ITEM_DROP_LOOP_CONTRACT.md`.
Validation: `docs/validation/M3_MINIMUM_ITEM_DROP_LOOP_VALIDATION.md`.
Handoff: `docs/handoff/HANDOFF_M3_MINIMUM_ITEM_DROP_LOOP.md`.

Non-goals: no `demo_7x7`, no complete warehouse, no complete equipment/loadout system, no full Objective / Reward / Pool, no complete Rule Engine, no project metadata/resource import, no gameplay runtime PASS, and no manual playtest PASS.

## M3R Item Usability Completion

Status: implementation in progress on `godot/m3r-item-usability-completion`.

Current M3R scope: M3 supplement that makes the minimum item pack usable after warehouse writeback. It adds Warehouse Lite, Codex Lite, DeployPrep real minimal loadout, equipment carry-in, consumable carry-in, selected loadout propagation through `RunStartConfig` / `RunConfig`, and minimal profile / permit / protocol / talent interfaces.

Contract: `docs/20_product/M3R_ITEM_USABILITY_COMPLETION_CONTRACT.md`.
Validation: `docs/validation/M3R_ITEM_USABILITY_COMPLETION_VALIDATION.md`.
Handoff: `docs/handoff/HANDOFF_M3R_ITEM_USABILITY_COMPLETION.md`.

Non-goals: no complete warehouse economy, no complete LongTerm system, no complete Codex research, no complete equipment strengthening, no full Objective / Reward / Pool, no complete Rule Engine, no project metadata/resource import, no gameplay runtime PASS, and no manual long playtest PASS.

## M3H Item Loop Hardening

Status: implementation in progress on `godot/m3h-item-loop-hardening-metadata-hygiene`.

Current M3H scope: M3/M3R boundary hardening for in-run equipment registration, carry-in equipment validity, unused consumable failure salvage, abandon settlement semantics, `safe_yield` / `long_term_gold` naming, and generated metadata hygiene.

Contract: `docs/20_product/M3H_ITEM_LOOP_HARDENING_CONTRACT.md`.
Validation: `docs/validation/M3H_ITEM_LOOP_HARDENING_VALIDATION.md`.
Handoff: `docs/handoff/HANDOFF_M3H_ITEM_LOOP_HARDENING.md`.

Non-goals: no complete warehouse economy, no complete equipment strengthening, no full Objective / Reward / Pool, no complete Rule Engine, no Godot metadata/resource import, no gameplay runtime PASS, and no manual playtest PASS.
