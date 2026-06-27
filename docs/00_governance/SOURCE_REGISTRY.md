# DOC-GOV-002 Source Registry

文档状态：当前来源注册表
适用范围：仓库文档入口、外部来源、历史快照和证据归属
最后更新：2026/06/27

本文件是 DOC-GOV-002 后的来源总表，不替代原始文件、验证记录或用户确认。

## 1. 当前入口

| 路径 | 状态 | 用途 |
| --- | --- | --- |
| `docs/INDEX.md` | current_entry | DOC-GOV-002 后统一入口 |
| `docs/README.md` | current_entry | 仓库 docs 第一阅读入口和写入边界 |
| `docs/10_current/CURRENT_STATE.md` | current_state | 当前事实摘要 |
| `docs/10_current/NEXT_ACTION.md` | current_next_action | 下一步与阶段闸门 |
| `docs/10_current/CAPABILITY_MATRIX.yaml` | current_matrix | 能力状态矩阵 |
| `docs/20_product/PRODUCT_CONTRACT.md` | draft_contract | 产品契约草案 / 待确认 |
| `docs/00_governance/DOC_PLACEMENT_STANDARD.md` | governance_rule | 新文档落位、阶段完成文档和禁止写入规则 |
| `docs/00_governance/DUPLICATE_DOC_LEDGER.md` | governance_ledger | 重复文档组状态台账 |
| `docs/00_governance/P2_EXECUTION_REPORT.md` | execution_report | P2 执行报告与自检结果 |
| `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md` | current_source_boundary | Base Docs 归档与 Connection 并行交接的当前只读边界 |
| `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY_UPDATE_REPORT.md` | execution_report | 2026/06/23 外部来源边界校准与自检记录 |
| `docs/00_governance/DOC_GOV_002_EXECUTION_REPORT.md` | execution_report | DOC-GOV-002 执行报告与自检结果 |
| `docs/40_validation/VALIDATION_INDEX.md` | current_validation_index | 验证记录索引，只说明验证范围 |
| `docs/50_stages/active/STAGE_INDEX.md` | current_active_stage_index | 当前 active / pending 阶段索引 |
| `docs/50_stages/closed/STAGE_INDEX.md` | current_closed_stage_index | closed / historical 阶段索引 |

## 2. 旧入口与扩展证据

| 路径 | 当前状态 | 说明 |
| --- | --- | --- |
| `docs/PROJECT_BASELINE.md` | expanded_evidence / historical_status | 保留历史与扩展事实正文；DOC-GOV-002 后不作为第一入口 |
| `docs/ENGINEERING_STATUS.md` | expanded_evidence / historical_status | 保留工程状态正文；当前由 `10_current` 汇总 |
| `docs/NEXT_HANDOFF.md` | expanded_evidence / historical_handoff | 保留历史 handoff；当前第一下一步见 `10_current/NEXT_ACTION.md` |
| `docs/DOCS_INDEX.md` | expanded_evidence / historical_navigation | 保留旧导航；当前入口见 `INDEX.md` |
| `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` | read_only_engineering_evidence | 只读证据；当前文档治理不修改 Godot docs |

## 3. 外部来源与注册表

| 来源 | 仓库登记路径 | 状态 | 边界 |
| --- | --- | --- | --- |
| `D:\AGAME1\Base Docs` | `docs/70_sources/base_docs/BASE_DOCS_SOURCE_REGISTRY.md` | external_live_reference | 当前归档后的外部只读策划来源；旧文件名不保证仍是唯一有效路径 |
| `D:\AGAME1\Base Docs_Governance` | `docs/00_governance/DUPLICATE_DOC_LEDGER.md` | external_governance_snapshot | Base Docs 非破坏式整理副本区 / 索引区 / 历史快照区；不替代当前仓库事实源 |
| `D:\AGAME1\Base Docs` UI 图片 | `docs/70_sources/ui_reference/UI_REFERENCE_REGISTRY.md` | external_ui_reference | 图片不作为规则权威；既有仓库图片是此前获授权的冻结历史快照 |
| `D:\AGAME1\Connection` | `docs/60_interfaces/connection/CONNECTION_SOURCE_REGISTRY.md` | external_parallel_handoff | 只登记路径与观测哈希；内容不进入 Git，不导入 Godot |
| `Godot/GraytailGodot/docs` | `docs/30_engineering/godot/GODOT_DOCS_REGISTRY.md` | read_only_registered | 不复制、不修改 Godot docs |

Base Docs 既有 `docs/design_sources/` 和 `docs/70_sources/` 副本只保留此前阶段的历史证据价值，不自动同步，不替代当前外部归档。Connection 内容镜像不保留在仓库。

## 4. 既有证据目录

| 目录 | 状态 | 说明 |
| --- | --- | --- |
| `docs/design_sources/` | imported_design_sources | G20 导入文本设计源，仍是设计参考 |
| `docs/handoff/` | stage_evidence | 阶段 handoff，保留证据价值 |
| `docs/validation/` | validation_evidence | 验证记录，只证明其明确验证范围 |
| `docs/stage_summaries/` | stage_summary_evidence | 阶段摘要 |
| `docs/route_analysis/` | route_governance | 路线与依赖分析 |
| `docs/project_governance/` | legacy_governance_evidence | G20 治理材料；当前治理入口在 `00_governance/` |

## 5. DOC-GOV-002 去重边界

| 重复关系 | 当前权威 / 入口 | 非权威但保留 |
| --- | --- | --- |
| 当前入口重复 | `docs/README.md`、`docs/INDEX.md`、`docs/10_current/*` | `docs/DOCS_INDEX.md`、`docs/PROJECT_BASELINE.md`、`docs/ENGINEERING_STATUS.md`、`docs/NEXT_HANDOFF.md` |
| 治理目录重复 | `docs/00_governance/**` | `docs/project_governance/**` |
| 仓库 docs 与外部快照重复 | `Game1_work/docs` | `Base Docs_Governance/06_工程仓库docs参考/docs` |
| Godot docs 与仓库 docs 重复 | `Game1_work/docs` | `Godot/GraytailGodot/docs` |
| 产品来源重复 | `docs/20_product/**` 作为仓库契约；`D:\AGAME1\Base Docs` 作为外部原件 | `docs/design_sources/**` 历史导入参考 |

## 6. 禁止反推

```text
1. 不从 UI 图片反推规则。
2. 不从工程临时实现反推策划定案。
3. 不把外部来源、历史导入或冻结快照写成最终玩法。
4. 不把 foundation / preview / display-only 写成完整系统。
5. 不把 Connection 交接资料写成已授权任务或验收结论。
6. 不因旧文件路径变化而回滚、清理或重建 Base Docs。
```

## 7. DOC-GOV-002 根目录旧文件来源登记

本表只登记来源归属，不要求移动、删除、重命名或改写旧文件。当前第一入口仍是 `docs/README.md`、`docs/INDEX.md`、`docs/10_current/*` 和 `docs/00_governance/*`。

| 文件 / 文件组 | 来源状态 | 当前使用方式 |
| --- | --- | --- |
| `CODEX_TASKS.md` | deprecated_reference | 旧任务参考，不作为当前任务入口 |
| `design-integration-delta.md` | legacy_integration | early integration delta 历史证据 |
| `design-integration-plan.md` | legacy_integration | early integration plan 历史证据 |
| `dev-plan.md` | legacy_design | 旧开发计划参考 |
| `DOCS_INDEX.md` | deprecated_reference | 旧导航，当前入口见 `docs/INDEX.md` |
| `ENGINEERING_STATUS.md` | historical_status | 旧工程状态扩展正文 |
| `game-design.md` | legacy_design | 旧设计参考 |
| `GAMEPLAY_LOGIC_MVP_STATUS.md` | historical_status | 旧 MVP 状态记录，不扩大为当前 gameplay runtime PASS |
| `HANDOFF_TWO_PC*.md` | historical_handoff | 旧 two-PC handoff 证据组 |
| `integration-self-check.md` | legacy_integration | early integration self-check |
| `LUA_BASELINE_STATUS.md` | legacy_lua | Lua baseline 历史证据 |
| `MILESTONES.md` | historical_status | 旧里程碑记录 |
| `NEXT_HANDOFF.md` | historical_handoff | 旧下一步 / handoff 聚合 |
| `PROJECT_BASELINE.md` | historical_status | 旧扩展基线 |
| `REFACTOR_ARCHITECTURE.md` | deprecated_reference | 旧重构架构参考 |
| `REPO_POLICY.md` | historical_status | 旧仓库策略参考 |
| `UE_FOUNDATION_STATUS.md` | legacy_ue | UE 旧路线历史证据 |
| `UE_REFACTOR_IMPLEMENTATION.md` | legacy_ue | UE 旧重构历史证据 |
| `ui-layout-implementation-plan.md` | legacy_design | 旧 UI layout 实施参考 |
| `v0.3-progress-assessment.md` | needs_archive_decision | 历史报告，未来可评估归档 |
| `v03-balance-port-self-check.md` | needs_archive_decision | 历史报告，未来可评估归档 |

## 8. DOC-GOV-002 归档候选来源说明

归档候选不是删除建议，也不是立即移动建议。归档前必须另起阶段、另行审计、明确目标路径和回滚方式。

```text
UE 旧路线：legacy_ue。
Lua 旧审计：legacy_lua。
early integration plan：legacy_integration。
old two-PC handoff：historical_handoff。
v0.3 / v03 报告：needs_archive_decision。
旧 root design/dev 文件：legacy_design。
```

## 9. DOC-GOV-002 命名与中文摘要来源规则

当前仓库事实入口以中文说明优先；历史英文文档不强制全文翻译。新建或后续更新的当前 contract / validation / handoff 至少应提供中文摘要，旧文档如继续被当前索引引用，应至少有中文状态说明。

```text
Gxx_主题_CONTRACT.md
Gxx_主题_VALIDATION.md
HANDOFF_Gxx_主题.md
ARTxx_主题.md
DOC_GOV_xxx_主题.md
README.md
*_INDEX.md
*_REGISTRY.md
```

旧文件不强制重命名；归档候选不得移动、不得删除，不能作为本轮执行授权。
# M2 Latest Planning Source Registration

| source_id | source_type | external_path | usage |
| --- | --- | --- | --- |
| M2-SRC-RUN-MAP | Base Docs external planning original | `D:\AGAME1\Base Docs\局内地图本体与生成规则策划案.md` | M2 map / KnownMap / return eligibility source reference only |
| M2-SRC-RUN-FLOW | Base Docs external planning original | `D:\AGAME1\Base Docs\局内流程与状态流转规则策划案.md` | M2 run loop / RunResult / settlement handoff source reference only |
| M2-SRC-ROOM | Base Docs external planning original | `D:\AGAME1\Base Docs\房间类型、标签与遭遇通用规则策划案.md` | M2 room feedback / encounter source reference only |
| M2-SRC-RULE | Base Docs external planning original | `D:\AGAME1\Base Docs\规则、效果、Modifier 与内容投放通用系统策划案.md` | M2 limited modifier source reference only |
| M2-SRC-DEPLOY | Base Docs external planning original | `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划修正案.md` | M2 DeployPrep five-tab and RunStartConfig source reference only |
