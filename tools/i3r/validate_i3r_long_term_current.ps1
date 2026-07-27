[CmdletBinding()]
param(
    [string]$RepoRoot = '',

    [Alias('GodotExe')]
    [string]$GodotPath = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Assert-Condition {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Get-Sha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-PngMetadata {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    Assert-Condition ($bytes.Length -ge 29) "PNG is truncated: $Path"
    $signature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
    for ($index = 0; $index -lt $signature.Length; $index++) {
        Assert-Condition ($bytes[$index] -eq $signature[$index]) "PNG signature mismatch: $Path"
    }
    $width = [System.Net.IPAddress]::NetworkToHostOrder([System.BitConverter]::ToInt32($bytes, 16))
    $height = [System.Net.IPAddress]::NetworkToHostOrder([System.BitConverter]::ToInt32($bytes, 20))
    return @{
        Width = $width
        Height = $height
        ColorType = [int]$bytes[25]
    }
}

function Assert-ExactSet {
    param(
        [string[]]$Actual,
        [string[]]$Expected,
        [string]$Label
    )
    $difference = @(Compare-Object -ReferenceObject @($Expected | Sort-Object) -DifferenceObject @($Actual | Sort-Object))
    Assert-Condition ($difference.Count -eq 0 -and $Actual.Count -eq $Expected.Count) "$Label set mismatch."
}

function Invoke-GodotRunner {
    param(
        [string]$Executable,
        [string]$ProjectRoot,
        [string]$Runner,
        [string]$PassMarker
    )
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $Executable --headless --path $ProjectRoot --script $Runner 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $output | ForEach-Object { Write-Host $_ }
    Assert-Condition ($exitCode -eq 0) "Godot runner failed ($exitCode): $Runner"
    Assert-Condition (($output -join "`n").Contains($PassMarker)) "Godot runner omitted PASS marker: $PassMarker"
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}
$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$observedRoot = (& git.exe -C $resolvedRoot rev-parse --show-toplevel).Trim()
Assert-Condition ($LASTEXITCODE -eq 0) "Unable to resolve active Git worktree."
Assert-Condition ((Resolve-Path -LiteralPath $observedRoot).Path -eq $resolvedRoot) "RepoRoot is not the active Git worktree root: $resolvedRoot"

$godotRoot = Join-Path $resolvedRoot 'Godot\GraytailGodot'
$currentRoot = Join-Path $resolvedRoot 'docs\40_validation\i3r_long_term_current'
$frozenRoot = Join-Path $resolvedRoot 'docs\art\validation\art23'
$reportCsvPath = Join-Path $currentRoot 'long_term_runtime_asset_report.csv'
$reportJsonPath = Join-Path $currentRoot 'long_term_runtime_asset_report.json'
$contractCsvPath = Join-Path $currentRoot 'long_term_runtime_asset_contract.csv'
$manifestPath = Join-Path $godotRoot 'data\assets\asset_manifest.csv'
$shellPath = Join-Path $godotRoot 'scripts\ui\long_term\long_term_shell.gd'
$frameworkPath = Join-Path $godotRoot 'scripts\ui\long_term\long_term_content_framework.gd'
$assetContractPath = Join-Path $godotRoot 'scripts\presentation\art23_long_term_asset_contract.gd'
$runtimeRunnerPath = Join-Path $godotRoot 'tests\art23_long_term_runtime_runner.gd'
$mainRouteRunnerPath = Join-Path $godotRoot 'tests\art23_long_term_main_route_runner.gd'
$matrixRunnerPath = Join-Path $godotRoot 'tests\art23_long_term_matrix_capture_runner.gd'
$generatorPath = Join-Path $resolvedRoot 'tools\art23_build_long_term_runtime.py'

foreach ($requiredPath in @(
    $reportCsvPath,
    $reportJsonPath,
    $contractCsvPath,
    $manifestPath,
    $shellPath,
    $frameworkPath,
    $assetContractPath,
    $runtimeRunnerPath,
    $mainRouteRunnerPath,
    $matrixRunnerPath,
    $generatorPath
)) {
    Assert-Condition (Test-Path -LiteralPath $requiredPath -PathType Leaf) "Missing current LongTerm governance input: $requiredPath"
}

$reportRows = @(Import-Csv -LiteralPath $reportCsvPath)
$contractRows = @(Import-Csv -LiteralPath $contractCsvPath)
$manifestRows = @(Import-Csv -LiteralPath $manifestPath)
$report = Get-Content -LiteralPath $reportJsonPath -Raw | ConvertFrom-Json
Assert-Condition ($reportRows.Count -eq 58) "Expected 58 current LongTerm runtime assets, got $($reportRows.Count)."
Assert-Condition ($contractRows.Count -eq 58) "Expected 58 current LongTerm contract rows, got $($contractRows.Count)."
Assert-Condition ((Get-Sha256 $reportCsvPath) -eq (Get-Sha256 $contractCsvPath)) "Current report and contract rows diverged."
Assert-Condition ($report.stage -eq 'I3R' -and $report.authority -eq 'current_production') "Current report authority is not I3R/current_production."
Assert-Condition ([int]$report.primary_modules -eq 6 -and [int]$report.secondary_pages -eq 25) "Current report module/page count drifted."
Assert-Condition ([int]$report.runtime_assets -eq 58 -and [int]$report.default_assets -eq 52) "Current report asset counts drifted."
Assert-Condition (@($reportRows | Where-Object default_load -eq 'true').Count -eq 52) "Current default-load row count drifted."
Assert-Condition ([double]$report.total_decoded_mib -le 18.0 -and [double]$report.default_decoded_mib -le 8.0) "Current LongTerm decoded texture budget exceeded."
Assert-Condition (@($reportRows.asset_id | Sort-Object -Unique).Count -eq 58) "Current report contains duplicate asset ids."
Assert-Condition (@($reportRows.runtime_asset | Sort-Object -Unique).Count -eq 58) "Current report contains duplicate runtime paths."

$expectedGroups = [ordered]@{
    'long_term_default' = 52
    'long_term_goals' = 1
    'long_term_codex' = 1
    'long_term_research' = 1
    'long_term_talent' = 1
    'long_term_profile' = 1
    'long_term_collection_appearance' = 1
}
foreach ($group in $expectedGroups.Keys) {
    $actual = @($reportRows | Where-Object load_group -eq $group).Count
    Assert-Condition ($actual -eq $expectedGroups[$group]) "Current load-group count mismatch for ${group}: expected $($expectedGroups[$group]), got $actual."
}

$manifestById = @{}
foreach ($row in $manifestRows) {
    if (-not $manifestById.ContainsKey($row.asset_id)) {
        $manifestById[$row.asset_id] = @()
    }
    $manifestById[$row.asset_id] += @($row)
}
foreach ($row in $reportRows) {
    Assert-Condition ($row.consumer -eq 'scripts/ui/long_term/long_term_shell.gd') "Current row has a non-production consumer: $($row.asset_id)"
    Assert-Condition ($row.runtime_status -eq 'current_production_reachable') "Current row has stale reachability status: $($row.asset_id)"
    Assert-Condition ($row.source_status -eq 'i3r_current_generated_from_audited_source') "Current row has stale source status: $($row.asset_id)"
    Assert-Condition ($row.runtime_asset.StartsWith('res://')) "Current row has a non-resource runtime path: $($row.asset_id)"
    $runtimeRelative = $row.runtime_asset.Substring('res://'.Length).Replace('/', '\')
    $runtimePath = Join-Path $godotRoot $runtimeRelative
    $sourcePath = Join-Path $resolvedRoot $row.source_candidate.Replace('/', '\')
    Assert-Condition (Test-Path -LiteralPath $runtimePath -PathType Leaf) "Current runtime asset is missing: $($row.runtime_asset)"
    Assert-Condition (Test-Path -LiteralPath $sourcePath -PathType Leaf) "Current source is missing: $($row.source_candidate)"
    Assert-Condition ((Get-Sha256 $runtimePath) -eq $row.runtime_sha256) "Current runtime hash mismatch: $($row.asset_id)"
    Assert-Condition ((Get-Sha256 $sourcePath) -eq $row.source_sha256) "Current source hash mismatch: $($row.asset_id)"
    Assert-Condition ($manifestById.ContainsKey($row.asset_id)) "Current manifest row is missing: $($row.asset_id)"
    $matches = @($manifestById[$row.asset_id])
    Assert-Condition ($matches.Count -eq 1) "Current manifest row is not unique: $($row.asset_id)"
    $manifestRow = $matches[0]
    Assert-Condition ($manifestRow.godot_path -eq $row.runtime_asset) "Manifest runtime path mismatch: $($row.asset_id)"
    Assert-Condition ($manifestRow.theme_key -eq $row.visual_key) "Manifest visual key mismatch: $($row.asset_id)"
    Assert-Condition ($manifestRow.linked_scene -eq $row.consumer) "Manifest consumer mismatch: $($row.asset_id)"
    Assert-Condition ($manifestRow.source_status -eq $row.source_status) "Manifest source status mismatch: $($row.asset_id)"
}

$gachaPattern = '^ui\.art23\.long_term\.(furniture\.gacha|control\.module\.gacha\.)'
Assert-Condition (@($reportRows | Where-Object asset_id -Match $gachaPattern).Count -eq 0) "Current report still contains gacha runtime rows."
Assert-Condition (@($manifestRows | Where-Object asset_id -Match $gachaPattern).Count -eq 0) "Current manifest still contains gacha runtime rows."
$retiredGachaPaths = @(
    'assets\ui\art23\long_term\furniture\gacha.png',
    'assets\ui\art23\long_term\controls\module_gacha_normal.png',
    'assets\ui\art23\long_term\controls\module_gacha_focused.png',
    'assets\ui\art23\long_term\controls\module_gacha_pressed.png',
    'assets\ui\art23\long_term\controls\module_gacha_selected.png',
    'assets\ui\art23\long_term\controls\module_gacha_locked.png'
)
foreach ($relativePath in $retiredGachaPaths) {
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $godotRoot $relativePath))) "Retired gacha runtime file still exists: $relativePath"
}

$talentPattern = '^ui\.art23\.long_term\.(furniture\.talent|control\.module\.talent\.)'
$talentRows = @($reportRows | Where-Object asset_id -Match $talentPattern)
$manifestTalentRows = @($manifestRows | Where-Object asset_id -Match $talentPattern)
Assert-Condition ($talentRows.Count -eq 6 -and $manifestTalentRows.Count -eq 6) "Current talent runtime must contain five controls and one furniture asset."
$talentFurnitureRows = @($talentRows | Where-Object asset_id -eq 'ui.art23.long_term.furniture.talent')
Assert-Condition ($talentFurnitureRows.Count -eq 1) "Dedicated talent furniture row is missing."
$talentFurnitureRow = $talentFurnitureRows[0]
Assert-Condition ([int]$talentFurnitureRow.width -eq 820 -and [int]$talentFurnitureRow.height -eq 526) "Dedicated talent furniture dimensions are not 820x526."
Assert-Condition ($talentFurnitureRow.source_candidate -eq 'docs/40_validation/i3r_long_term_current/sources/talent_furniture_alpha_source.png') "Talent furniture does not use the dedicated current alpha source."
Assert-Condition ($talentFurnitureRow.source_sha256 -eq 'bb341cbeb85cba1606fdbe9abe731cfc8a8730e2236f5b0d831d009ba54e9336') "Dedicated talent furniture source hash drifted."
Assert-Condition ($talentFurnitureRow.source_rect -eq 'alpha_bbox+contain_centered_padding8->820x526') "Talent furniture centered-contain source marker is missing."
$talentFurniturePath = Join-Path $godotRoot 'assets\ui\art23\long_term\furniture\talent.png'
$talentPng = Get-PngMetadata $talentFurniturePath
Assert-Condition ($talentPng.Width -eq 820 -and $talentPng.Height -eq 526 -and $talentPng.ColorType -eq 6) "Talent furniture must be an 820x526 RGBA PNG."
$talentAlphaSourcePath = Join-Path $currentRoot 'sources\talent_furniture_alpha_source.png'
$talentChromaSourcePath = Join-Path $currentRoot 'sources\talent_furniture_chroma_source.png'
Assert-Condition (Test-Path -LiteralPath $talentAlphaSourcePath -PathType Leaf) "Dedicated talent alpha source is missing."
Assert-Condition (Test-Path -LiteralPath $talentChromaSourcePath -PathType Leaf) "Dedicated talent chroma source is missing."
Assert-Condition ((Get-Sha256 $talentAlphaSourcePath) -eq 'bb341cbeb85cba1606fdbe9abe731cfc8a8730e2236f5b0d831d009ba54e9336') "Dedicated talent alpha source file hash drifted."

$shellText = Get-Content -LiteralPath $shellPath -Raw
$frameworkText = Get-Content -LiteralPath $frameworkPath -Raw
$assetContractText = Get-Content -LiteralPath $assetContractPath -Raw
$runtimeRunnerText = Get-Content -LiteralPath $runtimeRunnerPath -Raw
$matrixRunnerText = Get-Content -LiteralPath $matrixRunnerPath -Raw
$generatorText = Get-Content -LiteralPath $generatorPath -Raw
$moduleMatch = [regex]::Match(
    $shellText,
    'const MODULE_IDS:\s*Array\[StringName\]\s*=\s*\[(?<body>.*?)\]',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)
Assert-Condition ($moduleMatch.Success) "Could not parse current LongTerm module table."
$actualModules = @([regex]::Matches($moduleMatch.Groups['body'].Value, '&"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
$expectedModules = @('task_archive', 'codex', 'research', 'talent', 'profile', 'collection_appearance')
Assert-ExactSet $actualModules $expectedModules 'Current primary module'

$actualPages = @([regex]::Matches($frameworkText, '_group\(&"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
$expectedPages = @(
    'task', 'achievement', 'commission_record',
    'map', 'monster', 'collectible', 'equipment', 'consumable', 'event', 'rule', 'lore',
    'unlock_interface', 'research_entry', 'tree',
    'qualification_level', 'history', 'statistics', 'milestone', 'title', 'badge',
    'unique_display', 'appearance_config', 'display_content', 'badge_title', 'settlement_display'
)
Assert-ExactSet $actualPages $expectedPages 'Current secondary page'
Assert-Condition ($runtimeRunnerText.Contains('secondary_pages=25')) "Current runtime runner marker is not 25 pages."
Assert-Condition ($matrixRunnerText.Contains('[&"talent", [&"tree"]]') -and $matrixRunnerText.Contains('captured == 25')) "Current matrix capture runner is not the 25-page production matrix."
Assert-Condition ($assetContractText.Contains('TALENT_FURNITURE_PATH') -and $assetContractText.Contains('long_term.furniture.gacha')) "Current asset contract lacks dedicated-talent/no-gacha policy."
Assert-Condition ($generatorText.Contains('CURRENT_VALIDATION_ROOT') -and $generatorText.Contains('CURRENT_MODULE_TABLE')) "Current generator lacks separated I3R governance output."
Assert-Condition (-not $generatorText.Contains('gacha_furniture_chroma_source.png')) "Current generator still consumes frozen gacha furniture."

$frozenReportCsvPath = Join-Path $frozenRoot 'long_term_runtime_asset_report.csv'
$frozenReportJsonPath = Join-Path $frozenRoot 'long_term_runtime_asset_report.json'
$frozenContractCsvPath = Join-Path $frozenRoot 'long_term_runtime_asset_contract.csv'
$frozenMatrixPath = Join-Path $frozenRoot 'long_term_screenshot_matrix.csv'
$frozenAcceptancePath = Join-Path $resolvedRoot 'docs\validation\ART23_LONG_TERM_FINAL_UI_ACCEPTANCE.md'
$frozenValidationPath = Join-Path $resolvedRoot 'docs\validation\ART23_LONG_TERM_FINAL_UI_VALIDATION.md'
$frozenValidatorPath = Join-Path $resolvedRoot 'tools\validate_art23_long_term_final_ui.ps1'
$frozenGachaSourcePath = Join-Path $frozenRoot 'sources\gacha_furniture_chroma_source.png'
foreach ($frozenPath in @(
    $frozenReportCsvPath,
    $frozenReportJsonPath,
    $frozenContractCsvPath,
    $frozenMatrixPath,
    $frozenAcceptancePath,
    $frozenValidationPath,
    $frozenValidatorPath,
    $frozenGachaSourcePath
)) {
    Assert-Condition (Test-Path -LiteralPath $frozenPath -PathType Leaf) "Frozen ART23 evidence is missing: $frozenPath"
}
$frozenRows = @(Import-Csv -LiteralPath $frozenReportCsvPath)
$frozenContractRows = @(Import-Csv -LiteralPath $frozenContractCsvPath)
$frozenReport = Get-Content -LiteralPath $frozenReportJsonPath -Raw | ConvertFrom-Json
$frozenMatrixRows = @(Import-Csv -LiteralPath $frozenMatrixPath)
Assert-Condition ($frozenRows.Count -eq 58 -and $frozenContractRows.Count -eq 58) "Frozen ART23 asset evidence is not the 58-row closure."
Assert-Condition ([int]$frozenReport.runtime_assets -eq 58 -and [int]$frozenReport.default_assets -eq 52) "Frozen ART23 report is not the 58/52 closure."
Assert-Condition (@($frozenRows | Where-Object asset_id -Match $gachaPattern).Count -eq 6) "Frozen ART23 gacha asset evidence was not preserved."
Assert-Condition (@($frozenRows | Where-Object asset_id -Match $talentPattern).Count -eq 0) "Current talent rows leaked into frozen ART23 evidence."
Assert-Condition ($frozenMatrixRows.Count -eq 135) "Frozen ART23 matrix is not 135 rows."
$frozenStates = @($frozenMatrixRows | ForEach-Object { "$($_.module)/$($_.secondary)" } | Sort-Object -Unique)
Assert-Condition ($frozenStates.Count -eq 27) "Frozen ART23 matrix is not 27 unique pages."
$frozenAcceptanceText = Get-Content -LiteralPath $frozenAcceptancePath -Raw
$frozenValidationText = Get-Content -LiteralPath $frozenValidationPath -Raw
$frozenValidatorText = Get-Content -LiteralPath $frozenValidatorPath -Raw
Assert-Condition ($frozenAcceptanceText.Contains('ART23-CU-FROZEN-2') -and $frozenAcceptanceText.Contains('ALL_6_PRIMARY_AND_27_SECONDARY_PAGES_OR_FAIL')) "Frozen ART23 acceptance contract drifted."
Assert-Condition ($frozenValidationText.Contains('Matrix-Result: 27/27 PASS') -and $frozenValidationText.Contains('135/135')) "Frozen ART23 final validation drifted."
Assert-Condition ($frozenValidatorText.Contains('secondary_pages=27') -and $frozenValidatorText.Contains('$reportRows.Count -eq 58')) "Frozen ART23 validator drifted."
foreach ($resolution in @('1280x720', '1366x768', '1600x900', '1920x1080', '2560x1440')) {
    $contactSheet = Join-Path $frozenRoot "matrix_contact_sheets\art23_long_term_${resolution}_27_page_matrix.png"
    Assert-Condition (Test-Path -LiteralPath $contactSheet -PathType Leaf) "Frozen ART23 contact sheet is missing: $resolution"
}
$frozenGachaFurnitureRows = @($frozenRows | Where-Object asset_id -eq 'ui.art23.long_term.furniture.gacha')
Assert-Condition ($frozenGachaFurnitureRows.Count -eq 1) "Frozen ART23 gacha furniture row is missing."
Assert-Condition ($talentFurnitureRow.runtime_sha256 -ne $frozenGachaFurnitureRows[0].runtime_sha256) "Dedicated talent furniture reused the frozen gacha runtime image."

if (-not [string]::IsNullOrWhiteSpace($GodotPath)) {
    Assert-Condition (Test-Path -LiteralPath $GodotPath -PathType Leaf) "Configured GodotPath does not exist: $GodotPath"
    Invoke-GodotRunner $GodotPath $godotRoot 'res://tests/art23_long_term_runtime_runner.gd' 'ART23_LONG_TERM_RUNTIME=PASS primary_modules=6 secondary_pages=25'
    Invoke-GodotRunner $GodotPath $godotRoot 'res://tests/art23_long_term_main_route_runner.gd' 'ART23_LONG_TERM_MAIN_ROUTE=PASS'
} else {
    Write-Host 'godot_current_long_term_runners=SKIPPED (pass -GodotPath)'
}

Write-Output 'I3R_LONG_TERM_CURRENT_GOVERNANCE=PASS modules=6 pages=25 runtime_assets=58 gacha_runtime=0 talent_furniture=dedicated historical_art23=preserved'
