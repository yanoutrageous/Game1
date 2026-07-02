# ART21R2 Slice 6 Modal Section Report

## Status

PARTIAL. This pass moves modal title plates, summary panels, item/detail
sections, and the Result action strip onto draw-sliced Zujian3 runtime assets.
It does not complete modal composition, non-empty item-row validation, or the
UE-floor information hierarchy.

## Source And Cutting Path

- Source sheet: `D:\AGAME1\sources\draw\Zujian3.png`.
- Title/action source: `Zujian3_candidate_012.png`.
- Section source: `Zujian3_candidate_010.png`.
- Staging manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_section_staging_manifest.csv`.
- Dry-run plan:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_section_cut_dry_run_plan.csv`.
- Cut manifest:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_section_cut_manifest.csv`.
- Cut summary:
  `D:\AGAME1\sources\art\ART-21R2\_manifest\modal_section_cut_summary.json`.
- Script: `tools/art21r2_cut_modal_section_assets.py`.

Dry-run was executed before runtime write. Candidate 012 cleaned from 1199
purple-like pixels to 0; candidate 010 cleaned from 1534 purple-like pixels to
0. A wider post-write scan also found 0 opaque purple/pink edge pixels in the
runtime title and section PNGs.

## Runtime Assets

- `ui.art21r2.modal.title_plate` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_title_plate.png`.
- `ui.art21r2.modal.section.panel` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_section_panel.png`.
- `ui.art21r2.modal.action_strip` ->
  `res://assets/ui/art21r2/modal/ui_art21r2_modal_action_strip.png`.

## Godot Changes

- `art21_ui_placement_contract.gd` maps the modal title, section, and action
  strip visual keys.
- `InventoryPanel` places the title, summary, item-list, tooltip, and command
  result areas into image-skinned section containers.
- `GroundLootPanel` mirrors the same title and section treatment without
  changing the existing G route.
- `ResultPanel` adds image-backed summary and action-strip panels and forces
  ResultSummary wrapping/clipping after the first pass exposed text overflow.

## Live Evidence

- Inventory via existing Q route:
  `screenshots/slice6/godot_inventory_zujian3_modal_sections_pass31_smoke.png`.
- GroundLoot via existing G route:
  `screenshots/slice6/godot_ground_loot_zujian3_modal_sections_pass31_smoke.png`.
- Result via existing Pause -> Exit current run double-confirm abandon route:
  `screenshots/slice6/godot_result_zujian3_modal_sections_pass32_smoke.png`.

`godot_result_zujian3_modal_sections_pass31_smoke.png` exposed summary text
overflow and is not acceptance evidence; pass31 was corrected in pass32.

## Remaining Gaps

- Inventory and GroundLoot still lack non-empty item-row live evidence.
- Title/close-button composition is image-backed but still cramped at 856x511.
- Result is no longer overflowing, but the title treatment, reward/item
  hierarchy, and action button contrast remain below the UE floor.
- This pass remains smoke evidence only; it does not claim high-resolution UI QA
  or ART21R2 visual closeout.
