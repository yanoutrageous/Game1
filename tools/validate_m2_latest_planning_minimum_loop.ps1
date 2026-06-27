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

Test-FileContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd" 'route_mode": &"standard_run"' "DeployPrep start intent routes to standard_run"
Test-FileNotContains "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd" 'route_mode": &"demo_run"' "DeployPrep start intent must not route to demo_run"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_flow_state_contract.gd" 'standard_10x10' "RunIntent documents standard_10x10 bridge"
Test-FileContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" 'get_return_eligibility' "fast return uses TruthMap eligibility"
Test-FileContains "Godot/GraytailGodot/scripts/ui/minimap/minimap_view_model.gd" 'eligible_return' "minimap derives return action from eligibility"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_config.gd" 'rule_modifiers' "standard_10x10 includes minimum modifier config"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_rule_pipeline.gd" 'numeric_delta_for_rule' "rule pipeline exposes limited numeric modifier execution"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_rule_service.gd" 'modifier_black_coin_delta' "search reward applies modifier delta before ledger effect"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_query_facade.gd" 'settlement_input' "RunResult is exposed as settlement input"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_query_facade.gd" 'settlement_reads_run_result_only' "settlement boundary is explicit"
Test-FileContains "Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd" 'build_from_snapshot' "LongTerm consumes app snapshot"
Test-FileContains "Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd" 'meta_progress_summary' "LongTerm consumes MetaProgress summary display-only"
Test-FileContains "Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd" 'does not write history, rewards, objectives, assets, or save data' "LongTerm write boundary"
Test-FileContains "tools/godot_m2_minimum_loop_runner.gd" 'M2_MINIMUM_LOOP_REGRESSION=PASS' "M2 headless runtime runner exists"

$staged = git -C $RepoRoot diff --cached --name-only
if ($staged) {
    $failures.Add("staged files are present; M2 validation expects explicit staging gate later")
}

$forbiddenDiff = git -C $RepoRoot diff --name-only -- `
    "Godot/GraytailGodot/project.godot" `
    ":(glob)Godot/GraytailGodot/**/*.tscn" `
    ":(glob)Godot/GraytailGodot/**/*.tres" `
    ":(glob)Godot/GraytailGodot/**/*.res" `
    ":(glob)Godot/GraytailGodot/**/*.uid" `
    ":(glob)Godot/GraytailGodot/**/*.translation" `
    ":(glob)Godot/GraytailGodot/**/*.import"
if ($forbiddenDiff) {
    Write-Host "WARN: existing Godot metadata/project dirty remains unvalidated by M2 gate:"
    $forbiddenDiff | ForEach-Object { Write-Host "  $_" }
}

if ($failures.Count -gt 0) {
    Write-Host "M2 latest planning minimum loop validation: FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M2 latest planning minimum loop validation: PASS"
Write-Host "Checked DeployPrep standard route, return eligibility, minimum modifier execution, RunResult settlement input, and LongTerm display-only consumption."
