# AGENTS

Objective rule: evaluate facts as objectively and completely as possible; do not follow user preference over repository evidence.

Current authority:

```text
active_repo = D:\AGAME1\_repo_cache\Game1_work
godot_project = D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot
docs_entry = D:\AGAME1\_repo_cache\Game1_work\docs
```

G40 source roots:

```text
D:\AGAME1\sources\docs
D:\AGAME1\sources\docs_governance
D:\AGAME1\sources\art
D:\AGAME1\sources\draw
D:\AGAME1\handoff\connection
```

Rules:

- Do not touch paths outside `D:\AGAME1`.
- Do not treat Lua, UE, old prototypes, or stale worktrees as the active project.
- Do not treat preview/display-only/schema foundation as completed gameplay.
- Do not stage `project.godot`, scenes, resources, `.uid`, `.translation`, or import metadata without a specific gate.
- Do not copy Base Docs or Connection content into repo docs; register source paths instead.
- Follow `docs/00_governance/DOC_PLACEMENT_STANDARD.md` before creating new docs.
