# ART-14 Art Asset Need Matrix

## 0. 定位

本文件列出 ART-15 之前需要准备的美术素材需求。它不复制、不移动、不导入素材。

处理类型：

```text
direct_reuse = 已在 Godot runtime 或 staged 候选中可复用，仍需 ART-15 审计导入
crop = 需要从候选图裁切
redraw = 需要重绘或按规格重做
generate = 需要新生图
reference_only = 只能参考，不可 runtime 导入
defer = 暂缓
forbidden = 禁止直接导入
```

## 1. P0 需求矩阵

| ui_position | layer | asset_type | asset_need | size_or_ratio | transparent | nine_slice | state_variants | animation_frames | candidate_source | existing_asset_id | proposed_asset_id | visual_key | priority | handling |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 主菜单 | background_static | background | 基地门厅 / 回收站主背景，不带文字 | 16:9, 1920x1080 source | no | no | day/default | optional | Base Art Base / Draw main_menu | none or `ui.main_menu.bg` if accepted | `ui.main_menu.bg_base_hall` | `visual.main_menu.background.base_hall` | P0 | redraw |
| 主菜单 | character_or_actor | character_sprite / portrait | 当前角色展示层 / 剪影 | 512-768 height | yes | no | idle, selected | 2-4 idle optional | Draw characters | player sprite partial | `sprite.main_menu.operator.default` | `visual.main_menu.operator_showcase` | P0 | crop |
| 主菜单 | button_layer | button | 四个大入口按钮 | large 360x96 source | yes | yes | normal, hover, selected, disabled | no | Base confirmed UI | deploy buttons partial | `ui.main_menu.entry_button.large` | `visual.main_menu.entry_button` | P0 | redraw |
| 主菜单 | panel_base | panel | 公告牌 / 短讯框 | 520x160 source | yes | yes | normal, muted | no | Base confirmed UI | none | `ui.main_menu.notice_board` | `visual.main_menu.notice` | P1 | redraw |
| 出发探索总页 | background_static | background | 地图控制台 / 出勤大厅背景 | 16:9 | no | no | map_theme variants | optional | Base confirmed UI | none | `ui.deploy.bg_control_room` | `visual.deploy.background.control_room` | P0 | redraw |
| 出发探索-地图页 | item_card_layer | card | 地图模式卡 | 360x120 | yes | yes | normal, hover, selected, locked, recommended | no | Base / existing deploy panels | `ui.deploy.panel.*` partial | `ui.deploy.map_mode_card` | `visual.deploy.map_card` | P0 | redraw |
| 出发探索-仓库页 | slot/icon_layer | slot/icon | 出勤装备 / 消耗品槽 | 64 / 96 square | yes | yes | empty, filled, blocked, warning | no | Godot assets/ui/deploy/icons | `ui.deploy.icon.*` partial | `ui.deploy.loadout_slot` | `visual.deploy.loadout_slot` | P0 | direct_reuse + redraw |
| 出发探索-申领页 | item_card_layer | card | 申领 / 购买物资卡 | 320x100 | yes | yes | affordable, locked, recommended | no | deploy panels | none | `ui.deploy.requisition_card` | `visual.deploy.requisition_card` | P1 | redraw |
| 出发探索-目标页 | state_badge_layer | badge | 目标适配 / 失败条件 / 奖励标签 | 128x32 | yes | yes | matched, blocked, reward, danger | no | UI panels | none | `ui.deploy.objective_badge` | `visual.deploy.objective_badge` | P1 | redraw |
| 出发探索-出勤配置页 | button_layer | button | 开始 / 继续 / 放弃主按钮 | 420x92 | yes | yes | ready, blocked, warning | 2 pulse optional | Base confirmed UI / deploy button | `ui_button_confirm_deploy_large` staged | `ui.deploy.primary_action.large` | `visual.deploy.primary_action` | P0 | crop/redraw |
| 长期系统总页 | background_static | background | 档案室 / 图鉴墙背景 | 16:9 | no | no | default | optional | Base long-term confirmed | none | `ui.long_term.bg_archive_room` | `visual.long_term.background.archive_room` | P0 | redraw |
| 长期系统-图鉴 | item_card_layer | card | 图鉴卡 / 问号轮廓 / 锁定态 | 180x220 | yes | yes | hidden, discovered, owned, completed, new | reveal optional | Base long-term confirmed | none | `ui.long_term.codex_card` | `visual.long_term.codex_card` | P0 | redraw |
| 长期系统-个人资历 / 历史战绩 | history_thumbnail | thumbnail | 战绩缩略图框 / 结果 badge | 240x120 + badge | yes | yes | success, failed, abandoned | no | none | none | `ui.history.run_thumbnail_frame` | `visual.history.thumbnail` | P1 | generate |
| 局内 HUD | panel_base | panel | 左扫描器、右状态、底部 key bar 面板 | 320x720 / 300x240 / 1280x72 | yes | yes | normal, warning, danger | no | Godot assets/ui/hud | `ui.hud.panel.left`, `ui.hud.panel.protocol`, `ui.hud.bottom_bar` | keep existing + `ui.hud.panel.compact_status` | `visual.hud.panels` | P0 | direct_reuse + redraw |
| 小地图 MiniMap | map_tile | map_tile | 未知、已扫、已探索、已清理、污染、高危格 | 32/64 square | yes | no | unknown, scanned, explored, cleared, polluted, danger | reveal optional | Draw icons / Godot minimap | `icon.minimap.*` | `ui.minimap.tile.state_set` | `visual.minimap.tile_state` | P0 | direct_reuse + redraw |
| 小地图 MiniMap | map_marker | icon | 当前、旗标、撤离、事件、怪物、宝箱、雷、数字 1-8 | 32/64 | yes | no | normal, selected, warning | pulse optional | Draw icons / Godot minimap | `icon.room.*`, `icon.minimap.number.*` | `ui.minimap.marker.full_set` | `visual.minimap.markers` | P0 | direct_reuse + crop |
| 展开地图 MapOverlay | panel_base | panel | 大地图外框、格子详情、操作按钮 | 900x620 layout source | yes | yes | normal, selected | no | ART-13 map reference | partial | `ui.map_overlay.frame` | `visual.map_overlay.frame` | P0 | redraw |
| 房间主视图 | room_background | room_background | 普通/雷/宝箱/事件/怪物/撤离房背景 | 1024 square or 16:9 room plane | no | no | room_type variants | subtle idle optional | Godot rooms / Draw rooms | `room.background.*` | keep + `room.background.merchant` | `visual.room.background.*` | P0 | direct_reuse + generate |
| 房间主视图 | character_or_actor | character_sprite | 玩家 4 向 idle/walk | 64-128 frame | yes | no | idle, walk, hit | 2-4 frames | Draw characters | `sprite.player.*` partial | `sprite.player.operator.sheet` | `visual.room.player_actor` | P0 | crop |
| 雷房 | prop_or_event_object | room_prop | 雷陷阱 / 危险标记 | 128-256 | yes | no | hidden, revealed, triggered | 3-6 optional | Godot props / Draw props | `prop.mine.trap` | keep + `prop.mine.trap.triggered` | `visual.room.mine_trap` | P0 | direct_reuse + redraw |
| 宝箱房 | prop_or_event_object | chest | 宝箱关闭 / 打开 / 空 | 160-256 | yes | no | closed, open, empty, locked | 3-6 open optional | Godot props / Draw props | `prop.chest.closed` | `prop.chest.open`, `prop.chest.empty` | `visual.room.chest` | P0 | direct_reuse + crop |
| 事件房 | prop_or_event_object | event_object | 事件核心、祭坛、异常物 | 160-256 | yes | no | idle, active, resolved | optional | Base Art / Draw props | staged `yichang_hexin` | `prop.event.anomaly_core` | `visual.room.event_object` | P1 | crop/redraw |
| 怪物 / 战斗房 | monster_or_enemy | monster_sprite | 首批普通怪 / 精英怪占位 | 128-256 | yes | no | idle, attack, hit, defeated | required later | none / future gen | none | `sprite.monster.basic_01` | `visual.combat.monster.basic` | P1 | generate |
| 商人 / 回收终端 | prop_or_event_object | prop | 商人台 / 回收终端 明暗态 | 180-260 | yes | no | inactive, active, trade | optional | Draw props | staged merchant / terminal props | `prop.merchant.table`, `prop.recycler.terminal` | `visual.room.trade_terminal` | P1 | crop |
| 撤离点 | prop_or_event_object | exit_beacon | 撤离装置未激活 / 激活 | 180-260 | yes | no | inactive, active, confirmed | pulse optional | Draw props | staged exit device | `prop.extract.beacon` | `visual.room.extract_beacon` | P0 | crop/redraw |
| 搜索反馈 | feedback_overlay | effect_sprite / badge | 搜索进度、成功、空、失败 | 128 badge / 400 bar | yes | yes for bar | progress, success, empty, blocked | 4-8 optional | none | none | `ui.feedback.search_state` | `visual.feedback.search` | P0 | redraw |
| GroundLoot | item_card_layer | card / icon | 地面物品卡、稀有度、拾取按钮 | 340x80 card, 48 icon | yes | yes | normal, selected, blocked | pickup optional | Godot item assets | item icons partial | `ui.ground_loot.card`, `ui.item.rarity_badge` | `visual.item.ground_loot_card` | P0 | redraw |
| Inventory | item_card_layer | card / panel | 背包物品卡、容量条、使用 / 丢弃按钮 | 380x72 / bar 220x24 | yes | yes | normal, selected, full, blocked | select optional | Godot item assets | item icons partial | `ui.inventory.item_card`, `ui.inventory.capacity_bar` | `visual.item.inventory_card` | P0 | redraw |
| Item Tooltip | tooltip_panel | tooltip_panel | 物品详情框、效果图标、标签 | 360x180 | yes | yes | normal, warning, unique | fade optional | UI panels | none | `ui.item.tooltip_panel` | `visual.item.tooltip` | P0 | redraw |
| 物品确认 | modal_panel | modal / comparison | 拾取、丢弃、替换、使用确认 | 560x320 | yes | yes | pickup, drop, replace, use | no | none | none | `ui.item.confirm_modal` | `visual.item.confirm` | P0 | redraw |
| 背包满 / 重量不足提示 | feedback_overlay | warning badge / capacity bar | 容量阻塞提示 | 420x80 toast | yes | yes | full, overweight, blocked | shake optional | none | none | `ui.feedback.capacity_blocked` | `visual.feedback.capacity_blocked` | P0 | redraw |
| 撤离确认 | modal_panel | modal / summary panel | 撤离收益确认 | 640x420 | yes | yes | safe, risky, blocked | transition optional | none | none | `ui.extract.confirm_modal` | `visual.extract.confirm` | P0 | redraw |
| 失败 / 放弃确认 | modal_panel | modal / warning banner | 损失与抢救预览 | 640x420 | yes | yes | fail, abandon | warning pulse optional | none | none | `ui.run_end.abandon_fail_modal` | `visual.run_end.loss_confirm` | P0 | redraw |
| 本局结算报告 | settlement_panel | banner / rows / item sections | 成功、失败、放弃报告 | 1280x720 responsive | mixed | yes | success, failed, abandoned, special | count-up optional | none | none | `ui.settlement.report_panel` | `visual.settlement.report` | P0 | generate/redraw |
| 暂停菜单 | modal_panel | pause panel / button | 暂停、继续、设置、放弃 | 420x420 | yes | yes | normal, warning | fade optional | common panels | none | `ui.pause.menu_panel` | `visual.pause.menu` | P0 | redraw |
| 通用弹窗 | modal_panel | modal panel | 通用确认 / 详情 | 560x320 scalable | yes | yes | normal, danger, reward | fade optional | common panels | partial | `ui.common.modal_panel` | `visual.common.modal` | P0 | redraw |
| toast / notice / warning | feedback_overlay | toast panel | 短反馈 / warning | 420x64 | yes | yes | info, success, warning, danger, reward | 2-4 optional | none | none | `ui.common.toast` | `visual.common.toast` | P0 | redraw |
| 红点 / 角标 | badge | badge | 新增、可领取、警告、锁定 | 24-48 | yes | no | new, claim, warning, locked | ping optional | none | none | `ui.common.badge.state_set` | `visual.common.badge` | P1 | redraw |

## 2. P1 / P2 需求

| ui_position | asset_need | candidate_source | proposed_asset_id | priority | handling |
| --- | --- | --- | --- | --- | --- |
| 事件选择 | 事件选项卡、风险 / 奖励角标 | common modal + new icons | `ui.event.choice_card` | P1 | redraw |
| 战斗反馈 | 技能预警、受击、击败、清理特效 | new sprite/effect | `fx.combat.hit_set` | P1 | generate |
| 历史战绩列表 | 战绩缩略图、成功/失败/放弃 badge | settlement assets | `ui.history.result_badge_set` | P1 | redraw |
| 历史战绩详情 | 详情框、地图缩略图框、事件列表 | common panels | `ui.history.detail_panel` | P1 | redraw |
| 设置 | toggle、slider、segmented control | common UI | `ui.settings.control_set` | P1 | redraw |
| 长期系统-研究 | 研究节点、连线、完成态 | long-term reference | `ui.long_term.research_node` | P2 | generate |
| 长期系统-抽奖 | 抽奖按钮、奖池卡、结果展示 | long-term reference | `ui.long_term.gacha_panel` | P2 | defer |
| 长期系统-收藏 / 外观 | 外观卡、收藏状态、角色预览框 | long-term reference | `ui.long_term.collection_card` | P2 | defer |

## 3. 禁止直接导入清单

| source | reason | handling |
| --- | --- | --- |
| `Base Art\Base\*确定.png` | 整屏参考图，只能作为构图和视觉基准 | reference_only |
| `Base Art\ART-13` 整屏截图 | 局内参考图，不是 runtime 切片资产 | reference_only |
| `Base Art\M1\Lua demo.mp4` | 视频参考，不是 Godot runtime 素材 | reference_only |
| `Draw\30_game_ready\**\debug_detected_boxes.png` | 检测调试图，不是美术资产 | forbidden |
| 任何 `.uasset` | Godot runtime 不直接使用 | forbidden |

## 4. ART-15 P0 建议

优先导入 / 处理顺序：

1. MiniMap / MapOverlay tile + marker full set。
2. HUD panel + key prompt + feedback toast state set。
3. Room backgrounds + room props for normal / mine / chest / exit。
4. Inventory / GroundLoot item cards + tooltip + capacity blocked feedback。
5. Settlement report success / fail / abandon panels。

## 5. 代码与图片事实校正

本矩阵的优先级需要结合当前 Godot 资产事实修正：

| area | already available in runtime | should not be repeated | remaining art need |
| --- | --- | --- | --- |
| MiniMap | `icon.minimap.player/unknown/explored/scanned/flag`、`icon.room.mine/monster/chest/extract/exit/cleared`、`icon.minimap.number.1/2/3`，实际文件均为 32x32 PNG | 不重复导入已有基础 tile / marker | number 4-8、selected ring、danger、polluted、unresolved、expanded map marker state |
| HUD | `ui.hud.panel.left`、`ui.hud.panel.protocol`、`ui.hud.bottom_bar`、`ui.hud.mine_risk_tag`、`ui.hud.bar.frame/warning` 已存在 | 不重复新制基础 HUD panel | search/blocked/reward toast、compact status card、warning state overlay、interaction affordance |
| Room backgrounds | `room.background.normal/mine/chest/event/monster/exit` 均存在，实际 1254x1254 | 不重复导入 normal/mine/chest/event/monster/exit 基础背景 | merchant/trade/special room、room object active/resolved state |
| Props | `prop.chest.closed`、`prop.mine.trap`、`prop.gold.pile`、`prop.art07.*` 已存在或候选充分 | 不重复导入 closed chest / mine trap / gold pile | open/empty chest、triggered mine、active extract、resolved event、merchant terminal state |
| Items | medkit、syringe、flashlight、goggles、ore 已在 runtime | 不重复基础 item icon | item card、rarity badge、capacity/weight feedback、pickup/drop/replace confirmation |
| Deploy UI | deploy buttons/icons/panels 已在 manifest，但 note 多为 not wired | 不先批量重画按钮 | 接线、状态变体、slot empty/filled/blocked/warning |
| Key prompt | e/esc/f/m/q/t prompt 已在 runtime | 不重复 keycap | 全局 key bar state、disabled/active/hold variants |
| Main menu | `ui.main_menu.background.no_text` 已存在 | 不把 Base 确定稿整屏直用 | entry button state、notice board、hero/operator showcase、badge |
| Player | 128x128 idle direction sprite 已存在 | 不把 Draw debug 图导入 | walk sheet、main menu / deploy showcase、hit / interact variants |

修正后的 ART-15 P0 不应是“补全全部图片”，而是：
1. 已有 asset 的接线 / semantic review。
2. 核心状态变体。
3. feedback / modal / card / badge 等 UI 可读性资产。
4. 少量房间对象和结算报告专用视觉。
