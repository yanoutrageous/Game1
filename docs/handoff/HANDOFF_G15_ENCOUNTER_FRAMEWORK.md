# G15 Encounter Framework Handoff

## Stage Identity

- Historical label: G15
- Formal name: Encounter Contract Foundation
- Chinese name: 遭遇房通用框架基础
- Branch: `godot/g15-encounter-contract-foundation`
- Branch HEAD before R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`
- Merged to main: no
- Corresponding main baseline: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a`

## Current Fact Source

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch: `godot/g15-encounter-contract-foundation`
- Branch commits:
  - `aca5b958a588879a16da97616484424da795da7f feat(godot): add encounter contract foundation`
  - `1887385af81624ebcd84342ca765d75e6fbf20eb feat(godot): add encounter slot surface adapter`
- Main HEAD: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a`
- Worktree status before R5 planning/execution: clean, staged empty
- Validation chain status: static docs/code grep only; no Godot/editor/game/import run
- Primary docs to read next:
  - `docs/NEXT_HANDOFF.md`
  - `docs/PROJECT_BASELINE.md`
  - `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`
  - `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`

## Completed

- R3 rules layer created `EncounterContract` as the public/display dictionary contract.
- R3 added `EncounterResolver` as a read-only adapter from current run context to public encounter identity, state, options, view model, and result summary.
- R3 exposed `encounter_view_model` and `encounter_result_summary` through `RunQueryFacade` snapshots.
- R3 added additive CommandBus bridge `select_encounter_option`.
- R3 bridges search/chest options to existing `search_current_room()` and event options to existing `select_event_option()`.
- R4 added `RunSurfaceModel` display-only encounter section consumption from public snapshot fields.
- R4 added a lightweight `RunSurface` EncounterSlot.
- R4 added minimal `run_scene.gd` wiring from `RunSurface.encounter_option_selected` to `_dispatch_command(&"select_encounter_option", payload)`.
- R4 documented manual checklist and validation boundaries.

## Explicitly Not Done

- G15 is not merged to `main`.
- No runtime PASS is claimed.
- Godot/editor/game/import was not run.
- No full combat room, action combat, lottery system, out-of-run progression, MetaProgress, Deploy persistence, full event library, unique collectible system, warehouse, codex, appearance library, duplicate compensation, or record system was implemented.
- `lottery` is only a reserved encounter type name.
- Existing event, loot, extract, combat, settlement, screen routing, and old command semantics are not migrated into UI.
- No `project.godot`, resources, fonts, import products, `.uid`, or `.translation` files are part of G15 closeout.

## Validation Results

- Static validation: G15-R3/R4 code and docs were checked by `git diff --check`, `git status --short`, and targeted grep commands during their execution turns.
- Runtime smoke: not run.
- Manual smoke: not run.
- Known unverified items:
  - Runtime parser/load behavior for the branch after R4.
  - EncounterSlot visual behavior in actual Godot runtime.
  - End-to-end click behavior for search/chest/event options.
  - Branch-to-main integration state.

## Risks And Debt

- `run_scene.gd`, `RunSurfaceModel`, and global status docs remain high-conflict files for future UI/rules work.
- Existing event modal and new EncounterSlot can both expose event-related actions; runtime smoke should confirm player-facing flow remains understandable.
- G15 has no runtime PASS until explicitly authorized runtime or manual testing records it.
- Mainline promotion still requires a separate integration audit or merge plan.

## Next Handoff Guide

- Recommended next step: choose one of these with explicit user authorization:
  - runtime smoke / parser check;
  - branch-to-main integration audit;
  - G16 battle room / combat encounter planning;
  - further encounter content adapter planning.
- Not recommended next step: directly merge to main without checking remote/main state and branch integration risk.
- Files or systems to inspect first:
  - `Godot/GraytailGodot/scripts/core/run/encounter/`
  - `Godot/GraytailGodot/scripts/core/command/command_bus.gd`
  - `Godot/GraytailGodot/scripts/core/run/run_query_facade.gd`
  - `Godot/GraytailGodot/scripts/ui/run_surface/`
  - `Godot/GraytailGodot/scripts/core/run/run_scene.gd`
- Decisions that need user approval:
  - whether to run Godot/editor/runtime smoke;
  - whether to audit and merge the branch to main;
  - whether G16 starts with combat room planning or another encounter/content path.

## Safety Boundaries

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git pull`, `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not apply/pop/drop/delete the protective stash: `stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`.
- Do not run Godot/editor/game/import unless explicitly authorized.
- Dirty whitelist for future checks: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
