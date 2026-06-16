# Source of Truth Policy

This file defines Source of Truth priority for G20 project knowledge governance. It does not replace current status files, validation records, or implementation plans.

## Priority Order

1. Current mainline fact sources: `docs/PROJECT_BASELINE.md`, `docs/ENGINEERING_STATUS.md`, `docs/NEXT_HANDOFF.md`, `docs/DOCS_INDEX.md`, `docs/MILESTONES.md`, `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`, and `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md`.
2. Repository design sources under `docs/design_sources/`.
3. Handoff records under `docs/handoff/`.
4. Validation records under `docs/validation/`.
5. Stage summaries planned for G20-R3c.
6. Route analysis planned for G20-R3c.
7. Historical, archive, deprecated, or temporary references.
8. External Base Docs originals at `D:\AGAME1\Base Docs`.

## Rules

- Current engineering truth comes from repository current-status documents first.
- Imported design source files are versioned planning references, not direct implementation checklists.
- External Base Docs originals are creative sources. They are not direct execution input unless the user explicitly reauthorizes a source and target mapping.
- Validation records only prove the scope they explicitly validated.
- `Godot headless project-load/parser smoke PASS` is not `gameplay runtime PASS` and not `manual playtest PASS`.
- A foundation stage must not be described as a complete system unless a validation record proves the complete system boundary.
- R3d governance files such as branch inventory, commit milestone map, validation matrix, temporary/deprecated inventory, decision log, and glossary are planned in R3d and are not created by R3b.
