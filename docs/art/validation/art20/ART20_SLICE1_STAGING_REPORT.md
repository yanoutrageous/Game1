# ART-20 Slice 1 执行报告

## 0. 执行边界

- 是否修改 source 原始素材：否
- 是否删除 / 移动 / 重命名 source 原始素材：否
- 是否写入 ART-20 staging：是，仅写入 `D:\AGAME1\sources\art\ART-20`
- 是否写入 cut working / cut output：否
- 是否修改 Godot UI / runtime assets：否
- 是否修改 `asset_manifest.csv`：否。本切片只写入外部 staging manifest。
- 是否运行 Godot：否
- 是否 git add / commit / push：否
- 是否 reset / clean / stash / pull：否

## 1. 实际读取路径

- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art19r1\NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv`
- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art19r1\UI_COMPONENT_CUTTING_SPEC.csv`
- `D:\AGAME1\sources\draw\30_game_ready`

## 2. 实际写入路径

外部 staging：

- `D:\AGAME1\sources\art\ART-20`
- `D:\AGAME1\sources\art\ART-20\01_staging_from_draw\draw_30_game_ready`
- `D:\AGAME1\sources\art\ART-20\_manifest\staging_manifest.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\staging_excluded_candidates.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\staging_summary.json`

仓库文档：

- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art20\ART20_SLICE1_STAGING_REPORT.md`

## 3. staging 结果

- P0 admitted source：27
- 实际复制文件：27
- already_present：0
- 排除候选：1
- staged PNG 文件数：27
- source / staged hash 不一致：0
- source / staged 路径缺失：0
- staged_path hash 冲突：0
- 不合格 source_status：0

分类数量：

| category | count |
| --- | ---: |
| item_consumable | 2 |
| item_equipment | 2 |
| main_menu | 1 |
| ui_button_blank | 1 |
| ui_deploy_button | 6 |
| ui_deploy_icon | 4 |
| ui_deploy_panel | 3 |
| ui_key_prompt | 6 |
| ui_panel | 1 |
| ui_summary_bar | 1 |

排除候选：

| component | reason |
| --- | --- |
| `map_overlay_event_marker_64` | `needs_source_selection`，候选来源存在分歧：`sources/draw/30_game_ready/icons/64/04_biaoji_qi.png` / `sources/draw/30_game_ready/map_icon/map_icon_event.png`。本切片未纳入 staging。 |

## 4. 自检结果

- `staging_manifest.csv` 行数：27
- `staging_excluded_candidates.csv` 行数：1
- 每条 admitted 记录的 `source_path` 存在：是
- 每条 admitted 记录的 `staged_path` 存在：是
- 每条 admitted 记录的 `source_sha256 == staged_sha256`：是
- 未出现 `needs_source_selection` / `needs_visual_fit_review` / `reference_only` 被纳入 admitted staging：是
- 未向 `02_cut_working` 或 `03_cut_output` 写入文件：是
- 未触碰 Godot runtime assets / UI 代码 / `asset_manifest.csv`：是

## 5. git status 分类

Slice 1 新增的外部 staging 位于 `D:\AGAME1\sources\art\ART-20`，不属于仓库 git 状态。

仓库内本切片新增：

- `docs/art/validation/art20/ART20_SLICE1_STAGING_REPORT.md`

仓库内既有 dirty 仍保留，未清理、未 stage、未 commit，包括：

- Godot generated / manifest translation side effects：`project.godot`、`asset_manifest.*.translation`
- ART-18 / ART-19 / ART-19R1 相关既有 UI、文档、工具 dirty
- 文档治理既有 dirty：`docs/README.md`、`docs/INDEX.md`、`docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`

保护性 stash 仍存在，未操作。

## 6. 风险 / 未完成项

- `map_overlay_event_marker_64` 没有进入本轮 staging，需要审计判断后续 source selection。
- 本切片只完成 Draw P0 候选入场与 hash 闭环，没有真实切图、没有 Godot 导入、没有 manifest 登记。
- 后续 Slice 2 应只做 cutting tool dry-run，不应直接生成 runtime output。
- 当前仓库仍存在 ART-18 / ART-19 系列既有 dirty，后续切片必须继续分类，不得误认为 ART-20 新成果。

## 7. 请求审计

请求“美术调整-审计”框复核 ART-20 Slice 1：

- staging 范围是否符合 P0 admission。
- 27 个 copied source 是否可进入 Slice 2 cutting dry-run。
- `map_overlay_event_marker_64` 是否继续排除，或由审计指定唯一来源后再纳入。
- 是否允许进入 ART-20 Slice 2。
