# G14 阶段总结

## 阶段目标

G14 目标是 Legacy Demo UI Surface Sprint：新增旧 Demo 风格的可见 run UI surface foundation，同时保留既有 panel、CommandBus、screen routing 和事件/loot/extract 决策路径。它不是完整 final UI、不是完整 1:1 legacy Demo reproduction，也不是 G15。

## 实际完成

- G14-R3 新增 `RunSurfaceModel` display-only adapter、`MiniMapViewModel`、`UILayoutProfile` 和 latest command result 显示数据。
- G14-R3 新增 `RunSurface`，覆盖左 scanner、中心 room/objective、右 protocol/danger/status、底部 actions、左下资源、overlay/modal/feedback slots。
- `run_scene.gd` 继续拥有 CommandBus dispatch、event/loot/extract decisions、screen routing 和既有 panel control。
- G14-R4 refine scanner legend/detail、right-side protocol/danger/status lines、bottom action hints、button visual states、legacy-style modal chrome、event/loot/extract display text。
- parser hotfix 只修复 `run_surface.gd` type inference。

## 关键提交

- `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5` `feat(godot): add legacy demo run surface shell`
- `39b51f165b548cc28fef072675f846413513f2ed` `docs: record G14 run surface acceptance follow-up`
- `cc652e5a616359d7d6857c87da5f76c6aca25c28` `feat(godot): refine legacy demo run surface presentation`
- `fc2b86b6b6b2af9a6c249230621482617b594775` `fix(godot): resolve RunSurface parser type inference`
- `d6c03c6ff8ca9884f992a61e27728bdddf3a637a` `docs: close G14 legacy demo UI surface pass`

## 新增系统 / 修改系统

- 新增 `RunSurface` 与 `RunSurfaceModel` foundation。
- 修改显示层和 run screen composition。
- 不直接读取 `TruthMap`、`RunRuleService`、Ledger、`AssetLedger` private state。
- 不 dispatch CommandBus，不新增规则。

## 验证状态

- `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md` 记录 G14 R3/R4/hotfix/closeout 边界。
- G14 未运行 Godot/editor/game/import。
- 不声明 runtime PASS 或 manual playtest PASS。
- manual playtest PASS：`unknown`；R3c 未找到完整手动通过记录。

## 明确未完成

- 未完成完整 final UI。
- 未完成完整 1:1 legacy Demo reproduction。
- 未完成 MetaProgress、Deploy persistence、完整长期系统、action combat、完整事件库、完整 talent/card 系统、完整美术迁移。

## 后续承接点

- G15 在 G14 的显示 surface 上接入 public Encounter contract 和 EncounterSlot，而不是把规则搬进 UI。

## 主要风险

- `RunSurface` 可能被误读成完整 run screen 或规则所有者。
- parser hotfix 可能被误写成 runtime PASS。
- 历史记录包含一次外部临时脚本安全事件，后续执行必须继续禁止外部临时文件。

## 是否已合并 main

是。事实源显示 G14 complete, committed, pushed, and closed，且 current mainline includes G14 run surface work。

## 对后续路线的影响

G14 把可见 run surface 从零散 panel 整理成可承接的显示层，为 G15/G16 的 Encounter/Combat foundation 提供 UI 展示落点，同时明确 `run_scene.gd` 仍保留编排职责。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`
- `docs/handoff/HANDOFF_G14_LEGACY_DEMO_UI_SURFACE.md`
- `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
- Git commit log
