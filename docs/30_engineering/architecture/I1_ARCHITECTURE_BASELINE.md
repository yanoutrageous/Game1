# I1 Architecture Baseline

文档状态：当前 I1 工程架构基线；worktree 验收通过，committed HEAD 待验证。
最后更新：2026-07-20

## 1. 目的

本文件记录后续修改必须继承的运行权威、命令流、刷新作用域和持久化边界。它描述当前实现，不替代产品契约，也不把尚未实现的扩展点写成能力。

## 2. 运行链

```text
input / UI intent
  -> RunSceneInputRouter / page controller
  -> CommandBus (acceptance, normalization, signal boundary)
     -> ItemCommandHandler or runtime service
     -> RunStateMachine (phase authority)
     -> RunRuntimeController (lifecycle and terminal commit coordination)
  -> state_changed(scope=all|combat)
  -> RunScene coordination
     -> full view-model refresh
     -> lightweight combat refresh
  -> presentation controls
```

终局持久化链：

```text
RunAssetLedger final settlement snapshot
  -> RunRuntimeController idempotent terminal coordinator
  -> MetaProgress adapter
  -> SaveAdapter atomic/backup boundary
  -> result summary for presentation
```

结果 UI 不得反向拥有结算或写盘权。

## 3. 所有权表

| 数据 / 行为 | 唯一或主权威 | 消费者 / 适配器 | 禁止形成的第二权威 |
| --- | --- | --- | --- |
| run phase 与合法转换 | `RunStateMachine` | `RunContext` 兼容委托、controllers | UI、`RunContext` 直接赋值 |
| runtime 生命周期 | `RunRuntimeController` | `RunScene`、CommandBus | 旧 `GameKernel` autoload |
| 局内物品位置 | `RunAssetLedger` | CommandBus / handler、结果构建器 | inventory UI、本地副本 |
| 终局提交 | `RunRuntimeController` + meta adapter | result controller/view | result panel 直接写 MetaProgress |
| 命令接收与信号 | `CommandBus` | handlers/services | 控件直接调用内部 mutation |
| 物品命令细节 | `ItemCommandHandler` | CommandBus | 多份拾取/装备规则实现 |
| 保存原子边界 | `SaveAdapter` | save/profile services | 业务模块直接覆盖文件 |
| 内容 manifest | `ContentDB` autoload | catalogs / presentation | 重复加载形成漂移缓存 |
| 可复用脚本内容访问 | `ContentDBAccess` 运行时适配边界 | reusable catalogs / UI scripts | 编译期直接依赖 autoload symbol |
| 页面 revision | AppShell 当前快照与可见页 | 页面 shell | 隐藏页持续重建 |
| UI 文本/布局 | view model + presentation control | 生产场景 | UI 决定 gameplay 规则 |

## 4. 状态转换规则

- phase 赋值只能出现在 `Godot/GraytailGodot/scripts/core/run/run_state_machine.gd`。
- 任何新 lifecycle 入口必须调用状态机公开转换，并为合法/非法转换增加 runner。
- 终局状态必须先形成 final settlement；失败保全仍是两阶段，确认前不得提交。
- restart 必须区分普通确认路径和 debug gated 路径。
- 新命令应返回统一 result，再由 CommandBus 发出相应作用域的状态快照。

## 5. 刷新与性能规则

- `scope=all` 用于需要重新构建地图、背包、布局、页面摘要等完整视图模型的变化。
- `scope=combat` 只更新战斗 HP、威胁/压力、消息和必要的可见诊断；不得重建地图或隐藏页面。
- AppShell 只刷新可见页面；隐藏页面缓存 revision，切换显示时追上最新状态一次。
- `I1_COMBAT_REFRESH` 在生产 `main.tscn` 中采 180 次 combat 和 40 次 full 对照；combat p95 门为 8 ms 且必须低于 full p95。当前 core/latest-full worktree 分别测得 combat p95 519 μs / 321 μs，full p95 267,793 μs / 333,855 μs。
- 上述门只验证一次微基准。不得从它推断整局帧时间、显存、低端设备或发布性能。

## 6. 保存与兼容规则

1. 新数据先写临时文件并 flush。
2. 临时内容必须可解析后才可替换主文件。
3. 有效旧主文件在替换前进入 backup；损坏主文件不得覆盖有效 backup。
4. 主文件损坏时允许从有效 backup 恢复。
5. 主文件或 backup 的 schema 高于当前实现时只读保护；当前版本不得降级覆盖。
6. terminal commit 以 `result_id` 幂等；presentation 重开不得重复提交。
7. 这些规则不提供 active-run 跨进程检查点。

## 7. 项目元数据

当前明确 gate 允许的 I1 变更：

- Godot project feature target 为 `4.6`。
- autoload 保留 `ContentDB` 与 `SettingsManager`。
- 不再注册没有运行时消费者的 `GameKernel` autoload；脚本的历史存在不等于激活。

除此之外，`project.godot`、场景、资源、`.uid`、`.translation` 和 import metadata 仍是高风险范围，必须逐项解释并通过专门 gate。

## 8. 后续模块修改规则

- 先定位权威和消费者，再修改；禁止靠 UI 本地状态修正 core 事实。
- 一次只提取一个可被 runner 特征化的职责，不做无覆盖的大范围文件搬迁。
- 新增 runner 必须加入 `tools/i1/validation_manifest.json`，或以明确理由登记 `EXCLUDED_NON_SLICE`。
- 新增战斗高频事件默认选择最小 change scope，并用生产场景基准证明没有退回 full refresh。
- 新增资源必须经过来源、许可、hash、manifest 和 runtime key 门。
- 新增页面必须覆盖焦点、可读字号、反馈、禁用原因和支持分辨率；可见观感另行人工审查。

## 9. 已知结构债

- `RunScene` 仍是大型协调器，I1 只完成有证据支持的职责拆分。
- CommandBus 仍协调非物品命令，后续只能按稳定边界继续拆分。
- 玩家动画没有完整独立 death bitmap；音频和最终 motion feel 未验收。
- cleanup diagnostic、完整人工长局、通用性能、CI 远端成功、导出和发布仍未关闭。
