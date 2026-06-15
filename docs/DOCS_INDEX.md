# Docs Index

This file is the document navigation and historical index. It is not the fact source itself; use `docs/PROJECT_BASELINE.md` for current facts and `docs/NEXT_HANDOFF.md` for the minimum next-chat entry.

## Current Fact Sources

- `docs/PROJECT_BASELINE.md` - current engineering fact source.
- `docs/ENGINEERING_STATUS.md` - broader engineering status and validation list.
- `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` - Godot-specific current status.
- `docs/MILESTONES.md` - historical G-number to formal milestone mapping.
- `docs/bugs/G10_BASELINE_BUG_BACKLOG.md` - G10 baseline bug and remaining-scope backlog evidence.
- `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md` - Post-G16 architecture direction baseline and G17 route recommendation.

## Next Conversation Minimum Reading

Read these first in a new Codex or ChatGPT conversation:

1. `docs/NEXT_HANDOFF.md`
2. `docs/PROJECT_BASELINE.md`
3. `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`
4. `docs/DOCS_INDEX.md`
5. `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md`
6. `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md`
7. `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md`
8. `docs/handoff/HANDOFF_G17_APP_SHELL_MAIN_MENU.md`
9. `docs/handoff/HANDOFF_G16_COMBAT_ENCOUNTER_FOUNDATION.md`
10. `docs/handoff/HANDOFF_G15_ENCOUNTER_FRAMEWORK.md`
11. `docs/handoff/HANDOFF_G14_LEGACY_DEMO_UI_SURFACE.md`
12. `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`
13. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
14. `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`
15. `docs/handoff/HANDOFF_G13_RESOLUTION_LAYOUT_ADAPTATION.md`
16. `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`
17. `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
18. `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`
19. `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`
20. `docs/handoff/HANDOFF_TEMPLATE.md` when creating a new branch or closure report

Do not start by reading every old audit, branch change, or design file unless the task needs historical detail.

## Design Documents

- `docs/design/G8_ASSET_LEDGER_INVENTORY_SETTLEMENT_CORE_PLAN.md`
- `docs/design/G9_UI_PRESENTATION_LAYERING_ARCHITECTURE.md`
- `docs/design/G10_FUTURE_CONTENT_PLANNING.md`
- `docs/ui-layout-implementation-plan.md`
- Older design/reference docs under `docs/design/`, `docs/art/`, and root `docs/*.md` are historical unless linked by the current task.

## Audit Evidence

Current and recent audit files live under `docs/audits/`.

- G8 Asset Ledger & Settlement Core audit.
- G8.1 Architecture Hardening audit.
- G8.2 Kernel Protocol Baseline audit.
- G9 Presentation Layering Contracts audit.
- G9 UI Core Flow Baseline audit.
- G10 Progress & Art Smoke Foundation audit.

## Validation Evidence

- `docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md` records the G10 closeout 13-item static validation run.
- `docs/validation/G10_CLOSEOUT_REMOTE_CONFIRMATION_FOLLOWUP.md` records the post-merge remote live confirmation and documentation calibration follow-up.
- `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md` records the G11 mainline UX readability validation checklist, R3 execution notes, and R4 docs-only closeout record.
- `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md` records the G12 lightweight legacy Demo core-loop, Chinese readability, typography/readability validation checklist, R3 implementation record, and R4 docs-only closeout notes.
- `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md` records the G13 fixed resolution tier and layout adaptation validation checklist, R3 static validation, and R5 closeout boundary.
- `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md` records the G14 run surface validation checklist, R3 shell, R4 surface refinement, hotfix, closeout boundary, no-runtime-PASS status, and outside-repository temporary-script safety event record.
- `docs/validation/G15_ENCOUNTER_CONTRACT_VALIDATION.md` records the G15 encounter contract foundation validation checklist, R3 rules contract, R4 EncounterSlot adapter, R5 docs-only closeout boundary, deferred lottery boundary, fast-forward main merge status, and no-runtime-PASS status.
- `docs/validation/G16_COMBAT_ENCOUNTER_FOUNDATION_VALIDATION.md` records the G16 combat/monster encounter foundation static validation, Monster `attack_basic` bridge, public summary/risk/reward fields, R5 docs-only closeout, parser blocker fix, headless project-load/parser smoke PASS, fast-forward main merge status, and no-complete-gameplay-runtime-PASS status.
- `docs/validation/G17_APP_SHELL_MAIN_MENU_VALIDATION.md` records the G17 AppShell / MainMenuShell validation boundary and R3 Godot headless project-load/parser smoke PASS; no complete gameplay runtime PASS is claimed.

Older audits remain useful for traceability but are not the first source for current state.

## Handoff Documents

Current handoffs live under `docs/handoff/`.

- Use `docs/handoff/HANDOFF_TEMPLATE.md` for every new phase, branch closure, mainline promotion, BUG-fix batch, and runtime smoke report.
- Existing G5-G9 handoffs are historical evidence. They should not be deleted or renamed in this consolidation.
- G10 handoff records bounded stabilization/art-smoke work, closeout, mainline merge status, and remaining out-of-scope systems.
- `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md` records the G11 mainline testability and UX readability pass closeout.
- `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md` records the G12 legacy Demo core-loop readability and typography parity pass closeout.
- `docs/handoff/HANDOFF_G13_RESOLUTION_LAYOUT_ADAPTATION.md` records the G13 fixed resolution tier and layout adaptation closeout.
- `docs/handoff/HANDOFF_G14_LEGACY_DEMO_UI_SURFACE.md` records the G14 legacy Demo run surface sprint closeout, handoff, validation boundary, and next-stage candidates.
- `docs/handoff/HANDOFF_G15_ENCOUNTER_FRAMEWORK.md` records the G15 encounter framework handoff, R3/R4/R5 commit chain, static validation boundary, non-goals, fast-forward main merge status, and next-stage candidates.
- `docs/handoff/HANDOFF_G16_COMBAT_ENCOUNTER_FOUNDATION.md` records the G16 combat encounter foundation closeout, completed R3/R4/R5 scope, parser blocker fix, headless project-load/parser smoke PASS, fast-forward main merge status, and next-stage candidates.
- `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md` records the imported Post-G16 architecture direction baseline: keep G15/G16, split top-level app shell next, and route G17 toward `AppShell / NavigationIntent / PageRouter / MainMenuShell`.
- `docs/handoff/HANDOFF_G17_APP_SHELL_MAIN_MENU.md` records the G17 AppShell / MainMenuShell closeout, R2 implementation boundary, R3 acceptance, Godot headless project-load/parser smoke PASS, and fast-forward main merge status.

## Branch Change Records

Branch change records live under `docs/branch_changes/`. They document what changed on a branch, but they are not the current fact source after mainline promotion.

## Godot Docs

Godot-specific docs live under `Godot/GraytailGodot/docs/`.

- `GODOT_CURRENT_STATUS.md` is the Godot status summary.
- `GODOT_ARCHITECTURE_NOTES.md` describes architecture boundaries.
- `MANUAL_PLAYTEST_GUIDE.md` describes current and historical playtest routes.
- Stage reports such as `GODOT_UI_FINAL_G9_REPORT.md` are evidence for a specific stage.

## Historical Reference

Root-level handoff files, old G2-G7 notes, Lua audit docs, UE docs, and early feasibility files are historical references. Read them only when investigating why a prior decision was made.

## Current Boundary

Current G16 baseline main HEAD was `a28ae4c0c96f0b964602fd6fe7b88fa254354763` after G15 post-merge status calibration (`a28ae4c docs: mark G15 merged to main`). G16 branch work happened on `godot/g16-combat-encounter-foundation`; R3 is pushed at `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a`, R4 acceptance passed, R5 is docs-only branch closeout, parser blocker fix is `4637e8fa0eeec6859df4eab26d5a961868e4c071`, and G16 is fast-forward merged to `main` after headless project-load/parser smoke PASS.

G14 adds the first legacy Demo-style run surface shell, second-wave surface presentation refinement, and parser hotfix on top of completed G10, G11, G12, and G13 work. It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, complete long-term system completion, complete 1:1 legacy Demo reproduction, G15, or runtime PASS.

G14 acceptance records that `RunSurface` is UI surface composition only, `RunSurfaceModel` is display-only, neither directly reads `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state, neither dispatches CommandBus, and `run_scene.gd` retains CommandBus dispatch, screen routing, and event / loot / extract decisions.

Safety note: G14-R3 execution reported an outside-repository temporary-script incident that was cleaned as necessary deletion. Future CodeX work must keep forbidding outside-repository temporary files and must not scan outside-repository paths unless the user provides a concrete path and authorization.

G10 is complete, merged to main, and closed. It was limited to progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning. It is not complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.

G11, G12, G13, and G14 are complete and closed. G15 R3/R4/R5 are complete and fast-forward merged to main. G16 is complete and fast-forward merged to main, bounded to the first `combat_basic` / `monster_basic` encounter foundation: public Monster summary, `attack_basic` option, deterministic risk/reward preview, combat result summary, and a bridge through existing `select_encounter_option` to `fight_current_enemy`. G16 is not Boss, not action combat, not real-time combat, not out-of-run progression, not lottery, not Deploy persistence, and not complete gameplay runtime PASS or manual playtest PASS. Future UI / rules parallel work must use separate branches from latest `main`; two computers must not push directly to `main` in parallel.

Post-G16 architecture direction baseline recommends G17 as `AppShell / NavigationIntent / PageRouter / MainMenuShell`. The next structural risk is not Encounter/Combat, but top-level application ownership: main menu, expedition prep, long-term systems, settings, and RunScene should be routed through an app shell instead of accumulating inside `run_scene.gd` or a temporary shell.

G17 branch work on `godot/g17-app-shell-main-menu` has R2 implementation, R3 acceptance/docs closeout, Godot headless project-load/parser smoke PASS, and is fast-forward merged to `main`. It does not implement full main menu, formal expedition prep, long-term systems, warehouse, codex, lottery, MetaProgress, Deploy persistence, full settings, complete gameplay runtime PASS, or manual playtest PASS.
