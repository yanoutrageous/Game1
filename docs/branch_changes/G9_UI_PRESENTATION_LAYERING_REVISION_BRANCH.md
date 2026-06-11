# Branch Change: G9 UI Presentation Layering Revision

## Branch

`godot/g9-ui-presentation-layering-revision`

## Base

`main` at `c5fa0622f98be5b8cb61eedefdfa9990027c00e7`.

## Purpose

G9 corrects UI planning so the main background is not baked together with map theme, character outfit, props, atmosphere, foreground effects, or UI panels. It establishes a fixed base background plus independent Presentation Overlay contracts.

## Implemented

- G9 presentation layering architecture document.
- Contract-only `PresentationLayerContracts` schemas and placeholder examples.
- ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, OutfitPresentationDef, PanelState, UIVisibilityPolicy, NavigationEntry, ShortcutEntry, ExpeditionSummaryViewModel, and LongTermSummaryViewModel contracts.
- G9 audit and handoff docs.
- Engineering, Godot status, and architecture notes updates.
- `validate_ui_presentation_layering_g9.ps1`.

## Not Implemented

- No full UI shell navigation.
- No complete main page, expedition page, or long-term page.
- No real art import.
- No complete background switching.
- No complete character or outfit system.
- No complete Inventory, GroundLoot, or Settlement UI.
- No full MetaProgress or Deploy persistence.
- No action combat.
- No new gameplay content.
- No Godot editor/runtime/import run in this stage.
