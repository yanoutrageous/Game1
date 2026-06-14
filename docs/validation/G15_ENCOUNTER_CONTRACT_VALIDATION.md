# G15 Encounter Contract Validation

## Scope

- Stage: G15 Encounter Contract Foundation.
- R3 branch: `godot/g15-encounter-contract-foundation`.
- Baseline: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a` (`docs: close G14 legacy demo UI surface pass`).
- G14, G13, G12, G11, and G10 are complete and closed.
- G16 is not started.

## R3 Implementation Record

- Adds `EncounterContract` as a rules-layer public Dictionary schema helper.
- Adds `EncounterResolver` as a read-only adapter from `RunContext` to encounter identity, state, options, view model, and result summary.
- Exposes `encounter_view_model` and `encounter_result_summary` through `RunQueryFacade`.
- Adds additive CommandBus command `select_encounter_option`.
- First-wave adapters cover only search/chest and existing event options.
- `select_encounter_option` delegates search/chest to existing `search_current_room()` and event options to existing `select_event_option()`.
- Existing `search_current_room`, `select_event_option`, `request_extract`, and `confirm_extract` semantics are unchanged.

## Contract Fields

`EncounterOption` entries must include:

- `id`
- `title`
- `cost`
- `expected_reward`
- `risk`
- `one_shot`
- `requires_confirm`
- `disabled`
- `disabled_reason`
- `command_name`
- `command_payload`

`EncounterResult` / effect summaries must be able to represent:

- black coin / gold coin deltas
- item and backpack changes
- Buff / Debuff or status effects
- HP and pressure changes
- room state and encounter state changes
- log entries
- settlement summary changes

## Boundaries

- UI must consume `encounter_view_model` only after the R3 contract commit is pushed.
- UI must not read `TruthMap`, `RunRuleService`, Ledger, `AssetLedger`, or private rule state.
- Encounter contract must not bypass CommandBus.
- G15-R3 does not modify `run_scene.gd`, `RunSurface`, `RunSurfaceModel`, `presentation_mapping.gd`, resources, fonts, import products, `.uid`, `.translation`, or `project.godot`.
- G15-R3 does not migrate event / loot / extract decisions.
- G15-R3 does not implement combat room, action combat, out-of-run progression, MetaProgress, Deploy persistence, lottery, unique collectibles, warehouse, codex, appearance library, duplicate compensation, or record systems.
- `lottery` is reserved only as a future encounter type name.

## Parallel Ownership

- Computer one / rules line owns `scripts/core/run/encounter/*`, `command_bus.gd`, `run_rule_service.gd`, `run_query_facade.gd`, and G15 validation/status docs for R3.
- Computer two / UI line must wait for the R3 contract commit before adding an EncounterSlot or UI adapter.
- Do not modify high-conflict files from both lines in parallel: `run_scene.gd`, `run_ui_view_model.gd`, `presentation_mapping.gd`, `RunSurfaceModel`, and global status / handoff / validation docs.
- Two computers must not push directly to `main` in parallel.

## Static Validation Commands

Run from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "Encounter|EncounterOption|EncounterResult|EncounterViewModel|CommandBus|RunSurface|TruthMap|Ledger|AssetLedger|lottery|combat|extract|loot|event" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
rg -n "TruthMap|RunRuleService|RunAssetLedger|AssetLedger|CommandBus\\.dispatch" Godot/GraytailGodot/scripts/ui Godot/GraytailGodot/scripts/core/run/encounter
```

Expected static result:

- `EncounterContract` and `EncounterResolver` exist.
- `encounter_view_model` and `encounter_result_summary` are public snapshot fields.
- `select_encounter_option` is additive and does not replace old commands.
- Encounter UI-facing data does not expose private rule objects.
- Existing Godot dirty whitelist is not staged or committed.
- No outside-repository temporary scripts, logs, caches, or generated outputs are created.

## Runtime Status

- Godot/editor/game/import is not run for G15-R3 by default.
- This validation does not claim runtime PASS.
- Manual or runtime verification requires explicit later authorization.
