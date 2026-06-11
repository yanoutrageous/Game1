$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot '..\..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$Failures = @()

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

Test-RepoFileContains 'docs/design/G9_UI_PRESENTATION_LAYERING_ARCHITECTURE.md' @(
    'Base Background Layer',
    'Theme Overlay Layer',
    'Scene Prop Overlay Layer',
    'Character Layer',
    'Character Overlay Layer',
    'Foreground FX Layer',
    'UI Panel Layer',
    'Popup / Tooltip Layer',
    'fixed base background plus independent overlay layers',
    'Command / CommandResult',
    'ViewModel/snapshot',
    'No real art import',
    'No full UI shell navigation'
)

$ContractNames = @(
    'ThemeProfile',
    'PresentationLayerEntry',
    'CharacterPresentationConfig',
    'OutfitPresentationDef',
    'PanelState',
    'UIVisibilityPolicy',
    'NavigationEntry',
    'ShortcutEntry',
    'ExpeditionSummaryViewModel',
    'LongTermSummaryViewModel'
)
Test-RepoFileContains 'docs/design/G9_UI_PRESENTATION_LAYERING_ARCHITECTURE.md' $ContractNames
Test-ProjectFileContains 'scripts/presentation/presentation_layer_contracts.gd' $ContractNames

$RequiredFields = @(
    'theme_id',
    'schema_version',
    'display_name_key',
    'base_background_id',
    'color_grade_id',
    'lighting_overlay_id',
    'ambient_vfx_ids',
    'prop_overlay_ids',
    'foreground_overlay_ids',
    'panel_skin_id',
    'map_icon_theme_id',
    'risk_overlay_policy',
    'fallback_theme_id',
    'layer_id',
    'fallback_asset_id',
    'z_index',
    'anchor',
    'offset',
    'scale',
    'opacity',
    'blend_mode',
    'tint',
    'parallax_factor',
    'visibility_condition',
    'interactive',
    'blocks_input',
    'occlusion_policy',
    'reduction_group',
    'character_id',
    'base_sprite_id',
    'portrait_id',
    'default_pose_id',
    'available_pose_ids',
    'outfit_overlay_ids',
    'equipment_overlay_ids',
    'status_overlay_ids',
    'fallback_character_id',
    'outfit_id',
    'overlay_asset_ids',
    'slot',
    'rarity',
    'unlock_condition',
    'compatible_pose_ids',
    'page_id',
    'panel_id',
    'expanded_state',
    'last_selected_tab',
    'compact_mode',
    'summary_mode',
    'remember_state',
    'animation_profile_id',
    'policy_id',
    'entry_id',
    'visible',
    'compact_allowed',
    'dev_only',
    'priority',
    'label_key',
    'icon_id',
    'page',
    'target_panel',
    'category',
    'is_primary',
    'is_visible',
    'sort_order',
    'shortcut_id',
    'source_page',
    'target_page',
    'is_pinned',
    'last_used_sequence',
    'loadout_items',
    'consumables',
    'capacity_current',
    'capacity_max',
    'run_effects',
    'risk_warnings',
    'blocked_reason',
    'tracked_objective',
    'recommended_route',
    'profile_level',
    'profile_exp',
    'next_reward',
    'permanent_bonus',
    'task_progress',
    'codex_progress',
    'achievement_progress',
    'research_progress',
    'deprecated_state',
    'tags'
)
Test-ProjectFileContains 'scripts/presentation/presentation_layer_contracts.gd' $RequiredFields

Test-RepoFileContains 'docs/handoff/HANDOFF_G9_UI_PRESENTATION_LAYERING_REVISION.md' @(
    'G9 UI Presentation Layering Revision',
    'Dispatch state-changing actions through CommandBus',
    'Read run state through ViewModel/snapshot data only',
    'Do not bake map theme',
    'validate_ui_presentation_layering_g9.ps1'
)

Test-RepoFileContains 'docs/audits/AUDIT_G9_UI_PRESENTATION_LAYERING_REVISION.md' @(
    'Layering Boundary',
    'Contract Boundary',
    'Protocol Boundary',
    'Art Boundary',
    'Validator Boundary',
    'new and modified content',
    'No full UI implementation'
)

Test-RepoFileContains 'docs/branch_changes/G9_UI_PRESENTATION_LAYERING_REVISION_BRANCH.md' @(
    'godot/g9-ui-presentation-layering-revision',
    'c5fa0622f98be5b8cb61eedefdfa9990027c00e7',
    'PresentationLayerContracts',
    'validate_ui_presentation_layering_g9.ps1',
    'No real art import'
)

Test-RepoFileContains 'docs/ui-layout-implementation-plan.md' @(
    'G9 Presentation Layering Correction',
    'stable base-space composition',
    'independent overlay layers',
    'Core gameplay should provide semantic ids and snapshots only'
)

Test-RepoFileContains 'docs/ENGINEERING_STATUS.md' @(
    'G9 UI Presentation Layering Revision',
    'godot/g9-ui-presentation-layering-revision',
    'PresentationLayerContracts',
    'validate_ui_presentation_layering_g9.ps1'
)

Test-ProjectFileContains 'docs/GODOT_CURRENT_STATUS.md' @(
    'G9 UI presentation layering revision',
    'PresentationLayerContracts',
    'fixed base background',
    'validate_ui_presentation_layering_g9.ps1'
)

Test-ProjectFileContains 'docs/GODOT_ARCHITECTURE_NOTES.md' @(
    'G9 Presentation Layering Boundary',
    'Base Background',
    'Theme Overlay',
    'Scene Prop Overlay',
    'Character Layer',
    'Foreground FX',
    'UI Panel',
    'Popup / Tooltip',
    'PresentationLayerContracts'
)

$ContractText = Read-ProjectText 'scripts/presentation/presentation_layer_contracts.gd'
$ForbiddenContractPatterns = @(
    'extends Node',
    'preload(',
    'load(',
    'FileAccess',
    'user://',
    'ResourceLoader',
    'ResourceSaver',
    'DirAccess',
    'Texture2D',
    'TextureRect',
    'Autoload'
)
foreach ($Pattern in $ForbiddenContractPatterns) {
    if ($ContractText.Contains($Pattern)) {
        Add-Failure "contract-only stub contains forbidden runtime/resource coupling: $Pattern"
    }
}

$ChangedFiles = @()
try {
    $ChangedFiles = @(git -C $RepoRoot diff --name-only main...HEAD)
} catch {
    Add-Failure "unable to compute changed file scope for G9 validator: $_"
}

foreach ($RelativePath in $ChangedFiles) {
    $NormalizedPath = $RelativePath -replace '/', '\'
    if ($NormalizedPath.StartsWith('Godot\GraytailGodot\scripts\core\') -and $NormalizedPath.EndsWith('.gd')) {
        $Text = Read-RepoText $RelativePath
        $DirectArtCouplingPattern = 'res://[^"''\s\)]*\.(png|jpg|jpeg|webp|svg|tga|bmp|hdr|exr)|Texture2D|TextureRect|resource_path\s*='
        if ($Text -match $DirectArtCouplingPattern) {
            Add-Failure "G9 changed core gameplay file introduces direct presentation asset coupling: $RelativePath"
        }
    }
}

$LuaPrototypeStatus = @(git -C $RepoRoot status --short -- lua-prototype-main)
if ($LuaPrototypeStatus.Count -gt 0) {
    Add-Failure "lua-prototype-main has local modifications"
}

if ($Failures.Count -gt 0) {
    Write-Output 'UI_PRESENTATION_LAYERING_G9_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'UI_PRESENTATION_LAYERING_G9_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'LAYER_STACK=PASS'
Write-Output 'PRESENTATION_CONTRACTS=PASS'
Write-Output 'CONTRACT_ONLY_STUB=PASS'
Write-Output 'SCOPED_CORE_ASSET_COUPLING_CHECK=PASS'
Write-Output 'NO_LUA_PROTOTYPE_MODIFICATION=PASS'
