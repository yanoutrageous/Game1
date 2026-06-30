# ART-15 Slice 1 Asset Match Matrix

## 0. 定位

本文档记录 ART-15 Slice 1 的素材匹配结果。它只做资产对应、复用、候选和缺口判断，不导入图片、不修改 `asset_manifest.csv`、不修改 UI 代码。

判断依据：
- ART-14 规格文档和 `docs/art/validation/art14/`。
- 当前 `Godot/GraytailGodot/data/assets/asset_manifest.csv`。
- 当前 `Godot/GraytailGodot/assets/**` 实际 PNG。
- `D:\AGAME1\Base Art`、`D:\AGAME1\Draw\30_game_ready`、`D:\A GAME\26.5.30 GameJam\Draw` 的只读扫描结果。

处理标记：
- `existing_runtime`：已经在 Godot runtime assets 与 manifest 中存在。
- `direct_reuse`：可在 ART-15 后续切片直接通过 asset_id / visual_key 复用。
- `copy_to_runtime_candidate`：源文件存在，但需要后续小批复制到 Godot assets 并登记 manifest。
- `crop_required`：源文件存在，但需要裁切或切片后才适合 runtime。
- `repaint_required`：源文件/参考存在，但需要重绘状态、比例或九宫格。
- `generated_required`：当前没有合适源图，需要新制。
- `reference_only`：只能作为视觉参考，不能 runtime 导入。
- `defer`：本阶段不进入 P0。

## 1. 总体扫描结果

| source | scanned visual files | sha_matches_runtime | debug_or_forbidden | conclusion |
| --- | ---: | ---: | ---: | --- |
| `Godot/GraytailGodot/assets` | 74 | 74 | 0 | 当前 runtime 已有基础 UI / room / prop / item / key prompt / player 图片 |
| `D:\AGAME1\Base Art` | 188 | 86 | 0 | 大量 ART07/08 staging 已与 runtime 完全重复；Base / M1 / ART-13 主要 reference_only |
| `D:\AGAME1\Draw\30_game_ready` | 147 | 58 | 8 | 首批 game_ready 已大量进入 runtime；角色帧、title plate、scrollbar、summary bar 仍是候选 |
| `D:\A GAME\26.5.30 GameJam\Draw` | 969 | 99 | 21 | 旧池冗余高，只作为历史源；禁止解压或清理 `Art.zip` |

## 2. 核心 UI 位置匹配矩阵

| UI area | ART-14 need | current runtime asset | source candidate | decision | next action |
| --- | --- | --- | --- | --- | --- |
| 主菜单 background | 基地门厅 / 回收站背景 | `ui.main_menu.background.no_text` -> `assets/ui/main_menu/main_menu_bg_no_text.png`，1672x941 | `Draw\30_game_ready\main_menu\main_menu_bg_no_text.png` SHA 已匹配 runtime；Base 确定稿只参考 | `existing_runtime` + `direct_reuse` | 后续 Slice 3/4 接线和遮罩，不重复导入 |
| 主菜单 operator showcase | 角色 / 剪影展示层 | `sprite.player.*` 128x128 idle direction 已存在 | `Draw\30_game_ready\characters\*\frames`、`*_sheet.png` | `crop_required` | 后续只选择一个角色小批导入 walk / showcase；debug 图禁用 |
| 主菜单 entry button / notice / badge | 大按钮、公告板、红点 | `ui.common.button.dark`，deploy buttons 可借用 | Base 确定稿、deploy buttons | `repaint_required` | 后续可先复用 common button，再补主菜单专用 button/badge |
| 出发探索 tabs / buttons | 顶部 tab、主行动按钮 | `ui.deploy.button.*` 已在 manifest，note 多为 `not wired` | Base Art / Draw 同 SHA 重复 | `existing_runtime` + `direct_reuse` | Slice 3 接线优先；不重复复制 |
| 出发探索 slot / equipment icon | 装备、消耗品、slot state | `ui.deploy.icon.*`、item icons 已存在 | deploy icon / item icon staging 与 runtime 匹配 | `existing_runtime` + `repaint_required` | 已有 icon 直接复用；slot empty/filled/blocked 需补状态 |
| 出发探索 summary panel | 右侧摘要 panel、卡片 | `ui.deploy.panel.deploy_main_blank`、`ui.deploy.panel.deploy_summary_blank` | staging SHA 已匹配 runtime | `existing_runtime` + `direct_reuse` | 先接线和九宫格策略；必要时再重绘状态 |
| 长期系统 background | 档案室 / 图鉴墙 | 无专用 runtime asset | Base 长期系统确定稿、旧 GameJam UI reference | `repaint_required` | P1/P2；本阶段先用 Skin Kit + panel，避免整屏图直用 |
| 长期系统 cards / badges | 图鉴卡、研究节点、历史缩略图、抽奖 / 收藏卡 | 无专用 runtime asset | Base 长期系统确定稿 reference only | `generated_required` / `repaint_required` | 不进入 Slice 2 P0 导入，先列需求 |
| HUD panels | 左扫描器、右协议、底部 key bar | `ui.hud.panel.left`、`ui.hud.panel.protocol`、`ui.hud.bottom_bar`、`ui.hud.bar.*` | 已在 runtime | `existing_runtime` + `direct_reuse` | 后续接线已有 panel，补 compact / warning / selected 变体 |
| HUD search / warning / reward feedback | search result、blocked、reward、warning visual | 基础 label/panel 有，独立 feedback asset 缺 | `ui_summary_bar\ui_bar_blank_dark.png`、`ui_bar_blank_red.png`、`ui_bar_event_prompt.png` 在 Draw/old Draw | `copy_to_runtime_candidate` + `repaint_required` | Slice 2 可低风险导入 summary/warning bar 小批，或用 Skin Kit 生成 |
| MiniMap tiles / markers | unknown/scanned/explored/flag/room icons/number | `icon.minimap.*`、`icon.room.*`、`icon.minimap.number.1/2/3` 已存在 | Draw icons 32 已 SHA 匹配 runtime | `existing_runtime` + `direct_reuse` | 不重复导入基础 icon；补 number 4-8/selected/danger/polluted |
| MapOverlay frame / marker state | 大地图外框、selected marker、detail state | 复用 minimap icon；缺 frame / selected | ART-13 截图 reference only | `repaint_required` | Slice 2/3 先用 existing runtime + Skin Kit；后续补 frame asset |
| Room backgrounds | normal/mine/chest/event/monster/exit | `room.background.*` 六类 1254x1254 已存在 | Draw rooms 与旧 GameJam rooms 只做历史参考 | `existing_runtime` + `direct_reuse` | 不重复导入六类房间背景 |
| Room props | chest/mine/gold/ART07 props | `prop.chest.closed`、`prop.mine.trap`、`prop.gold.pile`、`prop.art07.*` 已存在 | Base Art / Draw props 多数 SHA 匹配 runtime | `existing_runtime` + `direct_reuse` | 接线和状态变体优先；open/active/resolved 可从候选补 |
| Event / merchant / extract prop state | event core、merchant table、extract beacon active | `prop.art07.04_shangren_tai`、`prop.art07.05_yichang_hexin`、`prop.art07.01/02_cheli_zhuangzhi_*` 已存在但 needs semantic review | Draw props 已匹配 runtime | `existing_runtime` + `direct_reuse` | 先 semantic review + mapping，不重复导入 |
| Inventory items | 物品图标 | `item.consumable.*`、`item.equipment.*`、`item.recovered.ore` 已存在 | Base Art / Draw item SHA 已匹配 runtime | `existing_runtime` + `direct_reuse` | Slice 3 接线；卡片/tooltip/capacity 另补 |
| Inventory / GroundLoot cards | item card、tooltip、capacity feedback | 无专用 card/tooltip asset | `ui_panel_terminal_main`、`ui_summary_bar` 候选；Skin Kit 可生成 | `repaint_required` | Slice 2 可导入 summary bar / title plate，card 先 Skin Kit |
| Result / Settlement | success/fail/abandon banner、report frame | `result_panel.tscn` 代码入口存在，专用 art 缺 | `ui_title_plate\ui_title_extract_confirm.png`、`ui_title_extraction_success.png`、`ui_title_signal_lost.png` | `copy_to_runtime_candidate` | Slice 2 低风险导入 title plates 或建立 report banner fallback |
| Toast / modal / badge | common modal、toast、badge | common button/panel 有，专用 toast/badge 缺 | summary bar / title plate / Skin Kit | `repaint_required` | Slice 5 统一动效和状态；Slice 2 可小批补 warning/reward bar |

## 3. P0 候选进入后续切片建议

| rank | candidate | source state | why low risk | proposed handling |
| --- | --- | --- | --- | --- |
| P0-01 | `ui_summary_bar\ui_bar_blank_dark.png` / `ui_bar_blank_red.png` | Draw / old GameJam 存在，未见 runtime manifest | HUD warning / capacity / toast 可复用 | `copy_to_runtime_candidate`，登记 `ui.feedback.bar.dark/red` |
| P0-02 | `ui_summary_bar\ui_bar_event_prompt.png` | old GameJam 存在，454x162 | 适合 event/search feedback prompt | `copy_to_runtime_candidate`，登记 `ui.feedback.event_prompt` |
| P0-03 | `ui_title_plate\ui_title_extract_confirm.png` | Draw/old GameJam 存在，243x150 | Result / extract confirmation 可见变化明确 | `copy_to_runtime_candidate`，登记 `ui.result.title.extract_confirm` |
| P0-04 | `ui_title_plate\ui_title_extraction_success.png` | Draw/old GameJam 存在，260x147 | Result success banner | `copy_to_runtime_candidate`，登记 `ui.result.title.extraction_success` |
| P0-05 | `ui_title_plate\ui_title_signal_lost.png` | Draw/old GameJam 存在，240x150 | Fail / signal lost banner | `copy_to_runtime_candidate`，登记 `ui.result.title.signal_lost` |
| P0-06 | `ui_scrollbar\ui_scrollbar_vertical.png` | Draw/old GameJam 存在，29x340 | Inventory / long list polish，风险低 | `defer` 到需要列表滚动视觉时 |
| P0-07 | player walk frames/sheets | Draw 与 old GameJam 30_game_ready 存在 | 可做运行态角色动画，但会影响 sprite 接线 | `crop_required`，暂不在 Slice 2 首批导入 |

## 4. 禁止进入 runtime 的匹配项

| source | reason | decision |
| --- | --- | --- |
| `Base Art\Base\*确定.png` | 整屏确定稿，只能做构图与视觉语义参考 | `reference_only` |
| `Base Art\ART-13\*.png` | 截图参考，不是切片素材 | `reference_only` |
| `Base Art\M1\Lua demo.mp4` / M1 PNG | 运行态结构参考，不是素材源 | `reference_only` |
| `Draw\30_game_ready\**\debug_detected_boxes.png` | 检测调试图 | `reference_only` / forbidden import |
| `D:\A GAME\26.5.30 GameJam\Draw\Art.zip` | 旧压缩包，本阶段禁止解压 | `defer` / forbidden this stage |
