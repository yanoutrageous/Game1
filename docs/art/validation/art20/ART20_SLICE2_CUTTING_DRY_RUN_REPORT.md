# ART-20 Slice 2 执行报告

## 0. 执行边界

- 是否修改 source 原始素材：否
- 是否写 ART-20 staging：否，本切片沿用 Slice 1 staging
- 是否写 cut output：否
- 是否生成 PNG：否
- 是否写 Godot runtime assets：否
- 是否修改 `asset_manifest.csv`：否
- 是否运行 Godot：否
- 是否 git add / commit / push：否
- 是否 reset / clean / stash / pull：否

## 1. 本切片目标

建立 ART-20 安全切片 dry-run 工具，读取 Slice 1 staging manifest、ART19R1 cutting spec、ART19R1 import batch plan，输出 component-level dry-run plan。

本切片只做计划输出，不生成真实切片图，不创建 `02_cut_working` / `03_cut_output`，不导入 Godot。

## 2. 实际修改 / 新增文件

仓库内新增：

- `D:\AGAME1\_repo_cache\Game1_work\tools\art20_cut_ui_assets.py`
- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art20\art20_slice2_cutting_dry_run_plan.csv`
- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art20\art20_slice2_cutting_dry_run_summary.json`
- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art20\ART20_SLICE2_CUTTING_DRY_RUN_REPORT.md`

外部 ART-20 目录：

- 未新增 `02_cut_working`
- 未新增 `03_cut_output`
- 未新增任何 PNG

## 3. 关键产物

dry-run 工具能力：

- 读取 `staging_manifest.csv`
- 读取 `UI_COMPONENT_CUTTING_SPEC.csv`
- 读取 `NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv`
- 支持 source candidate 精确匹配、glob 匹配、basename fragment 匹配
- 读取图片宽高、alpha bounds、透明像素数量、magenta 像素数量
- 生成 crop preview rect
- 生成 9-slice / crop dry-run 状态
- 标记 governance recut / rename 风险
- 标记未 staging source 和 `needs_source_selection` 阻断
- 默认只生成 CSV / JSON 计划，不写图片

dry-run summary：

| item | count |
| --- | ---: |
| staged_asset_count | 27 |
| spec_p0_count | 27 |
| import_plan_p0_count | 19 |
| dry_run_plan_rows | 59 |
| matched_rows | 54 |
| distinct_staged_sources_in_plan | 27 |
| ready_crop_rows | 25 |
| ready_9slice_rows | 18 |
| governance_review_rows | 11 |
| blocked_rows | 5 |
| generated_png_count | 0 |

dry-run status 分布：

| dry_run_status | count |
| --- | ---: |
| `dry_run_ready_crop_plan` | 25 |
| `dry_run_ready_9slice_plan` | 18 |
| `dry_run_governance_review` | 11 |
| `blocked_no_staged_source_match` | 4 |
| `blocked_pending_source_selection` | 1 |

## 4. 自检结果

- `python .\tools\art20_cut_ui_assets.py` 执行成功：是
- dry-run 输出 CSV 存在：是
- dry-run 输出 JSON 存在：是
- 27 个 Slice 1 staged source 全部被 dry-run plan 引用：是
- `02_cut_working` 是否存在：否
- `03_cut_output` 是否存在：否
- `D:\AGAME1\sources\art\ART-20` 下 PNG 总数：27，仅为 Slice 1 staging 文件
- `git diff --check`：无 whitespace error，仅既有 dirty 文件 CRLF warning
- `python -m py_compile`：通过；临时 `tools\__pycache__` 已清理
- 是否写 Godot / manifest：否

## 5. blocked / governance 项

继续阻断，不进入切图：

| component | status | reason |
| --- | --- | --- |
| `deploy_left_character_frame` | `blocked_no_staged_source_match` | `characters/**` 未纳入 Slice 1 staging |
| `longterm_left_character_profile` | `blocked_no_staged_source_match` | `characters/**` 未纳入 Slice 1 staging |
| `run_gameplay_viewport_background` | `blocked_no_staged_source_match` | `rooms/fangjian_jichu_1024.png` / `props/*.png` 未纳入 Slice 1 staging |
| `map_overlay_cell_64_set` | `blocked_no_staged_source_match` | `icons/64/*.png` / `map_tile_icon/*.png` 未纳入 Slice 1 staging |
| `map_overlay_event_marker_64` | `blocked_pending_source_selection` | 审计已要求继续排除，source selection 未完成 |

需要治理性重命名 / 重切复核：

- `ui_tab_selected_generic`
- `deploy_primary_tab_row` 中的 5 个 nav button
- `longterm_top_switch_tabs` 中的 5 个 nav button

这些行已标记为 `dry_run_governance_review`，不得在 Slice 3 中直接视为可 import 成果。

## 6. git status 分类

Slice 2 新增仓库成果：

- `tools/art20_cut_ui_assets.py`
- `docs/art/validation/art20/art20_slice2_cutting_dry_run_plan.csv`
- `docs/art/validation/art20/art20_slice2_cutting_dry_run_summary.json`
- `docs/art/validation/art20/ART20_SLICE2_CUTTING_DRY_RUN_REPORT.md`

既有 dirty 仍保留，未清理、未 stage、未 commit：

- Godot generated / manifest translation side effects：`project.godot`、`asset_manifest.*.translation`
- ART-18 / ART-19 / ART-19R1 相关既有 UI、文档、工具 dirty
- 文档治理既有 dirty：`docs/README.md`、`docs/INDEX.md`、`docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`
- ART-20 Slice 0 / Slice 1 产物

## 7. 风险 / 未完成项

- Slice 2 只做 dry-run，不证明真实切片视觉质量。
- `map_overlay_event_marker_64` 仍需 source selection 审计，不应进入 Slice 3。
- 角色展示、房间背景、地图格等未纳入 Slice 1 staging 的项目仍 blocked；若 Slice 3 需要处理，必须先回到 admission/source selection。
- 11 个 tab 类治理项需要在 Slice 3 中明确 component_id、runtime path 和页面语义，不能沿用 `talent_selected` 原语义。
- dry-run plan 中使用 alpha bounds / full source rect 作为预览，不等同最终人工 crop rect 审定。

## 8. 请求审计

请求“美术调整-审计”框复核 ART-20 Slice 2：

- dry-run 工具是否符合安全边界。
- dry-run plan 是否足以支撑 Slice 3 P0 真实切片。
- 5 个 blocked 项是否继续排除。
- 11 个 governance review 项是否允许进入 Slice 3 的治理性重切 / 重命名流程。
- 是否允许进入 ART-20 Slice 3。
