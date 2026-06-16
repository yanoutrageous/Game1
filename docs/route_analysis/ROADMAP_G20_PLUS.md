# G20+ 路线建议

## 声明

这是 G20 的路线建议。G21 后续已独立启动、完成 R3/R4 validation，并 fast-forward 合并到 main。G21-R5 又完成 docs-only 设计一致性校准：G22 不应直接按旧 Warehouse / Asset Page Shell 口径启动；G22、G23、G24、G25 仍需独立审计、计划、执行、验收和合并。

G20 是 docs-only knowledge governance，不实现 Asset Contract、Warehouse、Settlement、Objective、Gacha 或 gameplay，不运行 Godot。

## 建议路线

| 阶段 | 建议名称 | 建议目标 | 启动状态 |
| --- | --- | --- | --- |
| G20 | 项目知识治理与设计资料入库 | design source 文本入库、project governance、stage summaries、route analysis、system boundary/dependency maps | 已完成并 fast-forward 合并 main |
| G21 | Asset Contract Foundation | 建立资产/物品/奖励/标签/策略的最小 public contract，与现有 ledger 和 future long-term shell 对齐 | R3 complete at `29a68e7b093ae653be212e32eb97042c0a7c0a4c`; R4 Godot headless project-load/parser smoke PASS; R4B / first main commit `fdadd78ccdf1d61378ac93a74cfe26449e47c411`; merged main |
| G18-align | Deploy Prep Asset Attendance Alignment | 校准出发探索资产出勤视角、二级标签、卡片详情、深层跳转、开始/继续/放弃强确认口径 | 建议作为 G22 前置；未启动 |
| G22 | Deploy Prep Full Module Alignment / Warehouse later | G18-align 后再决定是否进入仓库/资产页 shell；不得直接实现完整仓库或长期系统扩展 | 未启动 |
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

## G21 执行状态

- G21-R3 已完成 Asset & Item Flow Contract Foundation，只做 schema / constants / default / normalize / validate / projection schema。
- G21-R4 已通过 Godot headless project-load/parser smoke PASS，且 smoke 后工作区 clean、无 dirty 副作用。
- G21 已 fast-forward 合并 main，main 首次包含 G21 的提交为 `fdadd78ccdf1d61378ac93a74cfe26449e47c411`。
- G21-R5 已完成设计一致性校准：Base Docs 全量一致性审计未发现 P0，但存在 P1/P2 设计口径与 foundation 完成度问题。
- G22 尚未启动。
- G21 不代表真实资产系统、仓库、事件总线、发奖、存档、抽奖、结算、历史战绩、红点或 Policy / Tag 规则引擎已实现。

## G21-R5 路线校准

- 出发探索仍是 foundation，不能误称为完整模块内容。
- 结算报告 / 历史战绩仍缺快照系统。
- 主菜单存在 warehouse 快捷入口口径风险；G17 主菜单仍是 foundation / 部分符合。
- G21 AssetEvent action 口径在代码中保持最小，文档层补充后续动作词：获得、消耗、丢失、转化、出售、入仓、清空、抢救、装备、卸下、加入出勤、移出出勤、解锁、完成、记录。
- 旧长期七模块结构为历史参考，已被长期系统整合案覆盖；当前长期系统按六模块：目标 / 图鉴 / 研究 / 个人资历 / 抽奖 / 收藏外观。
- 旧“天赋”页签或旧 UI 页签表述为历史参考；出发探索当前按：地图 / 仓库 / 申领 / 出勤配置 / 作业许可。
- 旧 G21/G22 排序为历史参考；当前以 G20+ roadmap 与本一致性校准后的路线为准。
- G22 前应先做 G18-align：出发探索资产出勤视角、二级标签、卡片详情、深层跳转、开始/继续/放弃强确认口径。
- 不得直接进入完整仓库、长期系统扩展、抽奖、奖励领取、结算历史实现。

## 禁止误读

- G20 不代表 Asset Contract 已启动；G21 是后续独立分支阶段。
- G21-R4 smoke PASS 不代表 complete gameplay runtime PASS 或 manual playtest PASS。
- G18 DeployPrepShell 不代表真实 Warehouse 或 Deploy persistence。
- G18-align 不代表真实仓库、真实出发消耗、真实结算历史或 RunScene 启动。
- G19 LongTermShell 不代表真实长期系统、资产系统、MetaProgress 或 gacha。
- 任何 `Godot headless project-load/parser smoke PASS` 都不能写成 complete gameplay runtime PASS 或 manual playtest PASS。
## G18-align-R4B Closeout Update

G18-align-R2 is complete at `55a048e7419a890cc899bdbd7fae4db4431ddacf`, and G18-align-R3 acceptance passed with Godot headless project-load/parser smoke PASS. This validates only the pre-G22 deploy prep alignment slice: asset attendance view, right-side summary, and start / continue / abandon strong-confirmation preview. It does not start G22 and does not implement complete deploy prep, complete warehouse, real asset writes, event bus, reward grant, persistence, or real RunScene start / continue / abandon logic.

## G18-align-R2 Execution Update

G18-align-R2 is now the active pre-G22 implementation slice on `godot/g18-align-deploy-prep-asset-view`. It narrows the next route to Deploy Prep asset attendance view alignment: secondary labels, card details, right-side summary, and start/continue/abandon strong-confirmation preview. It does not start G22 and does not implement complete warehouse, real asset writing, event bus, reward claim, persistence, or real exploration execution.
## G18-align Final Main Merge Calibration

- G18-align has been fast-forward merged to `main`.
- First `main` commit containing G18-align: `70d3735a3ed49dec31ce5a6de73cfdf0829885eb`.
- G18-align-R2 implementation commit: `55a048e7419a890cc899bdbd7fae4db4431ddacf`.
- G18-align-R4B closeout commit: `70d3735a3ed49dec31ce5a6de73cfdf0829885eb`.
- G18-align-R3 recorded Godot headless project-load/parser smoke PASS only.
- This is not gameplay runtime PASS and not manual playtest PASS.
- G22 remains not started; do not infer G22 start from this merge.
- The next step remains closeout / new-conversation handoff unless a later user instruction starts a new stage.
