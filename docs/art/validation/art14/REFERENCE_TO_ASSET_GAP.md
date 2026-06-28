# ART-14 Reference To Asset Gap

## 0. 定位

本文档把参考图、历史截图、当前 Godot 代码入口、当前图片实际状态放在同一张判断表中，避免只按策划案推导素材需求。

本文档不复制参考图、不导入图片、不修改 Godot，只记录差距。

## 1. 当前代码表面与截图覆盖

| screen / feature | code surface | scene surface | current screenshot evidence | conclusion |
| --- | --- | --- | --- | --- |
| 主菜单 | `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd` | app shell 动态构建 | ART11R2 main menu screenshots | 已有页面落地和背景候选，但仍需要主菜单入口按钮、公告、角色展示状态规范 |
| 出发探索 | `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd` | app shell 动态构建 | ART11R2 deploy screenshots | 已有总页和 tab 结构，仓库/申领/目标/出勤配置需要更具体的 asset state |
| 长期系统 | `Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd` | app shell 动态构建 | ART11R2 long-term screenshots | 代码已有模块框架，目标/图鉴/研究/历史/抽奖/收藏卡面还偏模板化 |
| HUD / run surface | `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd`、`run_ui_view_model.gd`、`hud_view_model.gd` | `scenes/ui/hud/hud.tscn` | ART13 final HUD / ART11R2 hotfix screenshots | 结构已接近可用，主要缺 room object state、feedback visual、combat/event object |
| MiniMap | `scripts/ui/minimap/minimap_panel.gd`、`minimap_view_model.gd` | `scenes/ui/minimap/minimap_panel.tscn` | ART13 HUD / map overlay screenshots | 基础 icon 已存在，缺 selected / polluted / unresolved / number 4-8 |
| MapOverlay | `scripts/ui/map_overlay/map_overlay_panel.gd` | `scenes/ui/map_overlay/map_overlay_panel.tscn` | ART13 final_map_overlay | 地图展开 UI 已存在，缺大地图 frame、selected marker、detail state visual |
| Inventory | `scripts/ui/inventory/inventory_panel.gd` | dynamic panel | ART13 final_inventory | 物品图标有，card/tooltip/capacity feedback 还需产品化素材 |
| GroundLoot | `scripts/ui/ground_loot/ground_loot_panel.gd` | dynamic panel | ART13 final_ground_loot | 物品图标有，拾取/阻断/容量反馈缺独立视觉 |
| Settlement / result | `scripts/ui/result/result_panel.gd` | `scenes/ui/result/result_panel.tscn` | current screenshot missing | 代码入口存在，但缺结算报告专用视觉规格和截图验证 |

## 2. 当前 runtime 图片实际状态

| category | actual files | dimensions observed | mapped asset ids | gap |
| --- | --- | --- | --- | --- |
| Main menu background | `assets/ui/main_menu/main_menu_bg_no_text.png` | 1672x941 | `ui.main_menu.background.no_text` | 可用作候选背景，仍缺入口按钮组 / notice board / hero frame 状态 |
| HUD panels | `assets/ui/hud/*.png` | panel 305-684px, bottom bar 590x176 | `ui.hud.*` | 有基础 panel，缺 compact / warning state / toast visual |
| MiniMap | `assets/ui/minimap/*.png` | 32x32 | `icon.minimap.*`, `icon.room.*`, `icon.minimap.number.1-3` | 缺 4-8 数字、selected、danger、polluted、unresolved |
| Room backgrounds | `assets/rooms/room_*.png` | 1254x1254 | `room.background.*` | normal/mine/chest/event/monster/exit 已覆盖，merchant/trade/special variants 缺 |
| Props | `assets/props/*.png`, `assets/props/art07/*.png` | 160/256px | `prop.*`, `prop.art07.*` | 基础物件已覆盖部分；状态变体和 semantic review 仍缺 |
| Item icons | `assets/items/**/*.png` | 57-94px | `item.*` | 图标可用；item card、rarity、capacity feedback 缺 |
| Deploy UI | `assets/ui/deploy/**/*.png` | buttons 60-289px, panels 95-320px | `ui.deploy.*` | 已导入但 note 标记 not wired；优先接线 / 语义审核 |
| Key prompts | `assets/ui/key_prompt/*.png` | 65-71px | `ui.key_prompt.*` | 图标可用，需统一 key bar state |
| Player sprites | `assets/player/*.png` | 128x128 | `sprite.player.*` | 单帧方向图可用，walk sheet / showcase portrait 缺 |

## 3. Base Art / Draw 候选事实

| source | actual state | allowed use | gap / caution |
| --- | --- | --- | --- |
| `Base Art\Base\主菜单确定.png`、`出发探索确定.png`、`长期系统确定.png` | 1672x941 整屏确定稿 | 参考构图、比例、信息密度 | 不得作为 runtime 整屏背景 |
| `Base Art\M1\Lua demo.mp4` 和 M1 PNG | M1/Lua HUD 与房间节奏参考 | 参考 HUD 空间、key bar、左扫描器 / 右协议层 | 不作为素材源 |
| `Base Art\05_export_runtime_candidates\art07_first_batch` | 52 张候选 PNG，尺寸与 Godot runtime 多数一致 | ART-15 可按 manifest-backed 小批导入 / 对齐 | 其中很多已进入 Godot assets，避免重复导入 |
| `Draw\30_game_ready\icons\32` | 32x32 minimap icon 源 | 历史来源和补缺参考 | 当前 runtime 已有对应多数图标 |
| `Draw\30_game_ready\characters` | 4 个角色，12 帧 128x128 + 512x384 sheet；含 debug 图 | 可作为后续角色动画候选 | debug_detected_boxes 禁止导入；角色需授权/命名/动作规格审核 |
| `Draw\30_game_ready\rooms\fangjian_jichu_1024.png` | 1024x1024 基础房间源 | 可作为特殊 room 参考 | Godot 已有 1254x1254 room backgrounds，需避免尺寸混乱 |
| `Draw\30_game_ready\ui_title_plate` | 撤离 / 成功 / 失联 title plates | 可作为 run end / settlement 参考 | 当前未见 runtime manifest 登记，需要 ART-15 批次判断 |

## 4. 主要差距结论

| area | not missing anymore | still missing |
| --- | --- | --- |
| 主菜单 | 背景候选已在 runtime，代码已有 shell | 入口按钮组状态、角色展示正式素材、公告板状态、红点 / 角标 |
| 出发探索 | deploy button/icon/panel 已导入，代码已有 tabs/cards/summary | 五个子页的专属卡片、状态 badge、slot state、blocked / ready visual |
| 长期系统 | 代码已有 6 模块框架 | 图鉴卡、研究节点、历史缩略图、抽奖/收藏卡面、模块红点 |
| HUD | panel/key prompt/room background/minimap 基础资产已有 | 交互反馈 visual、room object state、combat/event object、危险/奖励状态变体 |
| Inventory/GroundLoot | item icons 已有，代码 panel 已有 | item card、tooltip panel、容量/重量阻断、拾取/丢弃确认 visual |
| Settlement/History | result panel 代码入口存在 | 成功/失败/放弃结算 report、历史列表/详情视觉、thumbnail frame |

## 5. 对 ART-15 的约束

- ART-15 不能用“所有 UI 都缺图”作为前提；必须先复用已在 `assets/` 和 `asset_manifest.csv` 中存在的 P0 资产。
- `not wired` 和 `needs_semantic_review` 优先级高于重复导入。
- Base Art / Draw 只能作为候选源，进入 runtime 必须 manifest-backed。
- 所有新 `visual_key`、`asset_id`、`animation_key` 必须和当前代码表面绑定，不能只绑定策划名。

