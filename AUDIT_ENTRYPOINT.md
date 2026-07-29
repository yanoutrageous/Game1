# Audit Entrypoint

文档状态：I4 是当前 `ACTIVE` 阶段；I3R 保留为被接管前的历史机器证据。
最后更新：2026-07-30

## 读取顺序

1. AGENTS.md
2. docs/50_stages/active/STAGE_INDEX.md
3. docs/10_current/CURRENT_STATE.md
4. docs/10_current/NEXT_ACTION.md
5. docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md
6. docs/00_governance/I4_EXECUTION_LEDGER.md
7. docs/00_governance/I4_REQUIREMENT_MATRIX.md
8. docs/40_validation/VALIDATION_INDEX.md
9. tools/i4/README.md
10. docs/50_stages/closed/STAGE_INDEX.md

## 当前权威

    active_repo: git rev-parse --show-toplevel
    observed_branch: codex/i4-production-interaction-convergence
    active_stage: I4 / ACTIVE / PLAN_AUDIT
    latest_closed_non_art_baseline: I2
    historical_i3_entry: 09aaafe283aa2e4c2f30708c5f88b89ebf7753eb
    i3r_implementation_entry: 35189aaf524157761d1ab9cdddc39e76baa0d7ca
    latest_closed_art_stage: ART21
    later_scoped_page_ui_evidence: ART23
    i4_entry: 4127bd27a05b75cb5e3071cf6dc87d9287f679a9
    successor_authorization: USER_AUTHORIZED_I4_FULL_PROCESS_AND_PUSH

路径必须由 Git 动态解析；上面的分支是本机当前工作快照观测，不是跨机器路径选择规则。
Godot 是唯一生产实现目标，UE/Lua/旧原型只保留有边界的参考意义。

## I3R 继承验证状态

- 最终工作树 full：96/96 PASS（53 plain、43 cleanup-diagnostic、0 hard failure），
  报告 `.tmp/i1/20260726T171400780Z_6f66cb6f/report.json`，SHA-256 为
  `3CDF02791EC61CD580B78489A4C5B2581EF7E974AADEEA897AF06FEBD1494BC4`。
- 最终 production preview 132/132、long-term 125/125、state gallery 12/12；
  269/269 张静态图完成 Codex 复核。
- exact-head 与 Git 远端一致性由最终交付结果提供；真实设备/控制器/音频、目标 GPU
  长局和动态玩家/视觉签收仍为 pending，上述自动证据不构成 I3R 关闭。

## I3 冻结历史证据

- I3 历史入口提交为 `09aaafe283aa2e4c2f30708c5f88b89ebf7753eb`；不得把
  `35189aaf524157761d1ab9cdddc39e76baa0d7ca` 重新标成 I3 当前入口。
- I3.0–I3.7 的历史范围、实现、定向验收和当时审计见 I3 切片台账；这些材料不把
  I3 提升为当前闭合基线，最新闭合非美术基线仍为 I2。
- 历史 worktree full 为 75/75 PASS；报告位于忽略目录
  .tmp/i1/20260722T210300990Z_ed330093/report.json，SHA-256 为
  5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D。
- 真实生产输入、渲染检查、Base 完整性、去重、性能分布、保护路径和残余风险见 I3
  validation 与 handoff 原文。首次 quick/full 失败、补救和复验链也只在 validation
  原文中展开，导航不重复长表。

## I4 外部交付条件

I4 只有在同一候选提交通过 exact-head/full，随后 push 且远端分支 SHA 与本地一致，
并完成契约要求的生产、设备与玩家签收时才具备关闭条件。这些结果由最终交付记录提供；worktree
full 不能替代该门，本文不预写未知提交 SHA。
用户已于 2026-07-27 授权 commit、push 与 main 快进合并；最终远端 SHA 仍须由实际
交付结果核对，Git 交付本身不替代外部设备与玩家签收。

## 声明边界

- I3 仅作为已冻结历史入口保留；ART21 仍是项目级最新闭合美术阶段，ART23 仍只是
  较晚的页面/UI 范围证据。
- I4 是当前 active stage；I4 授权不自动授权新内容、新美术阶段、发布或其他后继阶段。
- Deploy 地图继续属于出发探索同页双栏，禁止回退为区域到难度的分步页面。
- Base 入库不等于 runtime admission；原始策划案保持原名、原字节和完整信息。
- 47 张渲染证据不构成最终审美、动画/音频手感或设备性能验收。
- full 门的 33 个 cleanup runner 具有 manifest 精确分类的资源残留；六次 I3 production 均为 18-resource 子集。诊断必须保留，不能写成 cleanup clean。
