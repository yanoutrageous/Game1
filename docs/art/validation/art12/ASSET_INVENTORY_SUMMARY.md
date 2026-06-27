# ART-12 Asset Inventory Summary

文档状态：ART-12 validation evidence
生成时间：2026-06-27

## 0. 定位

本文档记录 ART-12 对 `Base Art`、`Draw`、旧 GameJam `Draw`、Base 确定稿、M1 参考材料和 Godot runtime assets 的只读盘点结果。

本阶段不复制素材、不移动素材、不删除素材、不导入 Godot、不修改 `asset_manifest.csv`。

## 1. 环境输入

| 项 | 路径 / 结果 |
| --- | --- |
| 仓库 | `D:\AGAME1\_repo_cache\Game1_work` |
| 真实 Godot 项目 | `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot` |
| Base Art | `D:\AGAME1\Base Art` |
| Draw | `D:\AGAME1\Draw` |
| old Draw | `D:\A GAME\26.5.30 GameJam\Draw` |
| Godot runtime asset root | `Godot/GraytailGodot/assets` |

## 2. Base Art 总量

| 类型 | 数量 |
| --- | ---: |
| 总文件 | 188 |
| `.png` | 182 |
| `.csv` | 4 |
| `.md` | 1 |
| `.mp4` | 1 |

## 3. Base Art 分层

| 目录 | 文件数 | 判断 |
| --- | ---: | --- |
| `_registry` | 4 | registry CSV，ART-12 只读审计 |
| `00_prompts` | 0 | 当前无 prompt 文件 |
| `01_raw_generated` | 0 | 当前无 raw generated 文件 |
| `02_reference_collected` | 0 | 当前无外部参考收集文件 |
| `03_selected` | 52 | Draw 30_game_ready 首批 staging selected |
| `04_cut_working` | 0 | 当前无切割工作文件 |
| `05_export_runtime_candidates` | 52 | ART07 首批 runtime candidate staging，不代表已导入 |
| `06_animation_sources` | 48 | 角色动画帧 source，暂不进入 runtime batch |
| `07_sprite_sheets` | 4 | 角色 sprite sheet source，暂不进入 runtime batch |
| `08_visual_targets` | 10 | Base 确定稿 / 示例图 reference_only |
| `99_rejected_or_archive` | 0 | 当前无归档文件 |
| `Base` | 10 | UI 确定稿 / 示例 reference |
| `M1` | 7 | HUD / Lua demo reference |

## 4. Base / M1 Reference 列表

### Base

| 文件 | 用途 |
| --- | --- |
| `主菜单确定.png` | 主菜单排版与视觉语义 reference |
| `主菜单示例.png` | 主菜单历史参考 |
| `出发探索确定.png` | 出发探索排版与视觉语义 reference |
| `出发探索示例.png` | 出发探索历史参考 |
| `长期系统确定.png` | 长期系统排版与视觉语义 reference |
| `长期系统示例.png` | 长期系统历史参考 |
| `6.17问题1.png` | 问题记录 / visual target reference |
| `6.17问题2.png` | 问题记录 / visual target reference |
| `6.17问题3.png` | 问题记录 / visual target reference |
| `6.17问题4.png` | 问题记录 / visual target reference |

### M1

| 文件 | 用途 |
| --- | --- |
| `1.png` | HUD / runtime structure reference |
| `2.png` | HUD / runtime structure reference |
| `3.png` | HUD / runtime structure reference |
| `A1.png` | M1 extended visual reference |
| `A2.png` | M1 extended visual reference |
| `A3.png` | M1 extended visual reference |
| `Lua demo.mp4` | HUD、key bar、房间节奏和交互反馈参考 |

Base / M1 均只作为 reference；不得直接作为整屏 runtime UI 背景。

## 5. Draw / old Draw 总量

| 根路径 | 总文件 | `.png` | `.json` | `.md` | `.html` | `.zip` |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `D:\AGAME1\Draw` | 998 | 969 | 19 | 8 | 1 | 1 |
| `D:\A GAME\26.5.30 GameJam\Draw` | 998 | 969 | 19 | 8 | 1 | 1 |

两个目录的相对路径数量一致，文件大小比较差异为 0。ART-12 将它们视为镜像 / 迁移副本关系，不建议作为两个独立来源重复登记。

## 6. Draw _manifest 摘要

`D:\AGAME1\Draw\_manifest\asset_manifest.json` 的 scan 摘要：

| 字段 | 值 |
| --- | ---: |
| root_png_count | 21 |
| recursive_png_count | 967 |
| split_source_count | 9 |
| candidate_count | 542 |
| duplicate_group_count | 50 |

质量统计：

| quality | 数量 |
| --- | ---: |
| B | 429 |
| C | 45 |
| D | 4 |

候选类别统计：

| category | 数量 |
| --- | ---: |
| event_icon | 113 |
| item_equipment | 60 |
| map_room_icon | 15 |
| map_tile_icon | 10 |
| ui_button_text_fixed | 73 |
| ui_item_card | 46 |
| ui_panel | 3 |
| ui_summary_bar | 107 |
| unknown | 51 |

`selected_assets.md` 记录：selected assets 54，copied to `20_processed` 54，copied to `30_game_ready` 27。`duplicates.md` 记录 50 个 duplicate group，并明确要求 verify visually before discarding anything。

## 7. 30_game_ready 分类

| 分类 | 文件数 |
| --- | ---: |
| characters | 60 |
| icons | 29 |
| item_consumable | 2 |
| item_equipment | 2 |
| item_recovered | 1 |
| main_menu | 1 |
| map_icon | 6 |
| map_tile_icon | 3 |
| props | 13 |
| rooms | 2 |
| ui | 3 |
| ui_button_blank | 1 |
| ui_deploy_button | 8 |
| ui_deploy_icon | 4 |
| ui_deploy_panel | 3 |
| ui_icon | 1 |
| ui_key_prompt | 6 |
| ui_panel | 1 |
| ui_scrollbar | 1 |
| ui_summary_bar | 1 |
| ui_title_plate | 3 |

## 8. Godot runtime assets 摘要

| 项 | 结果 |
| --- | ---: |
| Godot assets PNG | 74 |
| `.import` 文件 | 76 |
| `asset_manifest.csv` records | 79 |
| `asset_id` 唯一 | 是 |

Manifest 主要类别：

| category | records |
| --- | ---: |
| ui_icon | 20 |
| prop_art07 | 9 |
| ui_deploy_button | 8 |
| ui_panel | 7 |
| ui_key_prompt | 6 |
| room_background | 6 |
| ui_deploy_icon | 4 |
| sprite | 4 |
| ui_deploy_panel | 3 |
| prop | 3 |
| item_consumable | 2 |
| item_equipment | 2 |
| item_recovered | 1 |
| audio | 1 |
| ui_badge | 1 |
| ui_font | 1 |
| ui_main_menu | 1 |

## 9. source_candidate 判断

可进入下一步 source_candidate 讨论：

- `Base Art\05_export_runtime_candidates\art07_first_batch` 中未进入 runtime 或尚未接线的 UI / item / prop / panel。
- `Base Art\06_animation_sources` 和 `07_sprite_sheets` 中的角色帧与 sprite sheet，但默认不进入下一批小批 runtime import，需先确认角色展示范围。
- `Draw\30_game_ready` 中已被 Base Art staging 覆盖的来源路径，作为 lineage reference。
- `Base Art\Base` 与 `Base Art\M1` 只作为布局 / 风格 / runtime structure reference。

暂缓：

- Draw `10_working/candidates` 全量候选。
- Draw duplicate group 的清理或去重。
- 旧 Draw 作为独立来源重复登记。
- Base 确定稿整屏图作为 runtime UI。
- 角色完整动画 runtime 导入。

## 10. 自检

- 已读取 docs 文档治理入口。
- 未修改 Base Art、Draw、old Draw、Godot runtime assets。
- Draw 与 old Draw 相对路径和文件大小一致，未发现改变来源判断的差异。
- 本文档只记录盘点和建议，不授权导入、删除、移动或 registry 写入。
