# ART-18R Reference Comparison and Rework Target

## 0. Document Role

This document records the ART-18R target judgement before code rework. It is not a new gameplay contract and does not authorize new asset import. ART-18R keeps existing runtime assets and focuses on product UI layout, layer responsibility, and visual readability.

## 1. Current Baseline

Baseline screenshots:

- `docs/art/validation/art18/art18_main_menu_1280x720.png`
- `docs/art/validation/art18/art18_deploy_prep_1280x720.png`
- `docs/art/validation/art18/art18_long_term_1280x720.png`
- `docs/art/validation/art18/art18_run_hud_1280x720.png`
- `docs/art/validation/art18/art18_map_overlay_1280x720.png`

ART-18 fixed the broad structure, but the result still reads as line-frame UI. Main menu buttons, route cards, long-term collection cards, Run HUD panels, and MapOverlay cells need stronger material, state, and visual hierarchy.

## 2. Reference Logic

Priority:

1. Planning and current code decide function and data boundaries.
2. User sketches decide region ratio and UI placement.
3. Base confirmed images decide material direction, button scale, borders, and product finish.
4. TapTap and UE references indicate mature pixel UI layering, feedback, and completion.
5. Lua prototype is used only for UI responsibility logic, not for direct UI copying.

Lua HUD logic confirms:

- Left fixed rail is the only major persistent cutout.
- Everything right of the left rail is the gameplay area.
- The protocol/status card is a small top-right overlay.
- Bottom info and key bar are overlay layers, not a layout row that shrinks the room.
- MapOverlay is a temporary map layer with dimming, grid, selection feedback, and close hint.

## 3. Target Rects at 1280x720

Run HUD target:

| Region | Rect |
| --- | --- |
| left_info_rail | `x=0 y=0 w=292 h=720` |
| gameplay_viewport | `x=292 y=0 w=988 h=720` |
| top_right_status_card | `x=1052 y=22 w=210 h=112` |
| bottom_info_card | `x=430 y=586 w=560 h=44` |
| bottom_key_bar | `x=318 y=650 w=940 h=64` |
| map_overlay_region | `x=18 y=18 w=1244 h=684` |

Deploy Prep target:

- Left column: character and readiness visual only.
- Center top: first-level mode tabs, not intruding into the right column.
- Center: route cards with stronger map/mission visual weight.
- Right column: compact equipment, summary, risk, reward modules.
- Primary action: strong bottom-right start button; continue/abandon sit above it.

Long Term target:

- Left column: character appearance and appearance setting action.
- Center: collection/archive wall.
- Right column: fixed short archive modules such as level, mainline, records, resources, rewards.
- No long detail article in the center.

Main Menu target:

- Background is the first visual.
- Right entry buttons are solid menu plates, not transparent line buttons.
- Character, notice, resource, and key hints are auxiliary.

## 4. Layer Responsibilities

Page screens:

- BackgroundRoot: image/background tint only.
- DecorationRoot: page semantic decoration and low-opacity glow.
- CharacterRoot: character or profile display.
- MainContentRoot: main cards and product content.
- SideStatusRoot: compact right or notice modules.
- PrimaryActionRoot: main calls to action and navigation.
- FloatingInfoRoot: short tips only.
- OverlayRoot: temporary overlays.
- ModalRoot: blocking modal only.

Run HUD:

- RunGameStageRoot: room/background/player/object visuals.
- RunLeftInfoRailRoot: minimap, short stats, backpack entrance.
- RunTopRightStatusRoot: small protocol/status card only.
- RunFloatingInfoRoot: short current room/action summary.
- RunInteractionPromptRoot: small object-adjacent prompt.
- RunActionOverlayRoot: bottom info and key bar overlays.
- RunOverlayRoot: map overlay and temporary overlays.
- RunModalRoot: blocking modal only.

## 5. Rework Priorities

1. Upgrade component material: panel/button/card/slot/keycap states must stop reading as thin line frames.
2. Main menu: right entry buttons become solid physical plates with stronger highlight and icon control.
3. Deploy Prep: route cards gain mission/map visual weight; right summary modules become compact product blocks.
4. Long Term: collection wall and archive detail become structured, card-led modules.
5. Run HUD: keep left-rail-plus-gameplay structure while improving material and readability.
6. MapOverlay: become a formal map layer instead of a transparent table.

## 6. Non-Goals

- No new gameplay rule.
- No new asset import by default.
- No runtime dependency on Base Art, Draw, or sources art.
- No commit or push in this execution frame.
