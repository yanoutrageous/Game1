# DOC-GOV-001 Source Registry

文档状态：当前来源注册表
适用范围：仓库文档入口、外部来源、历史快照和证据归属
最后更新：2026/06/26

本文件是 DOC-GOV-001 的来源总表，不替代原始文件、验证记录或用户确认。

## 1. 当前入口

| 路径 | 状态 | 用途 |
| --- | --- | --- |
| `docs/INDEX.md` | current_entry | P2 后统一入口 |
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

## 2. 旧入口与扩展证据

| 路径 | P2 状态 | 说明 |
| --- | --- | --- |
| `docs/PROJECT_BASELINE.md` | expanded_evidence / pre_p2_current_status | 保留历史与扩展事实正文；P2 后不作为第一入口 |
| `docs/ENGINEERING_STATUS.md` | expanded_evidence / pre_p2_engineering_status | 保留工程状态正文；P2 后由 `10_current` 汇总 |
| `docs/NEXT_HANDOFF.md` | expanded_evidence / pre_p2_handoff | 保留历史 handoff；P2 后第一下一步见 `10_current/NEXT_ACTION.md` |
| `docs/DOCS_INDEX.md` | expanded_evidence / historical_navigation | 保留旧导航；P2 后入口见 `INDEX.md` |
| `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` | read_only_engineering_evidence | 只读证据；P2 不修改 Godot docs |

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
| `docs/project_governance/` | legacy_governance_evidence | G20 治理材料；P2 新治理入口在 `00_governance/` |

## 5. DOC-GOV-001 去重边界

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
