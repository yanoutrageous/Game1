# Branch Changes: G10 Progress & Art Smoke Foundation

## Branch

- Branch: `godot/g10-progress-art-smoke-foundation`
- Base: `main @ a13a6fae3208850ae43e4b511511e008eb311a3e`
- Remote: `https://github.com/yanoutrageous/Game1.git`

## Changed

- Added a preserved G10 baseline bug backlog under `docs/bugs/`.
- Added bounded player-flow UI fixes:
  - ResultPanel return actions.
  - Run pause/settings overlay.
  - MapOverlay selected/action feedback.
  - Blocked CommandResult flash feedback.
- Added dev-only diagnostics contracts and panel:
  - Default player channel hides/disables diagnostics.
  - No local log writing or dangerous command execution.
- Added art smoke foundation:
  - `G10ArtSmokeRegistry`
  - manifest asset IDs
  - fallback asset IDs
  - no loose art assets
  - no direct core resource path coupling
- Added responsive/mobile reservation:
  - `UILayoutProfile`
  - `PresentationLayerContracts` entry
  - key panel profile hooks
- Updated baseline/status docs to use `a13a6fae3208850ae43e4b511511e008eb311a3e`.
- Added G10 validation script.

## Not Changed

- No core rules ownership changes.
- No complete MetaProgress.
- No Deploy persistence.
- No complete long-term backend.
- No action combat.
- No new gameplay.
- No full art replacement.
- No historical documentation deletion, move, or rename.
