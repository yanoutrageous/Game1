# ART-18 Reference Driven Core UI Product Layout

## 0. Document Role

ART-18 is a reference-driven product layout rebuild for the core UI.
It follows ART-15/16/17 findings and does not represent final visual QA or ART-19 polish.

This stage did not authorize:

- Direct runtime reads from external art sources.
- Using confirmed full-screen Base images as runtime UI backgrounds.
- Gameplay rule changes.
- Git commit or push.

## 1. Boundary

Modified scope:

- `Godot/GraytailGodot/scripts/ui/**`
- `Godot/GraytailGodot/scripts/presentation/**`
- `tools/validate_art18_reference_driven_ui.ps1`
- `docs/art/**`
- `docs/art/validation/art18/**`

Unmodified / not touched as ART-18 product:

- `D:\AGAME1\sources\art`
- `D:\AGAME1\sources\draw`
- `D:\AGAME1\handoff\connection`
- `Godot/GraytailGodot/scripts/core/command/**`
- `Godot/GraytailGodot/scripts/core/save/**`
- `Godot/GraytailGodot/data/assets/asset_manifest.csv`

Existing dirty files from before ART-18 remain separate:

- `Godot/GraytailGodot/project.godot`
- `docs/README.md`
- `docs/INDEX.md`
- `docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`

## 2. References Used

Current canonical art source root:

- `D:\AGAME1\sources\art`

Reviewed references:

- `D:\AGAME1\sources\art\Base\主菜单示例.png`
- `D:\AGAME1\sources\art\Base\出发探索确定.png`
- `D:\AGAME1\sources\art\Base\长期系统确定.png`
- User corrected deploy / long-term sketch.
- User corrected Run HUD sketch.
- `D:\AGAME1\sources\art\ART-14\A1.png`
- `D:\AGAME1\sources\art\M1\Lua demo.mp4`
- `D:\AGAME1\sources\art\M1\scripts\ui\HUD.lua`
- `D:\AGAME1\sources\art\M1\scripts\ui\MapOverlay.lua`
- `D:\AGAME1\sources\art\M1\scripts\ui\UILayout.lua`

Reference conclusion:

- Base confirmed images define product finish direction.
- User sketches define region placement and proportions.
- Lua is used only for runtime UI logic and layer responsibility reference, not copied UI.
- Current Godot is treated as a baseline to rebuild.

## 3. Slice 0: Baseline And Target Contract

Changed:

- Added `docs/art/ART18_REFERENCE_DRIVEN_UI_LAYOUT_TARGET.md`.
- Added baseline Computer Use screenshots:
  - `docs/art/validation/art18/baseline_main_menu.png`
  - `docs/art/validation/art18/baseline_deploy_prep.png`
  - `docs/art/validation/art18/baseline_long_term.png`
  - `docs/art/validation/art18/baseline_run_hud.png`
  - `docs/art/validation/art18/baseline_map_overlay.png`

Validation:

- Real Godot project launched from `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`.
- Baseline showed usable but still panel-heavy product layout.

## 4. Slice 1: Layout Contract And Skin Kit

Changed:

- Updated `Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd`.
- Updated `Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd`.

Key changes:

- Run left rail ratio changed from 30% to 23%.
- Run left rail clamp changed to `292..430`.
- Added ART-18 target rectangles for main menu, deploy prep, long term, and Run HUD.
- Added explicit Run target rectangles for:
  - left info rail
  - gameplay viewport
  - top-right status card
  - bottom info
  - bottom key bar
  - map overlay

Validation:

- `git diff --check` passed.

## 5. Slice 2: Main Menu And Deploy Prep

Changed:

- `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd`

Main menu result:

- Kept full-screen background as first visual.
- Moved top shortcuts and right action deck to ART-18 target positions.
- Reduced opacity / mass of left hero masks so the background is less blocked.
- Preserved large right-side entry buttons and left hero / notice areas.

Deploy prep result:

- Moved primary tabs to top center.
- Kept left panel focused on character / readiness visual.
- Kept equipment and consumables in the right column.
- Moved right summary upward and grouped it into short modules.
- Kept continue / abandon directly above the large start button.
- Compressed route cards to title + state instead of repeated text blocks.

Computer Use screenshot:

- `docs/art/validation/art18/art18_main_menu_1280x720.png`
- `docs/art/validation/art18/art18_deploy_prep_1280x720.png`

## 6. Slice 3: Long Term

Changed:

- `Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd`

Result:

- Moved top tabs to the center top, matching the deploy page family.
- Left side remains character appearance / profile visual and includes appearance setup.
- Center is a collection wall.
- Right side is short archive modules for level, mainline, record, resources, and rewards.
- Removed the old detail-page feeling as the dominant layout.

Computer Use screenshot:

- `docs/art/validation/art18/art18_long_term_1280x720.png`

## 7. Slice 4: Run HUD And MapOverlay

Changed:

- `Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd`
- `Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd`

Run HUD result:

- Left rail is about 23% of 1280 width.
- Everything right of the left rail is game area except overlays.
- Top-right protocol / pressure remains a small status card.
- Bottom info and key bar are overlays and do not cut the gameplay viewport.
- Object interaction prompt remains a small floating prompt.

MapOverlay result:

- MapOverlay remains a temporary full-screen overlay.
- The dimmer opacity was reduced from 0.28 to 0.18.
- The panel opacity was reduced slightly while preserving map readability.
- It no longer represents a permanent right rail or third column.

Computer Use screenshots:

- `docs/art/validation/art18/art18_run_hud_1280x720.png`
- `docs/art/validation/art18/art18_map_overlay_1280x720.png`

## 8. Slice 5: Feedback And State

Changed:

- Added `tools/validate_art18_reference_driven_ui.ps1`.

Validation focus:

- Required ART-18 docs and screenshots.
- No direct runtime hardcode of external art source paths.
- No `Button.expand_icon = true`.
- No visible command key leak patterns such as `command.rejected`, `command.accepted`, or `message_key` in UI/presentation strings.
- Forbidden dirty paths remain blocked from ART-18 product scope.

Existing command feedback check:

- `run_ui_view_model.gd` already maps command result reasons to player-facing text and does not concatenate `message_key` into HUD feedback.

## 9. Slice 6: Screenshot QA

Completed Computer Use screenshots at current desktop-capturable 1280-level size:

- `docs/art/validation/art18/art18_main_menu_1280x720.png`
- `docs/art/validation/art18/art18_deploy_prep_1280x720.png`
- `docs/art/validation/art18/art18_long_term_1280x720.png`
- `docs/art/validation/art18/art18_run_hud_1280x720.png`
- `docs/art/validation/art18/art18_map_overlay_1280x720.png`

1600 / 1920 note:

- A 1600x900 Godot launch was attempted with `--resolution 1600x900`.
- Computer Use captured only a `1069x631` window in the current desktop environment.
- ART-18 does not claim 1600x900 or 1920x1080 Computer Use visual acceptance in this run.

## 10. Residual Issues

Remaining product gaps:

- Main menu still needs richer Base-style material polish.
- Deploy prep center cards are now less text-heavy but still not full visual map cards.
- Long term center wall is structurally correct but still uses simple card frames.
- Final 1600 / 1920 visual QA needs an environment that can capture those resolutions.
- ART-19 should focus on final material polish, richer slot imagery, hover/selected animation polish, and higher-resolution screenshot QA.

Not accepted as complete:

- Final character illustration.
- Final Base-level UI skins.
- Full animation / VFX polish.
- Full content implementation for long term systems.

## 11. Next Stage Gate

ART-18 should enter audit review with Computer Use screenshot comparison.
If accepted, a separate audit / acceptance frame should decide commit and push.
If rejected, the next prompt should target specific visual gaps rather than broad coordinate patching.
