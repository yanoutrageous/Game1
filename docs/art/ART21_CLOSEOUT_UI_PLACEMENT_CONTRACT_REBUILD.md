# ART-21 Closeout: UI Placement Contract Rebuild

## Conclusion

ART-21 can close as `placement_contract_pass_visual_rebuild_partial`.

The stage proves a reproducible contract-backed path:

```text
ART21 component declaration -> staging PNG -> cut PNG -> Godot runtime PNG -> asset_manifest.csv -> visual_key / screen.slot contract -> Godot consumer -> Computer Use evidence
```

## Pass Criteria

| Item | Result |
| --- | --- |
| Stage branch | `art/art21-ui-placement-contract-rebuild` |
| Contract rows | PASS, 36 |
| ART21 runtime manifest rows | PASS, 36 |
| External staging rows | PASS, 36 |
| Runtime import rows | PASS, 36 |
| ART20 blocked replacements | PASS, 8 |
| Validator | PASS |
| Godot headless project-load/parser smoke | PASS, exit 0 |
| Godot headless runtime smoke | PASS, exit 0 |
| Computer Use screenshots | PASS_WITH_LIMITS |
| Ground loot live modal | NOT_TRIGGERED in sampled run |
| Final visual target | NOT_DONE |

## Evidence

Validation command:

```text
ART21 UI placement contract validation passed.
contract_rows=36
art21_manifest_rows=36
staging_rows=36
runtime_import_rows=36
blocked_resolution_rows=8
generated_side_effects_under_art21=0
```

Computer Use screenshots:

- `art21_cu_main_menu.png`
- `art21_cu_deploy_prep.png`
- `art21_cu_long_term.png`
- `art21_cu_run_hud.png`
- `art21_cu_map_overlay.png`
- `art21_cu_inventory.png`
- `art21_cu_result.png`
- `art21_cu_ground_loot_not_triggered.png`

## Files Added Or Updated

- `tools/art21_build_ui_assets.py`
- `tools/validate_art21_ui_placement_contract.ps1`
- `docs/art/ART21_LUA_UE_EXECUTION_LOGIC_UI_PLACEMENT_REBUILD.md`
- `docs/art/ART21_CLOSEOUT_UI_PLACEMENT_CONTRACT_REBUILD.md`
- `docs/art/validation/art21/ART21_SLICE0_EXECUTION_LOGIC_GAP_REPORT.md`
- `docs/art/validation/art21/UI_PLACEMENT_CONTRACT.md`
- `docs/art/validation/art21/ui_placement_contract.csv`
- `Godot/GraytailGodot/assets/ui/art21/**`
- `Godot/GraytailGodot/scripts/presentation/art21_ui_placement_contract.gd`
- `Godot/GraytailGodot/data/assets/asset_manifest.csv`
- Godot UI consumer scripts for main menu, deploy prep, long term, run surface, map overlay, inventory, ground loot, and result.

## Dirty Boundary

Pre-existing and Godot/editor generated dirty was not cleaned:

- `Godot/GraytailGodot/project.godot` remains modified and needs later config audit.
- `Godot/GraytailGodot/data/assets/asset_manifest.*.translation` remains generated/editor dirty.
- Ignored `.png.import`, `.uid`, `.translation`, and `.godot` files remain ignored generated side effects.

## Follow-up

1. Audit `project.godot` config differences before any main merge.
2. Validate ground loot with an accepted floor-item fixture or debug-spawn flow.
3. Continue visual quality work against Base / Lua / UE references; ART-21 provides placement authority, not final art polish.
