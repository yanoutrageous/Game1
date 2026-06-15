# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch: `godot/g16-combat-encounter-foundation`
- Source branch: `main`
- G16-R3 baseline main HEAD: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`
- G16-R3 branch: `godot/g16-combat-encounter-foundation`
- Branch HEAD before G15-R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`
- Branch closeout commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad`
- Rules-layer foundation commit: `aca5b958a588879a16da97616484424da795da7f`
- G15 post-merge status commit: `a28ae4c0c96f0b964602fd6fe7b88fa254354763 docs: mark G15 merged to main`
- G15 baseline main HEAD: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a`
- Main HEAD after G15 fast-forward and before post-merge status commit: `e72d3a5dc4a57122d42f881f391f2b47389fcdad`
- G15 branch merged to main: yes, by fast-forward
- Current milestone: G16 combat encounter foundation is active on `godot/g16-combat-encounter-foundation`. G15 is complete, pushed, merged to main, and closed. G10, G11, G12, G13, and G14 are complete, pushed, and closed.

## What The Branch Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, UI presentation layering contracts, G9 UI core flow, G10-G14 UX/surface work, and the completed G14 legacy Demo run surface sprint.

G15-R3 adds a rules-layer Encounter contract foundation. It introduces `EncounterContract`, `EncounterResolver`, public `encounter_view_model`, public `encounter_result_summary`, and additive `select_encounter_option` bridge for search/chest/event. It does not change old command semantics.

G15-R4 adds the first UI consumer. `RunSurfaceModel` builds a display-only encounter section from public snapshot fields, `RunSurface` renders a lightweight EncounterSlot, and `run_scene.gd` only wires option selection to `_dispatch_command(&"select_encounter_option", payload)`.

G16-R3 adds the first combat encounter foundation on top of the G15 public encounter framework. Monster rooms expose `monster_basic` / `combat_basic` public encounter data, a public `attack_basic` option, monster summary, risk/reward preview, and combat result summary. The option routes through `select_encounter_option` into the existing deterministic `fight_current_enemy` chain.

## What G15 Does Not Mean

G15 is now merged to `main` by fast-forward. The source branch remains useful as historical evidence.

G15 does not mean runtime PASS. Godot/editor/game/import was not run in G15-R3, G15-R4, or G15-R5 unless a later record explicitly says otherwise.

G15 does not implement full combat rooms, action combat, lottery systems, out-of-run progression, MetaProgress, Deploy persistence, full event libraries, unique collectibles, warehouse, codex, appearance library, duplicate compensation, record systems, complete final UI, or G16. `lottery` is only a reserved encounter type name.

G16-R3 does not implement Boss, elite, multi-monster combat, skills, passive systems, leave confirmation, teleport restrictions, combat animation, full drop economy, codex, action combat, real-time combat, lottery, out-of-run progression, MetaProgress, Deploy persistence, or runtime PASS.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/NEXT_HANDOFF.md`
3. `docs/handoff/HANDOFF_G15_ENCOUNTER_FRAMEWORK.md`
4. `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`
5. `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md`
6. `docs/DOCS_INDEX.md`
7. `docs/MILESTONES.md`
8. `docs/ENGINEERING_STATUS.md`
9. `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
10. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
11. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff

## Safety And Dirty Rules

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git pull`, `git fetch`, `git rebase`, `git reset`, `git clean`, or `git stash` unless a later user instruction explicitly permits the exact operation.
- Do not run Godot/editor/game/import unless the user explicitly authorizes it.
- Do not create temporary scripts, logs, caches, or derived files outside `D:\AGAME1\_repo_cache\Game1_work`.
- Do not scan or clean paths outside `D:\AGAME1\_repo_cache\Game1_work` unless the user provides an explicit path and authorization.
- Dirty whitelist only: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
- Protective stash must remain untouched: `stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`.
- Local user planning docs may exist as untracked files and are not part of G16 implementation or this commit: `docs/主菜单策划案.md`, `docs/战斗房与怪物遭遇通用规则策划案.md`, `docs/出发探索界面与出勤准备规则策划案.md`.
- If unknown dirty appears, stop and report.

## First Thing To Know

- G15 branch head before R5 closeout is `1887385af81624ebcd84342ca765d75e6fbf20eb`.
- G15-R3 is complete, committed, and pushed at `aca5b958a588879a16da97616484424da795da7f`.
- G15-R4 is complete, committed, and pushed at `1887385af81624ebcd84342ca765d75e6fbf20eb`.
- G15-R5 is docs-only closeout / handoff / status calibration and has been merged into main by fast-forward.
- G16-R3 starts from `main @ a28ae4c0c96f0b964602fd6fe7b88fa254354763` and is limited to `combat_basic` / `monster_basic` encounter foundation.
- `select_encounter_option` is additive only and delegates to existing search/event paths.
- For Monster rooms, G16-R3 extends `select_encounter_option` with `attack_basic`, which delegates to existing deterministic `fight_current_enemy`; it must not change `CombatState.fight_enemy()` settlement semantics.
- `EncounterViewModel` is public/display-only and must not expose TruthMap, Ledger, AssetLedger, RunAssetLedger, RunRuleService, or RunContext private objects.
- `RunSurface` is UI surface composition only, and `RunSurfaceModel` is display-only.
- `run_scene.gd` remains orchestration owner for CommandBus dispatch, screen routing, and event / loot / extract decisions.
- The protective stash remains expected and must not be apply/pop/drop/delete.

## Next Stage Candidates

- Runtime smoke / parser check for G16, only after explicit authorization.
- Post-merge runtime smoke / parser check, only after explicit authorization.
- Further encounter content adapter planning.

These are candidates only. G16-R3 does not claim runtime PASS.
