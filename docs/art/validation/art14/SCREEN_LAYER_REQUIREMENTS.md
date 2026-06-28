# ART-14 Screen Layer Requirements

## 0. 统一图层枚举

可用图层：

```text
background_static
background_motion
scene_midground
room_grid_or_map_layer
character_or_actor
monster_or_enemy
prop_or_event_object
interaction_hotspot
panel_base
panel_decoration
button_layer
icon_layer
item_card_layer
text_layer
state_badge_layer
resource_counter_layer
tooltip_layer
feedback_overlay
animation_fx
modal_overlay
transition_mask
debug_dev_only
```

禁止原则：

- 玩家主界面禁止 `debug_dev_only`。
- 出发探索禁止真实局内地图内容层。
- UI 禁止直接 runtime 读取 Base Art / Draw。
- 整屏参考图只能作为 `reference_only`，不能作为唯一 runtime 背景。

## 1. 图层需求表

| ui_position | required_layers | optional_layers | forbidden_layers | z_order | motion_allowed | reduce_motion_policy | notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 主菜单 | background_static, scene_midground, character_or_actor, panel_base, button_layer, text_layer, state_badge_layer | background_motion, red_dot badge, notice panel | debug_dev_only, room_grid_or_map_layer | bg < character < panels < buttons < text < badge | yes | background_motion off, button hover becomes color state | 不显示资源明细 |
| 出发探索总页 | background_static, character_or_actor, panel_base, tab/button_layer, item_card_layer, text_layer, state_badge_layer | background_motion, tooltip_layer | room_grid_or_map_layer true content, debug_dev_only | bg < character < panels < cards < buttons < tooltip | yes | tab motion can reduce to instant state | 五页签入口 |
| 出发探索-地图页 | panel_base, card_layer, icon_layer, state_badge_layer, text_layer, modal_overlay | background_static, map_mode decoration | true map layout, exit position, monster content | cards < detail < modal | yes | card selected glow static | 只显示参数和倾向 |
| 出发探索-仓库页 | panel_base, item_card_layer, slot/icon_layer, resource_counter_layer, tooltip_layer | modal_overlay | settlement_panel, history detail | list < tooltip < modal | yes | item add/remove fade only | 出勤视角 |
| 出发探索-申领页 | panel_base, item_card_layer, price/resource_counter_layer, state_badge_layer, modal_overlay | recommendation badge | inventory free sell all | cards < price < confirm | yes | purchase fx can become toast | 与仓库共资产流 |
| 出发探索-目标页 | panel_base, card_layer, badge_layer, reward icon, tooltip_layer | modal_overlay | long-term task full management | cards < detail < modal | yes | selected glow static | 单局目标 |
| 出发探索-出勤配置页 | panel_base, slot_layer, summary panel, button_layer, warning badge | background_motion | deep warehouse, settlement | summary < slots < primary button | yes | ready pulse off | 主按钮最强 |
| 长期系统总页 | background_static, scene_midground, profile panel, grid/card_layer, detail panel, text_layer | background_motion, red_dot | run HUD, deploy config | bg < profile < grid < detail < modal | yes | page transition fade only | 档案室 / 图鉴墙 |
| 长期系统-目标 | panel_base, card_layer, progress/resource_counter, reward badge | modal_overlay | run result recalculation | card < progress < reward | yes | progress anim can snap | 目标领取 |
| 长期系统-图鉴 | panel_base, grid/card, icon/silhouette, state_badge, detail panel | background_motion | undiscovered full reveal | grid < selected < detail | yes | reveal animation optional | 发现状态是核心 |
| 长期系统-研究 | panel_base, node/card, connector, requirement badge | animation_fx | direct run state write | tree < detail < modal | yes | route glow static | 研究未实现先占位 |
| 长期系统-个人资历 / 历史战绩 | profile panel, history list, badge, detail modal | chart/icon layer | reward recalculation | list < detail < modal | yes | count-up optional | 历史快照 |
| 长期系统-抽奖 | panel_base, reward card, button, result modal | animation_fx | main menu large embed | card < button < result | yes | reward reveal static fallback | deferred |
| 长期系统-收藏 / 外观 | preview, grid/card, badge, button | background_motion | inventory mutation | preview < grid < modal | yes | preview swap no tween | deferred |
| 局内 HUD | background_static, room_grid_or_map_layer, character_or_actor, panel_base, button_layer, icon_layer, text_layer, feedback_overlay | animation_fx, tooltip_layer | debug_dev_only | room < actor < panels < buttons < feedback | yes | all fx must have static state | left/middle/right/bottom |
| 小地图 MiniMap | room_grid_or_map_layer, marker/icon_layer, text/number_layer, state_badge | scan overlay | true unrevealed content, debug layer | tile < marker < number < selection | yes | scan pulse off, reveal snap | core gameplay |
| 展开地图 MapOverlay | modal_overlay, room_grid_or_map_layer, marker/icon_layer, detail panel, button_layer | transition_mask | TruthMap raw | dim < grid < detail < buttons | yes | open fade off | 大地图 |
| 房间主视图 | room_background, prop_or_event_object, character_or_actor, monster_or_enemy, interaction_hotspot, animation_fx | foreground decoration | full reference screenshot | bg < props < actors < fx < UI | yes | object idle off | central focus |
| 普通房 | room_background, character_or_actor, search hotspot, feedback_overlay | loot marker | monster layer unless encounter | bg < actor < hotspot < feedback | yes | search progress static bar | basic room |
| 雷房 | room_background, danger_marker, trap prop, feedback_overlay | pollution flicker | hidden mine before reveal | bg < trap < warning < fx | yes | warning flash -> static red badge | risk room |
| 宝箱房 | room_background, chest prop, interaction_hotspot, loot feedback | animation_fx | unique item normal drop unless special | bg < chest < fx < loot | yes | chest open single-frame | M3 source |
| 事件房 | room_background, event_object, choice modal, result toast | animation_fx | full event pool ids | object < modal < result | yes | event pulse static | P1 |
| 怪物 / 战斗房 | room_background, monster_or_enemy, hp/status, warning_fx, reward overlay | animation_fx | combat debug logs | monster < hp < warning < reward | yes | hit fx -> color flash | P1 |
| 商人 / 回收终端 | room_background, merchant/terminal prop, trade panel, safe_yield badge | modal_overlay | free inventory sell | prop < trade < confirm | yes | transaction fx -> toast | P1 |
| 撤离点 | room_background, exit beacon, confirm modal, transition_mask | animation_fx | extract outside exit | beacon < modal < transition | yes | beacon pulse static | P0 |
| 搜索反馈 | progress/feedback_overlay, icon_layer, text_layer | animation_fx | reason code | progress < result < toast | yes | progress instant, no shake | P0 |
| 事件选择 | modal_overlay, option cards, warning badge, button_layer | animation_fx | event internal id | dim < modal < cards < buttons | yes | modal fade off | P1 |
| 战斗反馈 | hp bar, hit fx, warning overlay, result toast | animation_fx | combat debug log | actors < fx < warning < result | yes | fx as icon state | P1 |
| GroundLoot | panel_base, item_card_layer, icon_layer, state_badge, button_layer | tooltip_layer | instance_id/source_path | panel < cards < tooltip | yes | pickup fx -> toast | P0 |
| Inventory | panel_base, item_card_layer, tooltip_layer, button_layer, resource_counter | modal_overlay | full warehouse management | panel < cards < tooltip < modal | yes | select glow static | P0 |
| Item Tooltip | tooltip_panel, icon_layer, text_layer, state_badge | comparison overlay | instance id, source path | tooltip above cards | yes | fade optional | P0 |
| 物品拾取 / 丢弃 / 替换 / 使用确认 | modal_overlay, item_card_layer, button_layer, feedback_overlay | comparison arrows | bypass capacity | dim < modal < buttons < result | yes | confirm fx -> static result | P0 |
| 背包满 / 重量不足提示 | warning toast, capacity bar, state_badge | shake fx | raw blocked code | normal UI < warning overlay | yes | shake disabled -> red badge | P0 |
| 撤离确认 | modal_overlay, reward/resource summary, button_layer, warning badge | transition_mask | non-exit extract | dim < modal < transition | yes | transition off | P0 |
| 失败 / 放弃确认 | modal_overlay, loss summary, salvage preview, warning badge | animation_fx | success styling | dim < modal < warning | yes | warning pulse static | P0 |
| 本局结算报告 | result banner, settlement_panel, item sections, resource counters, button_layer | count-up fx | warehouse management | banner < sections < buttons | yes | count-up snap to final | P0 |
| 历史战绩列表 | list/card, filter tab, thumbnail, result badge | chart layer | recalculation controls | list < filter < detail | yes | list slide off | P1 |
| 历史战绩详情 | detail panel, map thumbnail, event list, item summary | modal_overlay | current warehouse mutation | panel < detail < modal | yes | open fade off | P1 |
| 设置 | panel_base, tab/button, slider/toggle, text_layer | tooltip | gameplay state mutation | panel < controls < tooltip | yes | all motion optional | P1 |
| 暂停菜单 | modal_overlay, button stack, text_layer | background blur | result settlement | dim < menu < confirm | yes | dim only | P0 |
| 通用弹窗 | modal_overlay, panel_base, button_layer, text_layer | icon_layer | unmasked text over complex bg | dim < panel < text < buttons | yes | fade off | P0 |
| toast / notice / warning | feedback_overlay, icon_layer, text_layer, state_badge | animation_fx | backend codes | UI < toast stack | yes | duration no movement | P0 |
| 红点 / 角标 | state_badge_layer, icon_layer | animation_fx | resource numbers on main menu | base UI < badge | yes | ping off | P1 |
| Debug UI dev-only | debug_dev_only | none | player runtime surface | debug only above dev overlay | dev only | not applicable | must be gated |

## 2. 关键 P0 图层缺口

1. 局内 HUD：角色 / 怪物 / 事件 / 撤离对象层仍不足。
2. MiniMap / MapOverlay：污染、高危、标记、回传、撤离、数字状态需要成套图标。
3. Inventory / GroundLoot：卡片、tooltip、容量阻塞和拾取反馈需要统一状态层。
4. 结算报告：成功 / 失败 / 放弃 banner、资源转化和物品保留 / 丢失层尚未建立。
