# Next Action

文档状态：I3R 活动返工的验证与交付入口。
最后更新：2026-07-27

## 当前状态

    latest_closed_non_art_baseline: I2 / CLOSED / PASS_WITH_NOTES
    latest_closed_art_stage: ART21
    later_scoped_page_ui_evidence: ART23
    active_stage: I3R / ACTIVE / EXTERNAL_ACCEPTANCE_PENDING
    successor_authorization: USER_AUTHORIZED_I3R
    delivery_branch: codex/i3r-player-experience-rework
    storage_governance: CURRENT_PASS / 123 archived / 60 I3R / 0 live snapshot worktrees / 0 tombstones
    production_input_journey: PASS / rendered / 20 checkpoints / 20 screenshots
    production_state_gallery: final PASS_WITH_VISUAL_REVIEW_REQUIRED / 12 of 12 generated
    preview_matrix: final PASS_WITH_VISUAL_REVIEW_REQUIRED / 132 of 132 generated
    long_term_matrix: final PASS_WITH_VISUAL_REVIEW_REQUIRED / 125 of 125 generated
    codex_visual_review: 269 of 269 static images PASS / dynamic player signoff pending
    worktree_quick: PASS / 67 of 67
    final_worktree_full: PASS / 96 of 96 / 53 plain / 43 cleanup-diagnostic / 0 hard failures

I3 保持关闭历史；I3R 是用户明确授权的返工阶段，不是 I4，也不提升 ART21 的项目级
美术阶段权威。教程只通过“出发探索 → 地图 → tutorial_5x5 → 普通确认出发”进入，
不存在独立生产教程接口。

## 当前执行顺序

1. I3R.0–I3R.6 的实现、定向门和当前生产旅程已经按顺序完成；不得用任何单项 PASS
   代替最终 full、矩阵或外部门。
2. I3R.7 已完成 Base 消费者反自证、语义/生命周期分离、跨语义小地图 alias 债务，
   并把当前长期系统的 6 模块/25 页面与历史 ART23 的 6×27 冻结证据分流。
3. I3R.8 的最终工作树 full、132 例生产预览、125 例长期系统、12 例状态画廊、
   269/269 静态视觉复核和物理空间收口均已完成。
4. 用户已授权候选提交 exact-head/full、push、main 快进合并与远端 SHA 核对；结果
   由最终交付记录提供。阶段下一步仍是真实动态试玩验收；真实键鼠/手柄、目标 GPU
   长局和人工玩家签收继续独立 pending。交付如产生验证镜像，按 archive → verify →
   V2 restore → transaction prune 清理。

已完成的当前 worktree 证据：

- quick：`.tmp/i1/20260724T081049594Z_48c9c715/report.json`，67/67 PASS；
- 最终状态画廊：
  `.tmp/i1/20260726T174413001Z_03839547/i3r_production_state_gallery/wrapper_report.json`，
  12/12 生成；
- 最终生产预览矩阵：
  `.tmp/i1/20260726T171343894Z_6892a1f1/i3r_preview_matrix/matrix_manifest.json`，
  132/132 生成；最终长期系统矩阵：
  `.tmp/i1/20260726T173939443Z_6d8ac659/i3r_long_term_matrix/matrix_manifest.json`，
  125/125 生成；两者的预检、捕获期污染与镜像一致性均 PASS；
- I3R.5 局外生产旅程：`.tmp/i3r5_out_of_run_rendered_20260726`，
  22 checkpoint/22 PNG/36 次解析输入；
- I3R.6 教程合并套件：`.tmp/i3r6_final_combined_20260726`；首通/重播、四类事件、
  地图直接操作、非阻塞提示和 6 组响应式布局均 PASS；
- I3R.7 当前治理入口：Base 1012 对象/178 crosswalk 行，消费者证明
  `47 direct + 108 dynamic + 6 staging-no-consumer + 17 no-production-consumer`；
  当前长期系统 `6 modules / 25 pages / 58 runtime assets / gacha_runtime=0`；
- final worktree full：
  `.tmp/i1/20260726T171400780Z_6f66cb6f/report.json`，96/96 PASS，53 个纯 PASS、
  43 个 cleanup-diagnostic runner、0 个 hard failure，时长 1053141 ms。

状态画廊、生产预览和长期系统矩阵的自动状态均为
`PASS_WITH_VISUAL_REVIEW_REQUIRED`。Codex 已检查 132+125+12=269 张最终静态图；
这不替代用户的动态玩家体验与真实设备签收。

final worktree full 的 manifest SHA-256 为
`11B32B377A244B9DDF98637020CC9F263ABCDEB488472FA624F11F5A0A575406`，
report SHA-256 为
`3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4`，
业务文件数为 2333，业务指纹为
`E7ACAA39576A6DFEEB8B22EA18C41B0914A008F84F33348637183B1541C25A1F`。
其后只回写治理文档与空间终态，不修改 Godot/tools 业务内容；回写由最终静态与治理
检查单独复核。

## 空间治理终态

- 当前归档为 123 snapshots（I3R 60）与 6489 个 CAS 对象/735449033 bytes；
  index SHA-256 为
  `16974A206B007F737CB4CC45163720F3D10AF1170A657EC1DD477B26DE61AEAE`。
- final-full 快照 V2 独立恢复、两次树校验和副本移除 PASS；最终 verifier proof 为
  `A9B1286576B9E877642F9B2D0FACC7FE90F22C06D40C14856A1C7C7D97A377C4`。
- 本轮 38/38 快照工作树完成事务裁剪，worktree/tombstone 均为 0；76 个瞬态目标与
  752427027-byte 孤立 staging 已清理，事故取证目录保留。
- 当前 `E:\AGAME1` 为 `9.1937 GiB / 56331 files`，E 盘可用
  `112984649728 bytes / 105.2252 GiB`。

原始 `sources.zip`、Base、原始策划案与运行时素材均已保留，不视为缓存。阶段 Git
worktree 也不属于快照缓存：I2 含修改，I3/I3-baseline 虽可重建但可能绑定历史任务，
均未删除。以后最多保留一个活动验证镜像，新增证据继续执行
`archive → verify → V2 restore → transaction prune`，禁止通配或手工删除。

## 仍需外部或人工完成的关闭门

- 目标 GPU/FPS 与长局稳定性；
- 真实控制器、音频设备和减少动态模式；
- 完整键鼠/手柄玩家体验与逐图视觉签收；
- exact-head/full 与 Git 远端一致性证明由本次最终交付记录提供。

用户已于 2026-07-27 授权 commit、push 与 main 快进合并；本文不预写尚未生成的
提交 SHA。不得把 worktree PASS、Git 交付或 `PASS_WITH_VISUAL_REVIEW_REQUIRED`
改写为阶段关闭。外部玩家与设备门未完成前，I3R 保持 `ACTIVE`。

## 边界

- 不自动启动 I4、ART22 或其他后继阶段。
- Deploy 地图保持出发探索同页双栏；不回退到独立区域/难度页面。
- Base 原始策划案保持原名、原字节与原 SHA；Base 素材按内容 SHA 去重并通过显式
  runtime admission，不能被运行时直接扫描。
- 原始 `sources.zip`、Base 原始策划案和 Base 素材是基线来源，不是缓存；空间清理
  不得删除或以生成物替代它们。
- Godot 的生产代码、玩家可见内容和当前 runner 事实优先于早期文档。

详细范围、成功标准和证据入口见：

- `docs/20_product/I3R_PLAYER_EXPERIENCE_REWORK_CONTRACT.md`
- `docs/00_governance/I3R_EXECUTION_LEDGER.md`
- `docs/00_governance/I3R_REQUIREMENT_MATRIX.md`
- `tools/i3r/README.md`
