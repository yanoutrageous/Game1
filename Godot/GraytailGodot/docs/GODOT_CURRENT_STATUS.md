# GODOT_CURRENT_STATUS

## Time
2026-06-08 16:59:13 +08:00

## Stage
G2 Godot S1/S2 prototype foundation copied into Game1 branch godot/prototype-foundation.

## Project Location
- Repository project path: Godot/GraytailGodot
- Original project path on this PC: $srcGodot
- Original project modified: no.
- Godot version on this PC: Godot 4.6.3 stable console at D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe

## Current Foundation
- Main scene: es://scenes/main/main.tscn
- Run scene: es://scenes/run/run_scene.tscn
- Current sandbox: fixed 7x7 demo from S1/S2.
- Existing boundaries: TruthMap, IntelMap, RunContext, CommandBus, RoomResolver, ContentDB, HUD/MiniMap/ResultPanel ViewModels.
- Lua parity P0 not implemented in G2.

## Validation Scripts
- 	ools/validate_s1_foundation.ps1
- 	ools/validate_s2_rule_loop.ps1
- 	ools/validate_project_structure.ps1

## Exclusions
- .godot, editor caches, import caches, temp caches, and external Godot tools are not copied.
- Real art asset migration is not performed.

## Largest Copied Godot Files
- docs\GODOT_ENVIRONMENT_FINAL_REPORT.md : 10632 bytes
- docs\T2_PRE_REPO_AND_DOCS_ASSESSMENT.md : 9166 bytes
- project.godot : 6290 bytes
- tools\validate_s2_rule_loop.ps1 : 6007 bytes
- scripts\core\run\run_scene.gd : 5690 bytes
- docs\S1_ASSET_AND_PLACEHOLDER_REPORT.md : 3364 bytes
- tools\validate_s1_foundation.ps1 : 3275 bytes
- scripts\core\command\command_bus.gd : 3088 bytes
- scripts\core\intel\intel_map.gd : 3085 bytes
- scripts\core\run\run_context.gd : 2700 bytes

## Next Step
Continue from branch godot/prototype-foundation only when preparing godot/lua-parity-p0. Do not merge to main.
