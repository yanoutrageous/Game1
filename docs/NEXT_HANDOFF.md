# Next Handoff

Read this first in the next Codex or ChatGPT conversation. This is the minimum next-chat entry, not a full historical archive.

## Current Baseline

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Main HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Remote live main HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Current branch: `main`
- Current milestone: Progress & Art Smoke Foundation (G10) is complete, merged to main, and closed. The closeout follow-up is documentation calibration only; it is not G11.

## What Main Can Do

Main contains playable flow, asset ledger and settlement rules, architecture hardening, kernel protocol baseline, runtime parse hotfix, UI presentation layering contracts, and G9 UI core flow baseline.

The UI baseline includes a three-page shell, InventoryPanel, GroundLootPanel, pickup/drop through CommandBus, blocked reason display, and ResultPanel settlement explanation.

Main also contains the completed G10 bounded player-flow fixes, MiniMap click-to-map, dev-only diagnostics gating, manifest/fallback art smoke, responsive layout contracts, and updated bug/backlog documentation. It does not change core gameplay state ownership.

## What Main Does Not Mean

It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

## G10 Boundary

G10 is closed. Its completed area was current progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning.

Do not treat G10 as permission for complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, large real-art migration, or broad architecture reshaping.

## Minimum Reading

1. `docs/PROJECT_BASELINE.md`
2. `docs/DOCS_INDEX.md`
3. `docs/MILESTONES.md`
4. `docs/validation/G10_CLOSEOUT_REMOTE_CONFIRMATION_FOLLOWUP.md`
5. `docs/handoff/HANDOFF_TEMPLATE.md` before writing a new handoff

## Safety And Dirty Rules

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git rebase`, `git reset`, `git clean`, or `git stash`.
- Do not run Godot/editor/game/import unless the user explicitly authorizes it.
- Dirty whitelist only: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
- If unknown dirty appears, stop and report.

## First Thing To Know

The next conversation should know: main is at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`; remote live `main` and remote live `godot/g10-progress-art-smoke-foundation` were both confirmed at that commit; G10 is complete, merged, and closed. This does not start G11 and does not mean new gameplay, full systems, persistence, final UI, action combat, or full art migration is complete.
