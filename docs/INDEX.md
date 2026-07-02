# Game1 Docs Index

Current docs entrypoints:

```text
docs/README.md
docs/10_current/CURRENT_STATE.md
docs/10_current/CAPABILITY_MATRIX.yaml
docs/10_current/AUDIT_SCOPE.md
docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md
docs/10_current/G40_HEALTH_ISSUE_CLOSURE_MATRIX.md
docs/00_governance/DOC_PLACEMENT_STANDARD.md
docs/00_governance/DUPLICATE_DOC_LEDGER.md
docs/00_governance/SOURCE_REGISTRY.md
```

Stage process governance:

```text
docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md
```

Use this file when starting a new stage, auditing a stage plan, recovering from long context, or preparing high-risk execution gates. It is not part of the always-read entrypoint set for ordinary doc navigation.

Recent ART closeout evidence:

```text
docs/art/ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION.md
docs/art/ART20_CLOSEOUT_PIPELINE_PASS_VISUAL_INCOMPLETE.md
tools/validate_art20_ui_asset_pipeline.ps1
```

ART-20 is closed as a pipeline proof with visual gaps. It must not be read as final UI visual acceptance; ART-21 must add image placement indexing and target visual reconstruction.

Current G40 validation / cleanup helper tools:

```text
tools/validate_current_project.ps1
tools/inspect_dirty_state.ps1
tools/scan_g40_path_references.ps1
tools/validate_g40_cleanup_topology.ps1
tools/clean_generated_dirty_state.ps1
tools/prepare_validation_clean_state.ps1
```

Current validation entrypoint:

```powershell
powershell -ExecutionPolicy Bypass -File tools/validate_current_project.ps1
```

Current stage:

```text
G40 = Full Project Cleanup, Repository Remediation & Validation Stabilization
branch = godot/g40-full-project-cleanup-validation-stabilization
```

G40 current facts:

- `D:\AGAME1` topology is being rebuilt into active / sources / handoff / archive / reports / workflow / tools / external.
- Active repo remains physically at `D:\AGAME1\_repo_cache\Game1_work`.
- External source paths moved by G40 are registered in `docs/00_governance/SOURCE_REGISTRY.md`.
- Duplicate decisions are tracked outside the repo during G40 in `D:\AGAME1\reports\g40\duplicate_resolution_plan.csv` and `D:\AGAME1\reports\g40\cleanup_decisions.md`.
- `project.godot` dirty is pre-existing and not part of Slice 4 docs changes.

Recent engineering evidence remains in product/validation/handoff files. This index does not upgrade historical validation into gameplay runtime PASS or manual playtest PASS.

Important non-goals are listed in:

```text
docs/10_current/KNOWN_UNFINISHED_SYSTEMS.md
```

Current G40 stage docs:

```text
docs/20_product/G40_FULL_PROJECT_CLEANUP_REPOSITORY_REMEDIATION_VALIDATION_STABILIZATION_CONTRACT.md
docs/validation/G40_FULL_PROJECT_CLEANUP_VALIDATION.md
docs/handoff/HANDOFF_G40_FULL_PROJECT_CLEANUP_REPOSITORY_REMEDIATION_VALIDATION_STABILIZATION.md
```
