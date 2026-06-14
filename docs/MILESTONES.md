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

## Naming Rule

Use the formal name in new planning and handoff documents, and keep the historical label in parentheses when it helps locate old branches or validation records.

Example: `Legacy Demo UI Surface Sprint (G14)`.

## Current Mainline

Current main HEAD before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`.

Current remote live main HEAD before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`.

Current commit: `fc2b86b fix(godot): resolve RunSurface parser type inference`.

G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`.

G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`.

G14-R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

G14-R3 baseline before implementation and G13 closeout commit: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`.

The current mainline includes G10 Progress & Art Smoke Foundation, the G10 closeout follow-up, the completed G11 mainline UX readability pass, G11 closeout, the completed G12 legacy Demo readability/typography parity pass, G13 fixed resolution layout support and closeout, and the completed G14 run surface sprint. It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, complete long-term system completion, complete 1:1 legacy Demo reproduction, G15, or runtime PASS.

G11, G12, G13, and G14 are complete and closed. G14 acceptance records that `RunSurface` is UI-only composition, `RunSurfaceModel` is display-only, CommandBus dispatch and event / loot / extract decisions stay in `run_scene.gd`, and the outside-repository temporary-script incident was reported as cleaned without repository commit residue.

G14 did not run Godot/editor/game/import and does not claim runtime PASS.

## Next Stage Candidates

- Runtime smoke / playable verification.
- Old Demo UI manual acceptance.
- UI line continuing visible surface reproduction.
- Rules line starting main-loop semantics audit.
- UI / rules parallel branch strategy.

These are candidates only. The next stage is not started here, and G15 is not started in G14-R5.

If UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. The rules line must not directly modify UI surface code, and the UI line must not directly read rule private state. High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.
