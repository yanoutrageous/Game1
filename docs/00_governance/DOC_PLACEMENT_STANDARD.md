# Document Placement Standard

Status: current governance rule after I0.6.

Current repository docs entrypoint:

```text
D:\AGAME1\active\Game1_work\docs
```

Current external source roots:

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

## Placement Rules

| Document type | Location |
| --- | --- |
| Current state / next step / capability matrix | `docs/10_current/` |
| Current baseline assessment | `docs/10_current/` |
| Governance / source / lifecycle / duplicate ledgers | `docs/00_governance/` |
| Product contracts / planning rules / system boundaries | `docs/20_product/` |
| Engineering notes / ADR / Godot docs registry | `docs/30_engineering/` |
| Validation index | `docs/40_validation/VALIDATION_INDEX.md` |
| Active stage index | `docs/50_stages/active/STAGE_INDEX.md` |
| Closed stage index | `docs/50_stages/closed/STAGE_INDEX.md` |
| Stage validation originals | `docs/validation/` |
| Stage handoff originals | `docs/handoff/` |
| Connection source registration | `docs/60_interfaces/connection/` |
| Base Docs / UI reference source registration | `docs/70_sources/` |
| Historical / legacy / generated-report explanations | `docs/90_archive/` |

## External Source Rules

- Base Docs are user-injected original source content. Do not copy or rewrite source bodies into repo docs.
- Base Docs Governance is an external snapshot, not the current repository fact source.
- Connection is an external handoff area. Register paths and hashes when needed; do not import content into Git by default.
- Base Art / Draw are source/candidate material unless separately imported into runtime assets by an approved art gate.

## Naming Guidance

```text
Gxx_TOPIC_CONTRACT.md
Gxx_TOPIC_VALIDATION.md
HANDOFF_Gxx_TOPIC.md
ARTxx_TOPIC.md
DOC_GOV_xxx_TOPIC.md
README.md
*_INDEX.md
*_REGISTRY.md
```

## New Document Principles

1. If type is known, place it directly in the correct directory.
2. Do not keep long-lived new docs in the docs root.
3. Do not copy Base Docs bodies to solve citation problems.
4. Register duplicate content in `DUPLICATE_DOC_LEDGER.md` before deletion or archive.
5. Current entrypoints prefer Chinese summaries where practical; historical English files are not forcibly translated.
6. New contract / validation / handoff documents should include at least a Chinese summary.
7. Do not rewrite old validation / handoff into current facts; downgrade or label through indexes.
8. A completed baseline assessment is frozen as stage evidence; future changes belong in `CURRENT_STATE.md` or a new approved assessment.
