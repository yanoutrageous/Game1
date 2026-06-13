# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Main HEAD: `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f`
- Remote live main HEAD: `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f`
- Current branch: `main`
- Current milestone: G13 Fixed Resolution Layout Adaptation is active. G10, G11, and G12 are complete, pushed, and closed. G14 is not started.
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`
- G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`
- G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`
- G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`

## What Main Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, runtime parse hotfix, UI presentation layering contracts, and G9 UI core flow baseline.

The UI baseline includes a three-page shell, InventoryPanel, GroundLootPanel, pickup/drop through CommandBus, blocked reason display, and ResultPanel settlement explanation.

Main also contains the completed G10 bounded player-flow fixes, MiniMap click-to-map, dev-only diagnostics gating, manifest/fallback art smoke, responsive layout contracts, and updated bug/backlog documentation. It also contains the completed G11 mainline readability pass and the completed G12 legacy Demo readability/typography pass. G13 now targets fixed 16:9 resolution tiers, a minimal runtime display setting, and bounded layout adaptation on top of existing UI surfaces.

## What Main Does Not Mean

It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

G13 does not mean arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full DPI parity, complete final UI, complete settings, Deploy persistence, MetaProgress, action combat, new gameplay, new resources, or full art migration.

## G10 Boundary

G10 is closed. Its completed area was current progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning.

Do not treat G10 as permission for complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/DOCS_INDEX.md`
3. `docs/MILESTONES.md`
4. `docs/validation/G13_RESOLUTION_LAYOUT_ADAPTATION_VALIDATION.md`
5. `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`
6. `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
7. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
8. `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`
9. `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`
10. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff

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

- Main is at `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f`.
- G12 is complete and closed as a lightweight legacy Demo core-loop, Chinese readability, and typography/readability alignment stage.
- G13 is active for fixed resolution tiers and bounded layout adaptation.
- G13 supported tiers are `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.
- G10 closeout remains `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- G10 closeout follow-up remains `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.
- G11 is closed at `4be0010dd68abe1b0e74966775db64f736d78e15`.
- G12-R3 did not run Godot/editor/game/import, did not add font files/resources/import products, did not modify `run_scene.gd`, and did not commit the existing Godot dirty whitelist.
- G13 is not a G10/G11/G12 continuation, not G14, not arbitrary responsive UI, not mobile/ultrawide/4K/DPI parity, not a full settings system, and not a new gameplay or persistence phase.

## Next Stage Candidates

- Runtime smoke / playable verification.
- MetaProgress / long-term progression systems.
- Deploy persistence / save and deployment continuity.
- Main gameplay deepening after G12 validation.
- More complete legacy Demo experience reproduction.

These are candidates only. G13 does not start or implement them, and G14 is not started.
