# ART-14 美术资源管理、UI 图层规范与动效需求规格

## 0. 文档定位

ART-14 是文档与验证脚本阶段，只整理美术资源、UI 图层、动效、visual_key / asset_id / animation_key 和后续 runtime 导入优先级。

本阶段不导入图片，不修改 Godot UI，不修改 `asset_manifest.csv`，不修改 Base Art / Draw / Base Docs / Connection，不 commit / push。

## 1. 判断依据

本阶段不只依据策划案。判断同时读取并归纳：
- Base Docs 中主菜单、出发探索、局内地图、局内流程、房间 / 遭遇、战斗、M3 物品闭环、长期系统、结算 / 历史战绩、UI 信息架构相关策划。
- `D:\AGAME1\Base Art\Base` 三张确定稿和 M1 / Lua demo 参考。
- ART-10R / ART-11 / ART-11R2 / ART-13 历史验证截图。
- 当前 Godot UI 代码入口：main menu、deploy prep、long term、run surface、minimap、map overlay、inventory、ground loot、result。
- 当前 Godot runtime assets 和 `asset_manifest.csv` 中已经登记的图片事实。
- Base Art staging 与 Draw 中仍可作为候选、但不得直接 runtime 使用的图片事实。

## 2. 产物索引

| file | purpose |
| --- | --- |
| `docs/art/validation/art14/UI_POSITION_INDEX.md` | 44 个 UI 位置索引，包含当前代码表面映射和边界 |
| `docs/art/validation/art14/SCREENSHOT_GAP_REVIEW.md` | 参考图 / 历史截图差距复盘 |
| `docs/art/validation/art14/SCREEN_LAYER_REQUIREMENTS.md` | 每个屏幕或 UI 位置的图层、z-order、motion、fallback 需求 |
| `docs/art/validation/art14/ART_ASSET_NEED_MATRIX.md` | 美术素材需求矩阵，区分已有 runtime、候选待审核、新制、禁用 |
| `docs/art/validation/art14/MOTION_AND_FEEDBACK_REQUIREMENTS.md` | 动效和交互反馈规格 |
| `docs/art/validation/art14/VISUAL_KEY_AND_ASSET_ID_REQUIREMENTS.md` | visual_key / asset_id / animation_key / fallback 约定 |
| `docs/art/validation/art14/RUNTIME_IMPORT_PRIORITY.md` | ART-15 之后的 runtime 导入优先级 |
| `docs/art/validation/art14/REFERENCE_TO_ASSET_GAP.md` | 参考图、代码表面、实际图片状态之间的缺口 |
| `tools/validate_art14_art_resource_spec.ps1` | 只读验证脚本 |

## 3. UI 位置覆盖摘要

ART-14 覆盖 44 个 UI 位置：
- 主菜单、出发探索总页与 5 个子页。
- 长期系统总页与 6 个子模块。
- 局内 HUD、MiniMap、MapOverlay、房间主视图和 7 类房间 / 遭遇位置。
- GroundLoot、Inventory、Item Tooltip、物品确认、容量 / 重量阻断。
- 撤离 / 失败 / 放弃确认、结算报告、历史战绩列表 / 详情。
- 设置、暂停、通用弹窗、toast / warning、红点 / 角标、Debug dev-only。

## 4. 当前代码与图片事实

当前 Godot 不是空白 UI：
- `scripts/ui/main_menu/main_menu_shell.gd` 已落地主菜单 shell，含背景、角色展示、入口按钮、公告、key bar。
- `scripts/ui/deploy_prep/deploy_prep_shell.gd` 已落地出发探索 shell，含 tab、card、summary、action area。
- `scripts/ui/long_term/long_term_shell.gd` 已落地长期系统 shell，消费长期模块框架。
- `scripts/ui/run_surface/run_surface.gd` 已落地 HUD / run surface，含 left scanner、room area、right status、bottom actions、HUD/minimap 子场景。
- `scripts/ui/minimap/minimap_panel.gd` 与 `scripts/ui/map_overlay/map_overlay_panel.gd` 已有地图表面。
- `scripts/ui/inventory/inventory_panel.gd` 与 `scripts/ui/ground_loot/ground_loot_panel.gd` 已有物品流转面板。
- `scripts/ui/result/result_panel.gd` 和 `scenes/ui/result/result_panel.tscn` 已有结算 / result 入口。

当前 Godot runtime 也已经有 74 张 PNG：
- minimap 32x32 基础 icon / tile / number 1-3。
- HUD panels、bottom bar、warning bar、mine risk tag。
- normal / mine / chest / event / monster / exit room backgrounds。
- chest、mine、gold pile 与部分 ART07 props。
- item、deploy、key prompt、main menu background、player idle sprites。

因此 ART-15 不应按“全部缺素材”推进，而应先补状态变体、接线、fallback 和未覆盖核心 UI。

## 5. 图层规格原则

所有核心屏幕按以下图层思路整理：
- `background_static`：页面语义背景或 room background，不承载可交互信息。
- `background_overlay`：暗角、遮罩、safe area 适配。
- `semantic_scene_layer`：角色、房间物件、地图 / 档案 / 控制台视觉锚点。
- `panel_base`：可读性面板、九宫格 panel、summary panel。
- `item_card_layer`：card、slot、tooltip、列表行。
- `state_badge_layer`：selected、locked、warning、new、reward、ready。
- `feedback_overlay`：toast、search result、blocked、reward、damage、warning。
- `modal_layer`：确认、详情、结算、暂停。
- `debug_layer`：dev-only，不得进入玩家主界面。

## 6. 动效规格原则

动效必须服务状态辨识，不应替代美术状态图：
- 地图 reveal、selected pulse、warning blink、blocked shake、toast fade、reward count-up、item pickup transfer、chest open、mine trigger、extract pulse 是首批重点。
- 所有动效必须有 reduce motion fallback。
- 所有 `animation_key` 必须绑定 UI 位置和状态，不得用内部 command / reason code 命名。
- 如果缺专用素材，fallback 到现有 panel / icon / color state，不直接读取外部路径。

## 7. ART-15 进入建议

建议 ART-15 只做小批 manifest-backed runtime 导入或接线：
1. 先梳理 manifest 中已存在但 `not wired` / `needs_semantic_review` 的 UI / prop / deploy / key prompt。
2. P0 补 minimap 状态、HUD feedback、room object state、Inventory/GroundLoot feedback、settlement report。
3. 禁止直接把 Base 确定稿整屏图作为 runtime UI。
4. 禁止导入 Draw debug 图。
5. 进入 Godot 前必须逐项确认 `visual_key`、`asset_id`、`animation_key`、fallback 和授权状态。

## 8. 暂缓内容

暂缓：
- 完整角色立绘与最终角色动画。
- 完整怪物 / 事件池美术。
- 长期系统抽奖 / 收藏 / 外观的完整表现。
- 大规模重新生图。
- 清理 Draw 或 Base Art。
- 修改 runtime 规则、CommandBus、TruthMap、RunContext、save / run / command core。

