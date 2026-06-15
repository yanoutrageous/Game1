# G15 Encounter Framework Handoff

## Stage Identity

- Historical label: G15
- Formal name: Encounter Contract Foundation
- Chinese name: 遭遇房通用框架基础
- Branch: `godot/g15-encounter-contract-foundation`
- Branch HEAD before R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`
- Branch closeout commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad`
- Merged to main: yes, by fast-forward into `main` during G15 final integration
- Corresponding main baseline: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a`

## Current Fact Source

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch after final integration: `main`
- Source branch: `godot/g15-encounter-contract-foundation`
- Branch commits:
  - `aca5b958a588879a16da97616484424da795da7f feat(godot): add encounter contract foundation`
  - `1887385af81624ebcd84342ca765d75e6fbf20eb feat(godot): add encounter slot surface adapter`
- Branch closeout commit:
  - `e72d3a5dc4a57122d42f881f391f2b47389fcdad docs: close G15 encounter framework foundation`
- Main HEAD after fast-forward and before post-merge status commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad`
- Post-merge status commit: `docs: mark G15 merged to main`
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

- G15 has been fast-forward merged into `main`.
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
  - Post-merge runtime parser/load behavior.

## Risks And Debt

- `run_scene.gd`, `RunSurfaceModel`, and global status docs remain high-conflict files for future UI/rules work.
- Existing event modal and new EncounterSlot can both expose event-related actions; runtime smoke should confirm player-facing flow remains understandable.
- G15 has no runtime PASS until explicitly authorized runtime or manual testing records it.
- Mainline promotion was completed by fast-forward only; runtime smoke and playable verification remain separate future work.

## Next Handoff Guide

- Recommended next step: choose one of these with explicit user authorization:
  - runtime smoke / parser check;
  - post-merge runtime smoke / parser check;
  - G16 battle room / combat encounter planning;
  - further encounter content adapter planning.
- Not recommended next step: treating the fast-forward merge as runtime PASS without an authorized smoke or manual test.
- Files or systems to inspect first:
  - `Godot/GraytailGodot/scripts/core/run/encounter/`
  - `Godot/GraytailGodot/scripts/core/command/command_bus.gd`
  - `Godot/GraytailGodot/scripts/core/run/run_query_facade.gd`
  - `Godot/GraytailGodot/scripts/ui/run_surface/`
  - `Godot/GraytailGodot/scripts/core/run/run_scene.gd`
- Decisions that need user approval:
  - whether to run Godot/editor/runtime smoke;
  - whether to run post-merge Godot/editor/runtime smoke;
  - whether G16 starts with combat room planning or another encounter/content path.

## Safety Boundaries

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git pull`, `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not apply/pop/drop/delete the protective stash: `stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`.
- Do not run Godot/editor/game/import unless explicitly authorized.
- Dirty whitelist for future checks: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
