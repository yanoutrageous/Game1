# Handoff: G9 UI Final Integration

## Current Branch

`godot/g9-ui-final-integration`

## Current Stage

G9 UI Final Integration establishes the playable UI baseline for the current Godot branch.

## What Changed

- `G9ShellPanel` owns the three-page shell.
- `InventoryPanel` owns formal inventory display and drop requests.
- `GroundLootPanel` owns current-room ground loot display and pickup requests.
- `RunUIViewModel` formats blocked reasons, item tooltips, expedition/long-term summaries, EventLog, TransactionLog, and settlement explanations.
- `run_scene.gd` is reduced to scene assembly, routing, signal binding, CommandBus dispatch forwarding, and refresh distribution.
- `ResultPanel` uses the UI ViewModel to explain success/failure settlement.

## Follow-Up Rules

UI line:

- Read state from snapshots/ViewModels.
- Dispatch state changes through `CommandBus.dispatch`.
- Do not read or write `RunAssetLedger`, `TruthMap`, or private run state.
- Keep Debug folded and dev-only.

Rules line:

- Continue extending RulePipeline, ModifierSpec, RunAssetEffectHandler, and ledger contracts.
- Do not add UI state mutations from rules.

Content/art line:

- Add future art through PresentationLayerContracts, PresentationMapping, ContentDB, or AssetCatalog.
- Do not bake map theme, character outfit, or VFX into the base background.

G10 suggestions:

- Dedicated UI layout polish and accessibility pass.
- Formal ViewModel extraction for shell pages.
- Optional persisted settings after storage boundary is approved.
- Full MetaProgress/warehouse/task/codex/research only after dedicated planning.

## Validation

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_ui_final_g9.ps1
```

Then run the full validation chain listed in `docs/ENGINEERING_STATUS.md`.
