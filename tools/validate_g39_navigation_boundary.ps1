param(
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Read-RepoFile([string]$Path) {
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        $failures.Add("missing file: $Path")
        return ""
    }
    return Get-Content -LiteralPath $fullPath -Raw
}

function Require-Text([string]$Name, [string]$Content, [string]$Pattern) {
    if ($Content -notmatch $Pattern) {
        $failures.Add("$Name missing pattern: $Pattern")
    }
}

function Forbid-Text([string]$Name, [string]$Content, [string]$Pattern) {
    if ($Content -match $Pattern) {
        $failures.Add("$Name contains forbidden pattern: $Pattern")
    }
}

$appShell = Read-RepoFile "Godot/GraytailGodot/scripts/ui/app_shell/app_shell.gd"
$navigationIntent = Read-RepoFile "Godot/GraytailGodot/scripts/ui/app_shell/navigation_intent.gd"
$pageRouter = Read-RepoFile "Godot/GraytailGodot/scripts/ui/app_shell/page_router.gd"
$mainMenu = Read-RepoFile "Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd"
$deployShell = Read-RepoFile "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd"
$longTermShell = Read-RepoFile "Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd"
$runScene = Read-RepoFile "Godot/GraytailGodot/scripts/core/run/run_scene.gd"
$commandBus = Read-RepoFile "Godot/GraytailGodot/scripts/core/command/command_bus.gd"
$resultPanel = Read-RepoFile "Godot/GraytailGodot/scripts/ui/result/result_panel.gd"

Require-Text "NavigationIntent targets main" $navigationIntent 'TARGET_MAIN_MENU'
Require-Text "NavigationIntent targets deploy" $navigationIntent 'TARGET_DEPLOY'
Require-Text "NavigationIntent targets long term" $navigationIntent 'TARGET_LONG_TERM'
Require-Text "NavigationIntent targets run" $navigationIntent 'TARGET_RUN'
Require-Text "PageRouter deploy route" $pageRouter 'TARGET_DEPLOY'
Require-Text "PageRouter long term route" $pageRouter 'TARGET_LONG_TERM'
Require-Text "PageRouter run route" $pageRouter 'TARGET_RUN'

Require-Text "MainMenu emits navigation intent" $mainMenu 'navigation_intent_requested\.emit'
Require-Text "AppShell connects main menu navigation" $appShell 'main_menu_shell\.connect\("navigation_intent_requested"'
Require-Text "AppShell connects deploy navigation" $appShell 'deploy_page\.connect\("navigation_intent_requested"'
Require-Text "AppShell connects long term navigation" $appShell 'long_term_page\.connect\("navigation_intent_requested"'
Require-Text "AppShell uses PageRouter" $appShell 'PageRouterScript\.route_for_intent'
Require-Text "AppShell emits host route for run" $appShell 'host_route_requested\.emit\(intent\)'
Require-Text "DeployPrep exposes navigation intent" $deployShell 'signal navigation_intent_requested'
Require-Text "DeployPrep returns main through intent" $deployShell 'TARGET_MAIN_MENU'
Require-Text "DeployPrep routes long term through intent" $deployShell 'make_long_term'
Require-Text "DeployPrep start run intent" $deployShell 'deploy_start_intent_requested\.emit'
Forbid-Text "DeployPrep direct parent page route" $deployShell 'get_parent\(\).*show_(main|deploy|long_term)'
Require-Text "LongTerm exposes navigation intent" $longTermShell 'signal navigation_intent_requested'
Require-Text "LongTerm returns main through intent" $longTermShell 'TARGET_MAIN_MENU'
Require-Text "LongTerm routes deploy through intent" $longTermShell 'make_deploy'
Forbid-Text "LongTerm direct parent page route" $longTermShell 'get_parent\(\).*show_(main|deploy|long_term)'

Require-Text "RunScene pause continue" $runScene '_continue_from_pause'
Require-Text "RunScene pause deploy return guard" $runScene '_return_from_pause_to_deploy'
Require-Text "RunScene pause main return guard" $runScene '_return_from_pause_to_main'
Require-Text "RunScene pause abandon confirm" $runScene 'pause_exit_confirm_pending'
Require-Text "RunScene abandon through CommandBus" $runScene '_dispatch_command\(&"abandon_run"'
Require-Text "CommandBus abandon route exists" $commandBus 'func abandon_run'
Require-Text "RunScene result return main" $runScene '_return_from_result_to_main'
Require-Text "RunScene result return deploy" $runScene '_return_from_result_to_deploy'
Require-Text "ResultPanel return main signal" $resultPanel 'return_main_requested'
Require-Text "ResultPanel return deploy signal" $resultPanel 'return_deploy_requested'
Require-Text "RunScene closes map overlay" $runScene 'map_overlay_panel\.hide_overlay'
Require-Text "RunScene result Esc route" $runScene '_return_from_result_to_deploy'
Require-Text "RunScene releases focus after modal close" $runScene 'gui_release_focus'

$staged = (& git -C $RepoRoot diff --cached --name-only) -split "`r?`n" | Where-Object { $_ -ne "" }
$forbiddenStaged = $staged | Where-Object {
    $isG39VisibleEvidence = $_ -match '^docs/validation/g39/[^/]+\.png$'
    if ($isG39VisibleEvidence) {
        return $false
    }
    $_ -match '^docs/art/' -or
    $_ -match '^Godot/GraytailGodot/project\.godot$' -or
    $_ -match '^Godot/GraytailGodot/assets/' -or
    $_ -match '^Godot/GraytailGodot/data/assets/asset_manifest' -or
    $_ -match '\.(tscn|tres|res|uid|translation|import|png|jpg|jpeg|webp)$'
}
if ($forbiddenStaged.Count -gt 0) {
    $failures.Add("forbidden staged paths: $($forbiddenStaged -join ', ')")
}

if ($failures.Count -gt 0) {
    Write-Host "G39 navigation boundary validation: FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "G39 navigation boundary validation: PASS"
Write-Host "Checked AppShell/PageRouter route ownership, critical page routes, pause abandon authority, result return routes, modal close priority, and staged forbidden-path exclusion."
