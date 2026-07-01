# Source Registry

Status: current source registry after G40 Slice 4.

## Current External Source Roots

| Source | Current path | Legacy path before G40 | Status | Rule |
| --- | --- | --- | --- | --- |
| Planning originals | `D:\AGAME1\sources\docs` | `D:\AGAME1\Base Docs` | protected source | register/cite; do not rewrite |
| Governance snapshots | `D:\AGAME1\sources\docs_governance` | `D:\AGAME1\Base Docs_Governance` | external snapshot | not current repo fact source |
| Base art | `D:\AGAME1\sources\art` | `D:\AGAME1\Base Art` | protected art source | not runtime asset unless imported by gate |
| Draw/candidate art | `D:\AGAME1\sources\draw` | `D:\AGAME1\Draw` | candidate/source art | not runtime asset unless imported by gate |
| Connection handoff | `D:\AGAME1\handoff\connection` | `D:\AGAME1\Connection` | external handoff | register only; do not copy content into repo |
| Legacy Godot shell | `D:\AGAME1\external\godot_reference\Godot` | `D:\AGAME1\Godot` | external reference | not active project; not runtime executable source |
| Code audit 20260622 | `D:\AGAME1\reports\code_audit_20260622` | `D:\AGAME1\AGAME1_code_audit_delivery_report_20260622.*` | historical report | not current project truth |

## Legacy Path Labels

- Legacy path before G40: `D:\AGAME1\Base Docs`
  Moved to: `D:\AGAME1\sources\docs`
  Do not use as current canonical path: `D:\AGAME1\Base Docs`
- Legacy path before G40: `D:\AGAME1\Base Docs_Governance`
  Moved to: `D:\AGAME1\sources\docs_governance`
  Do not use as current canonical path: `D:\AGAME1\Base Docs_Governance`
- Legacy path before G40: `D:\AGAME1\Base Art`
  Moved to: `D:\AGAME1\sources\art`
  Do not use as current canonical path: `D:\AGAME1\Base Art`
- Legacy path before G40: `D:\AGAME1\Draw`
  Moved to: `D:\AGAME1\sources\draw`
  Do not use as current canonical path: `D:\AGAME1\Draw`
- Legacy path before G40: `D:\AGAME1\Connection`
  Moved to: `D:\AGAME1\handoff\connection`
  Do not use as current canonical path: `D:\AGAME1\Connection`
- Legacy path before G40: `D:\AGAME1\Godot`
  Moved to: `D:\AGAME1\external\godot_reference\Godot`
  Do not use as current active Godot project path: `D:\AGAME1\Godot`
- Legacy root report files before G40: `D:\AGAME1\AGAME1_code_audit_delivery_report_20260622.*`
  Moved to: `D:\AGAME1\reports\code_audit_20260622`
  Treat as historical audit delivery artifacts, not current project truth.

## Active Repo

```text
D:\AGAME1\_repo_cache\Game1_work
```

## Source Use Rules

- A source path can support a requirement or audit claim, but it does not become a repository fact until repo docs/code explicitly implement it.
- Do not infer current gameplay completion from source documents.
- Do not treat historical screenshots, UI references, or art candidates as runtime assets.
- Do not deduplicate protected sources destructively.

## G40 Working Reports Outside Repo

```text
D:\AGAME1\reports\g40\cleanup_inventory.json
D:\AGAME1\reports\g40\duplicate_file_inventory.csv
D:\AGAME1\reports\g40\duplicate_resolution_plan.csv
D:\AGAME1\reports\g40\cleanup_decisions.md
D:\AGAME1\reports\g40\duplicate_resolution_plan_current_paths.csv
D:\AGAME1\reports\g40\cleanup_execution_log.md
D:\AGAME1\reports\g40\archive_execution_log.csv
D:\AGAME1\reports\g40\remaining_manual_decisions.md
D:\AGAME1\reports\g40\remaining_reference_blockers.md
```

These are cleanup evidence during G40 and are not gameplay source material.
