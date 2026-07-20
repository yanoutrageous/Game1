# Art Docs

文档状态：I1 当前美术流程与历史证据入口
适用范围：`docs/art` 下美术流程、资产导入、表现层协作记录
最后更新：2026/07/20

本目录保存 ART 阶段、资产流程和表现层相关文档。它不替代 `docs/10_current`、`docs/INDEX.md` 或 `docs/00_governance`。

## 当前口径

- 项目级上一闭合美术阶段是 ART21 主菜单场景重构。
- ART23 是较晚且已验收的页面/UI 运行证据切片，可作具体页面回归依据，但不提升为项目级 latest closed art stage。
- ART24R2 以 `FAIL (24/61 PASS)` 封存，不能作为合格美术基线。
- I1 对 production UI、动画缓存/状态帧、ART25 来源/许可/manifest 和快速预览进行基线改善；ART25 资源门与最新 27 张预览的静态布局、层级、文字、无遮挡与无裁切检查已通过。I1 不是自动命名的新 ART stage，鼠标/手柄、动态动画、最终视觉/音频仍未验收。
- I1 当前证据入口：`docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`；生产预览操作见 `docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md`。

## 当前 ART 收尾索引

| Stage | 状态 | 主要文档 | 结论 |
| --- | --- | --- | --- |
| ART-21R2 | closed_partial_image_boundary_source_contract | `docs/art/ART21R2_CLOSEOUT_IMAGE_BOUNDARY_SOURCE_CONTRACT_PASS_VISUAL_PARTIAL.md`; `docs/art/validation/art21r2/`; `tools/validate_art21r2_image_boundary_ui.ps1` | PARTIAL: Main Menu `Main.png` source planks, Map Overlay event/flag, modal family, Long Term structure, and route guards are proven. Final UI visual completion and high-resolution QA are not claimed. |
| ART-21R1 | closed_partial_ue_floor | `docs/art/ART21R1_UE_PARITY_FLOOR_EXISTING_ASSETS.md`; `docs/art/ART21R1_CLOSEOUT_UE_PARITY_FLOOR.md`; `docs/art/validation/art21r1/`; `tools/validate_art21r1_ue_parity.ps1` | PARTIAL: `ue_parity_floor_partial / blockers_listed`. Run HUD world layer and main-menu direct Deploy Prep route are repaired with existing assets; Deploy / Long-term page-family, map tile readability, inventory keyboard route, and ground-loot live trigger remain blockers. |
| ART-21 | closed_with_residual_visual_risk | `docs/art/ART21_LUA_UE_EXECUTION_LOGIC_UI_PLACEMENT_REBUILD.md`; `docs/art/ART21_CLOSEOUT_UI_PLACEMENT_CONTRACT_REBUILD.md`; `docs/art/validation/art21/UI_PLACEMENT_CONTRACT.md` | UI Placement Contract established and mirrored in Godot runtime; core screens rebuilt against Lua / UE execution references. Ground loot live trigger remains NOT_TRIGGERED; final visual completion is not claimed. |
| ART-20 | closed_with_visual_gap | `docs/art/ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION.md`; `docs/art/ART20_CLOSEOUT_PIPELINE_PASS_VISUAL_INCOMPLETE.md` | Draw/source 到 Godot runtime 的切片、导入、manifest、visual_key、UI consumer 链路通过；核心 UI 目标视觉未完成，ART-21 必须补 `UI_ASSET_PLACEMENT_INDEX` 和核心界面视觉落地。 |

## 使用规则

```text
1. 新 ART 文档可落位于本目录，但必须遵守 docs/00_governance/DOC_PLACEMENT_STANDARD.md。
2. 不把美术导入记录写成玩法规则。
3. 不从 UI 图片反推规则权威。
4. 不修改 Base Art、Base Docs、Connection 或 Godot metadata。
```
