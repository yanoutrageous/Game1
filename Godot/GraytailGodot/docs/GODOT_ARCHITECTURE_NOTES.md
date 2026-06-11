# Godot Architecture Notes

## Current Baseline Entry

Use `docs/PROJECT_BASELINE.md` as the current engineering fact source, `docs/NEXT_HANDOFF.md` as the minimum next-chat entry, and `docs/DOCS_INDEX.md` as the document navigation and historical index.

Milestone names should use `docs/MILESTONES.md`; historical G labels remain for traceability but should not be the only long-term engineering names.

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

## G9 Presentation Layering Boundary

G9 keeps the main background separate from theme, character, prop, foreground, panel, and popup presentation. The base background is a stable base-space layer; map theme and character outfit changes are overlays, not baked background variants.

Layer order:

1. Base Background
2. Theme Overlay
3. Scene Prop Overlay
4. Character Layer
5. Character Overlay
6. Foreground FX
7. UI Panel
8. Popup / Tooltip

`PresentationLayerContracts` defines the contract-only schema for ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, OutfitPresentationDef, PanelState, UIVisibilityPolicy, NavigationEntry, ShortcutEntry, ExpeditionSummaryViewModel, and LongTermSummaryViewModel.

G9 dependency direction:

Core rules -> semantic ids and snapshots -> ViewModel -> PresentationLayerContracts / PresentationMapping / PresentationTheme -> ContentDB / AssetCatalog -> UI.

Core gameplay provides semantic ids such as `theme_id`, `character_id`, `outfit_id`, `risk_level`, and `tracked_objective_id`. Presentation code resolves those ids into layer entries and asset ids. UI state-changing actions still go through CommandBus and CommandResult.

G9 does not import real art, connect contracts to scenes, implement full UI shell navigation, or add gameplay.
