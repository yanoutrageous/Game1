# REPO_POLICY

## Branch Policy

- `main` = Lua prototype baseline from `D:\2026.6\GAME`.
- `godot/prototype-foundation` = current Godot S1/S2 foundation.
- `godot/lua-parity-p0` = future Godot Lua parity P0 implementation branch.

## Remote Policy

- Only remote mainline repository: `https://github.com/yanoutrageous/Game1.git`.
- Push is allowed only after `git remote -v` confirms origin is Game1.
- Old remote `https://github.com/yanoutrageous/Game.git` must not be used for this repository.

## Merge Policy

- Godot must not enter `main` until it is truly playable and user manually approves a merge.
- No automatic merge to `main`.
- No force push.

## File Policy

- Do not commit `D:\Godot\Tools`.
- Do not commit `.godot`, editor data, import caches, temp caches, or local tool directories.
- Lua baseline may retain its existing prototype assets unless a file exceeds GitHub limits or user decides a cleanup pass.
- Real art asset migration into Godot is a separate future phase.

## Push Safety

Before every push:

```powershell
git remote -v
git branch --show-current
git status --short
git ls-remote --heads origin
```

If remote state is unknown, do not push.
