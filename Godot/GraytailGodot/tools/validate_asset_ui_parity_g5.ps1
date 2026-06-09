$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
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

function Test-FileContains {
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )
    $FullPath = Resolve-ProjectPath $RelativePath
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

function Test-Exists {
    param([string]$RelativePath)
    $FullPath = Resolve-ProjectPath $RelativePath
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing: $RelativePath"
    }
}

$RequiredFiles = @(
    'scripts/core/content/asset_catalog.gd',
    'scripts/core/content/content_db.gd',
    'scripts/presentation/presentation_mapping.gd',
    'scripts/presentation/presentation_theme.gd',
    'scripts/ui/map_overlay/map_overlay_panel.gd',
    'scenes/ui/map_overlay/map_overlay_panel.tscn',
    'scripts/ui/tutorial/tutorial_popup_panel.gd',
    'scenes/ui/tutorial/tutorial_popup_panel.tscn',
    'scripts/ui/hud/hud.gd',
    'scripts/ui/hud/hud_view_model.gd',
    'scripts/ui/minimap/minimap_panel.gd',
    'scripts/ui/minimap/minimap_view_model.gd',
    'scripts/ui/result/result_panel.gd'
)
foreach ($RelativePath in $RequiredFiles) {
    Test-Exists $RelativePath
}

Test-FileContains 'scripts/core/content/content_db.gd' @('var asset_catalog := AssetCatalog.new()', 'asset_catalog.load_from_manifest', 'func get_asset_ref')
Test-FileContains 'scripts/core/content/asset_catalog.gd' @('class_name AssetCatalog', 'func load_from_manifest', 'func get_asset_ref', 'func validate_manifest_contract')
Test-FileContains 'scripts/presentation/presentation_mapping.gd' @('class_name PresentationMapping', 'func minimap_marker_from_cell', 'func room_visual_from_snapshot', 'func hint_for_snapshot')
Test-FileContains 'scripts/presentation/presentation_theme.gd' @('class_name PresentationTheme', 'func color_for_key', 'func risk_key')
Test-FileContains 'scripts/core/intel/intel_map.gd' @('PresentationMapping assigns asset ids', 'func build_public_cell', '"state": &"hidden"', 'random_exit', 'exit_id')
Test-FileContains 'scripts/ui/minimap/minimap_view_model.gd' @('PresentationMapping.minimap_marker_from_cell', 'intel_map.get_visible_map')
Test-FileContains 'scripts/core/run/run_scene.gd' @('MapOverlayScene', 'TutorialPopupScene', 'Start Tutorial 5x5', 'Start Standard 10x10', 'Controls: W/A/S/D or arrows move')

$ManifestPath = Resolve-ProjectPath 'data/assets/asset_manifest.csv'
if ([System.IO.File]::Exists($ManifestPath)) {
    $Rows = Import-Csv -LiteralPath $ManifestPath
    $HeaderLine = [System.IO.File]::ReadLines($ManifestPath) | Select-Object -First 1
    foreach ($Column in @('asset_id', 'godot_path', 'usage')) {
        if ($HeaderLine -notmatch "(^|,)$Column(,|$)") {
            Add-Failure "manifest missing compatible column: $Column"
        }
    }

    $Seen = @{}
    foreach ($Row in $Rows) {
        $AssetId = [string]$Row.asset_id
        if ([string]::IsNullOrWhiteSpace($AssetId)) {
            Add-Failure 'manifest row with empty asset_id'
            continue
        }
        if ($AssetId -notmatch '^[a-z0-9]+(\.[a-z0-9_]+)+$') {
            Add-Failure "asset_id is not lower dot notation: $AssetId"
        }
        if ($Seen.ContainsKey($AssetId)) {
            Add-Failure "duplicate asset_id: $AssetId"
        }
        $Seen[$AssetId] = $true

        $GodotPath = [string]$Row.godot_path
        $ReplacementNeeded = ([string]$Row.replacement_needed).ToLowerInvariant() -eq 'true'
        if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
            if (-not $GodotPath.StartsWith('res://assets/')) {
                Add-Failure "godot_path must use res://assets/: $AssetId -> $GodotPath"
            }
            $RelativeAssetPath = $GodotPath.Substring('res://'.Length).Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $PhysicalPath = Resolve-ProjectPath $RelativeAssetPath
            if (-not [System.IO.File]::Exists($PhysicalPath)) {
                Add-Failure "manifest asset file missing: $AssetId -> $GodotPath"
            }
        } elseif (-not $ReplacementNeeded) {
            Add-Failure "manifest empty godot_path must be replacement_needed=true: $AssetId"
        }
    }
} else {
    Add-Failure 'missing manifest: data/assets/asset_manifest.csv'
}

$CoreRuleFiles = @(
    'scripts/core/map/truth_map.gd',
    'scripts/core/intel/intel_map.gd',
    'scripts/core/run/run_context.gd',
    'scripts/core/command/command_bus.gd',
    'scripts/core/run/room_resolver.gd',
    'scripts/core/map/minefield_service.gd',
    'scripts/core/run/run_config.gd',
    'scripts/core/run/protocol_service.gd',
    'scripts/core/run/combat_state.gd',
    'scripts/core/run/run_inventory.gd',
    'scripts/core/run/tutorial_service.gd'
)
$CoreForbiddenPattern = 'Texture2D|TextureRect|res://assets|\.png|\.ogg|\.wav|load\(|preload\('
foreach ($RelativePath in $CoreRuleFiles) {
    $FullPath = Resolve-ProjectPath $RelativePath
    if (-not [System.IO.File]::Exists($FullPath)) {
        Add-Failure "missing core rule file: $RelativePath"
        continue
    }
    $Text = [System.IO.File]::ReadAllText($FullPath)
    if ($Text -match $CoreForbiddenPattern) {
        Add-Failure "core rule file contains direct asset/UI resource reference: $RelativePath"
    }
}

$UiFiles = @(
    'scripts/ui/hud/hud.gd',
    'scripts/ui/hud/hud_view_model.gd',
    'scripts/ui/minimap/minimap_panel.gd',
    'scripts/ui/minimap/minimap_view_model.gd',
    'scripts/ui/map_overlay/map_overlay_panel.gd',
    'scripts/ui/tutorial/tutorial_popup_panel.gd',
    'scripts/ui/result/result_panel.gd'
)
foreach ($RelativePath in $UiFiles) {
    $FullPath = Resolve-ProjectPath $RelativePath
    if ([System.IO.File]::Exists($FullPath)) {
        $Text = [System.IO.File]::ReadAllText($FullPath)
        if ($Text -match 'truth_map\.|TruthMap\.new|get_room_type\(|get_cell\(') {
            Add-Failure "UI script directly reads TruthMap: $RelativePath"
        }
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'ASSET_UI_PARITY_G5_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'ASSET_UI_PARITY_G5_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output 'MANIFEST_COMPATIBLE=PASS'
Write-Output 'ASSET_CATALOG_PRESENTATION_BOUNDARY=PASS'
Write-Output 'CORE_RULE_ASSET_BOUNDARY=PASS'
Write-Output 'UI_TRUTHMAP_BOUNDARY=PASS'
