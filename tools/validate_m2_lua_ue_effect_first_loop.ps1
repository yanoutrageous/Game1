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

Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_balance_catalog.gd" 'class_name RunBalanceCatalog' "balance catalog exists"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_content_catalog.gd" 'class_name RunContentCatalog' "content catalog exists"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_text_catalog.gd" 'class_name RunTextCatalog' "text catalog exists"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_effect_applier.gd" 'class_name RunEffectApplier' "effect applier exists"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_effect_applier.gd" 'EFFECT_HP_DELTA|hp_delta' "effect applier supports hp_delta"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_effect_applier.gd" 'EFFECT_PROTOCOL_PRESSURE_DELTA|protocol_pressure_delta' "effect applier supports protocol pressure"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_effect_applier.gd" 'EFFECT_RUN_FAIL|run_fail' "effect applier supports run_fail"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_effect_applier.gd" 'RunAssetEffectHandler\.apply_effects' "effect applier delegates asset effects to ledger handler"

Test-FileContains "Godot/GraytailGodot/scripts/core/run/combat_state.gd" 'RunEffectApplierScript\.apply_damage' "combat HP damage uses effect applier"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/event_service.gd" 'hp_delta' "events emit hp_delta"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/run/event_service.gd" 'context\.hp\s*-=' "events must not directly decrement hp"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/run/event_service.gd" 'ProtocolService\.add_pressure' "events must not directly add protocol pressure"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/room_resolver.gd" 'effect_protocol_pressure_delta' "room explore/mine pressure uses effect applier"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/room_resolver.gd" 'effect_mine_mark_triggered' "mine trigger mark uses effect applier"
Test-FileContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" 'RunEffectApplierScript\.effect_hp_delta\(hp_delta, "debug_heal_full"\)' "debug heal uses effect-first HP delta"
Test-FileNotContains "Godot/GraytailGodot/scripts/core/command/command_bus.gd" 'context\.hp\s*=\s*context\.max_hp' "debug heal must not directly set context hp"

Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_result_builder.gd" 'class_name RunResultBuilder' "run result builder exists"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_query_facade.gd" 'RunResultBuilderScript\.build' "query facade builds authoritative run result"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_query_facade.gd" 'SettlementInput' "query facade exposes SettlementInput"
Test-FileContains "Godot/GraytailGodot/scripts/core/run/run_query_facade.gd" 'settlement_reads_run_result_only' "settlement boundary is explicit"

Test-FileContains "Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd" 'meta_progress_summary' "LongTerm consumes MetaProgress summary"
Test-FileContains "Godot/GraytailGodot/scripts/ui/long_term/long_term_model.gd" 'does not write history, rewards, objectives, assets, or save data' "LongTerm write boundary"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" 'M2_LUA_UE_EFFECT_FIRST_LOOP=PASS' "M2 effect-first headless runner exists"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" '_validate_chest_reward_path' "M2 runner covers chest reward path"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" '_validate_ground_pickup_path' "M2 runner covers ground loot pickup path"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" '_validate_event_effect_path' "M2 runner covers event hp/pressure/gold/item path"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" '_validate_combat_reward_path' "M2 runner covers combat damage/reward path"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" '_validate_mine_effect_path' "M2 runner covers mine damage/pressure path"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" '_validate_extract_path' "M2 runner covers extract path"
Test-FileContains "tools/godot_m2_lua_ue_effect_first_runner.gd" '_validate_fail_path' "M2 runner covers fail path"

$forbiddenDiff = git -C $RepoRoot diff --name-only -- `
    "Godot/GraytailGodot/project.godot" `
    ":(glob)Godot/GraytailGodot/**/*.tscn" `
    ":(glob)Godot/GraytailGodot/**/*.tres" `
    ":(glob)Godot/GraytailGodot/**/*.res" `
    ":(glob)Godot/GraytailGodot/**/*.uid" `
    ":(glob)Godot/GraytailGodot/**/*.translation" `
    ":(glob)Godot/GraytailGodot/**/*.import"
if ($forbiddenDiff) {
    Write-Host "WARN: existing Godot metadata/project dirty remains outside M2 allowlist:"
    $forbiddenDiff | ForEach-Object { Write-Host "  $_" }
}

if ($failures.Count -gt 0) {
    Write-Host "M2 Lua/UE effect-first loop validation: FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "M2 Lua/UE effect-first loop validation: PASS"
Write-Host "Checked standard route, catalogs, effect applier, event/mine state effects, RunResult/SettlementInput, and LongTerm display-only boundary."
