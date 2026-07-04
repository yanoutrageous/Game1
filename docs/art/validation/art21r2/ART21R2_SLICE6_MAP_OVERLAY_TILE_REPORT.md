# ART21R2 Slice 6 Map Overlay Tile Report

Status: PARTIAL

This report records the first Slice 6 Map Overlay tile pass. It does not mark
Map Overlay or ART21R2 complete.

## Scope

- Preserve the existing `M` keyboard route and map cell click behavior.
- Do not add a new map/difficulty screen to the main menu flow.
- Reuse existing draw-derived runtime assets before generating or cutting new
  art.
- Use the selected draw game-ready outputs before touching the purple root
  sheet directly.
- Improve large Map Overlay cell readability without changing TruthMap or run
  rules.

## Code Change

- `map_overlay_panel.gd`
  - Keeps the existing `_art21_marker_state()` state classification and
    `_select_marker()` click callback.
  - Routes most large Map Overlay cell states through
    `Art09ManifestAssetMapping.art19_map64_ref()`.
  - Uses the existing draw-derived ART19 64px runtime assets for `unknown`,
    `explored`, `scanned`, `player`, `exit`, `mine`, and `chest`.
  - Routes `flagged` and `event` through ART21R2 draw-cleaned marker visual
    keys from the Zujian2 lineage without changing `_select_marker()` or
    `cell_action_requested`.
  - Scales and centers only the high-resolution ART21R2 event/flag marker icons
    inside the existing map-cell buttons so the new cuts are visible instead of
    being clipped by the legacy icon slot.
  - Preserves `flagged` in `MiniMapViewModel.build_from_run_map_snapshot()` so
    existing flag state and map-cell click behavior can render through the
    ART21R2 flag visual key.
  - Pass36 keeps the same `M` route and cell click behavior, but changes the
    centered `Panel` frame to the already cut ART21R2 Zujian3 modal frame via
    `Art21UIPlacementContract.style_box_for_visual_key()`.
  - Pass41 keeps `_select_marker()` and `cell_action_requested` intact while
    applying the already cut ART21R2 Zujian3 modal title plate, section panel,
    and action strip assets to the Map Overlay title/detail/footer labels.
  - Pass41 reduces unknown-cell visual dominance by dimming the existing
    draw-derived unknown texture instead of replacing map click hitboxes or
    adding a generated cell backplate.
  - Pass41 adds an image-backed selected-cell style path through the existing
    ART19 selected frame asset, but this remains code-level partial evidence
    until a dedicated selected-state screenshot is captured.

## Source And Cutting Path

- Root source sheet: `D:\AGAME1\sources\draw\Zujian2.png`.
- Runtime candidates:
  `D:\AGAME1\sources\draw\30_game_ready\map_icon\map_icon_event.png` and
  `D:\AGAME1\sources\draw\30_game_ready\map_icon\map_icon_marker_flag.png`.
- The purple root sheet was not imported directly.
- Script: `tools/art21r2_cut_map_overlay_marker_assets.py`.
- Staging manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\map_overlay_marker_staging_manifest.csv`.
- Dry-run plan:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\map_overlay_marker_cut_dry_run_plan.csv`.
- Cut manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\map_overlay_marker_cut_manifest.csv`.
- Cut summary:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\map_overlay_marker_cut_summary.json`.
- The title/detail/footer hierarchy reuses existing Zujian3 modal-section
  cuts:
  `ui.art21r2.modal.title_plate`,
  `ui.art21r2.modal.section.panel`, and
  `ui.art21r2.modal.action_strip`. No new generated art was introduced for
  pass41.

The event marker was cleaned from 89 purple-like pixels to 0. The flag marker
was cleaned from 90 purple-like pixels to 0.

## Reproduction Route

- Start Godot with debug tools and `--art21r2-seed-map-markers`.
- Click the existing main-menu `Start Exploration` entry directly into Deploy
  Prep, then start the run.
- Press the existing `M` Map Overlay route. The smoke seed reveals the current
  run map, pins one debug-only Event cell, and toggles one flag only for
  deterministic screenshot evidence; it does not add a new main-menu
  map/difficulty step and does not replace the normal cell click callback.
- For the sparse evidence, start Godot with debug tools and
  `--art21r2-seed-map-sparse-markers`, then use the same existing main-menu
  entry, Deploy Prep confirm button, and `M` Map Overlay route. The sparse state
  does not call full-map reveal; it only prepares a few explored/scanned cells,
  one Event cell, and one flagged cell for deterministic visual evidence.
  Audit marker: sparse state does not call full-map reveal.
- Pass40 clicks the visible flagged cell in the Map Overlay and captures the
  same panel after the flag disappears, proving the existing map-cell click
  route still toggles flag state instead of only relying on seed output.

## Evidence

| Evidence | File | Result |
| --- | --- | --- |
| Map Overlay open pass27 smoke | `screenshots/slice6/godot_map_overlay_art19_map64_pass27_smoke.png` | `M` opens Map Overlay and cells render with draw-derived 64px stone/question tiles instead of the previous empty generated squares. |
| Map Overlay selected pass27 smoke | `screenshots/slice6/godot_map_overlay_art19_map64_selected_pass27_smoke.png` | Clicking a map cell still updates detail/selection feedback; interaction path is preserved. |
| Map Overlay Zujian3 panel frame pass36 smoke | `screenshots/slice6/godot_map_overlay_zujian3_panel_frame_pass36_smoke.png` | The centered map panel now uses the ART21R2 Zujian3 modal frame while preserving the existing `M` open path. |
| Map Overlay event/flag marker pass38 smoke | `screenshots/slice6/godot_map_overlay_art21r2_event_flag_pass38_smoke.png` | Event and flagged states resolve ART21R2 draw-cleaned markers while preserving the existing `M` open path and cell click behavior. |
| Map Overlay sparse event/flag pass39 smoke | `screenshots/slice6/godot_map_overlay_art21r2_sparse_event_flag_pass39_smoke.png` | Existing `M` route opens a sparse state with only a few explored/scanned cells plus one Event and one Flag marker; this is not full-map reveal evidence. |
| Map Overlay sparse flag click pass40 smoke | `screenshots/slice6/godot_map_overlay_art21r2_sparse_flag_click_pass40_smoke.png` | Clicking the flagged map cell through the existing button route removes the Flag marker while preserving the Event marker and the centered panel. |
| Map Overlay hierarchy pass41 smoke | `screenshots/slice6/godot_map_overlay_hierarchy_pass41_smoke.png` | Existing main-menu direct Deploy Prep route and `M` Map Overlay route open a centered map panel with ART21R2 title/detail/footer plates and dimmed unknown cells; this remains 856x511 partial hierarchy evidence. |

## Verdict

PASS for this detail:

- Large Map Overlay cell visuals now use existing draw-derived runtime assets
  for most states.
- Event and flagged states now use ART21R2 draw-cleaned markers from selected
  Zujian2 game-ready outputs.
- The large centered panel frame now uses an existing draw-sliced ART21R2 modal
  frame instead of the previous generated terminal panel look.
- The title/detail/footer surfaces now reuse formal ART21R2 Zujian3 modal
  section cuts, and unknown cells are visually de-emphasized without changing
  cell click routing.
- Existing `M` input and cell click handling remain intact.
- No generated replacement art was introduced.

PARTIAL for the larger ART21R2 target:

- Pass39 is more readable than the full reveal pass, but it is still
  deterministic smoke evidence, not natural long-run exploration proof.
- Unknown cells are now readable but the full reveal pass still shows a dense
  10x10 question-mark wall.
- Footer/title hierarchy is improved by pass41 image plates but still reads as
  partial UI composition rather than final map art.
- Event/flag marker source is resolved for this pass, but selected-state
  hierarchy still needs a dedicated screenshot and art pass.
- This is 856x511 smoke evidence, not final high-resolution QA.
