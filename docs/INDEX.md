# Game1 Docs Index

文档状态：当前导航索引
最后更新：2026-07-11（I0.7 closeout）

## 第一入口

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/10_current/CURRENT_STATE.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/10_current/NEXT_ACTION.md`

## I0 当前证据

| 类型 | 文档 |
| --- | --- |
| 详细审计 | `docs/10_current/I0_BASELINE_ASSESSMENT.md` |
| 阶段契约 | `docs/20_product/I0_PROJECT_BASELINE_REFACTOR_CONTRACT.md` |
| 审计范围 | `docs/10_current/AUDIT_SCOPE.md` |
| 未完成系统 | `docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md` |
| 验证索引 | `docs/40_validation/VALIDATION_INDEX.md` |
| 最终 I0 validation | `docs/validation/I0_PROJECT_BASELINE_REFACTOR_VALIDATION.md` |
| 最终 I0 handoff | `docs/handoff/HANDOFF_I0_PROJECT_BASELINE_REFACTOR.md` |
| active stage（当前无授权阶段） | `docs/50_stages/active/STAGE_INDEX.md` |
| closed stage | `docs/50_stages/closed/STAGE_INDEX.md` |
| 当前执行环境 | `docs/00_governance/EXECUTION_ENVIRONMENT.md` |
| 文本编码台账 | `docs/00_governance/TEXT_ENCODING_LEDGER.md` |

I0 已关闭为 `CLOSED_WITH_RECORDED_SAFETY_NONCONFORMANCE_AND_LIMITATIONS`。实现自动化为 PASS_WITH_NOTES，可见烟测为有限覆盖；完整人工游玩、最终视觉、CI 或发布 PASS 不得推断。当前没有已授权后续阶段。

## 治理入口

- `docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`
- `docs/00_governance/DOC_PLACEMENT_STANDARD.md`
- `docs/00_governance/DOCUMENT_LIFECYCLE.md`
- `docs/00_governance/SOURCE_REGISTRY.md`
- `docs/00_governance/EXTERNAL_SOURCE_BOUNDARY.md`
- `docs/00_governance/DUPLICATE_DOC_LEDGER.md`

## 历史证据边界

- G40 及更早阶段原文保留在 `docs/validation/`、`docs/handoff/`、`docs/art/`、`docs/audits/`、`docs/stage_summaries/` 等原位置。
- `docs/PROJECT_BASELINE.md`、`docs/ENGINEERING_STATUS.md`、`docs/NEXT_HANDOFF.md` 和 `docs/project_governance/` 是 expanded / historical evidence，不是当前事实入口。
- 历史文件中的 `D:\AGAME1\_repo_cache\Game1_work` 可以是当时的真实路径；不得批量替换。
- G40 健康矩阵已降为历史阶段矩阵，不在当前第一入口中。

## 当前验证命令

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/i0/invoke_i0_tests.ps1 -Profile remediated
```
