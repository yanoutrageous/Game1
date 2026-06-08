$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot '..\..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$Failures = @()

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
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

function Test-Exists {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Failure "missing ${Label}: $Path"
    }
}

Test-Exists (Join-Path $RepoRoot 'docs\lua_audit\LUA_DEEP_AUDIT_REPORT.md') 'Lua deep audit'
Test-Exists (Join-Path $RepoRoot 'docs\lua_audit\LUA_TO_GODOT_PARITY_SPEC.md') 'Lua to Godot parity spec'
Test-Exists (Join-Path $RepoRoot 'docs\lua_audit\LUA_SYSTEM_CALLGRAPH.md') 'Lua system callgraph'
Test-Exists (Join-Path $RepoRoot 'docs\lua_audit\LUA_PARITY_TASKS_FOR_GODOT.csv') 'Lua parity tasks'

Test-FileContains 'scripts/core/run/run_config.gd' @(
    'func tutorial_5x5',
    '"width": 5',
    '"height": 5',
    '"seed": 777',
    '"mine_count": 4',
    '"event_room_count": 4',
    '"monster_room_count": 5',
    '"chest_room_count": 4',
    '"random_exit_count": 0',
    'Vector2i(0, 2)',
    'Vector2i(1, 1)',
    'Vector2i(2, 0)',
    'Vector2i(3, 3)',
    'Vector2i(4, 4)',
    'tutorial_exit',
    'func standard_10x10',
    '"width": 10',
    '"height": 10',
    '"mine_count": 20',
    '"monster_room_count": 10',
    '"chest_room_count": 10',
    '"event_room_count": 10',
    '"random_exit_count": 2',
    '"mine_hits_are_fatal": false',
    '"reveal_on_move": true',
    '"move_requires_revealed": false'
)

Test-FileContains 'scripts/core/map/truth_map.gd' @(
    'func setup_from_config',
    'func setup_manual_map',
    'func setup_standard_map',
    'func get_visible_exits',
    'func mark_triggered',
    'func count_room_type',
    '"random_exit": true',
    'get_adjacent_mine_count'
)

Test-FileContains 'scripts/core/intel/intel_map.gd' @(
    'func build_public_cell',
    'func get_visible_map',
    'func toggle_flag',
    '"state": &"hidden"',
    '"adjacent_mines": -1',
    'random_exit',
    'exit_id'
)

Test-FileContains 'scripts/core/run/run_context.gd' @(
    'var mode',
    'var phase',
    'var turn',
    'var power',
    'var protocol_level',
    'var pending_gold',
    'var safe_gold',
    'var parts',
    'var searched_cells',
    'var run_stats',
    'var result_snapshot',
    'func start_tutorial_run',
    'func start_standard_run',
    'func complete_extract',
    'func fail_run'
)

Test-FileContains 'scripts/core/command/command_bus.gd' @(
    'func start_tutorial_run',
    'func start_standard_run',
    'func move_by',
    'func toggle_flag_cell',
    'func search_current_room',
    'func interact_current_room',
    'func fight_current_enemy',
    'func request_extract',
    'func confirm_extract',
    'func cancel_extract',
    'abs(delta.x) + abs(delta.y) != 1',
    'Blocked by map boundary'
)

Test-FileContains 'scripts/core/run/room_resolver.gd' @(
    'func enter_room',
    'func search_current_room',
    'func interact_current_room',
    'func fight_current_enemy',
    'func can_extract',
    'ProtocolService.add_pressure(context, 2)',
    'ProtocolService.add_pressure(context, 10)',
    'CombatState.take_mine_hit',
    'RunInventory.add_search_reward',
    'context.searched_cells[key] = true'
)

Test-FileContains 'scripts/core/run/protocol_service.gd' @('pressure >= 80', 'pressure >= 60', 'pressure >= 40', 'pressure >= 20', 'return 5')
Test-FileContains 'scripts/core/run/combat_state.gd' @('BASE_MINE_DAMAGE := 30', 'func take_mine_hit', 'func fight_enemy')
Test-FileContains 'scripts/core/run/run_inventory.gd' @('func add_search_reward', 'min(4', 'min(11', 'context.carried_items.append_array')
Test-FileContains 'scripts/core/run/tutorial_service.gd' @('func trigger_for', 'tutorial_popup', 'func confirm_popup')
Test-FileContains 'scripts/ui/minimap/minimap_view_model.gd' @('func build_from_intel', 'intel_map.get_visible_map')
Test-FileContains 'scripts/ui/hud/hud_view_model.gd' @('HP:', 'Power:', 'Pressure:', 'Adjacent Mines:', 'Search:', 'Enemy/Event/Exit Hint')
Test-FileContains 'scripts/ui/result/result_panel.gd' @('Outcome:', 'Safe Gold:', 'Final HP:', 'Final Pressure:', 'Monsters Defeated:')

$UiFiles = @(
    'scripts/ui/hud/hud.gd',
    'scripts/ui/hud/hud_view_model.gd',
    'scripts/ui/minimap/minimap_panel.gd',
    'scripts/ui/minimap/minimap_view_model.gd',
    'scripts/ui/result/result_panel.gd'
)
foreach ($RelativePath in $UiFiles) {
    $FullPath = Join-Path $ProjectRoot $RelativePath
    if ([System.IO.File]::Exists($FullPath)) {
        $Text = [System.IO.File]::ReadAllText($FullPath)
        if ($Text -match 'truth_map\.|TruthMap\.new|get_room_type\(|get_cell\(') {
            Add-Failure "UI script directly reads TruthMap: $RelativePath"
        }
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'LUA_PARITY_P0_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'LUA_PARITY_P0_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'TUTORIAL_5X5=PASS'
Write-Output 'STANDARD_10X10_COUNTS=PASS'
Write-Output 'COMMAND_BUS_ENTRY=PASS'
Write-Output 'UI_TRUTHMAP_BOUNDARY=PASS'
