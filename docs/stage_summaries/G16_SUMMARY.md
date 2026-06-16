# G16 阶段总结

## 阶段目标

G16 目标是 Combat Encounter Foundation：在 G15 encounter contract 之上添加第一版 `combat_basic` / `monster_basic` public encounter data 和 `attack_basic` option bridge。G16 是 combat encounter foundation，不是完整战斗系统。

## 实际完成

- Monster rooms 暴露 public `monster_summary`、`combat_encounter_state`、`attack_basic` option、deterministic risk summary、reward preview 和 combat result summary。
- `select_encounter_option` 将 Monster `attack_basic` 委托到既有 deterministic `fight_current_enemy` command path。
- 不修改 `CombatState.fight_enemy()`、`RoomResolver.fight_current_enemy()`、`RunRuleService.apply_combat_reward()` settlement semantics。
- UI 修改限制在 `RunSurfaceModel` display-only mapping。
- 后续 parser blocker fix 使 encounter helper references parser-safe。

## 关键提交

- `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a` `feat(godot): add combat encounter foundation`
- `8a0e0c3e718a30c1f0afd210b46ecfa564d16468` `docs: close G16 combat encounter foundation`
- `4637e8fa0eeec6859df4eab26d5a961868e4c071` `fix(godot): expose encounter parser classes`
- `9af74aeefd3a28b6b417fa0667532737cddc916b` `docs: mark G16 merged to main`

## 新增系统 / 修改系统

- 新增 combat/monster encounter foundation。
- 扩展 `select_encounter_option` 的 Monster `attack_basic` routing。
- 不实现 Boss、elite、multi-monster combat、skills、passive systems、leave confirmation、teleport restriction、combat animation、full drop economy、codex、action combat 或 real-time combat。

## 验证状态

- `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md` 记录 static validation、Monster `attack_basic` bridge、public summary/risk/reward fields、R5 docs-only closeout、parser blocker fix、Godot headless project-load/parser smoke PASS 和 fast-forward main merge status。
- `Godot headless project-load/parser smoke PASS` 不等于 complete gameplay runtime PASS。
- 未声明 manual playtest PASS。

## 明确未完成

- 未完成完整战斗系统。
- 未完成 Boss、elite、多怪、技能、被动、动画、实时战斗、完整掉落经济、codex、lottery、out-of-run progression、MetaProgress、Deploy persistence。

## 后续承接点

- Post-G16 architecture direction 指向 G17：优先拆 top-level AppShell / NavigationIntent / PageRouter / MainMenuShell，而不是继续堆 `run_scene.gd`。

## 主要风险

- parser smoke PASS 可能被误读为 complete gameplay runtime PASS。
- Combat foundation 可能被误读为完整战斗系统。
- 继续向 `run_scene.gd` 堆功能会扩大编排边界风险。

## 是否已合并 main

是。事实源记录 G16 fast-forward merged to main after Godot headless project-load/parser smoke PASS。

## 对后续路线的影响

G16 证明 G15 encounter contract 可承接 Monster/combat 最小切片，同时暴露下一阶段压力：主菜单、出发准备、长期系统需要 top-level app shell，而不是继续让 run 层承担所有入口。

## 事实来源

- `docs/PROJECT_BASELINE.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/MILESTONES.md`
- `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md`
- `docs/handoff/HANDOFF_G16_COMBAT_ENCOUNTER_FOUNDATION.md`
- `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`
- `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
- Git commit log
