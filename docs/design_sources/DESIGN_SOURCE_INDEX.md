# Design Source Index

This index records G20-R3a text design source imports and G20-R3b external visual reference registration. It does not modify the imported source bodies.

## Imported Text Sources

| repo_path | original_base_docs_source | domain | status | control_stage | owner_system | engineering_role | implementation_permission | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `docs/design_sources/ui_flow/main_menu_design.md` | `D:\AGAME1\Base Docs\主菜单策划案.md` | ui_flow | imported_text_copy | G20-R3a | MainMenuShell / AppShell | design reference | requires separate implementation plan | Active cross-stage menu source; not a direct task list. |
| `docs/design_sources/ui_flow/G09_UI_INFORMATION_ARCHITECTURE.md` | `D:\AGAME1\Base Docs\UI修改策划案.txt` | ui_flow | imported_text_copy | G20-R3a | UI information architecture | historical design reference | requires separate implementation plan | Stage marker retained because the source aligns with G09-era UI IA. |
| `docs/design_sources/run_flow/deploy_prep_rules.md` | `D:\AGAME1\Base Docs\出发探索界面与出勤准备规则策划案.md` | run_flow | imported_text_copy | G20-R3a | DeployPrepShell / RunStartConfig | design reference | requires separate implementation plan | Active deploy-prep source; not proof that deploy rules are implemented. |
| `docs/design_sources/run_flow/G10_CORE_MODULE_ASSET_SETTLEMENT_RULES.md` | `D:\AGAME1\Base Docs\主模块修改策划案.txt` | run_flow | imported_text_copy | G20-R3a | core module / asset / settlement | historical design reference | requires separate implementation plan | Stage marker retained for G10-era core module planning. |
| `docs/design_sources/long_term/long_term_integration_asset_interface.md` | `D:\AGAME1\Base Docs\长期系统整合与资产接口规则策划案.md` | long_term | imported_text_copy | G20-R3a | LongTermShell / asset interface | design reference | requires separate implementation plan | Active long-term integration source; G19 remains foundation only. |
| `docs/design_sources/long_term/G18_LONG_TERM_UI_RULES_LEGACY.md` | `D:\AGAME1\Base Docs\长期系统界面与长期构筑规则策划案.md` | long_term | imported_text_copy | G20-R3a | long-term UI rules | legacy design reference | requires separate implementation plan | Marked LEGACY because source is historical relative to current LongTermShell foundation. |
| `docs/design_sources/asset_model/item_asset_model_mapping.md` | `D:\AGAME1\Base Docs\物品资产模型与内容映射规则策划案.md` | asset_model | imported_text_copy | G20-R3a | Item / asset model | design reference | requires separate implementation plan | Candidate input for future Asset Contract Foundation; G21 not started. |
| `docs/design_sources/settlement_history/run_report_history.md` | `D:\AGAME1\Base Docs\本局结算报告与历史战绩系统.md` | settlement_history | imported_text_copy | G20-R3a | settlement / history | design reference | requires separate implementation plan | Candidate input for future Settlement / History Snapshot Foundation. |
| `docs/design_sources/encounter_combat/combat_room_monster_rules.md` | `D:\AGAME1\Base Docs\战斗房与怪物遭遇通用规则策划案.md` | encounter_combat | imported_text_copy | G20-R3a | encounter / combat | design reference | requires separate implementation plan | Does not expand G15/G16 foundation by itself. |
| `docs/design_sources/architecture/G16_POST_ARCHITECTURE_DIRECTION_REFERENCE.md` | `D:\AGAME1\Base Docs\G16后工程架构评估与G17路线总结.md` | architecture | imported_text_copy | G20-R3a | architecture direction | reference | requires separate implementation plan | Historical direction source; current facts still come from repository status docs. |
| `docs/design_sources/architecture/godot_future_plan.md` | `D:\AGAME1\Base Docs\未来规划策划案.txt` | architecture | imported_text_copy | G20-R3a | future planning | design reference | requires separate implementation plan | Roadmap source only; does not start G21+. |
| `docs/design_sources/meta/feasibility_analysis.md` | `D:\AGAME1\Base Docs\可行性判断.md` | meta | imported_text_copy | G20-R3a | feasibility | reference | requires separate implementation plan | Feasibility reference; not current validation evidence. |
| `docs/design_sources/meta/difficulty_model_analysis.md` | `D:\AGAME1\Base Docs\难度判断.md` | meta | imported_text_copy | G20-R3a | difficulty model | reference | requires separate implementation plan | Difficulty reference; not current runtime validation. |

## External Visual References

These PNG files remain only in external Base Docs. They were not copied into the repository and must not be treated as imported assets.

| repo_path | original_base_docs_source | domain | status | control_stage | owner_system | engineering_role | implementation_permission | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `not_imported` | `D:\AGAME1\Base Docs\主菜单确定.png` | ui_flow | external_reference / pending_user_authorization | G20-R3b | MainMenuShell | visual reference | no implementation permission | PNG not imported; no `reference_images/` directory created. |
| `not_imported` | `D:\AGAME1\Base Docs\主菜单示例.png` | ui_flow | external_reference / pending_user_authorization | G20-R3b | MainMenuShell | visual reference | no implementation permission | PNG not imported; no `reference_images/` directory created. |
| `not_imported` | `D:\AGAME1\Base Docs\出发探索确定.png` | run_flow | external_reference / pending_user_authorization | G20-R3b | DeployPrepShell | visual reference | no implementation permission | PNG not imported; no `reference_images/` directory created. |
| `not_imported` | `D:\AGAME1\Base Docs\出发探索示例.png` | run_flow | external_reference / pending_user_authorization | G20-R3b | DeployPrepShell | visual reference | no implementation permission | PNG not imported; no `reference_images/` directory created. |
| `not_imported` | `D:\AGAME1\Base Docs\长期系统确定.png` | long_term | external_reference / pending_user_authorization | G20-R3b | LongTermShell | visual reference | no implementation permission | PNG not imported; no `reference_images/` directory created. |
| `not_imported` | `D:\AGAME1\Base Docs\长期系统示例.png` | long_term | external_reference / pending_user_authorization | G20-R3b | LongTermShell | visual reference | no implementation permission | PNG not imported; no `reference_images/` directory created. |
