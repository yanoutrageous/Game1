param(
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Test-FileContains {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Label
    )
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        $failures.Add("missing file: $Path")
        return
    }
    $content = Get-Content -LiteralPath $fullPath -Raw
    if ($content -notmatch $Pattern) {
        $failures.Add("missing evidence: $Label in $Path")
    }
}

function Test-FileNotContains {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Label
    )
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        $failures.Add("missing file: $Path")
        return
    }
    $content = Get-Content -LiteralPath $fullPath -Raw
    if ($content -match $Pattern) {
        $failures.Add("forbidden evidence: $Label in $Path")
    }
}

Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "class_name M3ItemCatalog" "M3 item catalog"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "TYPE_EQUIPMENT|equipment_items" "equipment item group"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "TYPE_CONSUMABLE|consumable_items" "consumable item group"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "collectible_items" "collectible item group"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "monster_drop_items" "monster drop item group"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "unique_drop_allowed.*false" "ordinary unique drop guard"

Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_content_catalog.gd" "M3ItemCatalog" "RunContentCatalog consumes M3 item catalog"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_rule_service.gd" "LOCATION_ROOM_FLOOR" "rewards default to GroundLoot"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_rule_service.gd" "use_consumable" "consumable use service"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_rule_service.gd" "safe_yield_delta" "trader safe_yield output"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "consume_inventory_item" "consumable inventory consumption"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "settle_abandon" "abandon settlement boundary"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "CURRENCY_LONG_TERM_GOLD" "long-term gold layer"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "safe_yield_state" "abandon safe_yield decision state"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "consumables_cleared|consume.*cleared" "old consumable clearing policy"

Test-FileContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" "use_consumable|use_item" "use item command"
Test-FileContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" "abandon_run" "abandon command"
Test-FileContains "Godot/GraytailGodot/scripts/core/save/meta_progress_adapter.gd" "long_term_gold|abandon_count" "MetaProgress summary alignment"
Test-FileContains "Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd" "use_item_requested" "inventory use item UI intent"
Test-FileContains "Godot/GraytailGodot/scripts/ui/shell/run_ui_view_model.gd" "run_black_coin|safe_yield|long_term_gold|GroundLoot" "income layer display text"
Test-FileContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_tab_model.gd" "salvage candidate" "DeployPrep consumable settlement wording"
Test-FileContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd" "salvage candidate" "DeployConfig consumable settlement wording"

Test-FileContains "tools/godot_m3_minimum_item_drop_loop_runner.gd" "M3_MINIMUM_ITEM_DROP_LOOP=PASS" "M3 headless runner"
Test-FileContains "tools/godot_m3_minimum_item_drop_loop_runner.gd" "_validate_ground_loot_and_inventory_loop" "GroundLoot pickup/drop validation"
Test-FileContains "tools/godot_m3_minimum_item_drop_loop_runner.gd" "_validate_consumable_use" "consumable use validation"
Test-FileContains "tools/godot_m3_minimum_item_drop_loop_runner.gd" "_validate_success_settlement" "success settlement validation"
Test-FileContains "tools/godot_m3_minimum_item_drop_loop_runner.gd" "_validate_failure_settlement" "failure settlement validation"
Test-FileContains "tools/godot_m3_minimum_item_drop_loop_runner.gd" "_validate_abandon_settlement" "abandon settlement validation"

$forbiddenDiff = git -C $RepoRoot diff --name-only -- `
    "Godot/GraytailGodot/project.godot" `
    ":(glob)Godot/GraytailGodot/**/*.tscn" `
    ":(glob)Godot/GraytailGodot/**/*.tres" `
    ":(glob)Godot/GraytailGodot/**/*.res" `
    ":(glob)Godot/GraytailGodot/**/*.uid" `
    ":(glob)Godot/GraytailGodot/**/*.translation" `
    ":(glob)Godot/GraytailGodot/**/*.import"
if ($forbiddenDiff) {
    foreach ($path in $forbiddenDiff) {
        $failures.Add("forbidden Godot metadata/project diff: $path")
    }
}

if ($failures.Count -gt 0) {
    Write-Host "M3 minimum item drop loop validation: FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M3 minimum item drop loop validation: PASS"
Write-Host "Checked M3 item catalog, GroundLoot-first rewards, consumable use, income layers, settlement boundaries, UI wording, and M3 headless runner evidence."
