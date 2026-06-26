# Handoff G36 Runtime Architecture / Save Profile

G36-R2 adds save/profile foundation and thins RunScene responsibilities without changing project scenes or runtime gameplay scope.

## What Changed

- Added save profile foundation scripts under `Godot/GraytailGodot/scripts/core/save`.
- Added run architecture helper scripts under `Godot/GraytailGodot/scripts/core/run`.
- `MetaProgressAdapter` now blocks save/debug/settlement writes when the loaded save is in read-only fallback.
- `RunScene` now uses helpers for meta commit, debug lookup, UI model bridge, and run start route normalization.
- DeployPrep/AppShell normalize start payloads through `RunStartRouteAdapter`.
- Added `tools/validate_g36_runtime_architecture.ps1`.

## Boundaries

- RunScene remains the current authoritative runtime owner.
- GameKernel remains a non-authoritative bootstrap placeholder.
- Profile switching is blocked mid-run.
- No complete SaveManager UI, active-run persistence, real RunBootstrapper, warehouse writes, objective/reward/pool implementation, or new gameplay content is implemented.
- No gameplay runtime PASS or manual playtest PASS is claimed.

## Next Gate

Proceed to unified G36-R3 audit / release gate after branch validation and parser smoke are reviewed.

## Validation Snapshot

- G35 runtime safety validation: PASS.
- G36 runtime architecture validation: PASS.
- Godot headless import smoke: PASS.
- Godot headless project-load/parser smoke: PASS.
- Godot headless scene-load smoke: PASS.
- Gameplay runtime PASS and manual playtest PASS are not claimed.
