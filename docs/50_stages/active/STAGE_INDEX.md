# Active Stage Index

文档状态：ART23 关闭后的当前索引

当前没有已授权的后续 active stage。

| Stage | Line | Status | Evidence | Boundary |
| --- | --- | --- | --- | --- |
| none | none | ART23 closed; successor not yet named / no_authorized_active_stage | `docs/10_current/NEXT_ACTION.md` | ART23 关闭不自动授权 MVP 后续内容、工程重构、CI 或发布阶段。 |

## 当前整合基线

| Item | Current fact |
| --- | --- |
| Active repo | Resolve with `git rev-parse --show-toplevel`; no drive-letter authority |
| Current art branch | `art/art23-long-term-final-ui` |
| Integration base | `origin/integration/i0-art21-baseline` |
| I0 source | `origin/i0/project-baseline-refactor` at `77569579a6c66d9f4350f0ba419906a7814dd502` |
| ART21 source | `origin/art/art21-main-menu-scene-reconstruction` at `93420a8f3799c540ac8a2b46d3c264d5f3ee10f1` |
| Godot project | `<git-worktree-root>/Godot/GraytailGodot` |
| Toolchain contract | Godot 4.6.3 from I0; current-machine path must be explicitly configured or resolved by the I0 bootstrap |
| Latest closed non-art stage | I0, with its recorded safety nonconformance and limitations |
| Latest closed art stage | ART23 long-term final art UI |
| Main-menu design canvas | 1280×720 |
| Deploy-prep design canvas | 1280×720; 5 primary / 34 secondary states |
| Long-term design canvas | 1280×720; 6 primary / 27 secondary pages |

## Interpretation

- I0 remains the common repository, toolchain, test and governance baseline.
- ART21 supplies the final scene-based main-menu implementation and evidence.
- ART21R2, ART21R1 and the earlier ART21 placement work remain preliminary
  historical slices; they do not supersede the final ART21 main-menu closeout.
- Historical `D:\AGAME1` paths remain valid inside I0 handoff and validation
  evidence, but current scripts and current documents must resolve the active
  repository relative to the current Git worktree.
- No full-game manual playtest, release, CI, performance or post-ART23 visual stage is
  implied by this baseline integration.
