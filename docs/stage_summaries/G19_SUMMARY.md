# G19 阶段总结

## 阶段目标

G19 目标是 LongTermShell Foundation：在 AppShell 长期系统 route 上替换旧 placeholder，新增六模块长期系统 shell、placeholder/preview/disabled state 和 display-only interface preview fields。G19 不是真实长期系统、资产系统或 MetaProgress。

## 实际完成

- 新增 `LongTermShell` foundation。
- 固定六个顶层模块：目标、图鉴、研究、个人资历、抽奖、收藏/外观。
- 目标与个人资历包含 child preview groups。
- 研究和抽奖显示 disabled reasons，不执行 unlock、roll、cost 或 result generation。
- snapshot/interface sections 为 display-only previews。
- LongTermShell 不 dispatch CommandBus，不读取 RunContext、Encounter、Combat、Ledger 或 TruthMap。

## 关键提交

- `4eeb345daef5f8263b325db2ab5607e6c78f6d36` `feat(godot): add long term shell foundation`
- `04e14865f4d5eff7b16398d5730054273ccd0823` `docs: close G19 long term shell foundation`
- `ef362dc01bb4303408e86c2441cf9ae8b4379e1d` `docs: mark G19 merged to main`

## 新增系统 / 修改系统

- 新增 LongTermShell foundation。
- 修改 AppShell long-term route。
- 不实现真实目标、任务进度、成就检查、委托接受、codex data、research、profile progression、history storage、gacha、collection/appearance equipment、warehouse、asset events、item models、RewardBundle、Policy/Tag rules、red-dot clearing、reward claiming、persistence、MetaProgress、RunScene startup、CommandBus dispatch 或 private run-state reads。

## 验证状态

- `docs/validation/G19_LONG_TERM_SHELL_FOUNDATION_VALIDATION.md` 记录 G19 boundary、six-module placeholder plan、static validation commands、R4B Godot headless project-load/parser smoke PASS 和 no-runtime/manual-PASS boundary。
- `Godot headless project-load/parser smoke PASS` 不等于 complete gameplay runtime PASS。
- 未声明 manual playtest PASS。

## 明确未完成

- 未完成真实长期系统。
- 未完成 asset system、item model、gacha、history storage、reward claiming、MetaProgress、persistence、red-dot clearing。
- 未启动 RunScene。

## 后续承接点

- G20 改为 docs-only knowledge governance，先整理设计资料、阶段总结、路线分析和边界。
- 后续 Asset Contract / Warehouse / Settlement / Objective / Gacha 等只能在独立阶段启动。

## 主要风险

- LongTermShell 可能被误读成长期系统已实现。
- 抽奖 tab 可能被误读成 gacha 已启动。
- display-only preview 可能被误读成真实数据合同已经落地。

## 是否已合并 main

是。事实源记录 G19 fast-forward merged to main，main HEAD 为 `ef362dc01bb4303408e86c2441cf9ae8b4379e1d`。

## 对后续路线的影响

G19 暴露了长期系统、资产系统、奖励、历史、抽奖等未来系统的入口密度，因此 G20 先转向知识治理，避免在缺少设计源索引和边界图时直接启动 Asset Contract。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/NEXT_HANDOFF.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G19_LONG_TERM_SHELL_FOUNDATION_VALIDATION.md`
- `docs/handoff/HANDOFF_G19_LONG_TERM_SHELL_FOUNDATION.md`
- `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
- `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
- Git commit log
