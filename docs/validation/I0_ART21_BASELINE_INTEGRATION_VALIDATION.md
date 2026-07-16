# I0 + ART21 Baseline Integration Validation

状态：PASS_WITH_NOTES
日期：2026-07-16

## 中文摘要

I0 工程基线与 ART21 主菜单场景基线已在隔离 worktree 中整合。I0 的
保存、输入、CSV、调试门、12 个 runner 和污染守卫全部保留；ART21 的
主菜单 clean plate、152 个运行时资产、四入口、覆盖层、路由、动效与
多分辨率证据全部保留。当前机器不再把 `D:\AGAME1` 当作执行权威。

整合结论不是纯 PASS：I0 的 24 条退出清理提示、5 个冻结编码例外、
历史可见启动 AppData log 安全不符合项和有限人工覆盖仍然有效。
本次验证不使用 Computer Use，也没有启动可见 Godot。

## 输入基线

| 输入 | 远端哈希 |
| --- | --- |
| `origin/main` | `ecc628d15838288aae17f250ac0298fc79cb15c7` |
| `origin/i0/project-baseline-refactor` | `77569579a6c66d9f4350f0ba419906a7814dd502` |
| `origin/art/art21-main-menu-scene-reconstruction` | `93420a8f3799c540ac8a2b46d3c264d5f3ee10f1` |
| I0 / ART21 common base | `3dbb843e34f16a9a10b7122a0e094c457a7057c6` |

整合分支：`integration/i0-art21-baseline`。

## 冲突决策

- `main_menu_shell.gd` 使用 ART21 最终场景实现。
- `art21_ui_placement_contract.gd` 保留 I0 的广义映射，并桥接
  `Art21MainMenuAssetContract`。
- 资产 manifest 自动合并为 331 个唯一 ID、17 列、无空 ID、无重复。
- 当前治理文档使用 repository-relative 路径；历史绝对路径原文不改写。
- stage index 同时承认 I0 为最新非美术阶段、ART21 为最新美术阶段。

## I0 验证

工作树报告：
`D:\AGAME2\reports\i0\I0.2_20260716T104553690Z_333694ba.json`

| 项目 | 结果 |
| --- | --- |
| overall | `PASS_WITH_NOTES` |
| characterization | `PASS_REMEDIATED_WITH_NOTES` |
| runners | 12 / 12 |
| blocking diagnostics | 0 |
| cleanup diagnostics | 24 |
| document encoding | `PASS_WITH_RECORDED_LIMITATION` |
| static baseline | PASS |
| environment probe | PASS |
| pollution guard | PASS |
| asset manifest | 331 rows / 17 columns / unique IDs |

报告位于当前机器工作区外层的受控报告目录，不纳入 Git。

## ART21 验证

运行时在 I0 隔离镜像中执行：

```text
ART21_MAIN_MENU_RUNTIME=PASS entries=4 overlays=2 transitions=2 shortcuts=2 motion_groups=10
```

结构与回归：

| 命令 | 结果 |
| --- | --- |
| `tools/validate_art21_main_menu_scene.ps1` | PASS |
| `tools/validate_art21_ui_placement_contract.ps1` | PASS |
| `tools/validate_art20_ui_asset_pipeline.ps1` | PASS |
| `tools/validate_art21r1_ue_parity.ps1` | PASS_STRUCTURAL |
| `tools/validate_g39_navigation_boundary.ps1` | PASS |
| `tools/validate_art17_core_screen_layering.ps1` | PASS |

ART21 主门确认：

- 152 个运行时 PNG。
- 66 个 live / interaction-reachable 资产。
- 10.40 MiB 默认保守解码预算。
- 17 条 motion contract，8 条 live tuned、3 条 code motion、
  6 条 deferred optional。
- 6 张状态 / 分辨率证据图。
- ART21 资产目录无 `.import`、`.uid` 或 `.translation` sidecar。

## 未声明

- 未运行 Computer Use。
- 未启动可见 Godot。
- 未执行完整人工游玩。
- 未验证最终性能、兼容性、导出、CI 或发布。
- 未消除 I0 历史 `SAFETY_NONCONFORMANCE`。
