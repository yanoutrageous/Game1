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

Test-FileContains 'scripts/core/command/command_result.gd' @(
    'class_name CommandResult',
    '"accepted"',
    '"reason_code"',
    '"message_key"',
    '"command_id"',
    '"produced_events"',
    '"produced_transactions"',
    '"snapshot_delta"',
    'from_action'
)

Test-FileContains 'scripts/core/command/command_bus.gd' @(
    'func dispatch',
    '_normalize_command',
    '"command_id"',
    '"actor_id"',
    '"source"',
    '"payload"',
    '"sequence"',
    'CommandResult.from_action',
    '_events_since',
    '_transactions_since',
    '_snapshot_delta_for',
    'event_option_unavailable',
    'cannot_extract',
    'no_extract_request'
)

Test-FileContains 'scripts/core/run/run_query_facade.gd' @(
    'class_name RunQueryFacade',
    'func get_event_log_snapshot',
    'func get_transaction_log_snapshot',
    'func get_content_def_snapshot',
    '"event_log"',
    '"transaction_log"',
    '"content_definitions"',
    'get_public_snapshot'
)

Test-FileContains 'scripts/core/run/run_event_log.gd' @(
    'class_name RunEventLog',
    '"event_id"',
    '"event_type"',
    '"command_id"',
    '"actor_id"',
    '"source"',
    '"payload"',
    '"sequence"',
    'run_started',
    'room_entered',
    'room_searched',
    'item_gained',
    'item_picked_up',
    'item_dropped',
    'combat_resolved',
    'event_option_selected',
    'extraction_found',
    'extraction_success',
    'run_failed',
    'settlement_completed'
)

Test-FileContains 'scripts/core/run/run_transaction_log.gd' @(
    'class_name RunTransactionLog',
    '"transaction_id"',
    '"command_id"',
    '"effect_id"',
    '"actor_id"',
    '"source"',
    '"action"',
    '"before"',
    '"after"',
    '"currency_delta"',
    '"item_moves"',
    '"reason"',
    '"sequence"'
)

Test-FileContains 'scripts/core/run/run_asset_effect_handler.gd' @(
    'EffectSpec',
    'record_transaction',
    '_record_transaction_for_effect',
    '_record_events_for_effect',
    'EVENT_ITEM_GAINED',
    'EVENT_ITEM_PICKED_UP',
    'EVENT_ITEM_DROPPED',
    'EVENT_SETTLEMENT_COMPLETED',
    'produced_transactions'
)

Test-FileContains 'scripts/core/run/run_rule_service.gd' @(
    'RuleResult',
    'EffectSpec',
    '"effect_id"',
    '"command_id"',
    '"rule_request_id"',
    'make_rule_result',
    'make_effect_spec',
    '_make_rule_request',
    '_effect_for_request',
    '_finalize_rule',
    'produced_effects',
    'produced_transactions'
)

Test-FileContains 'scripts/core/run/run_rule_pipeline.gd' @(
    'class_name RunRulePipeline',
    'make_rule_request',
    'make_rule_context',
    'DefaultRuleResult',
    'apply_modifiers',
    'Final RuleResult',
    'produced_effects',
    'produced_events',
    'produced_transactions'
)

Test-FileContains 'scripts/core/run/run_modifier_spec.gd' @(
    'class_name RunModifierSpec',
    '"modifier_id"',
    '"source"',
    '"priority"',
    '"phase"',
    '"target_rule"',
    '"operation"',
    '"value"',
    '"duration"',
    '"stack_rule"',
    '"conflict_tags"',
    '"reason"',
    '"sequence"',
    'compare_stable'
)

Test-FileContains 'scripts/core/content/content_def_registry.gd' @(
    'class_name ContentDefRegistry',
    '"content_id"',
    '"schema_version"',
    '"kind"',
    '"display_name_key"',
    '"tags"',
    '"definition"',
    '"deprecated_state"',
    'CurrencyDef',
    'ItemDef',
    'EncounterDef',
    'EffectDef',
    'ModifierDef',
    'LootTableDef'
)

Test-FileContains 'scripts/core/run/run_context.gd' @(
    'var run_event_log',
    'var transaction_log',
    'var rule_pipeline',
    'var content_defs',
    'RunEventLog.new()',
    'RunTransactionLog.new()',
    'RunRulePipeline.new()',
    'ContentDefRegistry.new()',
    'record_event'
)

$RunSceneText = Read-ProjectText 'scripts/core/run/run_scene.gd'
if ($RunSceneText -match 'command_bus\.(move_by|attempt_room_transition|search_current_room|interact_current_room|fight_current_enemy|select_event_option|pickup_ground_item|drop_inventory_item|request_extract|confirm_extract|cancel_extract|restart_run|start_tutorial_run|start_standard_run|toggle_flag_cell|teleport_to_explored|confirm_tutorial_popup|flag_current_cell)\s*\(') {
    Add-Failure 'formal UI/debug path directly calls CommandBus action method instead of dispatch'
}
if ($RunSceneText -notmatch 'command_bus\.dispatch') {
    Add-Failure 'run_scene has no command_bus.dispatch usage'
}

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

$MutationBoundaryFiles = @(
    'scripts/core/run/event_service.gd',
    'scripts/core/run/combat_state.gd',
    'scripts/core/run/room_resolver.gd',
    'scripts/core/command/command_bus.gd',
    'scripts/core/run/run_query_facade.gd',
    'scripts/core/content/content_def_registry.gd'
)
foreach ($RelativePath in $MutationBoundaryFiles) {
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'asset_ledger\.(add_currency|spend_currency|add_reward_items|pickup_ground_item|drop_inventory_item|settle_success|settle_failure|sell_best_inventory_item|item_instances|currency_balances|room_floor_items)') {
        Add-Failure "non-ledger/effect path mutates asset ledger: $RelativePath"
    }
}

$NoWriteFiles = @(
    'scripts/core/command/command_bus.gd',
    'scripts/core/command/command_result.gd',
    'scripts/core/run/run_asset_ledger.gd',
    'scripts/core/run/run_asset_effect_handler.gd',
    'scripts/core/run/run_rule_service.gd',
    'scripts/core/run/run_rule_pipeline.gd',
    'scripts/core/run/run_modifier_spec.gd',
    'scripts/core/run/run_event_log.gd',
    'scripts/core/run/run_transaction_log.gd',
    'scripts/core/run/run_query_facade.gd',
    'scripts/core/run/run_context.gd',
    'scripts/core/content/content_def_registry.gd',
    'scripts/core/save/save_adapter.gd',
    'scripts/core/save/meta_progress_adapter.gd'
)
foreach ($RelativePath in $NoWriteFiles) {
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'FileAccess|ResourceSaver|DirAccess|user://|SettingsManager\.set_value') {
        Add-Failure "G8.2 kernel path contains persistence/write API: $RelativePath"
    }
}

$LuaPrototypeStatus = git -C $RepoRoot status --short -- lua-prototype-main 2>$null
if (-not [string]::IsNullOrWhiteSpace($LuaPrototypeStatus)) {
    Add-Failure "lua-prototype-main has local modifications: $LuaPrototypeStatus"
}

Test-RepoFileContains 'docs/branch_changes/G8_2_KERNEL_PROTOCOL_HARDENING_BRANCH.md' @('G8.2', 'Command envelope', 'RunEventLog', 'TransactionLog', 'ContentDef')
Test-RepoFileContains 'docs/audits/AUDIT_G8_2_KERNEL_PROTOCOL_HARDENING.md' @('Mutation Boundary', 'CommandResult', 'RulePipeline', 'ModifierSpec', 'ContentDef')
Test-RepoFileContains 'docs/handoff/HANDOFF_G8_2_KERNEL_PROTOCOL_HARDENING.md' @('UI', 'RulePipeline', 'ModifierSpec', 'EffectHandler', 'ContentDef', 'SaveAdapter')

if ($Failures.Count -gt 0) {
    Write-Output 'KERNEL_PROTOCOL_G8_2_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'KERNEL_PROTOCOL_G8_2_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'COMMAND_ENVELOPE_AND_RESULT=PASS'
Write-Output 'QUERY_VIEWMODEL_BOUNDARY=PASS'
Write-Output 'MUTATION_BOUNDARY=PASS'
Write-Output 'EVENT_LOG=PASS'
Write-Output 'EFFECT_TRANSACTION_CORRELATION=PASS'
Write-Output 'MODIFIER_RULEPIPELINE_CONTENTDEF=PASS'
Write-Output 'NO_PERSISTENCE_OR_ACTION_COMBAT=PASS'
