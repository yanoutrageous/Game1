# ART21R2 Draw Slice Audit

## Scope

This audit records the ART21R2 rule that missing UI art must first check
`D:\AGAME1\sources\draw` for sliceable source material. It does not mark any
visual slot complete.

## Findings

- Raw sheets such as `1.png`, `2.png`, `3.png`, `4.png`, `5.png`, `6.png`,
  `Zuhe.png`, `Zuhe2.png`, `Zujian1.png`, `Zujian2.png`, and `Zujian3.png`
  contain a strong magenta/purple background and cannot be imported directly as
  runtime UI assets.
- `10_working/candidates/**` contains many crops with purple edge or background
  remnants. These are slice sources, not direct runtime-ready assets.
- `20_processed/**` and `30_game_ready/**` contain the already selected and
  cleaned assets. These should be preferred before generating new UI art.
- `30_game_ready/icons/64/**` is already represented in the runtime manifest as
  `ui.art19.map64.*` and is acceptable for ART21R2 minimap/map-overlay evidence.
- `30_game_ready/map_tile_icon/map_tile_unknown.png` is a valid sliced asset,
  but its large question mark is not suitable for a dense 10x10 in-run minimap
  without a dedicated HUD-size cut.

## Existing Slice Process To Reuse

The earlier ART19R1 / ART20 pipeline is the governing precedent for ART21R2
draw-source reuse:

- `docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.md` defines source,
  crop rectangle, output size, 9-slice, state set, runtime path, `asset_id`, and
  `visual_key` before runtime import.
- `docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.md` separates
  `confirmed_existing`, `confirmed_existing_set`, `needs_source_selection`, and
  `needs_visual_fit_review`. The last two cannot be imported without a separate
  source-selection decision.
- `D:\AGAME1\sources\draw\_manifest\asset_inventory.md` already classifies the
  magenta-background root sheets. `5.png` and other deploy/UI sheets were split
  into candidates rather than imported as whole images.
- `D:\AGAME1\sources\draw\_manifest\deploy_ui_assets_review.md` records the
  supplemental `5.png` flow: magenta sheet -> auto/manual candidates ->
  A-level game-ready assets -> B-level processed-only references.
- `tools/art20_cut_ui_assets.py` is the closest reusable implementation model:
  default dry-run, explicit `--write-cut-output`, `staging_manifest.csv` input,
  `alpha_bounds` / `magenta_pixels` metadata, guarded output root, same-hash
  idempotence, `cut_manifest.csv`, `cut_blocked_or_review.csv`, and gallery.
- `docs/art/validation/art20/ART20_SLICE4_RUNTIME_IMPORT_REPORT.md` confirms
  that cut output alone is not runtime approval. Import only happened for
  single `asset_id` / `visual_key` rows that were not governance-review,
  not unresolved multi-candidate rows, and not pending manual 9-slice review.

For ART21R2 this means a purple-background source must pass through the same
admission -> dry-run -> cut output -> manifest -> runtime import -> screenshot
sequence. A candidate crop with purple remnants is not runtime-ready evidence.

## Current Scan Snapshot

- `D:\AGAME1\sources\draw` excluding `debug_detected_boxes.png`: 948 PNG files.
- Root source sheets: 23 total, 15 require slicing or background cleanup before
  any runtime use.
- `10_working/candidates`: 542 total, 156 likely need further slicing or
  background cleanup, and 384 need purple-trace review.
- `20_processed`: 176 total, 0 large purple-background assets, 4 purple-trace
  review items.
- `30_game_ready`: 139 total, 0 large purple-background assets, 1 purple-trace
  review item.

## ART21R2 Decision

- Do not directly generate replacement minimap art while draw-derived runtime
  candidates exist.
- Use existing draw-derived runtime assets for current-cell and state overlays
  where they improve readability.
- If a slot still needs new art, first cut or clean the purple-background draw
  source into a transparent runtime candidate, then update manifest and evidence.
- Do not treat ART20 blocked rows as imported assets. In particular,
  `map_overlay_cell_64_set` and `map_overlay_event_marker_64` still require a
  fresh source-selection/cutting path before they can be claimed complete.

## Applied ART21R2 HUD Minimap Pass

- Source set: `D:\AGAME1\sources\draw\30_game_ready\icons\32`.
- External cut/import record:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\minimap_hud_cut_manifest.csv`.
- Runtime target: `Godot/GraytailGodot/assets/ui/art21r2/minimap`.
- Imported states: `player`, `explored`, `scanned`, `mine`, `chest`, `exit`.
- Unknown cells intentionally stay on the existing blank ART21 tile for the Run
  HUD so the left rail does not regress into a dense question-mark wall.
- Flag and event are not claimed as solved by this pass. Event remains a
  source-selection issue from ART20 and must not be marked complete.
- Evidence screenshot:
  `screenshots/slice3/godot_run_hud_after_slice3_minimap_hud32_pass16_smoke.png`.
- Result: `PARTIAL`. The imported 32px player marker is visible in the smoke
  screenshot, but the 10x10 HUD minimap remains dense and below the UE floor.

## Applied ART21R2 Map Overlay Tile Pass

- Source set: existing `D:\AGAME1\sources\draw\30_game_ready\icons\64`
  imports already registered as `ui.art19.map64.*`.
- Runtime target: `Godot/GraytailGodot/assets/ui/art19/map64`.
- Applied states: `unknown`, `explored`, `scanned`, `player`, `exit`, `mine`,
  and `chest`.
- `flagged` and `event` stay on the existing ART21 map assets because ART20
  left `map_overlay_event_marker_64` blocked and there is no approved ART19 64px
  event/flag runtime asset in the current manifest.
- Evidence screenshots:
  `screenshots/slice6/godot_map_overlay_art19_map64_pass27_smoke.png` and
  `screenshots/slice6/godot_map_overlay_art19_map64_selected_pass27_smoke.png`.
- Result: `PARTIAL`. The map cells are no longer the small generated empty
  ART21 squares, but the modal frame and dense unknown-cell wall still fall below
  the UE-floor Map Overlay target.

## Applied ART21R2 Modal Frame Pass

- Source sheet: `D:\AGAME1\sources\draw\Zujian3.png`.
- Source candidate:
  `D:\AGAME1\sources\draw\10_working\candidates\Zujian3\Zujian3_candidate_001.png`.
- Dedicated ART21R2 manifests:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_staging_manifest.csv`,
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_cut_dry_run_plan.csv`,
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_cut_manifest.csv`, and
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_cut_summary.json`.
- Runtime target: `Godot/GraytailGodot/assets/ui/art21r2/modal`.
- Imported slots: `inventory_panel_frame`, `ground_loot_panel_frame`, and
  `result_modal_frame`.
- The first cleanup threshold left visible purple fringe in preview, so it was
  not accepted. The final script rule reduced purple-like pixels from 3690 to 0
  and then overwrote only the same-turn generated modal PNGs with `--force`.
- Evidence screenshots:
  `screenshots/slice6/godot_inventory_zujian3_modal_frame_pass28_smoke.png`,
  `screenshots/slice6/godot_ground_loot_zujian3_modal_frame_pass28_smoke.png`,
  and `screenshots/slice6/godot_result_zujian3_modal_frame_pass28_smoke.png`.
- Result: `PARTIAL`. The modal frame material is now draw-sliced and
  image-owned, but row buttons, result buttons, title treatment, and typography
  remain below the UE/Base floor.

## Applied ART21R2 Modal Control Pass

- Source sheet: `D:\AGAME1\sources\draw\Zujian3.png`.
- Source candidates:
  `D:\AGAME1\sources\draw\10_working\candidates\Zujian3\Zujian3_candidate_005.png`
  for normal rows/buttons and
  `D:\AGAME1\sources\draw\10_working\candidates\Zujian3\Zujian3_candidate_008.png`
  for danger buttons.
- Dedicated ART21R2 manifests:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_staging_manifest.csv`,
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_cut_dry_run_plan.csv`,
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_cut_manifest.csv`,
  and
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_control_cut_summary.json`.
- Runtime target: `Godot/GraytailGodot/assets/ui/art21r2/modal`.
- Imported roles: modal item row normal, modal primary button, modal secondary
  button, and modal danger button.
- Candidate 005 cleanup: purple-like pixels 1297 -> 0. Candidate 008 cleanup:
  purple-like pixels 1184 -> 0.
- Evidence screenshots:
  `screenshots/slice6/godot_inventory_zujian3_modal_controls_pass29_smoke.png`,
  `screenshots/slice6/godot_ground_loot_zujian3_modal_controls_pass29_smoke.png`,
  and `screenshots/slice6/godot_result_zujian3_modal_controls_pass30_smoke.png`.
- Result: `PARTIAL`. The modal control boundaries are image-owned, but the
  current live run does not prove non-empty inventory/ground-loot rows, and
  result button contrast remains weak.
