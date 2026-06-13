# G14 Legacy Demo UI Surface Validation

## Scope

- Stage: G14 Legacy Demo UI Surface Sprint.
- R1: coupling audit completed before this implementation; `run_scene.gd` was confirmed to own run flow, UI build, routing, CommandBus dispatch, event/loot/extract feedback, panel control, diagnostics, and layout distribution.
- R2: plan approved for a minimal `RunSurface` / `RunSurfaceModel` cut before deeper legacy Demo UI work.
- R3 target: first low-fidelity run-screen surface shell only.
- Baseline before R3: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` (`docs: close G13 resolution layout adaptation pass`).
- Current main HEAD after R3: `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5`.
- Current remote live main after R3: `1d33c894b6b2c948bf2c7f9c5a55387dce717fc5`.
- R3 commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

## R3 Implementation Record

- Added `RunSurfaceModel` as a display-only adapter from public run snapshot, `MiniMapViewModel`, `UILayoutProfile`, and the latest `CommandResult`.
- Added `RunSurface` as a lightweight run-screen composition layer for the first legacy Demo-style surface: left scanner rail, central room/objective panel, right protocol/danger/status rail, bottom action bar, left resource pocket, overlay slot, modal slot, and feedback slot.
- Updated `run_scene.gd` to instantiate the surface, connect surface signals back to the existing orchestration methods, and pass the surface model during view refresh.
- Existing HUD, MiniMap, MapOverlay, Inventory, GroundLoot, ResultPanel, TutorialPopup, event, loot, extract, pause, and diagnostics paths remain reusable.
- Event, loot, and extract are only routed into surface slots in R3; command result decisions, rule branches, and screen routing remain in `run_scene.gd`.
- R3 does not change snapshot schema, CommandBus semantics, RunContext private state, TruthMap, Ledger, AssetLedger, RunRuleService, gameplay rules, resources, fonts, import products, or project metadata.
- R3 is complete, committed, and pushed.

## R3 Acceptance Follow-Up

- `RunSurface` is UI surface composition only.
- `RunSurfaceModel` is display-only and consumes public snapshot/ViewModel/profile/result inputs.
- `RunSurface` and `RunSurfaceModel` do not directly read `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state.
- `RunSurface` and `RunSurfaceModel` do not dispatch CommandBus and do not add gameplay rules.
- `run_scene.gd` retains CommandBus dispatch, screen routing, and event / loot / extract command result decisions.
- Protective stash remains expected and must not be touched: `stash@{0}: On godot/g7-lua-ux-flow-parity-p2: pre-sync generated dirty before aligning to G13 closeout main`.
- Remaining dirty is allowed only when it is the existing whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.

## Safety Event Record

- During G14-R3 execution, two temporary script files were mistakenly created outside `D:\AGAME2\repo\Game1`.
- The execution frame reported that the outside-repository temporary scripts were cleaned as necessary deletion.
- The G14-R3 repository commit contains no outside-repository path.
- This validation follow-up does not scan, clean, or verify outside-repository directories.
- Future CodeX instructions must continue to explicitly forbid outside-repository temporary scripts, logs, caches, and derived files.
- If outside-repository residue confirmation is needed, the user must provide the exact path and explicit authorization. CodeX must not independently search parent, sibling, user, system, old UE/Game.git, `lua-prototype-main`, or other repository directories.

## Static Checks

Recommended commands from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "RunSurface|RunSurfaceModel|RunMainLayout|run_scene|CommandBus|TruthMap|UILayoutProfile|MapOverlay|Inventory|GroundLoot|ResultPanel" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
rg -n "TruthMap|RunRuleService|RunAssetLedger|AssetLedger|CommandBus\\.dispatch" Godot/GraytailGodot/scripts/ui/run_surface Godot/GraytailGodot/scripts/ui/shell/run_ui_view_model.gd
```

Expected static result:

- `RunSurface` and `RunSurfaceModel` exist.
- `RunSurface` does not call `CommandBus.dispatch`.
- `RunSurface` and `RunSurfaceModel` do not directly read `TruthMap`, `RunRuleService`, `RunAssetLedger`, `AssetLedger`, or private rule state.
- Existing panel APIs remain snapshot/ViewModel based.
- Existing Godot dirty whitelist must not be staged or committed.

## Runtime Status

- Godot/editor/game/import was not run during this static implementation pass.
- This validation record does not claim runtime PASS.
- Manual runtime verification is still required before claiming visual or interaction PASS.

## Manual Checklist Summary

- Start tutorial and standard runs after explicit runtime authorization.
- Confirm the first run screen reads as a legacy Demo-style structure: scanner left, room/objective center, protocol/danger/status right, actions bottom, resources lower-left.
- Confirm Inventory, GroundLoot, MapOverlay, ResultPanel, TutorialPopup, EventOptionPanel, LootResultPanel, ExtractConfirmPanel, and Pause overlay still open through existing player paths.
- Confirm event/loot/extract behavior still uses existing command/routing logic and has not moved rule decisions into the surface.
- Confirm all supported G13 fixed tiers remain manually checkable before any runtime PASS claim.
