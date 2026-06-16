# Execution Environment

This file records execution boundaries for the current Game1 worktree.

## Paths

- Repository path: `D:\AGAME1\_repo_cache\Game1_work`
- Godot project path: `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`
- Wrong external Godot path: `D:\AGAME1\Godot\GraytailGodot`
- Base Docs path: `D:\AGAME1\Base Docs`
- Godot console executable: `D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe`

## PATCH_MODE

- Historical fact: `PATCH_MODE=AGAME1_ROOT`.
- Every write batch must still run a fresh apply_patch root probe before editing.
- If `PATCH_MODE=AGAME1_ROOT`, apply_patch paths must start with `_repo_cache/Game1_work/`.
- If `PATCH_MODE=REPO_ROOT`, apply_patch paths use repository-relative paths.

## Do-Not-Touch Paths

- `D:\AGAME1\Base Docs`
- `D:\AGAME1\Godot`
- `D:\AGAME1\Godot\GraytailGodot`
- `D:\AGAME1\_repo_cache\Game_feature_editor_playable_prototype`
- `D:\AGAME1\_codex_reports`
- old UE/Game.git
- `lua-prototype-main`
- parent directories, sibling directories, user directories, system directories, and global config directories

## Git Safety

Do not run `git pull`, `git rebase`, `git reset`, `git clean`, `git stash`, `git stash apply`, `git stash pop`, `git stash drop`, `git stash clear`, `git push --force`, prune, branch deletion, remote branch deletion, or main push unless a later task explicitly authorizes a safe variant.

Protection stash is do-not-touch:

`stash@{0}: On main: pre-sync generated dirty before aligning to G15 encounter branch on computer two`

## Validation Boundary

G20-R3a/R3b are docs-only. They do not run Godot, do not modify Godot project files, and do not claim `Godot headless project-load/parser smoke PASS`, `gameplay runtime PASS`, or `manual playtest PASS`.
