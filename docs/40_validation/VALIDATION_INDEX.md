# Validation Index

文档状态：I3 关闭验证入口；当前无 active stage。
最后更新：2026-07-23

## I3 收口证据

- 总契约：docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md
- 切片台账：docs/00_governance/I3_SLICE_GATE_LEDGER.md
- 用户反馈：docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md
- validation：docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md
- handoff：docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md
- Base 审计：docs/00_governance/I3_BASE_RETENTION_AND_DEDUP_AUDIT.md

最终 worktree full 为 75/75 PASS：42 个 runner 为纯 PASS，33 个为
PASS_WITH_CLEANUP_DIAGNOSTIC，blocking 为 0，时长 785952 ms。

    report: .tmp/i1/20260722T210300990Z_ed330093/report.json
    report_sha256: 5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D
    source_mode: worktree
    profile: full

首次 quick/full 失败、真实原因、补救与复验链只在 I3 validation 原文展开。

## 分类证据

| 范围 | 当前结果 | 解释边界 |
| --- | --- | --- |
| I3 定向 runner | PASS | 地图、搜索、HUD/输入、长期、战斗/结果与模态模型 |
| Production 公开输入 | 6/6 PASS | 三条 runner 各 headless/rendered；47 PNG、6 JSON/CSV |
| Base | PASS | 1041 files；25 planning；1407 members；1012 unique；395 aliases |
| 同机冻结 CPU workload | PASS_WITH_NOTES | enemy1 低基数残余保留；不等于设备 GPU/FPS |
| 人工可见检查 | PASS_WITH_NOTES | 17 张代表图无阻断问题；不等于最终审美/手感 |
| Cleanup | PASS_WITH_NOTES | 全量 33 个 runner 按 manifest 分类；六次 production 的 18-resource 子集仍可复现 |
| Worktree full | 75/75 PASS | 不替代 exact-head/full |
| Exact-head 与 push | 外部交付门 | 由最终交付记录写入真实 SHA；本文不预写 |

## 外部交付命令

提交后的最终对象使用：

    powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
      -File .\tools\i1\invoke_i1.ps1 `
      -Profile full `
      -SourceMode head `
      -GodotExe 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'

随后 push 并比较 git rev-parse HEAD 与远端分支 SHA。任一门失败都使 I3 关闭无效并重新
打开 I3.7。

## 历史与回归证据

| 证据 | 当前用法 |
| --- | --- |
| I2 validation/handoff | 前序闭合非美术基线，冻结历史 |
| I1 validation/handoff | 更早闭合非美术基线，冻结历史 |
| ART21 closeout/validation | 项目级最新闭合美术阶段 |
| ART23 validation | 较晚页面/UI 范围证据，不提升 art-stage authority |
| ART24R2 final Computer Use | 失败封存，24/61 PASS |
| G41/M6/M7 runners | 当前 full 的行为回归来源 |

## 声明规则

- 精确 PASS marker、exit code 和无 blocking diagnostic 才构成 runner PASS。
- cleanup diagnostic 必须保留分类，不能假装不存在。
- worktree PASS 不替代 exact-head PASS；head PASS 不替代 push/remote SHA。
- screenshot、headless、rendered、manual、performance、CI、export 和 release 分开声明。
- I3 是最新闭合非美术基线，但不自动授权任何 successor。
