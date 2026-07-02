# ART-21R1 UE Parity Floor With Existing Assets

## Boundary

ART-21R1 repaired the highest-risk UI presentation gaps using existing Godot runtime assets and already-governed same-source PNGs. It did not import UE `.uasset` files, did not make UE or source art paths runtime dependencies, and did not change gameplay core / command / save semantics.

Branch:

```text
art/art21r1-ue-parity-existing-assets
```

## Implementation Summary

| Area | Change |
| --- | --- |
| Main menu | Preserved the original `出发探索 -> Deploy Prep` click route, removed default tooltips, raised background visibility, removed left-side artificial line/mask overlays, and kept the right menu in a single board-like action deck. |
| Run HUD | Keeps real `RoomLayer/PlayerLayer` rendering authoritative; hides the former RunSurface UI room/player duplicate layers; removes permanent top room text masks and right-side world fill; suppresses large success feedback. |
| Map overlay | Reworked `map_overlay_panel.gd` toward a centered modal grid with stronger dimming, square cells, and less table-like spacing. |
| Evidence | Captured UE and Godot before/after screenshots under `docs/art/validation/art21r1/screenshots/`. |
| Contract | Added `docs/art/validation/art21r1/ui_placement_contract_v2.csv` with screen/layer/slot/state/consumer/screenshot mapping. |

## Files

- `Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd`
- `Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd`
- `Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd`
- `docs/art/validation/art21r1/ART21R1_VISUAL_GAP_OBSERVATION.md`
- `docs/art/validation/art21r1/ART21R1_UE_SHARED_ASSET_MATRIX.csv`
- `docs/art/validation/art21r1/ui_placement_contract_v2.csv`
- `docs/art/validation/art21r1/ART21R1_UE_PARITY_COMPARISON.md`

## Explicit Non-Claims

- This is not Base final visual completion.
- This is not a full Deploy / Long-term page-family rebuild.
- This does not add UE-style area/difficulty pages to the Godot main menu. Map, area, difficulty, and loadout choice remain Deploy Prep responsibilities.
- This does not replace the real run world with a UI-drawn room/player layer; RunSurface duplicate world layers are explicitly hidden.
- This does not prove UE inventory / loot / event parity because those UE states were not naturally triggered in the sampled run.
- This does not prove Godot ground loot visual parity because ground loot was not naturally triggered in the sampled run.
- The validator is structural evidence only; screenshot comparison remains the acceptance boundary.
