# Document Lifecycle

> P2 更新：本文件保留为 G20 文档生命周期规则。P2 后当前生命周期规则见 `docs/00_governance/DOCUMENT_LIFECYCLE.md`。

This file defines document lifecycle categories for G20 governance. It does not delete, rename, or move historical documents.

## Lifecycle Types

| type | meaning | maintenance |
| --- | --- | --- |
| `source_design` | Imported or external design source. | Long-term reference; implementation requires a separate plan. |
| `current_status` | Current engineering fact source. | Long-term maintained and updated at closeout. |
| `handoff` | Next-step or stage handoff evidence. | Stage evidence; update when a stage or batch closes. |
| `validation` | Validation scope and result. | Stage evidence; must state exactly what was run. |
| `stage_summary` | Stage-level summary. | Planned in G20-R3c. |
| `route_analysis` | Roadmap or dependency analysis. | Planned in G20-R3c. |
| `project_governance` | Policy, registry, lifecycle, naming, execution environment. | Long-term maintained. |
| `archive` | Preserved historical material. | Read-only reference unless explicitly updated. |
| `deprecated` | No longer preferred source. | Register first; do not delete automatically. |
| `temporary` | Short-lived or uncertain file. | Register first; do not delete automatically. |

## Maintenance Rules

- Current-status documents must be updated when a stage or branch closeout changes the current fact source.
- Handoff and validation documents are stage evidence; they should not be rewritten into broader claims.
- Design source documents do not authorize implementation by themselves.
- Deprecated and temporary files are registered before any rename, move, or deletion.
- R3d will create the detailed branch, commit, validation, temporary/deprecated, decision, and glossary records.

## Closeout Update Set

At closeout, update at minimum:

- `docs/PROJECT_BASELINE.md`
- `docs/ENGINEERING_STATUS.md`
- `docs/NEXT_HANDOFF.md`
- `docs/DOCS_INDEX.md`
- `docs/MILESTONES.md`
- relevant handoff and validation records
- `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md` when Godot-facing status changes
- `Godot/GraytailGodot/docs/MANUAL_PLAYTEST_GUIDE.md` when validation or manual scope changes
