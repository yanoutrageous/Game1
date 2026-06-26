param(
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

function Read-RepoFile([string]$Path) {
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Missing required file: $Path"
    }
    return Get-Content -LiteralPath $fullPath -Raw
}

function Require-Text([string]$Name, [string]$Content, [string]$Pattern) {
    if ($Content -notmatch $Pattern) {
        throw "G35 validation failed: $Name missing pattern $Pattern"
    }
}

$meta = Read-RepoFile "Godot/GraytailGodot/scripts/core/save/meta_progress_adapter.gd"
$save = Read-RepoFile "Godot/GraytailGodot/scripts/core/save/save_adapter.gd"
$debugGate = Read-RepoFile "Godot/GraytailGodot/scripts/core/debug/debug_gate.gd"
$commandBus = Read-RepoFile "Godot/GraytailGodot/scripts/core/command/command_bus.gd"
$runScene = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene.gd"
$roomResolver = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/room_resolver.gd"
$gameKernel = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/game_kernel.gd"
$deployBoundary = @(
    (Read-RepoFile "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd"),
    (Read-RepoFile "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd"),
    (Read-RepoFile "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_tab_model.gd")
) -join "`n"

Require-Text "MetaProgressAdapter load result" $meta "load_json_result"
Require-Text "MetaProgressAdapter load status" $meta "last_load_status"
Require-Text "SaveAdapter explicit load result" $save "func load_json_result"
Require-Text "SaveAdapter read-only fallback" $save "read_only_fallback"
Require-Text "SaveAdapter future schema guard" $save "future_schema"
Require-Text "DebugGate OS debug build gate" $debugGate "OS\.is_debug_build"
Require-Text "CommandBus execution gate" $commandBus "DebugGateScript\.is_debug_tools_enabled"
Require-Text "RunScene debug gate" $runScene "m1_debug_panel_enabled"
Require-Text "RoomResolver event returns real result" $roomResolver '(?s)&"Event":.*EventService\.execute_default.*return result'
Require-Text "GameKernel inactive ownership marker" $gameKernel "RunScene owns the authoritative"
Require-Text "DeployPrep remains preview boundary" $deployBoundary "RunBootstrapper"

$loadBlock = [regex]::Match($meta, '(?s)func load_or_create_default\(\) -> Dictionary:(.*?)func save\(\) -> bool:')
if (-not $loadBlock.Success) {
    throw "G35 validation failed: could not locate MetaProgressAdapter.load_or_create_default block"
}
if ($loadBlock.Groups[1].Value -match "\bsave\s*\(") {
    throw "G35 validation failed: load_or_create_default still writes storage"
}

Write-Output "G35_RUNTIME_SAFETY_VALIDATION=PASS"
