# HANDOFF_TWO_PC_GODOT_LUA_PARITY_P0

## Status

- Branch: `godot/lua-parity-p0`
- Base commit: `1ca472b98a44ab40116751192b7afef6ae62c0fe`
- Target commit: see final `git log -1 --oneline`
- Remote: `https://github.com/yanoutrageous/Game1.git`
- Godot project path: `Godot/GraytailGodot/project.godot`

## Continue On Another PC

```powershell
git clone https://github.com/yanoutrageous/Game1.git Game1
cd Game1
git remote -v
git fetch origin
git checkout godot/lua-parity-p0
git status --short
```

Remote must be `Game1.git`, not old `Game.git`.

## Validation

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
```

If Godot is locally available without installation or global config changes, run headless editor and runtime smoke from the repository project path.

## Safety Notes

- Do not merge Godot work into `main` without explicit approval.
- Do not modify `lua-prototype-main`.
- Do not force push.
- Do not push to old `https://github.com/yanoutrageous/Game.git`.
- Do not migrate real art assets as part of this stage.
- Do not automatically start the next stage.

## Next Stage

After user approval, the next stage may broaden parity beyond P0, such as richer event options, MapOverlay, failure salvage details, or content text polish.
