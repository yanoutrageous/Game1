# Handoff G19 LongTermShell Foundation

## Stage Facts

- Stage: G19 LongTermShell Foundation.
- Branch: `godot/g19-long-term-shell-foundation`.
- Baseline main: `0e44c261f399a197d6e6eec277eb51ce72e1ba8c docs: mark G18 merged to main`.
- Scope: `LongTermShell foundation + 6 module placeholder + interface preview only`.
- G19 uses six top-level modules: 目标、图鉴、研究、个人资历、抽奖、收藏 / 外观.
- G19-R3 implementation commit: `4eeb345daef5f8263b325db2ab5607e6c78f6d36 feat(godot): add long term shell foundation`.
- G19-R4B status: execution-frame self-check PASS, Godot headless project-load/parser smoke PASS, docs-only closeout complete on the G19 branch.
- G19 is not merged to main.
- G20 has not started.

## Completed In R3

- Added `LongTermShell`, `LongTermModel`, `LongTermTabModel`, and `LongTermSnapshot` under `Godot/GraytailGodot/scripts/ui/long_term/`.
- Replaced the AppShell long-term placeholder page with `LongTermShell`.
- Added `PAGE_LONG_TERM` in `PageRouter` while keeping the old placeholder alias compatible.
- Added additive `NavigationIntent.make_long_term()` helper.
- Added display-only preview fields for profile, unlock, history, asset projection, event flow, reward, red-dot, inventory link, codex link, and history link surfaces.

## Explicit Non-Goals

G19 does not implement real long-term systems, real goals, real task progress, real achievement checks, real commission acceptance, real codex data, real research, real profile progression, real history storage, real gacha, real collection / appearance equipment, real warehouse, real asset events, real RewardBundle, real ItemDefinition, real ItemInstance, real ItemStack, real Policy / Tag rules, real red-dot clearing, real reward claiming, real persistence, MetaProgress, RunScene startup, CommandBus dispatch, RunContext / Encounter / Combat / Ledger / TruthMap reads, DeployPrepShell semantic changes, DeployConfig semantic changes, G15/G16 encounter/combat semantic changes, project settings, scenes, resources, fonts, import products, `.uid`, `.translation`, or Base Docs changes.

## Validation Boundary

- R3 validation is static only: diff, diff check, status, positive grep, and code-only negative grep.
- R4B validation adds Godot headless project-load/parser smoke PASS.
- Smoke before/after status stayed clean and produced no project, scene, resource, import, `.uid`, or `.translation` dirty.
- Documentation may mention future-system terms only in forbidden-scope or not-implemented sections.
- No full gameplay runtime PASS is claimed.
- No manual playtest PASS is claimed.
- Base Docs were not modified.
- PATCH_MODE remains `AGAME1_ROOT`; future `apply_patch` paths still require the `_repo_cache/Game1_work/` prefix.

## Next Step

Use the G19 branch for main-merge decision. Do not start G20 until G19 mainline promotion is explicitly decided.
