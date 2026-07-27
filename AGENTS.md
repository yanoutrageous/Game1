# AGENTS

Objective rule: evaluate facts as objectively and completely as possible; do not follow user preference over repository evidence.

Current authority:

```text
active_repo = <git-worktree-root>
godot_project = <git-worktree-root>\Godot\GraytailGodot
docs_entry = <git-worktree-root>\docs
active_stage = I3R / ACTIVE
latest_closed_non_art_baseline = I2 / CLOSED / PASS_WITH_NOTES
```

The active root must be resolved with `git rev-parse --show-toplevel` (or from the
current script location). Never select an active repository by matching a drive
letter or another computer's absolute path.

Read current stage facts in this order:

1. `docs/50_stages/active/STAGE_INDEX.md`
2. `docs/10_current/CURRENT_STATE.md`
3. `docs/10_current/NEXT_ACTION.md`
4. `docs/20_product/I3R_PLAYER_EXPERIENCE_REWORK_CONTRACT.md`
5. `docs/00_governance/I3R_EXECUTION_LEDGER.md`
6. `docs/00_governance/I3R_REQUIREMENT_MATRIX.md`
7. `docs/40_validation/VALIDATION_INDEX.md`
8. `tools/i3r/README.md`

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
- I2 is the latest effective closed non-art project baseline. I3 retains
  conditional closeout evidence, but its own validation and handoff require
  exact-head/full plus push/remote-SHA proof before closed-baseline authority
  can take effect.
- I3R is the current active rework stage. It is not closed and does not
  automatically authorize I4, a new art stage, or any other successor.
