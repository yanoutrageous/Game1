# ART21R2 Slice 6 Map Overlay Tile Report

Status: PARTIAL

This report records the first Slice 6 Map Overlay tile pass. It does not mark
Map Overlay or ART21R2 complete.

## Scope

- Preserve the existing `M` keyboard route and map cell click behavior.
- Do not add a new map/difficulty screen to the main menu flow.
- Reuse existing draw-derived runtime assets before generating or cutting new
  art.
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
  - Leaves `flagged` and `event` on the existing ART21 map assets because the
    ART20 `map_overlay_event_marker_64` source remained blocked and no approved
    ART19 64px event/flag replacement exists in the current manifest.
  - Pass36 keeps the same `M` route and cell click behavior, but changes the
    centered `Panel` frame to the already cut ART21R2 Zujian3 modal frame via
    `Art21UIPlacementContract.style_box_for_visual_key()`.

## Evidence

| Evidence | File | Result |
| --- | --- | --- |
| Map Overlay open pass27 smoke | `screenshots/slice6/godot_map_overlay_art19_map64_pass27_smoke.png` | `M` opens Map Overlay and cells render with draw-derived 64px stone/question tiles instead of the previous empty generated squares. |
| Map Overlay selected pass27 smoke | `screenshots/slice6/godot_map_overlay_art19_map64_selected_pass27_smoke.png` | Clicking a map cell still updates detail/selection feedback; interaction path is preserved. |
| Map Overlay Zujian3 panel frame pass36 smoke | `screenshots/slice6/godot_map_overlay_zujian3_panel_frame_pass36_smoke.png` | The centered map panel now uses the ART21R2 Zujian3 modal frame while preserving the existing `M` open path. |

## Verdict

PASS for this detail:

- Large Map Overlay cell visuals now use existing draw-derived runtime assets
  for most states.
- The large centered panel frame now uses an existing draw-sliced ART21R2 modal
  frame instead of the previous generated terminal panel look.
- Existing `M` input and cell click handling remain intact.
- No generated replacement art was introduced.

PARTIAL for the larger ART21R2 target:

- Unknown cells are now readable but visually dense as a 10x10 question-mark
  wall.
- Footer/title hierarchy still reads as UI placeholder text, not final map art.
- `flagged` and `event` remain on non-final ART21 assets and are not claimed as
  solved.
- This is 856x511 smoke evidence, not final high-resolution QA.
