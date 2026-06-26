# ART-11 UI 产品化视觉系统重建与核心界面落地

## 0. 文档定位

ART-11 记录 UI 产品化底座与核心界面落地结果。它承接 ART-10R 的视觉返工，不代表最终视觉 QA、最终素材替换或完整玩法内容完成。

本阶段不提交 Godot generated side effects，不导入 Base Art / Draw 原图，不修改 gameplay core / run / command / save 规则。

## 1. 基线对比结论

Slice 0 通过 Computer Use 记录了主菜单、出发探索、长期系统和 HUD 的基线截图，并对照 Base 三张确定稿与 M1 / Lua demo。主要差距集中在显示模式、布局硬编码、背景语义、角色锚点、组件状态、玩家文案密度和 HUD 信息结构。

## 2. UI 系统底座

ART-11 将 Skin Kit 从单纯样式 helper 推进为组件库入口，覆盖 panel、button、tab、card、slot、badge、key bar、summary panel、notice box、locked overlay 和 selected glow 等基础组件。

统一入口包括字体 token、受控 icon size、visual state tone、layout profile 和文案清洗函数。

## 3. 显示模式 / 全屏 / safe area

Slice 1 解除了 SettingsManager 对窗口尺寸的 1280x720 硬锁，建立 `UILayoutProfile` 的 viewport、content scale、safe margin、grid unit 和 column gap。主菜单已接入 profile-based rect / size 转换，并完成 1280x720、1600x900、1920x1080 三档验证。

当前仍保留 Windows 标题栏；borderless/fullscreen 产品化设置不在本阶段完成范围内。

## 4. 组件库与 visual state

组件状态覆盖 normal、hover、selected、disabled、locked、warning、danger、new、reward、ready，并兼容已有 preview / owned / configured / pending 数据状态。按钮 icon 通过 Skin Kit 控制尺寸，避免 `expand_icon` 撑爆控件。

## 5. 背景分层与角色展示

主菜单增加基地门厅、门框、暖光、前景线和角色舱视觉锚点。出发探索增加控制室、地图网格、整备剪影。长期系统增加档案室、架线、头像剪影和详情灯线。HUD 增加扫描器、房间焦点、协议警戒和底部 key bar 光层。

这些仍是程序化视觉层，后续可替换为 manifest-backed runtime 素材。

## 6. 主菜单落地

主菜单已形成左侧角色展示、右侧大型入口按钮、顶部小入口、公告框和底部 key bar。Slice 4 进一步压缩入口副标题和公告数量，降低工程报告感。

## 7. 出发探索落地

出发探索保持左侧整备展示、中间路线 / 目标卡片、右侧摘要和底部开始探索按钮。Slice 4 压缩左侧说明、卡片内容和详情区行数，减少重叠与截断风险。

## 8. 长期系统落地

长期系统形成左侧角色档案、中间卡片网格、右侧详情栏。Slice 4 将卡片从三行压为两行，并缩短左栏、详情栏和联动说明，避免文本压缩。

## 9. HUD / runtime UI 落地

HUD 参考 M1 / Lua demo 的左扫描器、中央房间、右协议状态和底部 key bar 结构。Slice 3 统一 key prompt，Slice 4 将右侧状态行数限制为常驻摘要，详细信息保留在 tooltip / 后续详情入口。

## 10. inventory / loot 跟随适配

inventory 已接入 Skin Kit 的受控 icon 策略，避免物品图标撑爆按钮。loot 相关工程语义通过 Skin Kit 文案清洗降低玩家可见风险。完整 inventory / loot 产品化仍留给后续阶段。

## 11. 文案降噪策略

主界面只保留决策信息；长说明进入 tooltip、detail panel 或文档。玩家界面避免直出 preview、read_only、display_only、schema、interface、G24、G30、slot、Legacy、Debug 等工程语义。

Slice 4 已压缩主菜单公告、出发探索左栏 / 卡片 / 详情、长期系统卡片 / 详情、HUD 右侧状态。

## 12. 截图 QA 与验证结果

最终截图落点：

- `docs/art/validation/art11/art11_main_menu_1280x720.png`
- `docs/art/validation/art11/art11_deploy_prep_1280x720.png`
- `docs/art/validation/art11/art11_long_term_1280x720.png`
- `docs/art/validation/art11/art11_run_hud_1280x720.png`
- `docs/art/validation/art11/art11_main_menu_1600x900.png`
- `docs/art/validation/art11/art11_deploy_prep_1600x900.png`
- `docs/art/validation/art11/art11_long_term_1600x900.png`
- `docs/art/validation/art11/art11_run_hud_1600x900.png`
- `docs/art/validation/art11/art11_main_menu_1920x1080.png`
- `docs/art/validation/art11/art11_deploy_prep_1920x1080.png`
- `docs/art/validation/art11/art11_long_term_1920x1080.png`
- `docs/art/validation/art11/art11_run_hud_1920x1080.png`

验证脚本：`tools/validate_art11_ui_productization.ps1`。

## 13. generated side effects 策略

以下内容继续按 generated side effects 隔离，不自动纳入 ART-11 成果：

- `project.godot`
- `*.translation`
- `*.uid`
- `.import`
- `.godot`

审查 / 提交前必须单独确认这些文件是否排除，执行框不执行 git add / commit / push。

## 14. 暂缓内容

暂缓完整 borderless/fullscreen 设置 UI、最终美术素材替换、长期系统完整玩法、inventory / loot 完整产品化、完整动画、新生图、真实角色立绘导入、ART-12 polish。

## 15. 后续进入 ART-12 条件

进入 ART-12 前需要完成审查框验收，确认截图 QA 通过、generated side effects 分类清楚、提交边界明确，并列出下一轮 polish / 视觉 QA / 素材补齐范围。
