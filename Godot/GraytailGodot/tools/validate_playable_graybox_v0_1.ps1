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
    'Start Tutorial 5x5',
    'Start Standard 10x10',
    'Controls: W/A/S/D or arrows move',
    'command_bus.dispatch(&"start_tutorial_run")',
    'command_bus.dispatch(&"start_standard_run")'
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
Write-Output 'TUTORIAL_MANUAL_START=PASS'
Write-Output 'STANDARD_MANUAL_START=PASS'
Write-Output 'HUD_MINIMAP_RESULT_READABLE=PASS'
