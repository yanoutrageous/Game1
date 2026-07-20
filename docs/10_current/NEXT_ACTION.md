# Next Action

文档状态：I1 关闭后的增量开发入口；当前无自动授权的后继阶段。
最后更新：2026-07-21

## 当前状态

I1 已以 `CLOSED / PASS_WITH_NOTES` 收口，最新闭合非美术基线为 I1，当前没有自动命名或授权的后继阶段。下一项工作应先定义独立范围、验收门与证据，再按下述默认方式推进；不得继续以 I1 名义扩大重构范围。

## I1 后默认开发方式

- 日常修改先跑 quick；程序权威/保存/战斗跑 core；UI/动画/路由跑 ui + preview；合入或阶段关闭跑 full/head。
- 一次只迁移一个有 characterization 的职责，继续缩小 `RunScene` 和剩余协调耦合。
- 新命令、状态、资源、页面、schema 和接口都必须登记权威、失败边界和最小验证说明。
- capture、人工、性能、CI、导出和发布证据分开记录，不能互相替代。

## 后续候选增量

| Priority | 候选方向 | 前置门 |
| --- | --- | --- |
| P1 | active-run 跨进程检查点、恢复与迁移 | save/version/idempotency/crash recovery contract |
| P1 | `RunScene` 下一职责提取与 CommandBus 继续分区 | pre-change characterization + full regression |
| P1 | 完整人工关键路径、动画/交互手感和可见状态矩阵 | 独立 manual/Computer Use criteria |
| P2 | 仓库经济、装备被动/强化、Boss/精英和更深内容 | 产品规则 + runtime + UI + persistence 联合契约 |
| P2 | 通用性能、设备/输入、导出、CI 与发布 | workload、阈值、目标平台与远端 artifact |

这些是候选，不是自动命名或授权的新 G/ART/M/P 阶段。下一增量必须引用 I1 contract、architecture、runbook 和最终 validation。

## 必须继承的事实

- 最新闭合非美术基线是 I1；项目级最新闭合美术阶段是 ART21。I0 保留为前序冻结基线。
- ART23 是较晚页面/UI 证据，不提升项目级 art-stage authority；ART24R2 仍是失败历史。
- `RunAssetLedger`、`RunStateMachine`、`RunRuntimeController`/meta adapter 和 `SaveAdapter` 的权威边界不得绕开。
- 失败保全确认前不写局外，同一 `result_id` 不重复提交。
- 当前进程继续不等于跨进程恢复。
- I1 combat 微基准不等于通用性能或发布 PASS。
