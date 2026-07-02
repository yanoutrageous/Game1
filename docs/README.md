# Game1 Docs

This directory is the current documentation entrypoint for the active Game1 repo.

Read first:

```text
docs/README.md
docs/INDEX.md
docs/10_current/CURRENT_STATE.md
docs/10_current/CAPABILITY_MATRIX.yaml
docs/10_current/AUDIT_SCOPE.md
docs/00_governance/DOC_PLACEMENT_STANDARD.md
docs/00_governance/DUPLICATE_DOC_LEDGER.md
docs/00_governance/SOURCE_REGISTRY.md
```

Current external source roots after G40 Slice 3:

```text
D:\AGAME1\sources\docs
D:\AGAME1\sources\docs_governance
D:\AGAME1\sources\art
D:\AGAME1\sources\draw
D:\AGAME1\handoff\connection
```

Legacy path before G40: `D:\AGAME1\Base Docs`
Moved to: `D:\AGAME1\sources\docs`
Do not use as current canonical path: `D:\AGAME1\Base Docs`

Legacy path before G40: `D:\AGAME1\Connection`
Moved to: `D:\AGAME1\handoff\connection`
Do not use as current canonical path: `D:\AGAME1\Connection`

## Current Validation

Run the current G40 validation entrypoint from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_current_project.ps1
```

Current expected marker during G40 cleanup:

```text
G40_UNIFIED_VALIDATION=PASS_WITH_NOTES
```

Current G40 stage documentation:

```text
docs/20_product/G40_FULL_PROJECT_CLEANUP_REPOSITORY_REMEDIATION_VALIDATION_STABILIZATION_CONTRACT.md
docs/validation/G40_FULL_PROJECT_CLEANUP_VALIDATION.md
docs/handoff/HANDOFF_G40_FULL_PROJECT_CLEANUP_REPOSITORY_REMEDIATION_VALIDATION_STABILIZATION.md
```

Recent ART closeout evidence:

```text
docs/art/ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION.md
docs/art/ART20_CLOSEOUT_PIPELINE_PASS_VISUAL_INCOMPLETE.md
```

ART-20 is a pipeline proof closeout, not final UI visual acceptance.

Directory responsibilities:

| Directory | Responsibility |
| --- | --- |
| `00_governance/` | document governance, source registry, duplicate ledgers, lifecycle rules |
| `10_current/` | current state, next action, capability matrix, audit scope |
| `20_product/` | product contracts and system boundary contracts |
| `30_engineering/` | engineering notes, ADRs, Godot docs registration |
| `40_validation/` | validation index |
| `50_stages/active/` | active stage index |
| `50_stages/closed/` | closed stage index |
| `60_interfaces/connection/` | Connection source registration |
| `70_sources/` | Base Docs / art / UI reference source registration |
| `90_archive/` | historical, legacy, generated-report explanations |
| `validation/` | stage validation originals |
| `handoff/` | stage handoff originals |

Rules:

- Do not place new long-lived documents in the docs root.
- Do not copy external source bodies into repo docs.
- Register duplicate or legacy material before moving or deleting it.
- Current entrypoints are preferred in Chinese when practical; historical English files are not forcibly translated.
- New contract / validation / handoff documents should include at least a Chinese summary.
- Stage planning / audit / execution / closeout process rules live in `docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md`.
