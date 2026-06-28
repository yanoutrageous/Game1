# ART-14 Visual Key and Asset ID Requirements

## 0. 命名原则

- `visual_key` 描述 UI 语义，不绑定路径。
- `asset_id` 必须对应 manifest-backed runtime asset。
- `animation_key` 描述行为，不绑定具体帧文件。
- `fallback_asset_id` 必须已有或明确列入 ART-15 补齐。
- UI 不拼接 `res://`，不直接读取 Base Art / Draw。

## 1. 命名模式

| kind | pattern | example |
| --- | --- | --- |
| visual_key | `visual.<domain>.<surface>.<semantic>` | `visual.minimap.tile_state` |
| asset_id | `<domain>.<surface>.<role>[.<variant>]` | `ui.minimap.tile.unknown` |
| animation_key | `anim.<domain>.<surface>.<action>` | `anim.map.tile.reveal` |
| fallback_asset_id | same asset id namespace | `ui.common.button.dark` |

## 2. Key / ID requirements

| ui_position | layer | asset_need | visual_key | asset_id_pattern | animation_key | fallback_asset_id | state_variants | priority | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 主菜单 | background_static | 基地门厅背景 | `visual.main_menu.background.base_hall` | `ui.main_menu.bg.*` | `anim.main_menu.enter` | `ui.main_menu.bg_base_hall_placeholder` | default | P0 | 不使用整屏确定稿 |
| 主菜单 | button_layer | 四大入口按钮 | `visual.main_menu.entry_button` | `ui.main_menu.entry_button.*` | `anim.button.entry.hover` | `ui.common.button.dark` | normal, hover, selected, disabled | P0 | 固定入口 |
| 主菜单 | state_badge_layer | 红点/公告提示 | `visual.main_menu.notice_badge` | `ui.common.badge.*` | `anim.badge.red_dot.ping` | `ui.common.badge.new` | new, warning, claim | P1 | 不显示资源数 |
| 出发探索总页 | background_static | 出勤大厅背景 | `visual.deploy.background.control_room` | `ui.deploy.bg.*` | `anim.deploy.page.enter` | `ui.deploy.panel.main` | default, map_theme | P0 | 左角色 + 中卡 + 右摘要 |
| 出发探索-地图页 | item_card_layer | 地图模式卡 | `visual.deploy.map_card` | `ui.deploy.map_card.*` | `anim.deploy.map_card.select` | `ui.deploy.panel.card` | normal, selected, locked, recommended | P0 | 不提前显示真实地图 |
| 出发探索-仓库页 | slot_layer | 出勤槽 | `visual.deploy.loadout_slot` | `ui.deploy.slot.*` | `anim.deploy.item.add_to_loadout` | `ui.deploy.slot.empty` | empty, filled, blocked | P0 | 装备/消耗品 |
| 出发探索-申领页 | item_card_layer | 申领物资卡 | `visual.deploy.requisition_card` | `ui.deploy.requisition_card.*` | `anim.deploy.requisition.claim` | `ui.deploy.panel.card` | affordable, locked, recommended | P1 | 购买/领取/合法出售 |
| 出发探索-目标页 | state_badge_layer | 目标适配 badge | `visual.deploy.objective_badge` | `ui.deploy.objective_badge.*` | `anim.deploy.objective.invalid` | `ui.common.badge.warning` | matched, blocked, reward | P1 | 单局目标 |
| 长期系统总页 | background_static | 档案室背景 | `visual.long_term.background.archive_room` | `ui.long_term.bg.*` | `anim.long_term.module.switch` | `ui.long_term.bg_archive_placeholder` | default | P0 | 档案/图鉴墙 |
| 长期系统-图鉴 | item_card_layer | 图鉴卡 | `visual.long_term.codex_card` | `ui.long_term.codex_card.*` | `anim.codex.discovery.reveal` | `ui.common.card.locked` | hidden, discovered, owned, completed | P0 | 未发现不可泄露 |
| 局内 HUD | panel_base | HUD 面板组 | `visual.hud.panels` | `ui.hud.panel.*` | `anim.run.key.press` | `ui.hud.panel.protocol` | normal, warning, danger | P0 | 现有可复用 |
| 局内 HUD | button_layer | 底部 key bar | `visual.hud.key_bar` | `ui.hud.key_bar.*` | `anim.run.key.press` | `ui.hud.bottom_bar` | normal, pressed, disabled | P0 | WASD/M/F/E/T/Q/Esc |
| 小地图 MiniMap | map_tile | 地图格状态 | `visual.minimap.tile_state` | `ui.minimap.tile.*` | `anim.map.tile.reveal` | `ui.minimap.tile.unknown` | unknown, scanned, explored, cleared, polluted, danger | P0 | 32/64 双规格 |
| 小地图 MiniMap | map_marker | 地图标记 | `visual.minimap.markers` | `ui.minimap.marker.*` | `anim.map.marker.toggle` | `ui.minimap.marker.unknown` | player, flag, mine, monster, chest, event, exit, extract, number | P0 | 数字 1-8 需补全 |
| 展开地图 MapOverlay | panel_base | 大地图框 | `visual.map_overlay.frame` | `ui.map_overlay.frame.*` | `anim.map_overlay.open` | `ui.common.modal_panel` | normal, selected | P0 | 大格可读 |
| 房间主视图 | room_background | 房型背景 | `visual.room.background.*` | `room.background.*` | `anim.run.room.enter_fade` | `room.background.normal` | normal, mine, chest, event, monster, exit, merchant | P0 | 已有部分 |
| 房间主视图 | character_or_actor | 玩家角色 | `visual.room.player_actor` | `sprite.player.*` | `anim.actor.player.idle` | `sprite.player.default` | idle, walk, hit | P0 | Draw character frames 可裁切 |
| 雷房 | prop_or_event_object | 雷陷阱 | `visual.room.mine_trap` | `prop.mine.trap.*` | `anim.room.mine.trigger` | `prop.mine.trap` | hidden, revealed, triggered | P0 | 避免提前泄露 |
| 宝箱房 | prop_or_event_object | 宝箱 | `visual.room.chest` | `prop.chest.*` | `anim.room.chest.open` | `prop.chest.closed` | closed, open, empty, locked | P0 | 需 open/empty |
| 事件房 | prop_or_event_object | 事件物 | `visual.room.event_object` | `prop.event.*` | `anim.room.event.trigger` | `prop.event.anomaly_core` | idle, active, resolved | P1 | 事件池后续 |
| 怪物 / 战斗房 | monster_or_enemy | 怪物 | `visual.combat.monster.basic` | `sprite.monster.*` | `anim.combat.monster.appear` | `sprite.monster.placeholder` | idle, attack, hit, defeated | P1 | 需新生图 |
| 商人 / 回收终端 | prop_or_event_object | 商人台/终端 | `visual.room.trade_terminal` | `prop.trade.*` | `anim.trade.confirm` | `prop.recycler.terminal` | inactive, active, trade | P1 | 安全收益 |
| 撤离点 | prop_or_event_object | 撤离装置 | `visual.room.extract_beacon` | `prop.extract.beacon.*` | `anim.extract.beacon.activate` | `prop.extract.beacon.inactive` | inactive, active, confirmed | P0 | P0 |
| 搜索反馈 | feedback_overlay | 搜索状态 | `visual.feedback.search` | `ui.feedback.search.*` | `anim.room.search.progress` | `ui.common.toast` | progress, success, empty, blocked | P0 | 不显示 reason code |
| GroundLoot | item_card_layer | 地面物品卡 | `visual.item.ground_loot_card` | `ui.ground_loot.card.*` | `anim.item.pickup.fly_to_bag` | `ui.common.card.item` | normal, selected, blocked | P0 | M3 |
| Inventory | item_card_layer | 背包卡 | `visual.item.inventory_card` | `ui.inventory.item_card.*` | `anim.item.drop_to_ground` | `ui.common.card.item` | normal, selected, full, blocked | P0 | M3 |
| Item Tooltip | tooltip_layer | tooltip | `visual.item.tooltip` | `ui.item.tooltip_panel.*` | `anim.tooltip.appear` | `ui.common.tooltip_panel` | normal, warning, unique | P0 | 不显示 instance_id |
| 物品确认 | modal_overlay | 物品确认弹窗 | `visual.item.confirm` | `ui.item.confirm_modal.*` | `anim.item.replace.confirm` | `ui.common.modal_panel` | pickup, drop, replace, use | P0 | M3 |
| 背包满 / 重量不足提示 | feedback_overlay | 容量阻塞 | `visual.feedback.capacity_blocked` | `ui.feedback.capacity_blocked.*` | `anim.warning.capacity.flash` | `ui.common.toast.warning` | full, overweight, blocked | P0 | M3 |
| 撤离确认 | modal_overlay | 撤离确认 | `visual.extract.confirm` | `ui.extract.confirm_modal.*` | `anim.extract.confirm` | `ui.common.modal_panel` | safe, risky, blocked | P0 | 结算前 |
| 失败 / 放弃确认 | modal_overlay | 损失确认 | `visual.run_end.loss_confirm` | `ui.run_end.loss_confirm.*` | `anim.run_end.abandon.confirm` | `ui.common.modal_panel.danger` | fail, abandon | P0 | 非成功 |
| 本局结算报告 | settlement_panel | 结算报告 | `visual.settlement.report` | `ui.settlement.report.*` | `anim.settlement.success.banner` | `ui.common.modal_panel` | success, failed, abandoned, special | P0 | 必须成套 |
| 历史战绩列表 | item_card_layer | 战绩列表 | `visual.history.list` | `ui.history.row.*` | `anim.history.filter.switch` | `ui.common.card` | success, failed, abandoned | P1 | 长期系统 |
| 历史战绩详情 | panel_base | 战绩详情 | `visual.history.detail` | `ui.history.detail_panel.*` | `anim.history.detail.open` | `ui.common.modal_panel` | normal | P1 | 快照 |
| 设置 | panel_base | 设置控件 | `visual.settings.controls` | `ui.settings.control.*` | `anim.settings.control.change` | `ui.common.button.dark` | normal, selected, disabled | P1 | reduce motion |
| 暂停菜单 | modal_overlay | 暂停菜单 | `visual.pause.menu` | `ui.pause.menu_panel.*` | `anim.pause.open` | `ui.common.modal_panel` | normal, danger | P0 | 局内 |
| 通用弹窗 | modal_overlay | 通用弹窗 | `visual.common.modal` | `ui.common.modal_panel.*` | `anim.modal.open_close` | `ui.common.modal_panel` | normal, danger, reward | P0 | 全局 |
| toast / notice / warning | feedback_overlay | toast | `visual.common.toast` | `ui.common.toast.*` | `anim.toast.show` | `ui.common.toast.info` | info, success, warning, danger, reward | P0 | 全局 |
| 红点 / 角标 | state_badge_layer | badge | `visual.common.badge` | `ui.common.badge.*` | `anim.badge.red_dot.ping` | `ui.common.badge.new` | new, claim, warning, locked | P1 | 全局 |
| Debug UI dev-only | debug_dev_only | dev overlay | `visual.dev.debug_overlay` | `dev.debug.overlay.*` | none | none | dev_only | dev_only | 不进玩家 UI |

## 3. fallback 策略

- P0 UI 面板可以暂用 `ui.common.button.dark`、`ui.hud.panel.*`、`ui.common.modal_panel` 类通用资产，但 ART-15 需要登记为 fallback，而不是最终美术。
- 地图和房间类 P0 不应长期使用纯色块；至少需要 tile / marker / room background / prop 的 manifest-backed 资产。
- 未发现内容应使用 silhouette / question / locked，而不是空白或 debug 文本。
