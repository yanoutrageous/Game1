# G10 Baseline BUG Backlog

## Raw Baseline Smoke

- Branch: `godot/g10-progress-art-smoke-foundation`
- Base main HEAD: `a13a6fae3208850ae43e4b511511e008eb311a3e`
- Smoke type: Godot 4.6.3 headless runtime launch.
- Result: PASS. The project parsed and launched the main scene for 30 frames without parser errors.
- Godot dirty after smoke: none observed.

## Raw P0 Issues

- None confirmed by the headless baseline smoke.

## Raw P1 Issues

- ResultPanel has settlement explanation but no explicit player-facing return route to main menu or expedition shell.
- Run screen uses `cancel` for modal close, but there is no dedicated pause/settings overlay for in-run state review.
- MapOverlay supports click actions but lacks a clear selected-cell/action feedback line after flag or teleport requests.
- Blocked reason appears as text, but there is no visual feedback pulse for rejected commands.

## Raw P2 Issues

- Settings shell is placeholder-only; dev diagnostics are not separated behind an enforceable dev-only policy.
- Art smoke contracts exist, but there is no G10 record proving a small manifest/registry/fallback path.
- Responsive/mobile behavior is mostly implicit fixed-position UI; no UILayoutProfile contract or narrow-screen strategy exists.
- Fact-source docs still need HEAD drift calibration from `eb9f5d6...` to `a13a6fa...`.

## Resolved During G10

- P1 ResultPanel return route: added player-facing return actions for main menu and expedition shell.
- P1 pause/settings overlay: added an in-run pause/settings overlay that does not write preferences or core state.
- P1 MapOverlay feedback: added selected-cell/action feedback for flag and teleport requests.
- P1 blocked reason feedback: added a short visual flash for rejected CommandResult feedback.
- P2 dev diagnostics gate: added a dev-only diagnostics shell with build-channel/UIVisibilityPolicy gating; it is hidden and disabled in the default player channel.
- P2 art smoke record: added a manifest asset_id registry with fallback checks for a small panel/button/icon/character/theme-overlay sample.
- P2 responsive contract: added `UILayoutProfile` and key panel profile hooks for desktop/narrow layout reservation.
- P2 fact-source drift: updated G10-facing baseline/status docs to use main `a13a6fae3208850ae43e4b511511e008eb311a3e` as the current base.

## Remaining After G10

- Complete final UI, full MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, and broad architecture reshaping remain out of scope.
- Responsive/mobile remains a reserved contract and key breakpoint smoke, not complete touch or orientation support.
- Art intake remains a small manifest/registry/fallback smoke, not a real art migration.
- Settings and dev diagnostics remain shell-only; no local preference persistence or external log writing was added.
