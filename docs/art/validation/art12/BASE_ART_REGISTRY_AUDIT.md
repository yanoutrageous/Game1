# ART-12 Base Art Registry Audit

文档状态：ART-12 validation evidence
生成时间：2026-06-27

## 0. 定位

本文档只读审计 `D:\AGAME1\Base Art\_registry`。ART-12 默认不写 registry，不修正 CSV，不追加真实记录。

## 1. Registry 文件与行数

| 文件 | 行数 | 说明 |
| --- | ---: | --- |
| `source_registry.csv` | 207 | source 记录 |
| `review_status.csv` | 207 | candidate review 记录 |
| `export_manifest.csv` | 52 | runtime candidate export 记录 |
| `generation_log.csv` | 1 | staging_operation 记录 |

## 2. 状态统计

### source_registry

| 字段 | 值 | 数量 |
| --- | --- | ---: |
| authorization_status | pending_verification | 207 |
| usage_scope | source_selected | 52 |
| usage_scope | runtime_candidate | 52 |
| usage_scope | animation_source | 48 |
| usage_scope | R5_candidate_only | 41 |
| usage_scope | visual_target;reference_only | 10 |
| usage_scope | sprite_sheet_source | 4 |

### review_status

| 字段 | 值 | 数量 |
| --- | --- | ---: |
| review_status | pending_review | 207 |
| target_usage | source_selected | 52 |
| target_usage | runtime_candidate | 52 |
| target_usage | animation_source | 48 |
| target_usage | minimap_mapoverlay | 14 |
| target_usage | visual_target;reference_only | 10 |
| target_usage | room_prop | 8 |
| target_usage | common_ui_resource_icon | 8 |
| target_usage | marker | 6 |
| target_usage | sprite_sheet_source | 4 |
| target_usage | player_idle_facing | 4 |
| target_usage | room_background | 1 |

### export_manifest

| 字段 | 值 | 数量 |
| --- | --- | ---: |
| target_runtime_role | runtime_candidate | 52 |
| manifest_status | not_ready | 52 |

### generation_log

| 字段 | 值 | 数量 |
| --- | --- | ---: |
| tool | staging_operation | 1 |
| model_or_method | source_migration | 1 |
| status | pending_review | 1 |

## 3. ID 对应关系

| 检查项 | 结果 |
| --- | --- |
| source_id 唯一 | 是 |
| candidate_id 唯一 | 是 |
| export_id 唯一 | 是 |
| review_status.source_id 在 source_registry 中存在 | 207 / 207 |
| export_manifest.candidate_id 在 review_status 中存在 | 52 / 52 |
| generation_log.source_id 在 source_registry 中存在 | 0 / 1 |

`generation_log.source_id=ART07_source_migration` 不在 `source_registry` 中。由于该行是 `staging_operation / source_migration`，不是单张图片 source，本阶段不视为阻断；建议后续 registry 维护阶段决定是否引入 operation_id 字段或登记 operation pseudo-source。

## 4. 路径边界与绝对路径风险

| 文件 | 字段 | 绝对路径行数 | 判断 |
| --- | --- | ---: | --- |
| `source_registry.csv` | source_path | 166 | 指向 `D:\AGAME1\Draw`、`D:\AGAME1\Base Art` 等 lineage/staging 路径，不能直接作为 Godot runtime 路径 |
| `export_manifest.csv` | export_path | 52 | 指向 `D:\AGAME1\Base Art\05_export_runtime_candidates`，只能作为 staging export path |
| `generation_log.csv` | output_path | 1 | 指向 `D:\AGAME1\Base Art`，是 staging operation 输出范围 |

建议后续将 registry 明确区分：

- external_lineage_path
- base_art_staging_path
- proposed_runtime_path
- manifest_asset_id

本阶段不改 CSV header。

## 5. approved / final / runtime_ready 检查

未发现 `approved`、`final`、`runtime_ready` 作为当前状态承诺。`generation_log.csv` 中存在 `not_generated_final`，该字符串是说明该行不是 AI 生成最终稿，不是 final 状态承诺。

## 6. 语义不一致 / 缺字段

当前 registry 可用，但存在治理层面的改进点：

1. `generation_log` 把 staging operation 放在 `source_id` 字段中，语义与 asset source 不完全一致。
2. `source_registry.source_path` 与 `export_manifest.export_path` 含大量绝对路径，适合作 lineage，不适合作跨机器 source of truth。
3. `review_status.target_usage` 同时包含 target usage 和角色语义，后续可拆成 `target_usage` 与 `asset_role`。
4. `export_manifest.proposed_asset_id` 仍多为 `pending_intended_asset_id`，需要在 runtime import 前补齐 intended asset id。
5. `transparent_background`、`animation_frames` 当前为 pending_verification，下一批导入前需补规格。

## 7. 建议

- 本阶段不写 registry。
- 后续如进入 registry 维护阶段，建议只追加 pending-only 记录，不删除、不重排既有行。
- 如果要把 ART-12 asset gap 转成 registry，需要审计框单独授权 registry 写入。
- runtime import 前必须补 `proposed_asset_id`、visual_key、尺寸、透明背景、是否九宫格 / tile / sprite sheet。

## 8. 自检

- registry 只读检查完成。
- 未写入 Base Art。
- 未修改 CSV。
- 未发现需立即阻断的 current final / runtime ready 状态承诺。
