# UI 组件切片规格

## 0. 文档定位

本文是 ART-19R1 Slice 4 产物，用于定义后续 UI 素材切片、命名、状态和 Godot runtime 目标路径。
本文不执行真实切图，不修改 Godot runtime，不修改 `asset_manifest.csv`，不修改 Godot UI 代码。

## 1. 输入依据

- Slice 1：`UI_SOURCE_ASSET_INVENTORY.md` 与 inventory CSV。
- Slice 2：`UI_ASSET_SEMANTIC_CLASSIFICATION.md` 与分类 CSV。
- Slice 3：`ART19_IMPORTED_ASSET_REVIEW.md` 对 ART-19 已接入素材的复核。
- 参考图：`sources/art/Base/*.png`、`sources/art/ART-14/A1.png`、`sources/art/M1/**`。
- 候选素材：`sources/draw/30_game_ready/**` 与 `sources/art/05_export_runtime_candidates/**`。

## 2. 切片原则

- Base / ART-14 / M1 主要作为 `reference_only`，不能直接 runtime 使用。
- `sources/draw/30_game_ready` 是下一批低风险 runtime_candidate 的主要来源。
- ART-19 已接入素材要收敛复用边界，避免具体语义组件被泛化。
- 所有可拉伸 UI 面板必须明确九宫格边界和最小显示尺寸。
- 状态集至少区分 normal / selected / disabled / locked / warning，必要时补 hover / pressed / reward。

## 3. 规格统计

| 页面 / 域 | 数量 | 说明 |
| --- | ---: | --- |
| `shared` | 8 | 通用 panel、button、tab、slot、keycap、badge。 |
| `main_menu` | 4 | 主菜单背景、入口按钮、公告框、顶部按钮。 |
| `deploy_prep` | 7 | 出发探索背景、角色展示、tab、路线卡、装备槽、摘要、按钮。 |
| `long_term` | 5 | 长期系统背景、角色档案、收藏卡、右侧短模块、顶部切换。 |
| `run_hud` | 6 | 左栏、主游戏画面、右上状态卡、底部信息、keybar、对象提示。 |
| `map_overlay` | 3 | 地图格、展开地图面板、关闭提示。 |
| `inventory` | 2 | 背包面板和物品槽。 |
| `ground_loot` | 1 | 地面拾取卡。 |
| `result` | 1 | 结果标题牌。 |

优先级：

| 优先级 | 数量 |
| --- | ---: |
| `P0` | 27 |
| `P1` | 9 |
| `P2` | 1 |

## 4. 页面规格摘要

### 4.1 Shared

- `ui_panel_large_terminal_frame`：将 `terminal_main` 收敛为 shared large frame，后续页面可派生专用大框。
- `ui_panel_summary_card`：将 `deploy_summary` 收敛为 small summary card，避免无边界泛用。
- `ui_button_primary_gold`：以 deploy confirm 来源建立 gold primary，但需明确状态集。
- `ui_button_dark_secondary`：用于暗色次级按钮和 keybar 按钮。
- `ui_tab_selected_generic`：重命名或替换 talent-specific selected tab。
- `ui_icon_slot_frame`：用于装备槽、背包槽、收藏格和选中框。
- `ui_keycap_prompt_set`：为 E / Q / F / M / T / Esc 等快捷键提供统一 keycap。
- `ui_badge_state_set`：用于 ready / warning / reward / locked 等短状态。

### 4.2 主菜单

- 背景使用 `main_menu_bg_no_text.png` 或经审查后的主菜单背景，不使用整屏 Base 图作为唯一 runtime UI。
- 右侧大入口按钮需要实体材质和 selected / disabled 状态。
- 公告框只做短信息，不承载长段工程说明。
- 顶部小入口按钮使用统一 icon + button 规格。

### 4.3 出发探索

- 背景候选需做视觉适配复核，不能把普通房间图强行命名为准备大厅。
- 左侧角色展示只放角色与短状态，不再堆装备详情。
- 一级 tab 横向排列，必要时左右滑动，不换行压缩详情区。
- 中区路线卡使用 panel + selected glow + 短标签。
- 右侧摘要拆成装备、消耗品、风险、收益等短模块。
- 主按钮与继续 / 终止等次级按钮必须有清晰层级。

### 4.4 长期系统

- 左侧固定角色外观展示和设置外观按钮。
- 中区为收藏墙 / 图鉴墙，不做长段详情页。
- 右侧固定显示等级、主线、资历、资源、奖励等短模块。
- 顶部必须有返回主菜单和切换到出发探索的按钮。

### 4.5 Run HUD

- 左侧固定信息栏约 20%-25%，用于小地图、状态、背包入口。
- 左栏之外应尽量保留为实际游戏画面。
- 右上角协议 / 压力只作为小浮动状态卡，不形成右侧整列。
- 主信息栏与快捷键栏是覆盖层，不挤压主房间画面。
- 场景内对象提示必须小型化并贴近对象。

### 4.6 MapOverlay

- 展开地图是临时 overlay，不改变 HUD 基础布局。
- 地图面板应保留底层房间可辨识度。
- event / monster / flag 等 marker 不能继续复用 scanned alias。

## 5. ART-19 已接入素材约束

- `ui.art19.panel.terminal_main`：后续拆成 `main_menu_entry_board`、`longterm_profile_frame`、`longterm_collection_wall` 等页面专用件。
- `ui.art19.panel.deploy_summary`：仅作为 small summary card 的来源之一。
- `ui.art19.button.confirm`：需要改名为 `ui.shared.button.primary_gold` 或限定为 deploy 主按钮。
- `ui.art19.button.selected_tab`：必须替换或重命名，不能继续保留 talent tab 语义。
- `ui.art19.map64.scanned`：event alias 暂停扩散，Slice 5 单列 `ui.map_overlay.cell.event_64`。
- `ui.art19.scrollbar.vertical`：保留为 reserved / defer。

## 6. 后续使用

真实切图和导入前必须：

- 明确 source 文件和 source SHA256。
- 明确切片矩形、九宫格、状态和输出尺寸。
- 确认 target runtime path 没有冲突。
- 确认 asset_id 唯一。
- 确认 visual_key 不误导页面职责。
- 通过 manifest diff 和截图验收。

## 7. 边界

- 未修改素材源。
- 未执行真实切图。
- 未修改 Godot UI 代码。
- 未修改 `asset_manifest.csv`。
- 未新增 runtime asset。
- 未运行 Godot。
- 未 commit / push。
