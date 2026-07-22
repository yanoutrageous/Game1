# I2 Target Architecture and Migration Plan

文档状态：I2 目标架构与迁移计划；获批范围已实施，但本文仍是计划/边界说明，不以组件名称或计划文字代替运行时验证。
最后更新：2026-07-22

## 1. 架构目标

I2 不更换领域权威。目标是在现有 Godot 生产路径上建立清晰的“领域事实 → 查询投影 → 页面状态 → 表现/动画 → 玩家意图 → 命令”链，使 UI 重排、素材替换和新增交互不再直接扩大 `RunScene`、AppShell 或页面脚本的耦合。

```text
Content / Save / Run domain authorities
                |
           read-only query
                v
        screen-specific projection
                |
                v
        view + presentation state
                |
         explicit player intent
                v
       command / navigation boundary
                |
                v
       authoritative state transition
```

动画、计时器、tooltip、proximity panel、transition 和结果页只消费语义状态，不能写入库存、phase、奖励、结算或存档。

## 2. 必须保留的权威

| 领域 | 当前权威 | I2 允许的变化 | 禁止 |
| --- | --- | --- | --- |
| 局内 phase | `RunStateMachine` | 增加只读投影、明确 transition reason | UI/动画直接写 phase |
| 局内物品位置 | `RunAssetLedger` + command handlers | 增加列表/详情/品质投影 | UI 维护第二份可提交库存 |
| terminal settlement | `RunRuntimeController` / meta adapter | 增加结果解释投影、失败重试反馈 | 结果页重复提交或预测为最终值 |
| 保存 | `SaveAdapter` | 设置与游戏进度分域调用、明确失败反馈 | UI 直接覆盖文件、未来 schema 降级 |
| 内容 | `ContentDB` / existing access boundary | 增加面向页面的只读 projection | 页面硬编码内容/地图 ID |
| 地图 truth | 当前 run/map authority | 增加 fog-safe mini/full-map projection | 泄露未知雷/房间或生成第二份 truth |
| 战斗 | 固定步 simulation + command/event path | 表现插值、事件批处理、测量点 | 变步长 UI Tick 成为战斗权威 |

## 3. 目标模块边界

下列名称表示职责，不预先要求新建同名 class。每个切片应先复用现有模式；只有职责被至少两个消费者共享或当前协调器确有 characterization 时才提取。

### 3.1 应用壳与共享表现

| 职责 | 输入 | 输出 | 边界 |
| --- | --- | --- | --- |
| Navigation coordinator | 入口意图、当前 route、可离开条件 | route prepare/commit/cancel/fail | 只有它提交页面路由；转场不直接切页 |
| Transition presenter | source/target 语义、reduced-motion、完成/取消 token | 动画进度和完成信号 | 不拥有 route；重复点击必须幂等或拒绝 |
| Modal/focus stack | modal 优先级、previous focus | 打开/关闭、焦点归还 | 一个输入事件只能被最高层消费 |
| Settings application boundary | persisted settings + draft | apply/confirm/revert/result | 控件不能声称尚无消费者的设置已生效 |
| Character presentation port | actor/skin id、semantic motion state、anchor | sprite/clip/fallback | 页面不感知源图布局、帧数或时装路径 |
| UI style/layer tokens | semantic role/state | panel/button/text/layer style | 统一语义与层级，不强迫模块使用同一构图 |

### 3.2 主菜单

- `MainMenuShell` 保留页面装配；文字、旗帜、选中框和角色通过场景语义锚点定位。
- 入口发出 `navigate(target)` 意图；navigation coordinator 请求 transition presenter 播放“洞口/下层/其他入口”状态，完成后一次性提交 route。
- transition fail/cancel 恢复 source 页面、输入和焦点；reduced motion 可立即使用短淡变但仍走同一状态结果。

### 3.3 Deploy

```text
Deploy selection source
  -> left list projection
  -> selected-id detail projection
  -> summary projection (overview/config/effect/objective)
  -> start intent -> existing RunStartConfig/command path
```

- Map presenter 只把现有 ID 分为显示规模并在同一页投影难度；不得引入 region page state。
- Warehouse presenter 读取局外库存实例、当前使用/出勤与品质；所有动作转成现有或经批准的新命令。
- Claim presenter 可复用 split-layout/focus 组件，但拥有独立数据与 action adapter。
- Summary presenter 只从已选配置和权威可用性生成简写，不保存自己的业务状态。
- 金币是局外权威投影；交易结果刷新 projection，不能乐观写最终余额后忽略失败。

### 3.4 长期系统

- 共享 shell 只负责全局导航、一级模块和档案栏开合。
- 任务档案、天赋、图鉴、研究、资历、收藏、角色分别拥有面向其真实数据的 presenter；避免继续以一套通用卡片容纳所有字段。
- “目标 → 天赋”迁移分三步：

  1. 建立任务/成就/委托记录的新 projection、导航和回归，保持原数据权威；
  2. 定义天赋节点 ID、依赖、成本、效果、解锁和持久化权威；
  3. 完成数据与红点迁移后再修改入口名称，保留失败回退。

没有第二步的真实规则时，只能展示设计原型，不能成为 production capability。

### 3.5 局内与结果

`RunScene` 当前仍是大型协调器。I2 只按以下可 characterization 的职责逐个外移，不做大爆炸重写：

| 目标职责 | 只读输入 | 玩家意图 | 不拥有 |
| --- | --- | --- | --- |
| Room object presentation | room/object state、anchors | interact/focus | chest reward、door transition |
| Proximity details | nearby candidate snapshot | select/pickup/open | ledger mutation、自动拾取 |
| Quick inventory presentation | ledger projection、capacity | use/drop/open inventory | inventory truth |
| Map presentation | fog-safe map snapshot | select/mark/close | truth map、move command |
| Protocol/status presentation | protocol/pressure/reason | none/view details | protocol calculation |
| Modal/focus owner | current modal priority | confirm/cancel | phase/result authority |
| Result explanation | immutable result snapshot、save state | confirm salvage/retry/continue | settlement calculation/commit |

职责提取前先记录现有信号、输入、刷新和 lifecycle 行为；提取后由相同 characterization 加新增行为 runner 证明外部行为未意外变化。

## 4. 状态机边界

### 4.1 导航与转场

```text
IDLE
  -> PREPARING(target, token)
  -> PLAYING(token)
  -> COMMITTING(target, token)
  -> IDLE(target)

PREPARING / PLAYING / COMMITTING
  -> CANCELLING -> IDLE(source)
  -> FAILED(reason) -> IDLE(source)
```

- 同一 token 只提交一次；过期动画回调无效。
- route guard 先于动画；目标构建失败不应把 source 页面隐藏在不可恢复状态。
- reduced motion 不跳过 state machine，只改变 presenter 的时长和效果。

### 4.2 设置

```text
PERSISTED -> EDITING_DRAFT -> APPLYING
APPLYING -> APPLIED -> PERSISTING -> PERSISTED
APPLYING / PERSISTING -> FAILED -> EDITING_DRAFT or REVERTED
```

即时预览字段与需确认字段必须明确区分；退出未确认设置要还原。保存失败不得显示为成功，未来 schema 保护继承 I1。

### 4.3 页面选择

- 列表保存稳定 `selected_id`，详情与摘要由同一 ID 投影。
- 内容刷新后若 ID 消失，使用显式 fallback 并通知焦点；不得按旧 index 误选其他内容。
- page/tab/filter/scroll/focus 是表现状态，不进入领域存档，除非产品明确要求并另设 schema 门。

### 4.4 角色与对象表现

```text
authoritative event/state
  -> semantic presentation state
  -> clip lookup(actor/skin/state)
  -> frame/rig-baked playback or static fallback
```

- 语义状态包括 idle/move/enter/attack/hurt/dead/interact 等；clip 缺失必须降级而非阻断玩法。
- 领域位置/碰撞即时权威，视觉插值可延后但不得显示穿门、错箱或错误交互距离。
- 怪物入场和箱子展示只在相应权威事件后播放；动画结束不发放奖励。

## 5. 性能设计

I1 的 combat refresh p95 只测刷新函数。I2 性能工作按以下分解：

```text
frame total
  simulation fixed-step
  snapshot creation/copy
  command/event dispatch
  presentation update
  UI layout/draw
  asset load/cache
  allocation/GC and memory growth
```

测量场景至少覆盖 1/3/5 敌人、峰值效果、箱子多物品、地图打开、背包滚动、页面往返和 60 秒以上持续战斗。记录 P50/P95/P99/max、追赶步数、加载次数、分配量和内存漂移。优化前固定机器、版本、分辨率、VSync、seed 和内容；优化后用相同配置比较。没有整帧证据时只能声明分项改善。

优先调查已有高概率成本：每帧战斗快照复制、actor view 遍历、同步资源加载、隐藏页面持续 `_process`、整页/格网重建。调查结果决定是否缓存、事件化或局部刷新；本计划不预先宣称这些都是实际瓶颈。

## 6. 迁移顺序与回退

| Step | 迁移 | 先验/characterization | 回退点 |
| --- | --- | --- | --- |
| 0 | I2 文档与门 | exact HEAD full 39/39 | I1 closed baseline；无运行改动 |
| 1 | 共享 focus/modal/settings/character/transition seam | 当前 route、Esc、settings round-trip、animation fallback | 保留当前 fade/页面输入路径，可按 feature gate 回退 |
| 2 | 主菜单锚点与语义转场 | 四入口与返回、三分辨率 | 逐入口回退，不回滚共享接口 |
| 3 | Deploy split view/summary/map | 八地图 ID、RunStartConfig、库存/金币命令 | tab 级回退；地图路由不得变化 |
| 4 | 长期模块 presenter 与任务迁移 | 任务/成就/红点/领取/存档 | 保留旧 Goal 入口直到迁移等价通过 |
| 5 | Run presentation 逐职责提取 | room/object/ledger/map/modal 信号与输入 | 每个 presenter 独立 feature gate；RunScene 旧适配保留至通过 |
| 6 | room/result/performance | deterministic combat、结算幂等、失败保全 | 表现可回退；领域/存档变更必须 migration/backup |
| 7 | 删除仅由 I2 引入且确认无用的 compatibility seam | 全量调用图、full/head、人工关键路径 | 删除前独立 diff 与回滚提交点 |

compatibility seam 只服务当前迁移，必须登记 owner 和删除条件；不得为猜测中的未来系统建立通用插件层。

## 7. 每个工程切片的最小交付

```text
Before:
  authority and behavior characterization
  allowed/protected path list
  baseline command and evidence
Change:
  one responsibility or one coherent page flow
After:
  targeted runner
  required I1 profile
  production preview
  dynamic/input/failure review where user-facing
  performance comparison where claimed
  asset/import audit where touched
Claim:
  exact implemented states and explicit NOT_RUN/deferred items
```

## 8. 目标判断

该架构计划的成功标准不是新增类的数量，而是：页面可以替换布局/素材而不改领域权威；状态转换可取消、可恢复、可测试；玩家看到的内容来自同一事实源；真实工作负载可分解测量；新增页面状态能快速进入生产预览和操作验收。

## 9. I2 实施边界与后续架构项

I2 已在获批范围内落实只读投影、显式玩家意图、模态/focus 优先级、页面/角色表现边界、世界对象/地图/背包展示边界、战斗离房与结果解释的权威分离；`RunStateMachine`、`RunAssetLedger`、terminal settlement、`SaveAdapter` 和既有内容/地图 truth 仍保持唯一领域权威。实际接线、回归与失败路径证据以待建 `docs/validation/I2_PLAYER_EXPERIENCE_REFACTOR_VALIDATION.md` 为准。

本文没有因此宣称目标架构已全面落地。`RunScene` 仍是大型协调器；完整导航空间转场、运行时骨骼/时装素材管线、真实天赋数据权威、批量经济事务、跨进程 active-run 恢复、最终美术/音频和设备级性能架构均不在本次已验证范围。后续若提取新职责或改变领域边界，必须另建迁移契约、characterization 与等价回归门，不能把本计划视为自动授权。
