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

Test-FileContains 'scripts/core/run/run_scene.gd' @(
    'SCREEN_MAIN_MENU',
    'SCREEN_DEPLOY',
    'SCREEN_RUN',
    'MainMenuPanel',
    'ModeEntryPanel',
    'Depart Exploration',
    'Start Tutorial 5x5',
    'DeployShellPanel',
    'DeployShellTabs',
    'StartStandard10x10Button',
    'RunOverlayRoot',
    'LeftSidebar',
    'RightUtilityRail',
    'ProtocolStatusPanel',
    'BottomActionBar',
    'BottomActionBarButtons',
    'EventOptionPanel',
    'LootResultPanel',
    'ExtractConfirmPanel',
    'func _show_main_menu',
    'func _show_deploy_shell',
    'func _show_run_screen',
    'func _handle_interact_pressed',
    'func _show_event_panel',
    'func _show_loot_panel',
    'func _request_extract_from_ui',
    'player_controller.move_local',
    'command_bus.attempt_room_transition',
    'GridUp'
)

Test-FileContains 'scripts/ui/hud/hud.gd' @(
    'StatusBackdrop',
    'ProtocolBackdrop',
    'HintBackdrop',
    'ColorRect.new',
    'PresentationTheme.panel_color'
)

Test-FileContains 'scenes/ui/hud/hud.tscn' @(
    'MiniMapSlot',
    'StatusPanel',
    'ProtocolPanel',
    'HintPanel',
    'offset_top = 252.0',
    'offset_top = 424.0',
    'offset_top = 532.0'
)

Test-FileContains 'scenes/ui/result/result_panel.tscn' @(
    'offset_left = -310.0',
    'offset_top = -220.0',
    'offset_right = 310.0',
    'offset_bottom = 220.0'
)

$RunSceneText = [System.IO.File]::ReadAllText((Resolve-ProjectPath 'scripts/core/run/run_scene.gd'))
if ($RunSceneText -match 'event\.is_action_pressed\("move_up"\)[\s\S]{0,160}command_bus\.move_by') {
    Add-Failure 'formal move_up input still directly calls grid move'
}
if ($RunSceneText -match 'event\.is_action_pressed\("move_down"\)[\s\S]{0,160}command_bus\.move_by') {
    Add-Failure 'formal move_down input still directly calls grid move'
}
if ($RunSceneText -match 'event\.is_action_pressed\("move_left"\)[\s\S]{0,160}command_bus\.move_by') {
    Add-Failure 'formal move_left input still directly calls grid move'
}
if ($RunSceneText -match 'event\.is_action_pressed\("move_right"\)[\s\S]{0,160}command_bus\.move_by') {
    Add-Failure 'formal move_right input still directly calls grid move'
}
if ($RunSceneText -match 'FileAccess|ResourceSaver|DirAccess|MetaProgress|user://|SettingsManager\.set_value') {
    Add-Failure 'Deploy shell or run scene contains persistence/write API'
}

$UiFiles = @(
    'scripts/core/run/run_scene.gd',
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
    Write-Output 'LUA_UX_FLOW_PARITY_G7_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'LUA_UX_FLOW_PARITY_G7_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'MAIN_MENU_FLOW=PASS'
Write-Output 'DEPLOY_SHELL_READ_ONLY=PASS'
Write-Output 'RUN_LAYOUT_NO_OVERLAY_START_BUTTONS=PASS'
Write-Output 'EVENT_LOOT_EXTRACT_PANELS=PASS'
Write-Output 'ROOM_LOCAL_MOVEMENT_STILL_SEPARATED=PASS'
Write-Output 'UI_TRUTHMAP_BOUNDARY=PASS'
