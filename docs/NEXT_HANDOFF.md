# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME2\repo\Game1`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch: `main`
- Current main HEAD before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`
- Current remote live main HEAD before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`
- Current commit: `fc2b86b fix(godot): resolve RunSurface parser type inference`
- G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`
- G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`
- G14-R3 feature commit: `1d33c89 feat(godot): add legacy demo run surface shell`
- G13 closeout commit: `8878bd3 docs: close G13 resolution layout adaptation pass`
- Current milestone: G14 Legacy Demo UI Surface Sprint is complete, committed, pushed, and in R5 closeout. G10, G11, G12, and G13 are complete, pushed, and closed. G15 is not started.

## What Main Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, runtime parse hotfixes, UI presentation layering contracts, and the G9 UI core flow baseline.

The UI baseline includes a three-page shell, InventoryPanel, GroundLootPanel, pickup/drop through CommandBus, blocked reason display, MiniMap click-to-map, MapOverlay feedback, Pause/Settings overlay, dev-only diagnostics hiding, and ResultPanel settlement/return routes.

G13 added fixed 16:9 resolution tiers, runtime-only display selection, resize locking, a minimal settings-page selector, fixed-tier `UILayoutProfile` fields, and bounded layout adaptation on existing UI surfaces.

G14 adds the first legacy Demo-style run surface pass. `RunSurface` composes the left scanner, center room/objective panel, right protocol/danger/status rail, bottom action bar, lower-left resource/backpack summary, overlay slot, modal slot, and feedback slot. `RunSurfaceModel` is display-only and adapts public snapshot, `MiniMapViewModel`, `UILayoutProfile`, and latest command result data.

G14-R4 refined the low-fidelity presentation layer: scanner legend, action hints, button enabled/disabled visuals, dark modal/button style helpers, event / loot / extract display text, and right-rail status/feedback hierarchy. The hotfix at `fc2b86b` resolves a GDScript parser type inference error in `run_surface.gd`.

`run_scene.gd` remains the orchestration owner. CommandBus dispatch, screen routing, and event / loot / extract command result decisions stay in the existing run scene paths.

## What Main Does Not Mean

G14 does not mean complete 1:1 legacy Demo reproduction, complete final UI, action combat, full event library, talent/card systems, MetaProgress, Deploy persistence, new gameplay, full art migration, broad architecture rewrite, G15, or runtime PASS.

G14 did not run Godot/editor/game/import and must not be reported as runtime PASS. Runtime smoke, playable verification, five-tier visual checks, and old Demo UI manual acceptance remain future verification candidates.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/NEXT_HANDOFF.md`
3. `docs/handoff/HANDOFF_G14_LEGACY_DEMO_UI_SURFACE.md`
4. `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`
5. `docs/DOCS_INDEX.md`
6. `docs/MILESTONES.md`
7. `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`
8. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
9. `docs/handoff/HANDOFF_G13_RESOLUTION_LAYOUT_ADAPTATION.md`
10. `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`
11. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff

## Safety And Dirty Rules

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git pull`, `git fetch`, `git rebase`, `git reset`, `git clean`, or `git stash` unless a later user instruction explicitly permits the exact operation.
- Do not run Godot/editor/game/import unless the user explicitly authorizes it.
- Do not create temporary scripts, logs, caches, or derived files outside `D:\AGAME2\repo\Game1`.
- Do not scan or clean paths outside `D:\AGAME2\repo\Game1` unless the user provides an explicit path and authorization.
- Dirty whitelist only: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
- Protective stash must remain untouched: `stash@{0}: On godot/g7-lua-ux-flow-parity-p2: pre-sync generated dirty before aligning to G13 closeout main`.
- If unknown dirty appears, stop and report.

## Safety Event

G14-R3 execution reported that two temporary script files were mistakenly created outside `D:\AGAME2\repo\Game1`. The execution frame reported that they were cleaned as necessary deletion, and no repository commit contains an outside-repository path. Future CodeX instructions must continue to explicitly forbid outside-repository temporary files. Do not independently scan outside-repository paths; if residue confirmation is needed, the user must provide the exact path and authorization.

## First Thing To Know

- G14 is complete and closed by R5 docs-only closeout.
- G14 started from `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`, the G13 closeout main.
- G14-R3 is complete, committed, and pushed at `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5`.
- G14-R3 follow-up is complete, committed, and pushed at `39b51f165b548cc28fef072675f846413513f2ed`.
- G14-R4 is complete, committed, and pushed at `cc652e5a616359d7d6857c87da5f76c6aca25c28`.
- G14 hotfix is complete, committed, and pushed at `fc2b86b6b6b2af9a6c249230621482617b594775`.
- `RunSurface` is UI surface composition only, and `RunSurfaceModel` is display-only.
- They do not directly read `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state, do not dispatch CommandBus, and do not add rules.
- G14 did not run Godot/editor/game/import and does not claim runtime PASS.
- The protective stash remains expected and must not be apply/pop/drop.

## Next Stage Candidates

- Runtime smoke / playable verification.
- Old Demo UI manual acceptance.
- UI line continuing visible surface reproduction.
- Rules line starting main-loop semantics audit.
- UI / rules parallel branch strategy.

These are candidates only. The next stage is not started, and G15 is not started in G14-R5.

If UI and rules work proceed in parallel, branch from the latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. The rules line must not directly modify the UI surface, and the UI line must not directly read rules private state.

High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.
