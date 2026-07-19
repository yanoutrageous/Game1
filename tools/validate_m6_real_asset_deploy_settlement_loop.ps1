param(
    [string]$RepoRoot = (Get-Location).Path,
    [string]$GodotExecutable = '',
    [string]$GitExecutable = ''
)

$ErrorActionPreference = 'Stop'
$Failures = [System.Collections.Generic.List[string]]::new()
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)
$ProjectRoot = Join-Path $RepoRoot 'Godot/GraytailGodot'
if ([string]::IsNullOrWhiteSpace($GodotExecutable)) {
    $GodotCandidates = @(
        (Join-Path (Split-Path $RepoRoot -Parent) 'tools/runtimes/godot/4.6.3/Godot_v4.6.3-stable_win64_console.exe'),
        'D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe',
        'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
    )
    $GodotExecutable = $GodotCandidates | Where-Object { [System.IO.File]::Exists($_) } | Select-Object -First 1
}

$RequiredFiles = @(
    'Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd',
    'Godot/GraytailGodot/scripts/core/content/m3r_item_usability_model.gd',
    'Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd',
    'Godot/GraytailGodot/scripts/core/save/meta_progress_adapter.gd',
    'Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd',
    'Godot/GraytailGodot/scripts/ui/result/result_panel.gd',
    'tools/godot_m6_real_asset_deploy_settlement_loop_runner.gd',
    'docs/20_product/M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_CONTRACT.md',
    'docs/validation/M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION.md',
    'docs/handoff/HANDOFF_M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP.md'
)
foreach ($RelativePath in $RequiredFiles) {
    if (-not [System.IO.File]::Exists((Join-Path $RepoRoot $RelativePath))) {
        $Failures.Add("missing file: $RelativePath")
    }
}

$Markers = @(
    @{ Path = 'Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd'; Values = @('requires_salvage_selection', '_clear_terminal_consumables', '_validate_salvage_selection', 'salvage_capacity": 0') },
    @{ Path = 'Godot/GraytailGodot/scripts/core/save/meta_progress_adapter.gd'; Values = @('duplicate_ignored', 'history_records', '_remove_carry_in_items') },
    @{ Path = 'Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd'; Values = @('MAX_EQUIPPED_ITEMS := 2', 'MAX_CARRIED_CONSUMABLES := 3', 'temporary_claim') },
    @{ Path = 'Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd'; Values = @('continue_active_run', 'abandon_active_run') },
    @{ Path = 'Godot/GraytailGodot/scripts/ui/result/result_panel.gd'; Values = @('failure_salvage_confirmed', 'FailureSalvagePanel', 'selected_salvage_ids') },
    @{ Path = 'Godot/GraytailGodot/scripts/core/run/run_scene.gd'; Values = @('continue_active_run', 'abandon_active_run', 'confirm_failure_salvage') }
)
foreach ($MarkerGroup in $Markers) {
    $FullPath = Join-Path $RepoRoot $MarkerGroup.Path
    if (-not [System.IO.File]::Exists($FullPath)) { continue }
    $Text = [System.IO.File]::ReadAllText($FullPath)
    foreach ($Marker in $MarkerGroup.Values) {
        if (-not $Text.Contains([string]$Marker)) {
            $Failures.Add("missing M6 marker '$Marker' in $($MarkerGroup.Path)")
        }
    }
}

$ForbiddenSpecs = @(
    'Godot/GraytailGodot/project.godot',
    ':(glob)Godot/GraytailGodot/**/*.tscn',
    ':(glob)Godot/GraytailGodot/**/*.tres',
    ':(glob)Godot/GraytailGodot/**/*.res',
    ':(glob)Godot/GraytailGodot/**/*.uid',
    ':(glob)Godot/GraytailGodot/**/*.translation',
    ':(glob)Godot/GraytailGodot/**/*.import'
)
if ([string]::IsNullOrWhiteSpace($GitExecutable)) {
    $GitExecutable = (Get-Command git -ErrorAction Stop).Source
}
$ForbiddenDiff = & $GitExecutable -C $RepoRoot diff --name-only -- $ForbiddenSpecs
foreach ($Path in $ForbiddenDiff) {
    $Failures.Add("forbidden Godot metadata/project diff: $Path")
}
$Untracked = & $GitExecutable -C $RepoRoot ls-files --others --exclude-standard
foreach ($Path in $Untracked) {
    if ($Path -match '^Godot/GraytailGodot/.*\.(tscn|tres|res|uid|translation|import)$' -or $Path -eq 'Godot/GraytailGodot/project.godot') {
        $Failures.Add("forbidden untracked Godot metadata/resource: $Path")
    }
}

if (-not [System.IO.File]::Exists($GodotExecutable)) {
    $Failures.Add("Godot executable missing: $GodotExecutable")
} else {
    $RunnerPath = Join-Path $RepoRoot 'tools/godot_m6_real_asset_deploy_settlement_loop_runner.gd'
    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $RunnerOutput = & $GodotExecutable --headless --path $ProjectRoot --script $RunnerPath 2>&1
    $RunnerCode = $LASTEXITCODE
    $RunnerOutput | ForEach-Object { Write-Output $_ }
    if ($RunnerCode -ne 0) {
        $Failures.Add("M6 runner exited with code $RunnerCode")
    }
    if (-not (($RunnerOutput -join "`n").Contains('M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP=PASS'))) {
        $Failures.Add('M6 runner PASS marker missing')
    }
    $Art22Output = & $GodotExecutable --headless --path $ProjectRoot --script 'res://tests/art22_deploy_prep_runtime_runner.gd' 2>&1
    $Art22Code = $LASTEXITCODE
    $Art22Output | ForEach-Object { Write-Output $_ }
    if ($Art22Code -ne 0 -or -not (($Art22Output -join "`n").Contains('ART22_DEPLOY_PREP_RUNTIME=PASS'))) {
        $Failures.Add('ART22 DeployPrep visible runtime regression failed')
    }
    $ErrorActionPreference = $PreviousErrorActionPreference
}

if ($Failures.Count -gt 0) {
    Write-Output 'M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION=FAIL'
    foreach ($Failure in $Failures) { Write-Output "FAIL: $Failure" }
    exit 1
}

Write-Output 'M6_REAL_ASSET_DEPLOY_SETTLEMENT_LOOP_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
