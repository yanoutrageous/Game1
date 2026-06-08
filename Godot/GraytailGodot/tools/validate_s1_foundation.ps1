$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$ExpectedRoot = 'D:\Godot\GraytailGodot'

if ($ProjectRoot -ne $ExpectedRoot) {
    Write-Output "S1_VALIDATION=FAIL"
    Write-Output "project root mismatch: $ProjectRoot"
    exit 1
}

$Failures = @()

function Test-FileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )

    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $RelativePath))
    if (-not ($FullPath -eq $ProjectRoot -or $FullPath.StartsWith($ProjectRoot + [System.IO.Path]::DirectorySeparatorChar))) {
        $script:Failures += "outside project: $RelativePath"
        return
    }

    if (-not [System.IO.File]::Exists($FullPath)) {
        $script:Failures += "missing: $RelativePath"
        return
    }

    $Text = [System.IO.File]::ReadAllText($FullPath)
    foreach ($Pattern in $Patterns) {
        if ($Text -notmatch [regex]::Escape($Pattern)) {
            $script:Failures += "missing pattern in ${RelativePath}: $Pattern"
        }
    }
}

Test-FileContains 'scripts/core/content/content_db.gd' @('func get_asset_ref', 'func has_asset', 'func get_placeholder_label')
Test-FileContains 'scripts/core/run/run_context.gd' @('func reset_demo_run', 'func is_inside', 'func get_current_pos', 'func get_status_snapshot')
Test-FileContains 'scripts/core/map/truth_map.gd' @('func setup_demo_map', 'func get_room_type', 'func set_room_type', 'func is_mine', 'func get_adjacent_mine_count', 'func is_inside', 'width = 7', 'height = 7', '&"Spawn"', '&"Mine"', '&"Chest"', '&"Event"', '&"Monster"', '&"Exit"', '&"Normal"')
Test-FileContains 'scripts/core/intel/intel_map.gd' @('func setup', 'func reveal_cell', 'func flag_cell', 'func is_revealed', 'func get_cell_info', 'func get_all_cells')
Test-FileContains 'scripts/core/map/minefield_service.gd' @('func count_adjacent_mines', 'func get_neighbors_8')
Test-FileContains 'scripts/core/command/command_bus.gd' @('func bind_context', 'func start_demo_run', 'func move_by', 'func flag_current_cell', 'func interact', 'func extract', 'func restart_run')
Test-FileContains 'scripts/core/run/room_resolver.gd' @('func enter_room', 'func interact_current_room')
Test-FileContains 'scripts/ui/minimap/minimap_view_model.gd' @('func build_from_intel')
Test-FileContains 'scripts/ui/hud/hud_view_model.gd' @('class_name HUDViewModel', 'func build_status')
Test-FileContains 'scripts/ui/minimap/minimap_panel.gd' @('get_asset_ref', 'get_placeholder_label')
Test-FileContains 'scripts/core/run/run_scene.gd' @('StartRun', 'MoveUp', 'MoveDown', 'MoveLeft', 'MoveRight', 'Flag', 'Interact', 'Extract', 'Restart', 'move_up', 'move_down', 'move_left', 'move_right', 'interact', 'flag_cell', 'open_map', 'debug_restart_run')
Test-FileContains 'data/assets/asset_manifest.csv' @('license_status', 'replacement_needed', 'internal placeholder only; replace before public release')

if ($Failures.Count -gt 0) {
    Write-Output 'S1_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'S1_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'CHECKED=S1 interfaces, manifest placeholders, minimap fallback, debug entries'
