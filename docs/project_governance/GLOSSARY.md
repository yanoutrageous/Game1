# 术语表

本文件是 G20-R3d2 新增的项目治理术语表。它解释当前文档中反复出现的 shell、foundation、preview、contract、snapshot、source of truth、design source、validation status 等术语，避免把路线建议、设计源或轻量 smoke 误读成已实现系统。

| term | definition | scope | not_meaning | related_files |
| --- | --- | --- | --- | --- |
| Shell | 顶层或模块级 UI / 路由容器，用来承载页面、placeholder、preview、disabled state 或后续模块入口。 | G17 AppShell、G18 DeployPrepShell、G19 LongTermShell。 | 不等于完整业务系统，不等于已接入真实数据、持久化或完整玩法。 | `docs/stage_summaries/G17_SUMMARY.md`; `docs/stage_summaries/G18_SUMMARY.md`; `docs/stage_summaries/G19_SUMMARY.md` |
| Foundation | 阶段性基础切片，建立最小接口、页面位置、数据形状或验证边界。 | G10-G19 各 foundation 阶段。 | 不等于完整系统，不等于最终 UI，不等于完整 gameplay。 | `docs/stage_summaries/STAGE_SUMMARY_INDEX.md`; `docs/route_analysis/ROUTE_ANALYSIS_G10_TO_G19.md` |
| Preview | 只读或 display-only 的展示数据，用来说明未来信息结构或输出形状。 | DeployConfig preview、RunStartConfig preview、LongTerm interface preview、reward preview。 | 不等于真实执行，不等于资源消耗，不等于持久化写入。 | `docs/stage_summaries/G18_SUMMARY.md`; `docs/stage_summaries/G19_SUMMARY.md` |
| Contract | 模块之间稳定的公开数据/命令边界。 | EncounterContract、DeployConfig、RunStartConfig、G21 Asset Contract。 | 不等于完整实现，不等于私有状态暴露。 | `docs/stage_summaries/G15_SUMMARY.md`; `docs/validation/G21_ASSET_ITEM_FLOW_CONTRACT_VALIDATION.md` |
| Snapshot | 某一时刻的公开只读状态视图。 | RunContext status snapshot、RunQueryFacade snapshots、LongTermSnapshot 建议。 | 不等于状态 owner，不等于可写接口，不等于真实存档。 | `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`; `docs/project_governance/VALIDATION_STATUS_MATRIX.md` |
| Source of Truth | 当前事实判断的优先来源。 | 当前状态、handoff、validation、governance 文件之间的优先级。 | 不等于所有历史文档都同等有效。 | `docs/project_governance/SOURCE_OF_TRUTH_POLICY.md`; `docs/project_governance/SOURCE_REGISTRY.md` |
| Base Docs | 用户外部设计原件目录 `D:\AGAME1\Base Docs`。 | 外部原件引用和 G20-R3a 文本设计源来源。 | 不等于本轮可修改路径，不等于仓库内实现清单。 | `docs/project_governance/SOURCE_REGISTRY.md`; `docs/design_sources/DESIGN_SOURCE_INDEX.md` |
| Design Source | 设计依据或设计源副本。 | `docs/design_sources/**` 中的 G20-R3a imported_text_copy。 | 不等于代码实现清单，不等于功能已完成证明。 | `docs/design_sources/README.md`; `docs/design_sources/DESIGN_SOURCE_INDEX.md` |
| Active Source | 当前仍应优先阅读的事实源或导航源。 | `PROJECT_BASELINE`、`NEXT_HANDOFF`、`ENGINEERING_STATUS`、`GODOT_CURRENT_STATUS` 等。 | 不等于历史资料自动失效，也不等于路线建议已启动。 | `docs/project_governance/SOURCE_REGISTRY.md`; `docs/DOCS_INDEX.md` |
| Historical Reference | 仍可追溯但不是当前事实源的历史文档。 | 旧 handoff、旧 branch_change、旧 audit、早期 UE/Lua/G5-G9 文档。 | 不等于可以删除，不等于当前实现状态。 | `docs/project_governance/TEMP_AND_DEPRECATED_INVENTORY.md` |
| Deprecated | 相对当前事实源或阶段命名已经过时的文档、术语或路径。 | 旧命名、旧路线、旧阶段报告候选。 | 不等于已授权删除，不等于文件内容全错。 | `docs/project_governance/DOCUMENT_LIFECYCLE.md`; `docs/project_governance/TEMP_AND_DEPRECATED_INVENTORY.md` |
| Temporary | 临时生成、临时交接或阶段性中间物。 | early handoff、two pc handoff、临时计划/评估候选。 | 不等于可以清理；G20-R3d2 只登记。 | `docs/project_governance/TEMP_AND_DEPRECATED_INVENTORY.md` |
| Needs Review | 用途、有效性或归档位置尚不能从当前事实源确认。 | 无法确认当前用途的旧文档或候选。 | 不等于错误，不等于删除许可。 | `docs/project_governance/TEMP_AND_DEPRECATED_INVENTORY.md` |
| Asset | 资产系统中的广义资源、货币、物品、外观、奖励或可追踪内容。 | G8 asset ledger、future Asset Contract。 | 不等于 Godot 导入资源文件本身，不等于本轮修改资源。 | `docs/design_sources/asset_model/item_asset_model_mapping.md`; `docs/route_analysis/ROADMAP_G20_PLUS.md` |
| Item | 可被定义、实例化、堆叠、入包、掉落、结算或入仓的物品概念。 | G8 ledger、future item/asset model。 | 不等于当前所有 UI 都已支持完整物品经济。 | `docs/design_sources/asset_model/item_asset_model_mapping.md`; `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` |
| ItemDefinition | 物品定义层，描述稳定 id、分类、展示、规则和基础属性。 | G21 Asset Contract / item model schema。 | 不等于单个玩家持有物，不等于运行时实例，不等于真实物品内容表。 | `docs/design_sources/asset_model/item_asset_model_mapping.md`; `docs/validation/G21_ASSET_ITEM_FLOW_CONTRACT_VALIDATION.md` |
| ItemInstance | 物品实例层，描述一次掉落、持有或结算中的具体实例状态。 | G8 item instance reference / G21 Asset Contract schema。 | 不等于静态定义，不等于堆叠总量，不等于已持久化玩家物品。 | `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`; `docs/validation/G21_ASSET_ITEM_FLOW_CONTRACT_VALIDATION.md` |
| ItemStack | 同类物品按数量聚合后的显示或存储形态。 | G21 Asset Contract schema、future warehouse、inventory、reward display。 | 不等于所有物品都能无损合并，不等于实例状态消失，不等于真实仓库实现。 | `docs/design_sources/asset_model/item_asset_model_mapping.md`; `docs/handoff/HANDOFF_G21_ASSET_ITEM_FLOW_CONTRACT.md` |
| AssetEvent | 资产变化事件，记录获得、消耗、转换、入仓、丢失、补偿等事实。 | G21 Asset Contract schema / future Settlement / History。 | 不等于 UI 提示文本，不等于直接修改状态的许可，不等于事件总线已实现。 | `docs/validation/G21_ASSET_ITEM_FLOW_CONTRACT_VALIDATION.md`; `docs/route_analysis/SYSTEM_BOUNDARY_MAP.md` |
| RewardBundle | 奖励包，聚合货币、物品、经验、解锁、标签或后续事件。 | future Objective / Settlement / LongTerm systems。 | 不等于已实现奖励系统，不等于真实发奖执行。 | `docs/route_analysis/ROADMAP_G20_PLUS.md`; `docs/design_sources/long_term/long_term_integration_asset_interface.md` |
| Policy | 可配置规则策略，用来描述限制、掉落、结算、可见性、出售、保底等规则。 | future Asset Contract、Warehouse、Gacha、LongTerm。 | 不等于当前代码已经有完整策略引擎。 | `docs/design_sources/asset_model/item_asset_model_mapping.md`; `docs/route_analysis/SYSTEM_BOUNDARY_MAP.md` |
| Tag | 语义标签，用来给物品、遭遇、奖励、目标或模块提供分类与过滤依据。 | future content definition / asset model。 | 不等于 UI 文案，不等于唯一规则来源。 | `docs/design_sources/asset_model/item_asset_model_mapping.md`; `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` |
| MetaProgress | 局外长期进度、账号/档案成长、持久化资源和解锁状态的统称。 | future long-term systems / persistence。 | 不等于 G19 LongTermShell；G19 只是 foundation / preview。 | `docs/stage_summaries/G19_SUMMARY.md`; `docs/PROJECT_BASELINE.md` |
| Godot parser smoke PASS | Godot headless project-load/parser smoke 通过，说明项目加载和脚本解析层面通过该次检查。 | G16 final、G17-R3、G18-R4、G19-R4B、G21-R4 等已有记录。 | 不等于 manual playtest PASS；不等于 full gameplay runtime PASS；不等于全部交互路线已人工验证。 | `docs/project_governance/VALIDATION_STATUS_MATRIX.md`; `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md` |
| Manual Playtest PASS | 人工按手册实际运行并完成指定路线后的通过结论。 | 需要单独记录实际测试范围、日期、路线和结果。 | 不等于 parser smoke PASS；不能从静态检查自动得出。 | `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`; `docs/project_governance/VALIDATION_STATUS_MATRIX.md` |
| Full gameplay runtime PASS | 完整或指定范围 gameplay runtime 路线实际运行通过的结论。 | 只有明确授权、明确路线和明确记录后才能声明。 | 不等于 Godot parser smoke PASS；不等于 manual checklist 存在；G20 docs-only 不声明该状态。 | `docs/project_governance/VALIDATION_STATUS_MATRIX.md`; `docs/validation/G19_LONG_TERM_SHELL_FOUNDATION_VALIDATION.md` |
