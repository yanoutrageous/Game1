# Duplicate Document Ledger

Status: current duplicate documentation ledger after I0.6.

This ledger records document/source duplication decisions. It does not authorize deletion by itself.

## Current Entry Documents

| Document | Status |
| --- | --- |
| `docs/README.md` | current docs entrypoint |
| `docs/INDEX.md` | current docs index |
| `docs/10_current/CURRENT_STATE.md` | current state summary |
| `docs/10_current/CAPABILITY_MATRIX.yaml` | current capability matrix |
| `docs/10_current/NEXT_ACTION.md` | current next action |
| `docs/10_current/I0_BASELINE_ASSESSMENT.md` | I0 baseline assessment; freeze after closeout |
| `docs/00_governance/DOC_PLACEMENT_STANDARD.md` | current placement rules |
| `docs/00_governance/SOURCE_REGISTRY.md` | current source registry |
| `docs/00_governance/DUPLICATE_DOC_LEDGER.md` | current duplicate ledger |

## G40 Duplicate Evidence

| Evidence | Location | Status |
| --- | --- | --- |
| Full inventory | `D:\AGAME1\reports\g40\cleanup_inventory.json` | G40 working report |
| Duplicate file inventory | `D:\AGAME1\reports\g40\duplicate_file_inventory.csv` | G40 working report |
| Duplicate resolution plan | `D:\AGAME1\reports\g40\duplicate_resolution_plan.csv` | G40 working report |
| Directory duplicate inventory | `D:\AGAME1\reports\g40\duplicate_directory_inventory.csv` | G40 working report |
| Cleanup decisions | `D:\AGAME1\reports\g40\cleanup_decisions.md` | G40 working report |
| Current-path duplicate manifest | `D:\AGAME1\reports\g40\duplicate_resolution_plan_current_paths.csv` | G40 Slice 9B execution manifest |
| Cleanup execution log | `D:\AGAME1\reports\g40\cleanup_execution_log.md` | G40 Slice 9B execution log |
| Archive execution log | `D:\AGAME1\reports\g40\archive_execution_log.csv` | G40 Slice 9B archive log |
| Remaining manual decisions | `D:\AGAME1\reports\g40\remaining_manual_decisions.md` | G40 Slice 9B unresolved list |
| Remaining reference blockers | `D:\AGAME1\reports\g40\remaining_reference_blockers.md` | G40 Slice 9B unresolved list |

## Policy

- Current docs stay in the current docs entrypoints above.
- Historical validation and handoff originals stay in `docs/validation/` and `docs/handoff/`.
- External source content stays under `D:\AGAME1\sources` or `D:\AGAME1\handoff`.
- Duplicate files are not deleted until an approved cleanup execution slice.
- Reference-blocked duplicates must wait for path migration before archive/delete.

## Known Duplicate Classes

| Class | Current handling |
| --- | --- |
| Stale worktree duplicates | archive/delete candidate after Git-safe review |
| Historical report duplicates | archive candidate |
| Protected source duplicates | keep; optional review only |
| Generated/cache duplicates | ignore or clean only under metadata policy |
| Active repo duplicate assets/docs | manual decision before action |

## I0 Supersession And Encoding Decisions

| Document group | Current handling |
| --- | --- |
| `docs/PROJECT_BASELINE.md`, `docs/ENGINEERING_STATUS.md`, `docs/NEXT_HANDOFF.md`, `docs/project_governance/` | retain as expanded / historical evidence; current authority is the I0 current chain |
| `docs/10_current/G40_HEALTH_ISSUE_CLOSURE_MATRIX.md` | retain as G40 historical stage matrix; removed from current first-entry set |
| `docs/00_governance/P2_EXECUTION_REPORT.md` | retain byte-damaged historical evidence with exact encoding-ledger hash |
| `docs/20_product/PRODUCT_CONTRACT.md` | retain byte-damaged P2 draft; it is not the approved I0 contract |
| three byte-damaged README indexes | preserve exact preimage; current navigation is carried by valid `I0_INDEX.md` companions registered in `TEXT_ENCODING_LEDGER.md` |
