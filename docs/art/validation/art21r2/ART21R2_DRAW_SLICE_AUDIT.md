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
