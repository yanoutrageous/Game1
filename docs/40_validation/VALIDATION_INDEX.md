# Validation Index

文档状态：当前验证索引
最后更新：2026-07-11（I0.7 closeout）

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
| 文档编码与清单 | PASS_WITH_RECORDED_LIMITATION | closeout tree：805 inventory、377 文本、428 图片 magic、5 个精确历史例外、0 新异常 |
| 静态契约 | PASS | 四个基线缺陷与 runner inventory 均通过 |
| Godot runners | 12/12 PASS_WITH_CLEANUP_DIAGNOSTIC | 0 blocking；24 个退出清理提示 |
| RunScene 快照 | 5/5 identical | I0.4 前后及两次迁移后逐字一致 |
| 污染守卫 | PASS | Git、stash、refs、index 和业务指纹未改变 |
| I0.5 原子迁移 | PASS_WITH_FOLLOWUPS | 同卷原子移动；followups 在 I0.6 收口 |
| ART-13 | PASS_WITH_28_WARNINGS | warning 包含原始 dirty 与词语复核项 |
| ART-14 | EXPECTED_FAIL_ON_PROTECTED_DIRTY_STATE | 5 error 均由原始 dirty 精确解释，非回归 |
| 可见 Godot 烟测 | PASS_WITH_NOTES / LIMITED_COVERAGE | main menu → deploy prep → run HUD；M / Q / G / T 响应；无持久化截图 |
| 人工游玩检查 | LIMITED_COVERAGE / FULL_PASS_NOT_CLAIMED | 移动、撤离完成、结算、返回未观察 |
| 可见启动安全边界 | NONCONFORMING_RECORDED | AppData logs 新增 / 改写；业务路径已恢复，外部日志未修改或删除 |
| 发布 / CI | not_run | 不得声称 PASS |

恢复后的最终 implementation acceptance：

- `D:\AGAME1\reports\i0\I0.2_20260711T064535471Z_5b55f8c8.json`
- SHA256：`6868337E7E51DB03BA083725914165D6D7456F017252823C866939CF4B98782F`
- validated implementation head：`d34f869e85993704ca4091b26f9e40a39795c860`
- 12/12、0 blocking、24 cleanup、business `656 / A3440342...D0928`、pollution PASS。

最终原文：`docs/validation/I0_PROJECT_BASELINE_REFACTOR_VALIDATION.md`。最终交接：`docs/handoff/HANDOFF_I0_PROJECT_BASELINE_REFACTOR.md`。

## 声明边界

- `PASS_WITH_NOTES` 不是纯 PASS。
- headless / runner PASS 只证明其测试契约，不等于完整 gameplay runtime PASS。
- 可见 smoke 不等于完整人工 playtest。
- 人工 playtest 不自动等于最终视觉、性能、发布或 CI PASS。
- 阶段 CLOSED 不抹除 `SAFETY_NONCONFORMANCE`，也不等于 overall PASS。
- 历史 validation / handoff 原文继续保留在原目录，不因当前索引而扩大结论。
