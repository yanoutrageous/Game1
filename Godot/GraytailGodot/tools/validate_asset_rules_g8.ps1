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

Test-FileContains 'scripts/core/run/run_asset_ledger.gd' @(
    'class_name RunAssetLedger',
    'const CURRENCY_BLACK := &"black_coin"',
    'const CURRENCY_GOLD := &"gold_coin"',
    'currency_definitions',
    'can_gain_in_run',
    'can_spend_in_run',
    'can_persist_to_meta',
    'settlement_rule',
    'instance_id',
    'item_id',
    'display_name',
    'item_type',
    'rarity',
    'weight',
    'value_state',
    'base_value',
    'tags',
    'source',
    'location_state',
    'room_pos',
    'LOCATION_INVENTORY',
    'LOCATION_EQUIPPED',
    'LOCATION_ROOM_FLOOR',
    'LOCATION_WAREHOUSE',
    'LOCATION_SETTLEMENT_POOL',
    'LOCATION_LOST',
    'room_floor_items',
    'func pickup_ground_item',
    'func drop_inventory_item',
    'blocked_capacity',
    'func equip_inventory_item',
    'func unequip_item',
    'can_consume',
    'status_effects',
    'duration_type',
    'remaining',
    'RARITY_TIERS',
    '&"unique"',
    'can_sell": false if unique_item',
    'func settle_success',
    'func settle_failure',
    'warehouse_lite',
    'sync_compat_fields'
)

Test-FileContains 'scripts/core/run/run_rule_service.gd' @(
    'class_name RunRuleService',
    'RuleResult',
    'func encounter_for_room',
    'encounter_type',
    'encounter_tags',
    'func apply_search_reward',
    'func apply_combat_reward',
    'func apply_event_rule_result',
    'func pickup_ground_item',
    'func drop_inventory_item',
    'func settle_success',
    'func settle_failure',
    'RunAssetLedger.LOCATION_INVENTORY',
    'RunAssetLedger.LOCATION_ROOM_FLOOR',
    'gold_coin_delta',
    'status_effects'
)

Test-FileContains 'scripts/core/run/run_context.gd' @(
    'var asset_ledger',
    'RunAssetLedger.new()',
    'RunRuleService.settle_success',
    'RunRuleService.settle_failure',
    '"black_coin"',
    '"gold_coin"',
    '"backpack_capacity"',
    '"backpack_used"',
    '"room_floor_items"',
    '"warehouse_lite"',
    '"settlement_log"',
    '"status_effects"',
    'encounter_type',
    'encounter_tags',
    'blocked_reason'
)

Test-FileContains 'scripts/core/command/command_bus.gd' @(
    '&"pickup_ground_item"',
    '&"drop_inventory_item"',
    'func pickup_ground_item',
    'func drop_inventory_item',
    'RunRuleService.pickup_ground_item',
    'RunRuleService.drop_inventory_item'
)

Test-FileContains 'scripts/core/run/event_service.gd' @(
    'RunRuleService.execute_trader_sell_best',
    'RunRuleService.execute_dice_bet',
    'RunRuleService.apply_event_rule_result',
    'black_coin_delta',
    'status_effects'
)

Test-FileContains 'scripts/ui/hud/hud_view_model.gd' @(
    'Black Coin:',
    'Gold Coin:',
    'Bag:',
    'Floor Items:',
    'Encounter:',
    'Blocked:'
)

Test-FileContains 'scripts/ui/result/result_panel.gd' @(
    'Black Coin:',
    'Gold Coin:',
    'Warehouse Lite Items:',
    'Room Floor Lost:',
    'Settlement Log Entries:'
)

Test-FileContains 'scripts/core/run/run_config.gd' @(
    '"backpack_capacity": 10',
    '"failure_salvage_capacity": 1',
    '"black_to_gold_rate": 1.0'
)

$AssetMutationFiles = @(
    'scripts/core/run/event_service.gd',
    'scripts/core/run/combat_state.gd',
    'scripts/core/run/room_resolver.gd'
)
foreach ($RelativePath in $AssetMutationFiles) {
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'context\.(pending_gold|safe_gold|parts|carried_items)\s*(\+|-)?=') {
        Add-Failure "rule file directly mutates legacy asset fields instead of ledger: $RelativePath"
    }
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

$NoPersistenceFiles = @(
    'scripts/core/run/run_asset_ledger.gd',
    'scripts/core/run/run_rule_service.gd',
    'scripts/core/run/run_context.gd',
    'scripts/core/command/command_bus.gd',
    'scripts/core/run/run_scene.gd',
    'scripts/ui/result/result_panel.gd'
)
foreach ($RelativePath in $NoPersistenceFiles) {
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'FileAccess|ResourceSaver|DirAccess|MetaProgress|user://|SettingsManager\.set_value') {
        Add-Failure "G8 rules path contains persistence/write API: $RelativePath"
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'ASSET_RULES_G8_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'ASSET_RULES_G8_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'LEDGER_CURRENCY_LOCATION=PASS'
Write-Output 'GROUND_LOOT_COMMANDS=PASS'
Write-Output 'INVENTORY_EQUIPMENT_CONSUMABLES_BUFFS=PASS'
Write-Output 'SETTLEMENT_WAREHOUSE_LITE=PASS'
Write-Output 'COMPAT_VIEWMODEL_BOUNDARY=PASS'
Write-Output 'NO_PERSISTENCE_API=PASS'
