$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot '..\..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$Failures = @()
$CurrentMainHead = 'a13a6fae3208850ae43e4b511511e008eb311a3e'

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

function Resolve-RepoPath {
    param([string]$RelativePath)
    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $RelativePath))
    if (-not ($FullPath -eq $RepoRoot -or $FullPath.StartsWith($RepoRoot + [System.IO.Path]::DirectorySeparatorChar))) {
        Add-Failure "outside repo: $RelativePath"
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

function Read-RepoText {
    param([string]$RelativePath)
    $FullPath = Resolve-RepoPath $RelativePath
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing: $RelativePath"
        return ''
    }
    return [System.IO.File]::ReadAllText($FullPath)
}

function Test-ProjectFileContains {
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

function Test-RepoFileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )
    $Text = Read-RepoText $RelativePath
    foreach ($Pattern in $Patterns) {
        if ($Text -notmatch [regex]::Escape($Pattern)) {
            Add-Failure "missing pattern in ${RelativePath}: $Pattern"
        }
    }
}

Test-RepoFileContains 'docs/bugs/G10_BASELINE_BUG_BACKLOG.md' @(
    'Raw Baseline Smoke',
    'Raw P1 Issues',
    'Resolved During G10',
    'Remaining After G10',
    $CurrentMainHead
)

Test-RepoFileContains 'docs/validation/G10_CLOSEOUT_VALIDATION_TRANSCRIPT.md' @(
    'G10 Closeout Validation Transcript',
    'Validation count: 13',
    'validate_g10_progress_art_smoke.ps1',
    'G10_PROGRESS_ART_SMOKE_VALIDATION=PASS',
    'Result: all 13 static validations PASS'
)

Test-ProjectFileContains 'scripts/core/run/run_scene.gd' @(
    'PauseSettingsOverlayPanel',
    'open_map_requested.connect',
    '_open_map_from_ui(&"minimap")',
    'return_main_requested.connect',
    'return_deploy_requested.connect',
    'BlockedReasonFlash',
    'DevDiagnosticsPanelScript',
    'G10ArtSmokeRegistry',
    'UILayoutProfileScript',
    'show_action_feedback',
    'DEV_DIAGNOSTICS_ENABLED',
    'command_bus.dispatch'
)

Test-ProjectFileContains 'scripts/ui/shell/g9_shell_panel.gd' @(
    'BUILD_CHANNEL',
    'DEV_DIAGNOSTICS_ENABLED',
    'DevDiagnosticsEntryButton',
    'dev_diagnostics_requested',
    'UIVisibilityPolicy',
    'DeployToLongTermButton'
)

Test-ProjectFileContains 'scripts/ui/dev/dev_diagnostics_panel.gd' @(
    'class_name DevDiagnosticsPanel',
    'DEV_ONLY_POLICY',
    '"visible": false',
    '"dev_only": true',
    '"unlock_condition": &"dev_channel"',
    'apply_diagnostics',
    'last_command'
)

Test-ProjectFileContains 'scripts/ui/result/result_panel.gd' @(
    'return_main_requested',
    'return_deploy_requested',
    'ResultReturnMainButton',
    'ResultReturnDeployButton',
    'apply_layout_profile',
    'create_tween'
)

Test-ProjectFileContains 'scripts/ui/map_overlay/map_overlay_panel.gd' @(
    'show_action_feedback',
    'show_open_feedback',
    'selected_feedback_text',
    'cell_action_requested'
)

Test-ProjectFileContains 'scripts/ui/minimap/minimap_panel.gd' @(
    'open_map_requested',
    '_gui_input',
    'MOUSE_BUTTON_LEFT',
    'MiniMapPanel click opens MapOverlay',
    'MOUSE_FILTER_IGNORE'
)

Test-ProjectFileContains 'scripts/ui/shell/ui_layout_profile.gd' @(
    'class_name UILayoutProfile',
    'PROFILE_DESKTOP',
    'PROFILE_NARROW',
    'profile_for_size',
    'touch_ready'
)

Test-ProjectFileContains 'scripts/presentation/presentation_layer_contracts.gd' @(
    'UILayoutProfile',
    'UI_LAYOUT_PROFILE_REQUIRED_FIELDS',
    'ui_layout_profile_example'
)

Test-ProjectFileContains 'scripts/presentation/g10_art_smoke_registry.gd' @(
    'class_name G10ArtSmokeRegistry',
    'manifest asset_ids only',
    'fallback_asset_id',
    'ui.hud.panel.left',
    'ui.common.button.dark',
    'ui.common.gold_icon',
    'sprite.player.default',
    'room.background.normal',
    'build_smoke_report'
)

Test-RepoFileContains 'docs/PROJECT_BASELINE.md' @(
    $CurrentMainHead,
    'G10 Progress & Art Smoke Foundation',
    'G10 adds bounded',
    'not represent complete MetaProgress',
    'Dirty handling whitelist'
)

Test-RepoFileContains 'docs/NEXT_HANDOFF.md' @(
    $CurrentMainHead,
    'godot/g10-progress-art-smoke-foundation',
    'not a new gameplay or full systems phase'
)

Test-RepoFileContains 'docs/MILESTONES.md' @(
    'G10',
    'Progress & Art Smoke Foundation',
    'a13a6fae3208850ae43e4b511511e008eb311a3e'
)

Test-RepoFileContains 'docs/ENGINEERING_STATUS.md' @(
    'G10 Progress & Art Smoke Foundation',
    'Implemented In G10',
    'validate_g10_progress_art_smoke.ps1'
)

Test-RepoFileContains 'Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md' @(
    'G10 Progress & Art Smoke Foundation',
    'UILayoutProfile',
    'validate_g10_progress_art_smoke.ps1'
)

Test-RepoFileContains 'docs/audits/AUDIT_G10_PROGRESS_ART_SMOKE_FOUNDATION.md' @(
    'G10 Progress & Art Smoke Foundation',
    'No complete MetaProgress',
    'Art smoke'
)

Test-RepoFileContains 'docs/handoff/HANDOFF_G10_PROGRESS_ART_SMOKE_FOUNDATION.md' @(
    'G10',
    'Progress & Art Smoke Foundation',
    'Explicitly Not Done'
)

Test-RepoFileContains 'docs/branch_changes/G10_PROGRESS_ART_SMOKE_FOUNDATION_BRANCH.md' @(
    'godot/g10-progress-art-smoke-foundation',
    'G10ArtSmokeRegistry',
    'UILayoutProfile'
)

Test-RepoFileContains 'Godot/GraytailGodot/docs/GODOT_G10_PROGRESS_ART_SMOKE_REPORT.md' @(
    'G10 Progress & Art Smoke',
    'no loose',
    'validate_g10_progress_art_smoke.ps1'
)

Test-RepoFileContains 'docs/design/G10_FUTURE_CONTENT_PLANNING.md' @(
    'Future Content Planning',
    'Do not add loose images',
    'complete MetaProgress remains a later phase'
)

$ArtRegistryText = Read-ProjectText 'scripts/presentation/g10_art_smoke_registry.gd'
if ($ArtRegistryText -match 'res://|\.png|\.jpg|\.jpeg|\.webp|\.ogg|\.wav|load\(|preload\(') {
    Add-Failure 'G10 art smoke registry directly references resources instead of manifest asset ids'
}

$ForbiddenUiFiles = @(
    'scripts/core/run/run_scene.gd',
    'scripts/ui/dev/dev_diagnostics_panel.gd',
    'scripts/ui/shell/ui_layout_profile.gd',
    'scripts/ui/inventory/inventory_panel.gd',
    'scripts/ui/ground_loot/ground_loot_panel.gd',
    'scripts/ui/result/result_panel.gd',
    'scripts/ui/map_overlay/map_overlay_panel.gd'
)

foreach ($RelativePath in $ForbiddenUiFiles) {
    $Text = Read-ProjectText $RelativePath
    if ($Text -match 'FileAccess|ResourceSaver|DirAccess|user://|DeployPersistence|ActionCombat|MetaProgress\.new') {
        Add-Failure "G10 UI/script contains forbidden persistence or out-of-scope implementation: $RelativePath"
    }
    if ($Text -match 'RunAssetLedger|asset_ledger\.|TruthMap|get_cell\(|get_room_type\(') {
        Add-Failure "G10 UI/script directly reads core private ledger or TruthMap state: $RelativePath"
    }
}

$DocFiles = @(
    'docs/PROJECT_BASELINE.md',
    'docs/NEXT_HANDOFF.md',
    'docs/DOCS_INDEX.md',
    'docs/ENGINEERING_STATUS.md',
    'Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md',
    'docs/audits/AUDIT_G10_PROGRESS_ART_SMOKE_FOUNDATION.md',
    'docs/handoff/HANDOFF_G10_PROGRESS_ART_SMOKE_FOUNDATION.md'
)

foreach ($RelativePath in $DocFiles) {
    $Text = Read-RepoText $RelativePath
    if ($Text -match 'complete MetaProgress is implemented|Deploy persistence is complete|complete long-term system is implemented|action combat is implemented|new gameplay is implemented|full art replacement is complete|complete mobile support') {
        Add-Failure "G10 doc claims out-of-scope completion: $RelativePath"
    }
}

$LuaPrototypeStatus = @(git -C $RepoRoot status --short -- lua-prototype-main)
if ($LuaPrototypeStatus.Count -gt 0) {
    Add-Failure 'lua-prototype-main has local modifications'
}

if ($Failures.Count -gt 0) {
    Write-Output 'G10_PROGRESS_ART_SMOKE_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'G10_PROGRESS_ART_SMOKE_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'G10_BUG_BACKLOG=PASS'
Write-Output 'UI_INTERACTION_FIXES=PASS'
Write-Output 'DEV_DIAGNOSTICS_GATE=PASS'
Write-Output 'ART_SMOKE_MANIFEST_FALLBACK=PASS'
Write-Output 'RESPONSIVE_RESERVATION=PASS'
Write-Output 'G10_DOCS=PASS'
Write-Output 'NO_OUT_OF_SCOPE_SYSTEMS=PASS'
Write-Output 'NO_LUA_PROTOTYPE_MODIFICATION=PASS'
