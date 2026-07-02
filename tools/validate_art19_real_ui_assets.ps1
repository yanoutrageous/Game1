param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
    Write-Error $Message
    exit 1
}

$manifestPath = Join-Path $RepoRoot "Godot\GraytailGodot\data\assets\asset_manifest.csv"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    Fail "asset_manifest.csv missing"
}

$rows = Import-Csv -LiteralPath $manifestPath
$duplicates = $rows | Group-Object asset_id | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name
if ($duplicates.Count -gt 0) {
    Fail ("Duplicate asset_id detected: " + ($duplicates -join ", "))
}

$missing = @()
foreach ($row in $rows) {
    if ([string]::IsNullOrWhiteSpace($row.godot_path)) { continue }
    if ($row.replacement_needed -eq "true") { continue }
    $fsPath = $row.godot_path -replace "^res://", "Godot/GraytailGodot/"
    $fsPath = Join-Path $RepoRoot ($fsPath -replace "/", "\")
    if (-not (Test-Path -LiteralPath $fsPath)) {
        $missing += "$($row.asset_id) => $($row.godot_path)"
    }
}
if ($missing.Count -gt 0) {
    Fail ("Manifest godot_path missing: " + ($missing -join "; "))
}

$requiredArt19 = @(
    "ui.art19.panel.terminal_main",
    "ui.art19.panel.deploy_main",
    "ui.art19.panel.deploy_summary",
    "ui.art19.panel.frame_highlight",
    "ui.art19.button.dark",
    "ui.art19.button.confirm",
    "ui.art19.button.selected_tab",
    "ui.art19.bar.summary_dark",
    "ui.art19.scrollbar.vertical",
    "ui.art19.map64.player",
    "ui.art19.map64.unknown",
    "ui.art19.map64.explored",
    "ui.art19.map64.scanned",
    "ui.art19.map64.mine",
    "ui.art19.map64.chest",
    "ui.art19.map64.exit"
)

$assetIds = @{}
foreach ($row in $rows) { $assetIds[$row.asset_id] = $true }
foreach ($assetId in $requiredArt19) {
    if (-not $assetIds.ContainsKey($assetId)) {
        Fail "Missing ART19 asset_id: $assetId"
    }
}

$requiredFiles = @(
    "Godot\GraytailGodot\scripts\presentation\art09_manifest_asset_mapping.gd",
    "Godot\GraytailGodot\scripts\presentation\presentation_mapping.gd",
    "Godot\GraytailGodot\scripts\presentation\art10_ui_skin_kit.gd",
    "Godot\GraytailGodot\scripts\ui\main_menu\main_menu_shell.gd",
    "Godot\GraytailGodot\scripts\ui\deploy_prep\deploy_prep_shell.gd",
    "Godot\GraytailGodot\scripts\ui\long_term\long_term_shell.gd",
    "Godot\GraytailGodot\scripts\ui\run_surface\run_surface.gd",
    "Godot\GraytailGodot\scripts\ui\map_overlay\map_overlay_panel.gd",
    "docs\art\validation\art19\ART19_UI_ASSET_KIT_MAPPING.md",
    "docs\art\validation\art19\ART19_IMPORTED_ASSET_REPORT.md",
    "docs\art\ART19_REAL_UI_ART_KIT_AND_CORE_SCREEN_REPLACEMENT.md",
    "docs\art\validation\art19\ART19_SCREEN_REPLACEMENT_REPORT.md"
)
foreach ($path in $requiredFiles) {
    $full = Join-Path $RepoRoot $path
    if (-not (Test-Path -LiteralPath $full)) {
        Fail "Required ART19 file missing: $path"
    }
}

$requiredScreenshots = @(
    "docs\art\validation\art19\art19_main_menu_1280x720.png",
    "docs\art\validation\art19\art19_deploy_prep_1280x720.png",
    "docs\art\validation\art19\art19_long_term_1280x720.png",
    "docs\art\validation\art19\art19_run_hud_1280x720.png",
    "docs\art\validation\art19\art19_map_overlay_1280x720.png"
)
foreach ($path in $requiredScreenshots) {
    $full = Join-Path $RepoRoot $path
    if (-not (Test-Path -LiteralPath $full)) {
        Fail "Required ART19 screenshot missing: $path"
    }
}

$mappingFile = Join-Path $RepoRoot "Godot\GraytailGodot\scripts\presentation\art09_manifest_asset_mapping.gd"
$skinFile = Join-Path $RepoRoot "Godot\GraytailGodot\scripts\presentation\art10_ui_skin_kit.gd"
$presentationFile = Join-Path $RepoRoot "Godot\GraytailGodot\scripts\presentation\presentation_mapping.gd"
$mapOverlayFile = Join-Path $RepoRoot "Godot\GraytailGodot\scripts\ui\map_overlay\map_overlay_panel.gd"

if (-not (Select-String -LiteralPath $mappingFile -Pattern "art19_skin_ref" -Quiet)) {
    Fail "art19_skin_ref missing from Art09ManifestAssetMapping"
}
if (-not (Select-String -LiteralPath $presentationFile -Pattern "art19_skin_ref" -Quiet)) {
    Fail "PresentationMapping does not expose art19_skin_ref"
}
if (-not (Select-String -LiteralPath $skinFile -Pattern "StyleBoxTexture" -Quiet)) {
    Fail "Skin Kit does not use StyleBoxTexture"
}
if (-not (Select-String -LiteralPath $mapOverlayFile -Pattern "art19_map64_ref" -Quiet)) {
    Fail "MapOverlay does not use art19_map64_ref"
}

$scriptRoots = @(
    "Godot\GraytailGodot\scripts\presentation",
    "Godot\GraytailGodot\scripts\ui"
)
$hardcoded = @()
foreach ($root in $scriptRoots) {
    $fullRoot = Join-Path $RepoRoot $root
    if (-not (Test-Path -LiteralPath $fullRoot)) { continue }
    $matches = Get-ChildItem -LiteralPath $fullRoot -Recurse -File -Include *.gd |
        Select-String -Pattern "D:\\AGAME1\\sources\\art|D:\\AGAME1\\sources\\draw|D:\\AGAME1\\Base Art|D:\\AGAME1\\Draw"
    foreach ($match in $matches) {
        $hardcoded += "$($match.Path):$($match.LineNumber): $($match.Line.Trim())"
    }
}
if ($hardcoded.Count -gt 0) {
    Fail ("External runtime source hardcode found: " + ($hardcoded -join "; "))
}

$status = git -C $RepoRoot status --short
$forbiddenDirty = $status | Where-Object {
    $_ -match "Godot/GraytailGodot/scripts/core/command/" -or
    $_ -match "Godot/GraytailGodot/scripts/core/save/" -or
    $_ -match "D:/AGAME1/sources" -or
    $_ -match "D:\\AGAME1\\sources"
}
if ($forbiddenDirty.Count -gt 0) {
    Fail ("Forbidden dirty paths detected: " + ($forbiddenDirty -join "; "))
}

Write-Host "ART19 real UI assets validation passed."
Write-Host ("ART19 asset rows: " + ($rows | Where-Object { $_.asset_id -like "ui.art19.*" }).Count)
