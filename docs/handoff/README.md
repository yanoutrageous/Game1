# Handoff Docs

文档状态：阶段交接原文入口。
最后更新：2026-07-22

最新闭合交接：`HANDOFF_I2_PLAYER_EXPERIENCE_REFACTOR.md`，状态 `CLOSED_PASS_WITH_NOTES`。当前无 active stage，I2 关闭不自动授权新阶段。

本目录保存阶段 handoff 原文。新 handoff 直接落位于本目录，不复制到 docs 根目录；旧 handoff 保持历史时间点，不因 current chain 更新而重写。

## 当前证据口径

- I2 handoff：最新闭合非美术基线。39/39 production capture 仅为静态人工检查；性能仅表明可比本机负载未见系统性相对回退。
- I1 handoff：前序闭合非美术基线，记录提交态 full/head、Git 交付与 quick CI 证据，并保留 notes 与排除项。
- I0 handoff：更早闭合非美术基线，并永久保留其有限可见覆盖和安全不符合记录。
- ART21：项目级最新闭合美术阶段。
- ART23 handoff：较晚页面/UI 证据切片，可作回归材料，但不替代 ART21 stage authority。
- ART24R2 handoff：失败验收封存，不作为合格美术基线。

## 使用规则

```text
1. 新 handoff 命名使用 HANDOFF_<stage>_<topic>.md，并至少提供中文摘要。
2. 旧 handoff 通过 INDEX / STAGE_INDEX 标注状态，不改写正文。
3. handoff 只交接已验证范围，不自动授权下一阶段。
4. pending handoff 不能作为完成或发布声明。
```

I2 仍未验收最终审美、音频、动态交互手感、长局、设备矩阵、CI full、导出与发布；handoff 不得把这些未覆盖项转化为后续自动授权。
