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

## Post-Commit Validation Update - 2026-06-08 17:01:08 +08:00

- Remote origin became reachable after the local G2 commit.
- Remote branch state: efs/heads/main exists at 8f7e3cb67642708e6a5245d19f722bbfdb357ebe.
- G1 main push remains blocked because remote main exists and content compatibility has not been confirmed.
- Remote godot/prototype-foundation was not listed by git ls-remote --heads origin at this check.
- Project validation scripts executed from the repository copy failed with project root mismatch: D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot.
- The failure indicates the copied validation scripts still expect the original Godot project path; no code/tool fix was made in G2.

## G2 Push Result - 2026-06-08 17:03:09 +08:00

- Push precheck remote: https://github.com/yanoutrageous/Game1.git.
- Remote main exists at 8f7e3cb67642708e6a5245d19f722bbfdb357ebe; local G1 main was not pushed.
- Remote godot/prototype-foundation did not exist before push.
- Normal push executed: git push origin godot/prototype-foundation.
- Push result: success, new remote branch created.
- Force push: no.
