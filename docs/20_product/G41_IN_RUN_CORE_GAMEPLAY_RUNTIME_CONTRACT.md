# G41 局内基础玩法运行时与交互接口补全契约

状态：CLOSED / PASS；实现、正式执行审计、回归和污染检查均已通过，随 G41 最终提交上传。

## 中文摘要

G41 的程序目标是把已有的地图格探索、资产账本和结算规则接成真实的房间内玩法：玩家连续移动并靠近实体交互，宝箱在世界中开启并生成实际地面掉落，玩家可拾取、替换或再次丢下物品；怪物房由固定步长战斗模拟驱动，胜利奖励与逃跑损失通过现有 CommandBus / Rule / Effect 管线提交。

本阶段只承诺程序侧“可玩且可接美术”。美术资源、动画品质、最终特效和音频由并行美术工作负责，不作为 G41 程序关闭条件。缺少美术资源时必须使用程序占位，不得崩溃或改变碰撞。

## 基线与参考边界

- 实施基线：`art/art23-long-term-final-ui` 的 `7f2e0b304e2cd7959411bfe6422d3d0b3337462f`。
- 基线例外：用户明确要求 ART24 不得作为 G41 基线；`art/art24-in-run-final-ui` 未进入实现、审计或验收证据。
- 活跃项目：当前 Git worktree 内的 `Godot/GraytailGodot`。
- UE 行为参考：`yanoutrageous/Game.git` 的最新可验证提交 `de4ece1163505d9fe08e31cd0dbe10477909f963`。
- UE 的史莱姆、幼体、蝙蝠、无人机参数与行为作为迁移参考；UE 中把战斗逻辑放在 UMG Tick 的结构不迁移。
- Lua 与 UE 均为只读参考，不是当前状态权威。

## 权威边界

| 数据 | 唯一写入权威 | 消费者 |
| --- | --- | --- |
| 局内物品位置 | `RunAssetLedger` | 地面实体、背包、替换面板、结算 |
| 活跃战斗的位置、HP、计时器、敌人、投射物和激光 | `G41CombatSimulation` | 房间运行时视图、HUD 只读快照 |
| 持久局内 HP、房间清理、奖励和逃跑损失 | CommandBus → RoomResolver → Rule/Effect | RunContext 公共快照 |
| 美术显示 | `visual_key + visual_state + anchors` | 美术子场景或程序占位 |

UI 与房间视图不得直接修改 HP、物品位置、宝箱结算、房间清理或最终结算。

## 程序—美术接口

稳定锚点：

- `VisualRoot`
- `BodyAnchor`
- `PromptAnchor`
- `HealthBarAnchor`
- `AttackOrigin`
- `ProjectileOrigin`
- `LootSpawnAnchor`
- `ShadowAnchor`

稳定状态：

- 玩家：`idle / move / attack_windup / attack_active / attack_recovery / hurt / dead`
- 宝箱：`closed / opening / opened`
- 地面物品：`idle / focused / pickup / blocked`
- 近战怪物：`idle / move / warning / active / cooldown / hurt / dead / split`
- 远程怪物：`idle / move / aim / fire / cooldown / hurt / dead`
- 投射物：`spawn / active / hit / despawn`

协作规则：

1. 程序负责 gameplay 脚本、固定逻辑碰撞、状态机、运行时根节点和占位显示。
2. 美术负责图片、SpriteFrames、动画和 `VisualRoot` 下的视觉子树。
3. 核心程序不得硬编码最终 PNG 路径，不得从纹理尺寸计算逻辑碰撞。
4. 资产映射/manifest 的整合切片必须只有一个提交所有者；程序和美术不得同时修改同一映射文件。
5. 替换或缺失美术资产不得要求修改战斗、拾取、开箱或结算代码。

## 交付范围

- 房间内连续八方向移动、朝向、加速和减速。
- 距离驱动的通用交互请求，当前实现宝箱与逐实例地面物品。
- 宝箱一次性 `closed → opening → opened`，奖励进入当前房间 `room_floor`。
- `instance_id` 一对一世界掉落实体；拾取失败保留原实例；替换把背包物品移回同一房间地面。
- 60Hz 固定步长、私有确定性随机源和只读战斗快照。
- 史莱姆追击/预警/近战与死亡分裂，幼体游走/近战，蝙蝠保持距离/三发散射，无人机保持距离/跟踪激光/冲刺。
- 玩家攻击前摇/生效/后摇、120 度锥形判定、冷却和受击无敌帧。
- 多敌人、投射物线段扫掠、激光周期伤害、死亡、房间清理和一次性怪物地面掉落。
- 战斗中到门口按逃跑处理：损失 10% 待结算黑币；确定性选中的普通非消耗品移到当前房间地面；房间不清理，再进入重新开战。
- 模态框、地图、暂停与阻塞教学期间显式暂停战斗模拟。
- 新局、失败、撤离和放弃时清理运行时状态。

## 非范围

- 最终角色、怪物、掉落、弹道、激光、宝箱美术与音效。
- Boss、精英、技能树、完整被动系统、完整事件系统与最终数值平衡。
- 跨进程局内保存、存档迁移、发布、CI、性能认证或完整人工长时间游玩。
- 对 UE UMG Tick 架构的复制。

## 验收规则

1. Godot 4.6.3 能加载主场景，GDScript 无解析错误。
2. `RunAssetLedger` 是物品位置唯一权威；世界实体只投影当前房间 `room_floor`。
3. 宝箱只结算一次；重复交互不增加黑币或物品。
4. 背包有空间时拾取成功；满背包时物品仍在地面；替换后拾取物进背包、被替换物回到同一房间地面。
5. 怪物房创建固定步长战斗；四种怪物行为、锥形攻击、冷却、无敌帧、分裂、投射物、激光和失败事件均可观察。
6. 胜利只提交一次奖励并清理房间；怪物掉落成为实际世界地面实体。
7. 逃跑精确损失 10% 待结算黑币；物品损失只移动到 `room_floor`；房间保持未清理且再次进入会重启战斗。
8. 30/60/144Hz 外层调度与包含 0.2 秒卡顿的调度，在相同输入下得到相同规范状态与事件顺序。
9. 暂停 5 秒等同于不推进任何战斗 tick。
10. 缺失最终美术时程序占位仍可玩；更换 `VisualRoot` 内容不改变逻辑碰撞。
11. `tests/g41_in_run_core_gameplay_runtime_runner.gd` 输出 `G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS`。
12. 相关既有结构、M2/M3/M5/I0 与 ART21/22/23 路线不得回归。

以上规则已由 `docs/validation/G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_VALIDATION.md` 的正式执行审计逐项核对。用户已授权计划确认后的审计、修正、提交和上传自动完成。
