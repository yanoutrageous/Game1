param(
    [Parameter(Mandatory = $false)]
    [string]$GodotExecutable = $env:G41_GODOT_EXECUTABLE
)

$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$RequiredFiles = @(
    'scripts/core/run/g41_in_run_runtime.gd',
    'scripts/gameplay/combat/g41_combat_simulation.gd',
    'scripts/gameplay/combat/g41_deterministic_rng.gd',
    'scripts/gameplay/combat/g41_monster_catalog.gd',
    'scripts/gameplay/interaction/g41_interactable.gd',
    'scripts/gameplay/interactables/g41_chest_interactable.gd',
    'scripts/gameplay/loot/g41_ground_loot_entity.gd',
    'scripts/gameplay/runtime/g41_room_runtime_view.gd',
    'scripts/gameplay/runtime/g41_runtime_actor_view.gd',
    'scripts/gameplay/runtime/g41_runtime_visual_contract.gd',
    'tests/g41_in_run_core_gameplay_runtime_runner.gd'
)

$Failures = [System.Collections.Generic.List[string]]::new()

foreach ($RelativePath in $RequiredFiles) {
    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $RelativePath))
    if (-not $FullPath.StartsWith($ProjectRoot + [System.IO.Path]::DirectorySeparatorChar)) {
        $Failures.Add("outside project: $RelativePath")
        continue
    }
    if (-not [System.IO.File]::Exists($FullPath)) {
        $Failures.Add("missing: $RelativePath")
    }
}

$CombatPath = Join-Path $ProjectRoot 'scripts/gameplay/combat/g41_combat_simulation.gd'
$VisualContractPath = Join-Path $ProjectRoot 'scripts/gameplay/runtime/g41_runtime_visual_contract.gd'
$InRunRuntimePath = Join-Path $ProjectRoot 'scripts/core/run/g41_in_run_runtime.gd'
$RuntimeControllerPath = Join-Path $ProjectRoot 'scripts/core/run/run_runtime_controller.gd'
$CommandBusPath = Join-Path $ProjectRoot 'scripts/core/command/command_bus.gd'
$RunScenePath = Join-Path $ProjectRoot 'scripts/core/run/run_scene.gd'
$RunnerPath = Join-Path $ProjectRoot 'tests/g41_in_run_core_gameplay_runtime_runner.gd'
$RuntimePaths = @(
    (Join-Path $ProjectRoot 'scripts/gameplay/combat'),
    (Join-Path $ProjectRoot 'scripts/gameplay/interaction'),
    (Join-Path $ProjectRoot 'scripts/gameplay/interactables/g41_chest_interactable.gd'),
    (Join-Path $ProjectRoot 'scripts/gameplay/loot'),
    (Join-Path $ProjectRoot 'scripts/gameplay/runtime')
)
$ReadOnlyProjectionPaths = @(
    (Join-Path $ProjectRoot 'scripts/gameplay/runtime/g41_room_runtime_view.gd'),
    (Join-Path $ProjectRoot 'scripts/gameplay/runtime/g41_runtime_actor_view.gd'),
    (Join-Path $ProjectRoot 'scripts/gameplay/interactables/g41_chest_interactable.gd'),
    (Join-Path $ProjectRoot 'scripts/gameplay/loot/g41_ground_loot_entity.gd'),
    (Join-Path $ProjectRoot 'scripts/ui/hud/hud_view_model.gd')
)

if ([System.IO.File]::Exists($CombatPath)) {
    $CombatText = [System.IO.File]::ReadAllText($CombatPath)
    foreach ($Marker in @('const FIXED_STEP := 1.0 / 60.0', 'PLAYER_ATTACK_CONE_DOT := 0.50', 'func _spawn_slimelings', 'func _update_projectiles', 'func _update_lasers')) {
        if (-not $CombatText.Contains($Marker)) {
            $Failures.Add("combat contract missing: $Marker")
        }
    }
}

if ([System.IO.File]::Exists($VisualContractPath)) {
    $ContractText = [System.IO.File]::ReadAllText($VisualContractPath)
    foreach ($Anchor in @('VisualRoot', 'BodyAnchor', 'PromptAnchor', 'HealthBarAnchor', 'AttackOrigin', 'ProjectileOrigin', 'LootSpawnAnchor', 'ShadowAnchor')) {
        if (-not $ContractText.Contains($Anchor)) {
            $Failures.Add("visual anchor missing: $Anchor")
        }
    }
}

$MarkerGroups = @(
    @{ Path = $RuntimeControllerPath; Markers = @('active_combat_owner', 'world_item_owner', 'in_run_runtime.reset()') },
    @{ Path = $InRunRuntimePath; Markers = @('func build_read_only_snapshot', '"source": "g41_combat_simulation"', 'func request_flee', 'func set_paused') },
    @{ Path = $CommandBusPath; Markers = @('unauthorized_runtime_command', 'resolve_runtime_combat', 'flee_runtime_combat') },
    @{ Path = $RunScenePath; Markers = @('in_run_runtime.set_paused(runtime_paused)', 'request_nearest_interaction', 'in_run_runtime.request_attack()', 'in_run_runtime.request_flee()') },
    @{ Path = $RunnerPath; Markers = @('changed the domain-event order', 'Room-view rebuild failed', 'Normal extraction left G41 runtime state alive', 'ArtVisual replacement') }
)
foreach ($MarkerGroup in $MarkerGroups) {
    $FilePath = [string]$MarkerGroup.Path
    if (-not [System.IO.File]::Exists($FilePath)) {
        continue
    }
    $Text = [System.IO.File]::ReadAllText($FilePath)
    foreach ($Marker in $MarkerGroup.Markers) {
        if (-not $Text.Contains([string]$Marker)) {
            $Failures.Add("authority or audit marker missing: $Marker")
        }
    }
}

foreach ($ProjectionPath in $ReadOnlyProjectionPaths) {
    if (-not [System.IO.File]::Exists($ProjectionPath)) {
        continue
    }
    $ProjectionText = [System.IO.File]::ReadAllText($ProjectionPath)
    if ($ProjectionText -match '\bcontext\.(hp|max_hp|pending_gold|safe_gold|current_room_type|run_active)\s*=') {
        $Failures.Add("presentation directly mutates RunContext: $ProjectionPath")
    }
    if ($ProjectionText -match '\b(asset_ledger|truth_map)\.(add_|spend_|pickup_|replace_|drop_|move_|set_|clear_|mark_)') {
        $Failures.Add("presentation directly mutates a runtime authority: $ProjectionPath")
    }
}

foreach ($RuntimePath in $RuntimePaths) {
    $Files = @()
    if ([System.IO.Directory]::Exists($RuntimePath)) {
        $Files = Get-ChildItem -LiteralPath $RuntimePath -Filter '*.gd' -File -Recurse
    } elseif ([System.IO.File]::Exists($RuntimePath)) {
        $Files = Get-Item -LiteralPath $RuntimePath
    }
    foreach ($File in $Files) {
        $Text = [System.IO.File]::ReadAllText($File.FullName)
        if ($Text -match 'res://assets/.+\.png') {
            $Failures.Add("hard-coded final art path: $($File.FullName)")
        }
        if ($Text -match 'texture\.get_size\(\).*(collision|radius)|collision.*texture\.get_size\(\)') {
            $Failures.Add("texture-sized collision: $($File.FullName)")
        }
    }
}

if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
    $Failures.Add('Godot executable not supplied; pass -GodotExecutable or set G41_GODOT_EXECUTABLE')
} elseif (-not [System.IO.File]::Exists([System.IO.Path]::GetFullPath($GodotExecutable))) {
    $Failures.Add("Godot executable missing: $GodotExecutable")
} else {
    $RunnerOutput = & $GodotExecutable --headless --path $ProjectRoot --script 'res://tests/g41_in_run_core_gameplay_runtime_runner.gd' 2>&1
    $RunnerExitCode = $LASTEXITCODE
    $RunnerOutput | ForEach-Object { Write-Output $_ }
    if ($RunnerExitCode -ne 0) {
        $Failures.Add("G41 runner exited with code $RunnerExitCode")
    }
    if (-not (($RunnerOutput -join "`n").Contains('G41_IN_RUN_CORE_GAMEPLAY_RUNTIME=PASS'))) {
        $Failures.Add('G41 runner PASS marker missing')
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'G41_IN_RUN_CORE_GAMEPLAY_RUNTIME_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output "REQUIRED_FILES=$($RequiredFiles.Count)"
