# Source Registry

> P2 更新：本文件保留为 G20 治理来源注册证据。P2 后当前来源总表见 `docs/00_governance/SOURCE_REGISTRY.md`。

This registry records active sources, imported design sources, external references, and planned governance artifacts. It is a governance index, not a replacement for the source files.

## Current Active Fact Sources

| path | lifecycle | status | owner | notes |
| --- | --- | --- | --- | --- |
| `docs/PROJECT_BASELINE.md` | current_status | active | project status | Primary engineering fact source. |
| `docs/ENGINEERING_STATUS.md` | current_status | active | project status | Broader engineering status and validation list. |
| `docs/NEXT_HANDOFF.md` | handoff | active | handoff | Minimum next-chat entry. |
| `docs/DOCS_INDEX.md` | project_governance | active | docs navigation | Navigation and historical index. |
| `docs/MILESTONES.md` | project_governance | active | milestone map | Historical G-number to formal milestone mapping. |
| `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` | current_status | active | Godot status | Godot-specific current status. |
| `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md` | validation | active | manual validation | Manual/static validation guidance. |
| `docs/route_analysis/ROADMAP_G20_PLUS.md` | route_analysis | active | route governance | Calibrated by G21-R5; next recommended planning is G18-align before G22. |
| `docs/route_analysis/SYSTEM_BOUNDARY_MAP.md` | route_analysis | active | boundary governance | Calibrated by G21-R5 for Deploy Prep / AssetEvent / Warehouse boundaries. |
| `docs/project_governance/DECISION_LOG.md` | project_governance | active | decision register | Includes G21-R5 design alignment decision. |
| `docs/project_governance/VALIDATION_STATUS_MATRIX.md` | project_governance | active | validation register | Includes G21 and G21-R5 validation rows. |

## G21-R5 Design Alignment Audit Status

- Base Docs 全量一致性审计已完成，未发现 P0。
- P1/P2 设计口径与 foundation 完成度问题已登记到 current status、handoff、route analysis、decision log、glossary 和 validation matrix。
- 外部 `D:\AGAME1\Base Docs` 原件未修改、未复制、未移动、未删除。
- G21-R5 不创建新设计源，不运行 Godot，不修改代码，不进入 G22。
- 当前下一阶段建议：先做 G18-align / 出发探索资产出勤视角 planning，再决定 G22。

## Imported Design Sources

| path | lifecycle | status | control_stage | source |
| --- | --- | --- | --- | --- |
| `docs/design_sources/ui_flow/main_menu_design.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\主菜单策划案.md` |
| `docs/design_sources/ui_flow/G09_UI_INFORMATION_ARCHITECTURE.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\UI修改策划案.txt` |
| `docs/design_sources/run_flow/deploy_prep_rules.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划案.md` |
| `docs/design_sources/run_flow/G10_CORE_MODULE_ASSET_SETTLEMENT_RULES.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\主模块修改策划案.txt` |
| `docs/design_sources/long_term/long_term_integration_asset_interface.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\长期系统整合与资产接口规则策划案.md` |
| `docs/design_sources/long_term/G18_LONG_TERM_UI_RULES_LEGACY.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\长期系统界面与长期构筑规则策划案.md` |
| `docs/design_sources/asset_model/item_asset_model_mapping.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\物品资产模型与内容映射规则策划案.md` |
| `docs/design_sources/settlement_history/run_report_history.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\本局结算报告与历史战绩系统.md` |
| `docs/design_sources/encounter_combat/combat_room_monster_rules.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\战斗房与怪物遭遇通用规则策划案.md` |
| `docs/design_sources/architecture/G16_POST_ARCHITECTURE_DIRECTION_REFERENCE.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\G16后工程架构评估与G17路线总结.md` |
| `docs/design_sources/architecture/godot_future_plan.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\未来规划策划案.txt` |
| `docs/design_sources/meta/feasibility_analysis.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\可行性判断.md` |
| `docs/design_sources/meta/difficulty_model_analysis.md` | source_design | imported_text_copy | G20-R3a | `D:\AGAME1\Base Docs\难度判断.md` |

## External Visual References

| repo_path | lifecycle | status | control_stage | external_source |
| --- | --- | --- | --- | --- |
| `not_imported` | source_design | external_reference / pending_user_authorization | G20-R3b | `D:\AGAME1\Base Docs\主菜单确定.png` |
| `not_imported` | source_design | external_reference / pending_user_authorization | G20-R3b | `D:\AGAME1\Base Docs\主菜单示例.png` |
| `not_imported` | source_design | external_reference / pending_user_authorization | G20-R3b | `D:\AGAME1\Base Docs\出发探索确定.png` |
| `not_imported` | source_design | external_reference / pending_user_authorization | G20-R3b | `D:\AGAME1\Base Docs\出发探索示例.png` |
| `not_imported` | source_design | external_reference / pending_user_authorization | G20-R3b | `D:\AGAME1\Base Docs\长期系统确定.png` |
| `not_imported` | source_design | external_reference / pending_user_authorization | G20-R3b | `D:\AGAME1\Base Docs\长期系统示例.png` |

## Planned Governance Artifacts

| planned_path | lifecycle | planned_batch | status |
| --- | --- | --- | --- |
| `docs/stage_summaries/STAGE_SUMMARY_INDEX.md` | stage_summary | G20-R3c | planned |
| `docs/route_analysis/ROUTE_ANALYSIS_G10_TO_G19.md` | route_analysis | G20-R3c | planned |
| `docs/project_governance/BRANCH_INVENTORY.md` | project_governance | G20-R3d | planned |
| `docs/project_governance/COMMIT_MILESTONE_MAP.md` | project_governance | G20-R3d | planned |
| `docs/project_governance/VALIDATION_STATUS_MATRIX.md` | project_governance | G20-R3d | planned |
| `docs/project_governance/TEMP_AND_DEPRECATED_INVENTORY.md` | project_governance | G20-R3d2 | active / added in G20-R3d2 |
| `docs/project_governance/DECISION_LOG.md` | project_governance | G20-R3d2 | active / added in G20-R3d2 |
| `docs/project_governance/GLOSSARY.md` | project_governance | G20-R3d2 | active / added in G20-R3d2 |
