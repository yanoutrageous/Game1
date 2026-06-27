# ART-12 UI Productization Asset Gap

文档状态：ART-12 validation evidence
生成时间：2026-06-27

## 0. 定位

本文档基于 ART-11 / ART-11R2 的结果整理 UI 产品化素材缺口。它不是导入授权，不修改 Godot，不修改 manifest。

原则：

- Base 确定稿只作为排版和风格 reference。
- M1 / Lua demo 只作为 HUD、key prompt、runtime structure reference。
- Draw / Base Art 可作为 candidate 来源，但 runtime 不直接读取外部路径。
- 下一批 runtime import 必须 manifest-backed，并在 ART-13 或后续阶段单独执行。

## 1. 缺口清单

| screen / module | visual need | current placeholder / limitation | recommended source pool | proposed visual_key | proposed asset_id | size / aspect | transparency | nine-slice / tile / sheet | fallback | priority | next runtime batch | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 主菜单 | 基地门厅背景分层 | 仍为程序化背景与临时几何层 | Base Art `Base` reference + `05_export_runtime_candidates/main_menu` | `bg.main_menu.base_hall` | `ui.main_menu.background.base_hall.v1` | 16:9, 1920x1080 source, scalable | no | no | procedural hall background | P0 | yes | 不使用整屏确定稿；可用 `main_menu_bg_no_text.png` 做候选但需规格审查 |
| 主菜单 | 左侧角色 / hero 展示 | 当前 hero 区像占位剪影 | `06_animation_sources`, `07_sprite_sheets`, M1 visual reference | `hero.main_menu.player_standby` | `character.hero.standby.v1` | 512-768 px height | yes | sprite sheet later | silhouette panel | P0 | later | 先确认角色策略，避免全量动画导入 |
| 主菜单 | 顶部小入口 icon set | 图标比例仍偏临时 | `05_export_runtime_candidates/ui_deploy_icon`, Draw `30_game_ready/icons` | `icon.top_nav.system` | `ui.nav.icon.system.v1` | 32/48/64 px | yes | no | text-only tab | P1 | later | 需与 key prompt 风格统一 |
| 主菜单 | 公告 / notice frame | 程序化 panel，可读但缺美术质感 | `05_export_runtime_candidates/ui_panel`, Draw `20_processed/ui_summary_bar` | `panel.notice.main_menu` | `ui.panel.notice.main_menu.v1` | 9-slice panel | yes | nine-slice | Skin Kit panel | P1 | yes | 先做 panel 规格，不导整屏图 |
| 出发探索 | 准备大厅 / 控制台背景 | 程序化控制台背景 | Base Art `Base/出发探索确定.png` reference + Draw `rooms` | `bg.deploy.control_room` | `ui.deploy.background.control_room.v1` | 16:9 or layered 3-panel | no | tile optional | procedural deploy background | P0 | yes | 需要把背景与 panel 层分离 |
| 出发探索 | 左侧角色整备展示 | 当前为临时剪影与状态 badge | `06_animation_sources`, `07_sprite_sheets` | `hero.deploy.loadout_standby` | `character.hero.loadout_standby.v1` | 512 px height | yes | sprite sheet later | silhouette | P0 | later | 先确定主角立绘 / sprite 方向 |
| 出发探索 | 装备 / 消耗品 slot | 已有 slot 样式但素材层不完整 | `05_export_runtime_candidates/ui_deploy_panel`, `item_*` | `slot.deploy.loadout` | `ui.slot.deploy.loadout.v1` | 64/96 px slots | yes | nine-slice optional | Skin Kit slot | P0 | yes | P0 因装备信息是核心决策点 |
| 出发探索 | 路线卡片 icon / status badge | 卡片仍靠文字表达 | Draw `30_game_ready/map_icon`, `ui_status_tag` | `badge.route.risk_state` | `ui.badge.route.risk_state.v1` | 24/32/48 px | yes | no | text badge | P1 | later | 与 minimap marker 去重 |
| 长期系统 | 档案室 / 图鉴墙背景 | 程序化档案墙 | Base Art `Base/长期系统确定.png` reference | `bg.long_term.archive_room` | `ui.long_term.background.archive_room.v1` | 16:9 layered | no | tile optional | procedural archive wall | P0 | yes | 不导整屏确定稿 |
| 长期系统 | 档案头像 / 角色 card | 当前缺正式角色档案视觉 | `06_animation_sources`, M1 reference | `portrait.archive.player` | `character.portrait.archive.player.v1` | 256/384 px | yes | no | silhouette portrait | P1 | later | 需要角色授权和命名 |
| 长期系统 | 图鉴卡片 icon | 卡片仍以文字为主 | Draw `30_game_ready/icons`, `item_*`, `props` | `card.collection.icon` | `ui.collection.card.icon.v1` | 64/96 px | yes | no | generic card icon | P1 | later | 可复用已导入 props / items |
| HUD / run surface | 左扫描器 panel skin | 已可读但仍程序化 | M1 reference + `05_export_runtime_candidates/ui_panel` | `panel.hud.scanner` | `ui.hud.panel.scanner.v1` | 9-slice, left rail | yes | nine-slice | current Skin Kit panel | P0 | yes | 必须保证文字遮罩稳定 |
| HUD / run surface | 中央房间背景 variants | 已有 6 个 room_background，但整体仍需统一产品化 | Godot runtime rooms + Draw `30_game_ready/rooms` | `bg.room.variant` | `room.background.variant.v2` | square / 16:9 crop policy | no | tile optional | current room backgrounds | P1 | later | 先做候选计划，不改 manifest |
| HUD / run surface | 右侧协议 / reward / threat cards | 仍偏程序化 panel | M1 reference + `ui_panel`, `ui_summary_bar` | `panel.hud.protocol_card` | `ui.hud.panel.protocol_card.v1` | 9-slice cards | yes | nine-slice | current right panel | P0 | yes | 直接影响 1280 可读性 |
| key prompt / bottom key bar | 统一 keycap set | 已有 key prompts，但缺全局体系和更多键位 | `05_export_runtime_candidates/ui_key_prompt` | `keycap.global.pixel` | `ui.key_prompt.global.v1` | 32/48 px | yes | no | text keycap | P0 | yes | 当前只有 E/ESC/F/M/Q/T；需补 Spc/Tab/数字/方向 |
| inventory / loot | item card / loot row | 跟随适配但不完整 | `item_*`, Draw `ui_item_card`, `ui_slot_row_four` | `card.inventory.item` | `ui.inventory.card.item.v1` | 9-slice card + 64 px icon | yes | nine-slice | Skin Kit card | P1 | later | 避免与 deploy slot 断层 |
| inventory / loot | ground loot / reward icon | 仍依赖通用 props / item icon | `props`, `item_recovered`, `ui_icon` | `icon.loot.reward_state` | `ui.loot.icon.reward_state.v1` | 48/64 px | yes | no | generic item icon | P2 | later | 等玩法呈现策略明确 |

## 2. P0 下一批重点

1. 主菜单背景分层，不使用整屏确定稿。
2. 出发探索控制台背景与 loadout slot。
3. 长期系统档案室背景。
4. HUD scanner / protocol panel。
5. key prompt global set。

## 3. 暂缓项

- 最终角色立绘。
- 全量角色动画。
- 完整 inventory / loot 产品化。
- 旧 Draw duplicate 清理。
- Base 确定稿整屏 runtime 导入。

## 4. 自检

- 每项缺口包含 screen、visual need、source pool、visual_key、asset_id、规格、透明、九宫格 / tile / sheet、fallback、priority、next batch 判断。
- 本文档没有导入 Godot，也没有修改 manifest。
