# ART-18R Product UI Baseline Rework

## 0. Document Role

ART-18R is a visual/product baseline rework after ART-18. It does not change run rules, command authority, save rules, TruthMap, RunContext, or CommandBus semantics. It does not import new assets and does not authorize runtime reads from Base Art, Draw, or sources art.

## 1. Reference Review

Reference inputs:

- Base main menu, deploy prep, and long-term confirmed images.
- User run HUD sketch: left fixed rail, gameplay area to the right, top-right status card, bottom info and key bar overlays.
- Lua UI logic: left sidebar and top-right protocol card are persistent, bottom bar is overlay, MapOverlay is temporary full map layer.
- UE reference screenshot: `docs/art/validation/art18r/reference_ue_hud_1280x720.png`.

UE launch first showed `reference_ue_message_blocker.png` because the project path with spaces was not quoted. A second launch succeeded. The captured UE window was not exactly 1280x720, so it is used only as product-completion reference.

## 2. Slice Summary

Slice 0:

- Reconfirmed git root, branch, HEAD, dirty state, and protective stash.
- Added `ART18R_REFERENCE_COMPARISON_AND_REWORK_TARGET.md`.
- Defined target rects and layer responsibilities before code edits.

Slice 1:

- Strengthened shared Skin Kit panel/card/button material.
- Increased state contrast, border weight, padding, and selected/gold button readability.

Slice 2:

- Main menu right entry stack now has a solid board, stronger menu plates, and gold primary entry.
- Background remains visible as the first visual.

Slice 3:

- Deploy prep received route visual backing, stable short route labels, cleaned player-facing Chinese copy, and compact right summary modules.
- Existing model data is preserved; UI text prevents mojibake from leaking into route cards.

Slice 4:

- Long-term system received stronger collection wall cards, stable short archive labels, and cleaned right-side archive modules.
- Left character display and appearance action remain fixed.

Slice 5:

- Run HUD keeps the target structure: left rail plus large gameplay area, small top-right status card, bottom overlay information and key bar.
- MapOverlay is now a full-screen temporary map layer with clearer title, cells, border, and close hint.

Slice 6:

- Captured updated 1280 target screenshots in `docs/art/validation/art18r/`.
- Ran `git diff --check`.
- Ran Godot headless smoke.
- Added and ran ART18R validator.

## 3. Screenshot Results

Captured:

- `docs/art/validation/art18r/art18r_main_menu_1280x720.png`
- `docs/art/validation/art18r/art18r_deploy_prep_1280x720.png`
- `docs/art/validation/art18r/art18r_long_term_1280x720.png`
- `docs/art/validation/art18r/art18r_run_hud_1280x720.png`
- `docs/art/validation/art18r/art18r_map_overlay_1280x720.png`

The Windows capture surface returned 856x511 logical pixels for the Godot 1280x720 window. These screenshots still represent the 1280x720 Godot launch target, but ART-18R does not claim native 1600x900 or 1920x1080 capture completion in this execution run.

## 4. Current Visual Judgement

Main menu:

- Improved: button plates are more solid and the primary entry is clearly stronger.
- Remaining gap: still less finished than the UE/Base reference because final background/menu board art is not available in Godot runtime.

Deploy prep:

- Improved: route text is clean, center route area has stronger mission/map feel, right summary is readable.
- Remaining gap: route cards still rely on available icons and panels rather than final illustrated route thumbnails.

Long-term:

- Improved: collection wall and right archive modules are cleaner and no longer depend on long article text.
- Remaining gap: card art and archive detail imagery are still limited by current runtime assets.

Run HUD:

- Improved: target spatial structure is preserved and more readable.
- Remaining gap: left minimap and room markers need final art/state icon polish in a later pass.

MapOverlay:

- Improved: now clearly opens as a full map layer.
- Remaining gap: still grid-heavy; final iconography and map decoration should be completed with a later asset pass.

## 5. Boundaries

Modified scope stays in UI/presentation, docs, validation screenshots, and validator tooling. No commit or push was performed.

Generated side effects and pre-existing dirty files remain separated from ART-18R judgement.

## 6. Suggested Audit Focus

Audit should compare the ART18R screenshots directly against Base, user sketches, Lua logic, and UE reference:

- Does Run HUD still avoid a right-side permanent column?
- Does gameplay remain dominant outside the left rail?
- Are main menu buttons now closer to entity plates?
- Are deploy and long-term readable without mojibake or engineering copy?
- Does MapOverlay visibly open as a full map layer?

## 7. Remaining Work

Do not enter ART-19 from this execution frame. If ART-18R passes audit, the next work should be a separate stage for final art/icon/background polish and high-resolution screenshot coverage.
