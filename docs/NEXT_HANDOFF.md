# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Main HEAD: `e261ac7d8671b59e7e72750122e6581af6ea6644`
- Remote live main HEAD: `e261ac7d8671b59e7e72750122e6581af6ea6644`
- Current branch: `main`
- Current milestone: G11 Mainline Testability & UX Readability Repair closeout. G11-R3 is complete and pushed; G11-R4 is docs-only closeout, not G12.
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`
- G11-R3 commit: `e261ac7 fix(godot): improve G11 mainline UX readability`

## What Main Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, runtime parse hotfix, UI presentation layering contracts, and G9 UI core flow baseline.

The UI baseline includes a three-page shell, InventoryPanel, GroundLootPanel, pickup/drop through CommandBus, blocked reason display, and ResultPanel settlement explanation.

Main also contains the completed G10 bounded player-flow fixes, MiniMap click-to-map, dev-only diagnostics gating, manifest/fallback art smoke, responsive layout contracts, and updated bug/backlog documentation. It also contains the completed G11-R3 mainline readability pass for current fact sources, hand-test coverage, MapOverlay feedback wording, Inventory/GroundLoot hints, ResultPanel return tooltips, and Pause/Settings wording. It does not change core gameplay state ownership.

## What Main Does Not Mean

It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

## G10 Boundary

G10 is closed. Its completed area was current progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning.

Do not treat G10 as permission for complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/DOCS_INDEX.md`
3. `docs/MILESTONES.md`
4. `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`
5. `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`
6. `docs/validation/G10_CLOSEOUT_REMOTE_CONFIRMATION_FOLLOWUP.md`
7. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff

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

- Main is at `e261ac7d8671b59e7e72750122e6581af6ea6644`.
- G11-R3 is complete and pushed, and G11-R4 is a docs-only closeout.
- G10 closeout remains `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- G10 closeout follow-up remains `53a4e122376998d2f6d0a2a617b753a3d382b2f0`.
- G11 is not a G10 continuation, not G12, and does not mean new gameplay, full systems, persistence, final UI, action combat, or full art migration is complete.

## Next Stage Candidates

- MetaProgress / long-term progression systems.
- Deploy persistence / save and deployment continuity.
- Main gameplay deepening.

These are candidates only. G11-R4 does not start or implement them.
