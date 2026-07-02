# ART-19R1 UI Asset Governance and Cutting Prep

## 0. 文档定位

本文汇总 ART-19R1 的美术素材库统一治理、命名补录与 UI 切片准备结果。

本阶段只建立 `source -> component -> visual_key -> runtime asset` 的治理链路，不执行真实切图，不修改 Godot UI 代码，不修改 `asset_manifest.csv`，不导入新 runtime asset，不运行 Godot，不 commit / push。

本阶段的权威素材来源为：

- `D:\AGAME1\sources\art`
- `D:\AGAME1\sources\draw`

这些来源目录只读盘点，不移动、不删除、不重命名、不改写。

## 1. 执行边界

ART-19R1 允许写入范围仅限：

- `docs/art/ART19R1_UI_ASSET_GOVERNANCE_AND_CUTTING_PREP.md`
- `docs/art/validation/art19r1/**`
- `tools/validate_art19r1_asset_governance.ps1`

本阶段未修改：

- `D:\AGAME1\sources\art`
- `D:\AGAME1\sources\draw`
- Draw / Base Art / Connection 旧路径
- Godot UI 代码
- `Godot/GraytailGodot/data/assets/asset_manifest.csv`
- Godot runtime assets

当前工作区存在 ART-18 / ART-19 / docs governance / generated side effects 的前置 dirty；这些不属于 ART-19R1 成果，也不由本阶段清理或吸收。

## 2. Slice 0 环境与边界复核

Slice 0 完成了仓库和路径前置判断：

- 仓库根目录：`D:\AGAME1\_repo_cache\Game1_work`
- 当前分支：`main`
- 当前 HEAD：`e94389f578031c3b114afda95efee6a27cb30cd4`
- 保护性 stash 存在，未操作
- `D:\AGAME1\sources\art` 存在
- `D:\AGAME1\sources\draw` 存在

Slice 0 将当前 dirty 分类为既有 ART-18 / ART-19 / docs governance / generated side effects；本阶段后续只允许在 ART-19R1 文档与验证脚本范围内新增内容。

## 3. Slice 1 素材池全量盘点

Slice 1 输出：

- `docs/art/validation/art19r1/UI_SOURCE_ASSET_INVENTORY.md`
- `docs/art/validation/art19r1/_slice1_file_inventory.csv`
- `docs/art/validation/art19r1/_slice1_dir_counts.csv`
- `docs/art/validation/art19r1/_slice1_ext_counts.csv`
- `docs/art/validation/art19r1/_slice1_duplicate_hashes.csv`
- `docs/art/validation/art19r1/_slice1_special_dirs.csv`
- `docs/art/validation/art19r1/_slice1_summary.json`

核心统计：

| 项目 | 数量 |
| --- | ---: |
| 总文件 | 1197 |
| 总图片 | 1162 |
| `sources/art` 文件 | 199 |
| `sources/art` 图片 | 193 |
| `sources/draw` 文件 | 998 |
| `sources/draw` 图片 | 969 |
| 尺寸可读图片 | 1162 |
| 疑似重复 SHA 组 | 144 |

关键目录判断：

| 路径 | 文件 | 图片 | 判断 |
| --- | ---: | ---: | --- |
| `sources/art/04_cut_working` | 0 | 0 | 仍未形成真实切片工作区 |
| `sources/art/05_export_runtime_candidates` | 52 | 52 | 有 runtime candidate 基础 |
| `sources/art/Base` | 10 | 10 | 主要作为参考图和整屏视觉稿 |
| `sources/art/ART-13` | 6 | 6 | 参考图优先 |
| `sources/art/ART-14` | 5 | 5 | 运行态布局参考和切分来源候选 |
| `sources/art/M1` | 7 | 6 | Lua / M1 运行态参考 |
| `sources/draw/30_game_ready` | 151 | 147 | 当前低风险候选来源重点 |

结论：素材池具备可治理基础，但尚未完成组件切分、命名和来源到 runtime 的稳定链路。

## 4. Slice 2 语义分类

Slice 2 输出：

- `docs/art/validation/art19r1/UI_ASSET_SEMANTIC_CLASSIFICATION.md`
- `docs/art/validation/art19r1/UI_ASSET_SEMANTIC_CLASSIFICATION.csv`
- `docs/art/validation/art19r1/_slice2_semantic_counts.csv`
- `docs/art/validation/art19r1/_slice2_role_counts.csv`
- `docs/art/validation/art19r1/_slice2_screen_counts.csv`
- `docs/art/validation/art19r1/_slice2_art19_hash_matches.csv`

分类统计：

| 语义分类 | 数量 |
| --- | ---: |
| `cut_required` | 5 |
| `cut_working_needed` | 550 |
| `defer` | 168 |
| `reference_only` | 32 |
| `reject_or_archive` | 7 |
| `runtime_candidate` | 124 |
| `runtime_imported_correct` | 16 |
| `source_candidate` | 260 |

关键判断：

- `Base`、`ART-13`、`M1` 以 `reference_only` 为主，不直接 runtime 导入。
- `ART-14` 标记为 `cut_required`，因为它提供运行态图层和遮挡关系，但不能直接 runtime 使用。
- `05_export_runtime_candidates` 以 `runtime_candidate` 为主。
- `draw/10_working` 大量标记为 `cut_working_needed`，说明切片治理压力集中在工作候选区。
- `runtime_imported_wrong_usage` 未在 Slice 2 定案，因为是否用错位置必须结合 manifest、mapping、UI 代码和截图判断。

## 5. Slice 3 ART-19 已接入素材复核

Slice 3 输出：

- `docs/art/validation/art19r1/ART19_IMPORTED_ASSET_REVIEW.md`
- `docs/art/validation/art19r1/ART19_IMPORTED_ASSET_REVIEW.csv`
- `docs/art/validation/art19r1/_slice3_imported_asset_review_counts.csv`

复核范围为 `Godot/GraytailGodot/assets/ui/art19/**` 的 16 个 runtime PNG。

统计结果：

| 项目 | 数量 |
| --- | ---: |
| runtime 文件存在 | 16 |
| source 文件存在 | 16 |
| source/runtime SHA256 一致 | 16 |
| 可追溯到 `sources/draw/30_game_ready` | 16 |
| `no_confirmed_wrong_usage` | 12 |
| `wrong_usage_risk` | 4 |

重点风险：

- `ui.art19.panel.terminal_main`：来源正确，但语义过宽，不能长期作为主菜单 / 长期系统通用大容器。
- `ui.art19.panel.deploy_summary`：适合小摘要卡，但跨页面泛用有风险。
- `ui.art19.button.confirm`：适合出发探索主按钮，不应无审查升级为全局 confirm。
- `ui.art19.button.selected_tab`：来源名为 `nav_talent_selected`，作为全局 selected tab 存在命名和语义风险。
- `ui.art19.map64.scanned`：event alias 属临时用法，后续需要独立 event marker。
- `ui.art19.scrollbar.vertical`：当前按 reserved / defer 处理。

结论：已接入素材不是“文件错导入”，主要问题是语义使用范围过宽和后续组件化不足。

## 6. Slice 4 UI 组件切片规格

Slice 4 输出：

- `docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.md`
- `docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.csv`
- `docs/art/validation/art19r1/_slice4_component_spec_counts.csv`

组件规格统计：

| 页面 / 域 | 组件数 |
| --- | ---: |
| `shared` | 8 |
| `main_menu` | 4 |
| `deploy_prep` | 7 |
| `long_term` | 5 |
| `run_hud` | 6 |
| `map_overlay` | 3 |
| `inventory` | 2 |
| `ground_loot` | 1 |
| `result` | 1 |

优先级统计：

| 优先级 | 数量 |
| --- | ---: |
| `P0` | 27 |
| `P1` | 9 |
| `P2` | 1 |

规格覆盖字段：

- 来源图候选
- 裁切目标
- 输出尺寸
- 是否九宫格
- 是否可拉伸
- normal / selected / disabled / locked / warning 等状态需求
- 目标 Godot 目录
- asset_id / visual_key 候选
- 优先级与风险备注

治理重点：

- `terminal_main` 必须拆成 shared large frame 和页面专用 frame。
- `deploy_summary` 限制为 small summary card。
- `button_confirm_deploy_large` 限制为 deploy main button 或经审查改名为 generic primary。
- `button_nav_talent_selected` 必须替换或重命名为通用 selected tab / 页面专用 tab。
- `map64.scanned` 不能长期代替 event marker。

## 7. Slice 5 命名规范与下一批导入计划

Slice 5 输出：

- `docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD.md`
- `docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD_EXAMPLES.csv`
- `docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.md`
- `docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv`
- `docs/art/validation/art19r1/_slice5_next_import_plan_counts.csv`

命名规则：

- runtime 文件名：`ui_<domain>_<component>_<role>_<state>[_variant][_size].png`
- asset_id：`ui.<domain>.<component>.<role>.<state>[.<variant>]`
- visual_key：`<domain>.<component>.<role>[.<state>]`
- source_trace：`source_path + source_sha256 + cutting_spec_id`

下一批计划统计：

| 批次 | 数量 | 定位 |
| --- | ---: | --- |
| `B1_P0_governance_fix` | 8 | 修正 ART-19 已接入素材的命名、语义和复用风险 |
| `B2_P0_core_pages` | 11 | 补齐核心页面基础组件 |
| `B3_P1_followup_pages` | 4 | 背包、地面拾取、页面背景等跟随组件 |
| `B4_P2_result` | 1 | 结果界面标题牌集合 |

source_status 统计：

| source_status | 数量 |
| --- | ---: |
| `confirmed_existing` | 11 |
| `confirmed_existing_set` | 9 |
| `needs_source_selection` | 2 |
| `needs_visual_fit_review` | 2 |

需要后续审查选择的项目：

- `map_overlay_event_marker_64`
- `ground_loot_pickup_card`
- `deploy_background_staging_hall`
- `longterm_background_archive_room`

Slice 5 经过一次返修，已修正中文乱码、模糊 source candidate 和 keycap visual_key：

- `ui_shared_keycap_e_normal.png`
- `ui.shared.keycap.e.normal`
- `shared.keycap.e.normal`

## 8. 当前治理链路

ART-19R1 建立的链路如下：

```text
source pool
  -> inventory
  -> semantic classification
  -> imported asset review
  -> component cutting spec
  -> naming standard
  -> next runtime import batch plan
```

该链路的核心约束：

- source 图不能被 Godot runtime 直接读取。
- reference_only 图不能被伪装为 runtime candidate。
- runtime_candidate 仍需切片、命名、hash、manifest 和截图 gate。
- 已导入 asset 若来源正确但语义过宽，应通过命名和组件规格收敛，而不是直接扩大复用。
- `needs_source_selection` / `needs_visual_fit_review` 不能直接进入导入。

## 9. 后续真实切图 / 导入前置条件

进入后续真实 UI 切片和 runtime 导入前，必须逐项满足：

- 具体 source 文件已选定。
- source SHA256 已记录。
- 切片规格已明确尺寸、九宫格、拉伸策略和状态集。
- runtime 文件名符合命名规范。
- asset_id 唯一。
- visual_key 不误导页面职责。
- target runtime path 不冲突。
- `asset_manifest.csv` diff 可审查。
- UI 代码不直接读取 `sources/art` 或 `sources/draw`。
- 1280x720 截图确认无错位、遮挡、文字溢出或错误复用。

## 10. 暂缓内容

本阶段明确暂缓：

- 真实切图。
- 新 runtime asset 导入。
- 修改 `asset_manifest.csv`。
- 修改 Godot UI 代码。
- 运行 Godot。
- 对 `D:\AGAME1\sources\art` 或 `D:\AGAME1\sources\draw` 做移动、删除、重命名、清理。
- 处理 ART-18 / ART-19 既有 dirty。

## 11. 验证脚本

新增验证脚本：

- `tools/validate_art19r1_asset_governance.ps1`

脚本检查：

- ART-19R1 必要文档存在。
- Slice 1-5 汇总与 CSV 存在。
- ART-19R1 文档为 UTF-8 可读，且无连续问号乱码、replacement char、常见 mojibake 片段。
- Slice 5 不再含 `or shared primary` / `or new source` 等模糊候选语句。
- keycap 示例的 file / asset_id / visual_key 正确。
- `NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv` 中 `needs_source_selection` / `needs_visual_fit_review` 项不能被标为直接导入。
- 当前 dirty 只能属于 ART-19R1 允许输出或既有 ART-18 / ART-19 / docs governance / generated side effects 分类。
- 禁止路径没有新增 ART-19R1 变更。

## 12. 结论

ART-19R1 已完成从素材池盘点到命名补录、组件切片规格和下一批导入计划的治理基础建设。

当前可进入审计判断：是否认可 ART-19R1 的治理链路和文档完整性，并决定后续是否另开真实切图 / runtime 导入阶段。
