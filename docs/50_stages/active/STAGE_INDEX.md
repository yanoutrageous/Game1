# Active Stage Index

文档状态：I3R ACTIVE。
最后更新：2026-07-27

## 当前阶段

| Item | Current fact |
| --- | --- |
| Active stage | I3R / ACTIVE / EXTERNAL_ACCEPTANCE_PENDING |
| Latest effective closed non-art baseline | I2 / CLOSED / PASS_WITH_NOTES |
| Latest closed art stage | ART21 |
| Later accepted page/UI evidence | ART23 / scoped only |
| Successor authorization | 用户已明确授权 I3R |

I3 保留条件式 closeout 历史，其对象为
`09aaafe283aa2e4c2f30708c5f88b89ebf7753eb` /
tree `a077da34237dce5e4a6081d833efd939098b4641`。I3R 的 entry/base 为
`35189aaf524157761d1ab9cdddc39e76baa0d7ca` /
tree `82f100059add24ecb2c12e7fca0bfb17f3a95c50`。I3 的 worktree/full 已通过，
但 exact-head/full 和 push/remote-SHA 生效门未完成，因此不替代 I2 的闭合基线
authority。I3R 处理玩家运行反馈证伪、I3 未覆盖和被降级为 note 的体验问题；
它不是 I4，也不改写 I3 原始验证。

## I3R 边界

- 教程是 Deploy 地图 catalog 中的 `tutorial_5x5` 模式并进入 `standard_run`，
  不建立独立生产入口或独立运行接口。
- 地图继续属于出发探索同页双栏。
- I3R.0–I3R.8 全部通过后才能整体关闭。

## 历史限制

- I3R 授权不自动授权 I4、ART22 或其他后继阶段。
- ART21 仍是项目级最新闭合美术阶段；ART23 和 I3 UI 改动不提升 art-stage authority。
- I3R 之外的后续工作仍需另行授权。

## 当前入口

1. docs/10_current/CURRENT_STATE.md
2. docs/10_current/NEXT_ACTION.md
3. docs/20_product/I3R_PLAYER_EXPERIENCE_REWORK_CONTRACT.md
4. docs/00_governance/I3R_EXECUTION_LEDGER.md
5. docs/00_governance/I3R_REQUIREMENT_MATRIX.md
6. docs/40_validation/VALIDATION_INDEX.md
7. tools/i3r/README.md
8. docs/50_stages/closed/STAGE_INDEX.md

I3 的 validation/handoff 继续作为冻结历史证据：

- docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md
- docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md

## 当前正式证据

| Gate | Result | Evidence |
| --- | --- | --- |
| Worktree quick | `PASS` | `.tmp/i1/20260724T081049594Z_48c9c715/report.json` |
| Historical production state gallery | `11/11 / PASS_WITH_VISUAL_REVIEW_REQUIRED` | `.tmp/i1/20260724T081913076Z_117ed89a/i3r_production_state_gallery/manifest.json` |
| Final production state gallery | `12/12 / PASS_WITH_VISUAL_REVIEW_REQUIRED / Codex static review complete` | `.tmp/i1/20260726T174413001Z_03839547/i3r_production_state_gallery/wrapper_report.json`；manifest 同目录；不代替设备或玩家签收 |
| Current I3R.4 standard production journey | `20/20 / PASS` | `.tmp/i3r4_final_standard_rendered_20260726`；137 inputs；满包 13 screenshots/222 inputs 与终局 15 screenshots/129 inputs 另见 Validation Index |
| Current I3R.5 out-of-run production journey | `22/22 / PASS_WITH_EXTERNAL_BOUNDARY` | `.tmp/i3r5_out_of_run_rendered_20260726`；22 checkpoints、22 PNG、36 parsed inputs；范围化 Codex 视觉复核完成，不替代设备或玩家签收 |
| Current I3R.6 tutorial/map combined suite | `PASS_WITH_EXTERNAL_BOUNDARY` | `.tmp/i3r6_final_combined_20260726` 与 `.tmp/i3r6_popup_fix/visual/capture.png`；首通/重播、四类事件、地图直接操作、可关闭非阻塞提示和 6 组响应式布局 PASS |
| I3R.7 Base governance | `PASS` | 1012 Base objects；178 crosswalk rows / 175 runtime paths / 149 runtime SHA；47 direct + 108 dynamic + 6 staging-no-consumer + 17 no-production-consumer；1 promotion；2 open alias-debt groups |
| I3R.7 current long-term governance and final matrix | `PASS / 125/125 / Codex static review complete` | `tools/i3r/validate_i3r_long_term_current.ps1`：6 modules / 25 pages / 58 runtime assets / `gacha_runtime=0` / dedicated talent furniture；`.tmp/i1/20260726T173939443Z_6d8ac659/i3r_long_term_matrix/matrix_manifest.json`；历史 ART23 6×27/58 保持冻结 |
| Final production preview matrix | `132/132 / PASS_WITH_VISUAL_REVIEW_REQUIRED / Codex static review complete` | `.tmp/i1/20260726T171343894Z_6892a1f1/i3r_preview_matrix/matrix_manifest.json` |
| Canonical implementation full | `89/89 PASS` | `.tmp/i1/20260724T133447862Z_f32e4b02/report.json`；52 plain、37 cleanup runner、74 cleanup diagnostic、0 blocking、833956 ms；manifest `8D7DE29F024C7EDD23A7C851D1A1DEA35ED0292E257712D97127D8CCFB264811`，report `AB793F0920D88CB4BBE530A5BEFF30748E9D5ABCCF2C25959560CA061715C0EC`，source worktree/head `35189aaf524157761d1ab9cdddc39e76baa0d7ca`，business 2302 / fingerprint `B85932E120CFD1EEF785ABD7408B753EFA6BF5BEF16C4F41EAC38525D908A60B` |
| Final worktree full | `96/96 PASS` | `.tmp/i1/20260726T171400780Z_6f66cb6f/report.json`；53 plain、43 cleanup-diagnostic、0 hard failure、1053141 ms；manifest `11B32B377A244B9DDF98637020CC9F263ABCDEB488472FA624F11F5A0A575406`；report `3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4` |
| Historical space-governance checkpoint | `PASS / SUPERSEDED AS CURRENT SIZE` | 旧事务 81 snapshots、index `64BEC2C6…811E`、proof `C04B7630…3903`、`7.4064 GiB / 51163 files`；只绑定当时时点 |
| Current physical space reclose | `PASS` | 123 snapshots（I3R 60）、6489 CAS objects、final-full V2 restore PASS、本轮 38/38 镜像事务裁剪、worktree/tombstone 0；当前 `E:\AGAME1` 为 `9.1937 GiB / 56331 files` |
| Final worktree full / current matrices / static visual review | `PASS_WITH_EXTERNAL_BOUNDARY` | 96/96 full + 132/132 preview + 125/125 long-term + 12/12 gallery；269/269 Codex 静态复核通过；文档终态回写由静态/治理检查单独覆盖 |
| Exact-head/full | `PENDING` | 必须在候选提交上执行 |
| 真实设备与玩家签收 | `PENDING` | 目标设备、控制器/音频、长局、动态观感与玩家体验尚未签收 |

上述 quick、最终 full 与渲染产物均不构成 I3R 关闭。
`PASS_WITH_VISUAL_REVIEW_REQUIRED` 只说明机器生成及清单门通过，仍需人工视觉裁决。
I3R 还必须通过 exact-head、真实设备、目标 GPU、动态玩家视觉与外部交付门。
