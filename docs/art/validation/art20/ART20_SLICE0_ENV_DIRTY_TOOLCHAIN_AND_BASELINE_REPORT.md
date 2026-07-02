# ART-20 Slice 0 执行报告

## 0. 执行边界

- 是否修改 source 原始素材：否。
- 是否写 ART-20 staging：否。
- 是否写 cut output：否。
- 是否写 Godot：否。
- 是否修改 manifest：否。
- 是否运行 Godot：是，仅用于 Computer Use baseline 截图。
- 是否 commit / push：否。
- 是否操作 stash：否。

## 1. 本切片目标

Slice 0 目标是恢复上下文、确认 dirty 和边界、复核 ART19 / ART19R1 输入、只读查看旧工具链算法点，并捕获当前 Godot 五类 baseline 截图。

本切片不做 staging、不切图、不导入 runtime asset、不修改 UI 代码、不修改 `asset_manifest.csv`。

## 2. 环境自检

- git root：`D:/AGAME1/_repo_cache/Game1_work`
- 当前分支：`main`
- 当前 HEAD：`e94389f578031c3b114afda95efee6a27cb30cd4`
- 最新提交：`e94389f docs(project): classify active repo duplicate assets`
- 保护性 stash：存在，`stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`
- staged files：无。

当前 `git status --short` 含大量前置 dirty；这些不是 ART-20 Slice 0 产物。

## 3. dirty 分类

### 既有 Godot generated / editor side effects

- `Godot/GraytailGodot/project.godot`
- `Godot/GraytailGodot/data/assets/asset_manifest.*.translation`

### 既有 ART-18 / ART-19 UI 与 manifest dirty

- `Godot/GraytailGodot/data/assets/asset_manifest.csv`
- `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`
- `Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd`
- `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd`
- `Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd`
- `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd`
- `Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd`
- `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd`
- `Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd`
- `Godot/GraytailGodot/assets/ui/art19/`
- `docs/art/ART18*.md`
- `docs/art/ART19_REAL_UI_ART_KIT_AND_CORE_SCREEN_REPLACEMENT.md`
- `docs/art/validation/art18/`
- `docs/art/validation/art18r/`
- `docs/art/validation/art19/`
- `tools/validate_art18*.ps1`
- `tools/validate_art19_real_ui_assets.ps1`

### 既有文档治理 dirty

- `docs/README.md`
- `docs/INDEX.md`
- `docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`

### 既有 ART-19R1 产物

- `docs/art/ART19R1_UI_ASSET_GOVERNANCE_AND_CUTTING_PREP.md`
- `docs/art/validation/art19r1/`
- `tools/validate_art19r1_asset_governance.ps1`

### ART-20 Slice 0 新增产物

- `docs/art/ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION_PLAN.md`
- `docs/art/validation/art20/ART20_SLICE0_ENV_DIRTY_TOOLCHAIN_AND_BASELINE_REPORT.md`
- `docs/art/validation/art20/baseline_main_menu.png`
- `docs/art/validation/art20/baseline_deploy_prep.png`
- `docs/art/validation/art20/baseline_deploy_prep_after_long_term.png`
- `docs/art/validation/art20/baseline_long_term.png`
- `docs/art/validation/art20/baseline_run_hud.png`
- `docs/art/validation/art20/baseline_map_overlay.png`

## 4. 读取路径与参考材料

已读取：

- `docs/README.md`
- `docs/INDEX.md`
- `docs/00_governance/DOC_PLACEMENT_STANDARD.md`
- `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md`
- `docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`
- `docs/art/ART15R_VISUAL_LAYER_AND_LAYOUT_REWORK.md`
- `docs/art/ART16_CORE_UI_DECOUPLING_AND_RELAYOUT.md`
- `docs/art/ART17_CORE_SCREEN_LAYER_LANDING_AND_GAMESTAGE_REWORK.md`
- `docs/art/ART18_REFERENCE_DRIVEN_UI_LAYOUT_TARGET.md`
- `docs/art/ART18_REFERENCE_DRIVEN_CORE_UI_PRODUCT_LAYOUT.md`
- `docs/art/ART19R1_UI_ASSET_GOVERNANCE_AND_CUTTING_PREP.md`
- `docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.csv`
- `docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv`
- `docs/art/validation/art19r1/ART19_IMPORTED_ASSET_REVIEW.csv`

已查看 / 确认：

- `D:\AGAME1\sources\art\Base\主菜单示例.png`
- `D:\AGAME1\sources\art\Base\出发探索确定.png`
- `D:\AGAME1\sources\art\Base\长期系统确定.png`
- `D:\AGAME1\sources\art\M1\Lua demo.mp4`
- `D:\AGAME1\sources\art\M1\*.png`
- `docs/art/validation/art15/art15r_user_layout_reference_run_hud.jpg`
- `docs/art/validation/art15/art15r_user_layout_reference_deploy_long_term.jpg`

## 5. ART19 / ART19R1 反例复核

ART19R1 的有效结论：

- ART19 已导入素材来源可追溯，但语义范围偏宽。
- `ui.art19.panel.terminal_main` 不应继续作为主菜单 / 长期系统通用大容器。
- `ui.art19.panel.deploy_summary` 只适合小摘要卡。
- `ui.art19.button.confirm` 适合出发探索主按钮，不应无审查升级为全局 confirm。
- `ui.art19.button.selected_tab` 来源名含 talent，作为全局 selected tab 有命名风险。
- `ui.art19.map64.scanned` 不应长期兼任 event marker。

ART20 的处置原则：

- 不直接继承 ART19 的泛用替换策略。
- 先 staging，再切片，再 manifest，再 visual_key，再 UI 消费。
- `wrong_usage_risk` 必须通过命名、component_id、visual_key 和截图验收收敛。

## 6. 旧工具链只读复核

只读查看旧工具目录：

```text
D:\A GAME\26.5.30 GameJam\tools
```

发现可借鉴算法：

- `make_magenta_transparent`
- `crop_transparent_edges`
- alpha mask / bbox
- connected component detection
- manual bbox override
- sprite sheet split
- average hash / duplicate group
- manifest / report generation

不直接运行原因：

- 写入旧 `Draw/_manifest`、`Draw/20_processed`、`Draw/30_game_ready` 等路径。
- 旧路径不是 ART-20 规范工作区。
- 旧脚本包含生成、拆分、刷新报告等副作用。

## 7. Computer Use baseline

使用真实 Godot 项目：

```text
D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
```

Godot 可执行：

```text
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64.exe
```

已保存 baseline：

| 页面 | 截图 |
| --- | --- |
| 主菜单 | `docs/art/validation/art20/baseline_main_menu.png` |
| 出发探索 | `docs/art/validation/art20/baseline_deploy_prep.png` |
| 出发探索返程复核 | `docs/art/validation/art20/baseline_deploy_prep_after_long_term.png` |
| 长期系统 | `docs/art/validation/art20/baseline_long_term.png` |
| Run HUD | `docs/art/validation/art20/baseline_run_hud.png` |
| MapOverlay | `docs/art/validation/art20/baseline_map_overlay.png` |

截图尺寸均为 `856x511`。这是 Windows / Computer Use 当前捕获到的逻辑像素尺寸，不声明为 1280x720 高清验收，只作为 Slice 0 baseline。

## 8. baseline 观察

主菜单：

- 背景已可见，但右侧按钮和左侧角色仍主要依赖 ART19 面板质感。
- 当前完成度低于 Base 主菜单示例，后续需要真实按钮、公告框、keybar 和角色/背景素材链路。

出发探索：

- 已有左角色 / 中内容 / 右摘要结构。
- 中间路线卡和右侧模块仍依赖泛用框体和文字，视觉层级不如 Base 确定稿。
- 从长期系统返回后页面可达性可用。

长期系统：

- 已有左角色 / 中收藏墙 / 右档案短模块结构。
- 中间卡片仍显得像占位格，缺少明确组件切片和真实图鉴墙状态。

Run HUD：

- 当前布局接近“左固定栏 + 右侧游戏画面 + 右上小状态卡 + 底部覆盖层”。
- 但左栏和底部仍大量依赖 ART19 泛用 panel，后续必须由 ART20 组件替换。

MapOverlay：

- 可以通过 `M` 触发并与普通 HUD 有明显差异。
- 当前更像全屏地图 overlay，但仍依赖 ART19 红黑面板框体，后续需要按组件治理替换。

## 9. 自检结果

- source 原始素材未修改。
- `D:\AGAME1\sources\art\ART-20` 未创建。
- 未写 staging。
- 未写 cut output。
- 未写 Godot runtime asset。
- 未修改 `asset_manifest.csv`。
- 未操作 stash。
- staged files 为空。
- 未运行旧工具链。
- 已运行 Godot 做 baseline 截图，并已关闭窗口。

## 10. 风险 / 未完成项

- 当前工作区已有大量 ART18 / ART19 / generated / docs governance dirty，后续每个切片必须持续分类。
- Slice 0 baseline 受桌面缩放影响为 856x511，后续验收切片必须尽量获取更高清截图。
- ART-19 资源已接入但存在语义过宽风险，不能作为 ART20 默认正确输出。
- M1 目录当前未发现 `scripts/ui/HUD.lua` 等 Lua 源码文件，仅存在图片和 `Lua demo.mp4`；如后续需要 Lua 代码参考，需要审计或用户确认真实路径。

## 11. 请求审计

请“美术调整-审计”框使用 5.5xHigh / 5.5超高审计本 Slice，并判断是否允许进入 Slice 1。
