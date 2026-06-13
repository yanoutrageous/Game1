# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME2\repo\Game1`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- G14-R3 baseline main HEAD: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`
- G14-R3 baseline remote live main HEAD: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`
- Current branch: `main`
- Current milestone: G14 Legacy Demo UI Surface Sprint is active. G10, G11, G12, and G13 are complete, pushed, and closed.
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`
- G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`
- G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`
- G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G13 baseline commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`
- G13 closeout commit: `8878bd3 docs: close G13 resolution layout adaptation pass`

## What Main Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, runtime parse hotfix, UI presentation layering contracts, and G9 UI core flow baseline.

The UI baseline includes a three-page shell, InventoryPanel, GroundLootPanel, pickup/drop through CommandBus, blocked reason display, and ResultPanel settlement explanation.

Main also contains the completed G10 bounded player-flow fixes, MiniMap click-to-map, dev-only diagnostics gating, manifest/fallback art smoke, responsive layout contracts, and updated bug/backlog documentation. It also contains the completed G11 mainline readability pass and the completed G12 legacy Demo readability/typography pass. G13 added fixed 16:9 resolution tiers, runtime-only display selection, resize locking, a minimal settings-page selector, fixed-tier `UILayoutProfile` fields, and bounded layout adaptation on existing UI surfaces. G14-R3 starts the legacy Demo visible run surface by adding `RunSurface` and `RunSurfaceModel` without moving rules or CommandBus decisions into UI.

## What Main Does Not Mean

It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

G14 does not mean complete 1:1 legacy Demo reproduction, complete final UI, action combat, full event library, talent/card systems, MetaProgress, Deploy persistence, new gameplay, full art migration, broad architecture rewrite, G15, or runtime PASS.

## G10 Boundary

G10 is closed. Its completed area was current progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning.

Do not treat G10 as permission for complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/DOCS_INDEX.md`
3. `docs/MILESTONES.md`
4. `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`
5. `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`
6. `docs/handoff/HANDOFF_G13_RESOLUTION_LAYOUT_ADAPTATION.md`
7. `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`
8. `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
9. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
9. `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`
10. `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`
11. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff

## Safety And Dirty Rules

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not run Godot/editor/game/import unless the user explicitly authorizes it.
- Dirty whitelist only: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
- If unknown dirty appears, stop and report.

## First Thing To Know

The next conversation should know:

- G14-R3 started from `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf`, the G13 closeout main.
- G12 is complete and closed as a lightweight legacy Demo core-loop, Chinese readability, and typography/readability alignment stage.
- G13 is complete, pushed, and in docs-only closeout for fixed resolution tiers and bounded layout adaptation.
- G13 supported tiers are `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.
- G13-R3 did not run Godot/editor/game/import, did not submit `project.godot`, did not submit resources/import products/font files, and did not submit the existing dirty whitelist.
- G13 closeout is static-validation only; DisplayServer window behavior, five-tier runtime behavior, settings-page apply/reset behavior, resize locking, and visual clipping still need later runtime smoke or manual verification before any PASS claim.
- G10 closeout remains `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- G10 closeout follow-up remains `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.
- G11 is closed at `4be0010dd68abe1b0e74966775db64f736d78e15`.
- G12-R3 did not run Godot/editor/game/import, did not add font files/resources/import products, did not modify `run_scene.gd`, and did not commit the existing Godot dirty whitelist.
- G14-R3 is not a G10/G11/G12/G13 continuation, not G15, not a full UI remake, not new gameplay, and not runtime PASS.

## Next Stage Candidates

- Runtime smoke / playable verification.
- Five-tier resolution manual smoke.
- DisplayServer window behavior verification.
- MetaProgress / long-term progression systems.
- Deploy persistence / save and deployment continuity.
- Main gameplay deepening after G12 validation.
- G14-R4 second-wave run surface refinement.

These are candidates only. G14-R3 does not start G15 and does not close G14.
