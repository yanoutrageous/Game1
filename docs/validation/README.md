# Validation Docs

当前程序阶段验证：`M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION.md`。历史验证保留，但其中与 M6 冲突的自动出勤、消耗品返还/保全和放弃资源待定语义不再是当前规则。

文档状态：阶段验证原文入口
适用范围：`docs/validation` 下阶段验证记录
最后更新：2026-07-18

本目录保存阶段验证原文。验证记录只证明其明确验证范围，不扩大为玩法通过或手测通过。

当前美术阶段封存验证：`ART24R2_FINAL_COMPUTER_USE_RESULTS.md`（`FAIL / 24 of 61 PASS`）。合格美术基线仍为 `ART23_LONG_TERM_FINAL_UI_VALIDATION.md`。I0 + ART21 整合验证继续作为工程基线记录。

## 使用规则

```text
1. 新 validation 命名建议：Gxx_主题_VALIDATION.md。
2. 新 validation 至少提供中文摘要。
3. gameplay runtime PASS 和 manual playtest PASS 必须有对应实际验证记录，否则不得声明。
4. parser/headless smoke 不等于 gameplay runtime PASS 或 manual playtest PASS。
```
