# S2 Path Normalization Report

## Time
2026-06-08 16:05:57 +08:00

## Canonical Paths
- correct_reports: D:\AGAME1\_codex_reports
- correct_repo: D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype
- drift_reports: D:\AGAME1_codex_reports
- drift_repo: D:\AGAME1_repo_cache\Game_feature_editor_playable_prototype

## Path Existence Matrix Before
| key | path | exists | type | file_count | total_bytes |
|---|---|---:|---|---:|---:|
| correct_reports | D:\AGAME1\_codex_reports | True | Directory | 3 | 22364 |
| drift_reports | D:\AGAME1_codex_reports | True | Directory | 1 | 2841 |
| correct_repo | D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype | True | Directory | 582 | 162124499 |
| drift_repo | D:\AGAME1_repo_cache\Game_feature_editor_playable_prototype | False | Missing | 0 | 0 |

## Copy Results

### Reports
- label: reports
- source: D:\AGAME1_codex_reports
- target: D:\AGAME1\_codex_reports
- source_exists: True
- target_created: False
- copied: 1
- skipped_same_hash: 0
- conflicts_copied: 0
  - copied: S1_ASSET_AND_PLACEHOLDER_REPORT.md -> D:\AGAME1\_codex_reports\S1_ASSET_AND_PLACEHOLDER_REPORT.md

### Repo Cache
- label: repo_cache
- source: D:\AGAME1_repo_cache\Game_feature_editor_playable_prototype
- target: D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype
- source_exists: False
- target_created: False
- copied: 0
- skipped_same_hash: 0
- conflicts_copied: 0

## Path Existence Matrix After
| key | path | exists | type | file_count | total_bytes |
|---|---|---:|---|---:|---:|
| correct_reports | D:\AGAME1\_codex_reports | True | Directory | 4 | 25205 |
| drift_reports | D:\AGAME1_codex_reports | True | Directory | 1 | 2841 |
| correct_repo | D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype | True | Directory | 582 | 162124499 |
| drift_repo | D:\AGAME1_repo_cache\Game_feature_editor_playable_prototype | False | Missing | 0 | 0 |

## Notes
- Drift directories were not deleted, moved, renamed, or modified.
- No output was written to drift report or drift repo paths.
- Subsequent S2 outputs use D:\AGAME1\_codex_reports and D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype only.