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

## Naming Rule

Use the formal name in new planning and handoff documents, and keep the historical label in parentheses when it helps locate old branches or validation records.

Example: `Legacy Demo UI Surface Sprint (G14)`.

## Current Mainline

Current main HEAD before G16 post-merge status commit: `4637e8fa0eeec6859df4eab26d5a961868e4c071`.

G16 baseline main HEAD before R3: `a28ae4c0c96f0b964602fd6fe7b88fa254354763`.

Current branch: `main`.

Current G16-R3 baseline commit: `a28ae4c docs: mark G15 merged to main`.

G16-R3 commit: `fb18aa0 feat(godot): add combat encounter foundation`.

G16-R4 acceptance: passed.

G16-R5 status: docs-only branch closeout.

G16 parser blocker fix: `4637e8f fix(godot): expose encounter parser classes`.

G16 merged to main: yes, by fast-forward.

Current G15 branch HEAD before R5 closeout: `1887385af81624ebcd84342ca765d75e6fbf20eb`.

Current main commit before G15-R3: `d6c03c6 docs: close G14 legacy demo UI surface pass`.

G15-R5 branch closeout commit: `e72d3a5 docs: close G15 encounter framework foundation`.

G15-R4 commit: `1887385 feat(godot): add encounter slot surface adapter`.

G15-R3 commit: `aca5b95 feat(godot): add encounter contract foundation`.

G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`.

G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`.

G14-R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

G14-R3 baseline before implementation and G13 closeout commit: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`.

The current mainline includes G10 Progress & Art Smoke Foundation, the G10 closeout follow-up, the completed G11 mainline UX readability pass, G11 closeout, the completed G12 legacy Demo readability/typography parity pass, G13 fixed resolution layout support and closeout, the completed G14 run surface sprint, G15 Encounter Contract Foundation, and G16 combat encounter foundation. G16 adds only the first `combat_basic` / `monster_basic` encounter foundation; it does not represent complete final UI, complete MetaProgress, complete Deploy persistence, complete long-term system completion, complete 1:1 legacy Demo reproduction, Boss, action combat, real-time combat, complete gameplay runtime PASS, or manual playtest PASS.

G11, G12, G13, and G14 are complete and closed. G15 R3/R4/R5 are complete and merged to main. G16 keeps `select_encounter_option` additive and extends only Monster `attack_basic` routing to existing deterministic `fight_current_enemy`; search/event/extract command semantics remain unchanged.

G15-R3/R4/R5 did not run Godot/editor/game/import and do not claim runtime PASS. G16 final ran Godot headless project-load/parser smoke and passed, but does not claim complete gameplay runtime PASS or manual playtest PASS.

## Next Stage Candidates

- Further encounter content adapter planning.
- Later out-of-run progression stage.
- Later lottery / unique collectible / appearance stage after progression, warehouse, codex, appearance library, and record systems.

These are candidates only. G16 final does not start G17, Boss, action combat, out-of-run progression, lottery, MetaProgress, or Deploy persistence.

If UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. The rules line must not directly modify UI surface code, and the UI line must not directly read rule private state. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.
