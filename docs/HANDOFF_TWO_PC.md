# HANDOFF_TWO_PC

## Current Status

- Updated: `2026-06-08 17:13:12 +08:00`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Work repository on this PC: `D:\AGAME1\_repo_cache\Game1_work`
- Remote `main`: `8f7e3cb67642708e6a5245d19f722bbfdb357ebe`
- Local Lua baseline commit: `d53d117af8c786014292c2981b7edfdaf11182ea`
- Remote Lua baseline branch: `lua-prototype-main` at `d53d117af8c786014292c2981b7edfdaf11182ea`
- Remote Godot foundation branch before G2.5 repair push: `godot/prototype-foundation` at `2f2f4918f9715e711dcaaac3dea76732c8b62643`
- Remote `main` already existed before G2.5 and was not overwritten.

## Branches To Use

- `main`: remote bootstrap branch currently not treated as the Lua baseline.
- `lua-prototype-main`: safe Lua prototype baseline branch from `D:\2026.6\GAME`.
- `godot/prototype-foundation`: current Godot S1/S2 foundation branch.
- Future `godot/lua-parity-p0`: planned Lua parity implementation branch, not started in G2.5.

## Clone On A New PC

```powershell
git clone https://github.com/yanoutrageous/Game1.git Game1
cd Game1
git remote -v
git ls-remote --heads origin
```

Remote must show only `Game1.git`. If it shows `Game.git`, stop before pushing.

## Checkout Lua Baseline

```powershell
git fetch origin
git checkout lua-prototype-main
git branch --show-current
git log -1 --oneline
```

Use this branch to inspect the preserved Lua prototype baseline. Do not assume remote `main` is the Lua baseline until the user explicitly audits and decides it.

## Checkout Godot Foundation

```powershell
git fetch origin
git checkout godot/prototype-foundation
git branch --show-current
git log -1 --oneline
```

Godot project path inside the repository:

```text
Godot/GraytailGodot/project.godot
```

Open that project with Godot 4.6.3 stable or the user-approved compatible Godot version.

## Run Repository Checks

```powershell
git remote -v
git branch -vv
git status --short
git log --oneline -5
git ls-remote --heads origin
```

For the Godot branch, the portable static checks are:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_s1_foundation.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_s2_rule_loop.ps1
```

Optional external S2 report/cache checks can be enabled by setting local environment variables before running `validate_s2_rule_loop.ps1`:

```powershell
$env:AGAME_REPORTS_DIR='D:\AGAME1\_codex_reports'
$env:AGAME_REPO_CACHE_DIR='D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype'
```

## Push Safety

Before every push:

```powershell
git remote -v
git branch --show-current
git status --short
git ls-remote --heads origin
```

Allowed push targets need explicit stage intent. Never push to `https://github.com/yanoutrageous/Game.git`. Never force push. Never push Godot work to `main`.

## Local Path Notes

These paths are current-PC references only and can differ on a new PC:

- Lua source candidate on this PC: `D:\2026.6\GAME`
- Original Godot source on this PC: `D:\Godot\GraytailGodot`
- Report directory on this PC: `D:\AGAME1\_codex_reports`
- Work repository on this PC: `D:\AGAME1\_repo_cache\Game1_work`

Do not manually delete source directories. Do not copy `D:\Godot\Tools`, `.godot`, editor data, or import caches into Git.

## Required Stage Documents

Every later stage must write:

- `docs/branch_changes/...`
- `docs/audits/...`
- an engineering status note
- a two-PC handoff update or supplement
