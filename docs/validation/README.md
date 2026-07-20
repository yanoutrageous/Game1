# Validation Docs

文档状态：阶段验证原文入口。
最后更新：2026-07-20

当前活动验证：`I1_INCREMENTAL_DEVELOPMENT_BASELINE_VALIDATION.md`，状态 `WORKTREE_ACCEPTANCE_PASS_HEAD_PENDING`。

本目录保存阶段验证原文。验证记录只证明明确覆盖的范围；static、headless、capture、manual、performance、CI、export 和 release 证据分别声明。

## 当前证据口径

- I0 validation：上一闭合非美术基线，冻结历史。
- ART21 closeout/validation：项目级上一闭合美术阶段。
- ART23 validation：较晚且已验收的页面/UI 证据切片，不提升项目级 stage authority。
- ART24R2 final Computer Use：`FAIL / 24 of 61 PASS`，保持失败封存。
- I1 validation：full worktree 39/39、ART25 与 27/27 预览静态图片复核已通过；full committed HEAD、commit/push 与最终 Git/metadata 证据完成后才能关闭。

## 使用规则

```text
1. 新 validation 直接落位 docs/validation/，至少提供中文摘要。
2. 旧 validation 不改写为当前事实；索引负责标注 superseded / historical / failed。
3. gameplay runtime PASS 和 manual playtest PASS 必须有对应实际证据。
4. preview/capture 生成不等于视觉 PASS。
5. worktree PASS 不等于 committed HEAD PASS。
6. 未运行的性能、CI、导出或发布不得声明通过。
```
