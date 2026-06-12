# Handoff: G10 Progress & Art Smoke Foundation

## Stage Identity

- Historical label: G10
- Formal name: Progress & Art Smoke Foundation
- Chinese name: 当前进度整理与美术接入基础验证
- Branch: `godot/g10-progress-art-smoke-foundation`
- G10 implementation HEAD before closeout: `cf6e73d16574f6b900d18217471522aa18a6ab10`
- Final G10 closeout HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Final mainline HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Merged to main: yes
- Corresponding main HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Remote live main HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Remote live G10 branch HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`

## Current Fact Source

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch: `main`
- Main HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Remote live main HEAD: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- Closed G10 branch: `godot/g10-progress-art-smoke-foundation`
- Worktree status: known dirty is limited to the Godot-generated whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
- Primary docs to read next:
  - `docs/NEXT_HANDOFF.md`
  - `docs/PROJECT_BASELINE.md`
  - `docs/bugs/G10_BASELINE_BUG_BACKLOG.md`
  - `docs/DOCS_INDEX.md`

## Completed

- Preserved raw G10 baseline smoke and P0/P1/P2 backlog in `docs/bugs/G10_BASELINE_BUG_BACKLOG.md`.
- Added ResultPanel return actions for main menu and expedition shell.
- Added run pause/settings overlay without persistence writes.
- Added MapOverlay action feedback and blocked reason visual feedback.
- Added dev-only diagnostics panel controlled by build-channel/UIVisibilityPolicy-equivalent gating.
- Added G10 art smoke registry using manifest asset IDs and fallback IDs only.
- Added `UILayoutProfile` responsive/mobile reservation and key panel hooks.
- Added MiniMapPanel direct click to open MapOverlay through the existing `open_map` command path.
- Kept MapOverlay feedback minimal: open-source hint plus selected/action feedback only.
- Added closeout validation transcript at `docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md`.
- Updated G10-facing baseline/status docs during implementation before final closeout.
- Post-merge closeout follow-up calibrated current fact-source/status docs to `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.

## Closeout Follow-up

- Remote live `main` confirmed at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- Remote live `godot/g10-progress-art-smoke-foundation` confirmed at `aa19db2f1989c6ebfc22676d84b83da5c6977f64`.
- This follow-up only corrects documentation facts and remote confirmation records.
- This follow-up is not G11 and does not reopen or continue G10 development.

## Explicitly Not Done

- No complete MetaProgress.
- No Deploy persistence.
- No complete long-term system backend.
- No action combat.
- No new gameplay.
- No full art replacement.
- No broad architecture reshaping.
- No complete mobile/touch support.
- No local preference persistence or external log writing.

## Validation Results

- Static validation: 13-item closeout transcript recorded at `docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md`.
- Runtime smoke: Godot headless parse/project launch PASS; no parser errors observed.
- Manual smoke: not a full manual QA pass; use G10 backlog for remaining targeted manual checks.

## Risks And Debt

- Responsive layout is still an early reservation.
- Art smoke uses a small internal/placeholder sample only.
- Settings and diagnostics are shell-level and intentionally do not persist preferences.
- Future UI cleanup should avoid growing `run_scene.gd` beyond routing, assembly, signal binding, dispatch forwarding, and refresh entry points.

## Next Handoff Guide

- Recommended next step: G10 is already closed; move only to a separately approved non-G10 phase if requested later.
- Not recommended next step: complete MetaProgress, Deploy persistence, full art migration, action combat, or new gameplay.
- Files to inspect first: `docs/bugs/G10_BASELINE_BUG_BACKLOG.md`, `Godot/GraytailGodot/scripts/core/run/run_scene.gd`, `Godot/GraytailGodot/scripts/ui/dev/dev_diagnostics_panel.gd`, `Godot/GraytailGodot/scripts/presentation/g10_art_smoke_registry.gd`.

## Safety Boundaries

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git rebase`, `git reset`, `git clean`, or `git stash`.
- Dirty whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
