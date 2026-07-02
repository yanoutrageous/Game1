# ART-21: Lua / UE Execution Logic UI Placement Rebuild

## Stage Summary

ART-21 establishes the first authoritative UI Placement Contract and uses it to rebuild the main runtime UI asset consumption points in Godot.

This stage does not claim final product art completion. It closes the ART-20 placement gap by connecting screen slots to `visual_key`, `asset_id`, runtime PNG, manifest row, and consumer script.

## Implemented Slices

| Slice | Status | Evidence |
| --- | --- | --- |
| Slice 0: Lua / UE / Godot gap audit | done | `docs/art/validation/art21/ART21_SLICE0_EXECUTION_LOGIC_GAP_REPORT.md` |
| Slice 1: UI Placement Contract | done | `docs/art/validation/art21/ui_placement_contract.csv`; `UI_PLACEMENT_CONTRACT.md` |
| Slice 2: assets/staging/cut/runtime import | done | `D:\AGAME1\sources\art\ART-21\_manifest\*.csv`; `cut_summary.json` |
| Slice 3: Godot UI rebuild | done_with_limits | `Art21UIPlacementContract`; main/deploy/long/run/map/inventory/result consumers |
| Slice 4: state/input | done_with_limits | Existing navigation and runtime input preserved; ground loot panel not naturally triggered in sampled run |
| Slice 5: validator | pass | `tools/validate_art21_ui_placement_contract.ps1` |
| Slice 6: live Godot screenshots | pass_with_limits | Computer Use screenshots under `docs/art/validation/art21` |

## Runtime Changes

- Added deterministic ART-21 asset generator: `tools/art21_build_ui_assets.py`.
- Added validator: `tools/validate_art21_ui_placement_contract.ps1`.
- Added runtime placement mirror: `Godot/GraytailGodot/scripts/presentation/art21_ui_placement_contract.gd`.
- Updated `Art10UISkinKit` to prefer ART-21 textures and fall back to ART-19/flat style.
- Updated main menu action deck, notice, and meta frames to ART-21 placement refs.
- Updated deploy prep left character frame, route wall, right summary, and primary action button to ART-21 refs.
- Updated long-term profile frame, collection wall, and detail panel to ART-21 refs.
- Updated Run HUD to show the gameplay viewport instead of hiding it, and to use ART-21 gameplay background, top-right status card, and bottom overlay.
- Updated MapOverlay map cell/marker state resolution to ART-21 cells and markers.
- Updated inventory, ground loot, and result modal frames to ART-21 placement refs.

## Validation Commands

```powershell
python .\tools\art21_build_ui_assets.py
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_art21_ui_placement_contract.ps1
& 'D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot' --quit
& 'D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe' --headless --path 'D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot' --quit-after 1
```

Godot headless commands exited 0. They still print existing resource-leak warnings at exit; no ART-21 runtime asset side-effect files were generated under `assets/ui/art21`.

## Live Screenshot Evidence

Captured through a real Godot window and Computer Use:

- `docs/art/validation/art21/art21_cu_main_menu.png`
- `docs/art/validation/art21/art21_cu_deploy_prep.png`
- `docs/art/validation/art21/art21_cu_long_term.png`
- `docs/art/validation/art21/art21_cu_run_hud.png`
- `docs/art/validation/art21/art21_cu_map_overlay.png`
- `docs/art/validation/art21/art21_cu_inventory.png`
- `docs/art/validation/art21/art21_cu_result.png`
- `docs/art/validation/art21/art21_cu_ground_loot_not_triggered.png`

## Limits

- ART-21 does not import user-provided final full-page reference images as runtime assets.
- ART-21 does not finish final visual quality against Base / Lua / UE references.
- Ground loot contract and code consumer are present, but the sampled live run did not naturally expose a floor-item state, so the visual modal remains unproven in live evidence.
- Pre-existing `project.godot` dirty has actual config differences and still needs a separate audit.
