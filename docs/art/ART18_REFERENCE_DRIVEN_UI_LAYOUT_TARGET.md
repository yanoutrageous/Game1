# ART-18 Reference Driven UI Layout Target

## 0. Document Role

This document records the ART-18 target layout and layer contract before code changes.
It is not a Godot import authorization, not a manifest change, and not a final visual QA pass.

ART-18 rebuilds the product layout for four core screens:

- Main menu
- Deploy prep
- Long term system
- Run HUD and MapOverlay

The target is reference-driven. Current Godot UI is treated as the baseline to improve, not as the source of truth.

## 1. Reference Priority

1. Design plan decides feature and information structure.
2. User sketches decide screen regions and UI position.
3. Base confirmed images decide material quality, borders, button scale, and product finish direction.
4. TapTap screenshots decide mature pixel UI hierarchy and completion benchmark.
5. UE prototype decides high-completion runtime reference.
6. Lua prototype decides runtime HUD, popup, map, and feedback rhythm.
7. Current Godot implementation is only a baseline to replace or reshape.

Current source-root note:

- The legacy `D:\AGAME1\Base Art` path is no longer the current canonical source path after G40.
- Current art references are under `D:\AGAME1\sources\art`.
- Runtime UI must not read directly from `D:\AGAME1\sources\art` or `D:\AGAME1\sources\draw`.

## 2. Slice 0 Baseline Evidence

Computer Use baseline screenshots:

- `docs/art/validation/art18/baseline_main_menu.png`
- `docs/art/validation/art18/baseline_deploy_prep.png`
- `docs/art/validation/art18/baseline_long_term.png`
- `docs/art/validation/art18/baseline_run_hud.png`
- `docs/art/validation/art18/baseline_map_overlay.png`

Observed baseline issues:

- Main menu has a visible background and usable button stack, but still reads as assembled panels rather than a productized Base-style menu.
- Deploy prep has the intended left/center/right family shape, but center route cards are still text-heavy and the right summary panel lacks visual hierarchy.
- Long term screen has the left profile, center collection wall, and right archive direction, but collection cards still behave like placeholder text cells.
- Run HUD is no longer a full left-middle-right debug layout, but the left rail is too visually dominant and the minimap block consumes too much vertical priority.
- MapOverlay is closer to a full map overlay, but it still visually inherits the HUD frame underneath and needs a clearer temporary-overlay contract.

## 3. Shared Layout Rules

All ART-18 screens should use a layout contract rather than scattered `Rect2` patches.

Base 1280x720 target:

- Outer safe margin: 24 px.
- Major panel gap: 12-18 px.
- Main visual layer must be visible before UI panels.
- Panels may frame content, but must not turn the screen into an opaque report page.
- Text should be grouped as labels, badges, short module summaries, or tooltip/detail content.
- Repeated engineering terms must not be exposed in player-facing UI.

Layer order:

1. Page background or game world.
2. Ambient / vignette / low-contrast decoration.
3. Persistent UI structure.
4. Content cards, buttons, tabs, slots.
5. Temporary overlays and object tips.
6. Modal overlays.
7. Cursor / focus / debug-only overlays.

## 4. Main Menu Target

Reference:

- `D:\AGAME1\sources\art\Base\主菜单示例.png`

1280x720 target rectangles:

| Region | Rect |
| --- | --- |
| background_scene | `x=0 y=0 w=1280 h=720` |
| title_cluster | `x=64 y=58 w=420 h=116` |
| hero_display | `x=64 y=200 w=280 h=320` |
| notice_strip | `x=64 y=540 w=560 h=74` |
| top_shortcuts | `x=760 y=62 w=430 h=44` |
| primary_action_deck | `x=760 y=148 w=430 h=390` |
| bottom_key_bar | `x=64 y=642 w=380 h=58` |

Responsibilities:

- The background is the first visual, not a hidden texture under opaque panels.
- The right action deck contains large, physical entry buttons.
- The left side anchors title, character/base mood, and a short announcement.
- The main menu must not look like a settings/debug list.

## 5. Deploy Prep Target

References:

- `D:\AGAME1\sources\art\Base\出发探索确定.png`
- User corrected deploy/long-term sketch.

1280x720 target rectangles:

| Region | Rect |
| --- | --- |
| background_scene | `x=0 y=0 w=1280 h=720` |
| left_character_panel | `x=32 y=88 w=280 h=596` |
| mode_switch_buttons | `x=32 y=28 w=280 h=42` |
| primary_tabs | `x=398 y=34 w=470 h=58` |
| secondary_filter_row | `x=372 y=104 w=526 h=44` |
| center_route_wall | `x=340 y=160 w=590 h=380` |
| center_detail_hint | `x=340 y=554 w=590 h=88` |
| right_summary_panel | `x=952 y=88 w=286 h=396` |
| right_action_cluster | `x=952 y=506 w=286 h=160` |

Responsibilities:

- Left panel is character / preparation visual only. Equipment and consumables live on the right.
- Primary tabs sit at the top center and must not intrude into the right summary column.
- Secondary filters must remain one row or become horizontally scrollable; they must not wrap and steal detail space.
- Continue / abandon actions sit just above the large start button.
- The line "选择路线" is not required if the card wall already communicates route selection.

## 6. Long Term Target

References:

- `D:\AGAME1\sources\art\Base\长期系统确定.png`
- User corrected deploy/long-term sketch.

1280x720 target rectangles:

| Region | Rect |
| --- | --- |
| background_scene | `x=0 y=0 w=1280 h=720` |
| left_character_archive | `x=32 y=88 w=280 h=596` |
| mode_switch_buttons | `x=32 y=28 w=280 h=42` |
| primary_tabs | `x=398 y=34 w=470 h=58` |
| collection_wall | `x=340 y=116 w=590 h=520` |
| right_archive_modules | `x=952 y=88 w=286 h=548` |
| appearance_button | `x=86 y=596 w=170 h=46` |

Responsibilities:

- Left side is character appearance / profile visual and includes a setup-appearance action.
- Center is a collection wall or archive grid, not a text detail page.
- Right side is fixed short archive modules: level, mainline, record, resources, rewards.
- The screen must not depend on long paragraph cards or repeated `[可查看]` labels.

## 7. Run HUD Target

References:

- User corrected Run HUD sketch.
- `D:\AGAME1\sources\art\ART-14\A1.png`
- `D:\AGAME1\sources\art\M1\Lua demo.mp4`
- Lua logic in `sources/art/M1/scripts/ui/HUD.lua`.

1280x720 target rectangles:

| Region | Rect |
| --- | --- |
| left_info_rail | `x=0 y=0 w=292 h=720` |
| gameplay_viewport | `x=292 y=0 w=988 h=720` |
| top_right_status_card | `x=1054 y=24 w=202 h=108` |
| object_tip | `dynamic, max w=260 h=72, near target object` |
| bottom_info_card | `x=412 y=590 w=620 h=44` |
| bottom_key_bar | `x=320 y=656 w=928 h=64` |
| map_overlay_region | `x=0 y=0 w=1280 h=720` |

Responsibilities:

- Left rail is fixed information: minimap, short status, inventory entry.
- Everything to the right of the left rail is game world unless temporarily covered by an overlay.
- There is no permanent right-side information column.
- Protocol / pressure is only a small top-right floating card.
- Bottom info and key bar are overlays; they must not shrink the room viewport.
- Object tips must stay small and near the object. They are not large central panels.
- MapOverlay is a temporary full-screen map layer. It may dim the game, but must be readable and visually separate from the persistent HUD rail.

## 8. Component Contract

The implementation should expose reusable tokens for:

- page background
- large action button
- compact button
- tab
- card
- slot
- badge
- keycap
- bottom key bar
- notice box
- selected glow
- locked overlay
- object tip
- modal panel

State coverage:

- normal
- hover
- selected
- disabled
- locked
- warning
- danger
- new
- reward
- ready

Implementation rule:

- Do not solve structure with one-off z-index patches.
- Do not use large opaque panels to hide layout failures.
- Do not depend on full-screen reference images as runtime UI.
- New art image integration must stay replaceable through slots, not hardcoded absolute source paths.

## 9. Slice 0 Receipt

Slice:

- Slice 0: context recovery, reference read, Computer Use baseline capture, target layout contract.

Changed:

- Added `docs/art/ART18_REFERENCE_DRIVEN_UI_LAYOUT_TARGET.md`.
- Added baseline screenshots under `docs/art/validation/art18/`.

Validation:

- Git root, branch, HEAD, dirty state, and protection stash were checked before screenshots.
- Real Godot project was launched from `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`.
- Baseline screenshots were captured through Computer Use.

Issue:

- Existing dirty files from governance/Godot editor state remain present and are not ART-18 products.
- Legacy `D:\AGAME1\Base Art` reference paths have moved; ART-18 uses `D:\AGAME1\sources\art` as current read-only source context.

Next:

- Slice 1 should turn this layout contract into reusable UI layout/profile/component code before page rebuild.
