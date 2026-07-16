param(
    [string]$Art21SourceRoot = $env:ART21_SOURCE_ROOT
)

$ErrorActionPreference = "Stop"

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$godotRoot = Join-Path $repoRoot "Godot\GraytailGodot"
$runtimeRoot = Join-Path $godotRoot "assets\ui\art21"
$assetManifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$validationRoot = Join-Path $repoRoot "docs\art\validation\art21"
$contractPath = Join-Path $validationRoot "ui_placement_contract.csv"
$mainMenuContractPath = Join-Path $validationRoot "main_menu_runtime_asset_contract.csv"
$mainMenuReportPath = Join-Path $validationRoot "main_menu_runtime_asset_report.json"
$contractScriptPath = Join-Path $godotRoot "scripts\presentation\art21_ui_placement_contract.gd"
$mainMenuContractScriptPath = Join-Path $godotRoot "scripts\presentation\art21_main_menu_asset_contract.gd"
$skinKitPath = Join-Path $godotRoot "scripts\presentation\art10_ui_skin_kit.gd"

$requiredFiles = @(
    $contractPath,
    $mainMenuContractPath,
    $mainMenuReportPath,
    $assetManifestPath,
    $contractScriptPath,
    $mainMenuContractScriptPath,
    $skinKitPath
)
foreach ($file in $requiredFiles) {
    Assert-Condition (Test-Path -LiteralPath $file -PathType Leaf) "Missing required file: $file"
}

$contractRows = @(Import-Csv -LiteralPath $contractPath)
$mainMenuRows = @(Import-Csv -LiteralPath $mainMenuContractPath)
$assetRows = @(Import-Csv -LiteralPath $assetManifestPath)
$art21Rows = @($assetRows | Where-Object { $_.asset_id -like "ui.art21.*" })
$mainMenuReport = Get-Content -LiteralPath $mainMenuReportPath -Raw | ConvertFrom-Json

Assert-Condition ($contractRows.Count -eq 36) "Expected 36 base ART21 placement rows, got $($contractRows.Count)."
Assert-Condition ($mainMenuRows.Count -eq 152) "Expected 152 ART21 main-menu runtime rows, got $($mainMenuRows.Count)."
Assert-Condition ([int]$mainMenuReport.asset_count -eq $mainMenuRows.Count) "Main-menu asset report count mismatch."
Assert-Condition ([bool]$mainMenuReport.budget_pass) "Main-menu decoded texture budget failed."
Assert-Condition ([double]$mainMenuReport.decoded_mib_default_load -le 128.0) "Main-menu default load exceeds 128 MiB."
foreach ($column in @("runtime_rect", "anchor", "pivot", "z_layer", "runtime_status", "default_load")) {
    Assert-Condition ($mainMenuRows[0].PSObject.Properties.Name -contains $column) "Main-menu placement contract is missing column: $column"
}
Assert-Condition (@($mainMenuRows | Where-Object { $_.default_load -eq "true" -and ($_.runtime_rect -eq "not_mounted" -or $_.anchor -eq "n/a" -or $_.pivot -eq "n/a") }).Count -eq 0) "A live main-menu asset lacks explicit placement metadata."

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

$requiredScreenshots = @(
    "art21_cu_main_menu.png",
    "art21_cu_deploy_prep.png",
    "art21_cu_long_term.png",
    "art21_cu_run_hud.png",
    "art21_cu_map_overlay.png",
    "art21_cu_inventory.png",
    "art21_cu_result.png",
    "art21_cu_ground_loot_not_triggered.png"
)
foreach ($screenshot in $requiredScreenshots) {
    $path = Join-Path $validationRoot $screenshot
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing ART21 validation screenshot: $screenshot"
    Assert-Condition ((Get-Item -LiteralPath $path).Length -gt 0) "ART21 validation screenshot is empty: $screenshot"
}

$duplicateAssetIds = @($assetRows | Group-Object asset_id | Where-Object { $_.Name -and $_.Count -gt 1 })
Assert-Condition ($duplicateAssetIds.Count -eq 0) ("Duplicate asset_id values found: " + (($duplicateAssetIds | Select-Object -ExpandProperty Name) -join ", "))
$duplicateVisualKeys = @(($contractRows + $mainMenuRows) | Group-Object visual_key | Where-Object { $_.Name -and $_.Count -gt 1 })
Assert-Condition ($duplicateVisualKeys.Count -eq 0) ("Duplicate ART21 visual_key values found: " + (($duplicateVisualKeys | Select-Object -ExpandProperty Name) -join ", "))

$expectedAssetIds = @(($contractRows.asset_id + $mainMenuRows.asset_id) | Sort-Object -Unique)
$actualAssetIds = @($art21Rows.asset_id | Sort-Object -Unique)
$missingManifestAssets = @($expectedAssetIds | Where-Object { $_ -notin $actualAssetIds })
$extraManifestAssets = @($actualAssetIds | Where-Object { $_ -notin $expectedAssetIds })
Assert-Condition ($missingManifestAssets.Count -eq 0) ("Contract asset_ids missing from asset_manifest.csv: " + ($missingManifestAssets -join ", "))
Assert-Condition ($extraManifestAssets.Count -eq 0) ("Unexpected ART21 asset_manifest.csv rows: " + ($extraManifestAssets -join ", "))

foreach ($row in $art21Rows) {
    Assert-Condition ($row.godot_path -like "res://assets/ui/art21/*") "ART21 row has unexpected godot_path: $($row.asset_id) -> $($row.godot_path)"
    $relative = $row.godot_path.Substring("res://".Length) -replace "/", "\"
    $localPath = Join-Path $godotRoot $relative
    Assert-Condition (Test-Path -LiteralPath $localPath -PathType Leaf) "ART21 runtime file missing: $localPath"
    $validStatus = $row.source_status -eq "art21_generated_contract_component" -or $row.source_status -like "art21_main_menu_runtime_*"
    Assert-Condition $validStatus "ART21 row has unexpected source_status: $($row.asset_id) -> $($row.source_status)"
    Assert-Condition ($row.source_status -notmatch "reference_only") "ART21 runtime asset is marked reference_only: $($row.asset_id)"
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

$contractScriptText = (Get-Content -LiteralPath $contractScriptPath -Raw) + "`n" + (Get-Content -LiteralPath $mainMenuContractScriptPath -Raw)
foreach ($visualKey in ($contractRows.visual_key + $mainMenuRows.visual_key)) {
    Assert-Condition ($contractScriptText.Contains($visualKey)) "ART21 runtime contract script missing visual_key: $visualKey"
}

$runtimeHardcodes = @()
foreach ($root in @((Join-Path $godotRoot "scripts\presentation"), (Join-Path $godotRoot "scripts\ui"))) {
    $runtimeHardcodes += Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.gd" |
        Select-String -Pattern "D:\\AGAME1\\sources|D:\\AGAME1\\Draw|D:\\AGAME1\\Base Art|D:\\AGAME1\\Connection"
}
Assert-Condition ($runtimeHardcodes.Count -eq 0) "Runtime hardcoded external source path found in UI/presentation scripts."

$generatedUnderArt21 = @(Get-ChildItem -LiteralPath $runtimeRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*.import" -or $_.Name -like "*.uid" -or $_.Name -like "*.translation"
})
Assert-Condition ($generatedUnderArt21.Count -eq 0) "Generated import side effects found under ART21 runtime asset directory."

if (-not [string]::IsNullOrWhiteSpace($Art21SourceRoot)) {
    $resolvedSource = Resolve-Path -LiteralPath $Art21SourceRoot -ErrorAction Stop
    Write-Host "external_source_root=$resolvedSource"
} else {
    Write-Host "external_source_root=NOT_MOUNTED (repository runtime contract used)"
}

$gitStatus = git -C $repoRoot status --short
$staged = @($gitStatus | Where-Object { $_ -match "^[MADRCU]" })
Assert-Condition ($staged.Count -eq 0) "There are staged changes; ART21 validation expects unstaged local work before closeout commit."

Write-Host "ART21 UI placement contract validation passed."
Write-Host "base_contract_rows=$($contractRows.Count)"
Write-Host "main_menu_contract_rows=$($mainMenuRows.Count)"
Write-Host "art21_manifest_rows=$($art21Rows.Count)"
Write-Host "main_menu_default_decoded_mib=$($mainMenuReport.decoded_mib_default_load)"
Write-Host "generated_side_effects_under_art21=$($generatedUnderArt21.Count)"
