# ART-21R1 Visual Gap Observation

## Scope

This observation was made before ART-21R1 code changes.

Branch at observation time:

```text
art/art21r1-ue-parity-existing-assets
base HEAD: da6943671da4a640a53a780bb77e81619cd95bc8
```

Existing dirty was not cleaned:

- `Godot/GraytailGodot/project.godot`
- `Godot/GraytailGodot/data/assets/asset_manifest.*.translation`

## Evidence

UE was launched from:

```text
D:\UE\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe
D:\A GAME\26.6\UE\Graytail\Graytail.uproject
```

Godot was launched from:

```text
D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
```

Screenshots:

| File | State | Resolution | Boundary |
| --- | --- | ---: | --- |
| `screenshots/ue_main_menu.png` | UE main menu | 1920x1105 | reference |
| `screenshots/ue_area_select.png` | UE area select | 1920x1105 | reference |
| `screenshots/ue_difficulty_select.png` | UE difficulty select | 1920x1105 | reference |
| `screenshots/ue_run_hud.png` | UE run HUD | 1920x1105 | reference |
| `screenshots/ue_map_overlay.png` | UE map overlay | 1920x1105 | reference |
| `screenshots/godot_main_menu_before.png` | Godot main menu before | 856x511 | smoke |
| `screenshots/godot_deploy_prep_before.png` | Godot deploy before | 856x511 | smoke |
| `screenshots/godot_long_term_before.png` | Godot long-term before | 856x511 | smoke |
| `screenshots/godot_run_hud_before.png` | Godot run HUD before | 856x511 | smoke |
| `screenshots/godot_map_overlay_before.png` | Godot map overlay before | 856x511 | smoke |
| `screenshots/godot_inventory_before.png` | Godot inventory before | 856x511 | smoke |
| `screenshots/godot_result_before.png` | Godot result before | 856x511 | smoke |

UE inventory / loot / event was not naturally triggered from the sampled initial run state.

## UE Layer Facts

| Area | Observed UE structure |
| --- | --- |
| Main menu | One full background scene carries the brand, building, path, character, portal, and right-side physical board. Text sits directly on wood/sign surfaces. Buttons are board planks, not generic UI panels. |
| Area select | Same background family; the large left hanging board changes title to area selection and the right physical board changes options. |
| Difficulty select | Same state machine and board family; no generic tooltip or floating panel is needed for core text. |
| Run HUD | Center world layer is the primary visual: real room art, player, doors, props. Left scan panel is fixed. Right top has compact protocol/status cards. Bottom key bar overlays the world and does not cut it away. |
| Map overlay | Modal dim layer over the run HUD, with a large centered grid and clear tile icons. It is not a transparent data table. |

## Godot Before Gaps

| Area | Observed Godot issue |
| --- | --- |
| Main menu | Background is present but heavily darkened and covered with generic panels. The right menu is a framed button list, not a physical board. Character and meta panels fight with the background instead of being structural scene elements. |
| Deploy prep | Uses many nested generic frames, per-row backplates, and hard-coded panels. It has left/center/right intent, but still reads as a tool UI instead of an authored page. |
| Long-term | Page-family structure exists, but collection cards and detail modules are mostly framed rectangles. The screen is acceptable for contract proof but below UE's physical-board floor. |
| Run HUD | World room is dim and visually subordinate. A permanent dark gameplay overlay, top text mask, prompt backplate, right fill layer, and multiple framed labels make the world layer feel like a background under UI. |
| Map overlay | Reads as a transparent spreadsheet over the HUD. It lacks UE's modal contrast, centered map body, and strong tile/icon hierarchy. |
| Inventory / Result | These can remain modal, but current modal styling is dense and text-heavy. Inventory opens through the action button, not a dedicated key. |

## Text And Backplate Policy Findings

- Main menu text should sit directly on board/plank images.
- Area and difficulty select text should sit directly on the same physical board family.
- Run HUD room title/body should not always live in a large top text box.
- Object prompt should appear only when state requires it and should be light.
- Bottom key/action prompts should be anchored to the key bar.
- Inventory, ground loot, result, and map overlay are valid modal/overlay cases.
- Left scan panel and right protocol cards are structural panels and should remain.

## Layout Root Cause

| Root cause | Evidence |
| --- | --- |
| Hard-coded `Rect2` | Main menu, deploy, long-term, and run surface place many visual nodes by fixed 1280x720 coordinates. At 856x511 capture scale, small text and framed modules crowd each other. |
| Container auto layout | Deploy and long-term rows/cards use containers inside framed regions; row text gets boxed repeatedly instead of using visual surfaces. |
| Generic panel reuse | ART-21 shared panel/frame assets are applied across unrelated page roles, so physical board / room / modal distinctions are weak. |
| Coarse contract | ART-21 has only one main-menu row and three run-HUD rows, which is not enough to express UE's board, plank, room, player, left rail, status card, and key bar slots. |
| Validator boundary | ART-21 validator proves contract/asset/consumer linkage, not UE visual parity. ART-21R1 needs side-by-side screenshot judgment. |

## Fix Classification

| Area | Classification | Rationale |
| --- | --- | --- |
| Run HUD | must rebuild | UE floor requires real room/player/props as main visual. A generated gameplay background cannot substitute. |
| Main menu route | targeted repair | Main menu needs cleaner physical-board presentation, but Godot's existing click contract must be preserved: `出发探索` routes directly to Deploy Prep. Area/difficulty/map selection belongs inside Deploy Prep, not as extra main-menu clicks. |
| Map overlay | must rebuild | Needs modal overlay and centered tile grid, not full-window transparent table. |
| Deploy | targeted repair | Keep left/center/right flow, reduce unnecessary text boxes and reuse existing panel/button assets more deliberately. |
| Long-term | targeted repair | Keep page family, reduce nested frame look. |
| Inventory / result | targeted repair | Modal is valid, but presentation should be cleaner and focus should return to Run HUD. |

## Gate Conclusion

Godot before ART-21R1 is below the UE prototype floor for main menu flow, Run HUD, and MapOverlay. ART-21R1 should proceed to code changes only after this observation, with priority:

1. Run HUD world-first rebuild.
2. Main menu state flow and board/plank presentation.
3. MapOverlay modal grid cleanup.
4. Deploy / long-term / modal cleanup without changing gameplay semantics.
