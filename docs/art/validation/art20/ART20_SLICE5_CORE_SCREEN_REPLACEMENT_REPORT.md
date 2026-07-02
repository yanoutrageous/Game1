# ART-20 Slice 5 Core Screen Replacement Report

## 0. Scope

- Source roots modified: no.
- ART-20 staging modified: no.
- ART-20 cut output modified: no.
- Godot runtime modified: yes, presentation mapping only.
- Manifest modified in this slice: no new rows; existing ART20 rows from Slice 4 are consumed.
- Godot run: yes, headless smoke and Computer Use visual checks.
- Commit / push: no.
- Stash operation: no.

## 1. Slice Goal

Slice 5 connects ART20 imported runtime components to UI consumers through the existing manifest-backed presentation path.

The goal is not to invent missing components or force ART20 into blocked areas. Components listed in `D:\AGAME1\sources\art\ART-20\_manifest\cut_blocked_or_review.csv` remain excluded from runtime use.

## 2. Actual Changes

Changed in this slice:

- `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`
  - `main_menu_background_ref()` now resolves to ART20 `main_menu.background.base_hall`.
  - `key_prompt_ref()` now maps semantic actions to ART20 keycaps:
    - interact -> E
    - cancel -> Esc
    - inspect -> F
    - map -> M
    - quick -> Q
    - toggle -> T
  - `deploy_icon_ref()` now prefers ART20 deploy icons when available.
  - `item_icon_ref()` now prefers ART20 medkit / syringe / flashlight / goggles / armor / backpack / bandage / compass when available.
  - `deploy_card_asset_ref()` and `inventory_item_icon_ref()` route known item/card semantics to ART20 where possible.

Existing dirty leveraged but not newly expanded by this slice:

- `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd`
  - Existing forwarding functions expose ART20 component refs.

Generated validation screenshots:

- `docs/art/validation/art20/art20_slice5_main_menu_current.png`
- `docs/art/validation/art20/art20_slice5_deploy_prep_current.png`
- `docs/art/validation/art20/art20_slice5_long_term_current.png`
- `docs/art/validation/art20/art20_slice5_run_hud_current.png`
- `docs/art/validation/art20/art20_slice5_map_overlay_current.png`
- `docs/art/validation/art20/art20_slice5_inventory_current.png`
- `docs/art/validation/art20/art20_slice5_ground_loot_current.png`

JPEG source captures are also present because Computer Use returned JPEG data URLs.

Rework validation screenshots after audit feedback:

- `docs/art/validation/art20/art20_slice5_rework_main_menu.png`
- `docs/art/validation/art20/art20_slice5_rework_deploy_prep.png`
- `docs/art/validation/art20/art20_slice5_rework_run_hud.png`
- `docs/art/validation/art20/art20_slice5_rework_inventory.png`

Second rework validation screenshots after targeted audit feedback:

- `docs/art/validation/art20/art20_slice5_rework2_deploy_prep.png`
- `docs/art/validation/art20/art20_slice5_rework2_inventory.png`

## 3. Coverage

### Main Menu

- ART20 main menu background is consumed via `main_menu_background_ref()`.
- Entry icons use ART20 only where the semantic role is exact:
  - deploy -> compass
  - long_term / settings / exit_game -> generic fallback, not ART20 deploy or item icons.
- Screenshot: `art20_slice5_main_menu_current.png`.
- Rework screenshot: `art20_slice5_rework_main_menu.png`.

### Deploy Prep

- Exact route / card / item icon consumers inherit ART20 refs through the shared mapping functions.
- Generic `consumable` and `equipment` categories fall back to existing generic icons and no longer map to ART20 medkit or flashlight.
- Deploy tabs and broad page-level icons use legacy generic refs unless the semantic match is exact.
- Generic deploy cards no longer map `consumable` to ART20 medkit; only `first_aid` / `medkit` exact card semantics use the ART20 medkit.
- Unknown deploy cards no longer default to ART20 compass; they now fall back to the legacy generic deploy icon.
- Screenshot: `art20_slice5_deploy_prep_current.png`.
- Rework screenshot: `art20_slice5_rework_deploy_prep.png`.
- Second rework screenshot: `art20_slice5_rework2_deploy_prep.png`.

### Long Term

- No long-term-specific ART20 panel or character frame is ready for runtime use.
- `cut_blocked_or_review.csv` blocks `longterm_left_character_profile`.
- The page remains visually dependent on existing ART19 / prior layout assets, with shared ART20 key/icon routing available only where existing consumers request shared refs.
- Screenshot: `art20_slice5_long_term_current.png`.

### Run HUD

- Bottom key prompt buttons route to ART20 keycap assets through `key_prompt_ref()`.
- No ART20 room viewport background is imported; `cut_blocked_or_review.csv` blocks `run_gameplay_viewport_background`.
- Screenshot: `art20_slice5_run_hud_current.png`.
- Rework screenshot: `art20_slice5_rework_run_hud.png`.

### MapOverlay

- No ART20 map overlay cell set is imported.
- `cut_blocked_or_review.csv` blocks `map_overlay_cell_64_set` and `map_overlay_event_marker_64`.
- MapOverlay remains on existing ART19 map64 refs to avoid wrong usage.
- Screenshot: `art20_slice5_map_overlay_current.png`.

### Inventory / GroundLoot / Result

- Inventory item icon resolution now prefers ART20 only where exact item semantics match.
- Generic item categories keep legacy/fallback refs.
- Inventory was visually reachable; screenshot: `art20_slice5_inventory_current.png`.
- Rework screenshot: `art20_slice5_rework_inventory.png`.
- Second rework screenshot: `art20_slice5_rework2_inventory.png`.
- GroundLoot did not expose a distinct loot panel in the current run state; screenshot records the current reachable state: `art20_slice5_ground_loot_current.png`.
- No ART20 result title asset is ready; result title was not replaced.

## 4. Validation

- `git diff --check`: pass. Only CRLF warnings were reported.
- Godot headless smoke:
  - Command: `Godot_v4.6.3-stable_win64_console.exe --headless --path ... --quit`
  - Result: exit code 0.
  - Note: Godot reported resource leak warnings on exit; no script parse failure was observed.
- Computer Use:
  - Real Godot project was launched from `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`.
  - Screenshots captured for main menu, deploy prep, long term, Run HUD, MapOverlay, inventory, and current ground-loot reachable state.
  - Captured logical size was 856x511 because the current project/window or Windows scaling does not expose 1280x720 through Computer Use in this environment.
- `Godot/GraytailGodot/assets/ui/art20/**`:
  - No `.import` or `.uid` files were found directly under the ART20 runtime asset directory during this slice check.

Audit feedback rework:

- Removed generic ART20 mapping for `consumable -> medkit` and `equipment -> flashlight`.
- Main menu `settings`, `exit_game`, and `long_term` no longer borrow ART20 deploy/item icons.
- Broad deploy prep tab/page icons now use legacy generic refs unless they are exact semantic ART20 matches.
- `git diff --check` remained passing after rework.

Second audit feedback rework:

- Removed the remaining generic deploy-card path that mapped any `consumable` card to ART20 medkit.
- ART20 medkit is now used only for exact `first_aid` / `medkit` deploy card semantics.
- Unknown deploy cards no longer default to ART20 compass and instead use the legacy generic deploy icon.
- Exact map / compass contexts continue to use ART20 compass where the semantic match is explicit.
- `git diff --check` and Godot headless smoke remained passing after the second rework.

## 5. Dirty Classification

Current dirty includes multiple stage outputs predating this slice:

- ART20 runtime import outputs:
  - `Godot/GraytailGodot/assets/ui/art20/`
  - `Godot/GraytailGodot/data/assets/asset_manifest.csv`
  - ART20 validation files under `docs/art/validation/art20/`
- ART20 Slice 5 code:
  - `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`
- Existing ART18 / ART19 / ART20 UI work:
  - UI scripts under `scripts/ui/**`
  - `art10_ui_skin_kit.gd`
  - `presentation_mapping.gd`
  - ART18 / ART19 docs and tools
- Generated side effects:
  - `project.godot`
  - `asset_manifest.*.translation`
  - `.import` / `.godot` present in the project tree

No commit, push, reset, clean, pull, or stash operation was performed.

## 6. Risks / Incomplete Items

- Slice 5 cannot fully replace every visible panel because only 15 ART20 runtime assets are currently imported.
- MapOverlay ART20 replacement is explicitly blocked by `cut_blocked_or_review.csv`.
- Long-term character/profile and run gameplay viewport assets are explicitly blocked by `cut_blocked_or_review.csv`.
- GroundLoot did not show an independent loot panel in the current live state; the screenshot records the current reachable state rather than a fabricated loot case.
- Computer Use screenshot size is lower than 1280x720 in this environment.

## 7. Audit Request

Please audit ART-20 Slice 5 with 5.5 xHigh / 5.5 ultra-high reasoning.

Audit focus:

- Verify whether the manifest-backed ART20 mapping is appropriate.
- Verify screenshots against the limited imported asset set.
- Confirm that blocked Slice 3 components were not forced into runtime.
- Decide whether ART-20 may proceed to Slice 6 final validation and documentation.
