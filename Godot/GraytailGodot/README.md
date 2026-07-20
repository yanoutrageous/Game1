# GraytailGodot

这是《灰尾回收 / 五四三二一》的当前 Godot 4 工程入口。

```text
project_path: <git-worktree-root>/Godot/GraytailGodot
engine_version: 4.6.3.stable.official.7d41c59c4
current_stage: I1 / worktree accepted / committed HEAD pending
latest_closed_non_art_baseline: I0
latest_closed_art_stage: ART21
```

当前仓库事实入口：

```text
../../docs/10_current/CURRENT_STATE.md
../../docs/10_current/I1_BASELINE_ASSESSMENT.md
../../docs/30_engineering/architecture/I1_ARCHITECTURE_BASELINE.md
../../docs/40_validation/VALIDATION_INDEX.md
```

## 当前工程口径

- 本目录保存运行时脚本、场景、资源、数据、项目配置和工程历史 docs。
- 本目录下 `docs/` 是历史/工程证据，不替代仓库当前事实链。
- 日常验证从仓库根运行 `tools/i1/invoke_i1.ps1`；它使用隔离 mirror、锁定 Godot、隔离环境和污染守卫。
- 快速界面阅览从仓库根运行 `tools/i1/invoke_i1_preview.ps1`，并从 production `scenes/main/main.tscn` 生成预览。
- 本机 Godot 位于 `E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe`；该路径不是跨机器默认值。

## 修改边界

1. `RunStateMachine`、`RunRuntimeController`、`RunAssetLedger`、`SaveAdapter` 和 presentation 的权威边界见 I1 architecture。
2. parser/headless/runner PASS 只证明覆盖的契约；最新 preview 人工静态 PASS 只覆盖布局、层级、文字、无遮挡与无裁切，不等于交互、动态动画或音频 PASS。
3. 当前进程 continue 不等于退出程序后的 active-run 恢复。
4. `I1_COMBAT_REFRESH` 只证明 combat 刷新微基准，不等于通用性能。
5. `project.godot`、场景、资源、`.uid`、`.translation` 和 import metadata 必须经过明确 gate 才能变更或暂存。
6. 活动工程不得用于无隔离的 editor/import 试跑；自动化和 capture 应走 I1 mirror。
7. 新资源必须有来源、许可、hash、manifest 和 runtime key 证据。

完整命令见 `../../docs/30_engineering/godot/I1_DEVELOPMENT_PREVIEW_VALIDATION_RUNBOOK.md`。
