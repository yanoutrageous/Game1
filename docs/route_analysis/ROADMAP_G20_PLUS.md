# G20+ 路线建议

## 声明

这是 G20 的路线建议，不代表 G21+ 已启动。G21、G22、G23、G24、G25 仍需独立审计、计划、执行、验收和合并。

G20 是 docs-only knowledge governance，不实现 Asset Contract、Warehouse、Settlement、Objective、Gacha 或 gameplay，不运行 Godot。

## 建议路线

| 阶段 | 建议名称 | 建议目标 | 启动状态 |
| --- | --- | --- | --- |
| G20 | 项目知识治理与设计资料入库 | design source 文本入库、project governance、stage summaries、route analysis、system boundary/dependency maps | 已在 G20 分支执行 R3a/R3b/R3c；尚未合并 main |
| G21 | Asset Contract Foundation | 建立资产/物品/奖励/标签/策略的最小 public contract，与现有 ledger 和 future long-term shell 对齐 | 未启动 |
| G22 | Warehouse / Asset Page Shell Foundation | 建立仓库与资产页 shell，消费 Asset Contract public snapshot，不做完整经济 | 未启动 |
| G23 | Settlement / History Snapshot Foundation | 建立结算结果与历史快照 foundation，连接 run result summary 与长期展示 | 未启动 |
| G24 | Objective / Reward Event Contract | 建立目标、奖励事件、claimable/reward bundle 合同，不做完整任务系统 | 未启动 |
| G25 | Gacha / Unique Collectible Preview Foundation | 建立抽奖与唯一藏品 preview foundation，不做真实概率、保底、消耗或持久化 | 未启动 |

## 阶段门禁

每个后续阶段都必须独立完成：

- 审计：确认前置事实、代码边界、文档边界和安全边界。
- 计划：明确目标、非目标、文件范围、验证范围。
- 执行：只实现该阶段授权切片。
- 验收：区分 static validation、parser smoke、gameplay runtime PASS、manual playtest PASS。
- 合并：单独记录 branch/head/main/remote 状态。

## G21 前置条件建议

- R3d 完成后，先确认完整分支库存、提交矩阵、验证矩阵和临时/过期文件清单。
- 明确 Asset Contract 与 G8 ledger、G15/G16 encounter/combat、G18 DeployPrepShell、G19 LongTermShell 的读写边界。
- 明确哪些设计源来自 `docs/design_sources/`，哪些仍是 future reference。

## 禁止误读

- G20 不代表 Asset Contract 已启动。
- G21 未启动。
- G18 DeployPrepShell 不代表真实 Warehouse 或 Deploy persistence。
- G19 LongTermShell 不代表真实长期系统、资产系统、MetaProgress 或 gacha。
- 任何 `Godot headless project-load/parser smoke PASS` 都不能写成 complete gameplay runtime PASS 或 manual playtest PASS。
