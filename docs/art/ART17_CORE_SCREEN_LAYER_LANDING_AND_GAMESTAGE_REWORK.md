# ART-17 四核心界面图层职责落地与 Run GameStage 重构

## 0. 文档定位

ART-17 是 ART-16 `ui_layer_contract` 的落地执行记录。它不是 ART-15 的继续坐标补丁，也不是新增素材阶段。

本阶段目标是把主菜单、出发探索、长期系统、Run HUD / MapOverlay 的图层职责落到真实节点根结构，尤其修正 Run HUD 中“房间画面被 UI 框架挤压或遮挡”的根问题。

## 1. 基线问题

执行前截图显示四个界面已能运行，但仍依赖大量同级节点和局部 `z_index`。Run HUD 的核心风险是房间画面、左侧状态栏、右上协议卡、底部操作条和交互提示混在同一个 Control 子树中，后续继续补坐标会增加遮挡风险。

已保存基线截图：

- `docs/art/validation/art17/baseline_main_menu.png`
- `docs/art/validation/art17/baseline_deploy_prep.png`
- `docs/art/validation/art17/baseline_long_term.png`
- `docs/art/validation/art17/baseline_run_hud.png`
- `docs/art/validation/art17/baseline_map_overlay.png`

## 2. UI Layer Contract 落地

`Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd` 扩展为包含根容器职责：

- 页面根：`BackgroundRoot`、`DecorationRoot`、`CharacterRoot`、`MainContentRoot`、`SideStatusRoot`、`PrimaryActionRoot`、`FloatingInfoRoot`、`OverlayRoot`、`ModalRoot`
- Run 根：`RunGameStageRoot`、`RunRoomViewportRoot`、`RunLeftInfoRailRoot`、`RunTopRightStatusRoot`、`RunFloatingInfoRoot`、`RunInteractionPromptRoot`、`RunActionOverlayRoot`、`RunOverlayRoot`、`RunModalRoot`

根容器负责绝对层级，根内子节点只使用局部层级。这样避免每个界面继续各自堆 `z_index`。

## 3. 主菜单落地

`main_menu_shell.gd` 在 build 后建立页面根，并按合约归类现有节点。

验证重点：

- 背景与氛围层位于背景 / 装饰根。
- 角色展示在 `CharacterRoot`。
- 右侧入口按钮和底部快捷入口在 `PrimaryActionRoot`。
- 公告、状态摘要等不再和背景节点同级混排。

## 4. 出发探索落地

`deploy_prep_shell.gd` 建立同一套页面根。由于筛选按钮和路线卡会随模型刷新，`_refresh_view()` 结束后会重新执行根归类，防止动态节点游离在根层之外。

验证重点：

- 左侧角色展示、中间路线卡、右侧摘要和底部主操作各自进入对应职责根。
- 动态筛选按钮仍可重建并进入根结构。
- 没有修改出发规则和 run start payload 语义。

## 5. 长期系统落地

`long_term_shell.gd` 建立同一套页面根。卡片网格随模型刷新后重新归类。

验证重点：

- 左侧角色 / 档案视觉、中间收藏墙、右侧档案短模块分层稳定。
- 模块切换后的动态卡片继续挂在根结构中。
- 没有实现新的长期玩法。

## 6. Run GameStage 重构

`run_surface.gd` 从同级节点混排调整为 Run 专用根：

- `RunGameStageRoot` 承载游戏主画面阶段。
- `RunRoomViewportRoot` 承载房间背景、房间视觉和主游戏画面。
- `RunLeftInfoRailRoot` 承载左侧固定状态栏。
- `RunTopRightStatusRoot` 承载右上角协议 / 压力小状态卡。
- `RunFloatingInfoRoot` 承载主信息栏和顶部房间短提示。
- `RunInteractionPromptRoot` 承载贴近对象的交互提示。
- `RunActionOverlayRoot` 承载底部快捷键栏。
- `RunOverlayRoot` 与 `RunModalRoot` 承载 overlay / modal。

本阶段移除了 Run HUD 内局部 `z_index = 420/421` 的强压层写法，改由根容器和根内局部顺序决定叠放。

后续实机复核发现，仅去掉右侧常驻栏还不够：房间画面如果仍按假定容器 fit，会变成“小房间漂在灰底上”。因此 `run_scene.gd` 的 GameStage 布局改为读取当前房间背景 sprite 的实际可见尺寸，并对左栏之外的 gameplay 区域执行 cover 缩放。这样后续替换房间美术时，布局依据实际贴图尺寸重新计算，而不是绑定某一张临时图的固定坐标。

## 7. MapOverlay 关系

MapOverlay 继续作为 Run overlay 使用。实机验证中，地图展开后会形成明显的大地图层，而不是点击小地图后无变化；底层房间仍可从遮罩下辨识，说明它是运行态 overlay，而不是重新切出常驻右侧 UI 栏。

## 8. 截图验证

ART-17 1280 档截图：

- `docs/art/validation/art17/art17_main_menu_1280x720.png`
- `docs/art/validation/art17/art17_deploy_prep_1280x720.png`
- `docs/art/validation/art17/art17_long_term_1280x720.png`
- `docs/art/validation/art17/art17_run_hud_1280x720.png`
- `docs/art/validation/art17/art17_map_overlay_1280x720.png`

本轮最终高清复核截图：

- `docs/art/validation/art17/art17_main_menu_max_final.png`
- `docs/art/validation/art17/art17_deploy_max_final.png`
- `docs/art/validation/art17/art17_long_term_max_final.png`
- `docs/art/validation/art17/art17_run_hud_max_final.png`
- `docs/art/validation/art17/art17_map_overlay_max_final.png`

当前可视结论：

- 四个核心页面没有因根重排变成空白。
- Run HUD 保持“左侧固定栏 + 左栏之外完整游戏画面 + 右上小状态卡 + 底部信息 / 快捷键覆盖层”。
- MapOverlay 展开后与普通 HUD 有明确差异，符合“大地图 overlay”定位。

## 9. 静态验证

新增脚本：

`tools/validate_art17_core_screen_layering.ps1`

验证内容：

- ART17 文档和截图存在。
- 四核心页面和 Run 根名称存在。
- 不存在 `expand_icon = true`。
- 不存在 UI / presentation 对 `D:\AGAME1\Base Art`、`D:\AGAME1\Draw`、`D:\AGAME1\Connection` 的 runtime 硬编码。
- 不存在高位 `z_index` 绕过。
- `core/command`、`core/save` 无 tracked 语义 diff。
- generated side effects 和既有 `asset_manifest.csv` dirty 只作为 warning 分类。

## 10. 未纳入内容

本阶段没有处理：

- 新素材导入。
- `asset_manifest.csv` 登记。
- 角色立绘最终替换。
- 长期系统完整玩法。
- 出发探索路线系统玩法扩展。
- `core/run`、`core/command`、`core/save` 语义改动。
- commit / push。

## 11. generated side effects 策略

当前工作区存在历史 Godot generated side effects，例如 `project.godot`、`*.translation`、`*.uid`、`.import` / `.godot` 相关文件。ART-17 不清理、不 reset、不 stash、不 stage 这些内容，只在报告和验证脚本中分类提示。

## 12. 后续进入 ART-18 条件

进入后续阶段前，需要审计框用 Computer Use 复核：

- 四核心页面根层职责是否真实生效。
- Run HUD 是否继续满足用户手绘图方向：左侧固定栏、右侧大面积游戏画面、右上角状态小遮挡、底部信息和快捷键覆盖层。
- 当前文案密度、比例和美术素材替换需求是否作为后续 polish / 新素材阶段处理，而不是回到 ART-15 式局部堆 z_index。
