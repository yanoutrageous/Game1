# AGENTS

Objective rule: evaluate facts as objectively and completely as possible; do not follow user preference over repository evidence.

Current authority:

```text
active_repo = <git-worktree-root>
godot_project = <git-worktree-root>\Godot\GraytailGodot
docs_entry = <git-worktree-root>\docs
```

The active root must be resolved with `git rev-parse --show-toplevel` (or from the
current script location). Never select an active repository by matching a drive
letter or another computer's absolute path.

Historical G40 source roots:

```text
D:\AGAME1\sources\docs
D:\AGAME1\sources\docs_governance
D:\AGAME1\sources\art
D:\AGAME1\sources\draw
D:\AGAME1\handoff\connection
```

Rules:

- `D:\AGAME1` records describe a historical machine layout and are not current
  path authority on this computer.
- Keep implementation writes inside the active Git worktree. External source
  packs may be read from an explicitly supplied path and must be copied through
  an audited import gate before runtime use.
- Do not treat Lua, UE, old prototypes, or stale worktrees as the active project.
- Do not treat preview/display-only/schema foundation as completed gameplay.
- Do not stage `project.godot`, scenes, resources, `.uid`, `.translation`, or import metadata without a specific gate.
- Do not copy Base Docs or Connection content into repo docs; register source paths instead.
- Follow `docs/00_governance/DOC_PLACEMENT_STANDARD.md` before creating new docs.
- ART21 main-menu scene reconstruction is the latest closed art stage. The
  earlier ART21 and ART21R1 branches remain preliminary slices of that stage;
  do not infer or start ART22 without an explicit new requirement.
- I1 is the latest closed non-art project stage. M5 and G40 remain historical
  baselines and must not be presented as the latest overall project progress.
