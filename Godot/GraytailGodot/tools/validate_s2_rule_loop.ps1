$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$ExternalReports = $env:AGAME_REPORTS_DIR
$ExternalRepoCache = $env:AGAME_REPO_CACHE_DIR

$Failures = @()

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
}

function Test-Exists {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Failure "missing ${Label}: $Path"
    }
}

function Test-FileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )

    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $RelativePath))
    if (-not ($FullPath -eq $ProjectRoot -or $FullPath.StartsWith($ProjectRoot + [System.IO.Path]::DirectorySeparatorChar))) {
        Add-Failure "outside project: $RelativePath"
        return
    }

    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing: $RelativePath"
        return
    }

    $Text = [System.IO.File]::ReadAllText($FullPath)
    foreach ($Pattern in $Patterns) {
        if ($Text -notmatch [regex]::Escape($Pattern)) {
            Add-Failure "missing pattern in ${RelativePath}: $Pattern"
        }
    }
}

Test-Exists (Join-Path $ProjectRoot 'docs\S2_PATH_NORMALIZATION_REPORT.md') 'Godot path normalization report'
Test-Exists (Join-Path $ProjectRoot 'docs\S2_RULE_LOOP_REPORT.md') 'Godot rule loop report'

if (-not [string]::IsNullOrWhiteSpace($ExternalReports)) {
    Test-Exists (Join-Path $ExternalReports 'S2_PATH_NORMALIZATION_REPORT.md') 'external path normalization report'
    Test-Exists (Join-Path $ExternalReports 'S2_RULE_LOOP_REPORT.md') 'external rule loop report'
}
if (-not [string]::IsNullOrWhiteSpace($ExternalRepoCache)) {
    Test-Exists $ExternalRepoCache 'external repo cache'
}

Test-FileContains 'scripts/core/run/run_context.gd' @(
    'var run_started',
    'var width',
    'var height',
    'var player_pos',
    'var hp',
    'var max_hp',
    'var pressure',
    'var pending_gold',
    'var extracted',
    'var failed',
    'func reset_demo_run',
    'func is_inside',
    'func get_current_pos',
    'func get_status_snapshot'
)
Test-FileContains 'scripts/core/map/truth_map.gd' @(
    'func setup_demo_map',
    'width = 7',
    'height = 7',
    '&"Spawn"',
    '&"Mine"',
    '&"Chest"',
    '&"Event"',
    '&"Monster"',
    '&"Exit"',
    '&"Normal"',
    'func get_room_type',
    'func set_room_type',
    'func is_mine',
    'func get_adjacent_mine_count',
    'func is_inside'
)
Test-FileContains 'scripts/core/intel/intel_map.gd' @(
    'func setup',
    'func reveal_cell',
    'func flag_cell',
    'func is_revealed',
    'func get_cell_info',
    'func get_all_cells',
    'return "G"',
    'return "M"',
    'return "C"',
    'return "E"',
    'return "X"',
    'return "!"'
)
Test-FileContains 'scripts/core/map/minefield_service.gd' @('func count_adjacent_mines', 'func get_neighbors_8')
Test-FileContains 'scripts/core/command/command_bus.gd' @(
    'func start_demo_run',
    'func move_by',
    'func flag_current_cell',
    'func interact',
    'func extract',
    'func restart_run',
    'abs(delta.x) + abs(delta.y) != 1',
    'Blocked by map boundary'
)
Test-FileContains 'scripts/core/run/room_resolver.gd' @(
    'func enter_room',
    'func interact_current_room',
    'Mine room triggered',
    'Chest opened',
    'Event placeholder resolved',
    'Monster placeholder resolved'
)
Test-FileContains 'scripts/core/content/content_db.gd' @('func get_asset_ref', 'func has_asset', 'func get_placeholder_label')
Test-FileContains 'scripts/ui/minimap/minimap_view_model.gd' @('func build_from_intel')
Test-FileContains 'scripts/ui/hud/hud_view_model.gd' @('class_name HUDViewModel', 'func build_status', 'HP:', 'Pending Gold:', 'Position:', 'Room:', 'Adjacent Mines:', 'Last Message:')
Test-FileContains 'scripts/ui/result/result_panel.gd' @('Outcome:', 'Pending Gold:', 'Final HP:', 'Final Pressure:', 'Final Position:')
Test-FileContains 'scripts/core/run/run_scene.gd' @('StartRun', 'MoveUp', 'MoveDown', 'MoveLeft', 'MoveRight', 'Flag', 'Interact', 'Extract', 'Restart', 'move_up', 'move_down', 'move_left', 'move_right', 'interact', 'flag_cell', 'open_map', 'debug_restart_run')

$UiFiles = @(
    'scripts/ui/hud/hud.gd',
    'scripts/ui/minimap/minimap_panel.gd',
    'scripts/ui/result/result_panel.gd'
)
foreach ($RelativePath in $UiFiles) {
    $FullPath = Join-Path $ProjectRoot $RelativePath
    if ([System.IO.File]::Exists($FullPath)) {
        $Text = [System.IO.File]::ReadAllText($FullPath)
        if ($Text -match 'truth_map|TruthMap.new|get_room_type\(') {
            Add-Failure "UI script directly reads TruthMap: $RelativePath"
        }
    }
}

$ManifestPath = Join-Path $ProjectRoot 'data\assets\asset_manifest.csv'
if ([System.IO.File]::Exists($ManifestPath)) {
    $ManifestText = [System.IO.File]::ReadAllText($ManifestPath)
    if ($ManifestText -match 'commercial|commercial_ready|commercial-ready') {
        Add-Failure 'manifest appears to mark unknown assets as commercial-ready'
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'S2_RULE_LOOP_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'S2_RULE_LOOP_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
if (-not [string]::IsNullOrWhiteSpace($ExternalReports)) {
    Write-Output "EXTERNAL_REPORTS=$ExternalReports"
} else {
    Write-Output 'EXTERNAL_REPORTS=not checked; set AGAME_REPORTS_DIR to enable'
}
if (-not [string]::IsNullOrWhiteSpace($ExternalRepoCache)) {
    Write-Output "EXTERNAL_REPO_CACHE=$ExternalRepoCache"
} else {
    Write-Output 'EXTERNAL_REPO_CACHE=not checked; set AGAME_REPO_CACHE_DIR to enable'
}
