# Handoff G14 Legacy Demo UI Surface

## Stage Identity

- Historical label: G14
- Formal name: Legacy Demo UI Surface Sprint
- Repository: `D:\AGAME2\repo\Game1`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Branch: `main`
- Current main HEAD before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`
- Current remote live main HEAD before G14-R5 docs closeout: `fc2b86b6b6b2af9a6c249230621482617b594775`
- Current commit: `fc2b86b fix(godot): resolve RunSurface parser type inference`
- G14-R4 commit: `cc652e5 feat(godot): refine legacy demo run surface presentation`
- G14-R3 follow-up commit: `39b51f1 docs: record G14 run surface acceptance follow-up`
- G14-R3 feature commit: `1d33c89 feat(godot): add legacy demo run surface shell`
- G13 closeout / G14 baseline: `8878bd3 docs: close G13 resolution layout adaptation pass`
- Status: complete, committed, pushed, and closed by G14-R5 docs-only closeout

## Completed

- R1 completed the coupling and cut-point audit.
- R2 completed the approved plan for a minimal surface/model cut.
- R3 added `RunSurfaceModel` as a display-only adapter from public snapshot, `MiniMapViewModel`, `UILayoutProfile`, and latest command result data.
- R3 added `RunSurface` as a lightweight UI surface composition layer with left scanner, center room/objective, right protocol/danger/status rail, bottom actions, lower-left resources, overlay slot, modal slot, and feedback slot.
- R3 connected `run_scene.gd` to instantiate the surface and pass display data while keeping CommandBus dispatch, screen routing, and event / loot / extract decisions in existing paths.
- R4 refined visible presentation only: scanner legend, action hints, button enabled/disabled visuals, dark modal/button style helpers, event / loot / extract display text, and right-rail status/feedback hierarchy.
- Hotfix `fc2b86b` resolved the `run_surface.gd` GDScript type inference parser error.

## Explicitly Not Done

- No complete 1:1 legacy Demo reproduction.
- No complete final UI.
- No action combat.
- No full MetaProgress.
- No Deploy persistence.
- No full event library.
- No new enemy, level, talent, card, or gameplay system.
- No full art migration.
- No complex animation or transition pass.
- No G15.
- No runtime PASS claim.

## Validation Results

- Static docs and grep-based validation are the basis for this closeout.
- Godot/editor/game/import was not run in G14-R3, G14-R4, the parser hotfix, or G14-R5.
- Runtime smoke and manual playable verification are still required before any PASS claim.
- `RunSurface` is UI surface composition only.
- `RunSurfaceModel` is display-only.
- Neither `RunSurface` nor `RunSurfaceModel` directly reads `TruthMap`, `RunRuleService`, Ledger, or `AssetLedger` private state.
- Neither `RunSurface` nor `RunSurfaceModel` dispatches CommandBus.
- Existing event / loot / extract decisions remain in `run_scene.gd`.

## Safety Record

- G14-R3 execution reported that two temporary script files were mistakenly created outside `D:\AGAME2\repo\Game1`.
- The execution frame reported that the files were cleaned as necessary deletion.
- The repository commits contain no outside-repository path.
- Future CodeX work must continue to forbid outside-repository temporary scripts, logs, caches, and derived files.
- Do not scan or clean outside-repository paths unless the user provides the exact path and explicit authorization.
- Protective stash remains expected and must not be apply/pop/drop: `stash@{0}: On godot/g7-lua-ux-flow-parity-p2: pre-sync generated dirty before aligning to G13 closeout main`.
- Remaining dirty is allowed only when it is the existing whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.

## Next Handoff Guide

- Recommended next candidates: runtime smoke / playable verification, old Demo UI manual acceptance, UI-line surface continuation, rules-line main-loop semantics audit, or UI / rules parallel branch strategy.
- Not recommended next step: starting G15 implicitly, expanding G14 into a full UI remake, or modifying rules from UI surface work.
- Files or systems to inspect first: `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd`, `Godot/GraytailGodot/scripts/ui/run_surface/run_surface_model.gd`, `Godot/GraytailGodot/scripts/core/run/run_scene.gd`, `docs/validation/G14_LEGACY_DEMO_UI_SURFACE_VALIDATION.md`, and `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`.
- Decisions needing user approval: running Godot/editor/runtime/import, creating a next-stage branch, splitting UI and rules work, or verifying any outside-repository residue.

## Parallel Branch Boundary

If UI and rules work proceed in parallel, branch from latest `main` into separate branches. Do not have two computers push directly to `main` in parallel.

The rules line must not directly modify UI surface code. The UI line must not directly read rules private state.

High-conflict ownership is required for:

- `run_scene.gd`
- `run_ui_view_model.gd`
- `presentation_mapping.gd`
- Global status / handoff / validation docs

## Safety Boundaries

- Do not modify old UE/Game.git.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not use `git pull`, `git fetch`, `git rebase`, `git reset`, `git clean`, or `git stash` unless a later user instruction explicitly permits the exact operation.
- Do not run Godot/editor/game/import unless explicitly authorized.
- Do not create temporary scripts, logs, caches, or derived files outside `D:\AGAME2\repo\Game1`.
- Do not scan or clean paths outside `D:\AGAME2\repo\Game1` unless the user provides an explicit path and authorization.
- Do not submit `project.godot`, resources, fonts, import products, `.uid`, `.translation`, or the existing Godot dirty whitelist.
