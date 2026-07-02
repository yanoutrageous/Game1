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
$art21Root = "D:\AGAME1\sources\art\ART-21"
$art21ManifestRoot = Join-Path $art21Root "_manifest"
$runtimeRoot = Join-Path $godotRoot "assets\ui\art21"
$assetManifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$validationRoot = Join-Path $repoRoot "docs\art\validation\art21"
$contractPath = Join-Path $validationRoot "ui_placement_contract.csv"
$contractScriptPath = Join-Path $godotRoot "scripts\presentation\art21_ui_placement_contract.gd"
$skinKitPath = Join-Path $godotRoot "scripts\presentation\art10_ui_skin_kit.gd"

$requiredFiles = @(
    (Join-Path $art21ManifestRoot "staging_manifest.csv"),
    (Join-Path $art21ManifestRoot "runtime_import_manifest.csv"),
    (Join-Path $art21ManifestRoot "blocked_resolution.csv"),
    (Join-Path $art21ManifestRoot "cut_summary.json"),
    $contractPath,
    $assetManifestPath,
    $contractScriptPath,
    $skinKitPath
)

foreach ($file in $requiredFiles) {
    Assert-Condition (Test-Path -LiteralPath $file -PathType Leaf) "Missing required file: $file"
}

$contractRows = @(Import-Csv -LiteralPath $contractPath)
$assetRows = @(Import-Csv -LiteralPath $assetManifestPath)
$art21Rows = @($assetRows | Where-Object { $_.asset_id -like "ui.art21.*" })
$stagingRows = @(Import-Csv -LiteralPath (Join-Path $art21ManifestRoot "staging_manifest.csv"))
$runtimeRows = @(Import-Csv -LiteralPath (Join-Path $art21ManifestRoot "runtime_import_manifest.csv"))
$blockedRows = @(Import-Csv -LiteralPath (Join-Path $art21ManifestRoot "blocked_resolution.csv"))
$cutSummary = Get-Content -LiteralPath (Join-Path $art21ManifestRoot "cut_summary.json") -Raw | ConvertFrom-Json

Assert-Condition ($contractRows.Count -eq 36) "Expected 36 ART21 placement contract rows, got $($contractRows.Count)."
Assert-Condition ($art21Rows.Count -eq 36) "Expected 36 ART21 asset_manifest rows, got $($art21Rows.Count)."
Assert-Condition ($stagingRows.Count -eq 36) "Expected 36 ART21 staging rows, got $($stagingRows.Count)."
Assert-Condition ($runtimeRows.Count -eq 36) "Expected 36 ART21 runtime import rows, got $($runtimeRows.Count)."
Assert-Condition ([int]$cutSummary.component_rows -eq 36) "cut_summary component_rows mismatch."
Assert-Condition ([int]$cutSummary.runtime_rows -eq 36) "cut_summary runtime_rows mismatch."
Assert-Condition ([int]$cutSummary.contract_rows -eq 36) "cut_summary contract_rows mismatch."

$expectedScreenCounts = @{
    "shared" = 14
    "main_menu" = 1
    "deploy_prep" = 3
    "long_term" = 3
    "run_hud" = 3
    "map_overlay" = 9
    "inventory" = 1
    "ground_loot" = 1
    "result" = 1
}

foreach ($screen in $expectedScreenCounts.Keys) {
    $actual = @($contractRows | Where-Object { $_.screen -eq $screen }).Count
    Assert-Condition ($actual -eq $expectedScreenCounts[$screen]) "Contract screen count mismatch for ${screen}: expected $($expectedScreenCounts[$screen]), got $actual."
}

$duplicateAssetIds = @($assetRows | Group-Object asset_id | Where-Object { $_.Name -and $_.Count -gt 1 })
Assert-Condition ($duplicateAssetIds.Count -eq 0) ("Duplicate asset_id values found: " + (($duplicateAssetIds | Select-Object -ExpandProperty Name) -join ", "))

$contractAssetIds = @($contractRows | ForEach-Object { $_.asset_id })
$manifestArt21AssetIds = @($art21Rows | ForEach-Object { $_.asset_id })
$missingManifestAssets = @($contractAssetIds | Where-Object { $_ -notin $manifestArt21AssetIds })
$extraManifestAssets = @($manifestArt21AssetIds | Where-Object { $_ -notin $contractAssetIds })
Assert-Condition ($missingManifestAssets.Count -eq 0) ("Contract asset_ids missing from asset_manifest.csv: " + ($missingManifestAssets -join ", "))
Assert-Condition ($extraManifestAssets.Count -eq 0) ("Unexpected ART21 asset_manifest.csv rows: " + ($extraManifestAssets -join ", "))

foreach ($row in $art21Rows) {
    Assert-Condition ($row.godot_path -like "res://assets/ui/art21/*") "ART21 row has unexpected godot_path: $($row.asset_id) -> $($row.godot_path)"
    $relative = $row.godot_path.Substring("res://".Length) -replace "/", "\"
    $localPath = Join-Path $godotRoot $relative
    Assert-Condition (Test-Path -LiteralPath $localPath -PathType Leaf) "ART21 runtime file missing: $localPath"
    Assert-Condition ($row.source_status -eq "art21_generated_contract_component") "ART21 row has unexpected source_status: $($row.asset_id) -> $($row.source_status)"
}

$requiredBlockedVisualKeys = @(
    "deploy.left_character_frame.replaced",
    "long_term.profile_frame.replaced",
    "run.gameplay_viewport.background.replaced",
    "map_overlay.cell.unknown.replaced",
    "map_overlay.cell.explored.replaced",
    "map_overlay.cell.scanned.replaced",
    "map_overlay.cell.flagged.replaced",
    "map_overlay.marker.event.replaced"
)

foreach ($visualKey in $requiredBlockedVisualKeys) {
    $row = @($contractRows | Where-Object { $_.visual_key -eq $visualKey })
    Assert-Condition ($row.Count -eq 1) "Missing blocked/replaced visual key in contract: $visualKey"
    Assert-Condition (-not [string]::IsNullOrWhiteSpace($row[0].blocked_reason)) "Blocked/replaced visual key lacks blocked_reason: $visualKey"
}

$consumerFiles = @(
    "scripts\presentation\art10_ui_skin_kit.gd",
    "scripts\presentation\art21_ui_placement_contract.gd",
    "scripts\ui\main_menu\main_menu_shell.gd",
    "scripts\ui\deploy_prep\deploy_prep_shell.gd",
    "scripts\ui\long_term\long_term_shell.gd",
    "scripts\ui\run_surface\run_surface.gd",
    "scripts\ui\map_overlay\map_overlay_panel.gd",
    "scripts\ui\inventory\inventory_panel.gd",
    "scripts\ui\ground_loot\ground_loot_panel.gd",
    "scripts\ui\result\result_panel.gd"
)

foreach ($relative in $consumerFiles) {
    $path = Join-Path $godotRoot $relative
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing ART21 consumer file: $path"
    $text = Get-Content -LiteralPath $path -Raw
    Assert-Condition ($text.Contains("Art21UIPlacementContract")) "Consumer file does not reference Art21UIPlacementContract: $relative"
}

$contractScriptText = Get-Content -LiteralPath $contractScriptPath -Raw
foreach ($visualKey in $contractRows.visual_key) {
    Assert-Condition ($contractScriptText.Contains($visualKey)) "ART21 runtime contract script missing visual_key: $visualKey"
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

$generatedUnderArt21 = @(Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*.import" -or $_.Name -like "*.uid" -or $_.Name -like "*.translation"
})

$gitStatus = git -C $repoRoot status --short
$staged = @($gitStatus | Where-Object { $_ -match "^[MADRCU]" })
Assert-Condition ($staged.Count -eq 0) "There are staged changes; ART21 validation expects unstaged local work before closeout commit."

Write-Host "ART21 UI placement contract validation passed."
Write-Host "contract_rows=$($contractRows.Count)"
Write-Host "art21_manifest_rows=$($art21Rows.Count)"
Write-Host "staging_rows=$($stagingRows.Count)"
Write-Host "runtime_import_rows=$($runtimeRows.Count)"
Write-Host "blocked_resolution_rows=$($blockedRows.Count)"
Write-Host "generated_side_effects_under_art21=$($generatedUnderArt21.Count)"
