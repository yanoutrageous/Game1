# Godot Architecture Notes

## G5 Presentation Boundary

- `TruthMap` owns real hidden map state.
- `IntelMap` owns player-known public map state and no longer assigns asset ids.
- `RunContext` exposes status and result snapshots.
- `CommandBus` remains the only player and Debug UI command entry.
- `RoomResolver` owns room behavior and does not reference UI nodes or textures.
- `MiniMapViewModel` builds display-ready markers from `IntelMap` public cells.
- `PresentationMapping` maps public semantics to `asset_id`, label, tooltip, theme key, and room visual data.
- `PresentationTheme` owns color roles and risk colors.
- `AssetCatalog` parses `asset_manifest.csv` and loads resources.
- `ContentDB` remains the autoload facade for asset and data lookup.

## Dependency Direction

Core rules -> RunContext/IntelMap public data -> ViewModel -> PresentationMapping/PresentationTheme -> ContentDB/AssetCatalog -> UI.

Core rule scripts must not hard-code image paths, audio paths, `Texture2D`, `TextureRect`, or UI node references. UI scripts must not read `TruthMap` directly.

## G5 UI Surfaces

- HUD uses `HUDViewModel` plus presentation colors and HUD panel assets.
- MiniMap uses `MiniMapViewModel` and manifest-backed icons with text fallback.
- MapOverlay uses the same MiniMap view model at a larger scale.
- Tutorial popup reads `RunContext.tutorial_popup` through snapshot refresh and confirms through `CommandBus`.
- ResultPanel remains snapshot-based and receives theme styling.
- Room/player visuals use presentation asset ids and do not change gameplay rules.
