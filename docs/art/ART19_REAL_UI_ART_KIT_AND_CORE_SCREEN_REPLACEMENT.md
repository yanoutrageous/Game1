# ART-19 真实 UI 美术素材套件接入与四核心界面首批替换

## 0. 文档定位

ART-19 是真实 UI PNG 美术素材进入 Godot runtime 的首批执行阶段。它接续 ART-18 / ART-18R 的布局重建成果，目标不是继续调整坐标，而是让四核心界面开始消费 manifest-backed runtime UI 素材。

本阶段不代表最终视觉 QA 完成，不进入 ART-20，不提交、不 push。

## 1. 执行边界

- 修改外部 `sources/art`：否。
- 修改外部 `sources/draw`：否。
- 修改旧 `Base Art` / `Draw` / `Connection`：否。
- 直接 runtime 读取外部 source 路径：否。
- 直接把 Base 确定稿整屏图作为 runtime UI：否。
- 修改 core command / save / run 语义：否。
- 修改 Godot runtime UI assets：是，仅 `Godot/GraytailGodot/assets/ui/art19/**`。
- 修改 `asset_manifest.csv`：是，仅追加 `ui.art19.*` 首批素材行。
- commit / push：否。

## 2. 执行前环境与 dirty 分类

执行基线：

- git root：`D:/AGAME1/_repo_cache/Game1_work`
- 分支：`main`
- HEAD：`e94389f578031c3b114afda95efee6a27cb30cd4`
- 最新提交：`e94389f docs(project): classify active repo duplicate assets`
- 保护性 stash：存在，未操作。

执行前已存在且不属于 ART-19 成果的 dirty：

- `Godot/GraytailGodot/project.godot`
- `docs/README.md`
- `docs/INDEX.md`
- `docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`
- ART-18 / ART-18R 文档、截图与验证脚本。
- `Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd`

ART-19 成果 dirty：

- `Godot/GraytailGodot/assets/ui/art19/**`
- `Godot/GraytailGodot/data/assets/asset_manifest.csv`
- `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`
- `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd`
- `Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd`
- `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd`
- `Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd`
- `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd`
- `Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd`
- `tools/validate_art19_real_ui_assets.ps1`
- `docs/art/ART19_REAL_UI_ART_KIT_AND_CORE_SCREEN_REPLACEMENT.md`
- `docs/art/validation/art19/**`

## 3. 素材导入

本轮从 `sources/draw/30_game_ready` 复制 16 个低风险 UI PNG 到 Godot runtime：

- 面板：terminal main、deploy main、deploy summary、frame highlight。
- 按钮：dark button、confirm deploy button、selected tab button。
- 信息条 / 装饰：summary bar、vertical scrollbar。
- MapOverlay 64px 图标：player、unknown、explored、scanned、mine、chest、exit。

导入详情见：

- `docs/art/validation/art19/ART19_IMPORTED_ASSET_REPORT.md`
- `docs/art/validation/art19/ART19_UI_ASSET_KIT_MAPPING.md`

## 4. Manifest 与 mapping

`asset_manifest.csv` 追加 16 个 `ui.art19.*` asset_id。manifest 快检结果：

```text
DuplicateAssetIds: none
MissingPaths: none
Art19Rows: 16
```

Presentation 出口：

- `Art09ManifestAssetMapping.art19_skin_ref()`
- `Art09ManifestAssetMapping.art19_map64_ref()`
- `PresentationMapping.art19_skin_ref()`
- `PresentationMapping.art19_map64_ref()`

UI 使用策略：

- `Art10UISkinKit` 优先通过 `StyleBoxTexture` 使用 ART-19 PNG。
- 素材缺失时 fallback 到原有 StyleBoxFlat，避免硬崩。
- 四核心界面不拼接外部 source 路径，只消费 manifest-backed asset_id。

## 5. 四核心界面替换结果

### 主菜单

- 右侧入口按钮板接入 `ui.art19.panel.terminal_main`。
- 大按钮、公告条、meta 区接入 ART-19 按钮 / 信息条 / 摘要面板。
- 截图：`docs/art/validation/art19/art19_main_menu_1280x720.png`

### 出发探索

- 中区路线框接入 `ui.art19.panel.deploy_main`。
- 右侧摘要和开始探索按钮接入 `ui.art19.panel.deploy_summary` 与 `ui.art19.button.confirm`。
- 截图：`docs/art/validation/art19/art19_deploy_prep_1280x720.png`

### 长期系统

- 左侧档案、中收藏墙、右详情短模块接入 ART-19 面板素材。
- 图鉴墙方向比 ART-18R 更明确，但仍保留后续字体与内容密度债务。
- 截图：`docs/art/validation/art19/art19_long_term_1280x720.png`

### Run HUD / MapOverlay

- Run HUD 左侧固定栏、右上状态卡、底部信息条和快捷键按钮接入 ART-19 面板 / 按钮 / 信息条。
- MapOverlay 使用 `ui.art19.map64.*` 标记图标。
- 截图：
  - `docs/art/validation/art19/art19_run_hud_1280x720.png`
  - `docs/art/validation/art19/art19_map_overlay_1280x720.png`

## 6. Computer Use 截图判断

实际运行 Godot 后完成四核心界面和 MapOverlay 截图。客观判断如下：

- 四核心界面均能看到真实 PNG 面板、按钮或地图图标，不再只是脚本线框。
- Run HUD 未回退成右侧整栏，主游戏画面仍是主要区域。
- MapOverlay 已有真实地图格 / marker 视觉。
- 部分页面仍有小字偏密、局部可读性一般的问题，这不是 ART-19 的完全视觉完成项，需要后续继续处理。

## 7. 验证

已执行或要求执行的验证：

```powershell
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_art19_real_ui_assets.ps1
& 'D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot' --quit
```

验证目标：

- `asset_manifest.csv` 可解析，asset_id 唯一。
- `ui.art19.*` 必要 asset_id 全部存在。
- manifest 指向路径存在。
- `Art09ManifestAssetMapping` / `PresentationMapping` / `Art10UISkinKit` / MapOverlay 均有 ART-19 接口或消费点。
- `scripts/presentation` 与 `scripts/ui` 不包含外部 source runtime hardcode。
- 不出现 core command / save 禁止 dirty。

## 8. 暂缓内容

- 最终页面级背景。
- 最终角色立绘。
- 完整动效和音画反馈。
- 更完整的物品、装备、奖励、状态图标套件。
- 文本密度、字号、行高和字体细节 polish。
- 更成熟的 1600x900 / 1920x1080 多分辨率截图矩阵。

## 9. 后续进入 ART-20 条件

ART-20 应在 ART-19 审计验收后再启动。建议重点：

- 扩充真实 UI 素材套件和页面级背景。
- 替换剩余工程感文本块和临时 slot。
- 做字体层级、按钮状态、hover / selected / reward / warning 的完整 QA。
- 基于 1280x720、1600x900、1920x1080 重新截图验收。
