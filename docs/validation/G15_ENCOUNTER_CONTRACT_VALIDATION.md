# G15 Encounter Contract Validation

## Scope

- Stage: G15 Encounter Contract Foundation.
- Branch: `godot/g15-encounter-contract-foundation`.
- Baseline: `d6c03c6ff8ca9884f992a61e27728bdddf3a637a` (`docs: close G14 legacy demo UI surface pass`).
- R3 commit: `aca5b958a588879a16da97616484424da795da7f feat(godot): add encounter contract foundation`.
- R4 commit: `1887385af81624ebcd84342ca765d75e6fbf20eb feat(godot): add encounter slot surface adapter`.
- R5 status: docs-only closeout / handoff / status calibration.
- Merged to main: no.
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

## R4 UI EncounterSlot Adapter Record

- Adds the first UI consumer for public `encounter_view_model` and `encounter_result_summary`.
- `RunSurfaceModel` builds a display-only encounter section from snapshot public fields only.
- `RunSurface` renders a lightweight EncounterSlot inside the existing run surface and emits `encounter_option_selected(option_id, command_payload)`.
- Disabled options stay visible with `disabled_reason` and do not dispatch.
- `requires_confirm` is display-only in G15-R4; no new confirmation modal is added.
- `run_scene.gd` only wires the RunSurface signal to `_dispatch_command(&"select_encounter_option", payload)` and adds `source: "ui"`.
- Encounter rewards continue to use the existing loot feedback path when `last_reward` is present.
- Existing EventOptionPanel, LootResultPanel, ExtractConfirmPanel, Inventory, GroundLoot, ResultPanel, MapOverlay, screen routing, and old command semantics are not migrated or replaced.

## R4 Boundaries

- UI consumes only public snapshot fields and public option payloads.
- UI does not read `TruthMap`, `RunRuleService`, Ledger, `AssetLedger`, `RunAssetLedger`, or `RunContext` private rule objects.
- UI does not bypass CommandBus and does not decide rule outcomes.
- G15-R4 does not implement combat rooms, action combat, lottery systems, out-of-run progression, MetaProgress, Deploy persistence, full event libraries, unique collectibles, warehouse, codex, appearance library, or duplicate compensation.
- G15-R4 does not modify `project.godot`, resources, fonts, import products, `.uid`, or `.translation` files.
- Godot/editor/game/import was not run for this static validation; do not claim runtime PASS.

## R4 Static Validation Commands

Run from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "encounter_view_model|encounter_result_summary|encounter_option_selected|select_encounter_option|TruthMap|RunRuleService|RunAssetLedger|AssetLedger|CommandBus\\.dispatch" Godot/GraytailGodot/scripts/ui Godot/GraytailGodot/scripts/core/run/run_scene.gd
rg -n "lottery|pity|pool|unique collectible|warehouse|codex|appearance|MetaProgress|Deploy persistence|action combat" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
```

Expected R4 static result:

- `RunSurfaceModel` references `encounter_view_model` and `encounter_result_summary` only as public snapshot fields.
- `RunSurface` owns EncounterSlot rendering and the public option-selected signal only.
- `run_scene.gd` dispatches only `select_encounter_option` for EncounterSlot selections.
- Disabled option UI has no dispatch path.
- Runtime PASS remains unclaimed until later explicit runtime smoke or manual test.

## R5 Closeout Record

- G15-R5 is docs-only closeout / handoff / status calibration.
- R3 and R4 are complete, committed, and pushed on `godot/g15-encounter-contract-foundation`.
- Branch HEAD before R5 closeout execution: `1887385af81624ebcd84342ca765d75e6fbf20eb`.
- Current branch is not merged to `main`.
- G15 completed the first encounter framework foundation only:
  - rules-layer public/display contract;
  - `EncounterResolver` public/display adapter;
  - public `encounter_view_model`;
  - public `encounter_result_summary`;
  - additive `select_encounter_option` bridge;
  - `RunSurfaceModel` display-only adapter;
  - `RunSurface` EncounterSlot;
  - minimal `run_scene.gd` wiring;
  - validation and manual checklist updates.
- G15 still does not implement full combat rooms, action combat, out-of-run progression, lottery systems, unique collectibles, warehouse/codex/appearance library systems, MetaProgress, Deploy persistence, full event libraries, or mainline promotion.
- Godot/editor/game/import was not run during G15-R5, and this document does not claim runtime PASS.
- G16 is not started.

## R5 Static Validation Commands

Run from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "G15|Encounter|EncounterSlot|runtime PASS|Godot/editor/game/import|G16|combat|lottery|MetaProgress|Deploy persistence" docs Godot/GraytailGodot/docs
```

Expected R5 static result:

- Current docs state G15 R3/R4 are complete and R5 is closeout.
- Current docs do not state that G15 is merged to main.
- Current docs do not state runtime PASS.
- G16, combat rooms, lottery, out-of-run progression, MetaProgress, Deploy persistence, and full event libraries remain future candidates or explicit non-goals.
- No Godot runtime/UI code, rules code, `project.godot`, resources, fonts, import products, `.uid`, or `.translation` files are modified by R5.
