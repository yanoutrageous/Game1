# Audit Entrypoint

文档状态：I0 当前只读审计入口
最后更新：2026-07-11

第一读取顺序：

```text
docs/README.md
docs/INDEX.md
docs/10_current/CURRENT_STATE.md
docs/10_current/CAPABILITY_MATRIX.yaml
docs/10_current/NEXT_ACTION.md
```

详细项目审计、进度和健康度见 `docs/10_current/I0_BASELINE_ASSESSMENT.md`。执行边界见 `docs/00_governance/EXECUTION_ENVIRONMENT.md`。

## 审计起点

```text
active_repo: D:\AGAME1\active\Game1_work
godot_project: D:\AGAME1\active\Game1_work\Godot\GraytailGodot
branch: i0/project-baseline-refactor
stage: no authorized active stage; I0 closed with recorded safety nonconformance and limitations
```

## 审计边界

- 先核对 branch、HEAD、index、refs、stash、worktree 和完整 status，再解释工作树。
- 将原始 12 项用户 dirty 与 I0 变更分开；不得清理、丢弃或混合暂存。
- 当前 Godot 自动化只允许通过 `tools/i0/invoke_i0_tests.ps1` 使用项目本地固定工具链；直接可见启动在日志隔离门通过前不授权。
- 不把 docs、静态、headless、runner、可见 smoke 或人工检查互相扩大为更强的 PASS。
- `D:\AGAME1\_repo_cache\Game1_work` 是已迁出的旧活动路径；历史文件中的该路径只作时间点证据。
- 不修改或删除 `D:\AGAME1` 外文件。
