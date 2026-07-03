# ART21R2 Slice 6 Deploy / Long Term ART19 Surface Report

## Status

PARTIAL. This pass reduces generated-looking inner UI boundaries on Deploy Prep
and Long Term, but it is not ART21R2 visual closeout.

## Scope

- No new generated art was introduced.
- No new draw slicing was required for this pass.
- Runtime surfaces reuse existing draw-derived ART19 assets already registered in
  `asset_manifest.csv`.
- Code changes only route panel/button StyleBoxTexture creation through manifest
  image assets; layout, text, input, and navigation ownership remain in code.

## Runtime Changes

- `Art10UISkinKit.style_box_from_asset_ref` now creates a `StyleBoxTexture`
  directly from a manifest asset reference.
- `DeployPrepShell` now applies ART19 image-backed surfaces to top tabs, filter
  chips, route cards, summary blocks, equipment slots, and action buttons.
- `LongTermShell` now applies ART19 image-backed surfaces to tabs, collection
  cards, detail blocks, and navigation/action buttons.
- The existing `DeployStartButton.pressed -> _on_start_preview_pressed()` route
  was not changed.
- Main menu Start Exploration still routes directly to Deploy Prep. No
  difficulty/map selection screen was added.

## Evidence

- `screenshots/slice6/godot_main_menu_art19_inner_surfaces_pass35_smoke.png`
- `screenshots/slice6/godot_deploy_prep_art19_inner_surfaces_pass35_smoke.png`
- `screenshots/slice6/godot_long_term_art19_inner_surfaces_pass35_smoke.png`
- `screenshots/slice6/godot_run_hud_from_deploy_art19_inner_surfaces_pass35_smoke.png`

## Remaining Gaps

- Deploy Prep still needs stronger route/map/task hierarchy and final text/icon
  fit.
- Long Term still has placeholder profile/archive copy and rough bottom detail
  slots.
- Page title treatment remains runtime text rather than source-art lettering.
- These screenshots are 856x511 smoke evidence, not full-resolution visual QA.

## Conclusion

The pass proves Deploy Prep and Long Term can use existing draw-derived ART19
image surfaces for inner boundaries while preserving the original click flow.
The result is `r2_partial`, not visually complete.
