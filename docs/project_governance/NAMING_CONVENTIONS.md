# Naming Conventions

This file defines document naming rules for G20 governance. It does not rename existing files by itself.

## Stage Prefixes

- Stage-specific files use a `G##_` prefix.
- Single-digit stages use two digits: `G09`, not `G9`.
- Current active fact sources do not need a `G##_` prefix.
- Active cross-stage design sources use stable system names, such as `main_menu_design.md` or `deploy_prep_rules.md`.
- Historical, legacy, or reference design sources use `G##_`, `LEGACY`, or `REFERENCE` when the stage or status is known.
- Uncertain files are marked `needs review`; do not force a rename without evidence.

## Rename Safety

- G20 does not bulk rename old documents in R3b.
- Any future rename must update `DOCS_INDEX`, `SOURCE_REGISTRY`, temporary/deprecated inventory, and all relevant links.
- Deprecated and temporary files are registered before any move or deletion.
- Branch names and Git history are not rewritten to match document naming.
