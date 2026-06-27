param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$GodotExe = "D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe"
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
        throw "G37 validation failed: $Name missing pattern $Pattern"
    }
}

$commandBus = Read-RepoFile "Godot/GraytailGodot/scripts/core/command/command_bus.gd"
$runScene = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene.gd"
$runContext = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_context.gd"
$stateMachine = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_state_machine.gd"
$runtimeController = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_runtime_controller.gd"
$flowContract = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_flow_state_contract.gd"
$gameKernel = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/game_kernel.gd"
$combatState = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/combat_state.gd"
$roomResolver = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/room_resolver.gd"
$eventService = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/event_service.gd"
$runRuleService = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_rule_service.gd"

Require-Text "RunStateMachine class" $stateMachine "class_name RunStateMachine"
Require-Text "RunRuntimeController class" $runtimeController "class_name RunRuntimeController"
Require-Text "RunRuntimeController owns context" $runtimeController "context = RunContextScript\.new\(\)"
Require-Text "RunRuntimeController owns command bus" $runtimeController "command_bus = CommandBusScript\.new\(\)"
Require-Text "CommandBus runtime binding" $commandBus "bind_runtime_controller"
Require-Text "CommandBus delegates start" $commandBus "runtime_controller\.start_standard_run"
Require-Text "CommandBus delegates extract" $commandBus "runtime_controller\.confirm_extract"
Require-Text "CommandBus binds resolver authority" $commandBus "room_resolver\.bind_runtime_controller\(runtime_controller\)"
Require-Text "RunScene uses runtime controller" $runScene "RunRuntimeControllerScript"
Require-Text "RunFlowStateContract projection marker" $flowContract "projection only"
Require-Text "GameKernel hard disabled" $gameKernel "G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED := false"
Require-Text "RuntimeController exposes fail transition" $runtimeController "func fail_run\(reason: String"
Require-Text "CombatState routes damage through effect applier" $combatState "RunEffectApplierScript\.apply_damage"
Require-Text "RoomResolver routes fail authority" $roomResolver "runtime_controller\.fail_run"
Require-Text "EventService routes event result through rule service" $eventService "RunRuleService\.apply_event_rule_result"
Require-Text "RunRuleService routes event HP through effect applier" $runRuleService "RunEffectApplierScript\.effect_hp_delta"
Require-Text "RunRuleService routes event pressure through effect applier" $runRuleService "RunEffectApplierScript\.effect_protocol_pressure_delta"
Require-Text "RunRuleService applies event run effects" $runRuleService "RunEffectApplierScript\.apply_effects\(context, run_effects, fail_authority\)"

if ($commandBus -match 'context\.phase\s*=[^=]') {
    throw "G37 validation failed: CommandBus still writes context.phase directly"
}
if ($runScene -match '(RunContextScript|CommandBusScript)\.new\(') {
    throw "G37 validation failed: RunScene still directly constructs RunContext/CommandBus"
}
if ($gameKernel -match '(?s)func reset_run\(\).*current_run_context = RunContextScript\.new\(\)' -and $gameKernel -notmatch 'G37_GAME_KERNEL_RUNTIME_DRIVER_ENABLED') {
    throw "G37 validation failed: GameKernel can drive a second RunContext"
}
if ($flowContract -match 'dispatch\(' -or $flowContract -match 'FileAccess|user://|save_json') {
    throw "G37 validation failed: RunFlowStateContract is not projection-only"
}
if ($runContext -notmatch 'func start_run' -or $runContext -notmatch 'func fail_run' -or $runContext -notmatch 'func complete_extract') {
    throw "G37 validation failed: RunContext internal primitives missing"
}

$directFailRunForbidden = @()
$runRoot = Join-Path $RepoRoot "Godot/GraytailGodot/scripts/core/run"
$allowedFailRunFiles = @(
    (Join-Path $runRoot "run_context.gd"),
    (Join-Path $runRoot "run_state_machine.gd"),
    (Join-Path $runRoot "run_runtime_controller.gd")
) | ForEach-Object { [System.IO.Path]::GetFullPath($_).ToLowerInvariant() }
$filesToScan = @(Get-ChildItem -LiteralPath $runRoot -Recurse -Filter "*.gd" | ForEach-Object { $_.FullName })
$filesToScan += Join-Path $RepoRoot "Godot/GraytailGodot/scripts/core/command/command_bus.gd"
foreach ($filePath in $filesToScan) {
    $fullPath = [System.IO.Path]::GetFullPath($filePath).ToLowerInvariant()
    if ($allowedFailRunFiles -contains $fullPath) {
        continue
    }
    $content = Get-Content -LiteralPath $filePath -Raw
    if ($content -match 'context\.fail_run\(') {
        $directFailRunForbidden += $filePath
    }
}
if ($directFailRunForbidden.Count -gt 0) {
    throw "G37 validation failed: direct context.fail_run outside runtime authority: $($directFailRunForbidden -join ', ')"
}

$diffNames = (& git -C $RepoRoot diff --name-only) -split "`r?`n" | Where-Object { $_ -ne "" }
$forbiddenDiff = $diffNames | Where-Object {
    $_ -match '(^|/)project\.godot$' -or
    $_ -match '\.(tscn|tres|res|uid|translation|import)$'
}
if ($forbiddenDiff.Count -gt 0) {
    throw "G37 validation failed: forbidden metadata diff: $($forbiddenDiff -join ', ')"
}

$projectPath = Join-Path $RepoRoot "Godot/GraytailGodot"
$runnerPath = Join-Path $RepoRoot "tools/godot_g37_command_sequence_runner.gd"
if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "G37 validation failed: Godot executable unavailable at $GodotExe"
}
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$runnerOutput = & $GodotExe --headless --path $projectPath --script $runnerPath 2>&1
$runnerExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
$runnerText = ($runnerOutput | Out-String)
if ($runnerExitCode -ne 0 -or $runnerText -notmatch "G37_COMMAND_SEQUENCE_REGRESSION=PASS") {
	throw "G37 validation failed: command sequence regression failed: $runnerText"
}

Write-Output "G37_RUNTIME_AUTHORITY_VALIDATION=PASS"
