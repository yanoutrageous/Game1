# ART-15 Slice 3 visual_key / PresentationMapping 接线报告

## 0. 文档定位

本文记录 ART-15 Slice 3 的 manifest-backed visual_key 接线结果。

本切片目标不是新增素材，也不是完成全部核心界面替换，而是把 Slice 2 已导入的 P0 runtime 图片通过 `asset_id` / visual_key / fallback 接到 UI 与 presentation 层，避免 UI 直接拼接外部路径或继续只依赖程序化色块。

本切片不修改 Base Art、Draw、Connection，不修改 gameplay core / run / command / save 语义，不 commit / push。

## 1. 输入依据

- `docs/art/ART14_ART_RESOURCE_LAYERING_AND_MOTION_SPEC.md`
- `docs/art/validation/art14/VISUAL_KEY_AND_ASSET_ID_REQUIREMENTS.md`
- `docs/art/validation/art14/RUNTIME_IMPORT_PRIORITY.md`
- `docs/art/validation/art15/ART15_ASSET_MATCH_MATRIX.md`
- `docs/art/validation/art15/ART15_EXISTING_RUNTIME_ASSET_REUSE.md`
- `docs/art/validation/art15/ART15_RUNTIME_IMPORT_REPORT.md`
- `Godot/GraytailGodot/data/assets/asset_manifest.csv`

## 2. 新增 / 扩展的 visual_key 映射

| visual role | state | asset_id | fallback_asset_id | 用途 |
| --- | --- | --- | --- | --- |
| `feedback_bar` | `neutral` / `success` / `ready` | `ui.feedback.bar.dark` | `ui.hud.panel.protocol` | HUD 命令反馈的默认条形承载 |
| `feedback_bar` | `warning` / `danger` / `blocked` | `ui.feedback.bar.red` | `ui.hud.panel.protocol` | HUD 阻断、危险、失败反馈 |
| `feedback_panel` | `search` / `event` / `reward` | `ui.feedback.event_prompt` | `ui.hud.panel.protocol` | 搜索、事件、奖励提示承载 |
| `result_title_plate` | `extract_confirm` | `ui.result.title.extract_confirm` | `ui.hud.panel.protocol` | 撤离确认 / 结算入口标题牌 |
| `result_title_plate` | `success` | `ui.result.title.extraction_success` | `ui.hud.panel.protocol` | 成功撤离 / 提取成功标题牌 |
| `result_title_plate` | `failure` / `failed` / `signal_lost` / `abandon` / `abandoned` | `ui.result.title.signal_lost` | `ui.hud.panel.protocol` | 失败、信号丢失、放弃结果标题牌 |

所有新增映射均通过 `Art09ManifestAssetMapping.asset_ref()` 返回，并保留 `manifest_backed=true` 与 fallback metadata。

## 3. 修改文件

| file | 变更 |
| --- | --- |
| `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd` | 增加 feedback/result 状态到 asset_id 的映射表，新增 `feedback_bar_ref()`、`feedback_panel_ref()`、`result_title_ref()` |
| `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd` | 增加 presentation 层包装函数，供 UI 层消费 manifest-backed refs |
| `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd` | 在 HUD 命令反馈区域加入 `TextureRect` 背板，根据 accepted / blocked 状态切换 feedback visual_key |
| `Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd` | GroundLoot 行按钮复用 inventory item visual_key 解析图标，减少物品界面断层 |
| `Godot/GraytailGodot/scripts/ui/result/result_panel.gd` | Result 面板增加标题牌 `TextureRect`，按 snapshot outcome 映射成功 / 失败 / 撤离确认标题图 |

## 4. 接线结果

### HUD / Run Surface

`RunSurface.show_command_feedback()` 现在不只更新文字，也会按命令结果切换 manifest-backed 反馈条：

- accepted / ok：`feedback_bar_ref("neutral")`
- rejected / blocked：`feedback_bar_ref("warning")`

贴图通过 `Art09ManifestAssetMapping.resolve_texture()` 从 manifest-backed `asset_id` 解析，不直接拼接 `res://` 路径，也不读取 Base Art / Draw。

### GroundLoot

`GroundLootPanel` 的物品按钮现在复用：

- `PresentationMapping.inventory_item_icon_ref(item)`
- `Art09ManifestAssetMapping.resolve_texture(asset_ref)`
- `Art10UISkinKit.controlled_button_icon(button, "slot")`

这使 GroundLoot 与 Inventory 使用同一套 item icon visual_key / fallback 逻辑，避免同一物品在背包与地面拾取界面出现视觉断层。

### Result / Settlement

`ResultPanel` 新增 `ResultTitlePlate` 图层，按 snapshot outcome 映射：

- `Extracted` / `success` -> `ui.result.title.extraction_success`
- `Failed` / `failure` -> `ui.result.title.signal_lost`
- `Abandoned` / `abandon` -> `ui.result.title.signal_lost`
- 默认 / 撤离确认 -> `ui.result.title.extract_confirm`

标题牌图层放在 backdrop 之上、文字层之下，用于降低纯程序化结算弹层的视觉空白。

## 5. fallback 与边界

- 新增 visual_key 均有 fallback：`ui.hud.panel.protocol`。
- UI 层只消费 `asset_ref` / `Texture2D`，不读取外部素材路径。
- 本切片没有修改 `core/run`、`core/command`、`core/save`。
- 本切片没有修改 TruthMap、RunContext、CommandBus 语义。
- 本切片没有把 `source_status` 写成 approved / final / runtime_ready。
- 本切片没有清理 Godot generated side effects。

## 6. 暂缓到后续切片

- 主菜单、出发探索、长期系统的大面积 visual replacement 属于 Slice 4。
- hover / selected / reward / blocked 等最小动效属于 Slice 5。
- Computer Use 多分辨率截图和最终脚本验收属于 Slice 6。
- Result / Settlement 是否在实际流程中完全可达，需要 Slice 6 运行验证确认。

## 7. Slice 3 自检结论

Slice 3 已完成核心 visual_key / PresentationMapping 接线：

- 新增 feedback / result title manifest-backed visual_key。
- HUD 命令反馈、GroundLoot item icon、Result title plate 已接入。
- 每个新增 visual_key 均有 fallback。
- 未出现 Base Art / Draw runtime hardcode。
- 未触碰禁止的 gameplay core / run / command / save 语义。

后续应进入 Slice 4：核心页面视觉替换，重点检查这些接线在运行画面中是否产生足够可见变化。
