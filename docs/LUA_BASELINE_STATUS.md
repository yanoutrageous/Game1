# LUA_BASELINE_STATUS

## Time
2026-06-08 16:56:00 +08:00

## Source
- Source path: $src
- Source branch: $srcBranch
- Source last commit: $srcCommit
- Source remote before copy:
`	ext
origin	https://github.com/yanoutrageous/Game.git (fetch)
origin	https://github.com/yanoutrageous/Game.git (push)
`

## Baseline Copy

- Target repository path: $work
- Old .git from source: excluded.
- Source directory modified: no.
- Godot source directory modified: no.
- Godot project included in main: no.

## Lua Prototype Scope

This baseline contains the current Lua playable prototype, including:

- scripts/main.lua
- scripts/systems/
- scripts/ui/
- scripts/tests/
- ssets/
- game_material/
- docs/
- .project/
- UE/ training/reference content
- .cli/ prototype CLI/tooling content retained as part of source snapshot

## Known Large Files

- .cli\UrhoXCLI : 40812024 bytes
- .cli\TileTerrainCLI : 22536656 bytes
- game_material\screenshot_menu.png : 8376936 bytes
- assets\video\cgt-20260531125819-5lj8t_video.mp4 : 5093463 bytes
- assets\Fonts\FusionPixel.otf : 4911852 bytes
- assets\video\cgt-20260531104804-2lhrg_video.mp4 : 3793027 bytes
- assets\video\cgt-20260531105325-zdl7s_video.mp4 : 3510949 bytes
- game_material\screenshot_gameplay.png : 3377687 bytes
- assets\Textures\menu_bg_no_text.png : 2904266 bytes
- assets\ui\main_menu\main_menu_bg_no_text.png : 2904266 bytes

No copied file exceeded 100MB in the pre-commit check. Files around tens of MB remain a repository-size risk and are recorded for future cleanup/LFS review.

## Godot Parity References

The following external reports are not automatically copied into this baseline by G1, but are intended references for later Godot work:

- $reports\LUA_DEEP_AUDIT_REPORT.md
- $reports\LUA_TO_GODOT_PARITY_SPEC.md
- $reports\LUA_SYSTEM_CALLGRAPH.md
- $reports\LUA_PARITY_TASKS_FOR_GODOT.csv
"@
=@"
# ENGINEERING_STATUS

## Stage
G1 main Lua baseline.

## Time
2026-06-08 16:56:00 +08:00

## Repository State
- Current repository path: $work
- Current remote: $remote
- Current branch: main
- Base commit: source $srcCommit
- Target commit: local G1 commit created by this stage; exact hash is in final execution output and git log -1 --oneline.
- Push: blocked until remote state is known; current network check failed before push.
- Push target: origin main only if remote main is absent/empty or user confirms compatibility.
- main modified: yes, local main created as Lua baseline.
- Lua source directory modified: no.
- Godot original directory modified: no.

## Entrypoints
- Lua prototype entry: scripts/main.lua
- Current Godot source path on this PC: $godot
- Godot version on this PC: Godot 4.6.3 stable console path D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe

## Next Branch
Next stage should start from local main and create godot/prototype-foundation.
