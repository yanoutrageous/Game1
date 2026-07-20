# Game1 / GraytailGodot

当前仓库正在建立 I1 增量开发基线。当前 worktree candidate 已通过 static、全部 worktree profiles、ART25 资源门和生产预览静态图片复核；精确提交后的 `full HEAD`、commit、push 与远端 CI 仍待完成，因此不得把 I1 记为关闭。

```text
repository: resolve with git rev-parse --show-toplevel
godot_project: <repository>/Godot/GraytailGodot
current_stage: I1 / worktree accepted / committed HEAD pending
latest_closed_non_art_baseline: I0
latest_closed_art_stage: ART21
later_accepted_page_ui_evidence: ART23
failed_historical_art_attempt: ART24R2 (24/61 PASS)
```

## 首要入口

1. `AUDIT_ENTRYPOINT.md`
2. `docs/README.md`
3. `docs/INDEX.md`
4. `docs/10_current/CURRENT_STATE.md`
5. `docs/10_current/NEXT_ACTION.md`

## 日常快速验证

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1.ps1 `
  -Profile quick `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

`E:\Godot` 是当前机器观测路径，不是跨机器默认值。其他环境使用 `-GodotExe`、`I1_GODOT_EXE` / `GODOT4` / `GODOT_EXE` 或 PATH；harness 会核对锁定版本、hash 和文件身份。

## 快速生产预览

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i1\invoke_i1_preview.ps1 -All `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

预览输出在 `.tmp/i1/<run-id>/previews/`。最新 9 状态 × 3 分辨率的 27 张图片已完成人工静态检查，布局、层级、文字、无遮挡与无裁切通过；机器报告仍要求视觉复核，鼠标/手柄手感、动态动画观感、音频与打击体感仍未验收，不得写成最终视觉或交互 PASS。

## 当前边界

- I1 验收通过后，项目适合进入“新增能力与存量修改并行”，但不是维护期或功能冻结。
- 当前进程内继续运行不等于退出 Godot 后的 active-run 恢复；后者未实现。
- `I1_COMBAT_REFRESH` 只证明战斗刷新微基准，不代表通用性能、设备矩阵或发布性能。
- GitHub Actions quick workflow 已配置，但远端实际成功前仍是 `configured_unproven`。
- 完整人工长局、最终美术/音频、完整经济、通用性能、导出和发布均未验收。
- 历史 validation / handoff 中的固定盘符只保留时间点证据属性。

完整操作见 `docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md`。
