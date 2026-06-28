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

Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3r_item_usability_model.gd" "build_warehouse_lite|normalize_warehouse_items" "Warehouse Lite model reads warehouse_items"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3r_item_usability_model.gd" "build_codex_lite|discovered_entries|undiscovered_entries" "Codex Lite from warehouse_items"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3r_item_usability_model.gd" "build_default_loadout|selected_equipment|selected_consumables" "loadout derivation"
Test-FileContains "Godot/GraytailGodot/scripts/core/content/m3r_item_usability_model.gd" "talent_carry_rigging|talent_salvage_clause|talent_shock_training" "minimal talent hooks"
Test-FileContains "Godot/GraytailGodot/scripts/ui/warehouse_lite/warehouse_lite_model.gd" "WarehouseLiteModel|selected_equipment|selected_consumables" "Warehouse Lite UI model"
Test-FileContains "Godot/GraytailGodot/scripts/ui/codex_lite/codex_lite_model.gd" "CodexLiteModel|discovered_entries|undiscovered_entries" "Codex Lite UI model"
Test-FileContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd" "RunStartConfig|selected_equipment_items|selected_consumable_items|preview.*false" "DeployPrep real minimal RunStartConfig"
Test-FileContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd" "_warehouse_cards|_loadout_cards|MetaProgress warehouse_items" "DeployPrep dynamic Warehouse/Loadout cards"
Test-FileContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd" "preview_only.*false|payload_from_deploy_preview" "DeployPrep start route passes config"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_start_config.gd" "selected_equipment_items|selected_consumable_items|warehouse_lite|codex_lite" "RunStartConfig M3R fields"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_config.gd" "runtime_config_patch|selected_equipment_items|selected_consumable_items" "RunConfig consumes M3R loadout"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "_add_starting_loadout|carry_in_equipment|carry_in_consumable|failure_salvage_capacity" "carry-in equipment and consumables"
Test-FileContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" "equip_item|unequip_item|start_standard_run\(payload" "CommandBus authority commands"
Test-FileContains "Godot/GraytailGodot/scripts/core/save/meta_progress_adapter.gd" "_remove_carry_in_items|_upsert_warehouse_item|failure|warehouse_items" "MetaProgress settlement carry-in handling"
Test-FileContains "Godot/GraytailGodot/scripts/core/save/save_adapter.gd" "profile_level|permit_level|protocol_difficulty|talent_flags" "minimal profile/permit/protocol fields"
Test-FileContains "Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd" "CodexLiteModel|codex_lite_model|_codex_cards" "LongTerm Codex Lite consumer"
Test-FileContains "tools/godot_m3r_item_usability_completion_runner.gd" "M3R_ITEM_USABILITY_COMPLETION=PASS" "M3R headless runner"

Test-FileNotContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd" "does not start real exploration|preview only|preview-only|real_start" "old DeployPrep preview-only start wording"

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
    Write-Host "M3R item usability completion validation: FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M3R item usability completion validation: PASS"
Write-Host "Checked Warehouse Lite, Codex Lite, loadout, carry-in consumables, settlement preservation, minimal profile hooks, and forbidden metadata diff."
