# ART-20 Closeout: Pipeline Pass, Visual Target Incomplete

## 0. 中文摘要

ART-20 可以收尾，但只能以“工程链路完成、视觉目标未完成”的状态收尾。

本阶段证明了以下链路可以闭合：

```text
source candidate -> ART20 staging -> cut output -> Godot runtime asset -> asset_manifest.csv -> visual_key / UI consumer -> Computer Use live evidence
```

本阶段没有证明核心 UI 已达到 Base / Lua / UE 参考目标，也没有完成图片到 UI 位置的权威索引。

## 1. 收尾结论

| 项目 | 结论 |
| --- | --- |
| 工程链路 | PASS |
| 素材源保护 | PASS |
| 切片流程 | PASS |
| runtime 导入 | PASS, limited |
| manifest-backed mapping | PASS, limited |
| live smoke evidence | PASS_WITH_LIMITS |
| 目标视觉达成 | FAIL / deferred |
| 是否可声明正式 UI 美术替换完成 | No |

ART-20 的正确阶段状态是：

```text
closed_with_visual_gap
```

## 2. 已完成事实

- `27` 个源素材进入 ART-20 staging。
- `54` 个 PNG 被实际切出到 `D:\AGAME1\sources\art\ART-20\03_cut_output`。
- `5` 个组件保持 blocked / review。
- `15` 个 ART20 runtime PNG 被导入 Godot。
- `15` 个 ART20 manifest rows 进入 `asset_manifest.csv`。
- ART20 visual keys 已通过 `art09_manifest_asset_mapping.gd` / `presentation_mapping.gd` 接到 UI consumer。
- Slice 6 使用真实 Godot 项目和 Computer Use 生成 live smoke 截图。
- `tools/validate_art20_ui_asset_pipeline.ps1` 在 Slice 6 收口时通过。
- 收尾复跑时发现 `assets/ui/art20/**` 下已有 Godot `.png.import` generated side effects；当前最终 commit gate 必须先决定这些 generated files 的排除或处置方式，不能直接声明当前工作树全绿。

## 3. 未完成事实

ART-20 未完成以下内容：

- 未建立 `UI_ASSET_PLACEMENT_INDEX`。
- 未记录每张图对应的 screen / ui_slot / layer / rect / consumer / scale_mode。
- 未完成主菜单、出发探索、长期系统、Run HUD、MapOverlay 的最终视觉替换。
- 未完成 1280x720 或更高分辨率的最终视觉 QA。
- 未复现完整 GroundLoot 可见掉落面板。
- 未导入被 blocked 的关键组件：
  - `deploy_left_character_frame`
  - `longterm_left_character_profile`
  - `run_gameplay_viewport_background`
  - `map_overlay_cell_64_set`
  - `map_overlay_event_marker_64`

## 4. 为什么视觉目标没有达成

ART-20 解决的是“能不能从 source 受控切片并进入 Godot runtime”，不是“这张图应该被放到哪个 UI 位置”。

当前缺少以下关键约束：

```text
screen
ui_slot
layer
rect / anchor
source_image
cut_output
runtime_asset
asset_id
visual_key
consumer_script
consumer_function
scale_mode
z_order
status
screenshot_evidence
```

因此 ART-20 后仍可能出现以下问题：

- 素材语义正确但放错位置。
- 背景被边框遮挡。
- 具体物品图标被用作通用图标。
- 面板被跨页面复用后比例不适配。
- 图层顺序正确性依赖脚本节点名和硬编码 `Rect2`。

## 5. 参考原型差距

Lua 原型可借鉴的核心是：

- `UILayout` 统一 base size / scale / offset。
- HUD 结构明确：左栏、主画面、右上小状态卡、底部 overlay。
- `UITheme` 以图片 registry 管理皮肤，缺图时 fallback。

UE 原型可借鉴的核心是：

- UI 资源按 `common / deploy / hud / Icons32 / Icons64 / keys / main_menu` 成组。
- `Apply9Slice` / Brush / SizeBox / native size 控制面板和按钮。
- Widget 层级明确，房间画面铺底，UI 面板浮在其上。
- 目标画面依赖完整素材集，而不是少量 icon / keycap。

Godot 当前差距是：

- ART20 runtime 只导入 `15` 个资产。
- 大部分页面仍依赖硬编码布局和旧框体。
- 缺少图片到 UI 位置的权威索引。
- 缺少完整页面专属素材集。

## 6. 后续 ART-21 前置条件

ART-21 不应继续做“小批量导入 + 试探式替换”。它必须先建立位置索引，再执行核心界面视觉落地。

ART-21 最低前置：

1. 新增 `UI_ASSET_PLACEMENT_INDEX`。
2. 按主菜单、出发探索、长期系统、Run HUD、MapOverlay 建立 screen slot。
3. 每个 slot 绑定 source / cut output / runtime asset / visual_key / consumer。
4. 标记每个 slot 的状态：
   - `ready`
   - `needs_cut`
   - `needs_source_selection`
   - `needs_redraw`
   - `blocked`
5. 再执行第二批素材切片和 runtime 导入。
6. 使用 Computer Use 对照 Base / Lua / UE 做最终视觉验收。

## 7. 收尾状态

ART-20 收尾状态：

```text
ART-20 工程链路通过，视觉目标未完成。
ART-20 可关闭为 pipeline proof。
ART-21 必须承接 UI 位置索引、槽位化消费、核心界面目标视觉重建。
```

## 8. 收尾复核结果

本次收尾新增了索引和 closeout 文档：

- `docs/art/ART20_CLOSEOUT_PIPELINE_PASS_VISUAL_INCOMPLETE.md`
- `docs/art/README.md`
- `docs/README.md`
- `docs/INDEX.md`
- `docs/40_validation/VALIDATION_INDEX.md`
- `docs/50_stages/closed/STAGE_INDEX.md`

收尾复核结果：

- 文档 diff check 通过，仅有既有 CRLF warning。
- 入口索引已能命中 ART-20 closeout。
- `tools/validate_art20_ui_asset_pipeline.ps1` 当前复跑失败，原因是 `Godot/GraytailGodot/assets/ui/art20/**` 下存在 `.png.import` generated side effects。
- 本次收尾未删除、清理、reset、stash、commit 或 push。

当前 commit / push 前置：

```text
1. 审查 ART20 .png.import generated side effects。
2. 明确这些 generated files 是否删除、忽略或单独归属。
3. 复跑 tools/validate_art20_ui_asset_pipeline.ps1。
4. 只 stage 明确归属的 ART20 / closeout 文件。
```

本文件不授权 commit / push，也不清理当前工作树 dirty。
