# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch for this handoff: `godot/g17-app-shell-main-menu`
- Base branch: `main`
- G17-R2 branch: `godot/g17-app-shell-main-menu`
- G17-R2 baseline main HEAD: `80c0d0653db0ec486c1b8f97b4787d8107dd2a0f docs: add post-G16 architecture direction baseline`
- G17-R2 commit: `368a7be5c2fb919db47421a026ddf417df9c1b1c feat(godot): add app shell main menu foundation`
- G17-R3 status: acceptance, Godot headless project-load/parser smoke, and docs-only closeout complete on the G17 branch.
- G17 branch remains separate from main; no mainline integration was performed in R3.
- Main HEAD at start of Post-G16 architecture direction import: `9af74aeefd3a28b6b417fa0667532737cddc916b docs: mark G16 merged to main`
- Source branch for G16: `godot/g16-combat-encounter-foundation`
- G16 baseline main HEAD: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`
- G16-R3 commit: `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a feat(godot): add combat encounter foundation`
- G16-R5 branch closeout commit: `8a0e0c3e718a30c1f0afd210b46ecfa564d16468 docs: close G16 combat encounter foundation`
- G16 parser blocker fix commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071 fix(godot): expose encounter parser classes`
- G16 merged to main: yes, by fast-forward.
- Main HEAD after G16 fast-forward and before this post-merge status commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071`
- G15 post-merge status commit: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`
- G15 branch closeout commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad docs: close G15 encounter framework foundation`
- G15-R4 commit: `1887385af81624ebcd84342ca765d75e6fbf20eb feat(godot): add encounter slot surface adapter`
- G15-R3 commit: `aca5b958a588879a16da97616484424da795da7f feat(godot): add encounter contract foundation`
- Current milestone: G16 combat encounter foundation is complete, pushed, parser-smoke checked, and fast-forward merged to `main`. G15 is complete, pushed, merged to main, and closed. G10, G11, G12, G13, and G14 are complete, pushed, and closed.
- Post-G16 architecture direction baseline: `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`.
- G17 validation draft: `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md`.
- G17 handoff: `docs/handoff/HANDOFF_G17_APP_SHELL_MAIN_MENU.md`.

## What Main Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, UI presentation layering contracts, G9 UI core flow, G10-G14 UX/surface work, the completed G14 legacy Demo run surface sprint, G15 Encounter contract / EncounterSlot work, and G16 combat encounter foundation.

G15-R3 adds a rules-layer Encounter contract foundation. It introduces `EncounterContract`, `EncounterResolver`, public `encounter_view_model`, public `encounter_result_summary`, and additive `select_encounter_option` bridge for search/chest/event. It does not change old command semantics.

G15-R4 adds the first UI consumer. `RunSurfaceModel` builds a display-only encounter section from public snapshot fields, `RunSurface` renders a lightweight EncounterSlot, and `run_scene.gd` only wires option selection to `_dispatch_command(&"select_encounter_option", payload)`.

G16-R3 adds the first combat encounter foundation on top of the G15 public encounter framework. Monster rooms expose `monster_basic` / `combat_basic` public encounter data, a public `attack_basic` option, monster summary, risk/reward preview, and combat result summary. The option routes through `select_encounter_option` into the existing deterministic `fight_current_enemy` chain.

The parser blocker fix `4637e8f` makes G15/G16 encounter helper references parser-safe. Final integration ran Godot headless project-load/parser smoke successfully before fast-forwarding G16 into `main`. This is not a complete gameplay runtime PASS or manual playtest PASS.

Post-G16 architecture direction import records the next structural recommendation: G17 should be `AppShell / NavigationIntent / PageRouter / MainMenuShell`, not a plain main-menu implementation. The point is to split app-level navigation from run-level orchestration before expanding main menu, expedition prep, long-term systems, lottery, or profile/save work.

G17-R2 starts that split on branch `godot/g17-app-shell-main-menu`: it adds `NavigationIntent`, `PageRouter`, `AppShell`, `MainMenuShell`, and a static `MainMenuModel`. `run_scene.gd` only mounts the AppShell and keeps existing run orchestration. G17-R3 acceptance and Godot headless project-load/parser smoke passed. G17 does not implement formal expedition prep, long-term systems, warehouse, codex, lottery, MetaProgress, Deploy persistence, or full settings.

## What G16 Does Not Mean

G16 does not implement Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restrictions, combat animation, full drop economy, codex, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, Deploy persistence, or full event library.

G16 does not claim complete gameplay runtime PASS or manual playtest PASS.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/NEXT_HANDOFF.md`
3. `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`
4. `docs/handoff/HANDOFF_G17_APP_SHELL_MAIN_MENU.md`
5. `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md`
6. `docs/handoff/HANDOFF_G16_COMBAT_ENCOUNTER_FOUNDATION.md`
7. `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md`
8. `docs/handoff/HANDOFF_G15_ENCOUNTER_FRAMEWORK.md`
9. `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`
10. `docs/DOCS_INDEX.md`
11. `docs/MILESTONES.md`
12. `docs/ENGINEERING_STATUS.md`
13. `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
14. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
15. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff.

## Safety And Dirty Rules

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git pull`, `git fetch`, `git rebase`, `git reset`, `git clean`, or `git stash` unless a later user instruction explicitly permits the exact operation.
- Do not run Godot/editor/game/import unless the user explicitly authorizes it.
- Do not create temporary scripts, logs, caches, or derived files outside `D:\AGAME1\_repo_cache\Game1_work`.
- Do not scan or clean paths outside `D:\AGAME1\_repo_cache\Game1_work` unless the user provides an explicit path and authorization.
- Planning source files now live under `D:\AGAME1\Base Docs` and are not part of repository commits.
- `docs/可行性判断.md` and `docs/难度判断.md` were moved by the user to `D:\AGAME1\Base Docs`; their repository deletions are authorized docs relocation deletions.
- Protective stash must remain untouched: `stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`.
- If unknown dirty appears, stop and report.

## First Thing To Know

- G16-R3 is complete and pushed at `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a`.
- G16-R5 branch closeout is complete and pushed at `8a0e0c3e718a30c1f0afd210b46ecfa564d16468`.
- G16 parser blocker fix is complete and pushed at `4637e8fa0eeec6859df4eab26d5a961868e4c071`.
- G16 is fast-forward merged to main after Godot headless project-load/parser smoke PASS.
- `select_encounter_option` is additive only and delegates to existing search/event paths.
- For Monster rooms, G16 extends `select_encounter_option` with `attack_basic`, which delegates to existing deterministic `fight_current_enemy`; it must not change `CombatState.fight_enemy()` settlement semantics.
- `EncounterViewModel` is public/display-only and must not expose TruthMap, Ledger, AssetLedger, RunAssetLedger, RunRuleService, or RunContext private objects.
- `RunSurface` is UI surface composition only, and `RunSurfaceModel` is display-only.
- `run_scene.gd` remains orchestration owner for CommandBus dispatch, screen routing, and event / loot / extract decisions.
- The protective stash remains expected and must not be apply/pop/drop/delete.

## Next Stage Candidates

- Current branch stage: G17 `AppShell / NavigationIntent / PageRouter / MainMenuShell` branch acceptance and closeout is complete.
- G17-R1 audit and planning is complete.
- G17-R2 implements minimal AppShell + MainMenuShell with expedition and long-term placeholder routes only.
- G17-R3 acceptance, docs closeout, and Godot headless project-load/parser smoke are complete.
- Suggested next decision: decide whether to integrate the G17 branch into main.

This handoff records G17 branch closeout status and does not claim complete gameplay runtime PASS or manual playtest PASS. No G18 work began.
