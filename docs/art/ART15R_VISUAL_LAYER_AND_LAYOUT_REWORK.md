# ART-15R 核心界面视觉返工与布局重建

## 0. 文档定位

ART-15R 是 ART-15 后的视觉层与布局返工记录。本文档记录 UI / presentation 层的布局、资源映射和截图验证结果，不代表玩法流程、返回主菜单、前往长期系统或退出当局逻辑已经实现。

本阶段不直接读取 Base Art 或 Draw，不把确定稿整屏图作为 runtime 背景，不提交，不 push。

## 1. 需求理解

出发探索和长期系统采用同源产品布局：

- 左侧固定角色外观展示区。
- 中间为主要内容区，承载一级页签、二级筛选、卡片列表或图鉴墙。
- 右侧为固定摘要 / 档案栏，承载装备、消耗品、等级、主线、资源、奖励和开始探索等关键操作位。

局内 HUD 采用用户调正后的手绘图语义：

- 左侧约 20%-25% 为固定状态栏，小地图、血量 / 战力 / 黑币 / 金币、背包入口。
- 右侧约 70% 除底部操作说明外都应尽量还给实际游戏画面。
- 右上角协议 / 压力只作为小状态卡遮挡，不形成整列右栏。
- 场景内交互提示保持小型浮层，贴近对象。
- 底部上方是主信息栏，最底部是快捷键栏。

## 2. 已有资产对应

ART-15 已完成首批 runtime 资产对应，ART-15R 继续复用这些 manifest-backed 资产：

- 主菜单背景：`ui.main_menu.background.no_text`。
- 出发探索按钮、图标、面板：`ui.deploy.button.*`、`ui.deploy.icon.*`、`ui.deploy.panel.*`。
- HUD 面板、反馈条、key prompt：`ui.hud.*`、`ui.feedback.*`、`ui.key_prompt.*`。
- 角色图：`sprite.player.*`。
- 房间背景：`room.background.*`。
- 物品图标：`item.consumable.*`、`item.equipment.*`、`item.recovered.*`。

本阶段没有把未来新美术图尺寸写死到逻辑里。新增布局调整仍通过 Skin Kit 区域 token、页面布局区域和 manifest / PresentationMapping 解析资源。后续新增或替换图片时，优先更新 asset manifest、PresentationMapping 或 Skin Kit layout spec，而不是在页面中写外部图片路径。

## 3. 出发探索返工

返工方向：

- 左侧保留角色 / 出勤者展示，不再放装备槽。
- 顶部一级页签放在中间内容区顶部，不挤占右侧栏。
- 二级筛选压缩为单行横向按钮，避免换行压缩详情页。
- 中间卡片区增高，减少无效空白。
- 右侧摘要整体上移，固定显示摘要、配置、装备 / 消耗品、效果、风险。
- 继续 / 终止按钮上移到开始探索按钮上方，开始探索保持最强视觉焦点。

仍暂缓：

- 返回主菜单和长期系统按钮只作为视觉位；真实流程由 M4 接入。
- 装备 / 消耗品最终图标状态仍依赖后续完整美术和数据接线。

## 4. 长期系统返工

返工方向：

- 左侧固定角色外观展示，底部保留“设置外观”按钮。
- 中间从详情页式结构改为图鉴 / 收藏 / 记录墙。
- 右侧固定档案栏，显示等级、主线、记录、资历、联动等短模块。
- 中间卡片不足时补充锁定档案位，避免大面积空置。
- 去除乱码标题和英文说明候选，改为中文短文案。

仍暂缓：

- 完整长期系统玩法、拍卖、研究、收藏真实经济。
- 最终角色立绘和外观系统。

## 5. 局内 HUD 返工

返工方向：

- 左侧栏按 20%-25% 宽度组织小地图、状态和背包入口。
- 右侧协议 / 压力压缩为右上角小状态卡。
- 奖励 / 事件不再占整列右栏。
- 主信息条固定到底部操作栏上方。
- 新增房间视觉填充层，走 `PresentationMapping.room_visual_from_snapshot()` 和 manifest 背景资源，使右侧 70% 更接近实际游戏画面。

该房间视觉填充层是可替换的 presentation 层，不修改 `core/run`，不读取 Base Art / Draw，也不把某一张背景图尺寸写死。

## 6. MapOverlay / Inventory / GroundLoot

MapOverlay 已调整：

- 降低全屏暗化强度。
- 地图展开面板贴近右侧实际游戏画面区域。
- 缩短顶部 / 底部说明，避免全屏黑雾感。
- ART-15R2 进一步降低暗罩并缩小面板，确保展开地图时房间画面仍可辨识。

Inventory / GroundLoot 仍需通过最终截图确认：

- 背包应形成清晰容器。
- 地面掉落应形成可读的拾取确认界面。
- 二者不应继续像 debug overlay。

## 7. 比例与空置修正

本阶段按用户反馈同步修正比例问题：

- 出发探索右栏上移，中间卡片区域加高。
- 长期系统中间区补足记录墙，减少空白。
- 局内 HUD 将右侧大部分面积还给房间视觉，只保留右上小状态卡。
- 文本说明继续压缩，优先保留决策信息和短状态。

## 8. ART-15R2 定点返修记录

ART-15R2 根据审计复核补充以下定点修正：

- 局内 HUD 左侧固定栏从接近 30% 调整到约 20%-25%，扩大中央与右侧实际游戏画面。
- 右上协议 / 压力继续保持小浮动卡，不形成右侧固定栏。
- 场景内物品 / 搜索提示缩小为小浮层，避免抢占画面中心。
- 底部主信息栏和操作快捷键栏分区更明确，快捷键按钮尺寸放大。
- MapOverlay 暗罩降低，地图面板缩小并上移，保留房间画面的可见性。
- 出发探索强化选中路线卡的地图节点层级，继续 / 终止按钮移动到开始探索上方。
- 长期系统右侧档案栏改为等级、主线、资历、资源、奖励短模块，中区收藏墙减少重复状态文本。

## 9. ART-15R3 HUD 定点修复记录

ART-15R3 根据审计复核只处理局内 HUD 阻断问题：

- 左侧固定栏内容整体内收，避免任何标题、状态或说明文字贴到窗口边缘。
- 小地图控件按当前栏宽重新布局并裁剪内部内容，避免网格或提示文本溢出到窗口边缘。
- 底部主信息栏改为单行短句预算，不再把长反馈文案压到快捷键按钮区域。
- 底部快捷键按钮禁用长 tooltip 直出，避免 hover 时出现长句覆盖按钮栏。
- MapOverlay 未做大拆，只确认展开地图和关闭后 HUD 未出现布局回退。

## 10. 图层显式化补充

后续实机复查确认，核心问题不只是比例，而是多个页面长期依赖 `add_child()` 创建顺序决定叠放关系。该方式会让背景、遮罩、frame、贴图、文字、按钮和浮层混在同一层级中，后续换图或新增控件时容易再次互相覆盖。

本轮补充修正：

- `run_surface.gd` 增加显式层级常量和 `_apply_layer_order()`，将房间背景、场景遮罩、结构面板、内容遮罩、文本内容、交互提示、底部栏、overlay、modal 分离。
- 主菜单、出发探索、长期系统增加页面级 `_apply_layer_order()`，按背景、氛围 / 遮罩、frame / texture、角色层、内容层、按钮层归类。
- `MiniMapPanel` 取消 marker native tooltip，并让 marker click 明确转发打开地图信号，避免系统 tooltip 横跨主游戏画面。
- `MapOverlayPanel` 取消格子按钮 native tooltip。格子详情只应进入面板内部短详情，不再通过系统 tooltip 压到房间画面上。

实机结果：

- 局内普通态已恢复为左侧固定栏、右侧主游戏画面、右上小状态卡、底部信息 / 快捷键栏的层级关系。
- 点击小地图后不再出现跨栏大 tooltip，主游戏画面不会被 marker 详情说明遮挡。
- 当前实机中 MapOverlay 展开触发仍不稳定；由于打开逻辑在 `core/run/run_scene.gd` 连接链路中，本轮未修改 core/run 语义，只完成 UI 层防遮挡处理。

新增验证截图：

- `docs/art/validation/art15/art15r_layer_fix_run_after_tooltip_patch.png`
- `docs/art/validation/art15/art15r_layer_fix_map_overlay_after_tooltip_patch.png`
- `docs/art/validation/art15/art15r_layer_fix_map_key_m.png`
- `docs/art/validation/art15/art15r_layer_fix_map_key_tab.png`

## 11. 验证产物

目标截图路径：

- `docs/art/validation/art15/art15r_main_menu_1280x720.png`
- `docs/art/validation/art15/art15r_deploy_prep_1280x720.png`
- `docs/art/validation/art15/art15r_long_term_1280x720.png`
- `docs/art/validation/art15/art15r_run_hud_1280x720.png`
- `docs/art/validation/art15/art15r_map_overlay_1280x720.png`
- `docs/art/validation/art15/art15r_inventory_1280x720.png`
- `docs/art/validation/art15/art15r_ground_loot_1280x720.png`
- `docs/art/validation/art15/art15r2_run_hud_1280x720.png`
- `docs/art/validation/art15/art15r2_map_overlay_1280x720.png`
- `docs/art/validation/art15/art15r2_deploy_prep_1280x720.png`
- `docs/art/validation/art15/art15r2_long_term_1280x720.png`
- `docs/art/validation/art15/art15r3_run_hud_1280x720.png`
- `docs/art/validation/art15/art15r3_map_overlay_1280x720.png`
- `docs/art/validation/art15/art15r3_run_hud_after_map_return_1280x720.png`
- `docs/art/validation/art15/art15r_deploy_prep_1600x900.png`
- `docs/art/validation/art15/art15r_long_term_1600x900.png`
- `docs/art/validation/art15/art15r_run_hud_1600x900.png`
- `docs/art/validation/art15/art15r_deploy_prep_1920x1080.png`
- `docs/art/validation/art15/art15r_long_term_1920x1080.png`
- `docs/art/validation/art15/art15r_run_hud_1920x1080.png`

验证脚本：

- `tools/validate_art15r_visual_layer_layout.ps1`

## 12. generated side effects

当前工作区存在 Godot generated side effects，例如 `.translation`、`.uid`、`.import`、`project.godot` 等。ART-15R 执行框不清理、不 reset、不 stash，这些副产物在报告中单独归类。

## 13. 暂缓内容

- 返回主菜单 / 前往长期系统 / 退出当局真实点击逻辑。
- 完整长期系统玩法。
- 完整背包经济和仓库经济。
- 终版角色立绘和动画。
- 新增大量美术图。
- ART-16 或后续 polish。

## 14. 后续条件

进入审计验收前必须完成：

- 1280x720 主菜单、出发探索、长期系统、HUD、MapOverlay、Inventory、GroundLoot 截图。
- 1600x900 / 1920x1080 出发探索、长期系统、HUD 截图。
- 静态验证脚本通过，或仅保留可解释 warning。
- 明确未修改 Base Art、Draw、Connection 和 core/run / core/command / core/save 语义。
