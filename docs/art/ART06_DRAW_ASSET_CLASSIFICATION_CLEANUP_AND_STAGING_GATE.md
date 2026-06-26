# ART-06 Draw 素材分类整理、冗余清理 dry-run 与 Base Art staging gate

## 0. 文档定位

本文档是 Draw 素材池分类整理、冗余清理 dry-run 与 Base Art staging gate 的一体化文档。它不是删除授权，不是移动授权，不是复制授权，不是 Godot 导入授权，也不是 manifest 修改授权。

本文档只记录只读审计结论、候选映射、quarantine dry-run 规则和后续 gate 条件。本阶段没有修改 `D:\AGAME1\Draw`，没有运行旧工具链脚本，没有写 Base Art，没有写 Connection，没有写 Godot，没有导入图片，没有 commit / push。

## 1. 当前环境与分支判断

| 项目 | 当前值 | 判断 |
| --- | --- | --- |
| git root | `D:/AGAME1/_repo_cache/Game1_work` | 正确 |
| 当前分支 | `main` | 可继续；本目标明确要求不要仅因 `main` 停止 |
| 当前 HEAD | `f185f7c399640519dea0ead77502faa3e98273ae` | `f185f7c M2 polish run UI feedback and minimap interactions` |
| pre status | clean | 可继续 |
| staged 文件 | 无 | 可继续 |
| 保护性 stash | `stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two` | 存在，未操作 |

当前分支未直接包含 `docs/art/ART05_FIRST_BATCH_LUA_ASSET_CANDIDATES.md`，因此本轮按目标要求只读使用已知 R5 commit：

`44323331fe00bb7025eadc8e975c19a6171ad426:docs/art/ART05_FIRST_BATCH_LUA_ASSET_CANDIDATES.md`

后续审查框是否允许 push `main` 需要单独判断；本文档本轮不 commit、不 push。

## 2. Draw 素材池结构

`D:\AGAME1\Draw` 存在，当前顶层包括：

- `00_raw`
- `10_working`
- `20_processed`
- `30_game_ready`
- `processed`
- `_manifest`
- 多个顶层源图，如 `1.png`、`2.png`、`2UI.png`、`Main.png`、`Next.png`、`Fangjian.png`、角色源图与组件源图
- `Art.zip`
- `asset_preview.html`

只读统计：

| 类型 | 数量 |
| --- | ---: |
| `.png` | 969 |
| `.json` | 19 |
| `.md` | 8 |
| `.html` | 1 |
| `.zip` | 1 |
| 目录总数 | 103 |
| `30_game_ready` 文件总数 | 151 |

`30_game_ready` 是当前最适合作为 canonical candidate layer 的目录。其主要分类包括：

| 分类 | 数量 |
| --- | ---: |
| `icons/32` | 14 |
| `icons/64` | 14 |
| character `frames` | 48 |
| `props` | 13 |
| `map_icon` | 6 |
| `map_tile_icon` | 3 |
| `rooms` | 2 |
| `ui_deploy_button` | 8 |
| `ui_deploy_icon` | 4 |
| `ui_deploy_panel` | 3 |
| `ui_key_prompt` | 6 |
| `ui_title_plate` | 3 |

目录定位：

| 路径 | 定位 | 本阶段动作 |
| --- | --- | --- |
| `00_raw` | 原始素材来源层 | DO_NOT_TOUCH |
| `10_working` | 候选生成与临时工作层 | lineage reference，仅 dry-run 分类 |
| `20_processed` | 已处理但不一定 canonical 的中间层 | 对比层，必要时 DEFER |
| `30_game_ready` | 当前首选 canonical candidate layer | KEEP，作为后续 staging review 源候选 |
| `_manifest` | 处理记录、lineage、registry 与报告 | KEEP / DO_NOT_TOUCH |
| `Art.zip` | 压缩包原始来源 | DO_NOT_TOUCH，不解压 |
| `processed` | 旧处理层 / 历史产物 | DEFER，需人工核对来源 |

## 3. `_manifest` lineage 判断

`_manifest` 只可作为 Draw 处理 lineage reference，不是 Godot manifest，也不是 runtime asset manifest。

关键读数：

- `asset_manifest.json` 顶层键：`draw_dir`、`scan`、`sources`、`split_sources`、`skipped`、`candidates`、`supplemental_runs`。
- `asset_manifest.json` 记录 `candidate_count=542`。
- `sources=21`，`split_sources=10`，`skipped=9`，`supplemental_runs=1`。
- `ui_asset_registry.json` metadata 包括 `source_manifest`、`candidate_dir`、`selection_policy`、`quality_counts_after_selection`、`selected_count`、`copied_to_20_processed`、`copied_to_30_game_ready`、`last_supplemental_update`。
- `selected_assets.md` 记录 selected assets 54，copied to `20_processed` 54，copied to `30_game_ready` 27；补充 Deploy UI selection 记录新增 `20_processed` 31、新增 `30_game_ready` 17。

lineage 风险：

- 多数 manifest 记录仍保留旧绝对路径 `D:\A GAME\26.5.30 GameJam\Draw\...`，当前仓库侧路径为 `D:\AGAME1\Draw\...`，后续若进入自动化必须先做路径重映射。
- `candidate` 与 `bbox` 记录可证明切割来源，但不能证明已授权、已审核或可进入 runtime。
- `selected` 与 `game_ready_path` 可作为候选优先级参考，但不能替代 Base Art registry 或 Godot manifest-backed 流程。
- `manual_crop=true` 的记录应 KEEP 并进入人工复核，不应被自动清理。
- `_manifest` 本身必须 KEEP / DO_NOT_TOUCH，因为它是后续复盘旧工具链产物链的主要证据。

## 4. 旧工具链源码风险

本轮只审计源码，没有运行以下脚本。

| 脚本 | 职责 | 是否写死路径 | 是否有 copy / move / delete / overwrite | 是否有 dry-run | 是否可直接运行 | 风险等级 | 建议 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `manage_draw_assets.py` | 标准化 Draw 目录、处理角色 / prop / icon / room、生成 manifest 与 preview | 使用 `draw_dir` 参数，但 manifest 中存在旧绝对路径风险 | 有 `shutil.copy2`、`shutil.rmtree`、`unlink`、`image.save`、`json.dump`、`write_text` | 有 `--apply`，默认 dry-run | 否 | 高 | 只做源码参考；真实执行前必须拆出独立 dry-run 审计与路径重映射 |
| `process_animal_sprites.py` | 角色 sprite 切帧、sheet 与 manifest 生成 | 依赖传入路径 | 有 `mkdir`、`frame.save`、`sheet.save`、`json.dump` | 未见等价 dry-run gate | 否 | 高 | 不直接运行；角色完整动画暂缓 |
| `select_ui_assets.py` | 从候选中挑选 UI 资产，复制到 processed / game_ready 并写报告 | 依赖 Draw root，但候选选择写死在源码常量 | 有 `shutil`、`image.save`、`write_text`，会写 missing/report | 未见安全 dry-run gate | 否 | 高 | 只将其 selection 列表作为 lineage reference |
| `split_magenta_sprites.py` | 基于 magenta / bbox 切 UI 候选并生成 manifest | 依赖 Draw root | 有 `shutil.rmtree(candidates_dir)`、`mkdir`、`crop.save`、`write_text` | 未见安全 dry-run gate | 否 | 极高 | 不直接运行；如需复用必须先移除 destructive 输出逻辑 |

结论：旧工具链只能作为源码审计对象与 lineage reference，不得直接运行。任何真实整理都必须另起安全脚本或人工流程，并先经过审查框验收。

## 5. canonical source 策略

1. `30_game_ready` 是首选 canonical candidate layer。
2. `20_processed` 只作为对比层或次级候选参考，不直接视为 canonical。
3. `10_working/candidates` 只作为 lineage 与 bbox 追溯来源。
4. `00_raw`、`_manifest`、`Art.zip` 不动。
5. 旧脚本不直接运行。
6. `debug_detected_boxes.png` 可作为 review 辅助，但不得进入 Base Art staging。
7. 路径仍含旧绝对路径的记录必须先重映射到 `D:\AGAME1\Draw`，再进入任何真实整理。

## 6. ART05 候选到 Draw 映射

| candidate_id | category | canonical_draw_path | match_status | duplicate_status | staging_suggestion | notes |
| --- | --- | --- | --- | --- | --- | --- |
| CAND-R5-MM-001 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\00_wanjia_dingwei.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | player position icon |
| CAND-R5-MM-002 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\01_weizhi_ge.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | unknown cell |
| CAND-R5-MM-003 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\02_yitan_ge.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | explored cell |
| CAND-R5-MM-004 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\03_saomiao_ge.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | scanned cell |
| CAND-R5-MM-005 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\04_biaoji_qi.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | marker flag |
| CAND-R5-MM-006 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\05_dici_xianjing_icon.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | mine / trap marker |
| CAND-R5-MM-007 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\06_guaiwu_icon.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | monster marker |
| CAND-R5-MM-008 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\07_baoxiang_icon.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | chest marker |
| CAND-R5-MM-009 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\08_cheli_icon.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | retreat marker |
| CAND-R5-MM-010 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\09_chukou_icon.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | exit marker |
| CAND-R5-MM-011 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\10_yiqingli_icon.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | cleared marker |
| CAND-R5-MM-012 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\11_shuzi_1.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | number 1 |
| CAND-R5-MM-013 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\12_shuzi_2.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | number 2 |
| CAND-R5-MM-014 | MiniMap / MapOverlay | `D:\AGAME1\Draw\30_game_ready\icons\32\13_shuzi_3.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | number 3 |
| CAND-R5-RB-001 | Room background | `D:\AGAME1\Draw\30_game_ready\rooms\fangjian_jichu_1024.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | room background |
| CAND-R5-RP-001 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\00_baoxiang_kai.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | open chest |
| CAND-R5-RP-002 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\03_baoxiang_guan.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | closed chest |
| CAND-R5-RP-003 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\05_yichang_hexin.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | anomaly core |
| CAND-R5-RP-004 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\06_dici_xianjing.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | spike trap |
| CAND-R5-RP-005 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\08_saomiaoyi.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | scanner |
| CAND-R5-RP-006 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\09_jinbi_dui.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | coin pile |
| CAND-R5-RP-007 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\10_yiliaobao.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | medkit prop |
| CAND-R5-RP-008 | Room prop | `D:\AGAME1\Draw\30_game_ready\props\11_wuzi_xiang.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | supply crate |
| CAND-R5-PL-001 | Player idle / facing | `D:\AGAME1\Draw\30_game_ready\characters\huli\frames\00_front_idle.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | front idle |
| CAND-R5-PL-002 | Player idle / facing | `D:\AGAME1\Draw\30_game_ready\characters\huli\frames\01_back_idle.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | back idle |
| CAND-R5-PL-003 | Player idle / facing | `D:\AGAME1\Draw\30_game_ready\characters\huli\frames\02_left_idle.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | left idle |
| CAND-R5-PL-004 | Player idle / facing | `D:\AGAME1\Draw\30_game_ready\characters\huli\frames\03_right_idle.png` | exact_name | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | right idle |
| CAND-R5-UI-001 | common UI / resource icon | `D:\AGAME1\Draw\30_game_ready\ui_icon\ui_icon_account_gold.png` | semantic_match | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | account gold icon |
| CAND-R5-UI-002 | common UI / resource icon | `D:\AGAME1\Draw\30_game_ready\ui_button_blank\ui_button_blank_dark.png` | semantic_match | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | blank button |
| CAND-R5-UI-003 | common UI / resource icon | `D:\AGAME1\Draw\30_game_ready\ui_summary_bar\ui_bar_blank_dark.png` | semantic_match | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | blank bar |
| CAND-R5-UI-004 | common UI / resource icon | `D:\AGAME1\Draw\30_game_ready\ui_panel\ui_panel_terminal_main.png` | semantic_match | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | terminal panel |
| CAND-R5-UI-005 | common UI / resource icon | `D:\AGAME1\Draw\30_game_ready\ui_deploy_icon\ui_icon_backpack.png` | semantic_match | covered_by_30_game_ready | NEEDS_MANUAL_REVIEW | source was HUD icon; canonical is deploy icon |
| CAND-R5-UI-006 | common UI / resource icon | `D:\AGAME1\Draw\30_game_ready\ui_deploy_icon\ui_icon_compass.png` | semantic_match | covered_by_30_game_ready | KEEP_FOR_STAGING_REVIEW | compass icon |
| CAND-R5-UI-007 | common UI / resource icon | `D:\AGAME1\Draw\30_game_ready\ui_icon\ui_icon_account_gold.png` | semantic_partial | possible_duplicate | NEEDS_MANUAL_REVIEW | `jinbi_icon` maps to account gold, not exact filename |
| CAND-R5-UI-008 | common UI / resource icon | `N/A` | no_exact_match | not_covered | DEFER | health bar fill needs separate review |
| CAND-R5-MK-001 | marker | `D:\AGAME1\Draw\30_game_ready\map_icon\map_icon_chest.png` | semantic_match | covered_by_30_game_ready | NEEDS_MANUAL_REVIEW | old `room_treasure` name not exact |
| CAND-R5-MK-002 | marker | `N/A` | no_exact_match | not_covered | DEFER | `room_safe` has no exact 30_game_ready marker |
| CAND-R5-MK-003 | marker | `D:\AGAME1\Draw\30_game_ready\map_icon\map_icon_monster.png` | semantic_match | covered_by_30_game_ready | NEEDS_MANUAL_REVIEW | old filename not exact |
| CAND-R5-MK-004 | marker | `D:\AGAME1\Draw\30_game_ready\map_icon\map_icon_exit.png` | semantic_match | covered_by_30_game_ready | NEEDS_MANUAL_REVIEW | exit / retreat semantics must be reviewed |
| CAND-R5-MK-005 | marker | `D:\AGAME1\Draw\30_game_ready\map_icon\map_icon_event.png` | semantic_match | covered_by_30_game_ready | NEEDS_MANUAL_REVIEW | old filename not exact |
| CAND-R5-MK-006 | marker | `D:\AGAME1\Draw\30_game_ready\map_icon\map_icon_mine.png` | semantic_partial | covered_by_30_game_ready | NEEDS_MANUAL_REVIEW | danger may not equal mine |

Marker 类旧文件名未完全匹配时，只标记 `NEEDS_MANUAL_REVIEW`，不得自动替换。

## 7. quarantine dry-run 清单

本节仅为 dry-run 清单，不授权真实 quarantine。`action` 只能是 `quarantine_candidate`。

| source_path_or_rule | reason | canonical_replacement_if_any | risk_level | action | requires_manual_review |
| --- | --- | --- | --- | --- | --- |
| hash duplicate groups, total `119` | 完全重复 hash，需人工选择 canonical | 优先 `30_game_ready` 等价版本 | medium | quarantine_candidate | true |
| `D:\AGAME1\Draw\Huanxiong.png` | 与 `00_raw\characters\Huanxiong.png` hash 相同 | `00_raw\characters\Huanxiong.png` | low | quarantine_candidate | true |
| `D:\AGAME1\Draw\Huli.png` | 与 `00_raw\characters\Huli.png` hash 相同 | `00_raw\characters\Huli.png` | low | quarantine_candidate | true |
| `D:\AGAME1\Draw\Mao.png` | 与 `00_raw\characters\Mao.png` hash 相同 | `00_raw\characters\Mao.png` | low | quarantine_candidate | true |
| `D:\AGAME1\Draw\Tuzi.png` | 与 `00_raw\characters\Tuzi.png` hash 相同 | `00_raw\characters\Tuzi.png` | low | quarantine_candidate | true |
| `D:\AGAME1\Draw\10_working\candidates\5\5_candidate_052.png` | 与 `20_processed\ui_deploy_row\ui_talent_row_normal.png` hash 相同 | `20_processed\ui_deploy_row\ui_talent_row_normal.png` | medium | quarantine_candidate | true |
| `D:\AGAME1\Draw\10_working\candidates\5\5_candidate_053.png` | 与 `20_processed\ui_deploy_row\ui_talent_row_locked.png` hash 相同 | `20_processed\ui_deploy_row\ui_talent_row_locked.png` | medium | quarantine_candidate | true |
| `D:\AGAME1\Draw\30_game_ready\*\debug_detected_boxes.png` | debug 检测图不是 staging 候选 | none | medium | quarantine_candidate | true |
| `20_processed` 中已有 `30_game_ready` 等价版本的副本 | canonical 已在 `30_game_ready` | `30_game_ready` 对应文件 | medium | quarantine_candidate | true |
| `10_working/candidates` 中未进入 processed / game_ready 的临时候选 | 临时切片，质量与语义未通过 selection | none | high | quarantine_candidate | true |

不得写 `delete_now`。真实 quarantine 只能移动到归档区，不能永久删除。

## 8. KEEP / QUARANTINE_CANDIDATE / DEFER / DO_NOT_TOUCH

| 分类 | 代表路径 | 理由 | 后续动作 |
| --- | --- | --- | --- |
| KEEP | `D:\AGAME1\Draw\30_game_ready` | canonical candidate layer | 进入 staging review 候选，不自动复制 |
| KEEP | `D:\AGAME1\Draw\_manifest` | lineage reference | 保留，用于审计与路径重映射 |
| KEEP | `D:\AGAME1\Draw\00_raw` | 原始来源 | 保留，不移动不删除 |
| KEEP | `D:\AGAME1\Draw\Art.zip` | 原始压缩包 | 保留，不解压 |
| KEEP | ART05 依赖文档 / commit `44323331...` | R5 映射来源 | 保留作为上游依据 |
| KEEP | `manual_crop=true` 相关文件 | 手工裁切信息有审计价值 | 保留并人工复核 |
| QUARANTINE_CANDIDATE | 重复副本 | hash 完全重复且有 canonical 替代 | 审查后移入归档区 |
| QUARANTINE_CANDIDATE | `debug_detected_boxes.png` | debug 产物，不是美术候选 | 审查后移入归档区 |
| QUARANTINE_CANDIDATE | 明确临时产物 | 未进入 processed / game_ready | 审查后移入归档区 |
| DEFER | 主菜单 / 宣传大图 | 不服务当前 A/B 接口 | 后续视觉方向确认后再处理 |
| DEFER | 完整 walk 动画 | R5/ART05 只要求 idle / facing | 等角色动画接口稳定 |
| DEFER | `20_processed` 旧输出层 | 中间层，需与 `30_game_ready` 比对 | 后续真实整理前再判定 |
| DEFER | 旧路径未重映射内容 | manifest 仍含 `D:\A GAME...` | 先做路径重映射策略 |
| DO_NOT_TOUCH | `_manifest` | lineage 证据 | 不移动、不删除、不重写 |
| DO_NOT_TOUCH | `30_game_ready` | canonical candidate layer | 不清理、不覆盖 |
| DO_NOT_TOUCH | `00_raw` | 原始来源 | 不动 |
| DO_NOT_TOUCH | `Art.zip` | 原始包 | 不解压、不删除 |
| DO_NOT_TOUCH | 旧工具链脚本本体 | 审计对象，不是执行对象 | 不运行、不修改 |

## 9. Base Art staging gate

可进入 staging review 的候选：

- ART05 中 `match_status=exact_name` 且 canonical 位于 `30_game_ready` 的 MiniMap / MapOverlay 图标。
- `30_game_ready\rooms\fangjian_jichu_1024.png`。
- `30_game_ready\props` 中与 ART05 exact match 的 8 个 prop。
- `30_game_ready\characters\huli\frames\00_front_idle.png` 到 `03_right_idle.png`。
- `30_game_ready` 中 exact / semantic match 且风险已人工确认的 UI 基础件。

仍需 `pending_verification` / `pending_review` 的候选：

- UI-005、UI-007、UI-008。
- marker 类旧文件名与 canonical 名称不完全一致的所有条目。
- 任何来源仍停留在旧绝对路径、manual_crop、processed-only 或 duplicate group 的条目。

不得进入 Base Art staging 的内容：

- debug 图。
- `Art.zip`。
- `00_raw` 原图。
- 未通过 R5 review 的 `10_working/candidates` 临时切片。
- 字体、音频、视频。
- 完整 walk 动画与复杂 transition / reward VFX。

## 10. 后续执行条件

- 下一步若要真实 quarantine，必须先由审查框验收并 push 本文档。
- 真实 quarantine 只能移动到归档区，不得永久删除。
- 永久删除至少需要两轮复审。
- R7 才能复制小批素材到 Base Art staging。
- 复制到 Base Art staging 前必须明确来源授权、review 通过、规格确认和 registry 写入 gate。
- 仍不得导入 Godot。
- 仍不得修改 manifest。
- 仍不得修改 scripts / scenes。
- 仍不得运行旧工具链脚本。

