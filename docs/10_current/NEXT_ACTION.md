# Next Action

文档状态：I2 active 执行入口；I2.0 已接受，运行时实现尚未声明。
最后更新：2026-07-22

## 当前状态

I1 已以 `CLOSED / PASS_WITH_NOTES` 收口，I2 已由用户明确授权为单一的玩家体验重构阶段。I2.0 已完成范围、风险、反馈追踪、架构、验证和切片门并通过独立 claim review；I2.1–I2.7 仍不因阶段激活自动获得写权限。

```text
I2 stage: ACTIVE
I2 current slice: I2.1A/I2.1B foundation and isolated I2.5A ready for implementation
I2 runtime implementation: NOT_STARTED / NOT_CLAIMED
entry head: b77132b9de655b36f71c930a35a191c383b55522
entry full/head: 39/39 PASS
```

## 立即下一步

1. 保持 I2.0 `ACCEPTED_WITH_NOTES / no runtime delta`；其 quick/worktree 21/21 PASS，不创建 validation/handoff，不提升 capability。
2. 按门账并行执行互不重叠的 I2.1A 状态/生命周期、I2.1B 设置/输入 foundation 与 I2.5A 既有资产接线；不得越过各自精确 allowed paths。
3. 主审统一登记新增 runner，并在定向测试、quick/ui 与交叉 claim review 后再开放 AppShell/Run 的设置/焦点集成门。

## 后续切片顺序

| 顺序 | 切片 | 进入前必须解决 |
| --- | --- | --- |
| 1 | I2.1 shared foundation | 设置字段、动画 proof、input/focus ownership、保护路径 |
| 2 | I2.2 main menu | 四入口转场状态/失败/reduced motion、锚点和素材复用 |
| 3 | I2.3 Deploy | 地图同页 no-regression、经济命令、任务 taxonomy、出勤配置落点 |
| 4 | I2.4 long-term | 任务档案迁移先于 Goal→天赋、天赋真实数据/效果权威 |
| 5 | I2.5 in-run presentation | room/object/ledger/map/modal characterization、proximity 不自动拾取 |
| 6 | I2.6 rooms/result/performance | 战斗离房规则、结算幂等、真实 1/3/5 敌人 workload 与阈值 |
| 7 | I2.7 integration/closeout | 反馈矩阵逐项处置、full/worktree→full/head、视觉/动态/输入/性能/来源综合证据 |

顺序可在风险审计后调整，但 I2.4 不能先改 Goal 名称再迁移真实任务，I2.3 不能把地图拆成新页面，I2.6 不能先声称性能改善再补 workload。

## 默认开发反馈

- 普通修改先 quick；程序权威/保存/战斗跑 core；UI/动画/路由跑 ui + production preview；切片 review 跑 full/worktree。
- UI 切片必须附 1280×720、1600×900、1920×1080 静态图和动态操作；键鼠、手柄/焦点、reduced motion、颜色冗余、长文本/本地化、生命周期/保存失败按相关性执行。
- 性能使用整帧、模拟、快照、表现、加载、分配和内存数据；combat refresh 微基准不能替代 FPS。
- 最终只在提交后 exact HEAD full 通过并完成综合证据审计时创建 I2 validation/handoff。

## 必须继承的事实

- Godot 是唯一实现目标；`E:\UE` 只读借鉴语义/交互/视觉概念，不移植架构、烤字布局或未知许可素材。
- Deploy 地图始终在同一页签：左地图名称与比例/规模，右难度与详情；保留 8 个现有 ID。
- `RunAssetLedger`、`RunStateMachine`、`RunRuntimeController`/meta adapter 和 `SaveAdapter` 权威不得绕开。
- 失败保全确认前不写局外，同一 `result_id` 不重复提交；UI/动画不拥有奖励和结算。
- 现有 Godot/UE/本地素材依次经 source/license/hash/manifest/import gate；确认不足后才允许批准的新生成。
- 主工作树的 `project.godot` 和七个 `asset_manifest.*.translation` 是外部受保护 dirty，不得吸收或清理。

## 当前不可声明

- 主菜单、Deploy、长期、局内或特殊房已经按用户反馈改善。
- 设置、骨骼/烘焙动画、时装替换、批量售卖或天赋树已经实现。
- 战斗房 FPS 已优化、最终视觉/音频已完成、人工长局已通过。
- I2 validation/handoff、capability promotion、commit/push/merge 或 release gate 已完成。

详细范围见 `docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md`；逐项反馈见 `docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md`；执行状态见 `docs/00_governance/I2_SLICE_GATE_LEDGER.md`。
