# ART-19 Screen Replacement Report

## 0. 定位

本报告记录 ART-19 首批真实 UI PNG 套件在四核心界面的替换结果。它用于证明当前界面已经从 ART-18R 的布局与线框式样式，推进到 manifest-backed runtime PNG 组件参与渲染。

本报告不声明最终视觉 QA 完成，不覆盖后续 ART-20 的素材补齐、动画、字体 polish 和页面级背景精修。

## 1. 截图证据

| 页面 | 截图 |
| --- | --- |
| 主菜单 | `docs/art/validation/art19/art19_main_menu_1280x720.png` |
| 出发探索 | `docs/art/validation/art19/art19_deploy_prep_1280x720.png` |
| 长期系统 | `docs/art/validation/art19/art19_long_term_1280x720.png` |
| Run HUD | `docs/art/validation/art19/art19_run_hud_1280x720.png` |
| MapOverlay | `docs/art/validation/art19/art19_map_overlay_1280x720.png` |

截图由真实 Godot 项目运行后截取。当前 Windows 缩放导致截图文件显示为 856x511 逻辑像素，但 Godot 启动目标分辨率为 1280x720。

## 2. 主菜单替换

替换内容：

- 右侧入口按钮板接入 `ui.art19.panel.terminal_main`。
- 大型入口按钮通过 Skin Kit 接入 `ui.art19.button.confirm` / `ui.art19.button.dark`。
- 公告条和 meta 区接入 `ui.art19.bar.summary_dark` 与 `ui.art19.panel.deploy_summary`。

结果判断：

- 右侧主按钮已从纯色块 / 线框感转为真实金属按钮和终端面板质感。
- 背景仍承担第一视觉，入口按钮成为明确操作焦点。
- 仍需后续处理顶部小入口字体、最终角色/装饰素材和页面级动态表现。

## 3. 出发探索替换

替换内容：

- 中区路线 / 卡片区域接入 `ui.art19.panel.deploy_main`。
- 右侧摘要面板接入 `ui.art19.panel.deploy_summary`。
- 开始探索按钮接入 `ui.art19.button.confirm`。
- tab、卡片、slot、普通按钮通过 Skin Kit 消费 ART-19 按钮和面板套件。

结果判断：

- 出发探索已具备真实 UI 面板、按钮和摘要框层级，不再主要依赖脚本绘制边框。
- 左角色 / 中内容 / 右摘要的产品页结构保留。
- 残留问题是部分文字仍偏密，后续需要继续配合最终图标、角色立绘和字体策略精修。

## 4. 长期系统替换

替换内容：

- 左侧档案区域接入 `ui.art19.panel.terminal_main`。
- 中间收藏墙 / 图鉴墙接入 `ui.art19.panel.terminal_main`。
- 右侧短模块详情接入 `ui.art19.panel.deploy_summary`。
- 卡片、tab、选择态继续通过 Skin Kit 获得 ART-19 真实按钮 / 高亮框。

结果判断：

- 长期系统已从工程卡片列表进一步转成档案墙 / 收藏墙方向。
- 三栏职责仍保持：左角色档案、中收藏墙、右短模块。
- 右侧和底部仍存在文本排版债务，属于 ART-20 可继续收敛的 polish 项。

## 5. Run HUD 替换

替换内容：

- 左侧固定栏、右上状态卡、底部主信息栏使用 Skin Kit ART-19 面板样式。
- 底部快捷键按钮使用 ART-19 按钮皮肤。
- 主信息反馈条接入 `ui.art19.bar.summary_dark`。

结果判断：

- Run HUD 仍保持用户要求的结构：左侧固定栏约占画面左侧，左栏之外主要还给游戏画面，右上角只作为小状态卡，底部信息与快捷键作为覆盖层。
- 真实按钮和信息条已经进入运行态界面。
- 仍需后续继续压缩左栏文本与最终运行态图标，但没有退回右侧整栏结构。

## 6. MapOverlay 替换

替换内容：

- MapOverlay 面板使用 Skin Kit 真实面板样式。
- 地图格 / 标记通过 `ui.art19.map64.*` 读取 manifest-backed 64px PNG。
- 玩家、未知、已探索、扫描、陷阱、箱子、出口均有首批真实图标映射。

结果判断：

- MapOverlay 已从纯按钮格子推进为真实地图格和 marker 图标。
- 当前大地图仍是覆盖层，但不改变 Run HUD 基础布局。
- 后续可继续改进地图格数量、缩放和交互动效。

## 7. 对 ART-18R 的变化

| 项目 | ART-18R 状态 | ART-19 结果 |
| --- | --- | --- |
| UI 面板 | 主要是 StyleBoxFlat / 脚本线框 | 真实 PNG `StyleBoxTexture` 参与渲染 |
| 按钮 | 样式统一但仍偏工程绘制 | 金属按钮、确认按钮、选中按钮进入 runtime |
| MapOverlay | 主要依赖按钮格和脚本样式 | 64px 地图格 / marker PNG 进入 runtime |
| Mapping | 无 ART-19 asset kit 出口 | `Art09ManifestAssetMapping` + `PresentationMapping` 暴露 ART-19 visual refs |
| manifest | 无 `ui.art19.*` | 16 个 `ui.art19.*` asset_id 已登记 |

## 8. 残留问题

- 本轮未导入最终页面级背景、角色立绘、完整动画素材。
- 部分页面仍有文字偏密、字体层级不够细、局部小标签可读性一般的问题。
- 真实素材套件仍是首批低风险 UI 组件，不是最终发布皮肤。
- 截图验收证明 ART-19 方向成立，但后续仍需 ART-20 继续做精修和素材补齐。
