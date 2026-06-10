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

function Read-ProjectText {
    param([string]$RelativePath)
    $FullPath = Resolve-ProjectPath $RelativePath
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing: $RelativePath"
        return ''
    }
    return [System.IO.File]::ReadAllText($FullPath)
}

function Test-FileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )
    $Text = Read-ProjectText $RelativePath
    foreach ($Pattern in $Patterns) {
        if ($Text -notmatch [regex]::Escape($Pattern)) {
            Add-Failure "missing pattern in ${RelativePath}: $Pattern"
        }
    }
}

function Test-FileDoesNotMatch {
    param(
        [string]$RelativePath,
        [string]$Pattern,
        [string]$Message
    )
    $Text = Read-ProjectText $RelativePath
    if ($Text -match $Pattern) {
        Add-Failure $Message
    }
}

Test-FileContains 'scripts/core/run/run_scene.gd' @(
    'SCREEN_MAIN_MENU',
    'SCREEN_DEPLOY',
    'SCREEN_RUN',
    'MainMenuPanel',
    'ModeEntryPanel',
    'DeployShellPanel',
    'DeployShellTabs',
    'StartStandard10x10Button',
    'RunOverlayRoot',
    'LeftSidebar',
    'RightUtilityRail',
    'ProtocolStatusPanel',
    'BottomActionBar',
    'BottomActionBarButtons',
    'DebugToggleButton',
    'debug_panel.visible = false',
    'EventOptionPanel',
    'LootResultPanel',
    'ExtractConfirmPanel',
    'func _show_main_menu',
    'func _show_deploy_shell',
    'func _show_settings_shell',
    'func _show_run_screen',
    'func _handle_interact_pressed',
    'func _show_event_panel',
    'func _show_loot_panel',
    'func _request_extract_from_ui',
    'func _event_type_label',
    'player_controller.move_local',
    'command_bus.dispatch(&"attempt_room_transition"',
    'GridUp'
)

Test-FileContains 'scripts/presentation/presentation_mapping.gd' @(
    'func hint_for_snapshot',
    '&"Event":',
    '&"Exit":',
    '&"Monster":'
)

Test-FileContains 'scripts/core/run/event_service.gd' @(
    'EVENT_TYPES := [&"trader", &"dice", &"altar", &"trap"]',
    'func get_event_options',
    'func execute_option',
    'func _execute_trader',
    'func _execute_dice',
    'func _execute_altar',
    'func _execute_trap'
)

Test-FileContains 'scripts/core/run/tutorial_service.gd' @(
    'POPUP_DEFS',
    '&"spawn_intro"',
    '&"number_rule"',
    '&"mine_rule"',
    '&"event_rule"',
    '&"monster_rule"',
    '&"chest_rule"',
    '&"map_rule"',
    '&"exit_goal"',
    '"blocking": true',
    '"once": true',
    '"show_after_room_effect": true'
)

Test-FileContains 'scripts/ui/tutorial/tutorial_popup_panel.gd' @(
    'apply_popup',
    'confirmed.emit()',
    'button.text ='
)

Test-FileContains 'scripts/ui/hud/hud.gd' @(
    'StatusBackdrop',
    'ProtocolBackdrop',
    'HintBackdrop',
    'ColorRect.new',
    'PresentationTheme.panel_color'
)

Test-FileContains 'scripts/ui/hud/hud_view_model.gd' @(
    'LEGACY_STATUS_VALIDATION_MARKERS',
    'PresentationMapping.hint_for_snapshot',
    'model.status_text',
    'model.protocol_text',
    'model.hint_text'
)

Test-FileContains 'scripts/ui/minimap/minimap_panel.gd' @(
    'LEGACY_MINIMAP_VALIDATION_MARKER',
    'MiniMapViewModel',
    'ContentDB.get_placeholder_label'
)

Test-FileContains 'scripts/ui/map_overlay/map_overlay_panel.gd' @(
    'signal cell_action_requested',
    'LEGACY_MAP_OVERLAY_VALIDATION_MARKER',
    'Button.new',
    'cell_action_requested.emit'
)

Test-FileContains 'scripts/ui/result/result_panel.gd' @(
    'LEGACY_RESULT_VALIDATION_MARKERS',
    'failure_salvage',
    'salvaged_item_count',
    'set_result_summary',
    'show_summary'
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

$RunSceneText = Read-ProjectText 'scripts/core/run/run_scene.gd'
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
if ($RunSceneText -match '_add_menu_button\([^\r\n]*"Start Tutorial 5x5"') {
    Add-Failure 'formal main menu still displays graybox Start Tutorial button'
}
if ($RunSceneText -match '_add_button\([^\r\n]*"Start Standard 10x10"') {
    Add-Failure 'formal deploy shell still displays graybox Start Standard button'
}

$LegacyEventHint = 'resolve event ' + 'placeholder'
$PresentationText = Read-ProjectText 'scripts/presentation/presentation_mapping.gd'
if ($PresentationText -match [regex]::Escape($LegacyEventHint)) {
    Add-Failure 'event presentation hint still contains the old placeholder event wording'
}

Test-FileDoesNotMatch 'scripts/core/run/run_scene.gd' '_add_menu_button\([^\r\n]*"Depart Exploration"' 'formal main menu still displays engineering Depart Exploration text'
Test-FileDoesNotMatch 'scripts/core/run/run_scene.gd' 'Lua flow parity shell|Read-only Foundation|No persistence writes|Choose an event option|Loot Result|Battle Result|Event Result|Confirm Extraction' 'run scene still contains visible engineering or graybox wording'
Test-FileDoesNotMatch 'scripts/core/run/event_service.gd' 'Sell best carried item|Bet 20 pending gold|Offer 10 HP|Disarm trap|Leave trader|Dice completed|Altar completed|Trap disarmed|Trap sprung' 'event service still contains old English option/result wording'
Test-FileDoesNotMatch 'scripts/core/run/tutorial_service.gd' 'Training Start|Mine Count|Mine Room|Event Room|Monster Room|Chest Room|Map Overlay|Route Planning|Use the exit' 'tutorial service still contains old English tutorial copy'
Test-FileDoesNotMatch 'scripts/ui/tutorial/tutorial_popup_panel.gd' 'button\.text\s*=\s*"Confirm"' 'tutorial popup confirm button still uses English visible text'
Test-FileDoesNotMatch 'scripts/ui/result/result_panel.gd' 'set_result_summary\("Run Result"' 'result panel still uses old English result title'

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
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'truth_map\.|TruthMap\.new|get_room_type\(|get_cell\(') {
        Add-Failure "UI script directly reads TruthMap: $RelativePath"
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
Write-Output 'NO_EVENT_PLACEHOLDER=PASS'
Write-Output 'LOCALIZED_TUTORIAL_AND_RESULT_FLOW=PASS'
Write-Output 'DEBUG_GRID_MOVE_COLLAPSED=PASS'
Write-Output 'ROOM_LOCAL_MOVEMENT_STILL_SEPARATED=PASS'
Write-Output 'UI_TRUTHMAP_BOUNDARY=PASS'
