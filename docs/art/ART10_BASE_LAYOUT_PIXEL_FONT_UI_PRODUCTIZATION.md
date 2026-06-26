# ART-10 Base 确定稿排版对齐与 M1/Lua 像素字体 UI 产品化

## 0. 文档定位

本文档记录 ART-10 的首轮 UI 产品化执行结果：以 Base 确定稿为排版基准，以 M1/Lua demo 为运行态结构参考，将 Godot UI 从工程 preview 进一步推向可审查的产品化界面。

本文档不代表最终视觉 QA 完成，不声明 Base Art 原图进入 runtime，不替代后续截图验收、字体授权确认或 ART-11 UI polish。本文档也不修改玩法规则、RunContext、CommandBus、TruthMap、存档或结算语义。

文档落位遵循仓库 docs 入口规则；本任务明确要求产物位于 `docs/art/ART10_BASE_LAYOUT_PIXEL_FONT_UI_PRODUCTIZATION.md`，因此保留在 `docs/art`。

## 1. 视觉基准

本轮参考 `D:\AGAME1\Base Art\Base` 中三张“确定”图：

- `主菜单确定.png`：用于主菜单全屏暗色机械背景、左侧角色展示占位、右侧主按钮组、公告框、底部快捷提示的结构参考。
- `出发探索确定.png`：用于 deploy prep 的左 / 中 / 右三栏、顶部 tab、二级筛选、卡片列表、右侧摘要和金色主按钮结构参考。
- `长期系统确定.png`：用于长期系统 shell 的顶部导航、横向 tab、左侧状态栏、中间卡片网格、右侧详情面板结构参考。

本轮参考 `D:\AGAME1\Base Art\M1` 中 Lua demo 及截图作为运行态结构参考，重点是左侧扫描 / 状态、中央房间区域、右侧协议 / 事件状态、底部 key bar。Lua 逻辑没有复制进 Godot。

## 2. 字体体系

字体优先来源：

```text
D:\AGAME1\_repo_cache\Game1_work\assets\Fonts\FusionPixel.otf
```

runtime 字体落点：

```text
Godot/GraytailGodot/assets/fonts/FusionPixel.otf
```

manifest-backed 记录：

```text
asset_id = ui.font.fusion_pixel
godot_path = res://assets/fonts/FusionPixel.otf
type = font
category = ui_font
license_status = pending_verification
source_status = pending_verification
```

`Art10UISkinKit.pixel_font()` 通过 `ContentDB.get_asset_ref("ui.font.fusion_pixel")` 解析字体；若字体不可用，Godot 默认字体仍作为 fallback，不阻断 UI 显示。字体授权状态保持 `pending_verification`，本轮不声明最终授权结论。

## 3. Skin Kit

新增 `Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd`，集中提供：

- title / body / muted / warning / danger 等文字颜色 token。
- panel / summary / danger / soft 等面板 StyleBox。
- primary / secondary / warning / danger / disabled 按钮 StyleBox。
- label / button / panel 应用函数。
- main menu、deploy prep、long term、run HUD 的参考布局 Rect token。
- 玩家可见文案 sanitizer，将 `preview`、`Debug`、`draft`、`Legacy`、`display_only`、`read_only` 等开发态词降级为产品界面可接受表述。

覆盖组件范围：

- 大按钮 / 小按钮
- tab
- panel
- card
- slot
- notice box
- summary panel
- bottom key bar
- selected / hover / disabled 状态

## 4. 主菜单产品化

修改文件：

```text
Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd
```

本轮主菜单保留 ART09 manifest-backed background asset，通过 Skin Kit 统一入口按钮、公告、meta 摘要、底部快捷入口的字体与按钮风格。玩家可见 `Debug` / `preview` 文案在显示出口进入 sanitizer。

本轮没有把 Base 确定稿整屏图直接当作 runtime UI，也没有引入 Base Art / Draw 绝对路径。

## 5. 出发探索产品化

修改文件：

```text
Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd
```

本轮 deploy prep 保留现有 DeployConfig / DeployPrepModel / RunStartRouteAdapter 数据语义，只对 UI 壳做产品化：

- 一级 tab、二级筛选按钮接入 Skin Kit。
- 卡片列表接入统一按钮样式。
- 右侧摘要 / 配置 / 效果 / 风险文本接入统一字体。
- 开始 / 继续 / 放弃按钮接入 primary / secondary / danger 风格。
- RunStartConfig 摘要文案从工程态 `id/bag/projection` 降级为更接近玩家界面的“出发配置 / 背包 / seed / 路线”。

本轮没有修改出发规则、背包容量规则、run start payload 语义或真实探索启动权限。

## 6. 长期系统 shell 产品化

修改文件：

```text
Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd
```

本轮长期系统只做 shell / visual frame：

- 增加左侧 profile column、中间 card grid column、右侧 detail column 的暗色三栏骨架。
- tab 按钮接入 Skin Kit，并区分 selected / secondary 状态。
- overview、module detail、snapshot、interface、history、next stage 文本统一进入 Skin Kit。
- 保留现有长期系统 placeholder / preview 数据，不实现完整长期系统玩法。

本轮没有写长期目标、解锁、历史、红点或奖励等真实 gameplay persistence。

## 7. 运行态 HUD 产品化

修改文件：

```text
Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd
Godot/GraytailGodot/scripts/ui/hud/hud.gd
Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd
Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd
```

本轮运行态 HUD 参考 M1/Lua 结构，但不复制 Lua 逻辑：

- 左侧扫描 / 小地图 / 资源区继续通过 ViewModel / snapshot 展示。
- 中央房间与目标信息不绕过现有 RunUIViewModel。
- 右侧协议 / 事件 / 奖励 / 命令反馈接入 Skin Kit 文案出口。
- 底部 action bar 接入 ART09 key prompt asset，并保持按钮 fallback。
- 背包与地面物品面板接入统一字体、按钮、命令反馈 sanitizer。

本轮没有修改 run rules、TruthMap、CommandBus、save-profile、拾取 / 丢弃 / 容量规则或指令权限。

## 8. 静态 / 可视验证结果

新增验证脚本：

```text
tools/validate_art10_ui_productization.ps1
```

已执行：

```text
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_art10_ui_productization.ps1
git diff --check
```

验证结果：

- ART-10 静态验证：PASS。
- FusionPixel source / target SHA256 一致。
- manifest 中 `ui.font.fusion_pixel` 唯一，且 `license_status` / `source_status` 均保持 `pending_verification`。
- UI 目标文件已接入 `Art10UISkinKitScript`。
- runtime UI 文件未硬编码 `D:\AGAME1\Base Art`、`D:\AGAME1\Draw` 或旧 GameJam Draw 作为 runtime 路径。
- `git diff --check` 通过，仅出现现有换行符 warning。

本轮未运行 Godot，因此没有生成截图验收结果，也不声明实际渲染 QA 通过。当前 `.uid`、`.translation`、`project.godot` 状态列为既有或 Godot generated side effects，不作为 ART-10 成果默认吸收。

## 9. 暂缓内容

本轮暂缓：

- 完整角色动画。
- 完整长期系统玩法。
- 最终主菜单美术。
- 全量 skin 替换。
- 新生成图片。
- 大规模 runtime 资源导入。
- 720p / 1080p / mobile 截图矩阵。
- Godot 实际运行截图 QA。
- 字体授权最终结论。
- 对模型层历史 `preview` 字段的全面重命名。

这些内容需要在审查确认后进入更小范围的 ART-11 或后续 UI polish / asset pass。

## 10. 后续进入 ART-11 条件

进入 ART-11 前建议满足：

- 审查框确认 ART-10 允许范围、generated side effects 与本轮实际成果边界。
- Godot 内运行并输出关键页面截图。
- 对主菜单、出发准备、长期系统、运行 HUD、背包 / 地面物品面板做文字溢出检查。
- 确认 FusionPixel 授权状态，或确定替代字体 fallback。
- 确认剩余 `preview/debug/draft/Legacy/display_only/read_only` 静态 token 中哪些属于模型契约，哪些需要后续改成产品文案。
- ART-11 只做视觉 QA 修正 / 第二轮 UI polish / 资源补齐，不直接扩展 gameplay 语义。
