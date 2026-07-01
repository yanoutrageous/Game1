# Audit Entrypoint

Use this file to start a read-only audit of the active repo after G40 Slice 4.

Read first:

```text
README.md
AGENTS.md
docs/README.md
docs/INDEX.md
docs/10_current/CURRENT_STATE.md
docs/10_current/CAPABILITY_MATRIX.yaml
docs/10_current/AUDIT_SCOPE.md
docs/00_governance/DOC_PLACEMENT_STANDARD.md
docs/00_governance/SOURCE_REGISTRY.md
docs/00_governance/DUPLICATE_DOC_LEDGER.md
```

Current external sources:

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

Audit boundary:

- Check Git state before trusting working tree content.
- Separate pre-existing `project.godot` dirty from G40 documentation/tool changes.
- Do not claim gameplay runtime PASS or manual playtest PASS from docs-only validation.
- Do not use stale worktrees under `_repo_cache` as current facts unless explicitly requested.
