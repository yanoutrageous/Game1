$ErrorActionPreference = "Stop"

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$godotRoot = Join-Path $repoRoot "Godot\GraytailGodot"
$art20Root = "D:\AGAME1\sources\art\ART-20"
$art20ManifestRoot = Join-Path $art20Root "_manifest"
$runtimeRoot = Join-Path $godotRoot "assets\ui\art20"
$assetManifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$mappingPath = Join-Path $godotRoot "scripts\presentation\art09_manifest_asset_mapping.gd"
$validationRoot = Join-Path $repoRoot "docs\art\validation\art20"
$finalDocPath = Join-Path $repoRoot "docs\art\ART20_DRAW_TO_RUNTIME_UI_COMPONENT_PIPELINE_EXECUTION.md"

$requiredFiles = @(
    (Join-Path $art20ManifestRoot "staging_manifest.csv"),
    (Join-Path $art20ManifestRoot "cut_manifest.csv"),
    (Join-Path $art20ManifestRoot "cut_blocked_or_review.csv"),
    (Join-Path $art20ManifestRoot "cut_summary.json"),
    (Join-Path $validationRoot "ART20_SLICE1_STAGING_REPORT.md"),
    (Join-Path $validationRoot "ART20_SLICE3_P0_COMPONENT_CUT_REPORT.md"),
    (Join-Path $validationRoot "ART20_SLICE4_RUNTIME_IMPORT_REPORT.md"),
    (Join-Path $validationRoot "ART20_SLICE5_CORE_SCREEN_REPLACEMENT_REPORT.md"),
    $finalDocPath,
    $assetManifestPath,
    $mappingPath
)

foreach ($file in $requiredFiles) {
    Assert-Condition (Test-Path -LiteralPath $file -PathType Leaf) "Missing required file: $file"
}

$requiredScreenshots = @(
    "art20_slice6_main_menu_final.jpg",
    "art20_slice6_deploy_prep_final.jpg",
    "art20_slice6_deploy_before_run_final.jpg",
    "art20_slice6_long_term_final.jpg",
    "art20_slice6_run_hud_final.jpg",
    "art20_slice6_map_overlay_final.jpg",
    "art20_slice6_inventory_final.jpg"
)

foreach ($name in $requiredScreenshots) {
    $path = Join-Path $validationRoot $name
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing Slice 6 screenshot: $path"
}

$stagingRows = Import-Csv -LiteralPath (Join-Path $art20ManifestRoot "staging_manifest.csv")
$cutRows = Import-Csv -LiteralPath (Join-Path $art20ManifestRoot "cut_manifest.csv")
$blockedRows = Import-Csv -LiteralPath (Join-Path $art20ManifestRoot "cut_blocked_or_review.csv")
$manifestRows = Import-Csv -LiteralPath $assetManifestPath
$art20Rows = @($manifestRows | Where-Object { $_.asset_id -like "ui.art20.*" })

Assert-Condition ($stagingRows.Count -gt 0) "ART20 staging manifest has no rows."
Assert-Condition ($cutRows.Count -eq 54) "Expected 54 ART20 cut manifest rows, got $($cutRows.Count)."
Assert-Condition ($blockedRows.Count -eq 5) "Expected 5 ART20 blocked rows, got $($blockedRows.Count)."
Assert-Condition ($art20Rows.Count -eq 15) "Expected 15 ART20 runtime manifest rows, got $($art20Rows.Count)."

$duplicateAssetIds = @($manifestRows | Group-Object asset_id | Where-Object { $_.Name -and $_.Count -gt 1 })
Assert-Condition ($duplicateAssetIds.Count -eq 0) ("Duplicate asset_id values found: " + (($duplicateAssetIds | Select-Object -ExpandProperty Name) -join ", "))

$expectedVisualKeys = @(
    "shared.keycap.e.normal",
    "shared.keycap.esc.normal",
    "shared.keycap.f.normal",
    "shared.keycap.m.normal",
    "shared.keycap.q.normal",
    "shared.keycap.t.normal",
    "main_menu.background.base_hall",
    "deploy.icon.medkit",
    "deploy.icon.syringe",
    "deploy.icon.flashlight",
    "deploy.icon.goggles",
    "deploy.icon.armor",
    "deploy.icon.backpack",
    "deploy.icon.bandage",
    "deploy.icon.compass"
)

$actualVisualKeys = @($art20Rows | ForEach-Object { $_.linked_data })
$missingVisualKeys = @($expectedVisualKeys | Where-Object { $_ -notin $actualVisualKeys })
$extraVisualKeys = @($actualVisualKeys | Where-Object { $_ -notin $expectedVisualKeys })
Assert-Condition ($missingVisualKeys.Count -eq 0) ("Missing ART20 visual_key rows: " + ($missingVisualKeys -join ", "))
Assert-Condition ($extraVisualKeys.Count -eq 0) ("Unexpected ART20 visual_key rows: " + ($extraVisualKeys -join ", "))

foreach ($row in $art20Rows) {
    Assert-Condition ($row.godot_path -like "res://assets/ui/art20/*") "ART20 row has unexpected godot_path: $($row.asset_id) -> $($row.godot_path)"
    $relative = $row.godot_path.Substring("res://".Length) -replace "/", "\"
    $localPath = Join-Path $godotRoot $relative
    Assert-Condition (Test-Path -LiteralPath $localPath -PathType Leaf) "ART20 runtime file missing: $localPath"
    Assert-Condition ($row.source_status -eq "art20_imported_pending_visual_validation") "ART20 row has unexpected source_status: $($row.asset_id) -> $($row.source_status)"
}

$generatedUnderArt20 = @(Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File | Where-Object {
    $_.Name -like "*.import" -or $_.Name -like "*.uid" -or $_.Name -like "*.translation"
})
Assert-Condition ($generatedUnderArt20.Count -eq 0) "Generated side effects found under ART20 runtime asset directory."

$mappingText = Get-Content -LiteralPath $mappingPath -Raw
$manifestText = ($art20Rows | ConvertTo-Csv -NoTypeInformation) -join "`n"
foreach ($blocked in $blockedRows) {
    $componentId = $blocked.component_id
    if ([string]::IsNullOrWhiteSpace($componentId)) {
        continue
    }
    Assert-Condition (-not $mappingText.Contains($componentId)) "Blocked component appears in ART20 mapping: $componentId"
    Assert-Condition (-not $manifestText.Contains($componentId)) "Blocked component appears in ART20 manifest rows: $componentId"
}

$scriptRootsToScan = @(
    (Join-Path $godotRoot "scripts\presentation"),
    (Join-Path $godotRoot "scripts\ui")
)
$runtimeHardcodes = @()
foreach ($root in $scriptRootsToScan) {
    if (Test-Path -LiteralPath $root) {
        $runtimeHardcodes += Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.gd" |
            Select-String -Pattern "D:\\AGAME1\\sources|D:\\AGAME1\\Draw|D:\\AGAME1\\Base Art|D:\\AGAME1\\Connection"
    }
}
Assert-Condition ($runtimeHardcodes.Count -eq 0) "Runtime hardcoded external source path found in UI/presentation scripts."

$gitStatus = git -C $repoRoot status --short
$staged = @($gitStatus | Where-Object { $_ -match "^[MADRCU]" })
Assert-Condition ($staged.Count -eq 0) "There are staged changes; ART20 execution must not stage files."

Write-Host "ART20 UI asset pipeline validation passed."
Write-Host "staging_rows=$($stagingRows.Count)"
Write-Host "cut_rows=$($cutRows.Count)"
Write-Host "blocked_rows=$($blockedRows.Count)"
Write-Host "art20_manifest_rows=$($art20Rows.Count)"
Write-Host "slice6_screenshots=$($requiredScreenshots.Count)"
