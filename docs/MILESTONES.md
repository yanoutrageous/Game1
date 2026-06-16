# Milestones

This file maps the historical G-number labels to stable milestone names. It does not rename branches, rewrite Git history, or remove historical labels.

| Historical label | Formal name | Status |
| --- | --- | --- |
| G5 | Asset UI Presentation Baseline | In main as historical baseline |
| G6 | Playable Lua Parity Core | In main as historical baseline |
| G7 | Playable Flow Baseline | In main |
| G8 | Asset Ledger & Settlement Core | In main |
| G8.1 | Architecture Hardening | In main |
| G8.2 | Kernel Protocol Baseline | In main |
| G8.2 hotfix | Runtime Parse Hotfix | In main |
| G9 Presentation | UI Presentation Layering Contracts | In main |
| G9 Final | UI Core Flow Baseline | In main |
| G10 | Progress & Art Smoke Foundation | Complete, merged to main, and closed at `aa19db2f1989c6ebfc22676d84b83da5c6977f64` |
| G11 | Mainline Testability & UX Readability Repair | Complete and closed at `4be0010dd68abe1b0e74966775db64f736d78e15` |
| G12 | Legacy Demo Core Loop, Chinese Readability & Typography Parity | Complete; R3 at `2855ca9889e394fb79d22c468b1355cd3871fd39`, closeout at `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f` |
| G13 | Fixed Resolution Layout Adaptation | Complete and closed at `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`; static validation only, no runtime PASS |
| G14 | Legacy Demo UI Surface Sprint | Complete and closed through parser hotfix at `fc2b86b6b6b2af9a6c249230621482617b594775`; R5 docs-only closeout records handoff/status |
| G15 | Encounter Contract Foundation | R3/R4/R5 complete and fast-forward merged to `main`; branch closeout commit `e72d3a5dc4a57122d42f881f391f2b47389fcdad`; no runtime PASS |
| G16 | Combat Encounter Foundation | R3 complete at `fb18aa06c1850b9e2c627285382e82b8bc7c5d3a`; R4 accepted; R5 docs-only branch closeout; parser blocker fix `4637e8f`; fast-forward merged to main after headless project-load/parser smoke PASS |
| Post-G16 direction | Architecture Direction Baseline | Docs-only imported direction baseline; recommends G17 as `AppShell / NavigationIntent / PageRouter / MainMenuShell` |
| G17 | AppShell / NavigationIntent / PageRouter / MainMenuShell | R2 implementation complete at `368a7be5c2fb919db47421a026ddf417df9c1b1c`; R3 acceptance, Godot headless project-load/parser smoke, docs-only closeout, and fast-forward main merge complete |
| G18 | DeployPrepShell / DeployConfig / RunStartConfig Foundation | R3 complete at `59ea57caf1baa977e727da2697cac014cbd7429e`; R4 closeout at `285695cda0141322b0672d65998f3d3f9aa32654`; Godot headless project-load/parser smoke PASS; fast-forward merged to main; no gameplay runtime PASS or manual playtest PASS |
| G19 | LongTermShell Foundation | R3 complete at `4eeb345daef5f8263b325db2ab5607e6c78f6d36`; R4B closeout / first main merge baseline at `04e14865f4d5eff7b16398d5730054273ccd0823`; fast-forward merged to main; no complete gameplay runtime PASS or manual playtest PASS |
| G20 | Project Knowledge Governance | Docs-only governance branch `godot/g20-project-knowledge-governance`; R3a imported authorized text design source copies at `caaf3c5eb0559a395b9940dacd05dc5810bcd1d7`; R3b adds governance maps and indexes at `81513bdbf10cf4f774a9bda5c3ce3e2d3b1302dc`; R3c adds G10-G19 stage summaries and route analysis at `10a2dd3ea2d71879b66f5d1c20177fb7bed2a6f1`; R3d1 adds branch / commit / validation governance matrices; R3d2 adds decision log / glossary / deprecated inventory; R4A read-only acceptance passed; R4B docs-only closeout / first main merge baseline at `ae689b7464fd6ea81a763110cd89813abcfb6665`; fast-forward merged to main; post-merge docs commit hash pending until commit; G21 not started; no Godot run |

## Naming Rule

Use the formal name in new planning and handoff documents, and keep the historical label in parentheses when it helps locate old branches or validation records.

Example: `Legacy Demo UI Surface Sprint (G14)`.

## Current Mainline

Current main HEAD before G17 post-merge status commit: `baa57fa41167c86ad226b5b8be4d540ff114269f`.

G16 baseline main HEAD before R3: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`.

Current branch: `main`.

Current G16-R3 baseline commit: `a28ae4c docs: mark G15 merged to main`.

G16-R3 commit: `fb18aa0 feat(godot): add combat encounter foundation`.

G16-R4 acceptance: passed.

G16-R5 status: docs-only branch closeout.

G16 parser blocker fix: `4637e8f fix(godot): expose encounter parser classes`.

G16 merged to main: yes, by fast-forward.

Post-G16 architecture direction baseline: `docs/handoff/HANDOFF_POST_G16_ARCHITECTURE_DIRECTION.md`.

Current G15 branch HEAD before R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`.

Current main commit before G15-R3: `d6c03c6 docs: close G14 legacy demo UI surface pass`.

G15-R5 branch closeout commit: `e72d3a5 docs: close G15 encounter framework foundation`.

G15-R4 commit: `1887385 feat(godot): add encounter slot surface adapter`.

G15-R3 commit: `aca5b95 feat(godot): add encounter contract foundation`.

G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`.

G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`.

G14-R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

G14-R3 baseline before implementation and G13 closeout commit: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`.

The current mainline includes G10 Progress & Art Smoke Foundation, the G10 closeout follow-up, the completed G11 mainline UX readability pass, G11 closeout, the completed G12 legacy Demo readability/typography parity pass, G13 fixed resolution layout support and closeout, the completed G14 run surface sprint, G15 Encounter Contract Foundation, G16 combat encounter foundation, G17 AppShell / MainMenuShell foundation, G18 DeployPrepShell / DeployConfig / RunStartConfig foundation, G19 LongTermShell foundation, and G20 Project Knowledge Governance docs-only artifacts. G20 does not represent Asset Contract, Warehouse, gameplay implementation, Godot parser smoke PASS, complete gameplay runtime PASS, or manual playtest PASS.

G11, G12, G13, and G14 are complete and closed. G15 R3/R4/R5 are complete and merged to main. G16 keeps `select_encounter_option` additive and extends only Monster `attack_basic` routing to existing deterministic `fight_current_enemy`; search/event/extract command semantics remain unchanged.

G15-R3/R4/R5 did not run Godot/editor/game/import and do not claim runtime PASS. G16 final ran Godot headless project-load/parser smoke and passed, but does not claim complete gameplay runtime PASS or manual playtest PASS.

## Next Stage Candidates

- Latest integrated stage: G20 `Project Knowledge Governance`.
- G20 docs-only governance completed R4A read-only acceptance, R4B docs-only closeout, fast-forward main merge, and post-merge docs calibration. G21 has not started. Candidate direction: Asset Contract Foundation, requiring independent audit, plan, execution, and validation.

G18 accepts the foundation only. It does not start Boss, action combat, true RunScene launch, real maps, warehouse/requisition/permit rules, settlement reports/history, long-term systems, lottery, MetaProgress, Deploy persistence, or any G19+ implementation.

If UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. The rules line must not directly modify UI surface code, and the UI line must not directly read rule private state. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.
