# Validation Index

文档状态：当前验证索引
最后更新：2026-07-11（I0.6）

## 当前入口

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/i0/invoke_i0_tests.ps1 -Profile remediated
```

当前 Godot 工具链必须来自 `D:\AGAME1\tools\runtimes\godot\4.6.3`。套件在 `D:\AGAME1\tools\runtimes\.tmp\i0` 建立隔离镜像和用户目录，并比较执行前后 Git 与业务文件指纹。

文档编码门独立执行：

```powershell
powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/i0/validate_document_encoding.ps1
```

## I0 当前结果

| 验证 | 当前结果 | 边界 |
| --- | --- | --- |
| 工具链 | PASS_WITH_RECORDED_LIMITATION | 版本 / 哈希通过；本机证书链 untrusted root 已记录 |
| 文档编码与清单 | PASS_WITH_RECORDED_LIMITATION | 已接入主套件；376 文本、428 图片 magic、5 个精确历史例外、0 新异常 |
| 静态契约 | PASS | 四个基线缺陷与 runner inventory 均通过 |
| Godot runners | 12/12 PASS_WITH_CLEANUP_DIAGNOSTIC | 0 blocking；24 个退出清理提示 |
| RunScene 快照 | 5/5 identical | I0.4 前后及两次迁移后逐字一致 |
| 污染守卫 | PASS | Git、stash、refs、index 和业务指纹未改变 |
| I0.5 原子迁移 | PASS_WITH_FOLLOWUPS | 同卷原子移动；followups 在 I0.6 收口 |
| ART-13 | PASS_WITH_28_WARNINGS | warning 包含原始 dirty 与词语复核项 |
| ART-14 | EXPECTED_FAIL_ON_PROTECTED_DIRTY_STATE | 5 error 均由原始 dirty 精确解释，非回归 |
| 可见 Godot 烟测 | pending | I0.7 |
| 人工游玩检查 | pending | I0.7 |
| 发布 / CI | not_run | 不得声称 PASS |

迁移后重复报告：

- `D:\AGAME1\reports\i0\I0.2_20260711T044908553Z_9d24aba9.json`
- `D:\AGAME1\reports\i0\I0.2_20260711T045314232Z_7792d2cf.json`

最终原文：`docs/validation/I0_PROJECT_BASELINE_REFACTOR_VALIDATION.md`（I0.7 定稿）。

## 声明边界

- `PASS_WITH_NOTES` 不是纯 PASS。
- headless / runner PASS 只证明其测试契约，不等于完整 gameplay runtime PASS。
- 可见 smoke 不等于完整人工 playtest。
- 人工 playtest 不自动等于最终视觉、性能、发布或 CI PASS。
- 历史 validation / handoff 原文继续保留在原目录，不因当前索引而扩大结论。
