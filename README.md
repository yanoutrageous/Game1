# Game1 / GraytailGodot

I3 是冻结历史，入口提交为 `09aaafe283aa2e4c2f30708c5f88b89ebf7753eb`。I3R 是
当前用户已授权的玩家体验与基础治理返工阶段，状态为 `ACTIVE`；实现入口提交为
`35189aaf524157761d1ab9cdddc39e76baa0d7ca`。最终工作树 full 已 96/96 PASS，
最终 132/125/12 矩阵与 269/269 Codex 静态复核已通过；用户已授权执行 exact-head
与 Git 交付，阶段关闭仍等待真实设备和动态玩家验收。

```text
repository: resolve with git rev-parse --show-toplevel
godot_project: <repository>/Godot/GraytailGodot
current_stage: I3R / ACTIVE / EXTERNAL_ACCEPTANCE_PENDING
latest_closed_non_art_baseline: I2
i3_historical_entry: 09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
i3r_implementation_entry: 35189aaf524157761d1ab9cdddc39e76baa0d7ca
latest_closed_art_stage: ART21
later_accepted_page_ui_evidence: ART23
failed_historical_art_attempt: ART24R2 (24/61 PASS)
```

## 首要入口

1. `docs/50_stages/active/STAGE_INDEX.md`
2. `docs/10_current/CURRENT_STATE.md`
3. `docs/10_current/NEXT_ACTION.md`
4. `docs/20_product/I3R_PLAYER_EXPERIENCE_REWORK_CONTRACT.md`
5. `docs/00_governance/I3R_EXECUTION_LEDGER.md`
6. `docs/00_governance/I3R_REQUIREMENT_MATRIX.md`
7. `docs/40_validation/VALIDATION_INDEX.md`
8. `tools/i3r/README.md`

总审计与文档导航仍见 `AUDIT_ENTRYPOINT.md`、`docs/README.md` 和 `docs/INDEX.md`。

## 日常快速验证

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r.ps1 `
  -Profile quick `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

`E:\Godot` 是当前机器观测路径，不是跨机器默认值。其他环境使用 `-GodotExe`、
`I1_GODOT_EXE` / `GODOT4` / `GODOT_EXE` 或 PATH；I3R 入口复用 I1 的隔离执行器并核对
锁定版本、hash 和文件身份。

## 快速生产预览

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tools\i3r\invoke_i3r_preview_matrix.ps1 -All `
  -SourceMode worktree `
  -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
```

正式 I3R 预览矩阵已生成 132/132，状态为
`PASS_WITH_VISUAL_REVIEW_REQUIRED`；PNG 生成不等于最终视觉或玩家体验通过。当前正式
证据摘要见 `docs/50_stages/active/STAGE_INDEX.md`。

## 当前边界

- I3R 仍为活动返工，不得声明 closed。最终工作树 full 已 96/96 PASS；报告为
  `.tmp/i1/20260726T171400780Z_6f66cb6f/report.json`。最终生产预览 132/132、
  长期系统 125/125、状态画廊 12/12，Codex 静态复核 269/269。
- exact-head/full 与 Git 远端一致性由本次最终交付结果提供；真实设备/控制器/音频、
  目标 GPU 长局和动态玩家/视觉签收仍待完成。
- I2 是最新闭合非美术基线；I3、I1 validation/handoff 均只保留为冻结历史。
- 当前进程内继续运行不等于退出 Godot 后的 active-run 恢复；后者未实现。
- 完整人工长局、最终美术/音频、完整经济、通用性能、导出和发布均未验收。
- 历史 validation / handoff 中的固定盘符只保留时间点证据属性。

I1 的提交态 39/39 与 Actions quick run `29760789712` 仅作为历史证据保留，见
`docs/validation/I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`。当前完整操作见
`tools/i3r/README.md`。
