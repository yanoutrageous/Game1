param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$GodotExe = "D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

function Read-RepoFile([string]$Path) {
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "G38 validation failed: missing required file: $Path"
    }
    return Get-Content -LiteralPath $fullPath -Raw
}

function Require-Text([string]$Name, [string]$Content, [string]$Pattern) {
    if ($Content -notmatch $Pattern) {
        throw "G38 validation failed: $Name missing pattern $Pattern"
    }
}

function Remove-CommentLines([string]$Content) {
    return (($Content -split "`r?`n") | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"
}

$runScene = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene.gd"
$gameKernel = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/game_kernel.gd"
$commandBus = Read-RepoFile "Godot/GraytailGodot/scripts/core/command/command_bus.gd"
$debugBridge = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene_debug_bridge.gd"
$resultController = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene_result_controller.gd"
$routeController = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene_route_controller.gd"
$inputRouter = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene_input_router.gd"
$feedback = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene_command_feedback.gd"
$budget = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene_responsibility_budget.gd"
$runtimeController = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_runtime_controller.gd"
$stateMachine = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_state_machine.gd"

Require-Text "RunScene responsibility budget" $budget "class_name RunSceneResponsibilityBudget"
Require-Text "RunScene budget runtime owner" $budget "RunRuntimeController"
Require-Text "RunScene budget lifecycle owner" $budget "RunStateMachine"
Require-Text "RunScene input router" $inputRouter "class_name RunSceneInputRouter"
Require-Text "RunScene route controller" $routeController "class_name RunSceneRouteController"
Require-Text "RunScene command feedback" $feedback "class_name RunSceneCommandFeedback"
Require-Text "RunScene result controller" $resultController "class_name RunSceneResultController"
Require-Text "RunScene uses input router" $runScene "RunSceneInputRouterScript"
Require-Text "RunScene uses route controller" $runScene "RunSceneRouteControllerScript"
Require-Text "RunScene uses command feedback helper" $runScene "RunSceneCommandFeedbackScript"
Require-Text "RunScene uses result controller" $runScene "RunSceneResultControllerScript"
Require-Text "RunScene publishes responsibility budget" $runScene "run_scene_responsibility_budget"
Require-Text "Result controller owns meta commit orchestration" $resultController "build_result_display_snapshot"
Require-Text "Result controller commit authority marker" $resultController "RunSceneResultController"
Require-Text "Debug bridge wraps meta debug" $debugBridge "debug_mark_and_save"
Require-Text "Debug bridge checks DebugGate" $debugBridge "DebugGateScript\.is_debug_tools_enabled"

if ($runScene -match '(RunContextScript|CommandBusScript)\.new\(') {
    throw "G38 validation failed: RunScene directly constructs RunContext/CommandBus"
}
if ($runScene -match 'RunSceneMetaCommitterScript\.(commit_result|debug_)') {
    throw "G38 validation failed: RunScene directly orchestrates result/meta/debug commit"
}
if ($runScene -match 'context\.phase\s*=(?!=)' -or $runScene -match 'context\.fail_run\(') {
    throw "G38 validation failed: RunScene writes lifecycle state directly"
}
if ($commandBus -match 'context\.phase\s*=(?!=)') {
    throw "G38 validation failed: CommandBus writes context.phase directly"
}
Require-Text "CommandBus delegates runtime authority" $commandBus "bind_runtime_controller"
Require-Text "CommandBus keeps DebugGate" $commandBus "DebugGateScript\.is_debug_tools_enabled"

Require-Text "GameKernel compatibility facade marker" $gameKernel "G38_GAME_KERNEL_COMPATIBILITY_FACADE"
Require-Text "GameKernel removal condition marker" $gameKernel "remove_autoload_in_project_metadata_only_in_a_future_project_godot_gate"
Require-Text "GameKernel active owner is controller" $gameKernel "RunRuntimeController"
if ($gameKernel -match '"active_owner": "GameKernel" if not authoritative_runtime') {
    throw "G38 validation failed: GameKernel still claims default active ownership"
}
Require-Text "RuntimeController owns context" $runtimeController "context = RunContextScript\.new\(\)"
Require-Text "RuntimeController owns command bus" $runtimeController "command_bus = CommandBusScript\.new\(\)"
Require-Text "RunStateMachine owns lifecycle primitive calls" $stateMachine "context\.fail_run\(reason\)"

$uiRoots = @(
    "Godot/GraytailGodot/scripts/ui/app_shell",
    "Godot/GraytailGodot/scripts/ui/main_menu",
    "Godot/GraytailGodot/scripts/ui/deploy_prep",
    "Godot/GraytailGodot/scripts/ui/run_surface",
    "Godot/GraytailGodot/scripts/ui/hud"
)
$uiViolations = @()
foreach ($root in $uiRoots) {
    $fullRoot = Join-Path $RepoRoot $root
    if (-not (Test-Path -LiteralPath $fullRoot)) {
        continue
    }
    foreach ($file in Get-ChildItem -LiteralPath $fullRoot -Recurse -Filter "*.gd") {
        $content = Remove-CommentLines (Get-Content -LiteralPath $file.FullName -Raw)
        if ($content -match 'SaveManager|MetaProgressAdapter|apply_settlement|context\.phase\s*=(?!=)|context\.fail_run\(|FileAccess|user://') {
            $uiViolations += $file.FullName
        }
    }
}
if ($uiViolations.Count -gt 0) {
    throw "G38 validation failed: UI direct lifecycle/save/result write surface: $($uiViolations -join ', ')"
}

$diffNames = (& git -C $RepoRoot diff --name-only) -split "`r?`n" | Where-Object { $_ -ne "" }
$forbiddenDiff = $diffNames | Where-Object {
    $_ -match '(^|/)project\.godot$' -or
    $_ -match '\.(tscn|tres|res|uid|translation|import)$' -or
    $_ -match '^Base Docs/' -or
    $_ -match '^Connection/'
}
if ($forbiddenDiff.Count -gt 0) {
    throw "G38 validation failed: forbidden diff: $($forbiddenDiff -join ', ')"
}

Write-Output "G38_RUNTIME_ARCHITECTURE_FINALIZATION_VALIDATION=PASS"
