# ART-15 核心美术资源生产化、manifest-backed 接入与核心界面视觉替换

## 0. 文档定位

ART-15 是 ART-14 之后的执行阶段，目标是把资源分层、visual_key、asset_id、fallback 与最小反馈落实到真实 Godot runtime asset、manifest、UI / presentation 接线和实际运行截图。

本文不是素材最终验收，也不代表所有视觉 QA 已完成。新增素材仍保持 `internal_staged` / `staged_pending_review`，不得视为 approved / final / runtime_ready。

## 1. 执行边界

- 未修改 Base Art / Draw / Connection / Base Docs 原始内容。
- 未从 Base Art / Draw runtime 读取图片。
- 未修改 TruthMap / RunContext / CommandBus 语义。
- 未修改 `core/run`、`core/command`、`core/save` 已跟踪代码。
- 未 commit / push。
- Godot generated side effects 保持隔离，未清理、未 stage。

## 2. 素材匹配结果

Slice 1 同时扫描了当前 Godot runtime assets、Base Art、Draw、旧 GameJam Draw 与 manifest，而不是只按策划案判断。

| source | result |
| --- | --- |
| Godot runtime PNG | 74 个 |
| Base Art visual files | 188 个，其中 86 个 SHA 匹配 runtime |
| Draw `30_game_ready` visual files | 147 个，其中 58 个 SHA 匹配 runtime |
| 旧 GameJam Draw visual files | 969 个，其中 99 个 SHA 匹配 runtime |

输出：

- `docs/art/validation/art15/ART15_ASSET_MATCH_MATRIX.md`
- `docs/art/validation/art15/ART15_EXISTING_RUNTIME_ASSET_REUSE.md`
- `docs/art/validation/art15/ART15_SOURCE_CANDIDATE_DEDUP_REVIEW.md`

明确排除：

- debug 图。
- Base 整屏确定稿。
- M1 / Lua demo 参考。
- ART-13 截图。
- `Art.zip`。

## 3. runtime 导入结果

Slice 2 导入 6 个低风险 UI runtime PNG，并追加 6 行 manifest。

| asset_id | godot_path |
| --- | --- |
| `ui.feedback.bar.dark` | `res://assets/ui/feedback/ui_bar_blank_dark.png` |
| `ui.feedback.bar.red` | `res://assets/ui/feedback/ui_bar_blank_red.png` |
| `ui.feedback.event_prompt` | `res://assets/ui/feedback/ui_bar_event_prompt.png` |
| `ui.result.title.extract_confirm` | `res://assets/ui/result/ui_title_extract_confirm.png` |
| `ui.result.title.extraction_success` | `res://assets/ui/result/ui_title_extraction_success.png` |
| `ui.result.title.signal_lost` | `res://assets/ui/result/ui_title_signal_lost.png` |

输出：

- `docs/art/validation/art15/ART15_RUNTIME_IMPORT_REPORT.md`

自检结果：

- 新增 asset_id 唯一。
- 新增 `godot_path` 文件存在。
- source / staged SHA 一致。
- 新增 manifest 行保持 `internal_staged` / `staged_pending_review`。

## 4. visual_key / PresentationMapping 接线

Slice 3 新增或扩展：

- `feedback_bar_ref()`
- `feedback_panel_ref()`
- `result_title_ref()`
- presentation wrapper。

接线结果：

- HUD 命令反馈条使用 `ui.feedback.bar.dark` / `ui.feedback.bar.red`。
- GroundLoot 复用 Inventory 的 item icon visual_key。
- Result 面板按 outcome 使用 result title plate。

输出：

- `docs/art/validation/art15/ART15_VISUAL_KEY_WIRING_REPORT.md`

## 5. 核心界面视觉替换结果

Slice 4 让核心界面发生可见变化：

| screen | replacement |
| --- | --- |
| Main Menu | 背景、入口 icon、公告纹理、行动记录 panel 纹理 |
| Deploy Prep | 修正 art09 refs 回退，主 panel / summary panel / tab icon / card icon / 开始按钮纹理可渲染 |
| Long Term | 三栏接入 terminal / protocol panel 纹理 |
| HUD | 命令反馈条接入 feedback asset |
| MiniMap / MapOverlay | 继续使用 manifest-backed minimap icon |
| Inventory / GroundLoot | item icon visual_key 统一 |
| Result / Settlement | Result title plate 接入；实际流程截图未强行进入 result |

输出：

- `docs/art/validation/art15/ART15_CORE_SCREEN_REPLACEMENT_REPORT.md`

## 6. 最小动效与反馈结果

Slice 5 新增 Skin Kit motion helper：

- `reduce_motion_enabled()`
- `motion_duration()`
- `feedback_color()`
- `animation_fallback_key()`
- `play_feedback_pulse()`
- `play_panel_open()`

已接入：

- HUD 命令 accepted / warning feedback pulse。
- Inventory panel open、使用 / 丢弃结果 feedback pulse。
- GroundLoot panel open、拾取 / 容量阻断 feedback pulse。
- Result panel open。

输出：

- `docs/art/validation/art15/ART15_MOTION_FEEDBACK_IMPLEMENTATION_REPORT.md`

## 7. Computer Use 验证

使用真实 Godot 项目：

`D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`

使用真实 Godot 可执行文件：

`D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64.exe`

Computer Use 捕获结果受 Windows DPI / 窗口边框影响，逻辑尺寸如下：

| requested | captured logical size |
| --- | --- |
| 1280x720 | 856x511 |
| 1600x900 | 1069x631 |
| 1920x1080 | 1280x737 |

### 1280x720

- `docs/art/validation/art15/art15_main_menu_1280x720.png`
- `docs/art/validation/art15/art15_deploy_prep_1280x720.png`
- `docs/art/validation/art15/art15_long_term_1280x720.png`
- `docs/art/validation/art15/art15_run_hud_1280x720.png`
- `docs/art/validation/art15/art15_map_overlay_1280x720.png`
- `docs/art/validation/art15/art15_inventory_1280x720.png`
- `docs/art/validation/art15/art15_ground_loot_1280x720.png`

### 1600x900

- `docs/art/validation/art15/art15_main_menu_1600x900.png`
- `docs/art/validation/art15/art15_deploy_prep_1600x900.png`
- `docs/art/validation/art15/art15_long_term_1600x900.png`
- `docs/art/validation/art15/art15_run_hud_1600x900.png`
- `docs/art/validation/art15/art15_map_overlay_1600x900.png`

### 1920x1080

- `docs/art/validation/art15/art15_main_menu_1920x1080.png`
- `docs/art/validation/art15/art15_deploy_prep_1920x1080.png`
- `docs/art/validation/art15/art15_long_term_1920x1080.png`
- `docs/art/validation/art15/art15_run_hud_1920x1080.png`
- `docs/art/validation/art15/art15_map_overlay_1920x1080.png`

Result / Settlement 未强行截图：当前普通房间流程没有自然进入结算状态，本阶段不通过 debug、改规则或私有状态绕路。

## 8. 可视结论

当前截图显示 ART-15 已经不再是“没有变化”：

- 主菜单入口、公告、行动记录区域可见 runtime UI 纹理。
- 出发探索主按钮、panel、tab / card 图标显示 manifest-backed 资源。
- 长期系统三栏可见 terminal / protocol panel 纹理。
- HUD 显示 room background、feedback bar、key prompt、minimap icons。
- MapOverlay 使用 minimap asset_id 图标。
- Inventory / GroundLoot 能使用 item icon visual_key。

仍需后续审计关注：

- 字体在高分辨率逻辑捕获下仍偏像素化，需要视觉 QA 判断是否接受。
- HUD 右侧文字密度仍高。
- Result / Settlement 需要后续通过真实流程或专门验收路径截图。
- MiniMap selected / danger 动效仍暂缓。

## 9. 验证脚本

验证脚本：

- `tools/validate_art15_core_art_asset_pipeline.ps1`

脚本检查：

- ART-15 总文档与 validation 文档存在。
- 关键截图存在且非空。
- `asset_manifest.csv` 可解析。
- 新增 asset_id 唯一。
- 新增 `godot_path` 文件存在。
- 无 Base Art / Draw runtime hardcode。
- 未修改 `core/run`、`core/command`、`core/save` 已跟踪代码。
- generated side effects 仅 warning。

## 10. 后续建议

ART-15 可进入审计验收。验收应重点使用截图判断：

- 替换是否足够可见。
- HUD / Deploy / Long Term 是否仍有阻断级重叠。
- Result 不可达是否接受，或是否需要单独开启 Result 验证入口。

本执行框不 commit / push。
