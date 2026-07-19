# ART24R2 生产节点全状态 Computer Use 路线

适用标准：`ART24R2-UE-LAYOUT-CU-FROZEN-1`、`ART24R2-FINAL-CU-FROZEN-1`。

本路线在最终验收前确定。ART24 preview runner 不能作为通过证据。允许从 Godot 编辑器启动生产 `main.tscn`，并使用生产局内的开发诊断面板播种真实房间、物品和结算快照；关闭诊断面板后，被检查的房间实体、上下文窗、地图、背包、模态层和结算页必须全部是生产节点。

## 固定入口

1. 从 Godot 编辑器运行 `main.tscn`，主菜单 → 出发探索 → 确认出发 → 实际局内。
2. 默认窗口使用 1280×720 逻辑视口；分辨率探针另行覆盖其余四档。
3. 需要稳定播种时：局内 Esc → 诊断面板。诊断层本身不参与视觉验收，播种完成后关闭。
4. 每一项记录 `PASS` 或 `FAIL`。任何 `FAIL` 立即停止完成判定，并在返工后复验该状态及前后相邻状态。

## 61 个二级状态路线

| # | secondary_id | 生产路线 | 主要检查点 |
| ---: | --- | --- | --- |
| 1 | `room.normal.idle` | 默认实际局内，关闭全部模态 | 方形房间、角色比例、四边出入口 |
| 2 | `room.normal.searching` | 默认房按 E 搜索，捕捉搜索过程 | 搜索反馈属于房间，不弹整屏战利品页 |
| 3 | `room.normal.loot_spawned` | 搜索产出或诊断播种地面物品后关闭诊断 | 物品先作为地面实体出现 |
| 4 | `room.normal.depleted` | 已搜索房再次搜索 | 已清空反馈短促，不改变主布局 |
| 5 | `room.mine.hidden` | 诊断移动到雷房但不触发 | 危险未公开，房间主体仍清晰 |
| 6 | `room.mine.warning` | 进入雷房警戒阶段 | 危险提示不遮挡角色与通路 |
| 7 | `room.mine.triggered` | 触发雷房 | 命中反馈受房间裁切，协议层同步 |
| 8 | `room.mine.resolved` | 完成雷房处理 | 危险已处理的差异可辨认 |
| 9 | `room.chest.closed` | 诊断 Nearest Chest，角色停在交互范围外 | 关闭箱体为房间实体 |
| 10 | `room.chest.context_nearby` | 靠近关闭箱体 | 只在靠近后出现紧凑悬浮窗 |
| 11 | `room.chest.opening` | 靠近后按 E，捕捉开箱帧 | 开启动画连续，内容不提前跳出 |
| 12 | `room.chest.container_open` | 开箱动画结束 | 悬浮窗显示真实箱内物，非固定整屏弹窗 |
| 13 | `room.chest.container_closed` | 关闭已打开箱体 | 箱体保持已生成内容，可再次靠近 |
| 14 | `room.chest.reopened` | 再次打开同一箱体 | 不重复生成内容，剩余物保持 |
| 15 | `room.chest.empty` | 取走箱内全部物品并重开 | 空箱反馈明确、仍可关闭/重开 |
| 16 | `room.event.idle` | 诊断 Nearest Event，未选择选项 | 事件物件属于房间 |
| 17 | `room.event.active` | 触发事件 | 选项层不暴露内部 ID，不破坏 HUD |
| 18 | `room.event.resolved` | 选择一个真实事件选项 | 结果回到同一房间层级 |
| 19 | `room.monster.appear` | 诊断 Nearest Monster，捕捉出现阶段 | 默认使用 UE/已有怪物资源，变体不改规则 |
| 20 | `room.monster.idle` | 怪物出现完成后不输入 | 脚底关系、体形和角色同尺度可信 |
| 21 | `room.monster.attack` | 触发清理并捕捉怪物攻击 | 动作不是单帧闪烁，特效受房间裁切 |
| 22 | `room.monster.hit` | 战斗命中阶段 | 受击帧、命中闪光和生命反馈一致 |
| 23 | `room.monster.defeated` | 完成战斗 | 击败帧与掉落顺序清楚，不弹整屏回收页 |
| 24 | `room.exit.inactive` | 到撤离房但未满足撤离条件 | 出口未激活状态可辨认 |
| 25 | `room.exit.active` | 满足条件并回到撤离房 | 激活出口具有明确视觉焦点 |
| 26 | `room.exit.confirm` | 按 T 请求撤离 | 撤离确认层位于正确层级且可取消 |
| 27 | `protocol.level.5` | 新局默认协议 5 | 颜色、标题、压力信息不压框 |
| 28 | `protocol.level.4` | 通过真实房间推进到协议 4 | 只更新协议内容，不重排 HUD |
| 29 | `protocol.level.3` | 推进到协议 3 | 风险层级差异可辨认 |
| 30 | `protocol.level.2` | 推进到协议 2 | 警戒色不污染整个房间 |
| 31 | `protocol.level.1` | 推进到协议 1 | 最高风险仍保持文字可读与紧凑高度 |
| 32 | `map.overview` | 按 M 打开生产地图 | 全屏暗幕、10×10 大网格、标题/提示完整 |
| 33 | `map.cell_selected` | 左键选择未知格 | 选中边框与详情层级明确 |
| 34 | `map.marked` | 对未知格执行标记/取消 | 标记状态与未知格、当前格可区分 |
| 35 | `map.return_available` | 诊断 Reveal Full Map 后选择已探索格 | 回传提示可读；M、Esc、右键均可关闭 |
| 36 | `inventory.empty` | 空包按 Q | 空态图标/说明有意图，不伪造物品 |
| 37 | `inventory.populated` | 诊断 Spawn Backpack Item 后按 Q | 使用真实物品图标、名称与容量 |
| 38 | `inventory.selected` | 点击真实物品行 | 选中层级与普通行不同 |
| 39 | `inventory.full` | 播种到真实容量上限后按 Q | 满载/禁用状态不依赖假槽位 |
| 40 | `inventory.tooltip` | 悬停真实物品 | 详情不漂浮出框、不遮住关键操作 |
| 41 | `loot.floor_visible` | 诊断 Spawn Floor Item 后关闭诊断 | 地面实体直接可见 |
| 42 | `loot.context_nearby` | 移动进入物品交互半径 | 悬浮窗仅靠近时出现 |
| 43 | `loot.context_multi` | 同房播种多件物品并靠近 | 多件列表仍为世界上下文，不升级整屏模态 |
| 44 | `loot.pickup` | 在悬浮窗执行拾取 | 拾取飞行/短反馈与地面实体消失同步 |
| 45 | `loot.capacity_blocked` | 背包满载后靠近地面物并尝试拾取 | 容量阻塞清楚且不吞掉物品 |
| 46 | `loot.replace_select` | 容量阻塞后进入替换选择 | 新旧物品和操作后果可比较 |
| 47 | `loot.replace_confirm` | 确认替换 | 反馈、背包内容和地面剩余物一致 |
| 48 | `loot.context_hidden_after_leave` | 离开交互半径 | 悬浮窗自动隐藏，移动不中断 |
| 49 | `overlay.tutorial` | 诊断 Tutorial Run | 教学层位于生产 overlay，确认后可返回 |
| 50 | `overlay.event_choice` | 触发真实事件 | 事件选项使用玩家语言和一致按钮层级 |
| 51 | `overlay.pause` | 局内按 Esc | 暂停层紧凑；继续、设置、返回、放弃层级明确 |
| 52 | `overlay.extract_safe` | 安全条件下按 T | 收益/背包/遗留摘要完整，可确认/取消 |
| 53 | `overlay.extract_risky` | 高风险协议下按 T | 危险强调明确但不改变控件位置 |
| 54 | `result.success` | 诊断 Force Extract Success，关闭诊断 | 380 内容列、300×130 横幅、两个等宽操作 |
| 55 | `result.failure_salvage_select` | 携带可保全物后诊断 Force Fail | 失败保全为独立前置态，候选/容量/确认完整 |
| 56 | `result.failure_salvage_selected` | 勾选一件可保全物 | 已选状态、重量与容量同步 |
| 57 | `result.failure_salvage_capacity_blocked` | 选择超过真实保全容量 | 超重项禁用或阻塞原因清楚 |
| 58 | `result.failure` | 完成失败保全确认 | 窄版失败报告、主横幅、两个操作 |
| 59 | `result.abandoned` | 暂停层主动放弃并二次确认 | 放弃与失败/成功风格可区分，控件位置不漂移 |
| 60 | `motion.full` | 默认动效，执行移动、攻击、受击、拾取、开箱 | 玩家四步移动、四阶段攻击及其他关键动效连续 |
| 61 | `motion.reduced` | 诊断 Toggle Reduced Motion 后重复同一路线 | 信息不丢失、布局不变、无强烈闪烁或输入锁死 |

## 审计证据记录

- 每项至少保留 Computer Use 的新鲜窗口观察；瞬时动画状态需在同一生产流程中观察多个时点。
- 代码门记录对应探针输出；代码门不能替代实机 PASS。
- 最终结果统一写入 `ART24R2_FINAL_COMPUTER_USE_RESULTS.md`，并包含失败项、返工轮次和复验结论。
