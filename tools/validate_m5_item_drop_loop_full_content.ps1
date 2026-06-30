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
        return
    }
    $content = Get-Content -LiteralPath $fullPath -Raw
    if ($content -match $Pattern) {
        $failures.Add("forbidden evidence: $Label in $Path")
    }
}

Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "eq_old_vest|eq_edge_opener|eq_recovery_bag|eq_goggles|eq_signal_pin|eq_insulated_sleeve" "M5 six equipment ids"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "con_ration|con_med_patch|con_tape_roll|con_scan_pin|con_calm_candy|con_stabilizer" "M5 six consumable ids"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" 'names := \[|"col_%02d"|collectible_level' "M5 collectible generator"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "mon_old_gear_set|mon_broken_patrol_badge|mon_loader_black_box|mon_abnormal_instruction" "M5 monster exclusive drop ids"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "unique_concept_items|collectible_level.*7|ordinary_drop_allowed.*false|unique_drop_allowed.*false" "unique gacha-only locked concept"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/content/m3_item_catalog.gd" "mon_broken_patrol[^_]" "non-ascii monster drop item id"

Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "replace_ground_item_with_inventory_item|_replacement_drop_candidate_id|failure_salvage_capacity: int = 4" "capacity-based replacement and failure salvage"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" 'failure_salvage_capacity(: int)? = 1|failure_salvage_capacity.*get\([^)]*, 1\)' "default one-item failure salvage"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_effect_handler.gd" "EFFECT_REPLACE_GROUND_ITEM|asset.replace_ground_item" "asset effect replacement"
Test-FileContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" "replace_ground_item|RunRuleService.replace_ground_item" "CommandBus replacement route"
Test-FileContains "Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd" "replace_item_requested|GroundLootReplaceButton" "GroundLoot replacement UI action"

Test-FileContains "Godot/GraytailGodot/scripts/core/run/event_service.gd" "confirm_high_value_sale|buy_treatment|buy_info|ALTAR_HP_COSTS|altar_stage" "M5 trader and altar options"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_rule_service.gd" "execute_trader_treatment|execute_trader_info|heal_pressure_reduce|replace_ground_item" "M5 rule service coverage"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_balance_catalog.gd" "ALTAR_HP_COSTS|ALTAR_BLACK_COIN_REWARDS|TRADER_TREATMENT_COST|TRADER_INFO_COST" "M5 event balances"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3r_item_usability_model.gd" "unique_concept_items|BASE_FAILURE_SALVAGE_CAPACITY := 4|eq_recovery_bag|eq_signal_pin" "Warehouse/Codex/DeployPrep alignment"

Test-FileContains "tools/godot_m5_item_drop_loop_full_content_runner.gd" "M5_ITEM_DROP_LOOP_FULL_CONTENT=PASS" "M5 headless runner marker"
Test-FileContains "docs/20_product/M5_MINIMUM_ITEM_PACK_DROP_LOOP_FULL_CONTENT_CONTRACT.md" "M5|最小物品包|GroundLoot|unique" "M5 product contract"
Test-FileContains "docs/validation/M5_MINIMUM_ITEM_PACK_DROP_LOOP_FULL_CONTENT_VALIDATION.md" "M5|validate_m5_item_drop_loop_full_content|Godot headless" "M5 validation doc"
Test-FileContains "docs/handoff/HANDOFF_M5_MINIMUM_ITEM_PACK_DROP_LOOP_FULL_CONTENT.md" "M5|handoff|M6" "M5 handoff doc"

$forbiddenSpecs = @(
    "Godot/GraytailGodot/project.godot",
    ":(glob)Godot/GraytailGodot/**/*.tscn",
    ":(glob)Godot/GraytailGodot/**/*.tres",
    ":(glob)Godot/GraytailGodot/**/*.res",
    ":(glob)Godot/GraytailGodot/**/*.uid",
    ":(glob)Godot/GraytailGodot/**/*.translation",
    ":(glob)Godot/GraytailGodot/**/*.import"
)
$forbiddenDiff = git -C $RepoRoot diff --name-only -- $forbiddenSpecs
if ($forbiddenDiff) {
    foreach ($path in $forbiddenDiff) {
        $failures.Add("forbidden Godot metadata/project diff: $path")
    }
}

$untracked = git -C $RepoRoot ls-files --others --exclude-standard
foreach ($path in $untracked) {
    if ($path -match '^Godot/GraytailGodot/.*\.(tscn|tres|res|uid|translation|import)$') {
        $failures.Add("forbidden untracked Godot metadata/resource: $path")
    }
    if ($path -eq 'Godot/GraytailGodot/project.godot') {
        $failures.Add("forbidden untracked project file: $path")
    }
}

if ($failures.Count -gt 0) {
    Write-Host "M5 item drop loop full content validation: FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M5 item drop loop full content validation: PASS"
Write-Host "Checked M5 item pack, GroundLoot replacement, event branches, failure salvage, Warehouse/Codex alignment, docs, runner evidence, and metadata boundaries."
