# ART-14 Motion and Feedback Requirements

## 0. 定位

本文件只定义动效与反馈需求，不实现动画、不导入序列帧。

统一要求：

- 所有动效必须有 reduce motion fallback。
- 动效不得改变玩法规则或隐藏必要信息。
- 阻塞反馈必须显示玩家文案，不显示内部 reason code。

## 1. 动效需求表

| ui_position | trigger | animation_key | visual_intent | duration | required_asset | fallback | reduce_motion | priority |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 主菜单 | 页面进入 | `anim.main_menu.enter` | 基地界面淡入，角色站位稳定 | 300-600ms | background + character | instant show | required | P1 |
| 主菜单 | 大按钮 hover / selected | `anim.button.entry.hover` | 明确当前入口 | 80-160ms | button states | color state | required | P0 |
| 主菜单 | 红点新增 | `anim.badge.new.ping` | 提醒有新内容 | 600-1000ms loop limited | badge | static red dot | required | P1 |
| 出发探索总页 | tab switch | `anim.deploy.tab.switch` | 页签切换不迷路 | 160-240ms | tab states | instant switch | required | P0 |
| 出发探索-地图页 | 地图卡 selected | `anim.deploy.map_card.select` | 反馈选择地图模式 | 120-220ms | card selected glow | selected frame | required | P0 |
| 出发探索-地图页 | locked click | `anim.deploy.locked.shake` | 告知未解锁 | 160-220ms | locked badge | warning toast | required | P1 |
| 出发探索-仓库页 | 加入出勤 | `anim.deploy.item.add_to_loadout` | 物品进入出勤槽 | 200-400ms | item icon + slot | slot highlight | required | P0 |
| 出发探索-仓库页 | 移除出勤 | `anim.deploy.item.remove_from_loadout` | 物品退出出勤槽 | 160-300ms | item icon | slot blink | required | P0 |
| 出发探索-申领页 | 购买 / 领取成功 | `anim.deploy.requisition.claim` | 资产事件完成 | 220-400ms | reward badge | toast | required | P1 |
| 出发探索-目标页 | 目标匹配失败 | `anim.deploy.objective.invalid` | 告知当前配置不满足 | 160-240ms | warning badge | static warning | required | P1 |
| 出发探索-出勤配置页 | 开始探索 ready | `anim.deploy.start.ready_pulse` | 主按钮可执行 | 800-1400ms subtle loop | primary button state | static ready state | required | P0 |
| 出发探索-出勤配置页 | 配置阻塞 | `anim.deploy.config.blocked` | 指向阻塞原因 | 160-240ms | warning badge | warning toast | required | P0 |
| 长期系统总页 | 模块切换 | `anim.long_term.module.switch` | 档案模块切换 | 180-300ms | cards/panels | instant switch | required | P1 |
| 长期系统-图鉴 | 首次发现 | `anim.codex.discovery.reveal` | 从问号到发现态 | 400-800ms | silhouette/card states | static discovered | required | P1 |
| 长期系统-研究 | 研究完成 | `anim.research.unlock` | 显示解锁路径 | 400-800ms | node + connector | completed badge | required | P2 |
| 局内 HUD | 进入房间 | `anim.run.room.enter_fade` | 房间切换确认 | 180-320ms | transition mask | instant room state | required | P0 |
| 局内 HUD | key press | `anim.run.key.press` | 底部操作反馈 | 80-140ms | key button states | pressed color | required | P0 |
| 小地图 MiniMap | tile reveal | `anim.map.tile.reveal` | 扫描 / 探索信息公开 | 120-220ms | tile states | snap reveal | required | P0 |
| 小地图 MiniMap | scan pulse | `anim.map.scan.pulse` | 扫描器工作感 | 500-900ms | scan overlay | static scan badge | required | P0 |
| 小地图 MiniMap | danger ping | `anim.map.danger.ping` | 高危格提示 | 400-700ms | danger marker | red marker | required | P0 |
| 展开地图 MapOverlay | open / close | `anim.map_overlay.open` | 大地图弹层进入 | 160-240ms | modal dim / frame | instant open | required | P0 |
| 展开地图 MapOverlay | tile selected | `anim.map_overlay.tile.select` | 当前格子选择 | 80-140ms | selection frame | static selection | required | P0 |
| 展开地图 MapOverlay | marker place/remove | `anim.map.marker.toggle` | 标记操作反馈 | 120-200ms | marker states | marker appears | required | P0 |
| 房间主视图 | room object idle | `anim.room.object.idle` | 房间对象可交互暗示 | 800-1600ms subtle | prop sprite states | static prop | required | P1 |
| 普通房 | search progress | `anim.room.search.progress` | 搜索需要时间感 | 400-900ms | progress bar | instant result | required | P0 |
| 普通房 | search success | `anim.room.search.success` | 找到掉落 / 收益 | 300-600ms | reward popup | success toast | required | P0 |
| 普通房 | search empty | `anim.room.search.empty` | 已耗尽 | 180-300ms | empty badge | empty text | required | P0 |
| 雷房 | mine triggered | `anim.room.mine.trigger` | 风险触发 | 300-700ms | mine fx / warning | red flash badge | required | P0 |
| 雷房 | pollution flicker | `anim.room.pollution.flicker` | 污染 / 异常区域 | 800-1400ms | pollution overlay | static purple/green badge | required | P1 |
| 宝箱房 | chest open | `anim.room.chest.open` | 箱子开启 | 300-600ms | chest frames | open sprite swap | required | P0 |
| 事件房 | event trigger | `anim.room.event.trigger` | 事件被激活 | 240-500ms | event object fx | modal open | required | P1 |
| 怪物 / 战斗房 | monster appear | `anim.combat.monster.appear` | 战斗开始 | 300-600ms | monster sprite | monster show | required | P1 |
| 怪物 / 战斗房 | skill warning | `anim.combat.skill.warning` | 技能预警 | 600-1000ms | warning marker | warning icon | required | P1 |
| 怪物 / 战斗房 | player hit | `anim.combat.player.hit` | 玩家受击 | 120-220ms | hit fx | HP flash | required | P1 |
| 怪物 / 战斗房 | monster hit | `anim.combat.monster.hit` | 怪物受击 | 120-220ms | hit fx | HP flash | required | P1 |
| 怪物 / 战斗房 | defeat / clear room | `anim.combat.clear_room` | 房间清理完成 | 300-700ms | clear badge / reward | clear badge | required | P1 |
| 商人 / 回收终端 | transaction confirm | `anim.trade.confirm` | 安全收益锁定 | 240-500ms | safe yield icon | toast | required | P1 |
| 撤离点 | exit beacon activate | `anim.extract.beacon.activate` | 撤离可用 | 600-1200ms pulse | beacon on/off | static active beacon | required | P0 |
| 撤离确认 | extraction confirm | `anim.extract.confirm` | 即将结束本局 | 300-600ms | transition mask | instant transition | required | P0 |
| GroundLoot | pickup fly-to-bag | `anim.item.pickup.fly_to_bag` | 地面物进入背包 | 300-600ms | item icon | toast + card removed | required | P0 |
| GroundLoot | capacity blocked | `anim.item.capacity.blocked` | 容量不足 | 160-240ms | warning badge | red static badge | required | P0 |
| Inventory | drop-to-ground | `anim.item.drop_to_ground` | 背包物离开 | 240-420ms | item icon | toast | required | P0 |
| Inventory | item use | `anim.item.use` | 消耗品生效 | 220-420ms | effect icon | effect toast | required | P0 |
| Item Tooltip | tooltip appear | `anim.tooltip.appear` | 物品详情出现 | 80-160ms | tooltip panel | instant show | required | P0 |
| 物品确认 | replace item confirm | `anim.item.replace.confirm` | 取舍明确 | 160-260ms | comparison arrows | modal state | required | P0 |
| 背包满 / 重量不足提示 | warning flash | `anim.warning.capacity.flash` | 阻塞原因醒目 | 240-400ms | warning toast | static warning | required | P0 |
| 本局结算报告 | success banner | `anim.settlement.success.banner` | 撤离成功 | 400-800ms | success banner | static banner | required | P0 |
| 本局结算报告 | failure banner | `anim.settlement.failure.banner` | 失败/放弃 | 400-800ms | failure banner | static banner | required | P0 |
| 本局结算报告 | black coin to gold | `anim.settlement.currency.convert` | 收益转化 | 600-1200ms | coin icons | final values | required | P0 |
| 本局结算报告 | item kept/lost | `anim.settlement.item.resolve` | 物品保留/丢失 | 300-600ms | item card states | kept/lost badge | required | P0 |
| 历史战绩列表 | filter switch | `anim.history.filter.switch` | 筛选响应 | 120-200ms | tab states | instant switch | required | P1 |
| 设置 | toggle/slider feedback | `anim.settings.control.change` | 设置变更反馈 | 80-160ms | control states | state change only | required | P1 |
| 暂停菜单 | modal dim | `anim.pause.open` | 局内暂停 | 120-240ms | dim overlay | instant dim | required | P0 |
| 通用弹窗 | modal open/close | `anim.modal.open_close` | 统一弹层感 | 120-220ms | modal panel | instant | required | P0 |
| toast / notice / warning | toast stack | `anim.toast.show` | 短反馈 | 120-220ms + 2-4s hold | toast panel | instant + timed hide | required | P0 |
| 红点 / 角标 | red dot ping | `anim.badge.red_dot.ping` | 新内容提示 | 600-1000ms limited | badge | static badge | required | P1 |

## 2. reduce motion 总规则

- 必须支持关闭循环闪烁、背景运动、长位移动画。
- 关闭后仍要保留状态颜色、badge、toast、静态图标。
- P0 阻塞反馈不能只靠动效表达，必须有文字或图标状态。
