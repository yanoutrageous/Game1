# Audit Entrypoint

文档状态：I3 已关闭，状态为 CLOSED / PASS_WITH_NOTES。最终关闭受外部交付门约束。
最后更新：2026-07-23

## 读取顺序

1. AGENTS.md
2. docs/50_stages/closed/STAGE_INDEX.md
3. docs/10_current/CURRENT_STATE.md
4. docs/validation/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md
5. docs/handoff/HANDOFF_I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION.md
6. docs/20_product/I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_CONTRACT.md
7. docs/00_governance/I3_SLICE_GATE_LEDGER.md
8. docs/00_governance/I3_USER_FEEDBACK_DISPOSITION_MATRIX.md
9. docs/10_current/AUDIT_SCOPE.md
10. docs/10_current/NEXT_ACTION.md

## 当前权威

    active_repo: git rev-parse --show-toplevel
    observed_branch: codex/i3-player-experience-calibration
    i3_entry_head: 09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
    i3_entry_tree: a077da34237dce5e4a6081d833efd939098b4641
    stage: I3 / CLOSED / PASS_WITH_NOTES
    active_stage: NONE
    latest_closed_non_art_baseline: I3
    latest_closed_art_stage: ART21
    later_scoped_page_ui_evidence: ART23
    successor_authorization: NONE

路径必须由 Git 动态解析；上面的分支是本机关闭时观测，不是跨机器路径选择规则。
Godot 是唯一生产实现目标，UE/Lua/旧原型只保留有边界的参考意义。

## 关闭证据

- I3.0–I3.7 属于同一阶段，范围、实现、定向验收和完成审计见 I3 切片台账。
- 最终 worktree full 为 75/75 PASS；报告位于忽略目录
  .tmp/i1/20260722T210300990Z_ed330093/report.json，SHA-256 为
  5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D。
- 真实生产输入、渲染检查、Base 完整性、去重、性能分布、保护路径和残余风险见 I3
  validation 与 handoff 原文。首次 quick/full 失败、补救和复验链也只在 validation
  原文中展开，导航不重复长表。

## 外部交付条件

I3 的关闭只有在同一候选提交通过 exact-head/full，随后 push 且远端分支 SHA 与本地
一致时才有效。这两项由最终交付记录提供；本文不预写未知提交 SHA。任一项失败都使
本次关闭声明无效，必须重新打开 I3.7 修复和复验。

## 声明边界

- I3 是最新闭合非美术基线；ART21 仍是项目级最新闭合美术阶段，ART23 仍只是较晚的
  页面/UI 范围证据。
- 当前无 active stage，也未自动授权 I4、ART22 或其他后继阶段。
- Deploy 地图继续属于出发探索同页双栏，禁止回退为区域到难度的分步页面。
- Base 入库不等于 runtime admission；原始策划案保持原名、原字节和完整信息。
- 47 张渲染证据不构成最终审美、动画/音频手感或设备性能验收。
- full 门的 33 个 cleanup runner 具有 manifest 精确分类的资源残留；六次 I3 production 均为 18-resource 子集。诊断必须保留，不能写成 cleanup clean。
