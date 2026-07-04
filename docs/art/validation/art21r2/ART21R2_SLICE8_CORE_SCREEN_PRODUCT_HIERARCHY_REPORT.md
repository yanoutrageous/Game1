# ART21R2 Slice 8 - Core Screen Product Hierarchy Pass

Status: `NOT_COMPLETE_R2_PARTIAL`

This slice improves core screen hierarchy and route evidence for Main Menu and
Long Term while preserving the existing Deploy Prep and in-run Map Overlay
paths. It is not ART21R2 closeout.

## Boundary

- No generated replacement art was introduced.
- No root purple sheet was imported directly.
- No main-menu area, difficulty, or map-selection screen was added.
- `Start Exploration` still routes directly to Deploy Prep.
- Run HUD `M` still opens the in-run Map Overlay.
- This slice records 856x511 smoke evidence only, not high-resolution visual QA.

## Runtime Changes

- `MainMenuShell` now adds image-backed title/header/entry plates using existing
  ART21R2 draw-sliced modal title, section, and button assets.
- `MainMenuShell` keeps transparent hitbox buttons and preserves
  `button.pressed -> _emit_entry(entry)` for all entries.
- `MainMenuShell` now wires up/down/left/right focus wrapping and grabs initial
  focus on `deploy`.
- `LongTermShell` now separates the center collection wall from a center detail
  preview block, matching the corrected page-family structure:
  left character/profile, center long-term content plus detail, right archive
  and global status.
- `LongTermShell` reduces the visible card wall to a more readable 3x2 grid and
  wires focus between tabs and cards.

## Evidence

- `screenshots/slice8/godot_main_menu_product_hierarchy_pass43_smoke.png`
- `screenshots/slice8/godot_deploy_prep_route_guard_pass44_smoke.png`
- `screenshots/slice8/godot_long_term_product_hierarchy_pass45_smoke.png`
- `screenshots/slice8/godot_run_hud_route_guard_pass46_smoke.png`
- `screenshots/slice8/godot_map_overlay_route_guard_pass47_smoke.png`

## Contract and Matrix Updates

- `ui_placement_contract_v3.csv` now records Main Menu title and entry plates,
  Long Term center content detail, and Slice 8 screenshots.
- `ART21R2_SLOT_GAP_MATRIX.csv` now records the remaining Main Menu dedicated
  title/plank source gap and Long Term page-family hierarchy gap.
- `ART21R2_SOURCE_SLOT_CUTTING_MATRIX.csv` now classifies Main Menu modal
  button reuse as formal draw-cut-ready material borrowed for the main-menu
  slot, not final plank art.
- `asset_manifest.csv` consumer fields now include the new Main Menu and Long
  Term consumers for the affected ART21R2/ART19 assets.

## Remaining Gaps

- Main Menu title lettering is still runtime text; a dedicated title/sign source
  or cut is still required before claiming title completion.
- Main Menu entry plates currently borrow modal button material; they need
  dedicated plank/menu button source selection or cuts.
- Long Term still uses ART21 generated outer frames and borrowed ART19 inner
  surfaces; profile, rewards, archive, and bottom detail slots are still rough.
- Deploy Prep and Run HUD are only route-guarded in this slice.
- Map Overlay remains partial; pass47 only proves the `M` path still works after
  Slice 8 changes.

## Conclusion

Slice 8 improves product hierarchy and input/focus evidence for Main Menu and
Long Term, while keeping Deploy Prep direct routing and in-run Map Overlay
routing intact. ART21R2 remains `NOT_COMPLETE_R2_PARTIAL`.
