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

Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "equipment_requires_extraction_registration" "in-run equipment registration block"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "registered_for_run|acquired_in_run|equip_allowed_now" "equipment registration flags"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd" "currency_semantics|long_term_gold|safe_yield" "currency semantic separation"
Test-FileContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" "context\.asset_ledger\.equip_inventory_item\(instance_id\)" "CommandBus delegates equip_item to ledger"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" "location_state.*LOCATION_EQUIPPED|LOCATION_EQUIPPED.*location_state|context\.carried_items.*equip" "CommandBus equip bypass"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_flow_state_contract.gd" "settle_abandon|pending_undecided|strong-confirm" "abandon settlement branch preview"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/run/run_flow_state_contract.gd" "no real abandon settlement|settlement_runtime_not_connected" "outdated abandon wording"
Test-FileContains "tools/godot_m3h_item_loop_hardening_runner.gd" "M3H_ITEM_LOOP_HARDENING=PASS" "M3H headless runner pass marker"
Test-FileContains "tools/godot_m3h_item_loop_hardening_runner.gd" "equipment_requires_extraction_registration|settle_abandon|pending_undecided" "M3H runner scenario coverage"
Test-FileContains "docs/20_product/M3H_ITEM_LOOP_HARDENING_CONTRACT.md" "M3H|equipment_requires_extraction_registration|safe_yield" "M3H product contract"
Test-FileContains "docs/validation/M3H_ITEM_LOOP_HARDENING_VALIDATION.md" "M3H|Godot headless|validate_m3h_item_loop_hardening" "M3H validation doc"
Test-FileContains "docs/handoff/HANDOFF_M3H_ITEM_LOOP_HARDENING.md" "M3H|handoff|G38" "M3H handoff doc"

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
    Write-Host "M3H item loop hardening validation: FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M3H item loop hardening validation: PASS"
Write-Host "Checked in-run equipment registration, carry-in boundaries, abandon settlement semantics, currency naming, runner/docs evidence, and forbidden metadata diff."
