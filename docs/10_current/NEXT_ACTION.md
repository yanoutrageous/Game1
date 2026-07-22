# Next Action

文档状态：I2 关闭后的下一步入口；无后续阶段自动授权。
最后更新：2026-07-22

## 当前状态

I1 是前序闭合非美术基线；I2 已以 `CLOSED / PASS_WITH_NOTES` 成为最新闭合非美术基线。ART21 仍是项目级最新闭合美术阶段。I2 的内部切片已经结束，不构成后续工作的隐含写权限。

```text
latest closed non-art baseline: I2 / CLOSED / PASS_WITH_NOTES
latest closed art stage: ART21
active successor stage: NONE
I2 closeout records: validation/handoff are the exact evidence source
```

## 立即下一步

1. 在新工作开始前阅读 I2 validation/handoff、反馈矩阵和 I2 gate ledger；把 I2 已验证范围与九项延期明确分开。
2. 若要处理延期项，先建立新的范围/产品决策/资产或性能门，不以 I2 的关闭状态取得写权限。
3. 若只做局部增量，沿用 I1 profiles、生产 preview、权威/保存/结算不变量与受保护路径规则；将新的用户体验声明与可复核证据一同提交。

## 已延期项目的重新开启门

| 项目 | 重新开启前提 |
| --- | --- | --- |
| 最终角色动画/时装与移动手感 | 获批素材/动画方案、替换夹具、reduced-motion、动态人工与性能门 |
| 空间叙事转场与跨页最终视觉 | 交互原型、导航失败回退、动态可见验收、资产方向批准 |
| 批量出售 | 价格/确认/原子性/幂等/保存失败回滚产品与工程契约 |
| 真实天赋树 | 点数、成本、依赖、效果、重置/返还和持久化权威 |
| 战斗房绝对性能 | 同机设备/GPU/长时 workload 与玩家可见掉帧验收 |
| 整合 UX/长局 | 跨页面键鼠/手柄、长文本/DPI、动态人工游玩与多终局回归 |

## 必须继承的事实

- Godot 是唯一实现目标；`E:\UE` 只读借鉴语义/交互/视觉概念，不移植架构、烤字布局或未知许可素材。
- Deploy 地图始终在同一页签：左地图名称与比例/规模，右难度与详情；保留 8 个现有 ID。
- `RunAssetLedger`、`RunStateMachine`、`RunRuntimeController`/meta adapter 和 `SaveAdapter` 权威不得绕开。
- 失败保全确认前不写局外，同一 `result_id` 不重复提交；UI/动画不拥有奖励和结算。
- 现有 Godot/UE/本地素材依次经 source/license/hash/manifest/import gate；确认不足后才允许批准的新生成。
- `project.godot`、scene/resource、`.uid`、import metadata 与 `asset_manifest.*.translation` 均保持受保护；没有专门 gate 时不得吸收、改写或清理。

## 仍不可声明

- 被延期的骨骼/烘焙动画、时装替换、批量售卖或天赋树已经实现。
- 战斗房绝对 FPS 已优化、最终视觉/音频已完成、整合玩家手感或人工长局已通过。
- I2 关闭自动授权了 I3、发布、导出或任何新功能范围。

详细范围见 `docs/20_product/I2_REFACTOR_DIRECTION_AND_INCREMENTAL_BASELINE_CONTRACT.md`；逐项反馈见 `docs/20_product/I2_PLAYER_FEEDBACK_TRACEABILITY_MATRIX.md`；执行状态见 `docs/00_governance/I2_SLICE_GATE_LEDGER.md`。
