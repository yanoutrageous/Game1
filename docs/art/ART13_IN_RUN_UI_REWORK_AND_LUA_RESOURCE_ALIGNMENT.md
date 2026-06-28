# ART-13 In-Run UI Rework and Lua Resource Alignment

## 0. Document Position

ART-13 records the in-run UI execution pass for Game1 / GraytailGodot. It covers HUD structure, minimap and map overlay readability, M3 item-loop presentation, and alignment with the Lua prototype resource distribution.

This document is not a Godot import approval for full-screen reference images. It does not authorize direct runtime reads from Base Art, Draw, or Connection. It also does not move the project into ART-14.

## 1. Inputs and Boundaries

Authoritative Godot project:

```text
D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
```

Reference-only material:

```text
D:\AGAME1\Base Art\ART-13
D:\AGAME1\Base Docs
https://github.com/yanoutrageous/Game.git
```

The first four ART-13 images are used as the layout reference for the in-run room, scanner map, map overlay, and HUD density. The later menu / long-term images are used only for shared visual language such as panel weight, key buttons, metal / wood borders, card rhythm, and locked / selected states.

## 2. Base Docs Rules Applied

The ART-13 pass preserves these product constraints:

- The in-run minimap is a core gameplay system, not decoration.
- HUD must expose health, combat pressure, protocol / pressure, black coin / safe yield, monster or encounter state, leave / search / clear availability, and item-loop feedback.
- UI reads ViewModel / snapshot and sends Command requests. It does not read TruthMap, RunContext, Ledger, or CommandBus internals directly.
- Debug UI and player-facing UI stay separated.
- M3 item-loop presentation must support GroundLoot, Inventory, pickup, drop, use, blocked capacity / weight feedback, and reward / settlement distinction.

## 3. Lua / Game.git Reference

Lua prototype references used:

- `scripts/ui/HUD.lua`: four-region in-run HUD with left scanner, right protocol / event state, and bottom key bar.
- `scripts/ui/MiniMap.lua`: compact scan map with current position, unknown / explored states, and icon-based cell state.
- `scripts/ui/MapOverlay.lua`: expanded map with larger grid, selectable cells, status detail, and map operations.
- `scripts/ui/UITheme.lua` and `scripts/ui/UILayout.lua`: shared UI resource and layout vocabulary.
- `scripts/scenes/DungeonRoom.lua`: central room as playable visual focus.

Resource distribution reference:

```text
assets/ui/common
assets/ui/deploy
assets/ui/hud
assets/ui/keys
assets/Textures/generated/icons
assets/Textures/generated/characters
assets/Textures/generated/props
```

No `.uasset` file was imported. No full-screen ART-13 reference image was used as runtime UI.

## 4. Slice 0 Baseline

Baseline screenshots:

```text
docs/art/validation/art13/baseline_main_menu_or_current.png
docs/art/validation/art13/baseline_deploy_prep.png
docs/art/validation/art13/baseline_hud_normal.png
docs/art/validation/art13/baseline_search_feedback.png
docs/art/validation/art13/baseline_map_overlay.png
docs/art/validation/art13/baseline_inventory.png
docs/art/validation/art13/baseline_ground_loot.png
```

Baseline findings:

- The original in-run HUD over-weighted left and right information columns and reduced the room's visual priority.
- Search / interaction feedback leaked English or internal-style command text in some states.
- Map overlay was present but too small and visually secondary for a core gameplay system.
- Inventory / GroundLoot could be reached, but presentation was too close to diagnostic item metadata.

## 5. Slice 1 HUD Structure

Modified files:

```text
Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd
Godot/GraytailGodot/scripts/ui/run_surface/run_surface_model.gd
Godot/GraytailGodot/scripts/ui/shell/run_ui_view_model.gd
```

Result:

- Rebuilt the in-run structure toward left scanner, central room, compact right state panels, and bottom action bar.
- Reduced permanent explanatory copy in the side panels.
- Moved command feedback into short player-facing copy.
- Added UI-layer masking for the player tag so the visible runtime label is product-facing instead of raw scene text.

Validation screenshots:

```text
docs/art/validation/art13/slice1_hud_normal_1280x720_window.png
docs/art/validation/art13/slice1_search_feedback_1280x720_window.png
docs/art/validation/art13/slice1_hud_after_label_mask.png
docs/art/validation/art13/slice1_search_feedback_after_copy_fix.png
```

## 6. Slice 2 Minimap and Map Overlay

Modified files:

```text
Godot/GraytailGodot/scripts/ui/minimap/minimap_panel.gd
Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd
```

Result:

- Increased minimap and overlay cell readability.
- Changed map overlay title and feedback from internal command style to player-facing map language.
- Preserved map operations as UI requests; no TruthMap or core run semantics were changed.

Validation screenshots:

```text
docs/art/validation/art13/slice2_map_overlay_1280x720_window.png
docs/art/validation/art13/slice2_map_overlay_after_copy_fix.png
```

## 7. Slice 3 Room Visual and Resource Alignment

No new runtime image import was required in this pass. The room visual continues to use existing manifest-backed Godot runtime assets and the current room scene composition.

The structural alignment was handled in UI layout and presentation:

- Central room remains the largest visual subject.
- Room / event / combat summaries are attached to the room context instead of dominating both side rails.
- ART-13 room-reference direction is represented through layout priority, not by importing the reference image as a background.

## 8. Slice 4 M3 Item Loop UI

Modified files:

```text
Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd
Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd
Godot/GraytailGodot/scripts/ui/shell/run_ui_view_model.gd
```

Result:

- Inventory summary now separates backpack use, black coin, safe yield, long-term gold preview, item count, and equipment count.
- Item display and tooltip copy was shortened and localized for player-facing use.
- GroundLoot guidance uses player-facing pickup / capacity language instead of command or backend terms.
- Reward and result copy distinguishes black coin, safe yield, long-term gold, inventory moves, equipment, and ground items.

Validation screenshots:

```text
docs/art/validation/art13/slice4_inventory_1280x720_window.png
docs/art/validation/art13/slice4_ground_loot_1280x720_window.png
```

## 9. Slice 5 Shared Visual Language

The pass reused the existing Skin Kit / presentation vocabulary and tightened the in-run UI without rebuilding menu or long-term screens in this stage.

Borrowed from the additional two reference images:

- heavier panel framing,
- compact key buttons,
- selected / warning color emphasis,
- readable card and slot density.

Not copied:

- menu structure,
- long-term system content structure,
- full-screen reference art,
- any asset outside manifest-backed runtime paths.

## 10. Slice 6 Validation and QA

Validation script:

```text
tools/validate_art13_in_run_ui.ps1
```

Final QA screenshot targets:

```text
docs/art/validation/art13/final_hud_1280x720.png
docs/art/validation/art13/final_search_feedback_1280x720.png
docs/art/validation/art13/final_inventory_1280x720.png
docs/art/validation/art13/final_ground_loot_1280x720.png
docs/art/validation/art13/final_map_overlay_1280x720.png
docs/art/validation/art13/final_hud_1600x900.png
docs/art/validation/art13/final_inventory_or_ground_loot_1600x900.png
docs/art/validation/art13/final_map_overlay_1600x900.png
docs/art/validation/art13/final_hud_1920x1080.png
docs/art/validation/art13/final_map_overlay_1920x1080.png
```

Computer Use capture on this machine reports scaled window images because of Windows display scaling. The launched Godot resolution remains the requested validation resolution.

## 11. Resources and Manifest

ART-13 did not add new image assets and did not modify `asset_manifest.csv` in the current execution pass.

Manifest validation remains required:

- CSV must parse.
- `asset_id` values must not duplicate.
- If manifest is modified later, every `res://` path must exist.

## 12. Generated Side Effects

Godot may create or update generated files such as:

```text
.godot
*.uid
*.import
*.translation
project.godot
```

These are not automatically ART-13 deliverables. They must be reviewed by the audit / acceptance frame before staging.

## 13. Temporary External Dirty State

The worktree currently also contains an ART-11R2 hotfix screenshot artifact:

```text
docs/art/validation/art11r2/final_self_check_run_hud_interaction_after_hotfix3.png
```

That artifact is not part of ART-13. It is kept separate and should be judged by the ART-11R2 audit flow.

## 14. Remaining Gaps Deferred to ART-14

- Final character / monster art direction.
- Richer room prop states and animation.
- Fully polished combat / event object affordances.
- Full settlement / warehouse polish beyond M3-loop readability.
- Final global art QA after audit feedback.

## 15. ART-13 Exit Condition

ART-13 can enter audit when:

- the validation script passes without blocking errors,
- final Computer Use screenshots exist for required viewport classes,
- no forbidden path or core gameplay rule change is present,
- no player-facing UI still exposes command keys, backend codes, or debug schema text,
- audit confirms generated side effects are separated from intended ART-13 results.
