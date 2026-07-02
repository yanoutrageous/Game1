# ART-20 Draw to Runtime UI Component Pipeline Execution

## 0. Document Role

This document records the ART-20 execution result for the UI art pipeline:

```text
sources/draw or sources/art source candidate
  -> sources/art/ART-20 staging
  -> cut output
  -> Godot runtime asset
  -> asset_manifest.csv
  -> visual_key / UI consumer
  -> Computer Use live validation
```

ART-20 is not final UI polish. It proves that a controlled art source can be admitted, cut, imported, mapped, and consumed without reading external source paths at runtime.

No commit or push was performed by the execution frame.

## 1. Boundaries

Modified ART-20 external workspace:

- `D:\AGAME1\sources\art\ART-20\01_staging_from_draw`
- `D:\AGAME1\sources\art\ART-20\03_cut_output`
- `D:\AGAME1\sources\art\ART-20\_manifest`

Modified runtime / repo areas:

- `Godot/GraytailGodot/assets/ui/art20/**`
- `Godot/GraytailGodot/data/assets/asset_manifest.csv`
- `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`
- `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd`
- `docs/art/validation/art20/**`
- `tools/art20_cut_ui_assets.py`
- `tools/validate_art20_ui_asset_pipeline.ps1`

Not modified as ART-20 source material:

- `D:\AGAME1\sources\draw`
- `D:\AGAME1\sources\art` outside the ART-20 workspace
- `D:\AGAME1\Draw`
- `D:\AGAME1\Base Art`
- `D:\AGAME1\Connection`

No gameplay core, command, save, or run-rule semantics were changed for ART-20.

## 2. Source and Staging

Slice 1 admitted a conservative Draw-derived P0 set into ART-20 staging.

Evidence:

- `D:\AGAME1\sources\art\ART-20\_manifest\staging_manifest.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\staging_summary.json`
- `docs/art/validation/art20/ART20_SLICE1_STAGING_REPORT.md`

Key rule:

- Source roots were read and copied from; source roots were not modified, moved, deleted, or renamed.

## 3. Cutting

Slice 2 created a dry-run planner and Slice 3 wrote real cut output.

Evidence:

- `tools/art20_cut_ui_assets.py`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_manifest.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_blocked_or_review.csv`
- `D:\AGAME1\sources\art\ART-20\_manifest\cut_summary.json`
- `docs/art/validation/art20/ART20_SLICE3_P0_COMPONENT_CUT_REPORT.md`
- `docs/art/validation/art20/art20_slice3_component_gallery.md`

Cut output summary:

- Cut manifest rows: 54
- Blocked rows: 5
- Runtime-imported subset after Slice 4: 15

Blocked rows stayed excluded:

- `deploy_left_character_frame`
- `longterm_left_character_profile`
- `run_gameplay_viewport_background`
- `map_overlay_cell_64_set`
- `map_overlay_event_marker_64`

## 4. Runtime Import and Manifest

Slice 4 imported 15 conservative ART20 runtime PNG files.

Runtime directory:

- `Godot/GraytailGodot/assets/ui/art20/**`

Manifest:

- `Godot/GraytailGodot/data/assets/asset_manifest.csv`

Imported visual keys:

- `shared.keycap.e.normal`
- `shared.keycap.esc.normal`
- `shared.keycap.f.normal`
- `shared.keycap.m.normal`
- `shared.keycap.q.normal`
- `shared.keycap.t.normal`
- `main_menu.background.base_hall`
- `deploy.icon.medkit`
- `deploy.icon.syringe`
- `deploy.icon.flashlight`
- `deploy.icon.goggles`
- `deploy.icon.armor`
- `deploy.icon.backpack`
- `deploy.icon.bandage`
- `deploy.icon.compass`

Evidence:

- `docs/art/validation/art20/ART20_SLICE4_RUNTIME_IMPORT_REPORT.md`
- `docs/art/validation/art20/art20_slice4_runtime_import_manifest.csv`
- `docs/art/validation/art20/art20_slice4_import_excluded.csv`
- `docs/art/validation/art20/art20_slice4_runtime_component_gallery.md`

## 5. UI Consumer Integration

Slice 5 connected the imported ART20 resources through the existing manifest-backed presentation path.

Main consumer surface:

- `Art09ManifestAssetMapping.main_menu_background_ref()`
- `Art09ManifestAssetMapping.key_prompt_ref()`
- `Art09ManifestAssetMapping.deploy_icon_ref()`
- `Art09ManifestAssetMapping.item_icon_ref()`
- `Art09ManifestAssetMapping.deploy_card_asset_ref()`
- `Art09ManifestAssetMapping.inventory_item_icon_ref()`
- `PresentationMapping` forwarding helpers

Final Slice 5 audit required two rework passes. The final accepted state is:

- Main menu `deploy` may use ART20 compass.
- Main menu `long_term`, `settings`, and `exit_game` use generic fallback, not ART20 item/deploy icons.
- Generic `consumable` no longer maps to ART20 medkit.
- Generic `equipment` no longer maps to ART20 flashlight.
- Deploy card medkit is used only for exact `first_aid` / `medkit` semantics.
- Unknown deploy cards no longer default to ART20 compass.
- Exact map / compass contexts may still use ART20 compass.

Audit result:

- `PASS_ALLOW_SLICE_6`

Evidence:

- `docs/art/validation/art20/ART20_SLICE5_CORE_SCREEN_REPLACEMENT_REPORT.md`
- `docs/art/validation/art20/art20_slice5_rework2_deploy_prep.png`
- `docs/art/validation/art20/art20_slice5_rework2_inventory.png`

## 6. Computer Use Final Evidence

Slice 6 used the real Godot project and Computer Use to capture final evidence. The current environment captures the Godot window at 856x511 logical pixels, so these images are live smoke evidence rather than full 1280x720 visual QA.

Final screenshots:

- `docs/art/validation/art20/art20_slice6_main_menu_final.jpg`
- `docs/art/validation/art20/art20_slice6_deploy_prep_final.jpg`
- `docs/art/validation/art20/art20_slice6_deploy_before_run_final.jpg`
- `docs/art/validation/art20/art20_slice6_long_term_final.jpg`
- `docs/art/validation/art20/art20_slice6_run_hud_final.jpg`
- `docs/art/validation/art20/art20_slice6_map_overlay_final.jpg`
- `docs/art/validation/art20/art20_slice6_inventory_final.jpg`

Observed coverage:

- Main menu consumes the ART20 main menu background and manifest-backed UI frame/button chain.
- Deploy prep consumes ART20 button/icon resources only where semantics are exact.
- Long term remains mostly dependent on prior ART18/ART19 layout assets because ART20 longterm profile assets are blocked.
- Run HUD consumes ART20 shared keycaps; ART20 run gameplay background is blocked.
- MapOverlay remains on the existing map overlay asset path because ART20 map cell/event marker assets are blocked.
- Inventory consumes ART20 exact item icons where item semantics match; generic categories fall back to legacy/generic refs.

## 7. Validation

Validator:

- `tools/validate_art20_ui_asset_pipeline.ps1`

Checks:

- Required ART20 manifest files exist.
- Required Slice reports exist.
- Final ART20 document exists.
- Slice 6 Computer Use screenshots exist.
- Staging manifest has rows.
- Cut manifest has 54 rows.
- Blocked manifest has 5 rows.
- `asset_manifest.csv` has 15 ART20 rows.
- ART20 visual keys match the expected imported set.
- ART20 manifest rows point to existing `res://assets/ui/art20/**` files.
- No generated `.import`, `.uid`, or `.translation` files are under `assets/ui/art20/**`.
- Blocked component ids are not present in ART20 manifest rows or ART20 mapping.
- UI / presentation scripts do not hardcode external source paths.
- No staged git changes exist.

Validation commands:

```powershell
git diff --check
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_art20_ui_asset_pipeline.ps1
```

## 8. Dirty Classification

The working tree remains intentionally dirty and mixed from ART18 / ART19 / ART20 plus generated side effects.

ART20-related outputs include:

- `Godot/GraytailGodot/assets/ui/art20/**`
- ART20 rows in `Godot/GraytailGodot/data/assets/asset_manifest.csv`
- `Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd`
- `Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd`
- `docs/art/ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION_PLAN.md`
- `docs/art/ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION.md`
- `docs/art/validation/art20/**`
- `tools/art20_cut_ui_assets.py`
- `tools/validate_art20_ui_asset_pipeline.ps1`

Generated side effects remain isolated and were not cleaned:

- `Godot/GraytailGodot/project.godot`
- `Godot/GraytailGodot/data/assets/asset_manifest.*.translation`
- `.import`
- `.godot`

No `git add`, commit, push, pull, reset, clean, or stash operation was performed.

## 9. Residual Risks

ART-20 proves the pipeline but does not complete final visual quality:

- Only 15 ART20 runtime assets were imported.
- 39 cut outputs remain deferred or excluded.
- Manual nine-slice rows still require review.
- Several multi-candidate rows still require final `asset_id` / `visual_key` resolution.
- Long term profile, Run gameplay background, MapOverlay cell set, and MapOverlay event marker remain blocked.
- GroundLoot was not fully reproduced as an independent visible loot panel.
- 856x511 Computer Use captures are environment-limited smoke evidence, not final release screenshots.

## 10. Conclusion

ART-20 has completed the intended pipeline proof:

```text
source candidate -> ART20 staging -> cut output -> runtime asset -> manifest -> visual_key -> UI consumer -> live validation evidence
```

Recommended next step: audit ART-20 Slice 6. If accepted, later stages can decide whether to commit/push the ART20 grouped outputs or continue with additional visual QA / asset import batches.
