# UI 素材命名规范

## 0. 文档定位

本文是 ART-19R1 Slice 5 产物，用于统一 UI runtime 素材的文件名、asset_id、visual_key、目标目录和来源追溯口径。
本文不是切图结果，不是 Godot 导入授权，不修改 `asset_manifest.csv`。

## 1. 命名目标

- 建立 `source -> component -> visual_key -> runtime asset` 的治理链路。
- 让文件名能表达页面域、组件类型、用途、状态和尺寸。
- 让 asset_id 与 visual_key 不再依赖来源文件夹或临时 ART-19 名称。
- 避免把页面专用素材误命名成全局通用素材。
- 明确 reference_only、source_candidate、runtime_candidate 与 runtime_imported 的边界。

## 2. 三层命名规则

| 对象 | 规则 | 示例 | 说明 |
| --- | --- | --- | --- |
| runtime 文件名 | `ui_<domain>_<component>_<role>_<state>[_variant][_size].png` | `ui_main_menu_button_primary_normal.png` | Godot runtime PNG 使用 ASCII snake_case；不沿用中文文件名或来源池临时名称。 |
| asset_id | `ui.<domain>.<component>.<role>.<state>[.<variant>]` | `ui.main_menu.button.primary.normal` | manifest 中的稳定资产 ID。 |
| visual_key | `<domain>.<component>.<role>[.<state>]` | `main_menu.button.primary.normal` | UI / presentation 层请求的语义 key；不得直接等同 source 文件名。 |
| target_dir | `Godot/GraytailGodot/assets/ui/<domain>/<component_family>/` | `Godot/GraytailGodot/assets/ui/main_menu/buttons/` | 页面专用件进入页面域，跨页面件进入 `shared`。 |
| source_trace | `source_path + source_sha256 + cutting_spec_id` | `sources/draw/30_game_ready/ui_deploy_button/ui_button_confirm_deploy_large.png` | 后续 manifest 或 registry 必须能追溯到源图和切片规格。 |

## 3. domain 词表

| domain | 使用范围 |
| --- | --- |
| `shared` | 跨页面通用 UI 件，如通用 panel、button、slot、keycap。 |
| `main_menu` | 主菜单专用背景、入口按钮、公告框、标题区。 |
| `deploy` | 出发探索页面专用路线卡、装备槽、准备页按钮、tab。 |
| `longterm` | 长期系统专用档案、收藏墙、图鉴卡、资历模块。 |
| `run_hud` | 局内 HUD 左侧栏、右上状态卡、底部信息条、对象提示。 |
| `map_overlay` | 展开地图、地图格、地图标记、地图面板。 |
| `inventory` | 背包面板、物品槽、背包分类。 |
| `ground_loot` | 地面拾取提示和拾取卡。 |
| `result` | 结算、撤离、失败、奖励结果界面。 |

## 4. component 词表

| component | 使用范围 |
| --- | --- |
| `background` | 页面背景或局内底层背景。 |
| `panel` | 可拉伸面板、框体、详情区。 |
| `button` | 主按钮、次按钮、入口按钮。 |
| `tab` | 一级或二级页签。 |
| `card` | 路线卡、收藏卡、拾取卡。 |
| `slot` | 装备槽、背包槽、图鉴槽。 |
| `badge` | 短状态标签。 |
| `keycap` | 快捷键键帽。 |
| `icon` | 普通图标或用途图标。 |
| `marker` | 地图标记或事件标记。 |
| `bar` | 信息条、状态条、进度条。 |
| `tooltip` | 小浮层提示。 |
| `overlay` | 临时遮罩或覆盖层。 |
| `title` | 标题牌、结果标题图。 |

## 5. state 词表

| state | 使用范围 |
| --- | --- |
| `normal` | 默认状态。 |
| `hover` | 鼠标悬停状态。 |
| `pressed` | 按下状态。 |
| `selected` | 当前选中状态。 |
| `disabled` | 不可用状态。 |
| `locked` | 未解锁状态。 |
| `warning` | 警告状态。 |
| `danger` | 危险状态。 |
| `reward` | 奖励或收益状态。 |
| `new` | 新内容提示状态。 |
| `ready` | 可开始、可执行、就绪状态。 |
| `active` | 激活状态。 |
| `empty` | 空槽状态。 |
| `filled` | 已填充状态。 |

## 6. 文件名模板

```text
ui_<domain>_<component>_<role>_<state>[_variant][_size].png
```

示例：

```text
ui_main_menu_button_primary_normal.png
ui_deploy_route_card_selected.png
ui_longterm_collection_card_locked.png
ui_run_hud_status_card_pressure_warning.png
ui_map_overlay_cell_unknown_64.png
ui_shared_keycap_e_normal.png
ui_inventory_slot_item_selected.png
```

规则：

- `domain` 必须来自第 3 节词表。
- `component` 必须来自第 4 节词表。
- `state` 必须来自第 5 节词表。
- `role` 必须描述组件语义，不得写 `tmp`、`misc`、`new`、`asset1`。
- 尺寸后缀只用于固定规格图，如 `64`、`128`、`9slice`。
- 来源文件名可记录在 source trace 中，但不得直接决定 runtime 文件名。

## 7. asset_id 模板

```text
ui.<domain>.<component>.<role>.<state>[.<variant>]
```

示例：

```text
ui.shared.panel.summary_card.normal
ui.deploy.card.route.selected
ui.longterm.card.collection.locked
ui.run_hud.panel.status_card.pressure.warning
ui.map_overlay.cell.unknown.64
ui.shared.keycap.e.normal
```

规则：

- asset_id 必须稳定，不随文件所在临时目录变化。
- asset_id 不写来源目录名，例如 `30_game_ready`、`art19`。
- asset_id 不写阶段名，除非文档引用历史来源。
- 已导入 ART-19 素材若语义不准，后续通过新 asset_id 替换，而不是继续扩大旧 ID 的用途。

## 8. visual_key 模板

```text
<domain>.<component>.<role>[.<state>]
```

示例：

```text
main_menu.button.primary.normal
deploy.route_card.selected
longterm.collection_card.locked
run_hud.status_card.pressure.warning
map_overlay.cell.unknown
shared.keycap.e.normal
```

规则：

- visual_key 是 UI 请求语义，不是 runtime 文件路径。
- visual_key 可以比 asset_id 稍短，但必须保留 domain 和 component 语义。
- keycap 示例必须使用 `shared.keycap.e.normal`，不得写成 `ui.keycap.e`。

## 9. 命名反例

| 反例 | 问题 | 正确处理 |
| --- | --- | --- |
| `button_nav_talent_selected.png` | 来源语义是天赋页签，不应直接当全局 selected tab。 | 重新裁切或重命名为 `ui_shared_tab_primary_selected.png`，并保留 source trace。 |
| `terminal_main.png` | 名称过宽，容易误用为所有页面大框。 | 拆为 `ui_shared_panel_large_frame_normal.png` 或页面专用 frame。 |
| `debug_detected_boxes.png` | 调试检测图，不是 runtime UI。 | 标记 `reject_or_archive`，不得进入 runtime。 |
| `主菜单确定.png` | 整屏参考图，不是组件素材。 | 标记 `reference_only`，可指导切片规格，不直接导入。 |
| `ui.keycap.e` | 缺少 domain，不符合 visual_key 规则。 | 使用 `shared.keycap.e.normal`。 |

## 10. 后续导入前置要求

后续任何 runtime 导入必须先满足：

- 已有 source path 与 source sha256。
- 已有切片规格或明确不需切片的理由。
- 已确认目标 domain、component、role、state。
- 已确认 target runtime path、asset_id、visual_key。
- 已明确是否九宫格、是否可拉伸、是否固定尺寸。
- 不从 `sources/art` 或 `sources/draw` 直接 runtime 读取。
- 不把整屏参考图当作唯一 runtime UI 背景或组件。