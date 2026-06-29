# ART-16 核心 UI 职责解耦与四界面重排

## 0. 文档定位

ART-16 记录在 ART-15 系列未完全收束且工作区已有 dirty / generated side effects 的前提下，对核心 UI 图层职责和四个主界面的重排执行结果。

本文档不是 Godot runtime 资产导入授权，不代表最终视觉 polish 完成，不授权提交 `asset_manifest.csv`、`project.godot`、`*.uid`、`*.translation`、`.import` 或 `.godot` 副产物。

## 1. 环境与 dirty 分类

执行前仓库位于 `D:\AGAME1\_repo_cache\Game1_work`，当前分支为 `main`，保护性 stash 存在。

dirty 分类：

- ART-15 / ART-15R 既有成果：UI shell、presentation、map overlay、ART15 文档与截图、少量已导入 UI 素材。
- Godot generated side effects：`project.godot`、`*.uid`、`*.translation`、`.import`、`.godot` 相关变更。
- ART-16 新成果：`ui_layer_contract.gd`、四界面接入层契约、HUD 左栏比例调整、ART16 截图、ART16 验证脚本与本文档。
- 风险项：`asset_manifest.csv` 和 ART15 素材目录仍为既有 dirty，ART-16 未把它们作为成果吸收。

## 2. Slice 0 基线复核

已使用真实 Godot 项目运行并通过 Computer Use 保存基线截图：

- `docs/art/validation/art16/baseline_main_menu.png`
- `docs/art/validation/art16/baseline_deploy_prep.png`
- `docs/art/validation/art16/baseline_long_term.png`
- `docs/art/validation/art16/baseline_run_hud.png`
- `docs/art/validation/art16/baseline_map_overlay.png`

基线结论：当前问题不是单纯素材缺口，而是多个页面在各自脚本中重复硬编码 `Rect2`、z 顺序、遮罩和职责，导致图层根结构不稳定。

## 3. Slice 1 UI 职责与图层契约

新增：

- `Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd`

统一层职责：

- `background`
- `gameplay_viewport`
- `character_display`
- `content_panel`
- `panel_texture`
- `content_text`
- `status_card`
- `floating_info`
- `action_bar`
- `overlay`
- `modal`

接入页面：

- `main_menu_shell.gd`
- `deploy_prep_shell.gd`
- `long_term_shell.gd`
- `run_surface.gd`
- `map_overlay_panel.gd`

修正点：角色展示层现在高于面板纹理，低于按钮和文字，避免主菜单、出发探索、长期系统的角色被面板压暗。

## 4. Slice 2 HUD / RunSurface 解耦重排

HUD 按用户调正手绘图和 M1 A1 参考执行：

- 左侧固定状态栏收敛到约 24.5%，不再接近 30%。
- 中央与右侧大区域保留为实际游戏画面。
- 右上角协议 / 压力为小状态卡，不形成整列右栏。
- 主信息栏为游戏画面下方的小浮动提示，不再作为全宽底部条。
- 快捷键栏与主信息栏分离。
- MapOverlay 只占左侧扫描区域，右侧房间仍可辨识。

`run_scene.gd` 只做 UI 装配边界改动：隐藏常驻 `Dev Debug` 浮动按钮，并把暂停菜单入口文案改为中文诊断入口；未修改 command、run rule、save/profile 语义。

## 5. Slice 3 出发探索 + 长期系统重排

出发探索当前结构：

- 左侧固定角色展示。
- 中区为路线 / 地图 / 行动选择。
- 顶部一级页签位于中区顶上，不侵占右栏。
- 二级筛选保持横向，不换行挤压详情区。
- 右侧为摘要、装备 / 消耗品、效果、风险短模块。
- 继续 / 终止位于开始探索上方。
- 开始探索保持底部主行动。

长期系统当前结构：

- 左侧固定角色外观展示和设置外观按钮。
- 中区为收藏与记录网格。
- 右侧固定显示等级、主线、资历、资源、奖励短模块。
- 不再用长段详情页占据主要区域。

## 6. Slice 4 主菜单重排

主菜单当前结构：

- 背景 / 门厅氛围 / 角色展示 / 入口按钮 / 公告 / 快捷键层级明确。
- 右侧大入口按钮保持主视觉权重。
- 左侧角色展示可读，不被面板纹理压住。
- 公告和行动记录保留为短信息，不承担长说明。

## 7. Slice 5 最终 QA 与文档

新增：

- `tools/validate_art16_ui_decoupling.ps1`
- `docs/art/ART16_CORE_UI_DECOUPLING_AND_RELAYOUT.md`
- `docs/art/validation/art16/**`

验证命令：

```powershell
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_art16_ui_decoupling.ps1
```

## 8. Computer Use 截图清单

1280x720：

- `docs/art/validation/art16/art16_main_menu_1280x720.png`
- `docs/art/validation/art16/art16_deploy_prep_1280x720.png`
- `docs/art/validation/art16/art16_long_term_1280x720.png`
- `docs/art/validation/art16/art16_run_hud_1280x720.png`
- `docs/art/validation/art16/art16_map_overlay_1280x720.png`

1600x900：

- `docs/art/validation/art16/art16_main_menu_1600x900.png`
- `docs/art/validation/art16/art16_deploy_prep_1600x900.png`
- `docs/art/validation/art16/art16_long_term_1600x900.png`
- `docs/art/validation/art16/art16_run_hud_1600x900.png`

1920x1080：

- `docs/art/validation/art16/art16_main_menu_1920x1080.png`
- `docs/art/validation/art16/art16_deploy_prep_1920x1080.png`
- `docs/art/validation/art16/art16_long_term_1920x1080.png`
- `docs/art/validation/art16/art16_run_hud_1920x1080.png`

说明：Computer Use 捕获的是桌面缩放后的逻辑像素；Godot 运行以 `--resolution` 启动对应档位，但截图文件实际像素受 Windows 缩放影响。

## 9. 禁止路径检查

ART-16 未修改：

- `D:\AGAME1\Base Art`
- `D:\AGAME1\Draw`
- `D:\AGAME1\Connection`
- `Godot/GraytailGodot/scripts/core/command/**`
- `Godot/GraytailGodot/scripts/core/save/**`

ART-16 未新增素材，未直接 runtime 读取 Base Art / Draw，未修改 `asset_manifest.csv` 作为本阶段成果。

## 10. generated side effects 策略

以下仍必须隔离，不作为 ART-16 成果默认提交：

- `project.godot`
- `*.uid`
- `*.translation`
- `.import`
- `.godot`
- 既有 `asset_manifest.csv` dirty
- ART15 素材和 ART15 文档 dirty

## 11. 暂缓内容

- 最终角色立绘和完整背景美术补齐。
- 真正发布级全屏 / borderless polish。
- ART15 已导入素材和 manifest dirty 的收口。
- HUD 内场景交互对象的最终动画和完整事件视觉。
- 更细的 inventory / loot 产品化重排。

## 12. 是否可进入 ART-16 审计验收

当前 ART-16 可进入审计验收，但存在需审计确认的风险：工作区仍包含 ART-15 既有成果和 Godot generated side effects，审计必须按 dirty 分类确认哪些属于 ART-16，哪些不得 stage / commit。
