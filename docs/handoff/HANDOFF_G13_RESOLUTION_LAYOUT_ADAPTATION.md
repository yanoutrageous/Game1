# Handoff G13 Resolution Layout Adaptation

## Identity

- Historical label: G13
- Formal name: Fixed Resolution Layout Adaptation
- Chinese name: 固定分辨率档位与布局适配
- Repository: `D:\AGAME1\_repo_cache\Game1_work`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Main HEAD after G13-R3: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`
- Remote live main after G13-R3: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`
- G13 baseline commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`
- Status: complete, pushed, and closed after G13-R5 docs-only closeout

## Scope Completed

- Added fixed resolution tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.
- Added runtime-only automatic resolution recommendation.
- Added runtime-only manual apply and restore-auto recommendation actions.
- Added runtime window resize locking without submitting `project.godot`.
- Added settings-page resolution selector, apply action, restore-auto action, and status text.
- Extended `UILayoutProfile` with fixed-tier fields.
- Lightly adapted existing HUD, MiniMap, MapOverlay, Inventory, GroundLoot, and ResultPanel sizing, font sizing, wrapping, minimum sizes, or tooltip-related layout.
- Updated G13 validation and manual hand-test checklist records.

## Validation Summary

- Static validation passed for `git diff --stat`, `git diff --check`, `git status --short`, fact grep, resolution-tier grep, UI/settings keyword grep, staged-range checks, and remote live main confirmation.
- Godot/editor/game/import was not run.
- This handoff does not claim runtime PASS.
- `project.godot` was not submitted.
- Resources, import products, and font files were not submitted.
- Existing dirty whitelist was not submitted.

## Remaining Verification Boundary

- DisplayServer window resize locking still needs runtime smoke or manual verification.
- Five supported resolution tiers still need manual visual clipping checks.
- Settings-page apply and restore-auto behavior still need runtime/manual verification.
- Key UI surfaces still need visual checks at `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.

## Non-Goals

G13 does not include arbitrary aspect-ratio responsiveness, mobile support, ultrawide support, 4K support, full platform DPI parity, complete final UI, complete settings, complete save/deploy persistence, MetaProgress, action combat, new gameplay, new resources, full art migration, broad UI rewrite, broad architecture reshaping, or runtime PASS.

## Next Stage Candidates

- Runtime smoke / playable verification.
- Five-tier resolution manual smoke.
- DisplayServer window behavior verification.
- Later broader layout adaptation.
- MetaProgress / Deploy persistence / main gameplay deepening.

These are candidates only. G13-R5 does not start G14 or any next-stage implementation.
