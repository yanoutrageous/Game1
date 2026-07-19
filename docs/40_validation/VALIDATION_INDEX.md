# Validation Index

文档状态：M6 关闭后的当前验证入口；最后更新 2026-07-19。

## 当前程序入口

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\validate_m6_real_asset_deploy_settlement_loop.ps1 `
  -RepoRoot E:\AGAME1 `
  -GodotExecutable E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

## 当前结果

| 验证 | 结果 | 边界 |
| --- | --- | --- |
| M6 静态门与 headless runner | PASS_WITH_CLEANUP_DIAGNOSTIC | 真实出勤、装备效果、终局结算、手动保全、幂等历史通过；退出有既有资源清理诊断 |
| ART22 DeployPrep runtime | PASS | 5 个页签、34 个状态、继续/放弃强确认和失败保全界面回归通过 |
| ART23 LongTerm runtime | PASS | 6 个模块、27 个二级页面与动效状态通过 |
| G41 in-run runtime | PASS | 固定步长战斗、交互、掉落和生命周期回归通过 |
| Godot project-load/parser smoke | PASS | Godot 4.6.3 headless editor 加载通过 |
| 完整人工长时间游玩 | not_run | 不得声明 PASS |
| 性能、CI、导出、发布 | not_run | 不得声明 PASS |

当前原文：`docs/validation/M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION.md`。

历史验证继续保留在 `docs/validation/`，但不能覆盖 M6 的最新规则；尤其 M3R/M5 中的自动出勤和放弃金色资源待定语义已被 M6 明确替代。
