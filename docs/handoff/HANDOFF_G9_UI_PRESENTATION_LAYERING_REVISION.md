# Handoff: G9 UI Presentation Layering Revision

## Current Branch

`godot/g9-ui-presentation-layering-revision`

## Current Stage

G9 defines the presentation layering contract for later UI and art work. It revises background theme switching into a fixed base background plus independent overlay layers.

## What Changed

- Added the G9 presentation layering architecture document.
- Added contract-only presentation schemas in `PresentationLayerContracts`.
- Reserved ThemeProfile, PresentationLayerEntry, CharacterPresentationConfig, OutfitPresentationDef, PanelState, UIVisibilityPolicy, NavigationEntry, ShortcutEntry, ExpeditionSummaryViewModel, and LongTermSummaryViewModel.
- Added validation for the G9 documentation and contract boundary.
- Updated engineering, Godot status, and architecture notes.

## Follow-Up Rules

UI line:

- Dispatch state-changing actions through CommandBus.
- Read run state through ViewModel/snapshot data only.
- Use Presentation contracts to resolve semantic IDs into layer and visual entries.
- Do not read or write `RunAssetLedger`, `TruthMap`, or private run-rule state.

Art line:

- Add real art through asset ids, catalog entries, layer config, ThemeProfile, CharacterPresentationConfig, or panel skin definitions.
- Do not bake map theme, character outfit, props, VFX, or UI state into the base background.
- Keep fallback asset ids available for missing art.

Rules line:

- Continue to expose semantic IDs and ViewModel fields.
- Do not introduce image paths, textures, or resource loading into core gameplay code.

Reduction line:

- Use `reduction_group`, `compact_allowed`, `summary_mode`, and `visibility_condition` to hide or downgrade busy UI layers.
- Do not solve UI density by rebuilding the page architecture.

## Validation Commands

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_architecture_hardening_g8_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_kernel_protocol_g8_2.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_presentation_layering_g9.ps1
```

## Known Limits

- No full UI shell.
- No main page, expedition page, or long-term page implementation.
- No real art import.
- No complete character or outfit system.
- No complete Inventory, GroundLoot, or Settlement UI.
- No full MetaProgress or Deploy persistence.
- No action combat.
- No Godot/editor/game/import run in this stage.
