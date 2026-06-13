# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Main HEAD: `2855ca9889e394fb79d22c468b1355cd3871fd39`
- Remote live main HEAD: `2855ca9889e394fb79d22c468b1355cd3871fd39`
- Current branch: `main`
- Current milestone: G12 Legacy Demo Core Loop, Chinese Readability & Typography Parity is complete, pushed, and closed. G10 and G11 are also complete, pushed, and closed. G13 is not started.
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`
- G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`
- G11 closeout commit: `4be0010 docs: close G11 mainline UX readability pass`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`

## What Main Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, runtime parse hotfix, UI presentation layering contracts, and G9 UI core flow baseline.

The UI baseline includes a three-page shell, InventoryPanel, GroundLootPanel, pickup/drop through CommandBus, blocked reason display, and ResultPanel settlement explanation.

Main also contains the completed G10 bounded player-flow fixes, MiniMap click-to-map, dev-only diagnostics gating, manifest/fallback art smoke, responsive layout contracts, and updated bug/backlog documentation. It also contains the completed G11 mainline readability pass and closeout. G12 is now complete: it lightly aligned legacy Demo core-loop feel, Chinese readability, scan/map feedback, HUD protocol/pressure wording, loot/settlement text, and local typography/readability settings on top of existing systems. It did not change core gameplay state ownership.

## What Main Does Not Mean

It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

G12 closeout does not mean 1:1 legacy Demo remake, new gameplay, new systems, full font pipeline, full art migration, action combat, or G13.

## G10 Boundary

G10 is closed. Its completed area was current progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning.

Do not treat G10 as permission for complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/DOCS_INDEX.md`
3. `docs/MILESTONES.md`
4. `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`
5. `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
6. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
7. `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`
8. `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`
9. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff

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

- Main is at `2855ca9889e394fb79d22c468b1355cd3871fd39`.
- G12 is complete and closed as a lightweight legacy Demo core-loop, Chinese readability, and typography/readability alignment stage.
- G10 closeout remains `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- G10 closeout follow-up remains `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.
- G11 is closed at `4be0010dd68abe1b0e74966775db64f736d78e15`.
- G12-R3 did not run Godot/editor/game/import, did not add font files/resources/import products, did not modify `run_scene.gd`, and did not commit the existing Godot dirty whitelist.
- G12 is not a G10/G11 continuation, not G13, not a 1:1 legacy Demo remake, and does not mean new gameplay, full systems, persistence, final UI, action combat, full font pipeline, or full art migration is complete.

## Next Stage Candidates

- Runtime smoke / playable verification.
- MetaProgress / long-term progression systems.
- Deploy persistence / save and deployment continuity.
- Main gameplay deepening after G12 validation.
- More complete legacy Demo experience reproduction.

These are candidates only. G12 does not start or implement them, and G13 is not started.
