$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot '..\..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
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

function Resolve-RepoPath {
    param([string]$RelativePath)
    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $RelativePath))
    if (-not ($FullPath -eq $RepoRoot -or $FullPath.StartsWith($RepoRoot + [System.IO.Path]::DirectorySeparatorChar))) {
        Add-Failure "outside repo: $RelativePath"
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

function Read-RepoText {
    param([string]$RelativePath)
    $FullPath = Resolve-RepoPath $RelativePath
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing: $RelativePath"
        return ''
    }
    return [System.IO.File]::ReadAllText($FullPath)
}

function Test-ProjectFileContains {
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

function Test-RepoFileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )
    $Text = Read-RepoText $RelativePath
    foreach ($Pattern in $Patterns) {
        if ($Text -notmatch [regex]::Escape($Pattern)) {
            Add-Failure "missing pattern in ${RelativePath}: $Pattern"
        }
    }
}

Test-ProjectFileContains 'scripts/core/run/run_scene.gd' @(
    'G9ShellPanelScript',
    'InventoryPanelScript',
    'GroundLootPanelScript',
    'SCREEN_LONG_TERM',
    'MainMenuPanel',
    'ModeEntryPanel',
    'DeployShellPanel',
    'LongTermSystemPanel',
    'InventoryPanel',
    'GroundLootPanel',
    'CommandResultReasonLabel',
    'DebugOperationPanel',
    'debug_panel.visible = false',
    '_show_inventory_panel',
    '_show_ground_loot_panel',
    '_pickup_floor_from_ui',
    '_drop_inventory_from_ui',
    'command_bus.dispatch(&"attempt_room_transition"',
    'RunUIViewModel.command_result_text'
)

Test-ProjectFileContains 'scripts/ui/shell/g9_shell_panel.gd' @(
    'class_name G9ShellPanel',
    'MainMenuTitle',
    'MainMenuSubtitle',
    'ModeEntryPanel',
    'LongTermSystemPanel',
    'SettingsShellPanel',
    'StartTutorialButton',
    'StartStandard10x10Button',
    'DeployShellTabs',
    '&"warehouse"',
    '&"claim"',
    '&"config"',
    '&"character"',
    '&"tasks"',
    '&"codex"',
    '&"achievements"',
    '&"profile"',
    '&"research"',
    'PresentationLayerEntry',
    'ThemeProfile',
    'center_expanded'
)

Test-ProjectFileContains 'scripts/ui/inventory/inventory_panel.gd' @(
    'class_name InventoryPanel',
    'drop_item_requested',
    'RunUIViewModel.item_display_line',
    'RunUIViewModel.item_tooltip',
    'RunUIViewModel.command_result_text',
    'InventoryDropButton',
    'backpack_capacity'
)

Test-ProjectFileContains 'scripts/ui/ground_loot/ground_loot_panel.gd' @(
    'class_name GroundLootPanel',
    'pickup_item_requested',
    'RunUIViewModel.item_display_line',
    'RunUIViewModel.item_tooltip',
    'RunUIViewModel.command_result_text',
    'GroundLootPickupButton',
    'blocked_capacity'
)

Test-ProjectFileContains 'scripts/ui/shell/run_ui_view_model.gd' @(
    'class_name RunUIViewModel',
    'reason_label',
    'tutorial_lock',
    'invalid_direction',
    'blocked_capacity',
    'cannot_extract',
    'event_option_unavailable',
    'compact_event_log',
    'compact_transaction_log',
    'event_log',
    'transaction_log'
)

Test-ProjectFileContains 'scripts/ui/result/result_panel.gd' @(
    'RunUIViewModel.result_summary',
    'event_log',
    'transaction_log',
    'failure_salvage',
    'salvaged_item_count',
    'settlement_log'
)

Test-ProjectFileContains 'scripts/presentation/presentation_layer_contracts.gd' @(
    'class_name PresentationLayerContracts',
    'ThemeProfile',
    'PresentationLayerEntry',
    'NavigationEntry',
    'ShortcutEntry'
)

Test-RepoFileContains 'docs/branch_changes/G9_UI_FINAL_INTEGRATION_BRANCH.md' @(
    'godot/g9-ui-final-integration',
    'aa5a93ed68a9a755293b97e65d4b9ffa4881054e',
    'InventoryPanel',
    'GroundLootPanel',
    'validate_ui_final_g9.ps1'
)

Test-RepoFileContains 'docs/audits/AUDIT_G9_UI_FINAL_INTEGRATION.md' @(
    'G9 UI Final Integration',
    'formal player flow',
    'not a full final UI',
    'No full MetaProgress',
    'No Deploy persistence',
    'No action combat'
)

Test-RepoFileContains 'docs/handoff/HANDOFF_G9_UI_FINAL_INTEGRATION.md' @(
    'G9 UI Final Integration',
    'UI baseline',
    'CommandBus.dispatch',
    'ViewModel',
    'InventoryPanel',
    'GroundLootPanel'
)

$RunSceneText = Read-ProjectText 'scripts/core/run/run_scene.gd'
if ($RunSceneText -match '格外危除|鏍煎') {
    Add-Failure 'wrong or mojibake title remains in run_scene'
}
if ($RunSceneText -match 'RunAssetLedger|asset_ledger\.|TruthMap|get_cell\(|get_room_type\(') {
    Add-Failure 'run_scene directly reads core private ledger or TruthMap state'
}
if ($RunSceneText -match '_add_debug_button\([^\r\n]*PickupFloor[\s\S]*_add_menu_button\([^\r\n]*PickupFloor') {
    Add-Failure 'pickup appears to remain debug-only'
}
if ($RunSceneText -notmatch '_show_inventory_panel' -or $RunSceneText -notmatch '_show_ground_loot_panel') {
    Add-Failure 'formal action bar does not expose inventory and ground loot'
}

$UiScriptFiles = @(
    $(Get-Item -LiteralPath (Resolve-ProjectPath 'scripts/ui/shell/g9_shell_panel.gd')),
    $(Get-Item -LiteralPath (Resolve-ProjectPath 'scripts/ui/shell/run_ui_view_model.gd')),
    $(Get-Item -LiteralPath (Resolve-ProjectPath 'scripts/ui/inventory/inventory_panel.gd')),
    $(Get-Item -LiteralPath (Resolve-ProjectPath 'scripts/ui/ground_loot/ground_loot_panel.gd')),
    $(Get-Item -LiteralPath (Resolve-ProjectPath 'scripts/ui/result/result_panel.gd'))
)
foreach ($File in $UiScriptFiles) {
    $Relative = $File.FullName.Substring($ProjectRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $Text = [System.IO.File]::ReadAllText($File.FullName)
    if ($Text -match 'FileAccess|ResourceSaver|DirAccess|user://|SettingsManager\.set_value|DeployPersistence|ActionCombat|MetaProgress\.new') {
        Add-Failure "UI script contains forbidden persistence or out-of-scope implementation: $Relative"
    }
    if ($Text -match 'RunAssetLedger|asset_ledger\.|TruthMap|get_cell\(|get_room_type\(') {
        Add-Failure "UI script directly reads core private ledger or TruthMap state: $Relative"
    }
}

$LuaPrototypeStatus = @(git -C $RepoRoot status --short -- lua-prototype-main)
if ($LuaPrototypeStatus.Count -gt 0) {
    Add-Failure 'lua-prototype-main has local modifications'
}

if ($Failures.Count -gt 0) {
    Write-Output 'UI_FINAL_G9_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'UI_FINAL_G9_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'THREE_PAGE_SHELL=PASS'
Write-Output 'INVENTORY_GROUND_LOOT_FLOW=PASS'
Write-Output 'COMMAND_RESULT_REASON=PASS'
Write-Output 'EVENT_TRANSACTION_RESULT_EXPLANATION=PASS'
Write-Output 'DEBUG_DEV_ONLY_COLLAPSED=PASS'
Write-Output 'NO_FORBIDDEN_PERSISTENCE_OR_ACTION_COMBAT=PASS'
