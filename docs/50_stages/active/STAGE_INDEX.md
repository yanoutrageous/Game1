# Active Stage Index

文档状态：I1 当前 active stage。
最后更新：2026-07-20

## 当前阶段

| Item | Current fact |
| --- | --- |
| Stage | I1 Incremental Development Baseline |
| Status | worktree accepted / committed HEAD pending |
| Active repo | `git rev-parse --show-toplevel` |
| Observed branch | `codex/i1-baseline-stabilization` |
| Source head | `2212992337aeef7cda412dbaaa191c3ad6cbb81a` |
| Latest closed non-art baseline | I0 |
| Latest closed art stage | ART21 |
| Later accepted page/UI evidence | ART23 |
| Failed historical art attempt | ART24R2 / 24 of 61 PASS |
| Local Godot observation | `E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe` |

## I1 Goal

把已有 playable program、UI/动画/资源和文档治理整理为统一的增量开发基线，使后续变更能够快速运行隔离自动化、生产场景预览和明确的人工复核。

## 已完成的 worktree 门

- static PASS：39 blocking / 46 inventory / 13 exclusions / 705 checks。
- preflight、quick 21/21、core 24/24、ui 23/23、full 39/39 worktree PASS，污染守卫 PASS。
- ART25 107 assets 来源、许可、manifest 与确定性门 PASS。
- 九状态 × 三分辨率 27/27 生产预览已生成；机器状态仍要求视觉复核，人工静态布局、层级、文字、无遮挡与无裁切 PASS。

## 剩余关闭门

- 文档引用/编码、diff、dirty/staged 和 metadata 最终边界检查。
- 精确 implementation commit 与提交后的 full head。
- commit/push 证据回填 validation/handoff；远端 CI 在实际成功前仍为 unproven。

## 未授权扩张

I1 不自动包含跨进程 active-run 恢复、完整经济/内容、最终美术/音频、完整人工长局、通用性能、设备矩阵、导出或发布。CI workflow 已配置，但远端成功前不是 proven capability。
