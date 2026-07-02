# Closed Stage Index

Status: readable closed-stage summary after G40 Slice 7.

This index points to historical evidence. It does not rewrite historical validation or handoff originals.

## Recent Closed / Baseline Stages

| Stage | Status | Primary evidence | Boundary |
| --- | --- | --- | --- |
| ART-20 | closed_with_visual_gap | `docs/art/ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION.md`; `docs/art/ART20_CLOSEOUT_PIPELINE_PASS_VISUAL_INCOMPLETE.md`; `docs/art/validation/art20/`; `tools/validate_art20_ui_asset_pipeline.ps1` | ART pipeline proof complete: staging, cutting, runtime import, manifest, visual_key and UI consumer smoke passed. Final UI visual target not achieved; ART-21 must add placement index and target visual reconstruction. |
| M5 | closed / merged baseline before G40 | `docs/validation/M5_MINIMUM_ITEM_PACK_DROP_LOOP_FULL_CONTENT_VALIDATION.md`; `docs/handoff/HANDOFF_M5_MINIMUM_ITEM_PACK_DROP_LOOP_FULL_CONTENT.md` | Latest gameplay baseline before G40; no new G40 gameplay claim |
| G39 | closed / route closure evidence | `docs/validation/G39_NAVIGATION_BOUNDARY_ROUTE_CLOSURE_VALIDATION.md`; `docs/handoff/HANDOFF_G39_NAVIGATION_BOUNDARY_ROUTE_CLOSURE.md` | Navigation boundary closure; no full settings/Profile UI |
| M3H | closed / item loop hardening evidence | `docs/validation/M3H_ITEM_LOOP_HARDENING_VALIDATION.md`; `docs/handoff/HANDOFF_M3H_ITEM_LOOP_HARDENING.md` | Item loop hardening; no full warehouse/Rule Engine |
| M3R | closed / item usability evidence | `docs/validation/M3R_ITEM_USABILITY_COMPLETION_VALIDATION.md`; `docs/handoff/HANDOFF_M3R_ITEM_USABILITY_COMPLETION.md` | Usability supplement; no complete LongTerm/Codex/equipment economy |
| M3 | closed / minimum item-drop loop evidence | `docs/validation/M3_MINIMUM_ITEM_DROP_LOOP_VALIDATION.md`; `docs/handoff/HANDOFF_M3_MINIMUM_ITEM_DROP_LOOP.md` | GroundLoot-first minimum loop |
| M2 | closed / playable loop evidence | `docs/validation/M2_LUA_UE_EFFECT_FIRST_PLAYABLE_LOOP_VALIDATION.md`; `docs/handoff/HANDOFF_M2_LUA_UE_EFFECT_FIRST_PLAYABLE_LOOP.md` | Lua / UE effect-first playable loop alignment |
| G38 | closed evidence | `docs/validation/G38_RUNTIME_ARCHITECTURE_FINALIZATION_VALIDATION.md`; `docs/handoff/HANDOFF_G38_RUNTIME_ARCHITECTURE_FINALIZATION.md` | Runtime architecture evidence |
| G37 | closed evidence | `docs/validation/G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_VALIDATION.md`; `docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION.md` | Runtime authority evidence |
| G36 and earlier | historical evidence | `docs/validation/`; `docs/handoff/`; `docs/stage_summaries/` | Historical stage evidence only |

## Archive Rule

- Keep validation and handoff originals in their original folders unless a later archive gate explicitly moves them.
- Do not use this index to claim gameplay runtime PASS or manual playtest PASS.
- Do not use this index to delete duplicate historical evidence.
