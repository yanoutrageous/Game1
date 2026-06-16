# Validation Status Matrix

## R3d1 Scope

本文件记录阶段验证状态，并强制区分 `Godot headless project-load/parser smoke PASS`, `manual playtest PASS`, `full gameplay runtime PASS`, `not run`, `not claimed`, and `unknown`。

- `Godot headless project-load/parser smoke PASS` 只代表 headless project-load/parser smoke，不代表 gameplay runtime PASS。
- `manual playtest PASS` 只有在明确手动验证证据存在时才能登记；本矩阵不从静态验证推断 manual PASS。
- `full gameplay runtime PASS` 只有完整 gameplay runtime 证据存在时才能登记；本矩阵不把 parser smoke 或 docs-only validation 升格为 runtime PASS。
- G20 当前是 docs-only governance，不运行 Godot，不声明 parser smoke，不声明 gameplay runtime PASS，不声明 manual playtest PASS。

## Matrix

| stage | static_validation | godot_parser_smoke | manual_playtest | full_gameplay_runtime | merged_to_main | evidence_sources | unverified_scope | notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| G10 | static validation PASS recorded | unknown / not claimed | unknown / not claimed | not claimed | yes | `docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md`; `docs/stage_summaries/G10_SUMMARY.md` | complete gameplay runtime; manual playtest PASS | G10 closeout static validation is recorded; no runtime/manual PASS is inferred. |
| G11 | static validation recorded | not claimed | not claimed | not claimed | yes | `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`; `docs/stage_summaries/G11_SUMMARY.md` | full manual completion evidence; full gameplay runtime | Manual playtest coverage guidance exists, but R3d1 does not find a complete manual PASS claim. |
| G12 | static validation recorded | not run | not claimed | not claimed | yes | `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`; `docs/stage_summaries/G12_SUMMARY.md` | Godot parser smoke; manual playtest PASS; full runtime | Existing records say G12-R3 did not run Godot/editor/game/import. |
| G13 | static validation recorded | not run | not claimed | not claimed | yes | `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`; `docs/stage_summaries/G13_SUMMARY.md` | Godot parser smoke; manual playtest PASS; full runtime | G13 closeout is static-validation only and does not claim runtime PASS. |
| G14 | static validation recorded | not run / not claimed | not claimed | not claimed | yes | `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`; `docs/stage_summaries/G14_SUMMARY.md` | parser smoke; manual playtest PASS; full runtime | Parser hotfix is a code fix, not a Godot parser smoke PASS claim. |
| G15 | static validation recorded | not run | not claimed | not claimed | yes | `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`; `docs/stage_summaries/G15_SUMMARY.md` | Godot parser smoke; manual playtest PASS; full runtime | G15-R3/R4/R5 records say Godot/editor/game/import was not run. |
| G16 | static validation recorded | Godot headless project-load/parser smoke PASS | not claimed | not claimed | yes | `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md`; `docs/stage_summaries/G16_SUMMARY.md` | manual playtest PASS; full gameplay runtime PASS | Parser smoke PASS must not be reported as gameplay runtime PASS or manual playtest PASS. |
| G17 | static validation recorded | Godot headless project-load/parser smoke PASS | not claimed | not claimed | yes | `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md`; `docs/stage_summaries/G17_SUMMARY.md` | manual playtest PASS; full gameplay runtime PASS | Parser smoke PASS only validates project-load/parser status. |
| G18 | static validation recorded | Godot headless project-load/parser smoke PASS | not claimed | not claimed | yes | `docs/validation/G18_DEPLOY_PREP_FOUNDATION_VALIDATION.md`; `docs/stage_summaries/G18_SUMMARY.md` | manual playtest PASS; full gameplay runtime PASS | G18 does not start RunScene and does not claim gameplay runtime PASS. |
| G19 | static validation recorded | Godot headless project-load/parser smoke PASS | not claimed | not claimed | yes | `docs/validation/G19_LONG_TERM_SHELL_FOUNDATION_VALIDATION.md`; `docs/stage_summaries/G19_SUMMARY.md` | manual playtest PASS; full gameplay runtime PASS | G19-R4B parser smoke is not complete gameplay runtime PASS and not manual playtest PASS. |
| G20-R3a | docs-only static inventory | not run | not run / not claimed | not claimed | no | `docs/NEXT_HANDOFF.md`; `docs/ENGINEERING_STATUS.md`; `git show caaf3c5` | Godot parser smoke; manual playtest; full gameplay runtime | Design source text copy import only; no Godot project/scenes/resources validation claim. |
| G20-R3b | docs-only static inventory | not run | not run / not claimed | not claimed | no | `docs/NEXT_HANDOFF.md`; `docs/ENGINEERING_STATUS.md`; `git show 81513bd` | Godot parser smoke; manual playtest; full gameplay runtime | Governance maps and indexes only. |
| G20-R3c | docs-only static inventory | not run | not run / not claimed | not claimed | no | `docs/DOCS_INDEX.md`; `docs/route_analysis/ROUTE_ANALYSIS_G10_TO_G19.md`; `git show 10a2dd3` | Godot parser smoke; manual playtest; full gameplay runtime | Stage summaries and route analysis only; G21 not started. |
| G20-R3d1 | docs-only git/diff validation in this execution | not run | not run / not claimed | not claimed | no | `docs/project_governance/BRANCH_INVENTORY.md`; `docs/project_governance/COMMIT_MILESTONE_MAP.md`; this file | Godot parser smoke; manual playtest; full gameplay runtime | R3d1 adds branch, commit, and validation matrices only. |
| G20-R3d2 | not executed | not run | not run / not claimed | not claimed | no | current G20 navigation docs | all R3d2 scope | R3d2 is intentionally left for a later separately authorized batch. |

## Required Distinctions

- `Godot headless project-load/parser smoke PASS` is not `full gameplay runtime PASS`.
- `Godot headless project-load/parser smoke PASS` is not `manual playtest PASS`.
- `not run` means the execution did not run that validation class.
- `not claimed` means no PASS claim is made even if related docs or checklists exist.
- `unknown` means R3d1 did not find enough evidence to classify the status.
