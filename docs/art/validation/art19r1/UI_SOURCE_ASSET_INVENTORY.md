# ART-19R1 UI Source Asset Inventory

## 0. 文档定位

本文件是 ART-19R1 Slice 1 的素材池全量盘点结果。它只记录 `D:\AGAME1\sources\art` 与 `D:\AGAME1\sources\draw` 的当前事实，用于后续 Slice 2 语义分类、Slice 4 UI 组件切片规格和 Slice 5 命名补录。

本文件不授权 runtime 导入，不移动、不删除、不重命名素材，不修改 Godot UI 代码和 `asset_manifest.csv`。

## 1. 扫描边界

读取路径：

```text
D:\AGAME1\sources\art
D:\AGAME1\sources\draw
```

写入路径：

```text
docs/art/validation/art19r1/UI_SOURCE_ASSET_INVENTORY.md
docs/art/validation/art19r1/_slice1_summary.json
docs/art/validation/art19r1/_slice1_file_inventory.csv
docs/art/validation/art19r1/_slice1_dir_counts.csv
docs/art/validation/art19r1/_slice1_ext_counts.csv
docs/art/validation/art19r1/_slice1_duplicate_hashes.csv
docs/art/validation/art19r1/_slice1_special_dirs.csv
```

未写入、未修改：

```text
D:\AGAME1\sources\art
D:\AGAME1\sources\draw
Godot/GraytailGodot/**
Godot/GraytailGodot/data/assets/asset_manifest.csv
```

## 2. 总量概览

| 范围 | 文件数 | 图片数 | 尺寸可读图片 | 尺寸不可读图片 |
| --- | ---: | ---: | ---: | ---: |
| `sources/art` | 199 | 193 | 193 | 0 |
| `sources/draw` | 998 | 969 | 969 | 0 |
| 合计 | 1197 | 1162 | 1162 | 0 |

图片扩展名以 `.png` 为主；本次扫描中所有图片尺寸均可读取。非图片包括 `.csv`、`.md`、`.json`、`.html`、`.mp4`、`.zip`。

## 3. 顶层目录数量

| 顶层目录 | 文件数 | 说明 |
| --- | ---: | --- |
| `sources/art/[root]` | 1 | `README.md` |
| `sources/art/_registry` | 4 | registry CSV |
| `sources/art/03_selected` | 52 | ART-07 选入素材镜像，和 runtime candidate 有大量重复 |
| `sources/art/04_cut_working` | 0 | 当前为空，说明尚未形成正式切图工作区 |
| `sources/art/05_export_runtime_candidates` | 52 | 当前最接近 runtime candidate 的外部素材层 |
| `sources/art/06_animation_sources` | 48 | 角色动画帧来源 |
| `sources/art/07_sprite_sheets` | 4 | 角色 sprite sheet 来源 |
| `sources/art/08_visual_targets` | 10 | Base 确定稿 / 示例图镜像，主要是视觉目标 |
| `sources/art/ART-13` | 6 | 高分辨率截图 / 阶段参考 |
| `sources/art/ART-14` | 5 | A1 与运行态截图参考 |
| `sources/art/Base` | 10 | 主菜单 / 出发探索 / 长期系统确定稿与示例、问题图 |
| `sources/art/M1` | 7 | M1 / Lua 原型图片和视频参考 |
| `sources/draw/[root]` | 25 | 旧候选、原始命名文件、zip/html 等 |
| `sources/draw/_manifest` | 11 | draw 侧 manifest / 索引材料 |
| `sources/draw/00_raw` | 4 | 旧 raw 层 |
| `sources/draw/10_working` | 552 | 最大工作层，含大量中间处理素材 |
| `sources/draw/20_processed` | 191 | processed 层 |
| `sources/draw/30_game_ready` | 151 | 当前最清晰的 game-ready 候选层 |
| `sources/draw/processed` | 64 | 旧 processed 残留层 |

## 4. 重点目录确认

| 路径 | 文件数 | 图片数 | 尺寸可读 | 当前判断 |
| --- | ---: | ---: | ---: | --- |
| `sources/art/04_cut_working` | 0 | 0 | 0 | 为空；后续如要切 UI 组件，需要先建立切片工作规格，不应直接补 runtime |
| `sources/art/05_export_runtime_candidates` | 52 | 52 | 52 | 组件候选层，包含 props、map icon、UI button、panel、key prompt 等 |
| `sources/art/Base` | 10 | 10 | 10 | 视觉目标 / 参考图，包含三屏确定稿和示例图，不应直接 runtime 读取 |
| `sources/art/ART-13` | 6 | 6 | 6 | 阶段截图参考，主要用于视觉对比和问题定位 |
| `sources/art/ART-14` | 5 | 5 | 5 | A1 与运行态截图参考，可用于遮挡关系 / 图层逻辑判断 |
| `sources/art/M1` | 7 | 6 | 6 | Lua 原型参考，含视频；用于运行态 UI 逻辑、弹窗、地图、反馈节奏参考 |
| `sources/draw/30_game_ready` | 151 | 147 | 147 | 当前 draw 侧最可用候选层，仍需语义分类和命名补录 |

## 5. 尺寸分布观察

高频尺寸：

| 范围 / 尺寸 | 数量 | 说明 |
| --- | ---: | --- |
| `sources/draw/30_game_ready` 128x128 | 48 | 角色帧为主 |
| `sources/art/06_animation_sources` 128x128 | 48 | 角色动画帧来源 |
| `sources/draw/20_processed` 128x128 | 48 | processed 角色帧 |
| `sources/draw/processed` 128x128 | 48 | 旧 processed 角色帧 |
| `sources/draw/30_game_ready` 64x64 | 16 | 64px icon / map marker 类候选 |
| `sources/draw/30_game_ready` 32x32 | 14 | 小图标候选 |
| `sources/art/Base` 1672x941 | 6 | 三核心界面确定稿 / 示例图 |
| `sources/art/08_visual_targets` 1672x941 | 6 | Base 确定稿 / 示例图镜像 |
| `sources/art/ART-13` 1918x1198 | 6 | 高分辨率阶段截图 |
| `sources/art/ART-14` 约 1270x680 / 1915x1134 | 5 | A1 + 实机截图参考 |
| `sources/art/M1` 1288x760 至 1918x1198 | 6 | M1 / Lua 原型参考图 |

## 6. `05_export_runtime_candidates` 内容概览

`05_export_runtime_candidates` 当前有 52 张图片，均可读取尺寸。主要类别：

- `item_consumable`：医疗包、针剂等消耗品。
- `item_equipment`：手电、护目镜等装备。
- `item_recovered`：矿石等回收物。
- `main_menu`：`main_menu_bg_no_text.png`，是整屏背景候选，不应直接作为唯一 UI 结构。
- `map_icon` / `map_tile_icon`：箱子、事件、出口、旗标、地雷、怪物、扫描格、未知格等。
- `props`：箱子、撤离装置、商人台、异常核心、地刺陷阱、零件堆、扫描仪、金币堆、医疗包、物资箱。
- `ui/icons`：金币、血条填充等小 UI 图标。
- `ui_button_blank` / `ui_deploy_button`：按钮和导航按钮候选。
- `ui_deploy_icon`：背包、护甲、绷带、指南针等图标候选。
- `ui_deploy_panel`：出发探索主面板、摘要面板、高亮框候选。
- `ui_key_prompt`：E / Esc / F / M / Q / T 按键提示。
- `ui_panel`：terminal main 面板候选。

这些素材适合进入 Slice 2/4 的组件判断，但当前仍只是外部候选，不是最终 runtime 事实。

## 7. `Base / ART-13 / ART-14 / M1` 参考判断

| 目录 | 当前事实 | 盘点阶段判断 |
| --- | --- | --- |
| `Base` | 10 张图，包括主菜单 / 出发探索 / 长期系统确定稿、示例图和问题图 | `reference_only` 倾向；决定视觉目标、材质方向、布局气质，不直接切入 runtime |
| `ART-13` | 6 张高分辨率截图 | `reference_only` 倾向；用于阶段对比和问题定位，不作为 UI 组件切片主来源 |
| `ART-14` | 5 张图，含 `A1.png` 和运行态截图 | `reference_only` / `cut_required` 待判断；A1 可参考运行态遮挡关系和图层，但是否切片需 Slice 2/4 定案 |
| `M1` | 6 张图片 + 1 个视频 | `reference_only` 倾向；用于 Lua 原型 UI 逻辑、反馈节奏、地图/弹窗关系参考，不直接复制为 runtime |

## 8. 重复候选

按 SHA256 发现 144 组重复图片。重复集中在以下链路：

```text
sources/draw/20_processed
sources/draw/30_game_ready
sources/art/03_selected/draw_30_game_ready
sources/art/05_export_runtime_candidates/art07_first_batch
```

示例：

| 重复素材 | 重复数 | 典型路径 |
| --- | ---: | --- |
| `main_menu_bg_no_text.png` | 5 | `sources/draw/Main.png`、`draw/20_processed`、`draw/30_game_ready`、`art/03_selected`、`art/05_export_runtime_candidates` |
| `ui_button_confirm_deploy_large.png` | 4 | `draw/20_processed`、`draw/30_game_ready`、`art/03_selected`、`art/05_export_runtime_candidates` |
| `ui_button_blank_dark.png` | 4 | `draw/20_processed`、`draw/30_game_ready`、`art/03_selected`、`art/05_export_runtime_candidates` |
| `ui_button_nav_talent_selected.png` | 4 | `draw/20_processed`、`draw/30_game_ready`、`art/03_selected`、`art/05_export_runtime_candidates` |
| `ui_icon_backpack.png` | 4 | `draw/20_processed`、`draw/30_game_ready`、`art/03_selected`、`art/05_export_runtime_candidates` |

处理建议：本阶段不得删除重复；后续应通过 source registry / component registry 记录 canonical source，而不是直接清理文件。

## 9. 风险观察

- `04_cut_working` 为空，说明还没有建立真实 UI 切片工作流。
- `05_export_runtime_candidates` 和 `draw/30_game_ready` 已有很多可用候选，但存在大量重复镜像，需要先建立 canonical source 判断。
- `Base`、`ART-13`、`ART-14`、`M1` 大多是整屏参考图或原型图，不应被误判为可直接 runtime 导入的组件。
- `draw/10_working` 数量最大，含 552 个文件，后续语义分类需要谨慎区分工作残留、候选和已处理素材。
- `draw` 根目录仍有 `Art.zip`、旧图片和 html 预览，不应在 ART-19R1 中解压、清理或反推为 runtime 事实。

## 10. 后续 Slice 2 输入

Slice 2 应基于本盘点做语义分类，重点回答：

- 哪些是 `reference_only`。
- 哪些是 `source_candidate`。
- 哪些需要进入 `cut_required` / `cut_working_needed`。
- 哪些是 `runtime_candidate`。
- ART-19 已接入的素材是否存在 `runtime_imported_wrong_usage`。
- 哪些重复链路需要建立 canonical source，而不是删除文件。
