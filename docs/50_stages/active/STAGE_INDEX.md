# Active Stage Index

文档状态：阶段索引
适用范围：当前活动阶段
最后更新：2026/06/27

## 活动阶段

| stage | lane | status | evidence | boundary |
| --- | --- | --- | --- | --- |
| DOC-GOV-002 | documentation governance | active / docs-only | `docs/README.md`、`docs/INDEX.md`、`docs/00_governance/DOC_PLACEMENT_STANDARD.md`、`docs/00_governance/DUPLICATE_DOC_LEDGER.md`、`docs/00_governance/DOC_GOV_002_EXECUTION_REPORT.md` | 不改 Base Docs / Base Docs_Governance / Connection / Base Art；不改工程代码；不运行 Godot；不 stage / commit / push |

## 当前工程证据 / 待后续 gate

| stage | status | evidence | boundary |
| --- | --- | --- | --- |
| G38 | release gate pending | `docs/validation/G38_RUNTIME_ARCHITECTURE_FINALIZATION_VALIDATION.md`、`docs/handoff/HANDOFF_G38_RUNTIME_ARCHITECTURE_FINALIZATION.md` | 需另行工程 gate；DOC-GOV-002 不自动执行 |
| G37S | validation / handoff supplement | `docs/validation/G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md`、`docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md` | supplement 证据，不写成 closed main |
| G37 | release gate pending | `docs/validation/G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_VALIDATION.md`、`docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION.md` | 需另行工程 gate；DOC-GOV-002 不自动执行 |

## 非活动但需保留的阶段名

| stage | status | note |
| --- | --- | --- |
| DOC-GOV-001 | completed / historical | 旧文档治理阶段，当前治理进入 DOC-GOV-002 |
| G36 and earlier | historical / closed evidence | 作为历史证据保留，不作为当前 active stage |
| P2 / G20 governance | historical | 旧治理材料保留；当前治理入口在 `docs/00_governance/` |
# M2 Latest Planning Minimum Gameplay & Meta Loop

| stage | lane | status | evidence | boundary |
| --- | --- | --- | --- | --- |
| M2 | program | implementation / validation pending | `docs/20_product/M2_LUA_UE_EFFECT_FIRST_PLAYABLE_LOOP_CONTRACT.md`; `docs/validation/M2_LUA_UE_EFFECT_FIRST_PLAYABLE_LOOP_VALIDATION.md`; `docs/handoff/HANDOFF_M2_LUA_UE_EFFECT_FIRST_PLAYABLE_LOOP.md` | effect-first Lua / UE parity; no full Objective / Reward / Pool; no full LongTerm / warehouse / Rule Engine; metadata dirty remains isolated |

# M3 Minimum Item Pack & Drop Loop

| stage | lane | status | evidence | boundary |
| --- | --- | --- | --- | --- |
| M3 | program | implementation / validation pending | `docs/20_product/M3_MINIMUM_ITEM_DROP_LOOP_CONTRACT.md`; `docs/validation/M3_MINIMUM_ITEM_DROP_LOOP_VALIDATION.md`; `docs/handoff/HANDOFF_M3_MINIMUM_ITEM_DROP_LOOP.md` | minimum item/drop loop; no complete warehouse/equipment, full Objective / Reward / Pool, complete Rule Engine, gameplay runtime PASS, or manual playtest PASS |

# M3R Item Usability Completion

| stage | lane | status | evidence | boundary |
| --- | --- | --- | --- | --- |
| M3R | program | implementation / validation pending | `docs/20_product/M3R_ITEM_USABILITY_COMPLETION_CONTRACT.md`; `docs/validation/M3R_ITEM_USABILITY_COMPLETION_VALIDATION.md`; `docs/handoff/HANDOFF_M3R_ITEM_USABILITY_COMPLETION.md` | M3 usability supplement; Warehouse Lite / Codex Lite / equipment and consumable carry-in only; no complete warehouse economy, complete LongTerm, complete Codex research, complete equipment strengthening, gameplay runtime PASS, or manual long playtest PASS |
