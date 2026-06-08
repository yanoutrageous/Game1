# HANDOFF_TWO_PC

## Time
2026-06-08 16:56:00 +08:00

## Repository
- Remote: $remote
- Local working copy on this PC: $work
- Main policy: main is Lua prototype baseline only.
- Godot work is not in main; use godot/prototype-foundation or later Godot branches.

## Clone on a new PC
`powershell
git clone https://github.com/yanoutrageous/Game1.git Game1
cd Game1
git remote -v
git checkout main
git branch --show-current
git log -1 --oneline
`

## Checkout Godot branch on a new PC
`powershell
git fetch origin
git checkout godot/prototype-foundation
git branch --show-current
git remote -v
`

## Avoid pushing to old Game.git
Before every push, run:
`powershell
git remote -v
git branch --show-current
`
Only push if remote is exactly $remote. Never push to https://github.com/yanoutrageous/Game.git.

## Local path notes
- Current Lua source on this PC: $src
- Current Godot source on this PC: $godot
- Current reports path on this PC: $reports
- These local paths are not required to match on a new PC.

## Tools
- Git
- Godot 4.6.3 stable console on this PC: D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe

## Work checks
Before work:
`powershell
git remote -v
git branch --show-current
git status --short
git log -1 --oneline
`
After work:
`powershell
git status --short
git log -1 --oneline
git remote -v
`

## Latest stage docs
- docs/REPO_POLICY.md
- docs/LUA_BASELINE_STATUS.md
- docs/ENGINEERING_STATUS.md
- docs/branch_changes/BRANCH_CHANGE_G1_MAIN_LUA_BASELINE.md
- docs/audits/AUDIT_G1_MAIN_LUA_BASELINE.md
"@
=@"
# REPO_POLICY

## Branch Policy

- main = Lua prototype baseline from $src.
- godot/prototype-foundation = current Godot S1/S2 foundation.
- godot/lua-parity-p0 = future Godot Lua parity P0 implementation branch.

## Remote Policy

- Only remote mainline repository: $remote.
- Push is allowed only after git remote -v confirms origin is Game1.
- Old remote https://github.com/yanoutrageous/Game.git must not be used for this repository.

## Merge Policy

- Godot must not enter main until it is truly playable and user manually approves a merge.
- No automatic merge to main.
- No force push.

## File Policy

- Do not commit D:\Godot\Tools.
- Do not commit .godot, editor data, import caches, temp caches, or tool binaries from Godot local installs.
- Lua baseline may retain its existing prototype assets unless a file exceeds GitHub limits or user decides a cleanup pass.
- Real art asset migration into Godot is a separate future phase.

## Push Safety

Before every push:
`powershell
git remote -v
git branch --show-current
git status --short
git ls-remote --heads origin
`
If remote state is unknown, do not push.
