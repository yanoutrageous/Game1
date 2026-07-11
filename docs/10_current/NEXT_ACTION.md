# Next Action

文档状态：当前下一步
最后更新：2026-07-11（I0.7 closeout）

## 当前授权状态

I0 已关闭，当前没有已授权的 active stage。不得自动继续代码重构、可见 Godot 启动、远端操作、CI 接入或产品内容开发；下一阶段需要用户单独批准。

## 建议的下一阶段候选

建议按独立门逐项批准，而不是一次性展开：

1. **可见启动安全门**：先证明 Godot 编辑器与游戏日志都隔离在 `D:\AGAME1`，再恢复任何可见验收。
2. **最小 CI / release gate**：复用 I0 的隔离套件、编码门和污染守卫，增加导出制品校验。
3. **Persistence 可靠性**：真实 save / profile 文件往返、失败恢复、版本迁移和异常路径。
4. **继续缩小 `RunScene`**：一次只迁移一个有特征测试与快照保护的职责。
5. **MVP 内容闭环**：目标—奖励—局外成长、引导、内容量与难度曲线。
6. **独立视觉 / 性能 / 兼容性门**：分辨率、输入设备、帧时间和最终可读性。

## 必须继承的基线

- 活动仓库：`D:\AGAME1\active\Game1_work`。
- 固定 Godot：`D:\AGAME1\tools\runtimes\godot\4.6.3`。
- 自动化入口：`tools/i0/invoke_i0_tests.ps1 -Profile remediated`。
- 最终 I0 validation：`docs/validation/I0_PROJECT_BASELINE_REFACTOR_VALIDATION.md`。
- 最终 I0 handoff：`docs/handoff/HANDOFF_I0_PROJECT_BASELINE_REFACTOR.md`。
- 原始 12 项 dirty 和保护性 stash 继续由用户决定归属。
- 在可见日志隔离门通过前，不直接启动可见 Godot。

## 声明边界

I0 的 12/12 runner、有限可见烟测和阶段关闭不等于完整人工游玩、最终视觉、性能、CI 或发布 PASS。I0.7 的范围外日志写入是永久保留的安全不符合记录，不能因业务文件已恢复而省略。
