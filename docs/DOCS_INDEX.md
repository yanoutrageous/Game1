# Docs Index

This file is the document navigation and historical index. It is not the fact source itself; use `docs/PROJECT_BASELINE.md` for current facts and `docs/NEXT_HANDOFF.md` for the minimum next-chat entry.

## Current Fact Sources

- `docs/PROJECT_BASELINE.md` - current engineering fact source.
- `docs/ENGINEERING_STATUS.md` - broader engineering status and validation list.
- `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` - Godot-specific current status.
- `docs/MILESTONES.md` - historical G-number to formal milestone mapping.
- `docs/bugs/G10_BASELINE_BUG_BACKLOG.md` - G10 baseline bug and remaining-scope backlog evidence.

## Next Conversation Minimum Reading

Read these first in a new Codex or ChatGPT conversation:

1. `docs/NEXT_HANDOFF.md`
2. `docs/PROJECT_BASELINE.md`
3. `docs/DOCS_INDEX.md`
4. `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md`
5. `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md`
6. `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`
7. `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md`
8. `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md`
9. `docs/handoff/HANDOFF_TEMPLATE.md` when creating a new branch or closure report

Do not start by reading every old audit, branch change, or design file unless the task needs historical detail.

## Design Documents

- `docs/design/G8_ASSET_LEDGER_INVENTORY_SETTLEMENT_CORE_PLAN.md`
- `docs/design/G9_UI_PRESENTATION_LAYERING_ARCHITECTURE.md`
- `docs/design/G10_FUTURE_CONTENT_PLANNING.md`
- `docs/ui-layout-implementation-plan.md`
- Older design/reference docs under `docs/design/`, `docs/art/`, and root `docs/*.md` are historical unless linked by the current task.

## Audit Evidence

Current and recent audit files live under `docs/audits/`.

- G8 Asset Ledger & Settlement Core audit.
- G8.1 Architecture Hardening audit.
- G8.2 Kernel Protocol Baseline audit.
- G9 Presentation Layering Contracts audit.
- G9 UI Core Flow Baseline audit.
- G10 Progress & Art Smoke Foundation audit.

## Validation Evidence

- `docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md` records the G10 closeout 13-item static validation run.
- `docs/validation/G10_CLOSEOUT_REMOTE_CONFIRMATION_FOLLOWUP.md` records the post-merge remote live confirmation and documentation calibration follow-up.
- `docs/validation/G11_MAINLINE_UX_READABILITY_VALIDATION.md` records the G11 mainline UX readability validation checklist, R3 execution notes, and R4 docs-only closeout record.
- `docs/validation/G12_LEGACY_DEMO_CORE_LOOP_PARITY_VALIDATION.md` records the G12 lightweight legacy Demo core-loop, Chinese readability, typography/readability validation checklist, R3 implementation record, and R4 docs-only closeout notes.

Older audits remain useful for traceability but are not the first source for current state.

## Handoff Documents

Current handoffs live under `docs/handoff/`.

- Use `docs/handoff/HANDOFF_TEMPLATE.md` for every new phase, branch closure, mainline promotion, BUG-fix batch, and runtime smoke report.
- Existing G5-G9 handoffs are historical evidence. They should not be deleted or renamed in this consolidation.
- G10 handoff records bounded stabilization/art-smoke work, closeout, mainline merge status, and remaining out-of-scope systems.
- `docs/handoff/HANDOFF_G11_MAINLINE_UX_READABILITY.md` records the G11 mainline testability and UX readability pass closeout.
- `docs/handoff/HANDOFF_G12_LEGACY_DEMO_CORE_LOOP_PARITY.md` records the G12 legacy Demo core-loop readability and typography parity pass closeout.

## Branch Change Records

Branch change records live under `docs/branch_changes/`. They document what changed on a branch, but they are not the current fact source after mainline promotion.

## Godot Docs

Godot-specific docs live under `Godot/GraytailGodot/docs/`.

- `GODOT_CURRENT_STATUS.md` is the Godot status summary.
- `GODOT_ARCHITECTURE_NOTES.md` describes architecture boundaries.
- `MANUAL_PLAYTEST_GUIDE.md` describes current and historical playtest routes.
- Stage reports such as `GODOT_UI_FINAL_G9_REPORT.md` are evidence for a specific stage.

## Historical Reference

Root-level handoff files, old G2-G7 notes, Lua audit docs, UE docs, and early feasibility files are historical references. Read them only when investigating why a prior decision was made.

## Current Boundary

Current main is `2855ca9889e394fb79d22c468b1355cd3871fd39` and includes G10 Progress & Art Smoke Foundation, the G10 closeout follow-up, the completed G11 mainline UX readability pass, G11 closeout, and the completed G12 lightweight legacy Demo readability/typography pass. It does not represent complete final UI, complete MetaProgress, complete Deploy persistence, or complete long-term system completion.

G10 is complete, merged to main, and closed. It was limited to progress整理, stability/BUG fixes, UI interaction optimization, dev-only diagnostics, art intake smoke, responsive/mobile reservation, and future content planning. It is not complete MetaProgress, Deploy persistence, complete long-term systems, action combat, new gameplay, full art replacement, or broad architecture reshaping.

G11 is complete and closed. G12 is complete and closed as lightweight legacy Demo core-loop, Chinese readability, and typography/readability alignment. It is not a G10/G11 continuation, not G13, not a 1:1 remake, not a new gameplay phase, and not a new systems phase.
