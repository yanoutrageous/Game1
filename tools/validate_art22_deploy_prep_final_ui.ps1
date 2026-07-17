param(
    [string]$GodotPath = $env:GODOT4_CONSOLE
)

$ErrorActionPreference = "Stop"

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-TextContains {
    param([string]$Text, [string]$Needle, [string]$Context)
    Assert-Condition $Text.Contains($Needle) "$Context is missing required token: $Needle"
}

function Get-PngDimensions {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    Assert-Condition ($bytes.Length -ge 24) "PNG is too short: $Path"
    $signature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
    for ($index = 0; $index -lt $signature.Length; $index++) {
        Assert-Condition ($bytes[$index] -eq $signature[$index]) "Invalid PNG signature: $Path"
    }
    $width = [System.BitConverter]::ToUInt32([byte[]]($bytes[19], $bytes[18], $bytes[17], $bytes[16]), 0)
    $height = [System.BitConverter]::ToUInt32([byte[]]($bytes[23], $bytes[22], $bytes[21], $bytes[20]), 0)
    return @([int]$width, [int]$height)
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotRoot = Join-Path $repoRoot "Godot\GraytailGodot"
$validationRoot = Join-Path $repoRoot "docs\art\validation\art22"
$assetRoot = Join-Path $godotRoot "assets\ui\art22\deploy_prep"
$reportCsvPath = Join-Path $validationRoot "deploy_prep_runtime_asset_report.csv"
$reportJsonPath = Join-Path $validationRoot "deploy_prep_runtime_asset_report.json"
$contractCsvPath = Join-Path $validationRoot "deploy_prep_runtime_asset_contract.csv"
$manifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$acceptancePath = Join-Path $repoRoot "docs\validation\ART22_DEPLOY_PREP_FINAL_UI_ACCEPTANCE.md"
$validationPath = Join-Path $repoRoot "docs\validation\ART22_DEPLOY_PREP_FINAL_UI_VALIDATION.md"
$handoffPath = Join-Path $repoRoot "docs\handoff\HANDOFF_ART22_DEPLOY_PREP_FINAL_UI.md"
$closeoutPath = Join-Path $repoRoot "docs\art\ART22_CLOSEOUT_DEPLOY_PREP_FINAL_UI.md"
$planPath = Join-Path $repoRoot "docs\art\ART22_DEPLOY_PREP_FINAL_UI_PLAN.md"
$motionAuditPath = Join-Path $validationRoot "ART22_DEPLOY_PREP_MOTION_AUDIT.md"
$motionContractPath = Join-Path $validationRoot "deploy_prep_motion_contract.csv"
$shellPath = Join-Path $godotRoot "scripts\ui\deploy_prep\deploy_prep_shell.gd"
$cardPath = Join-Path $godotRoot "scripts\ui\deploy_prep\deploy_prep_card_view.gd"
$layoutPath = Join-Path $godotRoot "scripts\ui\deploy_prep\deploy_prep_layout_contract.gd"
$assetContractPath = Join-Path $godotRoot "scripts\presentation\art22_deploy_prep_asset_contract.gd"
$runtimeRunnerPath = Join-Path $godotRoot "tests\art22_deploy_prep_runtime_runner.gd"
$mainRouteRunnerPath = Join-Path $godotRoot "tests\art22_deploy_prep_main_route_runner.gd"
$captureRunnerPath = Join-Path $godotRoot "tests\art22_deploy_prep_capture_runner.gd"

$requiredFiles = @(
    $reportCsvPath,
    $reportJsonPath,
    $contractCsvPath,
    $manifestPath,
    $acceptancePath,
    $validationPath,
    $handoffPath,
    $closeoutPath,
    $planPath,
    $motionAuditPath,
    $motionContractPath,
    $shellPath,
    $cardPath,
    $layoutPath,
    $assetContractPath,
    $runtimeRunnerPath,
    $mainRouteRunnerPath,
    $captureRunnerPath
)
foreach ($path in $requiredFiles) {
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing ART22 file: $path"
}

$reportRows = @(Import-Csv -LiteralPath $reportCsvPath)
$contractRows = @(Import-Csv -LiteralPath $contractCsvPath)
$manifestRows = @(Import-Csv -LiteralPath $manifestPath)
$report = Get-Content -LiteralPath $reportJsonPath -Raw | ConvertFrom-Json
$motionRows = @(Import-Csv -LiteralPath $motionContractPath)

Assert-Condition ($reportRows.Count -eq 57) "Expected 57 ART22 runtime assets, got $($reportRows.Count)."
Assert-Condition ($contractRows.Count -eq 57) "Expected 57 ART22 contract rows, got $($contractRows.Count)."
Assert-Condition ([int]$report.runtime_assets -eq 57) "Runtime report count mismatch."
Assert-Condition ([int]$report.default_assets -eq 36) "Expected 36 ART22 default assets."
Assert-Condition ([double]$report.total_decoded_mib -le 12.0) "ART22 total decoded texture load exceeds 12 MiB."
Assert-Condition ([double]$report.default_decoded_mib -le 10.0) "ART22 default decoded texture load exceeds 10 MiB."
Assert-Condition ($motionRows.Count -eq 17) "Expected 17 ART22 motion contract rows, got $($motionRows.Count)."
Assert-Condition (@($reportRows | Group-Object asset_id | Where-Object Count -gt 1).Count -eq 0) "Duplicate ART22 asset_id values found."
Assert-Condition (@($reportRows | Group-Object visual_key | Where-Object Count -gt 1).Count -eq 0) "Duplicate ART22 visual_key values found."
Assert-Condition (@($reportRows | Group-Object runtime_asset | Where-Object Count -gt 1).Count -eq 0) "Duplicate ART22 runtime paths found."

$expectedGroups = [ordered]@{
    "deploy_default" = 36
    "deploy_modal" = 1
    "deploy_active_run" = 4
    "deploy_map" = 6
    "deploy_claim" = 5
    "deploy_objective" = 5
}
foreach ($group in $expectedGroups.Keys) {
    $actual = @($reportRows | Where-Object load_group -eq $group).Count
    Assert-Condition ($actual -eq $expectedGroups[$group]) "Load-group count mismatch for ${group}: expected $($expectedGroups[$group]), got $actual."
}

$manifestById = @{}
foreach ($row in $manifestRows) { $manifestById[$row.asset_id] = $row }
foreach ($row in $reportRows) {
    Assert-Condition ($manifestById.ContainsKey($row.asset_id)) "ART22 asset is absent from manifest: $($row.asset_id)"
    Assert-Condition ($manifestById[$row.asset_id].godot_path -eq $row.runtime_asset) "Manifest path mismatch: $($row.asset_id)"
    $runtimePath = Join-Path $godotRoot ($row.runtime_asset.Substring(6) -replace "/", "\")
    Assert-Condition (Test-Path -LiteralPath $runtimePath -PathType Leaf) "Runtime PNG is missing: $runtimePath"
    Assert-Condition ((Get-FileHash -LiteralPath $runtimePath -Algorithm SHA256).Hash.ToLowerInvariant() -eq $row.runtime_sha256.ToLowerInvariant()) "Runtime hash mismatch: $($row.asset_id)"
    $sourcePath = Join-Path $repoRoot ($row.source_candidate -replace "/", "\")
    Assert-Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) "Source PNG is missing: $sourcePath"
    Assert-Condition ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant() -eq $row.source_sha256.ToLowerInvariant()) "Source hash mismatch: $($row.asset_id)"
}

$sidecars = @(Get-ChildItem -LiteralPath $assetRoot -Recurse -File | Where-Object {
    $_.Name -like "*.import" -or $_.Name -like "*.uid" -or $_.Name -like "*.translation"
})
$trackedArt22Files = @(git -C $repoRoot ls-files -- "Godot/GraytailGodot/assets/ui/art22/deploy_prep")
$trackedSidecars = @($trackedArt22Files | Where-Object { $_ -like "*.import" -or $_ -like "*.uid" -or $_ -like "*.translation" })
Assert-Condition ($trackedSidecars.Count -eq 0) "Generated Godot sidecars are tracked inside ART22 runtime assets."

$acceptanceText = Get-Content -LiteralPath $acceptancePath -Raw
$validationText = Get-Content -LiteralPath $validationPath -Raw
$shellText = Get-Content -LiteralPath $shellPath -Raw
$cardText = Get-Content -LiteralPath $cardPath -Raw
$layoutText = Get-Content -LiteralPath $layoutPath -Raw
$runnerText = Get-Content -LiteralPath $runtimeRunnerPath -Raw
$mainRouteRunnerText = Get-Content -LiteralPath $mainRouteRunnerPath -Raw
foreach ($token in @("Acceptance-Version: ART22-CU-FROZEN-2", "Pass-Policy: ALL_34_STATES_AND_MOTION_OR_FAIL", "Rework-Policy: SAME_CRITERIA_FULL_RESTART", "Motion-Watch-Seconds: 12", "Computer Use", "PASS / FAIL")) {
    Assert-TextContains $acceptanceText $token "ART22 acceptance"
}
foreach ($token in @("Computer-Use: PASS", "34/34", "AssetCatalog", "tooltip", "loadout_permission_interface", "preview_only")) {
    Assert-TextContains $validationText $token "ART22 final validation"
}
foreach ($token in @("map_classic_minesweeper", "warehouse_status", "claim_recommended", "objective_reward", "loadout_permission_interface")) {
    Assert-TextContains $acceptanceText $token "ART22 acceptance matrix"
}
foreach ($token in @("DeployParchmentGroup", "DeployFilterPrevious", "DeployFilterNext", "DeployResultHintPanel", "DeploySummaryBoard", "DeployPrimaryAction", "DeployCancelAction", "DeployCancelModal", 'preview_only"] = false')) {
    Assert-TextContains $shellText $token "deploy_prep_shell.gd"
}
foreach ($token in @("CHARACTER_IDLE_SEQUENCE", "CHARACTER_LOOK_SEQUENCE", "DeployBlueGroundFlame", "DeployBlueDust", "DeployWarmEmbers", "_update_summary_sway", "play_panel_open(card_scroll)")) {
    Assert-TextContains $shellText $token "deploy_prep_shell.gd motion"
}
foreach ($token in @("custom_minimum_size = Vector2(612, 112)", "CardArtworkFrame", "CardCategoryChip", "CardStatePanel", "_category_chip_text")) {
    Assert-TextContains $cardText $token "deploy_prep_card_view.gd"
}
Assert-Condition (-not $shellText.Contains("tooltip_text")) "DeployPrepShell still exposes unbacked native tooltip text."
Assert-Condition (-not $cardText.Contains("tooltip_text")) "DeployPrepCardView still exposes unbacked native tooltip text."
foreach ($token in @("PARCHMENT := Rect2(254, 14, 688, 692)", "CHARACTER := Rect2(34, 392, 190, 216)", "SUMMARY_BOARD := Rect2(984, 54, 252, 494)", "RESULT_HINT")) {
    Assert-TextContains $layoutText $token "deploy_prep_layout_contract.gd"
}
Assert-TextContains $runnerText "secondary_state_count == 34" "ART22 runtime runner"
Assert-TextContains $runnerText "summary_pages=4" "ART22 runtime runner"
Assert-TextContains $runnerText "character_frames=8 ambient_tracks=10" "ART22 runtime runner"
foreach ($token in @("res://scenes/main/main.tscn", "MainMenuEntry_deploy", "DeployPrepSceneCleanPlate", "ART22_DEPLOY_PREP_MAIN_ROUTE=PASS")) {
    Assert-TextContains $mainRouteRunnerText $token "ART22 actual main-route runner"
}

$expectedScreenshots = [ordered]@{
    "art22_deploy_prep_1280x720_expanded.png" = @(1280, 720)
    "art22_deploy_prep_1366x768_expanded.png" = @(1366, 768)
    "art22_deploy_prep_1600x900_expanded.png" = @(1600, 900)
    "art22_deploy_prep_1920x1080_expanded.png" = @(1920, 1080)
    "art22_deploy_prep_2560x1440_expanded.png" = @(2560, 1440)
    "art22_deploy_prep_1280x720_collapsed.png" = @(1280, 720)
    "art22_deploy_prep_1280x720_active_run.png" = @(1280, 720)
    "art22_deploy_prep_1280x720_cancel_modal.png" = @(1280, 720)
    "art22_deploy_prep_1280x720_warehouse.png" = @(1280, 720)
    "art22_deploy_prep_1280x720_claim.png" = @(1280, 720)
    "art22_deploy_prep_1280x720_objective.png" = @(1280, 720)
    "art22_deploy_prep_1280x720_loadout.png" = @(1280, 720)
}
$screenshotRoot = Join-Path $validationRoot "screenshots"
$screenshotHashes = @()
foreach ($name in $expectedScreenshots.Keys) {
    $path = Join-Path $screenshotRoot $name
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing ART22 screenshot: $name"
    $dimensions = Get-PngDimensions $path
    $expected = $expectedScreenshots[$name]
    Assert-Condition ($dimensions[0] -eq $expected[0] -and $dimensions[1] -eq $expected[1]) "Screenshot dimensions mismatch: $name"
    $screenshotHashes += (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
Assert-Condition (($screenshotHashes | Sort-Object -Unique).Count -eq $expectedScreenshots.Count) "ART22 screenshot evidence contains duplicate images."

$matrixRoot = Join-Path $validationRoot "filter_matrix"
$matrixSheets = @(Get-ChildItem -LiteralPath $matrixRoot -File -Filter "art22_filter_matrix_*.png")
Assert-Condition ($matrixSheets.Count -eq 5) "Expected five ART22 filter matrix sheets."
$matrixText = ($matrixSheets.BaseName -join " ")
foreach ($tab in @("map", "warehouse", "claim", "objective", "loadout")) {
    Assert-Condition ($matrixText.Contains("art22_filter_matrix_$tab")) "Missing filter matrix sheet for $tab."
}

$motionRoot = Join-Path $validationRoot "motion"
$motionScreens = @(Get-ChildItem -LiteralPath $motionRoot -File -Filter "art22_motion_collapsed_t*.png")
Assert-Condition ($motionScreens.Count -eq 6) "Expected six ART22 motion timing screenshots."
$motionHashes = @($motionScreens | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash } | Sort-Object -Unique)
Assert-Condition ($motionHashes.Count -eq 6) "Motion timing screenshots are not visually distinct."

if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
    Assert-Condition (Test-Path -LiteralPath $GodotPath -PathType Leaf) "Configured GodotPath does not exist: $GodotPath"
    & $GodotPath --headless --path $godotRoot --script "res://tests/art22_deploy_prep_runtime_runner.gd"
    Assert-Condition ($LASTEXITCODE -eq 0) "ART22 runtime runner failed."
    & $GodotPath --headless --path $godotRoot --script "res://tests/art22_deploy_prep_main_route_runner.gd"
    Assert-Condition ($LASTEXITCODE -eq 0) "ART22 actual main-route runner failed."
} else {
    Write-Host "godot_runtime_runner=SKIPPED (pass -GodotPath or set GODOT4_CONSOLE)"
}

Write-Host "ART22 deploy-prep final UI validation passed."
Write-Host "runtime_assets=$($reportRows.Count)"
Write-Host "default_decoded_mib=$($report.default_decoded_mib)"
Write-Host "primary_tabs=5"
Write-Host "secondary_states=34"
Write-Host "filter_matrix_sheets=$($matrixSheets.Count)"
Write-Host "resolution_screenshots=$($expectedScreenshots.Count)"
Write-Host "motion_contract_rows=$($motionRows.Count)"
Write-Host "motion_timing_screenshots=$($motionScreens.Count)"
Write-Host "ignored_runtime_sidecars=$($sidecars.Count)"
