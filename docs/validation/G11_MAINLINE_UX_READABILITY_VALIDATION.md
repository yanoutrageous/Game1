# G11 Mainline UX Readability Validation

- Date: 2026-06-12
- Stage: G11 Mainline Testability & UX Readability Repair
- Main baseline before G11-R3: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`
- G11-R3 commit: `e261ac7d8671b59e7e72750122e6581af6ea6644`
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`
- G10 closeout follow-up commit: `53a4e122376998d2f6d0a2a617b753a3d382b2f0`

## Boundary

- G11 is not a G10 continuation.
- G11 is not G12.
- G11 does not add new gameplay, new systems, persistence, action combat, full art migration, full mobile support, complete settings, or complete diagnostics.
- G11 changes are limited to current fact-source calibration, manual testability documentation, and small UX readability wording.

## Static Checks

Run after implementation from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "53a4e122|aa19db2f|G11|G10" docs Godot/GraytailGodot/docs
rg -n "MapOverlay|Inventory|GroundLoot|ResultPanel|Pause|diagnostic" Godot/GraytailGodot/scripts Godot/GraytailGodot/docs docs
```

## Manual Checklist

Do not mark these PASS unless a human or authorized runtime smoke actually plays the route.

- Main menu opens and `出发探索` reaches the deploy shell.
- Standard run starts from `确认出发`.
- MiniMap direct click opens MapOverlay.
- MapOverlay feedback shows selected coordinate, command id, and accepted/blocked state.
- InventoryPanel shows readable empty state, item tooltip, command result, and disabled drop reason.
- GroundLootPanel shows readable empty state, pickup tooltip, capacity hint, and `blocked_capacity` reason.
- ResultPanel success and failure summaries expose clear return routes to main menu and deploy page.
- Pause/Settings overlay explains continue, settings placeholder, and no local preference persistence.
- Dev-only diagnostics entry remains hidden or disabled in the default player channel.

## Runtime / Import Record

- Godot/editor/game/import was not run during this documentation and UI wording pass.
- No runtime PASS is claimed by this file.
- Existing dirty whitelist remains: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.

## G11-R4 Closeout Record

- G11-R3 is complete and pushed at `e261ac7d8671b59e7e72750122e6581af6ea6644`.
- G11-R4 is docs-only closeout, handoff, and status alignment.
- G11-R4 does not continue UI wording repair, does not modify Godot runtime/UI/resource files, and does not start G12.
- Remote live `main` was confirmed at `e261ac7d8671b59e7e72750122e6581af6ea6644` before this closeout edit.
- Validation for R4 is static only: `git diff --stat`, `git diff --check`, `git status --short`, and fact grep for `e261ac7`, `53a4e122`, `aa19db2f`, `G11`, and `G10`.
- Godot/editor/game/import was not run during G11-R4, and this record does not claim runtime PASS.
- Remaining known dirty is still limited to tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
