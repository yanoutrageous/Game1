# Game1 / GraytailGodot

当前仓库基线由 I0 工程基线与 ART21 主菜单场景基线整合而成。

```text
repository: resolve with git rev-parse --show-toplevel
godot_project: <git-worktree-root>/Godot/GraytailGodot
integration_branch: integration/i0-art21-baseline
latest_non_art_stage: I0
latest_art_stage: ART21
active_successor_stage: none
```

## 首要入口

1. `AUDIT_ENTRYPOINT.md`
2. `docs/README.md`
3. `docs/INDEX.md`
4. `docs/10_current/CURRENT_STATE.md`
5. `docs/10_current/NEXT_ACTION.md`

## 当前验证

先建立工作区内的锁定 Godot 4.6.3 工具链：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\bootstrap_toolchain.ps1
```

再运行 I0 的隔离 headless 套件：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile remediated
```

ART21 主菜单结构门：

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\validate_art21_main_menu_scene.ps1
```

## 边界

- 当前路径权威来自 Git worktree，不来自固定盘符。
- 历史 I0 validation / handoff 中的 `D:\AGAME1` 是当时机器证据，不是当前配置。
- I0 仍保留已记录的可见启动安全不符合项、有限人工覆盖和退出清理提示。
- ART21 已关闭，但不自动授权 ART22、产品内容扩展、CI 或发布阶段。
- headless / 静态验证不等于完整人工游玩、最终视觉、性能或发布 PASS。
- 当前整合与验收不使用 Computer Use，也不直接启动可见 Godot。
