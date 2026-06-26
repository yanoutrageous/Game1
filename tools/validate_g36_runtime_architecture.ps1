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
        throw "G36 validation failed: $Name missing pattern $Pattern"
    }
}

function Require-File([string]$Path) {
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "G36 validation failed: missing $Path"
    }
}

$requiredFiles = @(
    "Godot/GraytailGodot/scripts/core/save/save_manager.gd",
    "Godot/GraytailGodot/scripts/core/save/save_profile_manifest.gd",
    "Godot/GraytailGodot/scripts/core/save/save_import_staging.gd",
    "Godot/GraytailGodot/scripts/core/save/save_profile_preview.gd",
    "Godot/GraytailGodot/scripts/core/run/run_scene_debug_bridge.gd",
    "Godot/GraytailGodot/scripts/core/run/run_scene_meta_committer.gd",
    "Godot/GraytailGodot/scripts/core/run/run_scene_ui_bridge.gd",
    "Godot/GraytailGodot/scripts/core/run/run_start_config.gd",
    "Godot/GraytailGodot/scripts/core/run/run_start_route_adapter.gd"
)

foreach ($path in $requiredFiles) {
    Require-File $path
}

$meta = Read-RepoFile "Godot/GraytailGodot/scripts/core/save/meta_progress_adapter.gd"
$saveManifest = Read-RepoFile "Godot/GraytailGodot/scripts/core/save/save_profile_manifest.gd"
$saveManager = Read-RepoFile "Godot/GraytailGodot/scripts/core/save/save_manager.gd"
$runScene = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene.gd"
$routeAdapter = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_start_route_adapter.gd"
$routeConfig = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_start_config.gd"
$debugBridge = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene_debug_bridge.gd"
$commandBus = Read-RepoFile "Godot/GraytailGodot/scripts/core/command/command_bus.gd"
$gameKernel = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/game_kernel.gd"
$deployShell = Read-RepoFile "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd"
$appShell = Read-RepoFile "Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd"

Require-Text "MetaProgressAdapter write block flag" $meta "write_blocked"
Require-Text "MetaProgressAdapter write block reason" $meta "meta_progress_read_only_fallback"
Require-Text "MetaProgressAdapter writable guard" $meta "func _ensure_writable"
Require-Text "MetaProgressAdapter active profile injection" $meta "set_active_profile_path"
Require-Text "Save profile manifest path" $saveManifest "user://saves/manifest\.json"
Require-Text "Save profile meta path" $saveManifest "meta_progress\.json"
Require-Text "Save profile run checkpoint path" $saveManifest "run_checkpoint\.json"
Require-Text "Save profile preview path" $saveManifest "preview\.json"
Require-Text "SaveManager configures MetaProgressAdapter" $saveManager "configure_meta_adapter"
Require-Text "SaveManager blocks mid-run switch" $saveManager "blocked_mid_run_result"
Require-Text "RunScene uses SaveManager" $runScene "SaveManagerScript"
Require-Text "RunScene uses DebugBridge" $runScene "RunSceneDebugBridgeScript"
Require-Text "RunScene uses MetaCommitter" $runScene "RunSceneMetaCommitterScript"
Require-Text "RunScene uses UIBridge" $runScene "RunSceneUIBridgeScript"
Require-Text "RunScene uses route adapter" $runScene "RunStartRouteAdapterScript"
Require-Text "Route adapter existing route boundary" $routeAdapter "existing_run_route_only_no_run_bootstrapper"
Require-Text "Route config unsupported field capture" $routeConfig "unsupported_config_fields"
Require-Text "DeployPrep route adapter" $deployShell "payload_from_deploy_preview"
Require-Text "AppShell route adapter" $appShell "payload_from_route_payload"
Require-Text "Debug bridge uses DebugGate" $debugBridge "DebugGateScript\.is_debug_tools_enabled"
Require-Text "CommandBus debug gate remains" $commandBus "DebugGateScript\.is_debug_tools_enabled"
Require-Text "GameKernel remains non-authoritative" $gameKernel "RunScene owns the authoritative"

if ($runScene -match '(?s)func _nearest_room_of_type\(.*?for y in range\(run_context\.truth_map\.height\)') {
    throw "G36 validation failed: RunScene still directly iterates truth_map for debug room lookup"
}

$diffNames = (& git -C $RepoRoot diff --name-only) -split "`r?`n" | Where-Object { $_ -ne "" }
$forbiddenDiff = $diffNames | Where-Object {
    $_ -match '(^|/)project\.godot$' -or
    $_ -match '\.(tscn|tres|res|uid|translation|import)$'
}
if ($forbiddenDiff.Count -gt 0) {
    throw "G36 validation failed: forbidden metadata diff: $($forbiddenDiff -join ', ')"
}

Write-Output "G36_RUNTIME_ARCHITECTURE_VALIDATION=PASS"
