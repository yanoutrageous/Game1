# ART-19 UI Asset Kit Mapping

## 0. 定位

本文件记录 ART-19 首批真实 UI PNG 素材套件映射。`sources/art` 与 `sources/draw` 只作为来源；runtime 只读取 `res://assets/ui/art19/**` 与 manifest-backed asset_id。

ART-19 不把 Base 确定稿整屏图当作 runtime 背景，也不直接从外部 source 路径读取素材。

## 1. 组件需求表

| UI 部件 | 目标界面 | ART-19 处理 |
| --- | --- | --- |
| 主面板 / terminal frame | 主菜单、长期系统、Skin Kit 通用面板 | 导入 `ui.art19.panel.terminal_main` |
| 出发探索主面板 | 出发探索中区路线 / 卡片区域 | 导入 `ui.art19.panel.deploy_main` |
| 摘要 / 状态卡面板 | 主菜单公告、出发摘要、长期详情、HUD 右上状态卡 | 导入 `ui.art19.panel.deploy_summary` |
| 选中高亮框 | 卡片选中、slot、状态强调 | 导入 `ui.art19.panel.frame_highlight` |
| 暗色按钮牌 | 通用按钮、快捷键按钮、MapOverlay 格子 fallback | 导入 `ui.art19.button.dark` |
| 金色确认按钮 | 主操作、开始探索、大入口按钮 | 导入 `ui.art19.button.confirm` |
| 选中 tab 按钮 | tab / selected 状态 | 导入 `ui.art19.button.selected_tab` |
| 底部信息条 | Run HUD 主信息栏、短反馈 | 导入 `ui.art19.bar.summary_dark` |
| 竖向装饰条 | 滚动 / 侧栏装饰预留 | 导入 `ui.art19.scrollbar.vertical` |
| 64px 地图格 / 图标 | MapOverlay 大地图格 | 导入 `ui.art19.map64.*` |

## 2. Mapping

| asset_id | runtime path | source path | 用途 |
| --- | --- | --- | --- |
| `ui.art19.panel.terminal_main` | `res://assets/ui/art19/panels/terminal_main.png` | `sources/draw/30_game_ready/ui_panel/ui_panel_terminal_main.png` | 通用大面板、主菜单按钮板、长期系统档案墙 |
| `ui.art19.panel.deploy_main` | `res://assets/ui/art19/panels/deploy_main_blank.png` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_main_blank.png` | 出发探索主内容框、卡片框 |
| `ui.art19.panel.deploy_summary` | `res://assets/ui/art19/panels/deploy_summary_blank.png` | `sources/draw/30_game_ready/ui_deploy_panel/ui_panel_deploy_summary_blank.png` | 摘要卡、右上状态卡、小型 panel |
| `ui.art19.panel.frame_highlight` | `res://assets/ui/art19/panels/frame_highlight.png` | `sources/draw/30_game_ready/ui_deploy_panel/ui_frame_highlight.png` | 选中态 / 高亮框 |
| `ui.art19.button.dark` | `res://assets/ui/art19/buttons/button_blank_dark.png` | `sources/draw/30_game_ready/ui_button_blank/ui_button_blank_dark.png` | 默认按钮、key bar 按钮 |
| `ui.art19.button.confirm` | `res://assets/ui/art19/buttons/button_confirm_deploy_large.png` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_confirm_deploy_large.png` | 金色主操作按钮 |
| `ui.art19.button.selected_tab` | `res://assets/ui/art19/buttons/button_nav_talent_selected.png` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_nav_talent_selected.png` | 选中 tab / selected 状态 |
| `ui.art19.bar.summary_dark` | `res://assets/ui/art19/bars/summary_bar_dark.png` | `sources/draw/30_game_ready/ui_summary_bar/ui_bar_blank_dark.png` | 底部主信息栏 / 短反馈 |
| `ui.art19.scrollbar.vertical` | `res://assets/ui/art19/bars/scrollbar_vertical.png` | `sources/draw/30_game_ready/ui_scrollbar/ui_scrollbar_vertical.png` | 竖向装饰 / 滚动条预留 |
| `ui.art19.map64.player` | `res://assets/ui/art19/map64/player_marker_64.png` | `sources/draw/30_game_ready/icons/64/00_wanjia_dingwei.png` | MapOverlay 玩家位置 |
| `ui.art19.map64.unknown` | `res://assets/ui/art19/map64/unknown_cell_64.png` | `sources/draw/30_game_ready/icons/64/01_weizhi_ge.png` | MapOverlay 未知格 |
| `ui.art19.map64.explored` | `res://assets/ui/art19/map64/explored_cell_64.png` | `sources/draw/30_game_ready/icons/64/02_yitan_ge.png` | MapOverlay 已探索格 |
| `ui.art19.map64.scanned` | `res://assets/ui/art19/map64/scanned_cell_64.png` | `sources/draw/30_game_ready/icons/64/03_saomiao_ge.png` | MapOverlay 扫描格 |
| `ui.art19.map64.mine` | `res://assets/ui/art19/map64/mine_icon_64.png` | `sources/draw/30_game_ready/icons/64/05_dici_xianjing_icon.png` | MapOverlay 雷险格 |
| `ui.art19.map64.chest` | `res://assets/ui/art19/map64/chest_icon_64.png` | `sources/draw/30_game_ready/icons/64/07_baoxiang_icon.png` | MapOverlay 物资箱格 |
| `ui.art19.map64.exit` | `res://assets/ui/art19/map64/exit_icon_64.png` | `sources/draw/30_game_ready/icons/64/09_chukou_icon.png` | MapOverlay 撤离 / 出口格 |

## 3. 接入策略

- `Art09ManifestAssetMapping.art19_skin_ref()` 暴露 UI 套件 visual_key。
- `Art09ManifestAssetMapping.art19_map64_ref()` 暴露 MapOverlay 64px marker visual_key。
- `PresentationMapping` 转发上述 mapping，保持 presentation 层统一出口。
- `Art10UISkinKit` 优先用 `StyleBoxTexture` 消费 ART19 PNG，缺失时 fallback 到原 StyleBoxFlat。
- 四个界面继续只接收 manifest-backed asset_id，不拼外部 source 路径。

## 4. 缺口

- 当前仍缺最终页面级专用背景、角色立绘和完整动画套件。
- ART-19 首批仅替换 UI 组件皮肤，不声明最终视觉 QA 完成。
