# ART-20 Slice 3 执行报告

## 0. 执行边界

- 是否修改 source 原始素材：否
- 是否写 ART-20 staging：否，沿用 Slice 1 staging
- 是否写 cut output：是，仅写入 `D:\AGAME1\sources\art\ART-20\03_cut_output`
- 是否写 cut manifest：是，仅写入 `D:\AGAME1\sources\art\ART-20\_manifest`
- 是否写 Godot runtime assets：否
- 是否修改 `asset_manifest.csv`：否
- 是否运行 Godot：否
- 是否 git add / commit / push：否
- 是否 reset / clean / stash / pull：否

## 1. 本切片目标

根据 Slice 2 审计通过的 dry-run plan，对 P0 ready 项和允许进入治理性重切 / 重命名的 governance review 项执行真实切片，产出 cut output、cut manifest、blocked manifest 与 component gallery。

本切片不导入 Godot，不修改 manifest，不替换 UI。

## 2. 实际修改 / 新增文件

外部 ART-20 输出：

- `D:\AGAME1\sources\art\ART-20\03_cut_output\**\*.png`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_manifest.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_blocked_or_review.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_summary.json`

仓库内新增 / 更新：

- `D:\AGAME1\_repo_cache\Game1_work\tools\art20_cut_ui_assets.py`
- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art20\art20_slice3_component_gallery.md`
- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art20\ART20_SLICE3_P0_COMPONENT_CUT_REPORT.md`

## 3. 关键产物

cut summary：

| item | count |
| --- | ---: |
| cut_rows | 54 |
| generated_png_count | 54 |
| ready_for_review_cut_rows | 43 |
| governance_review_cut_rows | 11 |
| blocked_or_skipped_rows | 5 |
| written_rows | 47 |
| already_present_same_hash_rows | 7 |

cut status 分布：

| cut_status | count |
| --- | ---: |
| `cut_ready_for_review` | 43 |
| `cut_governance_review` | 11 |

blocked / skipped component：

- `deploy_left_character_frame`
- `longterm_left_character_profile`
- `run_gameplay_viewport_background`
- `map_overlay_cell_64_set`
- `map_overlay_event_marker_64`

component gallery：

- `D:\AGAME1\_repo_cache\Game1_work\docs\art\validation\art20\art20_slice3_component_gallery.md`

## 4. 自检结果

- `python .\tools\art20_cut_ui_assets.py --write-cut-output` 执行成功：是
- 写出模式幂等：是，第二次重跑 54 个输出全部 `already_present_same_hash`
- 输出 PNG 数量：54
- cut manifest 行数：54
- blocked manifest 行数：5
- 输出路径是否全部位于 `D:\AGAME1\sources\art\ART-20\03_cut_output`：是
- `output_sha256` 是否与实际输出文件一致：是
- 空透明输出：0
- `tools\__pycache__` 是否存在：否
- `git diff --check`：无 whitespace error，仅既有 dirty 文件 CRLF warning
- 是否写 Godot / manifest：否

输出尺寸分布：

| size | count |
| --- | ---: |
| 32x32 | 7 |
| 40x40 | 6 |
| 72x72 | 8 |
| 95x141 | 4 |
| 96x96 | 1 |
| 98x141 | 1 |
| 141x56 | 2 |
| 144x144 | 2 |
| 148x56 | 2 |
| 154x56 | 2 |
| 170x60 | 2 |
| 228x61 | 3 |
| 289x98 | 3 |
| 320x340 | 1 |
| 321x167 | 2 |
| 418x71 | 4 |
| 685x583 | 3 |
| 1672x941 | 1 |

## 5. 工具变更说明

`tools/art20_cut_ui_assets.py` 已从 dry-run planner 扩展为显式写出模式：

- 默认仍为 dry-run。
- 只有传入 `--write-cut-output` 才写 `03_cut_output`。
- 写出路径被 guard 限定在 `D:\AGAME1\sources\art\ART-20\03_cut_output`。
- 不覆盖不同 hash 的已有输出。
- 允许 same-hash 幂等重跑。
- blocked 行只写入 `cut_blocked_or_review.csv`，不生成 PNG。
- governance review 行生成 `cut_governance_review`，不标记为 import-ready。

## 6. git status 分类

Slice 3 新增 / 更新：

- `tools/art20_cut_ui_assets.py`
- `docs/art/validation/art20/art20_slice3_component_gallery.md`
- `docs/art/validation/art20/ART20_SLICE3_P0_COMPONENT_CUT_REPORT.md`

外部 ART-20 新增：

- `D:\AGAME1\sources\art\ART-20\03_cut_output`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_manifest.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_blocked_or_review.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_summary.json`

既有 dirty 仍保留，未清理、未 stage、未 commit：

- Godot generated / manifest translation side effects：`project.godot`、`asset_manifest.*.translation`
- ART-18 / ART-19 / ART-19R1 相关既有 UI、文档、工具 dirty
- 文档治理既有 dirty：`docs/README.md`、`docs/INDEX.md`、`docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`
- ART-20 Slice 0 / Slice 1 / Slice 2 产物

## 7. 风险 / 未完成项

- `cut_governance_review` 的 11 个 tab 类输出仍需审计确认命名、页面职责、selected/normal 语义，不可直接导入。
- `map_overlay_event_marker_64` 仍未完成 source selection。
- 角色展示、房间背景、地图格等 blocked 项未进入本切片输出。
- 九宫格项已保留完整源尺寸并标记 `nine_slice_margin=manual_review_required`，后续 Slice 4 导入前必须确认 nine-slice margin。
- 本切片没有验证 Godot 显示效果；视觉验收留给后续导入 / UI 替换切片。

## 8. 请求审计

请求“美术调整-审计”框复核 ART-20 Slice 3：

- 54 个 cut output 是否符合 Slice 3 边界。
- cut manifest / blocked manifest / gallery 是否足以支持 Slice 4。
- 11 个 `cut_governance_review` 是否允许在 Slice 4 中作为 manifest-backed import 候选，或是否需要先降级。
- 5 个 blocked 项是否继续排除。
- 是否允许进入 ART-20 Slice 4。
