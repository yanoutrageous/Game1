# G12 阶段总结

## 阶段目标

G12 目标是 Legacy Demo Core Loop, Chinese Readability & Typography Parity：以旧 Demo 作为 core-loop feel 和可读性参考，而不是 1:1 remake。范围限制在现有系统上的中文文案、反馈、reward/loot/settlement 说明和本地 typography/readability 调整。

## 实际完成

- 更新当前事实源、G12 validation 和 manual playtest guidance。
- 改善玩家可见文本、中文可读性、本地 typography/readability 设置。
- 改善 MiniMap/MapOverlay scan feedback、HUD protocol/pressure wording、Inventory/GroundLoot capacity 与 loot explanation、ResultPanel settlement readability、presentation mapping。

## 关键提交

- `2855ca9889e394fb79d22c468b1355cd3871fd39` `fix(godot): align G12 core loop readability with legacy demo`
- `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f` `docs: close G12 legacy demo parity pass`

## 新增系统 / 修改系统

- 修改现有 UI 文案、反馈与 presentation mapping。
- 没有新增 gameplay、系统、资源、字体、import product。
- 没有修改 `run_scene.gd`。

## 验证状态

- `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md` 记录 R3 execution 和 R4 docs-only closeout。
- G12-R3 没有运行 Godot/editor/game/import。
- 不声明 runtime PASS 或 manual playtest PASS。
- manual playtest PASS：`unknown`；R3c 未找到可证明完整手动通过的事实源。

## 明确未完成

- 不等于旧 Demo 1:1 remake。
- 未完成 MetaProgress、Deploy persistence、完整长期系统、action combat、新玩法、新关卡、新敌人、新经济系统、完整事件库、完整美术迁移、完整 final UI、完整 settings、完整 diagnostics 或完整字体系统。

## 后续承接点

- G13 承接固定 16:9 分辨率与布局适配。
- G14 承接可见 run UI surface，而不是重写规则。

## 主要风险

- 旧 Demo parity 容易被误读成完整复刻。
- typography/readability 调整可能被误读成完整字体管线。

## 是否已合并 main

是。事实源显示 G12 complete, pushed, and closed，且 current mainline includes completed G12。

## 对后续路线的影响

G12 把旧 Demo 的核心可读性和反馈口径搬回当前主线，为 G13 的固定分辨率验证和 G14 的 run surface 重组提供显示基线。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
- `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`
- Git commit log
