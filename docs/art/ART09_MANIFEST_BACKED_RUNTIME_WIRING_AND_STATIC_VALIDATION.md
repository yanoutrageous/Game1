# ART-09 manifest-backed 美术资产运行时接线与静态验证

## 0. 文档定位

本文档记录 ART-09 对 ART-08 manifest-backed 资产的运行时消费侧接线。它不代表最终美术 approved，不代表完整视觉 QA 通过，也不授权继续导入新图片、运行 Godot、生成 `.import` / `.uid` / `.godot` 副产物。

本阶段只在 presentation 与允许的 UI 脚本层接线，通过 asset_id 消费资源；不修改 `asset_manifest.csv`、Godot assets、scene、`project.godot`、ContentDB、AssetCatalog、core/run、core/command 或 core/save。

## 1. 输入资产

本轮从 ART-08 新增的 manifest-backed 资产中选择低风险 UI 消费范围：

- `ui.key_prompt.*`
- `ui.deploy.button.*`
- `ui.deploy.icon.*`
- `ui.deploy.panel.*`
- `item.consumable.*`
- `item.equipment.*`
- `item.recovered.*`
- `ui.main_menu.background.no_text`

本轮未接线 `prop.art07.*`，未接线 `map_icon` / `map_tile_icon`，未接线角色动画、sprite sheet 或 visual target 整屏稿。

## 2. 接线范围

| area | result |
| --- | --- |
| key prompt | 通过 `Art09ManifestAssetMapping.key_prompt_ref()` 暴露 action 到 `ui.key_prompt.*` 的 helper；主菜单快捷入口可消费 `interact` key prompt。 |
| deploy UI | DeployPrep tab/card/action/panel 增加 manifest-backed asset refs，shell 通过 ContentDB 解析为 Button icon 或 TextureRect。 |
| item icon | Inventory item row 通过 PresentationMapping 获取 item icon ref，并通过 ContentDB 解析为 Button icon。 |
| main menu background | MainMenu model 输出 `ui.main_menu.background.no_text`，shell 尝试渲染为背景 TextureRect；失败时保留原色块背景。 |

## 3. PresentationMapping / helper 变更

新增：

- `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`

调整：

- `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd`

helper 负责维护 ART-09 asset_id 白名单、fallback asset_id、asset ref 字典结构与 ContentDB 纹理解析。UI 脚本只接收 asset_id / fallback_asset_id metadata，不拼接 `res://assets/...` 路径。

fallback 策略：

- icon fallback: `icon.minimap.explored`
- button fallback: `ui.common.button.dark`
- panel fallback: `ui.hud.panel.protocol`
- background fallback: `room.background.normal`

## 4. UI 消费侧变更

| file | change |
| --- | --- |
| `scripts/ui/main_menu/main_menu_model.gd` | 增加 main menu background asset ref、entry icon refs、shortcut key prompt ref。 |
| `scripts/ui/main_menu/main_menu_shell.gd` | 尝试渲染 manifest-backed background TextureRect，并为 entry / shortcut Button 设置 icon。 |
| `scripts/ui/deploy_prep/deploy_config.gd` | 将 `art09_asset_refs` 放入 deploy config 与 run_start_config preview。 |
| `scripts/ui/deploy_prep/deploy_tab_model.gd` | 为 tab 与 card 输出 ART09 asset refs。 |
| `scripts/ui/deploy_prep/deploy_prep_shell.gd` | 为 panel TextureRect、tab Button、card Button、action Button 消费 ART09 asset refs。 |
| `scripts/ui/inventory/inventory_panel.gd` | 为 item row Button 消费 item icon asset refs。 |

未能完全渲染项：

- key prompt 没有独立 key prompt HUD 入口；本轮完成 helper 与 shortcut metadata，标记为 `manifest_backed_but_not_rendered_yet` 的路径仍由后续 UI 专项决定是否可视化。

## 5. 静态验证结果

新增静态验证脚本：

- `tools/validate_art09_manifest_backed_assets.ps1`

验证范围：

- `asset_manifest.csv` 可读取。
- asset_id 唯一。
- 本轮 27 个接线 asset_id 存在。
- fallback asset_id 存在。
- 每个接线 asset_id 的 `godot_path` 指向现有文件。
- 本轮接线白名单不包含 `prop.art07.*`、map、sprite 或 visual target。
- ART09 修改脚本不包含硬编码 `res://assets/...` 路径。

本阶段不运行 Godot。最终状态需由审查框决定是否运行更高层 smoke / headless gate。

## 6. 暂缓内容

- `prop.art07.*` 实战房间接线。
- `map_icon` / `map_tile_icon` 替换。
- 角色动画与 sprite sheet。
- `Base Art/08_visual_targets` 整屏视觉稿。
- 长期系统完整美术包。
- 继续导入新图片。
- scene / project.godot 级 UI skin 重构。

## 7. 后续进入 ART-10 条件

ART-10 才能做可视 QA、Godot headless 或 smoke gate。若后续运行 Godot，必须先明确 `.import` / `.uid` / `.godot` 副产物处理策略，并由相应审查框确认是否允许提交或清理这些副产物。
