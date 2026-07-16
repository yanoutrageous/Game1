# Audit Entrypoint

文档状态：I0 + ART21 整合基线审计入口
最后更新：2026-07-16

## 读取顺序

1. `docs/README.md`
2. `docs/INDEX.md`
3. `docs/10_current/CURRENT_STATE.md`
4. `docs/10_current/CAPABILITY_MATRIX.yaml`
5. `docs/10_current/NEXT_ACTION.md`

详细证据：

- I0 历史评估：`docs/10_current/I0_BASELINE_ASSESSMENT.md`
- I0 最终验证：`docs/validation/I0_PROJECT_BASELINE_REFACTOR_VALIDATION.md`
- ART21 最终关闭：`docs/art/ART21_CLOSEOUT_MAIN_MENU_SCENE_RECONSTRUCTION.md`
- 本次整合验证：`docs/validation/I0_ART21_BASELINE_INTEGRATION_VALIDATION.md`

## 当前审计起点

```text
active_repo: git rev-parse --show-toplevel
branch: integration/i0-art21-baseline
I0_source: 77569579a6c66d9f4350f0ba419906a7814dd502
ART21_source: 93420a8f3799c540ac8a2b46d3c264d5f3ee10f1
stage: no authorized successor stage
```

## 审计边界

- 先核对远端哈希、HEAD、branch、status、index、refs、stash 与 worktree，再解释差异。
- 不清理、覆盖或提交其他 worktree 的已有 dirty 状态。
- 当前脚本必须从 Git worktree 和显式工作区参数解析路径。
- 旧机器路径只可作为历史证据，不能选择当前仓库或工具链。
- Godot 自动化只通过 I0 隔离 headless harness；不授权直接可见启动。
- 不把静态、runner、截图或有限人工观察扩张为完整发布结论。
