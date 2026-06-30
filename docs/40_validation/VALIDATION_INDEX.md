# Validation Index

文档状态：验证索引
适用范围：仓库验证记录入口
最后更新：2026/06/27

验证记录只证明其明确验证范围。Godot headless project-load/parser smoke PASS 不等于 gameplay runtime PASS；manual playtest 未运行时不得写成 PASS。

## 1. 当前验证读取顺序

| stage | evidence | boundary |
| --- | --- | --- |
| DOC-GOV-002 | `docs/00_governance/DOC_GOV_002_EXECUTION_REPORT.md` | docs-only governance 自检；不运行 Godot；不 stage / commit / push |
| G38 | `docs/validation/G38_RUNTIME_ARCHITECTURE_FINALIZATION_VALIDATION.md` | runtime architecture finalization；release gate pending；不声明 gameplay runtime PASS / manual playtest PASS |
| G37S | `docs/validation/G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md` | validation / handoff supplement；不修改 runtime code；不扩大 G37 结论 |
| G37 | `docs/validation/G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_VALIDATION.md` | runtime authority / RunFlow execution consolidation；release gate pending；不声明 gameplay runtime PASS / manual playtest PASS |
| G36 | `docs/validation/G36_RUNTIME_ARCHITECTURE_SAVE_PROFILE_VALIDATION.md` | earlier runtime architecture / save profile foundation evidence |
| G35 | `docs/validation/G35_RUNTIME_SAFETY_OWNERSHIP_CLEANUP_VALIDATION.md` | runtime safety / ownership cleanup |
| G34 | `docs/validation/G34_RULE_EFFECT_MODIFIER_CONTENT_DELIVERY_COMMON_SYSTEM_VALIDATION.md` | rule/effect/modifier/content-delivery preview content |
| G33 | `docs/validation/G33_ROOM_TYPE_TAG_ENCOUNTER_COMMON_RULE_VALIDATION.md` | room type/tag/encounter common-rule preview content |
| G32 | `docs/validation/G32_RUN_FLOW_STATE_TRANSITION_FULL_CONTENT_VALIDATION.md` | run flow/state transition preview content |
| G31 | `docs/validation/G31_RUN_MAP_DOMAIN_ROOM_STATE_FOUNDATION_VALIDATION.md` | run map/room-state preview content |
| G30 | `docs/validation/G30_LONG_TERM_SYSTEM_ASSET_INTERFACE_FULL_CONTENT_VALIDATION.md` | LongTerm asset interface preview content |
| G27A-G29 | `docs/validation/` and `docs/handoff/` | historical / closed evidence |
| G20-G26 | `docs/validation/` and `docs/handoff/` | historical / closed evidence |

## 2. 使用边界

```text
1. validation 原文保留原位。
2. 本索引不复制完整验证正文。
3. 本索引不扩大验证结论。
4. gameplay runtime PASS 和 manual playtest PASS 必须有对应实际验证记录，否则不得声明。
5. G37/G38 不在本索引中被写成 closed 或 main 已完成。
6. DOC-GOV-002 不运行 Godot，不新增工程验证结论。
```
# M2 Latest Planning Minimum Gameplay & Meta Loop

| stage | evidence | boundary |
| --- | --- | --- |
| M2 | `docs/validation/M2_LUA_UE_EFFECT_FIRST_PLAYABLE_LOOP_VALIDATION.md` | Lua / UE effect-first playable loop alignment; no full Objective / Reward / Pool, LongTerm, warehouse, Rule Engine, gameplay runtime PASS, or manual playtest PASS unless separately validated |

# M3 Minimum Item Pack & Drop Loop

| stage | evidence | boundary |
| --- | --- | --- |
| M3 | `docs/validation/M3_MINIMUM_ITEM_DROP_LOOP_VALIDATION.md` | GroundLoot-first item/drop loop, consumables, income layers, settlement boundaries; no full warehouse/equipment/Objective/Reward/Pool/Rule Engine or manual playtest PASS |

# M3R Item Usability Completion

| stage | evidence | boundary |
| --- | --- | --- |
| M3R | `docs/validation/M3R_ITEM_USABILITY_COMPLETION_VALIDATION.md` | M3 supplement for Warehouse Lite, Codex Lite, Equipment Loadout, Consumable Carry-In, and minimal profile/permit/protocol/talent hooks; no complete warehouse, complete LongTerm, complete Codex research, complete equipment strengthening, gameplay runtime PASS, or manual long playtest PASS |

# M3H Item Loop Hardening

| stage | evidence | boundary |
| --- | --- | --- |
| M3H | `docs/validation/M3H_ITEM_LOOP_HARDENING_VALIDATION.md` | M3/M3R hardening for in-run equipment registration, abandon settlement semantics, currency naming, and metadata hygiene; no complete warehouse/equipment/Objective/Reward/Pool/Rule Engine, gameplay runtime PASS, or manual playtest PASS |

# G39 Navigation Boundary Route Closure

| stage | evidence | boundary |
| --- | --- | --- |
| G39 | `docs/validation/G39_NAVIGATION_BOUNDARY_ROUTE_CLOSURE_VALIDATION.md` | AppShell/PageRouter/RunScene navigation boundary and critical route closure; no full settings, Save/Profile UI, Objective/Reward/Pool, ART import, gameplay runtime PASS, or manual long playtest PASS |

# M5 Minimum Item Pack & Drop Loop Full Content

| stage | evidence | boundary |
| --- | --- | --- |
| M5 | `docs/validation/M5_MINIMUM_ITEM_PACK_DROP_LOOP_FULL_CONTENT_VALIDATION.md` | Minimum item pack and drop loop full content; no complete warehouse economy, complete equipment strengthening, full Objective/Reward/Pool, complete Rule Engine, gameplay runtime PASS, or manual playtest PASS |
