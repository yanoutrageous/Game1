# HANDOFF_TWO_PC_GODOT_BRANCH

## Time
2026-06-08 16:59:13 +08:00

## Clone and Branch Use
`powershell
git clone https://github.com/yanoutrageous/Game1.git Game1
cd Game1
git remote -v
git checkout main
git checkout godot/prototype-foundation
`

## Confirm Safety
`powershell
git branch --show-current
git remote -v
git status --short
git log -1 --oneline
`
Remote must be $remote, not old Game.git.

## Godot Project
- Repository path after checkout: Godot/GraytailGodot
- Current PC original path: $srcGodot
- New PC path can be different.
- Open the project by pointing Godot 4.6.3 stable at Godot/GraytailGodot/project.godot.

## Validation
`powershell
cd Godot\GraytailGodot
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate_s1_foundation.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\validate_s2_rule_loop.ps1
`

## Continue Development
- Do not develop Godot on main.
- Start future P0 work from godot/prototype-foundation by creating godot/lua-parity-p0.
- Do not copy real art assets during parity preparation.
- Do not commit .godot or import caches.

## Work Checks
Before and after every work session:
`powershell
git remote -v
git branch --show-current
git status --short
git log -1 --oneline
`
"@
=@"
# ENGINEERING_STATUS

## Stage
G2 Godot S1/S2 prototype foundation branch.

## Time
2026-06-08 16:59:13 +08:00

## Repository State
- Current repository path: $work
- Current remote: $remote
- Current branch: godot/prototype-foundation
- Base commit: $baseCommit
- Target commit: local G2 commit created by this stage; exact hash is in final execution output and git log -1 --oneline.
- Push: blocked until remote state is known.
- Push target: origin godot/prototype-foundation.
- main modified by this stage: no.
- Lua source directory modified: no.
- Godot original directory modified: no.

## Entrypoints
- Lua prototype entry on main: scripts/main.lua
- Godot project entry on this branch: Godot/GraytailGodot/project.godot
- Godot main scene: es://scenes/main/main.tscn
- Current Godot version: 4.6.3 stable console path D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
- Current report path on this PC: $reports

## Next Branch
Future Lua parity work should start from godot/prototype-foundation and create godot/lua-parity-p0.
