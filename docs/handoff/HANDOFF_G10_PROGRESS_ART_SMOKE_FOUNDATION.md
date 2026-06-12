# Handoff: G10 Progress & Art Smoke Foundation

## Stage Identity

- Historical label: G10
- Formal name: Progress & Art Smoke Foundation
- Chinese name: 当前进度整理与美术接入基础验证
- Branch: `godot/g10-progress-art-smoke-foundation`
- Branch HEAD: record from `git rev-parse HEAD` after final commit/push
- Merged to main: no
- Corresponding main HEAD: `a13a6fae3208850ae43e4b511511e008eb311a3e`

## Current Fact Source

- Repo: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Current branch: `godot/g10-progress-art-smoke-foundation`
- Main HEAD: `a13a6fae3208850ae43e4b511511e008eb311a3e`
- Worktree status: must be clean after validation and commit
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
- Updated current fact-source/status docs from `eb9f5d6...` to `a13a6fa...`.

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

- Static validation: final result recorded in final report.
- Runtime smoke: Godot headless parse/project launch PASS; no parser errors observed.
- Manual smoke: not a full manual QA pass; use G10 backlog for remaining targeted manual checks.

## Risks And Debt

- Responsive layout is still an early reservation.
- Art smoke uses a small internal/placeholder sample only.
- Settings and diagnostics are shell-level and intentionally do not persist preferences.
- Future UI cleanup should avoid growing `run_scene.gd` beyond routing, assembly, signal binding, dispatch forwarding, and refresh entry points.

## Next Handoff Guide

- Recommended next step: targeted stabilization or mainline promotion after validation and user review.
- Not recommended next step: complete MetaProgress, Deploy persistence, full art migration, action combat, or new gameplay.
- Files to inspect first: `docs/bugs/G10_BASELINE_BUG_BACKLOG.md`, `Godot/GraytailGodot/scripts/core/run/run_scene.gd`, `Godot/GraytailGodot/scripts/ui/dev/dev_diagnostics_panel.gd`, `Godot/GraytailGodot/scripts/presentation/g10_art_smoke_registry.gd`.

## Safety Boundaries

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git rebase`, `git reset`, `git clean`, or `git stash`.
- Dirty whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
