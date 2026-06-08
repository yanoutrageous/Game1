# HANDOFF_C2_TO_C1_GODOT_LUA_PARITY_P0

## Purpose

This document closes the Computer 2 work session and prepares Computer 1 to resume development from the same pushed branch.

## Handoff Direction

- Current computer: Computer 2.
- Next computer: Computer 1.
- Repository: `https://github.com/yanoutrageous/Game1.git`.
- Current branch: `godot/lua-parity-p0`.
- Current Computer 2 repository path: `D:\AGAME2\repo\Game1`.
- Current Computer 2 Godot path: `D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe`.
- Recommended Computer 1 repository path: `D:\AGAME1_repo_cache\Game1_work` or a user-selected fresh clone path.
- Existing Computer 1 command examples below use: `D:\AGAME1\_repo_cache\Game1_work`.

## Current Commit

```text
0b19a05 feat: make Godot parity build manually playable
```

This commit has been pushed to:

```text
origin/godot/lua-parity-p0
```

## Current Achievements

- G3 Lua Parity P0 is complete.
- G3.5 runtime repair is complete.
- G4 manually playable graybox v0.1 is complete.
- Tutorial manual start: YES.
- Standard manual start: YES.
- HUD/MiniMap/ResultPanel readable: YES.
- `MANUAL_PLAYTEST_GUIDE.md` has been generated.
- Real art assets were not migrated.
- `main` was not modified.
- `lua-prototype-main` was not modified.

## Validation Status On Computer 2

- Godot headless editor: PASS.
- Runtime smoke: PASS.
- `validate_project_structure.ps1`: PASS.
- `validate_lua_parity_p0.ps1`: PASS.
- `validate_playable_graybox_v0_1.ps1`: PASS.

Computer 2 validation used the existing Godot console executable:

```text
D:\Godot\downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe
```

## Generated Files Policy

- `.godot/` was not committed.
- `editor_data` was not committed.
- cache/temp files were not committed.
- `.import` metadata was not committed.
- Script `.gd.uid` sidecars generated for tracked scripts were committed as Godot resource metadata where needed.

## Computer 1 Resume Steps For Existing Work Copy

Run:

```powershell
cd D:\AGAME1\_repo_cache\Game1_work
git remote -v
git fetch origin
git checkout godot/lua-parity-p0
git pull --ff-only
git branch --show-current
git status --short
git log -1 --oneline
```

Computer 1 must confirm:

- remote only points to `https://github.com/yanoutrageous/Game1.git`.
- current branch is `godot/lua-parity-p0`.
- latest commit includes at least `0b19a05` or this C2-to-C1 handoff commit.
- worktree is clean.
- current branch is not `main`.
- current branch is not `lua-prototype-main`.

## Computer 1 Resume Steps For Fresh Clone

If Computer 1 does not have the work copy:

```powershell
git clone https://github.com/yanoutrageous/Game1.git D:\AGAME1\_repo_cache\Game1_work
cd D:\AGAME1\_repo_cache\Game1_work
git checkout godot/lua-parity-p0
```

Then run the same safety checks:

```powershell
git remote -v
git branch --show-current
git status --short
git log -1 --oneline
```

## Computer 1 Godot Guidance

- If Computer 1 already has a portable Godot, use the existing Computer 1 Godot.
- If Computer 1 does not have Godot, follow the repository's existing Godot environment documents.
- Do not modify PATH.
- Do not write global Godot configuration.
- Do not use an installer unless a separate future plan authorizes it.
- Project file to open:

```text
Godot/GraytailGodot/project.godot
```

Before manually opening the project, run the static validators:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
```

## Next Stage Recommendation

The recommended next stage is not more environment setup. Continue from `godot/lua-parity-p0` into G5 content system P1 after separate user authorization.

Suggested G5 focus:

- Event room content for trader/dice/altar/trap.
- Deeper `RunInventory` rewards and carried item handling.
- Protocol UI feedback.
- Deterministic combat rewards.
- Failure settlement and guaranteed fallback rewards.
- MapOverlay or manual playtest feedback improvements.

Do not merge to `main` yet.

Do not migrate real art assets yet unless a separate branch is planned, such as:

- `art/export-p0`
- `godot/art-integration-p0`

## Stop Condition

After this handoff document is committed and pushed to `origin/godot/lua-parity-p0`, Computer 2 should stop. Do not enter the next development stage automatically.
