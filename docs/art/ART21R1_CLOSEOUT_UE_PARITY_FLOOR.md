# ART-21R1 Closeout: UE Parity Floor

## Result

```text
PARTIAL: ue_parity_floor_partial / blockers_listed
```

## What Passed

- UE reference was launched and captured for main menu, area select, difficulty select, run HUD, and map overlay.
- Godot before screenshots were captured before code changes.
- Godot after screenshots were captured for main menu, deploy prep, run HUD, map overlay, inventory, and result.
- Run HUD now presents the real `RoomLayer/PlayerLayer` world layer as primary evidence instead of relying on `gameplay_viewport_background` or UI-drawn duplicate room/player layers.
- Main menu preserves the original direct `出发探索 -> Deploy Prep` click flow and no longer uses the previous left-side line-frame overlays.
- Map overlay is now a centered modal grid with stronger background separation.
- Inventory and result modals are reachable in a live Godot run.
- `ui_placement_contract_v2.csv` records screen, layer, slot, node, policy, runtime asset, consumer, trigger, and validation screenshot.

## Blockers / Residual Gaps

- Main menu still uses ART terminal/button skins for the right action board; it is cleaner but not a full UE physical board reproduction.
- UE-style area/difficulty selection was not implemented on the main menu by design; those choices belong in Deploy Prep.
- Run HUD no longer duplicates room/player through RunSurface, but real player placement remains governed by RunScene gameplay/local-position behavior and should be separately tuned if the player appears in an unexpected room-local position.
- Map overlay cells remain abstract squares and are still below UE tile/marker readability.
- Deploy and Long-term remain mostly ART-21 contract-era pages and were not rebuilt to the UE/Base page-family target in this pass.
- Inventory has a Q-labeled button, but `RunSceneInputRouter` does not currently route keyboard Q to inventory.
- Ground loot was not naturally triggered in the sampled Godot run, so ground loot visual parity is not claimed.
- UE inventory / loot / event were not naturally triggered in the sampled UE run, so those are reference gaps, not parity passes.

## Validation

Required validation commands for this closeout:

```powershell
git status --branch --short
& "D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe" --headless --path "D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot" --quit-after 5
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\validate_art21r1_ue_parity.ps1
```

The result should be interpreted with the screenshot comparison:

- Structural validator pass means required files, fields, screenshots, and forbidden runtime references are in order.
- Visual result remains PARTIAL because blockers above are visible in screenshots.

## Dirty Boundary

Known pre-existing/editor-generated dirty was not cleaned or staged as stage output:

- `Godot/GraytailGodot/project.godot`
- `Godot/GraytailGodot/data/assets/asset_manifest.*.translation`

## Next Stage Recommendation

The next art stage should target the remaining UE/Base gap directly:

1. Replace terminal/button skins on Main menu, Deploy, and Long-term with page-family structural surfaces.
2. Add a real inventory keyboard route or relabel the button/input policy.
3. Upgrade MapOverlay cells/markers from abstract squares to authored tile states.
4. Add a deterministic ground-loot trigger path for visual QA without changing gameplay semantics.
