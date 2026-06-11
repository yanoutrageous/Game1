# Audit: G9 UI Presentation Layering Revision

## Scope

G9 audits the presentation boundary before full UI implementation. The goal is to keep the main background, theme overlays, character presentation, props, effects, panels, and popups low-coupled from gameplay rules.

## Layering Boundary

- The base background is a stable base-space composition.
- Theme overlays represent map and atmosphere presentation through `theme_id`.
- Scene prop overlays are additive and can be hidden, reordered, or reduced.
- Character and character overlays are separate from the base background.
- Foreground FX is presentation-only and reducible.
- UI panels and popups sit above background and character layers.

## Contract Boundary

- `ThemeProfile` selects background, color grade, lighting, ambient VFX, prop overlays, foreground overlays, panel skin, and fallback theme.
- `PresentationLayerEntry` standardizes z-order, opacity, visibility, interaction, occlusion, and reduction fields.
- `CharacterPresentationConfig` and `OutfitPresentationDef` reserve later character and outfit visuals without gameplay stats.
- `PanelState`, `UIVisibilityPolicy`, `NavigationEntry`, and `ShortcutEntry` reserve UI shell behavior without implementing the shell.
- Expedition and long-term summary ViewModels remain read-only output shapes.

## Protocol Boundary

- UI state changes must continue through CommandBus and CommandResult.
- UI reads must continue through ViewModel/snapshot data.
- Presentation contracts resolve semantic IDs only.
- This stage does not connect presentation contracts to scenes or resource loading.

## Art Boundary

- No real art is imported.
- Placeholder asset ids are semantic ids, not direct file paths.
- Future art should enter through catalog/config replacement, not core gameplay changes.

## Validator Boundary

`validate_ui_presentation_layering_g9.ps1` checks this stage's new and modified content. It intentionally scopes resource-coupling checks to files changed by this stage so historical PresentationMapping behavior is not treated as a G9 failure.

## Non-Goals Confirmed

- No full UI implementation.
- No real art import.
- No complete background switching.
- No complete character or outfit system.
- No complete Inventory, GroundLoot, or Settlement UI.
- No full MetaProgress.
- No Deploy persistence.
- No action combat.
- No new gameplay content.
