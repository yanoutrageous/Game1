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

Screenshot boundary:

- All Computer Use screenshots in this closeout are `856x511`.
- They are smoke evidence from a real Godot window, not 1280 / 1600 / 1920 visual QA.
- `art21_cu_ground_loot_not_triggered.png` proves the sampled run did not expose a floor-item modal; it does not prove ground-loot modal visual acceptance.

## Slot Status

| Slot group | Status | Evidence / limit |
| --- | --- | --- |
| shared panels, buttons, tabs | completed | 14 contract rows, runtime PNGs, `Art10UISkinKit` fallback path |
| main_menu action deck | completed | `main_menu.action_deck_frame`, `art21_cu_main_menu.png` |
| deploy prep left / center / right | completed | `deploy.left_character_frame.replaced`, route wall, summary panel, `art21_cu_deploy_prep.png` |
| long-term left / center / right | completed | `long_term.profile_frame.replaced`, collection wall, detail panel, `art21_cu_long_term.png` |
| run HUD viewport / status / bottom overlay | completed_with_visual_risk | `run.gameplay_viewport.background.replaced`, status card, bottom overlay, `art21_cu_run_hud.png` |
| map overlay cells and markers | completed | unknown/explored/scanned/flagged cells and event/player/exit/mine/chest markers, `art21_cu_map_overlay.png` |
| inventory modal | completed | `inventory.panel.frame`, `art21_cu_inventory.png` |
| ground-loot modal | code_and_contract_completed_live_not_triggered | `ground_loot.panel.frame`; live floor-item modal still unproven |
| result modal | completed | `result.modal.frame`, `art21_cu_result.png` |
| ART-20 blocked slots | replaced | 8 rows in `blocked_resolution.csv`; no ART-20 blocked slot is silently dropped |

No ART-20 blocked slot remains `still_blocked` in the ART-21 contract. The remaining risk is live validation of `ground_loot`, not missing placement contract coverage.

## Base / Lua / UE / ART-21 Gap Table

| Screen | Base / visual target gap | Lua execution gap | UE execution gap | ART-21 result |
| --- | --- | --- | --- | --- |
| main_menu | still short of final product polish and authored background composition | Lua only contributes registry/fallback pattern | anchored hot-zone model is approximated, not fully rebuilt | action deck now slot-backed and visible in smoke screenshot |
| deploy_prep | still needs authored character/map/equipment art beyond generated frames | no Lua page parity target | left/center/right/bottom structure is represented, but UE terminal detail density is not fully matched | core page-family slots are contract-backed |
| long_term | still needs final collection-wall and progression art | no Lua page parity target | uses DeployTerminal page-family structure as reference, not a direct UE screen | left/center/right family slots are contract-backed |
| run_hud | generated viewport background is not final room art | Lua layout intent is now closer: fixed left info, main play region, bottom feedback | UE overlay stack is approximated; focus priority remains existing Godot behavior | near-square gameplay viewport restored with status card and bottom overlay |
| map_overlay | map cells/markers are first-pass generated tokens | Lua split layout/draw/click intent is preserved through existing Godot panel callbacks | UE modal grid concept is represented; zoom/polish is limited | cell and marker states are contract-backed |
| inventory / ground_loot / result | modal frames are first-pass generated, not final authored art | Lua HUD modal layering is only indirectly represented | UE loot/result modal layering is approximated | inventory/result have live screenshots; ground-loot code path exists but live trigger is missing |

## Remaining Visual Non-Completion

- Final Base-level art direction is not complete.
- Generated ART-21 frames are contract components, not final authored full-screen UI.
- Run HUD is structurally closer to the target, but still needs final room art, layout polish, and responsive QA.
- Ground-loot modal needs a deterministic floor-item validation path.
- Screenshot evidence is smoke resolution only.

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
4. Enter ART-22 only as a visual-quality and deterministic-live-validation stage, not as a replacement for the ART-21 placement contract.
