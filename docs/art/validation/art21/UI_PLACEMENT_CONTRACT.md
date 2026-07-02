# ART-21 UI Placement Contract

## Contract File

Authoritative CSV:

`docs/art/validation/art21/ui_placement_contract.csv`

The contract has 36 rows:

| Screen | Rows |
| --- | ---: |
| shared | 14 |
| main_menu | 1 |
| deploy_prep | 3 |
| long_term | 3 |
| run_hud | 3 |
| map_overlay | 9 |
| inventory | 1 |
| ground_loot | 1 |
| result | 1 |

## Required Fields

The contract records:

`screen`, `layer`, `slot`, `interaction_owner`, `state`, `visibility_rule`, `input_rule`, `intended_visual`, `source_candidate`, `cut_output`, `runtime_asset`, `asset_id`, `visual_key`, `consumer`, `stretch_or_9slice`, `fallback`, `blocked_reason`, `validation_screenshot`.

## Runtime Mirror

Godot consumes the contract through:

`Godot/GraytailGodot/scripts/presentation/art21_ui_placement_contract.gd`

The runtime mirror maps:

```text
visual_key -> ui.art21.* asset_id -> asset_manifest.csv -> runtime PNG
screen.slot -> visual_key
panel/button/map state -> visual_key
```

## ART-20 Blocked Replacements

ART-21 replaces the ART-20 blocked/reviewed slots:

- `deploy.left_character_frame.replaced`
- `long_term.profile_frame.replaced`
- `run.gameplay_viewport.background.replaced`
- `map_overlay.cell.unknown.replaced`
- `map_overlay.cell.explored.replaced`
- `map_overlay.cell.scanned.replaced`
- `map_overlay.cell.flagged.replaced`
- `map_overlay.marker.event.replaced`

## Validation

Validator:

`tools/validate_art21_ui_placement_contract.ps1`

Latest result:

```text
ART21 UI placement contract validation passed.
contract_rows=36
art21_manifest_rows=36
staging_rows=36
runtime_import_rows=36
blocked_resolution_rows=8
generated_side_effects_under_art21=0
```

## Screenshot Evidence

Computer Use evidence in `docs/art/validation/art21`:

- `art21_cu_main_menu.png`
- `art21_cu_deploy_prep.png`
- `art21_cu_long_term.png`
- `art21_cu_run_hud.png`
- `art21_cu_map_overlay.png`
- `art21_cu_inventory.png`
- `art21_cu_result.png`
- `art21_cu_ground_loot_not_triggered.png`

`ground_loot` remains not naturally triggered in the sampled run; the contract and runtime consumer exist, but panel visibility still needs a run state with floor items or a separately accepted debug-spawn validation.
