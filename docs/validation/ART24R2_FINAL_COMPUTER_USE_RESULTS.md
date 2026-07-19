# ART24R2 最终 Computer Use 验收结果

- 验收标准：`ART24R2-UE-LAYOUT-CU-FROZEN-1`、`ART24R2-FINAL-CU-FROZEN-1`
- 验收日期：2026-07-19
- 事实来源：UE 源码与实机、Godot 源码与生产 `main.tscn` 实机
- 最终结论：`FAIL / STAGE_ARCHIVED_BY_USER_DIRECTION`
- 视觉状态统计：`PASS 24 / FAIL 37`
- 自动化代码门：ART24 静态检查 `PASS`，当前聚焦回归 `8/8 PASS`，G41 核心运行时本体 `PASS`；正式包装校验未全部通过

## 结束条件说明

冻结标准要求 61 个二级状态全部经 Computer Use 通过后才允许标记完成与 push。本轮未满足该标准。2026-07-19 用户明确要求停止继续扩大返工与验收范围，将当前内容跑完后以“验收部分不通过”的状态结束并 push。因此：

1. 本文不修改、不追溯放宽冻结标准；
2. 本次 push 是未通过快照的阶段封存，不是验收通过；
3. ART24R2 不得在能力矩阵、阶段索引或后续交接中标记为 `PASS`/完成；
4. 后续若恢复返工，仍须沿用原冻结标准，补验 37 个失败状态及受影响相邻状态。

## 代码与实机双证据结论

| 模块 | UE 代码/实机基准 | Godot 代码状态 | Godot Computer Use 结果 | 判定 |
| --- | --- | --- | --- | --- |
| 默认局内构图 | 560×560 方形房间、64 高角色、约 22.4% 左栏、紧凑协议与 720×40 热键栏 | ScaleToFit 方形房间、角色缩放 0.50、UE 比例布局契约已接入 | 房间四边完整；角色约占房间高 10%—12%；左栏、协议、热键栏不再沿用用户截图中的异常比例 | PASS |
| 背包 | 固定四行，48 行高、4 间距，真实容量 | 四行真实数据、滚动满载、真实图标与详情清洗 | 空、已有、选中、满载、详情五态均在生产局内观察通过 | PASS |
| 地图 | 全屏暗幕、10×10 主网格、底部反馈，未知格可标记 | 移除常驻详情条，集中布局，标记语义独立 | 概览、选格、标记/取消通过；已探索格返回未形成冻结证据 | FAIL |
| 世界掉落/箱子 | 世界实体优先，靠近才显示上下文，不使用固定整屏回收页 | 房间 ScaleToFit 坐标转换到未缩放 UI overlay；真实主场景集成探针 | 箱子反复开合/清空、单件地面物、满包替换链路通过；多件、离开隐藏和明确容量拒绝未完整验收 | FAIL |
| 结算 | 380 内容列、300×130 横幅、两项真实操作；失败保全为前置状态 | 最终框与候选框分离，成功/失败共用正式结构 | 成功与失败最终态通过；候选、选中、超重阻塞、主动放弃未完成冻结验收 | FAIL |
| 战斗与动效 | 移动/攻击/受击/怪物全链路连续，减弱动效不丢信息 | 固定步长、显示插值、脏更新、完整玩家动作与怪物变体已实现 | 本轮未完成怪物全动作和减弱动效的逐状态 Computer Use 证据 | FAIL |

## 61 状态结果

`FAIL` 同时包含“实际画面不合格”和“没有在本轮冻结流程中取得足够的新鲜实机证据”。两者都不能作为通过。

### PASS（24）

- `room.normal.idle`
- `room.chest.closed`
- `room.chest.context_nearby`
- `room.chest.container_open`
- `room.chest.container_closed`
- `room.chest.reopened`
- `room.chest.empty`
- `protocol.level.5`
- `map.overview`
- `map.cell_selected`
- `map.marked`
- `inventory.empty`
- `inventory.populated`
- `inventory.selected`
- `inventory.full`
- `inventory.tooltip`
- `loot.floor_visible`
- `loot.context_nearby`
- `loot.pickup`
- `loot.replace_select`
- `loot.replace_confirm`
- `overlay.pause`
- `result.success`
- `result.failure`

### FAIL（37）

- `room.normal.searching`
- `room.normal.loot_spawned`
- `room.normal.depleted`
- `room.mine.hidden`
- `room.mine.warning`
- `room.mine.triggered`
- `room.mine.resolved`
- `room.chest.opening`
- `room.event.idle`
- `room.event.active`
- `room.event.resolved`
- `room.monster.appear`
- `room.monster.idle`
- `room.monster.attack`
- `room.monster.hit`
- `room.monster.defeated`
- `room.exit.inactive`
- `room.exit.active`
- `room.exit.confirm`
- `protocol.level.4`
- `protocol.level.3`
- `protocol.level.2`
- `protocol.level.1`
- `map.return_available`
- `loot.context_multi`
- `loot.capacity_blocked`
- `loot.context_hidden_after_leave`
- `overlay.tutorial`
- `overlay.event_choice`
- `overlay.extract_safe`
- `overlay.extract_risky`
- `result.failure_salvage_select`
- `result.failure_salvage_selected`
- `result.failure_salvage_capacity_blocked`
- `result.abandoned`
- `motion.full`
- `motion.reduced`

## 已确认的主要改善

- 角色与房间比例已从用户截图中的明显过小状态回到 UE 基准区间；碰撞与移动规则未随贴图尺寸改变。
- 中央战斗区恢复为完整方形主视觉，左栏、协议层与底栏不再压缩房间或形成大块无解释空白。
- 地面回收物首先显示为世界实体；靠近后出现紧凑悬浮窗，满载时进入真实替换流程，不再默认弹出固定整屏回收页。
- 箱子首次生成内容后可重复关闭与打开，剩余物和空箱状态保持一致。
- 展开地图回到 UE 的“标题—大网格—底部反馈”结构；背包和结算按 UE 的尺寸权重重新排布。
- 新增生产 `main.tscn` 坐标集成探针，覆盖旧布局探针无法发现的“测试通过但实机悬浮窗覆盖实体”问题。

## 未通过项的后续入口

若未来恢复 ART24R2，只需从上述 37 个 `FAIL` 状态继续；优先顺序为失败保全四态、地图返回、多物品/离开隐藏、怪物五态、完整/减弱动效。不得把本次封存 push 当作视觉验收通过证据。

## 最终自动化记录

- `ART24_STATIC_VALIDATION=PASS assets=209 reused=14 states=61 decoded_mib=35.63`
- 世界上下文、RunSurface、地图布局/场景、运行时矩阵、生产坐标集成、结算场景、背包布局共 8 个聚焦探针均 `PASS`。
- `G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS fixed_hz=60 outer_schedules=30,60,144,hitch monsters=slime,slimeling,bat,drone visual_contract=v1`。
- G41 正式包装校验为 `FAIL`：缺少 `ArtVisual replacement` 审计标记，且宝箱/角色视图仍被规则识别为硬编码最终美术路径。
- M6 逻辑 runner 与 ART22 出发页回归均 `PASS`；首次包装校验因三份新增 `.tscn` 探针尚未纳入 Git 而 `FAIL`，纳入提交范围后复跑得到 `M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION=PASS`。
- 背包场景探针退出时报告 `ObjectDB`/资源未释放警告；虽然退出码为 0、断言通过，仍计为未清技术债，不解释为最终质量通过。
