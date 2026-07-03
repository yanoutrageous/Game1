# ART21R2 Slice 7 - Source Inventory and Cut Demand Matrix

Status: `NOT_COMPLETE_R2_PARTIAL`

This slice is a source-inventory and cut-demand gate. It does not import new
runtime art, does not generate replacement images, does not change Godot UI
behavior, and does not mark ART21R2 visual work complete.

## Boundary

- Branch under audit: `art/art21r2-image-boundary-ui-rework`.
- New runtime assets: none.
- Godot UI script changes: none in this slice.
- Commit eligibility: only this report, the source/cut matrix, and validator
  structure checks.
- Current dirty not owned by this slice:
  `Godot/GraytailGodot/project.godot`,
  `Godot/GraytailGodot/data/assets/asset_manifest.*.translation`,
  `Godot/GraytailGodot/scripts/ui/result/result_panel.gd`,
  `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd`, old failed
  Result smoke screenshots, and `tools/__pycache__/`.

## Source Roots Checked

- `Godot/GraytailGodot/data/assets/asset_manifest.csv`.
- `docs/art/validation/art21r2/ui_placement_contract_v3.csv`.
- `docs/art/validation/art21r2/ART21R2_SLOT_GAP_MATRIX.csv`.
- `D:\AGAME1\sources\art\ART-21R2\_manifest\*.csv` and `*.json`.
- `D:\AGAME1\sources\art\ART-21R2\03_cut_output`.
- `D:\AGAME1\sources\draw\_manifest\asset_inventory.md`.
- `D:\AGAME1\sources\draw\_manifest\selected_assets.md`.
- `D:\AGAME1\sources\draw\_manifest\deploy_ui_assets_review.md`.
- `D:\AGAME1\sources\draw\30_game_ready`.
- Root sheets:
  `Main.png`, `Next.png`, `5.png`, `Zujian1.png`, `Zujian2.png`,
  `Zujian3.png`, `Zuhe.png`, `Zuhe2.png`, `1.png`, `2.png`, `2UI.png`,
  `3.png`, `4.png`, and `6.png`.

All named root sheets exist in the current `D:\AGAME1\sources\draw` tree.

## Matrix Output

Primary output:

- `docs/art/validation/art21r2/ART21R2_SOURCE_SLOT_CUTTING_MATRIX.csv`

The matrix is slot-level rather than a flat asset list. Each row records the
current asset, current visual key, current source class, source candidate,
manifest evidence, replacement need, current gap, next action, and validation
screenshot.

Required `current_source_class` values are limited to:

- `art21r2_formal_draw_cut_ready`
- `art21r2_generated_transition`
- `art19_draw_borrowed`
- `art20_transition`
- `art21_generated_transition`
- `art15_result_title_borrowed`
- `none_runtime_text`
- `code_scrim_exception`

Rows with multiple current assets may use semicolon-separated source classes.

## Source Classification

### Formal ART21R2 draw-cut-ready

These assets have dedicated ART21R2 manifests, runtime outputs, and purple
cleanup evidence where applicable:

- `ui.art21r2.modal.inventory.frame`
- `ui.art21r2.modal.ground_loot.frame`
- `ui.art21r2.modal.result.frame`
- `ui.art21r2.modal.item_row.normal`
- `ui.art21r2.modal.button.primary`
- `ui.art21r2.modal.button.secondary`
- `ui.art21r2.modal.button.danger`
- `ui.art21r2.modal.title_plate`
- `ui.art21r2.modal.section.panel`
- `ui.art21r2.modal.action_strip`
- `ui.art21r2.minimap.hud.player`
- `ui.art21r2.minimap.hud.explored`
- `ui.art21r2.minimap.hud.scanned`
- `ui.art21r2.minimap.hud.mine`
- `ui.art21r2.minimap.hud.chest`
- `ui.art21r2.minimap.hud.exit`

These can remain as R2 assets, but their slots may still be visually partial.

### ART21R2 generated transition

The Run HUD rail/status/bottom frames are currently ART21R2-branded but not
draw-cut-ready:

- `ui.art21r2.run.left_info_rail.frame`
- `ui.art21r2.run.status_card.frame`
- `ui.art21r2.run.bottom_overlay.frame`

They remove some visible Godot fallback edges, but they still require source
selection or a blocker decision before closeout.

### Draw-derived historical borrowing

The current work borrows draw-derived historical runtime assets where they
reduce visible generated UI:

- ART19 panels, buttons, summary bar, scrollbar, and map64 assets.
- ART15 Result title plates:
  `ui.result.title.extract_confirm`,
  `ui.result.title.extraction_success`, and
  `ui.result.title.signal_lost`.

These are not automatically ART21R2 completion. They are valid candidates or
interim materials and must be recorded as borrowed unless re-cut or explicitly
accepted for the R2 slot.

### Engineering transition material

The following are still transition layers:

- ART20 keycaps and deploy icons.
- ART20/main menu background lineage where used as the current runtime scene
  background.
- ART21 generated deploy, long-term, and shared frame assets. Map event/flag
  markers have an ART21R2 draw-cleaned pass but the overall map overlay remains
  partial.

These are useful for continuity but should not be described as final R2 image
boundary wins.

### Runtime text and code exceptions

- `main_menu/title` is still `none_runtime_text` and remains a baseline fail.
- `run_hud/keyboard_q_inventory` is a valid interaction route rather than an
  image slot.
- `map_overlay/modal_dimmer` is a `code_scrim_exception`; it may remain code
  because the visible modal boundary is image-owned.

## Root Sheet Decisions

### `5.png`

`5.png` is a deploy and page-family component sheet. Existing manifest notes
show usable buttons, panels, labels, scrollbars, icons, and decorations.

Decision:

- Use it for Deploy Prep and Long Term source selection.
- Do not import the root sheet directly.
- Do not import purple-background candidates directly.
- Do not import fixed text or example-content panels as dynamic runtime UI.

### `Zujian3.png`

`Zujian3.png` is the correct source family for modal frame, controls, title
plates, section panels, and action strips. ART21R2 already cut several formal
runtime assets from it.

Decision:

- Continue using it for Inventory, GroundLoot, Result, and map modal panel
  family work.
- Do not use it to solve main menu title art.
- Do not treat the existing formal cuts as proof that modal visual hierarchy is
  complete.

### `Zujian2.png`

`Zujian2.png` is the strongest source family for map/icon state follow-up.

Decision:

- Use it or the already game-ready `map_icon` assets to address map event,
  flag, and marker gaps.
- Clean all purple background before runtime import.
- Do not claim ART20 blocked `map_overlay_event_marker_64` solved without a
  fresh source-selection and cut/import record.
- Slice 6 pass38 records that fresh cut/import record for event and flag
  marker textures only. Pass39 adds sparse non-full-reveal evidence, and pass40
  adds click-to-unflag evidence; none of these close the map overlay visual
  target.

### `Zujian1.png`

`Zujian1.png` is more suitable for props, items, and small icons than for core
UI panels.

Decision:

- Do not use it as a core UI boundary source unless a later source-selection
  audit identifies a specific slot.

### `Main.png`

`Main.png` is the no-text main menu background source.

Decision:

- Keep it as scene/background material.
- It does not solve the missing title/sign art.

### `Next.png`

`Next.png` is a full Deploy composite reference.

Decision:

- Use it only as a visual reference for Deploy Prep layout.
- Do not directly split it into dynamic runtime UI without a separate source
  audit because it contains fixed sample content.

## Priority After Slice 7

1. Do not close out ART21R2.
2. If the Result title-plate candidate enters R2, keep it classified as
   ART15 borrowed partial evidence. It must stay linked to contract/gap/report
   rows and a Result screenshot proving no missing or duplicate title text.
3. Address the highest-risk temporary slots:
   `main_menu/title`,
   map overlay title/footer/selected-state hierarchy,
   Run HUD rail/minimap/status/bottom,
   Deploy Prep page-family frames, and
   Long Term page-family frames.
4. For each later visual edit, run Godot, capture evidence, compare against
   UE/Base/concept references, and record `PASS`, `PARTIAL`, or `FAIL` per
   slot. Validator output remains structural evidence only.

## Result

Slice 7 result: `PARTIAL`.

The matrix clarifies what is formal R2, what is borrowed, what is generated
transition, and what needs new cutting. It does not prove visual completion.
