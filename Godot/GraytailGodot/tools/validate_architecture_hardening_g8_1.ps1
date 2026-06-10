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

Test-FileContains 'scripts/core/run/run_query_facade.gd' @(
    'class_name RunQueryFacade',
    'func build_status_snapshot',
    'func build_result_snapshot',
    'func get_inventory_summary',
    'func get_encounter_summary',
    'get_public_snapshot',
    '"blocked_reason"'
)

Test-FileContains 'scripts/core/run/run_context.gd' @(
    'var query_facade',
    'RunQueryFacade.new()',
    'func build_result_snapshot',
    '_query().build_result_snapshot(self)',
    'func get_status_snapshot',
    '_query().build_status_snapshot(self)'
)

Test-FileContains 'scripts/core/run/run_rule_service.gd' @(
    'RuleResult',
    'EffectSpec',
    'make_rule_result',
    'make_effect_spec',
    '"ok"',
    '"status"',
    '"reason"',
    '"actor_id"',
    '"effects"',
    '"messages"',
    '"snapshot_delta"',
    '"settlement_log_entry"',
    'RunAssetEffectHandler.apply_effects'
)

Test-FileContains 'scripts/core/run/run_asset_effect_handler.gd' @(
    'class_name RunAssetEffectHandler',
    'EFFECT_ADD_CURRENCY',
    'EFFECT_SPEND_CURRENCY',
    'EFFECT_ADD_REWARD_ITEMS',
    'EFFECT_ADD_STATUS_EFFECT',
    'EFFECT_PICKUP_GROUND_ITEM',
    'EFFECT_DROP_INVENTORY_ITEM',
    'EFFECT_SETTLE_SUCCESS',
    'EFFECT_SETTLE_FAILURE',
    'sync_compat_fields'
)

Test-FileContains 'scripts/core/command/command_bus.gd' @(
    'DEFAULT_ACTOR_ID',
    'command_sequence',
    '_normalize_command',
    '"command_id"',
    '"actor_id"',
    '"source"',
    '"payload"',
    '"sequence"',
    'blocked_reason'
)

Test-FileContains 'scripts/core/content/run_rule_content.gd' @(
    'class_name RunRuleContent',
    'default_search_black_coin',
    'default_search_items',
    'item_def'
)

Test-FileContains 'scripts/core/save/save_adapter.gd' @(
    'class_name SaveAdapter',
    'build_run_save_snapshot',
    'can_write_persistence',
    'return false',
    'writes_storage'
)

Test-FileContains 'scripts/core/save/meta_progress_adapter.gd' @(
    'class_name MetaProgressAdapter',
    'build_settlement_export',
    'can_write_persistence',
    'return false',
    'writes_storage'
)

Test-FileContains 'scripts/ui/hud/hud_view_model.gd' @(
    'build_from_snapshot',
    'build_status'
)

$UiFiles = @(
    'scripts/core/run/run_scene.gd',
    'scripts/ui/hud/hud.gd',
    'scripts/ui/hud/hud_view_model.gd',
    'scripts/ui/result/result_panel.gd',
    'scripts/ui/minimap/minimap_panel.gd',
    'scripts/ui/minimap/minimap_view_model.gd',
    'scripts/ui/map_overlay/map_overlay_panel.gd',
    'scripts/ui/tutorial/tutorial_popup_panel.gd'
)
foreach ($RelativePath in $UiFiles) {
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'asset_ledger\.|RunAssetLedger|truth_map\.|TruthMap\.new|get_room_type\(|get_cell\(') {
        Add-Failure "UI script directly reads/writes ledger or TruthMap: $RelativePath"
    }
}

$NoPersistenceFiles = @(
    'scripts/core/run/run_asset_ledger.gd',
    'scripts/core/run/run_asset_effect_handler.gd',
    'scripts/core/run/run_rule_service.gd',
    'scripts/core/run/run_query_facade.gd',
    'scripts/core/run/run_context.gd',
    'scripts/core/command/command_bus.gd',
    'scripts/core/content/run_rule_content.gd',
    'scripts/core/save/save_adapter.gd',
    'scripts/core/save/meta_progress_adapter.gd',
    'scripts/core/run/run_scene.gd',
    'scripts/ui/result/result_panel.gd'
)
foreach ($RelativePath in $NoPersistenceFiles) {
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'FileAccess|ResourceSaver|DirAccess|user://|SettingsManager\.set_value') {
        Add-Failure "G8.1 architecture path contains persistence/write API: $RelativePath"
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'ARCHITECTURE_HARDENING_G8_1_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'ARCHITECTURE_HARDENING_G8_1_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'QUERY_SNAPSHOT_BOUNDARY=PASS'
Write-Output 'RULE_RESULT_EFFECT_SPEC=PASS'
Write-Output 'COMMAND_ENVELOPE=PASS'
Write-Output 'CONTENT_FALLBACK=PASS'
Write-Output 'SAVE_META_ADAPTER_CONTRACTS=PASS'
Write-Output 'NO_UI_LEDGER_TRUTHMAP_ACCESS=PASS'
Write-Output 'NO_PERSISTENCE_API=PASS'
