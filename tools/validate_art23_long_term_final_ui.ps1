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
$validationRoot = Join-Path $repoRoot "docs\art\validation\art23"
$assetRoot = Join-Path $godotRoot "assets\ui\art23\long_term"
$reportCsvPath = Join-Path $validationRoot "long_term_runtime_asset_report.csv"
$reportJsonPath = Join-Path $validationRoot "long_term_runtime_asset_report.json"
$contractCsvPath = Join-Path $validationRoot "long_term_runtime_asset_contract.csv"
$matrixCsvPath = Join-Path $validationRoot "long_term_screenshot_matrix.csv"
$motionContractPath = Join-Path $validationRoot "long_term_motion_contract.csv"
$motionAuditPath = Join-Path $validationRoot "ART23_LONG_TERM_MOTION_AUDIT.md"
$optimizationPath = Join-Path $validationRoot "ART23_INITIAL_AUDIT_AND_OPTIMIZATION.md"
$manifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$acceptancePath = Join-Path $repoRoot "docs\validation\ART23_LONG_TERM_FINAL_UI_ACCEPTANCE.md"
$finalValidationPath = Join-Path $repoRoot "docs\validation\ART23_LONG_TERM_FINAL_UI_VALIDATION.md"
$planPath = Join-Path $repoRoot "docs\art\ART23_LONG_TERM_FINAL_UI_PLAN.md"
$closeoutPath = Join-Path $repoRoot "docs\art\ART23_CLOSEOUT_LONG_TERM_FINAL_UI.md"
$handoffPath = Join-Path $repoRoot "docs\handoff\HANDOFF_ART23_LONG_TERM_FINAL_UI.md"
$shellPath = Join-Path $godotRoot "scripts\ui\long_term\long_term_shell.gd"
$layoutPath = Join-Path $godotRoot "scripts\ui\long_term\long_term_layout_contract.gd"
$frameworkPath = Join-Path $godotRoot "scripts\ui\long_term\long_term_content_framework.gd"
$modelPath = Join-Path $godotRoot "scripts\ui\long_term\long_term_model.gd"
$assetContractPath = Join-Path $godotRoot "scripts\presentation\art23_long_term_asset_contract.gd"
$runtimeRunnerPath = Join-Path $godotRoot "tests\art23_long_term_runtime_runner.gd"
$mainRouteRunnerPath = Join-Path $godotRoot "tests\art23_long_term_main_route_runner.gd"
$matrixRunnerPath = Join-Path $godotRoot "tests\art23_long_term_matrix_capture_runner.gd"
$readableFontPath = Join-Path $godotRoot "assets\fonts\NotoSansCJKsc-Regular.otf"
$readableFontLicensePath = Join-Path $godotRoot "assets\licenses\NotoSansCJK-OFL.txt"

$requiredFiles = @(
    $reportCsvPath, $reportJsonPath, $contractCsvPath, $matrixCsvPath,
    $motionContractPath, $motionAuditPath, $optimizationPath, $manifestPath,
    $acceptancePath, $finalValidationPath, $planPath, $closeoutPath, $handoffPath,
    $shellPath, $layoutPath, $frameworkPath, $modelPath, $assetContractPath,
    $runtimeRunnerPath, $mainRouteRunnerPath, $matrixRunnerPath,
    $readableFontPath, $readableFontLicensePath
)
foreach ($path in $requiredFiles) {
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing ART23 file: $path"
}

$reportRows = @(Import-Csv -LiteralPath $reportCsvPath)
$contractRows = @(Import-Csv -LiteralPath $contractCsvPath)
$manifestRows = @(Import-Csv -LiteralPath $manifestPath)
$matrixRows = @(Import-Csv -LiteralPath $matrixCsvPath)
$motionRows = @(Import-Csv -LiteralPath $motionContractPath)
$report = Get-Content -LiteralPath $reportJsonPath -Raw | ConvertFrom-Json

Assert-Condition ($reportRows.Count -eq 58) "Expected 58 ART23 runtime assets, got $($reportRows.Count)."
Assert-Condition ($contractRows.Count -eq 58) "Expected 58 ART23 contract rows, got $($contractRows.Count)."
Assert-Condition ([int]$report.runtime_assets -eq 58) "Runtime report count mismatch."
Assert-Condition ([int]$report.default_assets -eq 52) "Expected 52 ART23 default assets."
Assert-Condition ([double]$report.total_decoded_mib -le 18.0) "ART23 total decoded texture load exceeds 18 MiB."
Assert-Condition ([double]$report.default_decoded_mib -le 8.0) "ART23 default decoded texture load exceeds 8 MiB."
Assert-Condition ($motionRows.Count -eq 13) "Expected 13 ART23 motion contract rows, got $($motionRows.Count)."
Assert-Condition (@($reportRows | Group-Object asset_id | Where-Object Count -gt 1).Count -eq 0) "Duplicate ART23 asset IDs found."
Assert-Condition (@($reportRows | Group-Object visual_key | Where-Object Count -gt 1).Count -eq 0) "Duplicate ART23 visual keys found."
Assert-Condition (@($reportRows | Group-Object runtime_asset | Where-Object Count -gt 1).Count -eq 0) "Duplicate ART23 runtime paths found."
Assert-Condition ((Get-FileHash -LiteralPath $readableFontPath -Algorithm SHA256).Hash -eq "2C76254F6FC379FDDFCE0A7E84FB5385BB135D3E399294F6EEB6680D0365B74B") "Readable CJK font hash mismatch."
$fontManifestRows = @($manifestRows | Where-Object asset_id -eq "ui.art23.long_term.font.body")
Assert-Condition ($fontManifestRows.Count -eq 1) "Expected exactly one ART23 readable-font manifest row."
Assert-Condition ($fontManifestRows[0].godot_path -eq "res://assets/fonts/NotoSansCJKsc-Regular.otf") "Readable-font manifest path mismatch."
Assert-Condition ($fontManifestRows[0].license_status -eq "verified_ofl_1_1") "Readable-font license status is not verified."

$expectedGroups = [ordered]@{
    "long_term_default" = 52
    "long_term_goals" = 1
    "long_term_codex" = 1
    "long_term_research" = 1
    "long_term_profile" = 1
    "long_term_gacha" = 1
    "long_term_collection_appearance" = 1
}
foreach ($group in $expectedGroups.Keys) {
    $actual = @($reportRows | Where-Object load_group -eq $group).Count
    Assert-Condition ($actual -eq $expectedGroups[$group]) "Load-group count mismatch for ${group}: expected $($expectedGroups[$group]), got $actual."
}

$manifestById = @{}
foreach ($row in $manifestRows) { $manifestById[$row.asset_id] = $row }
foreach ($row in $reportRows) {
    Assert-Condition ($manifestById.ContainsKey($row.asset_id)) "ART23 asset is absent from manifest: $($row.asset_id)"
    Assert-Condition ($manifestById[$row.asset_id].godot_path -eq $row.runtime_asset) "Manifest path mismatch: $($row.asset_id)"
    $runtimePath = Join-Path $godotRoot ($row.runtime_asset.Substring(6) -replace "/", "\")
    Assert-Condition (Test-Path -LiteralPath $runtimePath -PathType Leaf) "Runtime asset is missing: $runtimePath"
    Assert-Condition ((Get-FileHash -LiteralPath $runtimePath -Algorithm SHA256).Hash.ToLowerInvariant() -eq $row.runtime_sha256.ToLowerInvariant()) "Runtime hash mismatch: $($row.asset_id)"
    $sourcePath = Join-Path $repoRoot ($row.source_candidate -replace "/", "\")
    Assert-Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) "Source is missing: $sourcePath"
    Assert-Condition ((Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant() -eq $row.source_sha256.ToLowerInvariant()) "Source hash mismatch: $($row.asset_id)"
}

$trackedArtFiles = @(git -C $repoRoot ls-files -- "Godot/GraytailGodot/assets/ui/art23/long_term")
$trackedSidecars = @($trackedArtFiles | Where-Object { $_ -like "*.import" -or $_ -like "*.uid" -or $_ -like "*.translation" })
Assert-Condition ($trackedSidecars.Count -eq 0) "Generated Godot sidecars are tracked inside ART23 assets."

$frameworkText = Get-Content -LiteralPath $frameworkPath -Raw
$shellText = Get-Content -LiteralPath $shellPath -Raw
$layoutText = Get-Content -LiteralPath $layoutPath -Raw
$runnerText = Get-Content -LiteralPath $runtimeRunnerPath -Raw
$mainRouteText = Get-Content -LiteralPath $mainRouteRunnerPath -Raw
$acceptanceText = Get-Content -LiteralPath $acceptancePath -Raw
$finalValidationText = Get-Content -LiteralPath $finalValidationPath -Raw

$expectedSecondaryIds = @(
    "task", "achievement", "commission_record",
    "map", "monster", "collectible", "equipment", "consumable", "event", "rule", "lore",
    "unlock_interface", "research_entry",
    "qualification_level", "history", "statistics", "milestone", "title", "badge",
    "pool", "cost", "result_entry",
    "unique_display", "appearance_config", "display_content", "badge_title", "settlement_display"
)
foreach ($id in $expectedSecondaryIds) {
    Assert-TextContains $frameworkText ('&"' + $id + '"') "long_term_content_framework.gd"
}
Assert-Condition ([regex]::Matches($frameworkText, [regex]::Escape('_group(&"')).Count -eq 27) "Long-term framework does not define exactly 27 secondary pages."
foreach ($token in @(
    "LongTermSceneCleanPlate", "LongTermModuleGroup", "LongTermModuleFurniture",
    "LongTermContentDetailBlock", "LongTermProfileFrame", "LongTermArchiveLever",
    "STATE_CLOSED", "STATE_OPENING", "STATE_SWITCHING", "CHARACTER_IDLE_SEQUENCE",
    "CHARACTER_LOOK_SEQUENCE", "_content_transition_nodes", "SCROLL_MODE_SHOW_NEVER",
    "LongTermArchiveDust", "LongTermBlueMotes", "LongTermReadableFont",
    "archive_context_module_id", "archive_context_secondary_id"
)) {
    Assert-TextContains $shellText $token "long_term_shell.gd"
}
Assert-Condition (-not $shellText.Contains('"等级 01"')) "LongTermShell contains a fake hard-coded level."
Assert-Condition (-not $frameworkText.Contains("拍卖") -and -not (Get-Content -LiteralPath $modelPath -Raw).Contains("拍卖")) "Long-term code still contains the incorrect auction label."
foreach ($token in @(
    "NAV_MAIN := Rect2(12, 28, 142, 50)", "MODULE_BUTTON_SIZE := Vector2(126, 90)",
    "CONTENT_PANEL := Rect2(300, 292, 560, 248)", "LEVER := Rect2(4, 612, 152, 100)",
    "PROFILE_FRAME := Rect2(1012, 8, 258, 704)"
)) {
    Assert-TextContains $layoutText $token "long_term_layout_contract.gd"
}
foreach ($token in @("primary_modules=6", "secondary_pages=27", "character_frames=8", "OPEN,CLOSED,OPENING,CLOSING,SWITCHING")) {
    Assert-TextContains $runnerText $token "ART23 runtime runner"
}
foreach ($token in @("res://scenes/main/main.tscn", "MainMenuEntry_long_term", "LongTermSceneCleanPlate", "ART23_LONG_TERM_MAIN_ROUTE=PASS")) {
    Assert-TextContains $mainRouteText $token "ART23 main-route runner"
}
foreach ($token in @(
    "Acceptance-Version: ART23-CU-FROZEN-2",
    "Pass-Policy: ALL_6_PRIMARY_AND_27_SECONDARY_PAGES_OR_FAIL",
    "Rework-Policy: SAME_CRITERIA_FULL_RESTART",
    "Motion-Watch-Seconds: 20", "Conditional-Pass: FORBIDDEN", "Computer Use"
)) {
    Assert-TextContains $acceptanceText $token "ART23 acceptance"
}
foreach ($token in @("Computer-Use: PASS", "Matrix-Result: 27/27 PASS", "135/135", "ART23-CU-FROZEN-2")) {
    Assert-TextContains $finalValidationText $token "ART23 final validation"
}

$expectedResolutions = [ordered]@{
    "1280x720" = @(1280, 720)
    "1366x768" = @(1366, 768)
    "1600x900" = @(1600, 900)
    "1920x1080" = @(1920, 1080)
    "2560x1440" = @(2560, 1440)
}
Assert-Condition ($matrixRows.Count -eq 135) "Expected 135 screenshot matrix rows, got $($matrixRows.Count)."
Assert-Condition (@($matrixRows | Group-Object { "$($_.resolution)/$($_.module)/$($_.secondary)" } | Where-Object Count -gt 1).Count -eq 0) "Duplicate screenshot matrix states found."
Assert-Condition (@($matrixRows.captured_sha256 | Sort-Object -Unique).Count -eq 135) "Screenshot matrix hashes are not all unique."
foreach ($resolution in $expectedResolutions.Keys) {
    $expected = $expectedResolutions[$resolution]
    $rows = @($matrixRows | Where-Object resolution -eq $resolution)
    Assert-Condition ($rows.Count -eq 27) "Expected 27 matrix rows for $resolution, got $($rows.Count)."
    foreach ($row in $rows) {
        Assert-Condition ([int]$row.width -eq $expected[0] -and [int]$row.height -eq $expected[1]) "Matrix dimensions mismatch for $resolution/$($row.module)/$($row.secondary)."
    }
    $sheetPath = Join-Path $validationRoot "matrix_contact_sheets\art23_long_term_${resolution}_27_page_matrix.png"
    Assert-Condition (Test-Path -LiteralPath $sheetPath -PathType Leaf) "Missing ART23 contact sheet: $resolution"
    $representatives = @(Get-ChildItem -LiteralPath (Join-Path $validationRoot "screenshots\final_representative") -File -Filter "art23_long_term_${resolution}_*.png")
    Assert-Condition ($representatives.Count -eq 1) "Expected one retained full-resolution representative for $resolution."
    $dimensions = Get-PngDimensions $representatives[0].FullName
    Assert-Condition ($dimensions[0] -eq $expected[0] -and $dimensions[1] -eq $expected[1]) "Representative dimensions mismatch for $resolution."
}

$optimizationEvidence = @(Get-ChildItem -LiteralPath (Join-Path $validationRoot "screenshots\optimization_evidence") -File -Filter "*.png")
Assert-Condition ($optimizationEvidence.Count -ge 8) "Expected at least eight retained audit/style/font optimization images."

if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
    Assert-Condition (Test-Path -LiteralPath $GodotPath -PathType Leaf) "Configured GodotPath does not exist: $GodotPath"
    & $GodotPath --headless --path $godotRoot --script "res://tests/art23_long_term_runtime_runner.gd"
    Assert-Condition ($LASTEXITCODE -eq 0) "ART23 runtime runner failed."
    & $GodotPath --headless --path $godotRoot --script "res://tests/art23_long_term_main_route_runner.gd"
    Assert-Condition ($LASTEXITCODE -eq 0) "ART23 main-route runner failed."
} else {
    Write-Host "godot_runtime_runners=SKIPPED (pass -GodotPath or set GODOT4_CONSOLE)"
}

Write-Host "ART23 long-term final UI validation passed."
Write-Host "runtime_assets=$($reportRows.Count)"
Write-Host "primary_modules=6"
Write-Host "secondary_pages=27"
Write-Host "matrix_states=$($matrixRows.Count)"
Write-Host "contact_sheets=5"
Write-Host "representative_screenshots=5"
Write-Host "motion_contract_rows=$($motionRows.Count)"
