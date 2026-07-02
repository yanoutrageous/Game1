# ART-19R1 UI Asset Semantic Classification

## 0. 文档定位

本文件是 ART-19R1 Slice 2 的语义分类结果。它基于 Slice 1 的全量盘点，对 `D:\AGAME1\sources\art` 与 `D:\AGAME1\sources\draw` 中的 1162 张图片建立初步语义分类。

本文件不移动、不删除、不重命名任何素材；不修改 Godot UI 代码；不修改 `asset_manifest.csv`；不导入 runtime asset。

支撑明细：

```text
docs/art/validation/art19r1/UI_ASSET_SEMANTIC_CLASSIFICATION.csv
docs/art/validation/art19r1/_slice2_semantic_counts.csv
docs/art/validation/art19r1/_slice2_role_counts.csv
docs/art/validation/art19r1/_slice2_screen_counts.csv
docs/art/validation/art19r1/_slice2_art19_hash_matches.csv
```

## 1. 分类口径

| 分类 | 含义 | 本轮用途 |
| --- | --- | --- |
| `reference_only` | 只作为视觉 / 布局 / 原型参考，不直接进入 runtime | Base 确定稿、M1、ART-13 等整屏图优先归入此类 |
| `source_candidate` | 可能作为来源，但尚未成为明确 runtime 候选 | raw、processed、staged mirror、旧根目录候选图 |
| `cut_required` | 图中有可参考结构或局部素材，但必须先定义裁切规格 | ART-14 A1 / 运行态截图类 |
| `cut_working_needed` | 需要进入受控切图工作流或当前处于 working 层 | `draw/10_working` 大量素材归入此类 |
| `runtime_candidate` | 已接近可用，但仍需组件规格、命名和 visual_key 判断 | `05_export_runtime_candidates` 与部分 `draw/30_game_ready` |
| `runtime_imported_correct` | hash 与 ART-19 runtime asset 匹配，且 canonical source 在 `draw/30_game_ready` | 仅作为“来源正确匹配”判断；最终用途正确性留给 Slice 3 |
| `runtime_imported_wrong_usage` | 已确认 runtime 接入用错 | 本轮未直接判定；Slice 3 对 Godot 已接入素材逐项复核 |
| `defer` | 暂缓，后续需要时再进入组件规格 | 角色帧、旧 processed、非当前 UI 首要素材 |
| `reject_or_archive` | debug / 侦测框 / 预览辅助等不应进入 runtime | 不删除，仅标记不建议使用 |

## 2. 分类结果汇总

| 分类 | 数量 | 判断说明 |
| --- | ---: | --- |
| `cut_required` | 5 | 主要是 ART-14 运行态参考图，可能含遮挡关系 / 图层信息，但不能直接使用 |
| `cut_working_needed` | 550 | 主要来自 `sources/draw/10_working`，说明切图和命名工作尚未治理 |
| `defer` | 168 | 角色动画、旧 processed、非当前 UI 首要素材，后续按需求再启用 |
| `reference_only` | 32 | Base、ART-13、M1、visual target 等整屏参考图 |
| `reject_or_archive` | 7 | debug 检测框、预览辅助等不建议进入 runtime |
| `runtime_candidate` | 124 | game-ready / runtime candidate 层中尚未导入或需复核的组件素材 |
| `runtime_imported_correct` | 16 | ART-19 已导入素材的 canonical source 命中 `draw/30_game_ready` |
| `runtime_imported_wrong_usage` | 0 | Slice 2 未确认错用；Slice 3 专门复核 ART-19 导入用法 |
| `source_candidate` | 260 | processed、raw、staged mirror 和旧根目录候选图 |

总计：1162 张图片。

## 3. 角色 / 部件粗分类

| Role hint | 数量 | 说明 |
| --- | ---: | --- |
| `background_or_composite` | 252 | 背景、整图、组合图、旧完整画面；多数需切分或仅作参考 |
| `character_animation` | 240 | 角色帧、sprite sheet、动画来源；暂不作为 UI 组件优先项 |
| `debug_or_detection_artifact` | 7 | debug 检测框 / 辅助图，应排除 runtime 使用 |
| `icon_or_game_object_component` | 161 | item、props、map icon、装备图标等 |
| `reference_screen_or_prototype` | 37 | Base / ART / M1 参考画面和原型图 |
| `ui_component` | 73 | panel、button、key prompt、summary bar 等 UI 组件候选 |
| `unclassified_visual_source` | 392 | 命名不足或来源层不明确，后续需人工补语义 |

## 4. 页面 / 使用范围粗分类

| Screen hint | 数量 | 说明 |
| --- | ---: | --- |
| `deploy_prep` | 74 | 出发探索按钮、面板、导航、装备相关候选 |
| `long_term` | 4 | 当前长期系统专用命名素材很少，后续需要补切片规格 |
| `main_menu` | 8 | 主菜单背景 / 相关整图为主 |
| `map_overlay/run_hud` | 55 | 地图格、marker、扫描 / 探索相关素材 |
| `reference_multi_screen` | 25 | 多页面参考图 |
| `run_hud_or_shared` | 240 | 角色、props、key、summary、HUD 通用候选 |
| `shared_or_unknown` | 756 | 命名无法可靠推断页面，需要后续命名补录 |

## 5. ART-19 runtime hash 命中

本轮对 `Godot/GraytailGodot/assets/ui/art19/**` 做只读 hash 对比，发现 39 条 source 图片与 ART-19 runtime asset hash 相同。

其中：

- 16 条 canonical source 位于 `sources/draw/30_game_ready`，标记为 `runtime_imported_correct`。
- 其余命中主要位于：
  - `sources/art/03_selected/draw_30_game_ready`
  - `sources/art/05_export_runtime_candidates/art07_first_batch`
  - `sources/draw/20_processed`
- 这些镜像不等同于新的 runtime 导入事实，只说明素材来源链路有重复，需要后续建立 canonical source。

已命中的 ART-19 canonical source 包括：

```text
sources/draw/30_game_ready/icons/64/00_wanjia_dingwei.png
sources/draw/30_game_ready/icons/64/01_weizhi_ge.png
sources/draw/30_game_ready/icons/64/02_yitan_ge.png
sources/draw/30_game_ready/icons/64/03_saomiao_ge.png
sources/draw/30_game_ready/icons/64/05_dici_xianjing_icon.png
sources/draw/30_game_ready/icons/64/07_baoxiang_icon.png
sources/draw/30_game_ready/icons/64/09_chukou_icon.png
sources/draw/30_game_ready/ui_button_blank/ui_button_blank_dark.png
sources/draw/30_game_ready/ui_deploy_button/ui_button_confirm_deploy_large.png
sources/draw/30_game_ready/ui_deploy_button/ui_button_nav_talent_selected.png
sources/draw/30_game_ready/ui_deploy_panel/ui_frame_highlight.png
sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_main_blank.png
sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_summary_blank.png
sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png
sources/draw/30_game_ready/ui_scrollbar/ui_scrollbar_vertical.png
sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png
```

## 6. 重点来源目录语义判断

### `sources/art/Base`

分类倾向：`reference_only`

原因：三屏确定稿 / 示例图 / 问题图是视觉目标和对比依据，不应直接作为 runtime 组件，也不应直接当整屏 UI 背景替代产品界面。

### `sources/art/ART-13`

分类倾向：`reference_only`

原因：主要是阶段截图，适合比较视觉问题，不适合作为切片来源。

### `sources/art/ART-14`

分类倾向：`cut_required`

原因：包含 A1 和运行态截图，能提供遮挡关系、图层逻辑和布局比例参考。如果后续要使用局部元素，必须先定义切片区域和输出尺寸。

### `sources/art/M1`

分类倾向：`reference_only`

原因：M1 / Lua 原型主要提供运行态 UI 逻辑、弹窗、地图、反馈节奏参考。其图片和视频不是当前 runtime UI 组件来源。

### `sources/art/05_export_runtime_candidates`

分类倾向：`runtime_candidate`

原因：该目录已有 panel、button、key prompt、map tile、props、item 等组件候选。部分与 ART-19 runtime hash 相同，但仍需后续补 visual_key / asset_id / 状态变体 / 可拉伸规则。

### `sources/draw/30_game_ready`

分类倾向：`runtime_candidate` / `runtime_imported_correct` / `defer`

原因：这是 draw 侧最可用候选层。UI panel、button、map64 已部分进入 ART-19；角色帧暂缓；debug 检测框标记为 `reject_or_archive`。

### `sources/draw/10_working`

分类倾向：`cut_working_needed`

原因：数量最大，命名和状态混杂，是后续切片和命名治理的主要来源之一，但不能直接导入 runtime。

## 7. wrong usage 判断边界

本轮没有直接标记 `runtime_imported_wrong_usage`，原因是：

- Slice 2 只对 source 图片做语义分类。
- “用错位置”需要结合 Godot runtime 文件、manifest、mapping、UI 截图和实际使用点判断。
- 该判断属于 Slice 3：ART-19 已接入素材复核。

因此本轮结论是：

```text
runtime_imported_wrong_usage = 0 confirmed in Slice 2
需要 Slice 3 逐项复核后才能定案
```

## 8. 后续 Slice 3 输入

Slice 3 应读取：

```text
Godot/GraytailGodot/assets/ui/art19/**
Godot/GraytailGodot/data/assets/asset_manifest.csv
Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd
Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd
Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd
Godot/GraytailGodot/scripts/ui/** 中 ART-19 使用点
```

并逐项判断：

- 是否来源可追溯。
- 命名是否合理。
- 用途是否正确。
- 是否保留。
- 是否替换。
- 是否只是临时占位。
- 是否属于 `runtime_imported_wrong_usage`。
