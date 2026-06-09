$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$Failures = @()

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
}

function Resolve-ProjectPath {
    param([string]$RelativePath)
    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $RelativePath))
    if (-not ($FullPath -eq $ProjectRoot -or $FullPath.StartsWith($ProjectRoot + [System.IO.Path]::DirectorySeparatorChar))) {
        Add-Failure "outside project: $RelativePath"
    }
    return $FullPath
}

function Test-FileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )
    $FullPath = Resolve-ProjectPath $RelativePath
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

Test-FileContains 'scripts/gameplay/player/player_controller.gd' @(
    'var local_pos',
    'func move_local',
    'func place_from_entry',
    'func block_transition',
    'func _transition_for_next_pos',
    'ROOM_RECT',
    'LOCAL_MOVE_SPEED'
)

Test-FileContains 'scripts/core/run/run_scene.gd' @(
    'func _process',
    'player_controller.move_local',
    '_attempt_room_transition',
    'command_bus.attempt_room_transition',
    'GridUp',
    'Debug / Grid Move',
    'cell_action_requested.connect',
    'teleport_to_explored'
)

Test-FileContains 'scripts/core/command/command_bus.gd' @(
    'func attempt_room_transition',
    'return move_by(direction)',
    'func teleport_to_explored',
    'func select_event_option',
    'toggle_flag_cell(payload.get("pos", null))'
)

Test-FileContains 'scripts/core/run/event_service.gd' @(
    'class_name EventService',
    'EVENT_TYPES := [&"trader", &"dice", &"altar", &"trap"]',
    'func get_event_state',
    'func execute_option',
    'func _execute_trader',
    'func _execute_dice',
    'func _execute_altar',
    'func _execute_trap'
)

Test-FileContains 'scripts/core/run/room_resolver.gd' @(
    'EventService.get_event_state',
    'EventService.execute_default',
    'func select_event_option',
    'CombatState.build_enemy_state',
    'TutorialService.trigger_for'
)

Test-FileContains 'scripts/core/run/run_context.gd' @(
    'var event_state',
    'var enemy_state',
    'var failure_salvage',
    'func has_blocking_tutorial_popup',
    'search_state_data',
    'failure_salvage'
)

Test-FileContains 'scripts/core/run/run_inventory.gd' @(
    'func build_failure_salvage',
    'pending_gold_lost',
    'salvaged_item',
    'func get_carried_item_value'
)

Test-FileContains 'scripts/ui/map_overlay/map_overlay_panel.gd' @(
    'signal cell_action_requested',
    'Click hidden cells to flag',
    'Button.new',
    'cell_action_requested.emit'
)

Test-FileContains 'scripts/ui/result/result_panel.gd' @(
    'Failure Pending Lost:',
    'Failure Salvaged Items:',
    'Carried Items:',
    'Carried Value:'
)

$RunSceneText = [System.IO.File]::ReadAllText((Resolve-ProjectPath 'scripts/core/run/run_scene.gd'))
if ($RunSceneText -match 'event\.is_action_pressed\("move_up"\)[\s\S]{0,120}command_bus\.move_by') {
    Add-Failure 'formal move_up input still directly calls grid move'
}
if ($RunSceneText -match 'event\.is_action_pressed\("move_down"\)[\s\S]{0,120}command_bus\.move_by') {
    Add-Failure 'formal move_down input still directly calls grid move'
}
if ($RunSceneText -match 'event\.is_action_pressed\("move_left"\)[\s\S]{0,120}command_bus\.move_by') {
    Add-Failure 'formal move_left input still directly calls grid move'
}
if ($RunSceneText -match 'event\.is_action_pressed\("move_right"\)[\s\S]{0,120}command_bus\.move_by') {
    Add-Failure 'formal move_right input still directly calls grid move'
}

$UiFiles = @(
    'scripts/ui/hud/hud.gd',
    'scripts/ui/hud/hud_view_model.gd',
    'scripts/ui/minimap/minimap_panel.gd',
    'scripts/ui/minimap/minimap_view_model.gd',
    'scripts/ui/map_overlay/map_overlay_panel.gd',
    'scripts/ui/tutorial/tutorial_popup_panel.gd',
    'scripts/ui/result/result_panel.gd'
)
foreach ($RelativePath in $UiFiles) {
    $FullPath = Resolve-ProjectPath $RelativePath
    if ([System.IO.File]::Exists($FullPath)) {
        $Text = [System.IO.File]::ReadAllText($FullPath)
        if ($Text -match 'truth_map\.|TruthMap\.new|get_room_type\(|get_cell\(') {
            Add-Failure "UI script directly reads TruthMap: $RelativePath"
        }
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'LUA_PLAYABLE_PARITY_G6_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'LUA_PLAYABLE_PARITY_G6_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'ROOM_LOCAL_MOVEMENT=PASS'
Write-Output 'DEBUG_GRID_MOVE_SEPARATED=PASS'
Write-Output 'EVENT_SERVICE_P1=PASS'
Write-Output 'MAP_OVERLAY_INTERACTION=PASS'
Write-Output 'FAILURE_SALVAGE_RESULT=PASS'
Write-Output 'UI_TRUTHMAP_BOUNDARY=PASS'
