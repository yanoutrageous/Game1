# Validation Docs

文档状态：阶段验证原文入口。
最后更新：2026-07-23

最新闭合验证为 I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md，状态
CLOSED / PASS_WITH_NOTES。当前无 active stage，I3 关闭不自动授权新阶段。

## I3 证据口径

- I3.0–I3.7 是同一阶段；切片审计、实现、定向门、生产旅程、Base 与完成审计均在
  validation、handoff 和切片台账中登记。
- 最终 worktree full 为 75/75 PASS；42 个 runner 为纯 PASS，33 个为
  PASS_WITH_CLEANUP_DIAGNOSTIC，blocking 为 0。
- 报告位于忽略目录 .tmp/i1/20260722T210300990Z_ed330093/report.json，SHA-256 为
  5E07C1FDA64391738ABAC8ABDFA2E71AFE398F88EF1C4DF0F567FECEF710D34D，时长
  785952 ms。
- 三条 production runner 各自 headless/rendered PASS，形成 47 张 PNG 与 6 组
  JSON/CSV；它们证明真实输入路线和可见信息闭环，不等于最终美术或手感验收。
- Base committed verify 覆盖 1041 个仓库文件、25 份原始策划、1407 个 art/draw
  member、1012 个唯一对象和 395 个 alias。
- enemy1 低基数性能残余、目标设备 GPU/FPS 未验收以及退出 cleanup
  生命周期诊断均保留为 notes；六次 production 为 18-resource 子集，全量以 manifest 分类为准。

首次 quick/full 失败、真实原因、补救与复验链见
I3_PLAYER_PERCEPTION_AND_BASELINE_CALIBRATION_VALIDATION.md；导航不重复长表。

## 外部交付门

同一候选提交仍必须通过 exact-head/full，并 push 到远端且验证远端分支 SHA 与本地
一致。最终交付记录负责提供真实提交 SHA；本文不预写未知值。任一门失败时，I3 的关闭
无效，必须重新打开 I3.7。

## 历史证据口径

- I2 validation：前序闭合非美术基线，CLOSED / PASS_WITH_NOTES。
- I1 validation：更早闭合非美术基线；其提交态 full/head 与 Actions quick 保持历史。
- ART21 closeout/validation：项目级最新闭合美术阶段。
- ART23 validation：较晚的页面/UI 范围证据，不提升项目级美术阶段权威。
- ART24R2 final Computer Use：FAIL / 24 of 61 PASS，保持失败封存。

## 使用规则

1. 新 validation 直接落位 docs/validation/，至少提供中文摘要。
2. 旧 validation 不改写为当前事实；索引标注 superseded、historical 或 failed。
3. gameplay runtime、manual、visual、performance、CI、export 与 release 分别声明。
4. capture 生成不等于视觉 PASS；worktree PASS 不等于 exact-head PASS。
5. cleanup diagnostic 必须精确登记，不能因总门通过而隐藏。
6. closed validation 不自动授权 successor。
