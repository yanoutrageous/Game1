# G14 Legacy Demo UI Surface Validation

## Scope

- Stage: G14 Legacy Demo UI Surface Sprint.
- Status: complete, committed, pushed, and closed by R5 docs-only closeout.
- Baseline before R3: `8878bd3bb15a4eddcdf0ac87d98b2aebb964fabf` (`docs: close G13 resolution layout adaptation pass`).
- Current main HEAD before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`.
- Current remote live main before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`.
- Current commit: `fc2b86b fix(godot): resolve RunSurface parser type inference`.
- R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`.
- R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`.
- R3 feature commit: `1d33c89 feat(godot): add legacy demo run surface shell`.

## Stage Record

- R1: coupling audit completed before implementation; `run_scene.gd` was confirmed to own run flow, UI build, routing, CommandBus dispatch, event/loot/extract feedback, panel control, diagnostics, and layout distribution.
- R2: plan approved for a minimal `RunSurface` / `RunSurfaceModel` cut before deeper legacy Demo UI work.
- R3: added the first low-fidelity run-screen surface shell.
- R3 acceptance follow-up: recorded display-only boundaries and safety event.
- R4: added second-wave presentation refinement only.
- Hotfix: fixed GDScript parser type inference in `run_surface.gd`.
- R5: docs-only closeout / handoff / status alignment; no UI or runtime code changes.

## Implemented

- Added `RunSurfaceModel` as a display-only adapter from public run snapshot, `MiniMapViewModel`, `UILayoutProfile`, and the latest `CommandResult`.
- Added `RunSurface` as a lightweight run-screen composition layer for the first legacy Demo-style surface: left scanner rail, central room/objective panel, right protocol/danger/status rail, bottom action bar, left resource pocket, overlay slot, modal slot, and feedback slot.
- Connected `run_scene.gd` to instantiate the surface, connect surface signals back to existing orchestration methods, and pass the surface model during view refresh.
- Preserved existing HUD, MiniMap, MapOverlay, Inventory, GroundLoot, ResultPanel, TutorialPopup, event, loot, extract, pause, and diagnostics paths.
- R4 refined scanner legend/detail, right-side protocol/danger/status lines, bottom action hints, button visual states, legacy-style modal chrome, event / loot / extract display text, and feedback hierarchy.
- The hotfix at `fc2b86b` made layout-related local variables explicit in `run_surface.gd` to resolve Godot parser type inference.

## Boundary Acceptance

- `RunSurface` is UI surface composition only.
- `RunSurfaceModel` is display-only and consumes public snapshot/ViewModel/profile/result inputs.
- `RunSurface` and `RunSurfaceModel` do not directly read `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state.
- `RunSurface` and `RunSurfaceModel` do not dispatch CommandBus and do not add gameplay rules.
- `run_scene.gd` retains CommandBus dispatch, screen routing, and event / loot / extract command result decisions.
- G14 does not change snapshot schema, CommandBus semantics, RunContext private state, TruthMap, Ledger, AssetLedger, RunRuleService, gameplay rules, resources, fonts, import products, or project metadata.
- G14 is not a complete 1:1 legacy Demo reproduction, complete final UI, action combat, full event library, talent/card systems, MetaProgress, Deploy persistence, new gameplay, full art migration, broad architecture rewrite, G15, or runtime PASS.

## Safety Event Record

- During G14-R3 execution, two temporary script files were mistakenly created outside `D:\AGAME2\repo\Game1`.
- The execution frame reported that the outside-repository temporary scripts were cleaned as necessary deletion.
- The G14 repository commits contain no outside-repository path.
- This validation follow-up does not scan, clean, or verify outside-repository directories.
- Future CodeX instructions must continue to explicitly forbid outside-repository temporary scripts, logs, caches, and derived files.
- If outside-repository residue confirmation is needed, the user must provide the exact path and explicit authorization. CodeX must not independently search parent, sibling, user, system, old UE/Game.git, `lua-prototype-main`, or other repository directories.

## Dirty / Stash Boundary

- Protective stash remains expected and must not be touched: `stash@{0}: On godot/g7-lua-ux-flow-parity-p2: pre-sync generated dirty before aligning to G13 closeout main`.
- Remaining dirty is allowed only when it is the existing whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
- G14 did not submit the existing Godot dirty whitelist.

## Static Checks

Recommended commands from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "fc2b86b|cc652e5|39b51f1|1d33c89|8878bd3|G14|G15|RunSurface|RunSurfaceModel|runtime PASS|Godot/editor/game/import|仓库外|临时脚本|stash|TruthMap|RunRuleService|AssetLedger|CommandBus|并行|规则线|UI 线" docs Godot/GraytailGodot/docs
rg -n "RunSurface|RunSurfaceModel|CommandBus|TruthMap|RunRuleService|Ledger|AssetLedger|MapOverlay|Inventory|GroundLoot|ResultPanel|extract|loot|event" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
rg -n "TruthMap|RunRuleService|RunAssetLedger|AssetLedger|CommandBus\\.dispatch" Godot/GraytailGodot/scripts/ui/run_surface Godot/GraytailGodot/scripts/ui/shell/run_ui_view_model.gd
```

Expected static result:

- `RunSurface` and `RunSurfaceModel` exist.
- `RunSurface` does not call `CommandBus.dispatch`.
- `RunSurface` and `RunSurfaceModel` do not directly read `TruthMap`, `RunRuleService`, `RunAssetLedger`, `AssetLedger`, or private rule state.
- Existing panel APIs remain snapshot/ViewModel based.
- Event, loot, and extract modals keep existing command and routing decisions in `run_scene.gd`.
- Existing Godot dirty whitelist must not be staged or committed.
- No outside-repository temporary scripts, files, logs, caches, or generated outputs are created.

## Runtime Status

- Godot/editor/game/import was not run during G14-R3, G14-R4, the parser hotfix, or G14-R5 closeout.
- This validation record does not claim runtime PASS.
- Manual runtime verification is still required before claiming visual, interaction, parser/runtime, or playable PASS.

## Manual Checklist Summary

- Start tutorial and standard runs after explicit runtime authorization.
- Confirm the first run screen reads as a legacy Demo-style structure: scanner left, room/objective center, protocol/danger/status right, actions bottom, resources lower-left.
- Confirm Inventory, GroundLoot, MapOverlay, ResultPanel, TutorialPopup, EventOptionPanel, LootResultPanel, ExtractConfirmPanel, and Pause overlay still open through existing player paths.
- Confirm event/loot/extract behavior still uses existing command/routing logic and has not moved rule decisions into the surface.
- Confirm scanner legend, right rail, feedback slot, action hints, and modal hierarchy match the G14-R4 low-fidelity surface goals.
- Confirm all supported G13 fixed tiers remain manually checkable before any runtime PASS claim.

## Next Candidate Boundary

- Runtime smoke / playable verification.
- Old Demo UI manual acceptance.
- UI line continuing visible surface reproduction.
- Rules line starting main-loop semantics audit.
- UI / rules parallel branch strategy.

These are candidates only. The next stage is not started, and G15 is not started in G14-R5.

If UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel. The rules line must not directly modify the UI surface, and the UI line must not directly read rules private state.

High-conflict ownership is required for `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, and global status / handoff / validation docs.
