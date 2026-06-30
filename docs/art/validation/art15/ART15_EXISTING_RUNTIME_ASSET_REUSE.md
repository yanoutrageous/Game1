# ART-15 Slice 1 Existing Runtime Asset Reuse

## 0. 定位

本文档列出 ART-15 应优先复用和接线的现有 runtime asset。目标是避免把已经导入、已经登记 manifest 的图片重复复制到 Godot。

本 Slice 不修改 `asset_manifest.csv`，只记录 reuse 决策。

## 1. Runtime asset 现状

| metric | value |
| --- | ---: |
| manifest rows | 79 |
| runtime PNG files under `Godot/GraytailGodot/assets` | 74 |
| Base Art files matching runtime SHA | 86 |
| Draw `30_game_ready` files matching runtime SHA | 58 |
| old GameJam Draw files matching runtime SHA | 99 |

结论：当前项目不是缺少基础素材，而是大量资产已存在但未完全通过 visual_key / UI code 消费。

## 2. Reuse groups

| group | asset_id examples | file state | reuse decision |
| --- | --- | --- | --- |
| MiniMap tiles | `icon.minimap.unknown`, `icon.minimap.explored`, `icon.minimap.scanned` | 32x32 PNG 已存在 | `direct_reuse`，Slice 3 接线 / 状态扩展 |
| MiniMap markers | `icon.minimap.player`, `icon.minimap.flag`, `icon.room.mine`, `icon.room.monster`, `icon.room.chest`, `icon.room.extract`, `icon.room.exit`, `icon.room.cleared` | 32x32 PNG 已存在 | `direct_reuse`，不可重复导入 Draw icons |
| MiniMap numbers | `icon.minimap.number.1/2/3` | 32x32 PNG 已存在 | `direct_reuse`，4-8 缺口另列 |
| HUD panels | `ui.hud.panel.left`, `ui.hud.panel.protocol`, `ui.hud.bottom_bar`, `ui.hud.mine_risk_tag`, `ui.hud.bar.frame`, `ui.hud.bar.warning` | 305-684px panel / 419x72 bar / 590x176 bottom bar | `direct_reuse`，后续补 warning / selected 变体 |
| Common button / icon | `ui.common.button.dark`, `ui.common.gold_icon` | common button 321x167，gold icon 87x89 | `direct_reuse`，可作为 modal / button fallback |
| Player idle | `sprite.player.default`, `sprite.player.idle.up/left/right` | 128x128 PNG | `direct_reuse`，walk/portrait 另列候选 |
| Room backgrounds | `room.background.normal/mine/chest/event/monster/exit` | 1254x1254 PNG | `direct_reuse`，merchant/trade/special room deferred |
| Core props | `prop.chest.closed`, `prop.mine.trap`, `prop.gold.pile` | 160/256px PNG | `direct_reuse`，open/triggered/active state 另补 |
| ART07 props | `prop.art07.00_baoxiang_kai`、`prop.art07.01_cheli_zhuangzhi_an`、`prop.art07.02_cheli_zhuangzhi_liang`、`prop.art07.04_shangren_tai`、`prop.art07.05_yichang_hexin`、`prop.art07.07_lingjian_dui`、`prop.art07.08_saomiaoyi`、`prop.art07.10_yiliaobao`、`prop.art07.11_wuzi_xiang` | 已存在，note 多为 not wired / needs_semantic_review | `direct_reuse` after semantic review |
| Key prompts | `ui.key_prompt.e/esc/f/m/q/t` | 65-71px PNG | `direct_reuse`，后续接入 global key bar |
| Items | `item.consumable.medkit/syringe`, `item.equipment.flashlight/goggles`, `item.recovered.ore` | 57-94px PNG | `direct_reuse`，Inventory / GroundLoot 不重复导入图标 |
| Deploy assets | `ui.deploy.button.*`, `ui.deploy.icon.*`, `ui.deploy.panel.*` | buttons/icons/panels 已存在 | `direct_reuse`，优先解决 `not wired` |
| Main menu bg | `ui.main_menu.background.no_text` | 1672x941 PNG | `direct_reuse`，不把 Base 确定稿整屏直用 |
| Font | `ui.font.fusion_pixel` | OTF registered | `direct_reuse`，授权状态仍需外部治理确认 |

## 3. Not wired / semantic review priority

以下不是“缺素材”，而是“已导入但需要接线或语义审核”：

| asset family | manifest note | ART-15 treatment |
| --- | --- | --- |
| `ui.key_prompt.*` | `ART08 staged from Base Art; not wired` | Slice 3 接入 key bar / HUD action buttons |
| `item.*` | `ART08 staged from Base Art; not wired` | Slice 3 接入 Inventory / GroundLoot item icon |
| `ui.deploy.button.*` | `ART08 staged from Base Art; not wired` | Slice 3 接入 deploy tabs/buttons 或保留 fallback |
| `ui.deploy.icon.*` | `ART08 staged from Base Art; not wired` | Slice 3 接入 deploy loadout/summary icons |
| `ui.deploy.panel.*` | `ART08 staged from Base Art; not wired` | Slice 3/4 接入 deploy card/summary panel |
| `ui.panel.terminal_main` | `not wired; needs_semantic_review` | 可作为 Inventory/GroundLoot/modal panel candidate，先审语义 |
| `ui.icon.jinbi_icon` / `ui.icon.xuetiao_tianchong` | `not wired; needs_semantic_review` | currency / health bar 使用前需确认含义 |
| `prop.art07.*` | `not wired; needs_semantic_review` | 房间对象优先复用，但需 UI label / room state 对应 |
| `ui.main_menu.background.no_text` | `not wired` | Slice 3/4 可接主菜单背景 visual_key |

## 4. Reuse-to-screen mapping

| screen | direct reuse assets | missing after reuse |
| --- | --- | --- |
| Main menu | `ui.main_menu.background.no_text`, `sprite.player.default`, `ui.common.button.dark` | large entry button state、notice board、red dot、operator showcase |
| Deploy prep | `ui.deploy.button.*`, `ui.deploy.icon.*`, `ui.deploy.panel.*`, `item.*` | slot state、summary badge、ready/blocked visual |
| Long term | Skin Kit / common panel fallback | codex card、research node、history thumbnail、module badge |
| HUD | `ui.hud.*`, `ui.key_prompt.*`, `room.background.*`, `prop.*` | search feedback、warning/reward toast、room object state variants |
| MiniMap / MapOverlay | `icon.minimap.*`, `icon.room.*`, `icon.minimap.number.1/2/3` | number 4-8、selected/danger/polluted/unresolved state |
| Inventory / GroundLoot | `item.*`, `ui.common.button.dark`, `ui.panel.terminal_main` candidate | item card、tooltip panel、capacity/weight feedback |
| Result / Settlement | common panel fallback only | title plates、success/fail/abandon banner、report frame |

## 5. Rule for later slices

Before copying any new PNG into `Godot/GraytailGodot/assets`, later slices must check:
1. Whether identical SHA already exists in runtime assets.
2. Whether an asset_id already exists in `asset_manifest.csv`.
3. Whether the desired change is actually a wiring / visual_key problem.
4. Whether the candidate source is reference-only or debug-only.

