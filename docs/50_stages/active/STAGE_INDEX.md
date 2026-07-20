# Active Stage Index

文档状态：当前无已授权 active stage；I1 已关闭。
最后更新：2026-07-21

## 当前阶段

| Item | Current fact |
| --- | --- |
| Stage | NONE |
| Status | no authorized successor; I1 closed `PASS_WITH_NOTES` |
| Active repo | `git rev-parse --show-toplevel` |
| Observed branch | `codex/i1-baseline-stabilization` |
| Validated head | `492d74fcdc94cb75e47401c203defd49dac11ae9` |
| Latest closed non-art baseline | I1 |
| Latest closed art stage | ART21 |
| Later accepted page/UI evidence | ART23 |
| Failed historical art attempt | ART24R2 / 24 of 61 PASS |
| Local Godot observation | `E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe` |

## 已关闭的 I1 基线

把已有 playable program、UI/动画/资源和文档治理整理为统一的增量开发基线，使后续变更能够快速运行隔离自动化、生产场景预览和明确的人工复核。

## 已完成的关闭门

- static PASS：39 blocking / 46 inventory / 13 exclusions / 705 checks。
- preflight、quick 21/21、core 24/24、ui 23/23、full 39/39 worktree PASS，污染守卫 PASS。
- ART25 107 assets 来源、许可、manifest 与确定性门 PASS。
- 九状态 × 三分辨率 27/27 生产预览已生成；机器状态仍要求视觉复核，人工静态布局、层级、文字、无遮挡与无裁切 PASS。
- implementation commit `6a4f207d743583c7342655488c2d9a652b9ab05c` 与 newline safety fix `492d74fcdc94cb75e47401c203defd49dac11ae9` 已交付；最终提交态 full/head 39/39 PASS。
- 分支已推送到 `origin/codex/i1-baseline-stabilization`；GitHub Actions quick run `29760789712` 成功。

## 后继授权

当前没有自动授权的后继 G/ART/M/P/I 阶段。后续工作必须先建立范围、验收门和证据入口，并以 I1 contract、architecture、runbook、validation 与 handoff 为基线。

## 未授权扩张

I1 不自动包含跨进程 active-run 恢复、完整经济/内容、最终美术/音频、完整人工长局、通用性能、设备矩阵、导出或发布。远端 quick 成功也不证明 full、导出或 release。
