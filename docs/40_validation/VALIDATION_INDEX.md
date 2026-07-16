# Validation Index

文档状态：I0 + ART21 整合后的当前验证索引
最后更新：2026-07-16

## 当前入口

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\i0\invoke_i0_tests.ps1 `
  -Profile remediated
```

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File tools\validate_art21_main_menu_scene.ps1
```

## 当前结果

| 验证 | 结果 | 边界 |
| --- | --- | --- |
| I0 工具链 | PASS | Godot 4.6.3 版本、大小、SHA-256 与 Authenticode 通过 |
| I0 文档编码 | PASS_WITH_RECORDED_LIMITATION | 5 个冻结历史异常精确匹配；linked worktree 支持通过 |
| I0 静态基线 | PASS | 12 runner、331 行资产、保存、输入、调试门通过 |
| I0 Godot runners | 12/12 PASS_WITH_CLEANUP_DIAGNOSTIC | 0 blocking、24 cleanup |
| I0 污染守卫 | PASS | Git 与业务文件快照前后不变 |
| ART21 runtime | PASS | 4 entries、2 overlays、2 transitions、2 shortcuts、10 motion groups |
| ART21 scene / asset gates | PASS | 152 PNG、10.40 MiB、6 captures、无运行时 sidecar |
| ART20 / ART21R1 / G39 / ART17 regression | PASS | 管线、结构、路由和层级回归通过 |
| Computer Use | not_run_by_direction | 本阶段明确不使用 |
| 完整人工游玩 / 发布 | not_run | 不得声明 PASS |

本次整合原文：
`docs/validation/I0_ART21_BASELINE_INTEGRATION_VALIDATION.md`。

历史原文：

- `docs/validation/I0_PROJECT_BASELINE_REFACTOR_VALIDATION.md`
- `docs/art/validation/art21/ART21_MAIN_MENU_SCENE_VALIDATION.md`

## 声明边界

- `PASS_WITH_NOTES` 不是纯 PASS。
- headless / runner 不等于完整人工游玩。
- 版本化截图不等于当前机器 Computer Use 验收。
- 阶段关闭不抹除 I0 的 `SAFETY_NONCONFORMANCE`。
