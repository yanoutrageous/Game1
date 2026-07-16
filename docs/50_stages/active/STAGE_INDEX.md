# Active Stage Index

文档状态：I0 与 ART21 基线整合后的当前索引

当前没有已授权的后续 active stage。

| Stage | Line | Status | Evidence | Boundary |
| --- | --- | --- | --- | --- |
| none | none | ART21 closed; successor not yet named / no_authorized_active_stage | `docs/10_current/NEXT_ACTION.md` | I0 与 ART21 的整合不自动授权 ART22、工程重构、内容扩展或发布阶段。 |

## 当前整合基线

| Item | Current fact |
| --- | --- |
| Active repo | Resolve with `git rev-parse --show-toplevel`; no drive-letter authority |
| Integration branch | `integration/i0-art21-baseline` |
| I0 source | `origin/i0/project-baseline-refactor` at `77569579a6c66d9f4350f0ba419906a7814dd502` |
| ART21 source | `origin/art/art21-main-menu-scene-reconstruction` at `93420a8f3799c540ac8a2b46d3c264d5f3ee10f1` |
| Godot project | `<git-worktree-root>/Godot/GraytailGodot` |
| Toolchain contract | Godot 4.6.3 from I0; current-machine path must be explicitly configured or resolved by the I0 bootstrap |
| Latest closed non-art stage | I0, with its recorded safety nonconformance and limitations |
| Latest closed art stage | ART21 main-menu scene reconstruction |
| Main-menu design canvas | 1280×720 |

## Interpretation

- I0 remains the common repository, toolchain, test and governance baseline.
- ART21 supplies the final scene-based main-menu implementation and evidence.
- ART21R2, ART21R1 and the earlier ART21 placement work remain preliminary
  historical slices; they do not supersede the final ART21 main-menu closeout.
- Historical `D:\AGAME1` paths remain valid inside I0 handoff and validation
  evidence, but current scripts and current documents must resolve the active
  repository relative to the current Git worktree.
- No full manual playtest, release, CI, performance or post-ART21 visual stage is
  implied by this baseline integration.
