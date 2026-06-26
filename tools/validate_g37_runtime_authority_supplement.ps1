param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$GodotExe = "D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

function Read-RepoFile([string]$Path) {
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "G37S validation failed: missing required file: $Path"
    }
    return Get-Content -LiteralPath $fullPath -Raw
}

function Require-Text([string]$Name, [string]$Content, [string]$Pattern) {
    if ($Content -notmatch $Pattern) {
        throw "G37S validation failed: $Name missing pattern $Pattern"
    }
}

function Remove-CommentLines([string]$Content) {
    return (($Content -split "`r?`n") | Where-Object { $_ -notmatch '^\s*#' }) -join "`n"
}

$runRoot = Join-Path $RepoRoot "Godot/GraytailGodot/scripts/core/run"
$commandBusPath = Join-Path $RepoRoot "Godot/GraytailGodot/scripts/core/command/command_bus.gd"

$commandBus = Read-RepoFile "Godot/GraytailGodot/scripts/core/command/command_bus.gd"
$runScene = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene.gd"
$runContext = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_context.gd"
$stateMachine = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_state_machine.gd"
$runtimeController = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_runtime_controller.gd"
$flowContract = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_flow_state_contract.gd"
$gameKernel = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/game_kernel.gd"
$sequenceRunner = Read-RepoFile "tools/godot_g37_command_sequence_runner.gd"
$validationDoc = Read-RepoFile "docs/validation/G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION_VALIDATION.md"
$handoffDoc = Read-RepoFile "docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_RUNFLOW_EXECUTION.md"
$supplementValidationDoc = Read-RepoFile "docs/validation/G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md"
$supplementHandoffDoc = Read-RepoFile "docs/handoff/HANDOFF_G37_RUNTIME_AUTHORITY_VALIDATION_SUPPLEMENT.md"

& (Join-Path $RepoRoot "tools/validate_g37_runtime_authority.ps1") -RepoRoot $RepoRoot -GodotExe $GodotExe
if ($LASTEXITCODE -ne 0) {
    throw "G37S validation failed: base G37 validation failed"
}

Require-Text "RunRuntimeController context ownership" $runtimeController "context = RunContextScript\.new\(\)"
Require-Text "RunRuntimeController state machine ownership" $runtimeController "state_machine = RunStateMachineScript\.new\(\)"
Require-Text "RunRuntimeController command bus ownership" $runtimeController "command_bus = CommandBusScript\.new\(\)"
Require-Text "RunRuntimeController binds command bus" $runtimeController "command_bus\.bind_runtime_controller\(self\)"
Require-Text "RunRuntimeController public fail wrapper" $runtimeController "func fail_run\(reason: String"

Require-Text "CommandBus runtime binding" $commandBus "bind_runtime_controller"
Require-Text "CommandBus binds RoomResolver authority" $commandBus "room_resolver\.bind_runtime_controller\(runtime_controller\)"
Require-Text "CommandBus debug gate check" $commandBus "DebugGateScript\.is_debug_tools_enabled\(\)"
Require-Text "CommandBus debug force extract command" $commandBus "debug_force_extract"
Require-Text "CommandBus debug force fail command" $commandBus "debug_force_fail"
Require-Text "CommandBus delegates debug force extract" $commandBus "runtime_controller\.debug_force_extract\(\)"
Require-Text "CommandBus delegates debug force fail" $commandBus "runtime_controller\.debug_force_fail"
Require-Text "RuntimeController debug force fail uses fail wrapper" $runtimeController "var result: Dictionary = fail_run\(reason\)"
Require-Text "RuntimeController debug force extract uses state machine" $runtimeController "state_machine\.force_extract\(context\)"

if ($runScene -match '(RunContextScript|CommandBusScript)\.new\(') {
    throw "G37S validation failed: RunScene directly constructs RunContext/CommandBus"
}

Require-Text "GameKernel hard disable constant" $gameKernel "G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED := false"
Require-Text "GameKernel dispatch hard-disable guard" $gameKernel "not G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED"

$flowContractExecutable = Remove-CommentLines $flowContract
if ($flowContractExecutable -match '\bdispatch\s*\(' -or
    $flowContractExecutable -match 'FileAccess|user://' -or
    $flowContractExecutable -match '\b(grant_reward|claim_reward|save_json|persist)\s*\(' -or
    $flowContractExecutable -match '\b(AssetLedger|RunAssetLedger)\b') {
    throw "G37S validation failed: RunFlowStateContract contains executable dispatch/persistence/grant/asset behavior"
}
Require-Text "RunFlowStateContract projection-only marker" $flowContract "projection only"

$runFiles = @(Get-ChildItem -LiteralPath $runRoot -Recurse -Filter "*.gd" | ForEach-Object { $_.FullName })
$scanFiles = $runFiles + $commandBusPath

$allowedPhaseFiles = @(
    (Join-Path $runRoot "run_context.gd"),
    (Join-Path $runRoot "run_state_machine.gd")
) | ForEach-Object { [System.IO.Path]::GetFullPath($_).ToLowerInvariant() }

$allowedFailFiles = @(
    (Join-Path $runRoot "run_context.gd"),
    (Join-Path $runRoot "run_state_machine.gd")
) | ForEach-Object { [System.IO.Path]::GetFullPath($_).ToLowerInvariant() }

$phaseViolations = @()
$failViolations = @()
foreach ($filePath in $scanFiles) {
    $fullPath = [System.IO.Path]::GetFullPath($filePath).ToLowerInvariant()
    $content = Get-Content -LiteralPath $filePath -Raw
    if (($allowedPhaseFiles -notcontains $fullPath) -and $content -match 'context\.phase\s*=(?!=)') {
        $phaseViolations += $filePath
    }
    if (($allowedFailFiles -notcontains $fullPath) -and $content -match 'context\.fail_run\(') {
        $failViolations += $filePath
    }
}
if ($phaseViolations.Count -gt 0) {
    throw "G37S validation failed: context.phase writes outside authority: $($phaseViolations -join ', ')"
}
if ($failViolations.Count -gt 0) {
    throw "G37S validation failed: context.fail_run calls outside authority: $($failViolations -join ', ')"
}

foreach ($pattern in @('start_tutorial_run', 'move_by', 'search_current_room', 'request_extract', 'confirm_extract')) {
    Require-Text "command sequence runner covers $pattern" $sequenceRunner $pattern
}
Require-Text "validation doc records force fail coverage" $validationDoc "force failure"
Require-Text "supplement validation records G38 recommendation" $supplementValidationDoc "G38"
Require-Text "supplement handoff records G38 recommendation" $supplementHandoffDoc "G38"

$diffNames = (& git -C $RepoRoot diff --name-only) -split "`r?`n" | Where-Object { $_ -ne "" }
$forbiddenDiff = $diffNames | Where-Object {
    $_ -match '(^|/)project\.godot$' -or
    $_ -match '\.(tscn|tres|res|uid|translation|import)$' -or
    $_ -match '^Godot/GraytailGodot/scripts/core/command/(?!command_bus\.gd$)' -or
    $_ -match '^Godot/GraytailGodot/scripts/core/(?!run/|command/command_bus\.gd$)' -or
    $_ -match '^Godot/GraytailGodot/scripts/ui/(?!app_shell/|main_menu/|deploy_prep/|run_surface/|hud/)'
}
if ($forbiddenDiff.Count -gt 0) {
    throw "G37S validation failed: current diff contains files outside G37/G38 runtime architecture ranges: $($forbiddenDiff -join ', ')"
}

Write-Output "G37_RUNTIME_AUTHORITY_SUPPLEMENT_VALIDATION=PASS"
