# Handoff Docs

文档状态：阶段交接原文入口。
最后更新：2026-07-20

当前活动交接：`HANDOFF_I1_INCREMENTAL_DEVELOPMENT_BASELINE.md`，状态 `DRAFT_WORKTREE_ACCEPTED_HEAD_PENDING`。

本目录保存阶段 handoff 原文。新 handoff 直接落位于本目录，不复制到 docs 根目录；旧 handoff 保持历史时间点，不因 current chain 更新而重写。

## 当前证据口径

- I0 handoff：上一闭合非美术基线，并永久保留其有限可见覆盖和安全不符合记录。
- ART21：项目级上一闭合美术阶段。
- ART23 handoff：较晚页面/UI 证据切片，可作回归材料，但不替代 ART21 stage authority。
- ART24R2 handoff：失败验收封存，不作为合格美术基线。
- I1 handoff：worktree acceptance 已记录；full committed HEAD、commit/push 和最终 Git 证据完成前不得改成 CLOSED。

## 使用规则

```text
1. 新 handoff 命名使用 HANDOFF_<stage>_<topic>.md，并至少提供中文摘要。
2. 旧 handoff 通过 INDEX / STAGE_INDEX 标注状态，不改写正文。
3. handoff 只交接已验证范围，不自动授权下一阶段。
4. pending handoff 不能作为完成或发布声明。
```
