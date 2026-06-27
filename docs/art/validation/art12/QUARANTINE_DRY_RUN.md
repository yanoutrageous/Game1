# ART-12 Quarantine Dry-Run

文档状态：ART-12 validation evidence
生成时间：2026-06-27

## 0. 定位

本文档是 quarantine dry-run，不是删除授权，不是移动授权，不是重命名授权，不是清理执行。

Marker: `NOT_DELETION_AUTHORIZATION`

永久删除至少需要后续单独阶段和二次复审。ART-12 不删除、不移动、不清理素材。

## 1. 分类规则

| 分类 | 含义 | 允许动作 |
| --- | --- | --- |
| KEEP | 当前仍有明确 reference、staging 或 runtime 价值 | 保留，继续引用 |
| CANDIDATE | 可进入后续 source_candidate / runtime candidate 讨论 | 保留，后续审查 |
| NEEDS_CROP | 需要裁切 / 缩放 / 透明边界处理 | 保留，后续加工 |
| NEEDS_REPAINT | 主题方向可用但质量或风格需重绘 | 保留，后续美术处理 |
| NEEDS_REVIEW | 来源、用途、重复关系或授权状态需复查 | 保留，后续审查 |
| QUARANTINE_CANDIDATE | 低价值、重复或 debug 残留的隔离候选 | 只登记，不移动 |
| DO_NOT_TOUCH | 外部原件、历史镜像、确定稿 reference、registry 等不可动内容 | 不修改、不清理 |

## 2. Dry-run 清单

| 路径 / 范围 | 分类 | 理由 | 建议 |
| --- | --- | --- | --- |
| `D:\AGAME1\Base Art\Base` | DO_NOT_TOUCH | 确定稿 / 示例 reference | 不进入 runtime，不移动 |
| `D:\AGAME1\Base Art\M1` | DO_NOT_TOUCH | HUD / Lua demo reference | 不进入 runtime，不移动 |
| `D:\AGAME1\Base Art\_registry` | DO_NOT_TOUCH | 当前 registry source of staging truth | ART-12 只读，不写 |
| `D:\AGAME1\Base Art\05_export_runtime_candidates\art07_first_batch` | CANDIDATE | 首批 runtime candidate staging | 后续做 dedupe / spec / manifest gate |
| `D:\AGAME1\Base Art\03_selected\draw_30_game_ready` | KEEP | selected source staging | 保留 lineage |
| `D:\AGAME1\Base Art\06_animation_sources` | NEEDS_REVIEW | 角色动画源，需角色策略 | 不全量导入 |
| `D:\AGAME1\Base Art\07_sprite_sheets` | NEEDS_REVIEW | sprite sheet 需 animation spec | 不全量导入 |
| `D:\AGAME1\Base Art\08_visual_targets` | DO_NOT_TOUCH | visual target reference_only | 不作为 runtime 背景 |
| `D:\AGAME1\Draw\30_game_ready\debug_detected_boxes.png` variants | QUARANTINE_CANDIDATE | debug detection output，不应进 runtime | 只登记，未来复审 |
| `D:\AGAME1\Draw\10_working\candidates` | NEEDS_REVIEW | 大量候选，未选定 | 不清理，不导入 |
| `D:\AGAME1\Draw\_manifest\duplicates.md` listed groups | NEEDS_REVIEW | average-hash similarity only | 视觉复核后才可处理 |
| `D:\A GAME\26.5.30 GameJam\Draw` | DO_NOT_TOUCH | old Draw mirror / historical lineage | 不作为独立来源清理 |
| `Godot/GraytailGodot/assets` | DO_NOT_TOUCH | runtime assets | ART-12 不改 |
| `Godot/GraytailGodot/**/*.uid`, `.translation`, `.import`, `.godot` | DO_NOT_TOUCH | generated side effects 分类对象 | 不清理、不 stage |

## 3. 特别说明

- `QUARANTINE_CANDIDATE` 不是删除授权。
- `QUARANTINE_CANDIDATE` 不是移动授权。
- `NEEDS_REVIEW` 不是低价值判断，只表示需要后续审查。
- duplicate group 不能仅凭 hash similarity 删除。
- old Draw 与 Draw 当前一致，不能把 old Draw 作为重复垃圾清理。

## 4. 后续复审建议

1. 先冻结 source registry / lineage 口径。
2. 再对 debug_detected_boxes、候选残留、重复组做视觉复核。
3. 生成删除 / 移动计划前必须列出回滚方式。
4. 删除动作必须另起阶段、另行审计、单独授权。

## 5. 自检

- 本文档包含“不是删除授权”。
- 本文档包含 `NOT_DELETION_AUTHORIZATION` 标记，供无中文编码依赖的验证脚本检查。
- 本文档未执行清理。
- 本文档未修改素材。
