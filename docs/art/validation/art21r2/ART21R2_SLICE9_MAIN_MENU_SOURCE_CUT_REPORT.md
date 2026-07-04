# ART21R2 Slice 9 Main Menu Source Cut Report

Status: `NOT_COMPLETE_R2_PARTIAL`

## Scope

Slice 9 addresses only the Main Menu title-board and right-side entry plank source ownership. It does not close out Main Menu, Long Term, Deploy Prep, Map Overlay, or ART21R2.

The route rule remains unchanged: `Start Exploration -> Deploy Prep` is direct. No area, map, or difficulty selection screen was added.

## Source Decision

Accepted source:
- `D:\AGAME1\sources\draw\Main.png`

Rejected for this slice:
- `D:\AGAME1\sources\draw\5.png`: useful for Deploy/LongTerm page-family panels and buttons, but not a dedicated Main Menu plank source.
- `D:\AGAME1\sources\draw\Zujian3.png`: useful for modal/panel/button family; continuing to use it for Main Menu planks would keep the Slice 8 modal-button borrow.

No finished `灰尾回收` title-lettering asset was found in the reviewed draw/base source roots. Therefore the Main Menu title text remains runtime text and the title row remains incomplete.

## Cut Outputs

Tool:
- `tools/art21r2_cut_main_menu_assets.py`

Manifests:
- `D:\AGAME1\sources\art\ART-21R2\_manifest\main_menu_staging_manifest.csv`
- `D:\AGAME1\sources\art\ART-21R2\_manifest\main_menu_cut_dry_run_plan.csv`
- `D:\AGAME1\sources\art\ART-21R2\_manifest\main_menu_cut_manifest.csv`
- `D:\AGAME1\sources\art\ART-21R2\_manifest\main_menu_cut_summary.json`

Runtime assets:
- `ui.art21r2.main_menu.title_board`
- `ui.art21r2.main_menu.board_header`
- `ui.art21r2.main_menu.entry_plank.deploy`
- `ui.art21r2.main_menu.entry_plank.long_term`
- `ui.art21r2.main_menu.entry_plank.settings`
- `ui.art21r2.main_menu.entry_plank.exit`

All cut rows record `purple_like_after=0`.

The title-board cut uses a source-silhouette alpha mask to remove non-board sky from the Main.png crop. This fixes the invalid rectangular sky overlay found during the first pass48 candidate check.

## Runtime Evidence

Screenshots:
- `screenshots/slice9/godot_main_menu_main_png_planks_pass48_smoke.png`
- `screenshots/slice9/godot_deploy_prep_direct_from_main_pass49_smoke.png`

Observed results:
- pass48 shows Main.png-derived title board/header/entry planks on the Main Menu.
- pass49 shows clicking `Start Exploration` directly enters Deploy Prep.
- No intermediate area, map, or difficulty page appears.
- The click path still uses the existing entry button pressed signal and `_emit_entry(entry)` route.

## Remaining Gaps

- Main Menu title lettering is still runtime text, not a finished title/sign asset.
- Entry text/icon fit and hover/pressed state presentation are still partial.
- Evidence remains 856x511 smoke-level, not high-resolution QA.
- This slice does not address Long Term left-role cleanup, Deploy Prep visual hierarchy, Run HUD, Map Overlay density, or Result.

## Conclusion

Slice 9 is a source-ownership improvement for the Main Menu plank surfaces. It replaces the Slice 8 modal-control borrow with Main.png source-derived cuts while preserving the direct `Start Exploration -> Deploy Prep` route.

This is still `NOT_COMPLETE_R2_PARTIAL`.
