# ART-12 美术资产治理、产品化素材缺口清单与下一批 runtime 素材准备

文档状态：ART-12 execution summary
生成时间：2026-06-27

## 0. 文档定位

ART-12 的目标不是继续 UI 代码返工，也不是直接导入 Godot，而是把当前美术素材体系整理成可持续推进的资产管理基线。

本阶段只生成仓库文档和验证脚本，不修改素材，不修改 Base Art registry，不修改 Godot runtime assets，不修改 `asset_manifest.csv`，不运行 Godot，不 commit / push。

## 1. 当前环境与分支状态

| 项 | 结果 |
| --- | --- |
| git root | `D:/AGAME1/_repo_cache/Game1_work` |
| 当前分支 | `docs/doc-gov-002` |
| 当前 HEAD | `f10b8052feaab3e553f01fa2b54d3dfb2ec9dc5f` |
| 最新提交 | `f10b805 docs: align document governance indexes` |
| protective stash | `stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two` 存在 |

分支不是美术分支不作为阻断。当前工作区 dirty 可归类为 Godot generated side effects，ART-12 不清理、不 stage、不提交。

## 2. Generated Side Effects Gate

当前 dirty 中包括：

- `Godot/GraytailGodot/project.godot`
- `Godot/GraytailGodot/data/assets/asset_manifest.*.translation`
- 多项 `Godot/GraytailGodot/**/*.gd.uid`

这些文件不属于 ART-12 成果。执行框不清理、不 reset、不 stash、不 stage。后续审查 / 验收框需要继续隔离。

## 3. Base Art / Draw / old Draw 对账摘要

详见：

- `docs/art/validation/art12/ASSET_INVENTORY_SUMMARY.md`
- `docs/art/validation/art12/DRAW_BASE_ART_DIFF.md`

核心结论：

- `Base Art` 当前 188 文件，其中 `.png` 182、CSV 4、MD 1、MP4 1。
- `Base Art\03_selected` 52 文件，`05_export_runtime_candidates` 52 PNG，`06_animation_sources` 48 文件，`07_sprite_sheets` 4 文件，`08_visual_targets` 10 文件。
- `Base Art\Base` 有 10 张 UI 确定稿 / 示例 reference。
- `Base Art\M1` 有 6 张图片 + `Lua demo.mp4`。
- `D:\AGAME1\Draw` 与 `D:\A GAME\26.5.30 GameJam\Draw` 均为 998 文件，扩展名统计一致，相对路径 + 文件大小差异为 0。
- old Draw 应视为历史镜像 / 迁移副本，不作为独立来源重复登记。

## 4. Base / M1 Reference 定位

- Base 确定稿用于主菜单、出发探索、长期系统的排版、比例、视觉语义参考。
- M1 / Lua demo 用于 HUD、runtime structure、key prompt、room interaction 节奏参考。
- Base / M1 均不直接进入 runtime，不作为整屏 UI 背景使用。

## 5. Registry 审计摘要

详见：

- `docs/art/validation/art12/BASE_ART_REGISTRY_AUDIT.md`

核心结论：

- `source_registry.csv`：207 行，全部 `pending_verification`。
- `review_status.csv`：207 行，全部 `pending_review`。
- `export_manifest.csv`：52 行，全部 `manifest_status=not_ready`。
- `generation_log.csv`：1 行，记录 ART07 staging operation。
- source_id、candidate_id、export_id 均唯一。
- review source 关系闭合，export candidate 关系闭合。
- `generation_log.source_id=ART07_source_migration` 不在 `source_registry`，但该行是 staging operation，不是图片 source；建议后续通过 operation_id 或 pseudo-source 处理。
- 未发现 `approved`、`final`、`runtime_ready` 作为当前状态承诺；`not_generated_final` 是说明性字符串。
- 存在大量绝对路径 lineage，后续可治理，但本阶段不写 registry。

## 6. UI 产品化素材缺口摘要

详见：

- `docs/art/validation/art12/UI_PRODUCTIZATION_ASSET_GAP.md`

P0 缺口：

1. 主菜单基地门厅背景分层。
2. 出发探索控制台 / 准备大厅背景。
3. 出发探索 loadout slot 与装备 / 消耗品视觉。
4. 长期系统档案室 / 图鉴墙背景。
5. HUD scanner / protocol panel。
6. key prompt global set。

仍暂缓：

- 最终角色立绘。
- 全量角色动画。
- 完整 inventory / loot 产品化。
- Base 确定稿整屏 runtime 导入。

## 7. Runtime Import Candidate 摘要

详见：

- `docs/art/validation/art12/RUNTIME_IMPORT_CANDIDATE_PLAN.md`

下一批建议优先级：

1. 先对已有 manifest-backed key prompt / deploy panel / prop 做 dedupe 与 visual_key 复核。
2. 小批补充 UI background / panel / frame 资产，而不是导入整屏 mockup。
3. 角色只建议 single-frame hero trial，不建议全量 sprite sheet runtime 导入。
4. Draw direct import 仍禁止；需要先经过 Base Art staging。

ART-12 不修改 `asset_manifest.csv`。

## 8. Quarantine Dry-run 摘要

详见：

- `docs/art/validation/art12/QUARANTINE_DRY_RUN.md`

分类规则：

- KEEP
- CANDIDATE
- NEEDS_CROP
- NEEDS_REPAINT
- NEEDS_REVIEW
- QUARANTINE_CANDIDATE
- DO_NOT_TOUCH

特别强调：quarantine dry-run 不是删除授权，不是移动授权，不是清理执行。永久删除至少需要后续单独阶段和二次复审。

## 9. 禁止项

ART-12 已遵守：

- 不修改 Draw。
- 不修改 old Draw。
- 不修改 Base Art。
- 不写 Base Art registry。
- 不复制图片到 Godot。
- 不导入 Godot。
- 不修改 `asset_manifest.csv`。
- 不修改 Godot scripts / scenes / assets。
- 不运行 Godot。
- 不 commit / push。
- 不操作 stash。

## 10. ART-13 进入条件

进入 ART-13 前建议确认：

1. 审计框验收 ART-12 文档与验证脚本。
2. 决定下一批 runtime import 是否只做 P0 小批。
3. 对候选资产补 visual_key、asset_id、尺寸、透明、九宫格 / tile / sprite sheet 规格。
4. 对已有 manifest 资产先做 dedupe，避免重复导入。
5. 如果需要写 Base Art registry，必须单独授权。
6. 如果需要执行 quarantine，必须另起阶段并二次复审。

## 11. Slice 自检记录

| Slice | 结果 |
| --- | --- |
| Slice 0 | repo / branch / HEAD / stash 已确认；dirty 可归类为 generated side effects |
| Slice 1 | Base Art / Draw / old Draw / Base / M1 / runtime assets 已盘点 |
| Slice 2 | Base Art registry 已只读审计，未写 CSV |
| Slice 3 | UI 产品化素材缺口清单已生成 |
| Slice 4 | runtime import candidate plan 与 quarantine dry-run 已生成 |
| Slice 5 | 总文档与验证脚本已生成 |
