# G13 阶段总结

## 阶段目标

G13 目标是 Fixed Resolution Layout Adaptation：只支持固定 16:9 分辨率层级，增加 runtime-only display selection、自动推荐、手动 apply/reset、窗口 resize locking 和现有 UI 的小范围布局适配。

## 实际完成

- 支持固定层级：`1280x720`、`1366x768`、`1600x900`、`1920x1080`、`2560x1440`。
- 增加 startup auto recommendation、runtime-only display selection、manual apply/reset、runtime window resize locking。
- 在 `UILayoutProfile` 中增加 fixed-tier 字段。
- 对 HUD、MiniMap、MapOverlay、Inventory、GroundLoot、ResultPanel 做轻量布局适配。
- 更新 validation 与 manual checklist。

## 关键提交

- `5afdb05fefe65031da1486507b0b39bdd2f1cea7` `feat(godot): add fixed resolution layout support`
- `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` `docs: close G13 resolution layout adaptation pass`

## 新增系统 / 修改系统

- 修改显示设置、UILayoutProfile 与现有 UI 布局。
- 没有修改核心规则、CommandBus、ledger、TruthMap、save/persistence、MetaProgress 或 Deploy persistence。
- 没有提交 `project.godot`、资源、import product、字体文件或 Godot dirty whitelist。

## 验证状态

- `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md` 记录静态验证和 closeout。
- G13-R3 未运行 Godot/editor/game/import。
- closeout 是 static-validation only，不声明 runtime PASS。
- manual playtest PASS：`unknown`；固定分辨率手动 smoke 仍需后续授权验证。

## 明确未完成

- 未支持任意宽高比、mobile、ultrawide、4K、完整 DPI parity。
- 未完成 complete final UI、complete settings、新 gameplay、新资源、完整美术迁移。

## 后续承接点

- G14 在固定分辨率基线之上做 Legacy Demo UI Surface Sprint。
- 后续任何 runtime/manual PASS 需要单独授权实际运行。

## 主要风险

- 固定层级适配可能被误读成全面响应式支持。
- 静态 closeout 可能被误写成 runtime PASS。

## 是否已合并 main

是。事实源显示 G13 complete and closed，且 current mainline includes G13 fixed resolution layout support and closeout。

## 对后续路线的影响

G13 为之后的 RunSurface、EncounterSlot、AppShell/Deploy/LongTerm shell 提供可控显示框架，避免在不稳定分辨率上推进复杂 UI。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`
- `docs/handoff/HANDOFF_G13_RESOLUTION_LAYOUT_ADAPTATION.md`
- Git commit log
