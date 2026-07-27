$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot '..\..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$Failures = @()

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
}

function Test-FileContains {
    param(
        [string]$BasePath,
        [string]$RelativePath,
        [string[]]$Patterns
    )

    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $BasePath $RelativePath))
    if (-not ($FullPath -eq $BasePath -or $FullPath.StartsWith($BasePath + [System.IO.Path]::DirectorySeparatorChar))) {
        Add-Failure "outside base path: $RelativePath"
        return
    }
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing: $RelativePath"
        return
    }

    $Text = [System.IO.File]::ReadAllText($FullPath)
    foreach ($Pattern in $Patterns) {
        if ($Text -notmatch [regex]::Escape($Pattern)) {
            Add-Failure "missing pattern in ${RelativePath}: $Pattern"
        }
    }
}

Test-FileContains $ProjectRoot 'scripts/core/run/run_scene.gd' @(
    'ModeEntryPanel',
    '_show_deploy_shell',
    'deploy_shell_panel.call("_on_primary_action_pressed")',
    '_start_run_from_route',
    'command_bus.dispatch(command_name, payload)'
)

Test-FileContains $ProjectRoot 'scripts/core/content/m7_content_catalog.gd' @(
    '"tutorial_5x5"',
    '"classic_7x7_simple"'
)

Test-FileContains $ProjectRoot 'scripts/ui/deploy_prep/deploy_map_projection.gd' @(
    'map_id == "tutorial_5x5"',
    'const SCALE_IDS := [&"5x5", &"7x7", &"10x10", &"13x13"]'
)

Test-FileContains $ProjectRoot 'scripts/core/command/command_bus.gd' @(
    'context.current_room_type == &"Exit"',
    'request_extract()',
    'confirm_extract()',
    'move_by(command_payload.get("delta", Vector2i.ZERO))',
    'fight_current_enemy()'
)

Test-FileContains $ProjectRoot 'scripts/core/run/room_resolver.gd' @(
    '&"Normal":',
    'return search_current_room(context)',
    'Event placeholder resolved',
    'Monster cleared',
    'Mine triggered'
)

Test-FileContains $ProjectRoot 'scripts/ui/hud/hud_view_model.gd' @(
    'HP:',
    'Power:',
    'Pressure:',
    'Position:',
    'Room:',
    'Adjacent Mines:',
    'Enemy/Event/Exit Hint:'
)

Test-FileContains $ProjectRoot 'scripts/ui/minimap/minimap_panel.gd' @(
    'MiniMap: icons fallback to text',
    'GridContainer',
    'ContentDB.get_placeholder_label'
)

Test-FileContains $ProjectRoot 'scripts/ui/result/result_panel.gd' @(
    'Outcome:',
    'Mode:',
    'Moves:',
    'Mine Hits:',
    'Monsters Defeated:'
)

Test-FileContains $ProjectRoot 'docs/MANUAL_PLAYTEST_GUIDE.md' @(
    'Start Tutorial 5x5',
    'Start Standard 10x10',
    'Tutorial recommended route',
    'Standard smoke route',
    'Known limits'
)

Test-FileContains $ProjectRoot 'docs/GODOT_PLAYABLE_GRAYBOX_V0_1_REPORT.md' @(
    'Headless editor',
    'Runtime smoke',
    'Tutorial manual start',
    'Standard manual start',
    'No real art assets'
)

Test-FileContains $RepoRoot 'docs/HANDOFF_TWO_PC_GODOT_PLAYABLE_GRAYBOX.md' @(
    'godot/lua-parity-p0',
    'Godot playable graybox v0.1',
    'Do not start the next stage automatically'
)

if ($Failures.Count -gt 0) {
    Write-Output 'PLAYABLE_GRAYBOX_V0_1_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'PLAYABLE_GRAYBOX_V0_1_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'TUTORIAL_DEPLOY_MAP_ROUTE=PASS'
Write-Output 'STANDARD_DEPLOY_ROUTE=PASS'
Write-Output 'HUD_MINIMAP_RESULT_READABLE=PASS'
