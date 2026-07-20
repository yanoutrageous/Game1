# Game1 Docs Index

文档状态：I1 关闭后的当前导航
最后更新：2026-07-21

## 第一入口

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/10_current/CURRENT_STATE.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/10_current/NEXT_ACTION.md`

## 当前权威材料

| 类型 | 文档 | 状态 |
| --- | --- | --- |
| 当前事实 | `docs/10_current/CURRENT_STATE.md` | current |
| 当前能力 | `docs/10_current/CAPABILITY_MATRIX.yaml` | current |
| 当前未完成 | `docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md` | current |
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
| active stage | `docs/50_stages/active/STAGE_INDEX.md` | none authorized |
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

- I1 的关闭权威是本地提交态 full/head 39/39；远端 Actions run `29760789712` 只证明 quick，预览静态图片复核也不替代动态或交互验收。
- ART23 的具体页面/UI 证据不改变 AGENTS 指定的项目级 latest closed art stage = ART21。
- G40、M/G/ART 历史记录继续作为范围内证据，不覆盖当前代码和 I1 入口。
- 外部 source pack 路径、历史 Godot 路径和旧 branch 名只保留时间点含义。
