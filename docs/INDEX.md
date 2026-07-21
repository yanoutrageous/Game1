# Game1 Docs Index

文档状态：I2 active 当前导航；实现尚未声明
最后更新：2026-07-22

## 第一入口

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/50_stages/active/STAGE_INDEX.md`
4. `docs/10_current/CURRENT_STATE.md`
5. `docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md`
6. `docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md`
7. `docs/00_governance/I2_SLICE_GATE_LEDGER.md`
8. `docs/10_current/CAPABILITY_MATRIX.yaml`
9. `docs/10_current/NEXT_ACTION.md`

## 当前权威材料

| 类型 | 文档 | 状态 |
| --- | --- | --- |
| 当前事实 | `docs/10_current/CURRENT_STATE.md` | current |
| 当前能力 | `docs/10_current/CAPABILITY_MATRIX.yaml` | current |
| 当前未完成 | `docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md` | current |
| I2 active stage | `docs/50_stages/active/STAGE_INDEX.md` | ACTIVE / implementation not claimed |
| I2 启动审计 | `docs/00_governance/I2_PRE_EXECUTION_SCOPE_RISK_AUDIT.md` | current pre-execution audit |
| I2 契约 | `docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md` | active contract |
| I2 起点评估 | `docs/10_current/I2_PRE_EXECUTION_BASELINE_ASSESSMENT.md` | active pre-execution assessment |
| I2 反馈矩阵 | `docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md` | current 43-item traceability |
| I2 架构/迁移 | `docs/30_engineering/architecture/I2_TARGET_ARCHITECTURE_AND_MIGRATION_PLAN.md` | target plan, not implemented |
| I2 验证/预览/人工计划 | `docs/30_engineering/godot/I2_VALIDATION_PREVIEW_AND_MANUAL_REVIEW_PLAN.md` | plan, not validation |
| I2 切片门账 | `docs/00_governance/I2_SLICE_GATE_LEDGER.md` | current gate authority |
| I1 契约 | `docs/20_product/I1_INCREMENTAL_DEVELOPMENT_BASELINE_CONTRACT.md` | closed contract |
| I1 评估 | `docs/10_current/I1_BASELINE_ASSESSMENT.md` | frozen closed assessment |
| I1 架构 | `docs/30_engineering/architecture/I1_ARCHITECTURE_BASELINE.md` | closed engineering baseline |
| I1 操作 | `docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md` | current runbook |
| I1 validation | `docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md` | CLOSED / PASS_WITH_NOTES |
| I1 handoff | `docs/handoff/HANDOFF_I1_INCREMENTAL_DEVELOPMENT_BASELINE.md` | CLOSED / PASS_WITH_NOTES |
| 执行环境 | `docs/00_governance/EXECUTION_ENVIRONMENT.md` | current |
| 来源注册 | `docs/00_governance/SOURCE_REGISTRY.md` | current |
| 重复台账 | `docs/00_governance/DUPLICATE_DOC_LEDGER.md` | current |
| 验证索引 | `docs/40_validation/VALIDATION_INDEX.md` | current |
| closed stages | `docs/50_stages/closed/STAGE_INDEX.md` | historical/current index |

## 冻结与历史证据

| 事实 | 证据 |
| --- | --- |
| I1 最新闭合非美术基线 | `docs/10_current/I1_BASELINE_ASSESSMENT.md`; `docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`; `docs/handoff/HANDOFF_I1_INCREMENTAL_DEVELOPMENT_BASELINE.md` |
| I0 前序冻结非美术基线 | `docs/10_current/I0_BASELINE_ASSESSMENT.md`; `docs/validation/I0_PROJECT_BASELINE_REFACTOR_VALIDATION.md`; `docs/handoff/HANDOFF_I0_PROJECT_BASELINE_REFACTOR.md` |
| ART21 项目级最新闭合美术阶段 | `docs/art/ART21_CLOSEOUT_MAIN_MENU_SCENE_RECONSTRUCTION.md`; `docs/art/validation/art21/` |
| ART23 较晚页面/UI 验收证据 | `docs/validation/ART23_LONG_TERM_FINAL_UI_VALIDATION.md`; `docs/art/validation/art23/` |
| ART24R2 失败封存 | `docs/validation/ART24R2_FINAL_COMPUTER_USE_RESULTS.md`; `docs/handoff/HANDOFF_ART24R2_FAILED_ACCEPTANCE_ARCHIVE.md` |

## 解释规则

- I2 是用户明确授权的单一跨线集成阶段；I2.0 文档/治理启动已接受，当前进入 I2.1 前置审计。I2.1–I2.7 必须逐切片过门，不能把计划或局部通过写成实现/阶段完成。
- I2 起点 exact HEAD `b77132b` 的 full/head 39/39 只证明进入回归基线；I2 当前没有 validation/handoff 或 runtime capability promotion。
- Godot 是实现目标，`E:\UE` 只读借鉴语义/交互/视觉概念。Deploy 地图保持同一页面，禁止 region→difficulty 分步页。
- I1 的关闭权威是本地提交态 full/head 39/39；远端 Actions run `29760789712` 只证明 quick，预览静态图片复核也不替代动态或交互验收。
- ART23 的具体页面/UI 证据不改变 AGENTS 指定的项目级 latest closed art stage = ART21。
- G40、M/G/ART 历史记录继续作为范围内证据，不覆盖当前代码和 I1 入口。
- 外部 source pack 路径、历史 Godot 路径和旧 branch 名只保留时间点含义。
