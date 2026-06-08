# GODOT_CURRENT_STATUS

## Updated

`2026-06-08 17:13:12 +08:00`

## Branch

This project copy lives under repository branch `godot/prototype-foundation`. It records the current Godot S1/S2 foundation only. It is not Lua Parity P0 and must not be merged into `main` automatically.

## Project Path

Repository project path:

```text
Godot/GraytailGodot/project.godot
```

Original source project on the current PC remains read-only for this stage:

```text
D:\Godot\GraytailGodot
```

## Validation Script Portability

G2.5 changed repository-copy validation scripts so project root is inferred from the script directory instead of the original absolute path `D:\Godot\GraytailGodot`.

Run from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_s1_foundation.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_s2_rule_loop.ps1
```

G2.5 results:

- Project structure validation: PASS
- S1 foundation validation: PASS
- S2 rule loop validation: PASS

`validate_s2_rule_loop.ps1` can optionally check local external report/cache paths if `AGAME_REPORTS_DIR` and `AGAME_REPO_CACHE_DIR` are set.

## Boundary

No real art migration, no Lua Parity P0 implementation, and no modification to the original Godot source directory occurred in G2.5.
