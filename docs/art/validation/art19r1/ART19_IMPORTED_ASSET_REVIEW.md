# ART-19 已接入素材复核

## 0. 文档定位

本文是 ART-19R1 Slice 3 产物，用于复核 `Godot/GraytailGodot/assets/ui/art19/**` 中已经接入的 runtime UI PNG。
本文只做来源追溯、命名判断和用途风险判断，不修改 Godot UI 代码，不修改 `asset_manifest.csv`，不新增 runtime asset。

## 1. 读取范围

- Runtime 目录：`Godot/GraytailGodot/assets/ui/art19/**`
- Manifest：`Godot/GraytailGodot/data/assets/asset_manifest.csv`，只读 `ui.art19.*` 行
- ART-19 文档：`docs/art/ART19_REAL_UI_ART_KIT_AND_CORE_SCREEN_REPLACEMENT.md`
- ART-19 验证目录：`docs/art/validation/art19/**`
- 相关映射脚本：`scripts/presentation/art09_manifest_asset_mapping.gd`、`presentation_mapping.gd`、`art10_ui_skin_kit.gd`
- UI 使用点：核心 UI shell 与 `map_overlay_panel.gd`
- 来源目录：`D:/AGAME1/sources/draw/30_game_ready/**`，仅用于 hash 和尺寸只读比对

## 2. 复核结论

- 已复核 ART-19 runtime PNG：16 个。
- runtime 文件存在：16 / 16。
- source 文件存在：16 / 16。
- source/runtime SHA256 一致：16 / 16。
- 16 个 ART-19 runtime PNG 均可追溯到 `sources/draw/30_game_ready`。
- 未确认“素材文件本身错误导入”的阻断项。
- 主要风险是具体语义素材被 Skin Kit 当作通用 role 扩散使用。

## 3. 统计

| 分组 | 值 | 数量 |
| --- | --- | ---: |
| traceability | traceable | 16 |
| hash_match | yes | 16 |
| usage_decision | keep | 10 |
| usage_decision | keep_with_followup | 1 |
| usage_decision | keep_with_scope_limit | 1 |
| usage_decision | replace_or_rename | 1 |
| usage_decision | temporary_keep_replace_later | 2 |
| usage_decision | defer_or_reserved | 1 |
| wrong_usage_status | no_confirmed_wrong_usage | 12 |
| wrong_usage_status | wrong_usage_risk | 4 |

## 4. 逐项判断

| asset_id | 尺寸 | source trace | 使用判断 | wrong_usage | 说明 |
| --- | --- | --- | --- | --- | --- |
| `ui.art19.bar.summary_dark` | 418x71 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为深色摘要条和底部信息条材料。 |
| `ui.art19.button.confirm` | 289x98 | traceable / hash yes | `keep_with_scope_limit` | `wrong_usage_risk` | 适合出发探索主确认按钮，不应直接升级为全局 confirm。 |
| `ui.art19.button.dark` | 321x167 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合暗色按钮、keybar 按钮和次级按钮材料。 |
| `ui.art19.button.selected_tab` | 228x61 | traceable / hash yes | `replace_or_rename` | `wrong_usage_risk` | 来源是 `nav_talent_selected`，作为全局 selected tab 命名过窄，需替换或重命名。 |
| `ui.art19.map64.chest` | 64x64 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为 MapOverlay chest marker。 |
| `ui.art19.map64.exit` | 64x64 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为 MapOverlay exit marker。 |
| `ui.art19.map64.explored` | 64x64 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为 explored / normal map cell。 |
| `ui.art19.map64.mine` | 64x64 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为 mine marker。 |
| `ui.art19.map64.player` | 64x64 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为 player marker。 |
| `ui.art19.map64.scanned` | 64x64 | traceable / hash yes | `keep_with_followup` | `wrong_usage_risk` | scanned 可保留，但 event alias 需要独立 event marker 规格。 |
| `ui.art19.map64.unknown` | 64x64 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为 unknown map cell。 |
| `ui.art19.panel.deploy_main` | 320x340 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合出发探索主面板和路线卡基础。 |
| `ui.art19.panel.deploy_summary` | 95x141 | traceable / hash yes | `temporary_keep_replace_later` | `wrong_usage_risk` | 适合小摘要卡，跨页面泛用或大尺寸拉伸有风险。 |
| `ui.art19.panel.frame_highlight` | 98x141 | traceable / hash yes | `keep` | `no_confirmed_wrong_usage` | 适合作为 slot/card 选中框基础。 |
| `ui.art19.panel.terminal_main` | 685x583 | traceable / hash yes | `temporary_keep_replace_later` | `no_confirmed_wrong_usage` | 文件可保留，但语义过宽，后续应拆成页面专用大框。 |
| `ui.art19.scrollbar.vertical` | 29x340 | traceable / hash yes | `defer_or_reserved` | `no_confirmed_wrong_usage` | 当前按 reserved / defer 处理，不能声明已正确落地。 |

## 5. 风险归纳

- `terminal_main` 不应长期作为主菜单、长期系统和通用大容器的共同材料。
- `deploy_summary` 应收敛为 small summary card，不应跨页面无限复用。
- `button_confirm_deploy_large` 应限制在 deploy 主按钮或经过命名重构后进入 shared primary。
- `button_nav_talent_selected` 必须从 talent 语义中剥离，不能直接作为全局 selected tab。
- `map64.scanned` 可保留 scanned 语义，但不能继续兼任 event marker。
- `scrollbar_vertical` 暂不进入核心导入计划。

## 6. 对 Slice 4 的要求

- 写清页面、组件、状态、尺寸、九宫格和 visual_key / asset_id 候选。
- 把 ART-19 已接入素材的用途边界纳入切片规格。
- 不得把 temporary skin 直接声明为 final 或 approved。
- 对 selected tab、summary card、large frame、event marker 建立替换或重命名计划。

## 7. 边界

- 未修改 `D:/AGAME1/sources/art`。
- 未修改 `D:/AGAME1/sources/draw`。
- 未修改 Godot UI 代码。
- 未修改 `asset_manifest.csv`。
- 未新增 runtime asset。
- 未运行 Godot。
- 未 commit / push。
