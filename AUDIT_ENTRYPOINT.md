# Audit Entrypoint

文档状态：I1 当前审计入口
最后更新：2026-07-20

## 读取顺序

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/10_current/CURRENT_STATE.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/10_current/NEXT_ACTION.md`

I1 核心材料：

- 契约：`docs/20_product/I1_INCREMENTAL_DEVELOPMENT_BASELINE_CONTRACT.md`
- 评估：`docs/10_current/I1_BASELINE_ASSESSMENT.md`
- 架构：`docs/30_engineering/architecture/I1_ARCHITECTURE_BASELINE.md`
- 操作：`docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md`
- 验证：`docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`
- 交接：`docs/handoff/HANDOFF_I1_INCREMENTAL_DEVELOPMENT_BASELINE.md`

## 当前审计起点

```text
active_repo: git rev-parse --show-toplevel
observed_branch: codex/i1-baseline-stabilization
source_head: 2212992337aeef7cda412dbaaa191c3ad6cbb81a
stage: I1 / worktree accepted / committed HEAD pending
latest_closed_non_art_baseline: I0
latest_closed_art_stage: ART21
later_accepted_page_ui_evidence: ART23
ART24R2: historical failed acceptance, 24/61 PASS
```

## 审计顺序

1. 解析 Git worktree root，核对 branch、HEAD、origin、dirty、staged、untracked、stash 和 worktree。
2. 以当前代码和 runner 为事实源，再核对契约与文档是否准确。
3. 复核已冻结的 static、preflight、quick、core、ui、full worktree JSON；当前结果分别为 PASS、PASS、21/21、24/24、23/23、39/39。
4. 复核最新 27/27 production capture 与 9 状态 × 3 分辨率人工静态图片结论；机器状态保持 review required，人工结论只覆盖布局、层级、文字、无遮挡与无裁切。
5. 复核已通过的 ART25 来源/许可/manifest/确定性证据，并完成文档引用/编码、`git diff --check` 和 metadata 暂存边界检查。
6. 精确暂存并提交后以 `SourceMode head` 运行 full；只有该结果证明确切提交。
7. push 后另行观察 GitHub Actions；没有成功 run 时 CI 仍为 unproven。

## 声明边界

- I1 当前 validation/handoff 已记录 worktree acceptance，但 committed HEAD、commit、push 仍 pending，不能靠 worktree 证据关闭阶段。
- headless / runner / 静态结果不替代完整人工游玩、最终视觉、交互手感、通用性能、导出或发布。
- ART23 只作为较晚页面/UI 证据；项目级 latest closed art stage 仍按治理权威记为 ART21。
- 历史绝对路径不能选择当前仓库、Godot 或外部 source pack。
- 不清理、覆盖或混合暂存无法解释的用户 dirty；Godot metadata 必须有明确 gate。
