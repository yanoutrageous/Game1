# ART21 Main Menu Scene Validation

Status: PASS; ART21 closeout evidence complete without Computer Use.

## Evidence

| Evidence | Result |
| --- | --- |
| Master-matched clean plate | 1280x720 live background |
| Accepted composite master | versioned evidence only |
| Runtime PNG assets | 152 |
| Conservative decoded texture load | 10.40 MiB / 128 MiB gate |
| Live/interaction-reachable asset rows | 66 |
| Deferred/unmounted asset rows | 85 |
| Evidence-only asset rows | 1 |
| Main-menu entries | 4 |
| Live motion groups | 10 |
| Overlays | settings and exit |
| Route transitions | deploy and long-term |
| Required captures | 6 |

## Captures

- `art21_main_menu_1280x720_default.png`
- `art21_main_menu_1280x720_long_term.png`
- `art21_main_menu_1280x720_settings.png`
- `art21_main_menu_1280x720_exit.png`
- `art21_main_menu_1600x900_default.png`
- `art21_main_menu_1920x1080_default.png`

## Required Checks

- `tools/validate_art21_main_menu_scene.ps1`
- `tools/validate_art21_ui_placement_contract.ps1`
- `tools/validate_art20_ui_asset_pipeline.ps1`
- `tools/validate_art21r1_ue_parity.ps1`
- `tools/validate_g39_navigation_boundary.ps1`
- `tools/validate_art17_core_screen_layering.ps1`
- `Godot/GraytailGodot/tests/art21_main_menu_runtime_runner.gd`
- `git diff --check`

## Visual Acceptance Notes

- The live clean plate removes baked character, board, title/notice/menu copy,
  flag cloth, company banners, and flame cores before their overlays are added.
- Character and menu-board art are generated from master-matched atlases, then
  deterministically trimmed, transparency-cleaned, resized, hashed, and listed
  in the runtime asset contract.
- Chinese title, notice copy, and menu labels are engine rendered.
- The long-term entry is rectangular and visually associated with the company;
  it does not point toward the dungeon or out of the screen.
- Focus feedback follows actual board bounds and does not add duplicate hooks.
- All live character frames retain a common foot baseline.
- Settings and exit overlays use the shared UI layer contract.
- 16:9 output is captured at 1280x720, 1600x900, and 1920x1080.

## Motion Acceptance Notes

The runtime runner verifies ten mounted motion groups, independent timing,
focus direction, location linkage, transition routing, and reduced-motion
freeze/hide behavior. Optional puddle, whole-foliage, notice-paper, and walk
prototypes remain unmounted because their current form would reduce quality.

## Visual Verification Boundary

The user requested no Computer Use during this phase. The six versioned runtime
captures were inspected statically for text clipping, residual checkerboard or
separator lines, transparent-edge halos, architecture duplication, menu
direction semantics, character scale, and critical-entry occlusion. Default
focus is Deploy, so the 1280x720 default capture also supplies the required
Deploy-focus evidence. The inspection passed; no Computer Use claim is made.
