# I1 Baseline Assessment

文档状态：`FROZEN_CLOSED_I1_BASELINE_ASSESSMENT`；I1 关闭后冻结，不再回写后续阶段事实。
评估日期：2026-07-21

## 1. 结论

判断：**I1 验收已证明项目适合进入“增量开发与存量修改并行”阶段。**

依据不是文档中的完成宣称，而是当前代码已经包含可运行的导航、出发、局内移动/交互/战斗、物品、终局结算、局外写回、地图难度与首轮长期成长内容；同时 I1 已形成统一隔离 runner、生产场景预览和明确的权威边界。继续把所有工作当作单一路径的核心开发，会放大回归和验证等待；完全转为维护也不成立，因为若干产品系统仍未完成。

worktree static、全部 profiles、ART25、预览静态检查、提交态 full/head 39/39 和 Git 交付已经使该结论生效；GitHub Actions quick run `29760789712` 另行证明远端 quick。自动化、预览、人审、性能与 CI 仍各自只证明明确范围。本评估不替代 `docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`。

## 2. 当前代码事实

| 方面 | 代码事实 | I1 处理 | 剩余风险 |
| --- | --- | --- | --- |
| 命令耦合 | `CommandBus` 同时承载多类命令协调 | 物品命令迁入独立 handler，bus 保留校验、归一化和信号职责 | 仍需按特征测试一次迁移一个职责 |
| 状态转换 | 历史兼容入口可直接触及 phase | phase 写入集中到 `RunStateMachine` | 状态种类继续扩展时需维护合法转换表 |
| 终局权威 | UI 与 runtime 历史上存在结算写回混淆风险 | `RunRuntimeController` 协调一次性最终提交，结果控制器只展示 | 幂等 key 和两阶段失败保全必须保持 |
| 重开安全 | 普通重开和 debug 路径存在混用风险 | 普通重开强制确认，debug restart 独立且受 gate 约束 | 新入口不得绕过 CommandBus |
| 保存 | 需要面对半写入、损坏与未来 schema | 临时文件、flush、备份、恢复和防降级保护 | 不包含 active-run 跨进程检查点 |
| 战斗刷新 | 全量 UI 重建进入战斗热路径成本高 | combat scope 使用轻量快照和局部刷新；最终 full/head combat p50/p95/p99/max 为 110/222/310/356 μs，full p95 151,070 μs | 仅有微基准，不代表长局或低端设备 |
| 页面刷新 | 隐藏页面也刷新会增加无效工作 | AppShell 只刷新可见页并缓存 revision | 新页面必须遵循同一作用域规则 |
| 场景协调 | `RunScene` 仍是大型协调器 | 已提取输入、路由、结果、命令反馈等职责并建立回归门 | 不能以 I1 名义宣称彻底解耦；行数变化本身也不是完成标准 |
| 项目元数据 | 旧 `GameKernel` autoload 已无运行时消费者 | I1 专门 gate 验证 4.6 feature 与当前 autoload 所有权；`ContentDBAccess` 消除可复用脚本的编译期 autoload 耦合 | metadata 仍属高风险暂存范围 |

## 3. 美术、动画与交互评估

| 方面 | 当前事实 | I1 改善 | 未完成边界 |
| --- | --- | --- | --- |
| UI 排版 | 主菜单、出发、长期、局内已有生产路由；历史阶段口径冲突 | 生产面板覆盖 1280×720、1600×900、1920×1080；run/combat 双行状态框与 deploy 单行摘要修复已通过定向 runner 和 latest full | 不能代替全部页面逐态人工验收 |
| 交互可达性 | 部分新增按钮缺少统一焦点或可见反馈风险 | 共享按钮可聚焦、可见文字不低于 13 px、禁用原因和命令反馈可见 | 鼠标/手柄手感仍需人工操作 |
| 动画 | 运行时角色/敌人有状态帧但反馈不完全统一 | 引入贴图缓存、idle/move/attack/hurt/dead 映射、受击最短可见时间和 reduced motion | 玩家缺少独立 death bitmap；不声明最终动画 |
| 资源表现 | ART25 内容资源存在来源、重复和占位风险 | 107 assets 来源/许可/manifest gate 与确定性 fingerprint 已通过；生产字体使用 Noto Sans CJK | 最终观感仍需独立人审 |
| 快速阅览 | 历史截图流程分散 | 从 production `main.tscn` 生成九状态 × 三分辨率 27/27 预览；静态布局、层级、文字、无遮挡与无裁切已人工通过 | 鼠标/手柄、动态动画与音频仍未验收 |

项目级最新闭合美术阶段仍按仓库治理记为 ART21。ART23 是较晚且已验收的页面/UI 运行证据切片，可作为具体页面回归依据，但不提升为新的项目级 art-stage authority。ART24R2 的 24/61 失败封存仍是历史事实，不得被 I1 改写为通过。

## 4. 文档与治理评估

发现的主要问题：

- 首入口分别停留在 I0+ART21、M6/M7、ART23/ART24R2 等不同时间点，branch 和 Godot 绝对路径互相冲突。
- 历史 `D:\AGAME1` 外部 source pack 被写成当前路径，但本机 2026-07-20 只读检查均不存在。
- Godot 内部 docs registry 使用历史绝对路径，且三个文件 hash 已漂移。
- 旧评估、validation 与 handoff 容易被误当作当前能力说明。
- CI quick 已有远端成功运行证据，但 full、导出与 release 仍未证明。

I1 的治理方式是保留历史原文，更新短入口链和注册表，不做批量删除或历史正文改写。I0 评估继续冻结；I1 变化已写入本评估和新的 validation / handoff。本文件随 I1 关闭冻结，后续事实不得回写。

## 5. 验证能力评估

I1 harness 提供：

- `preflight`：manifest、mirror、锁定 Godot、import 与隔离边界。
- preflight 已将 7 次包含 `.tmp` 历史 mirror 的全树扫描收敛为一次剪枝源检查和复制后完整目标检查；最新耗时 120,233 ms，较旧观测下降 36.5%，安全门保持。
- `quick`：短跨层回归。
- `core`：I0 特征用例、M/G 内容与 I1 程序不变量、战斗刷新微基准。
- `ui`：生产 UI 路由、布局、动画和交互契约。
- `full`：manifest 中全部 blocking runner。
- `SourceMode worktree/head`：分别验证当前改动和提交快照。
- JSON 报告、精确 marker、超时、engine diagnostic 分类、Git 与业务文件污染守卫。
- 生产场景预览 wrapper；生成证据与人工视觉验收分离。

最终提交态 full/head 39/39 与 27/27 预览证据表明这套能力足以支撑大部分后续切片的快速反馈；它仍不能覆盖完整人工游玩、交互手感、通用性能、跨进程恢复、导出或发布。

## 6. I1 后优先级

| Priority | 工作流 | 推荐 gate |
| --- | --- | --- |
| P0 | 保持 I1 quick/full、污染与权威不变量稳定 | 每个变更 quick；合入前关联 profile；阶段关闭 full/head |
| P1 | 继续拆分 `RunScene` 和 CommandBus 剩余职责 | 一次一个职责，先加 characterization，再迁移 |
| P1 | 建立 active-run 跨进程恢复和迁移 | save schema、崩溃恢复、未来版本、防重复提交测试 |
| P1 | 补完整人工关键路径与可见 UI 状态矩阵 | 独立人工/Computer Use 记录，不混入 headless PASS |
| P2 | 扩展仓库经济、内容量、Boss/精英、装备被动和长期成长 | 产品契约 + runtime + UI + persistence 联合 gate |
| P2 | 建立通用性能、设备、输入、导出与发布门 | 可复现 workload、阈值、CI artifact 和目标平台证明 |

## 7. 风险判断

- 最大程序风险已从“没有闭环”转为“多权威、热路径刷新和大型协调器导致修改回归”。
- 最大美术风险是自动布局/截图生成被误写为最终视觉与交互验收。
- 最大治理风险是历史路径、历史阶段和较晚页面证据混写成一个虚假的 latest stage。
- 后续交付风险是把 worktree 或 scoped CI 结果误当作提交态 full/head，或让新增改动绕过 I1 的权威、污染与回归门。

因此，I1 应作为之后所有增量的基线门，而不是一次性清债结束点。
