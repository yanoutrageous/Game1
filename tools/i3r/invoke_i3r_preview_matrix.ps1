[CmdletBinding()]
param(
    [string]$Scene = 'run',

    [string]$Resolution = '1280x720',

    [string]$UIScale = '100',

    [switch]$All,

    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$GodotExe = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '..\i0\i0_test_lib.ps1')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}


function Get-I3RMatrixWorkspaceRoot {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $repoPath = Get-I0CanonicalPath -Path $RepoRoot
    $commonResult = Invoke-I0Git -RepoRoot $repoPath -Arguments @(
        'rev-parse', '--path-format=absolute', '--git-common-dir'
    )
    $gitCommon = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $commonResult.stdout)
    $candidate = $repoPath
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-I0PathWithin -Path $gitCommon -Root $candidate -AllowRoot) {
            return $candidate
        }
        $parent = Split-Path -Parent $candidate
        if (
            [string]::IsNullOrWhiteSpace($parent) -or
            [string]::Equals($parent, $candidate, [System.StringComparison]::OrdinalIgnoreCase)
        ) {
            break
        }
        $candidate = Get-I0CanonicalPath -Path $parent
    }
    throw "Unable to derive I3R preview workspace root for repo=$repoPath git_common=$gitCommon"
}


function Get-I3RMatrixMarkedValue {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    $lines = @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object {
        $_.StartsWith($Marker, [System.StringComparison]::Ordinal)
    })
    if ($lines.Count -ne 1) {
        throw "Expected exactly one $Marker line, found $($lines.Count)"
    }
    return $lines[0].Substring($Marker.Length)
}


function Get-I3RMatrixFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I3RMatrixTextSha256 {
    param([Parameter(Mandatory = $true)][string]$Text)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return ([System.BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToUpperInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}


function Get-I3RMatrixJson {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "JSON file is missing: $Path"
    }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return ($raw | ConvertFrom-Json)
}


function ConvertTo-I3RMatrixProcessReport {
    param([Parameter(Mandatory = $true)]$ProcessResult)
    return [pscustomobject][ordered]@{
        file_path = $ProcessResult.file_path
        arguments = @($ProcessResult.arguments)
        working_directory = $ProcessResult.working_directory
        exit_code = $ProcessResult.exit_code
        timed_out = $ProcessResult.timed_out
        duration_ms = $ProcessResult.duration_ms
        stdout = Normalize-I0ProcessText -Text $ProcessResult.stdout
        stderr = Normalize-I0ProcessText -Text $ProcessResult.stderr
    }
}


function Get-I3RMatrixLogText {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return Get-Content -LiteralPath $Path -Raw
    }
    return ''
}


function Get-I3RMatrixDiagnostics {
    param([Parameter(Mandatory = $true)][string]$Text)
    $blocking = New-Object System.Collections.Generic.List[string]
    $cleanup = New-Object System.Collections.Generic.List[string]
    $seen = New-Object System.Collections.Generic.List[string]
    foreach ($match in @([regex]::Matches($Text, '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$'))) {
        $diagnostic = $match.Value.Trim()
        if (@($seen | Where-Object { [string]::Equals([string]$_, $diagnostic, [System.StringComparison]::Ordinal) }).Count -gt 0) {
            continue
        }
        [void]$seen.Add($diagnostic)
        if (
            $diagnostic -ceq 'WARNING: ObjectDB instances leaked at exit (run with --verbose for details).' -or
            $diagnostic -match '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
        ) {
            [void]$cleanup.Add($diagnostic)
        }
        else {
            [void]$blocking.Add($diagnostic)
        }
    }
    return [pscustomobject][ordered]@{
        blocking = $blocking.ToArray()
        cleanup = $cleanup.ToArray()
    }
}


if ($PSVersionTable.PSEdition -cne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -lt 1) {
    throw "I3R production preview matrix requires Windows PowerShell 5.1 Desktop; current=$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
}

$requestedRepo = Get-I0CanonicalPath -Path $RepoRoot
$resolvedRepoResult = Invoke-I0Git -RepoRoot $requestedRepo -Arguments @('rev-parse', '--show-toplevel')
$repo = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $resolvedRepoResult.stdout)
if (-not [string]::Equals($requestedRepo, $repo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RepoRoot must be the active Git worktree root: requested=$requestedRepo resolved=$repo"
}
$workspaceRoot = Get-I3RMatrixWorkspaceRoot -RepoRoot $repo
[void](Set-I0WorkspaceRoot -Path $workspaceRoot)
$setupRunnerPath = Get-I0CanonicalPath -Path (Join-Path $repo 'tools\i3r\godot_i3r_production_preview_matrix_runner.gd')
if (-not (Test-Path -LiteralPath $setupRunnerPath -PathType Leaf)) {
    throw "I3R preview runner is missing: $setupRunnerPath"
}
$setupRunnerSha256 = Get-I3RMatrixFileSha256 -Path $setupRunnerPath
$setupInvokerSha256 = Get-I3RMatrixFileSha256 -Path $PSCommandPath

$allScenes = @(
    'main_menu',
    'settings',
    'deploy',
    'long_term',
    'run',
    'combat',
    'inventory',
    'map',
    'result_success',
    'result_failure',
    'tutorial'
)
$authoritativeProbeNamesByScene = @{
    'main_menu' = @('MainMenuBoardLabel_deploy', 'MainMenuBoardLabel_long_term', 'MainMenuBoardLabel_settings')
    'settings' = @('Resolution', 'UIScale', 'WindowMode')
    'deploy' = @('MapScaleTitle', 'MapDetailTitle', 'MapSelectAction')
    'long_term' = @('LongTermContentDetailTitle', 'LongTermContentRecordTitle', 'LongTermContentRecordBody')
    'run' = @('RunScannerTitle', 'RunMineRiskText', 'RunAction_map')
    'combat' = @('RunScannerTitle', 'RunMineRiskText', 'RunAction_combat')
    'inventory' = @('InventoryPanelTitle', 'InventorySummary', 'InventoryItemTooltip')
    'map' = @('Title', 'Detail', 'MapCell_3_3')
    'result_success' = @('ResultTitle', 'ResultSummary', 'ResultReturnDeployButton')
    'result_failure' = @('ResultTitle', 'ResultSummary', 'ResultReturnDeployButton')
    'tutorial' = @('Title', 'Message', 'ConfirmButton')
}
$allResolutions = @('1280x720', '1366x768', '1600x900', '1920x1080')
$allUIScales = @('100', '125', '150')
$requestedScenes = @($Scene.Split(',') | ForEach-Object { $_.Trim() } | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
} | Select-Object -Unique)
$requestedResolutions = @($Resolution.Split(',') | ForEach-Object { $_.Trim() } | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
} | Select-Object -Unique)
$requestedUIScales = @($UIScale.Split(',') | ForEach-Object { $_.Trim().TrimEnd('%') } | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
} | Select-Object -Unique)
foreach ($sceneId in $requestedScenes) {
    if ($allScenes -cnotcontains $sceneId) {
        throw "Unsupported I3R preview scene: $sceneId"
    }
}
foreach ($resolutionId in $requestedResolutions) {
    if ($allResolutions -cnotcontains $resolutionId) {
        throw "Unsupported I3R preview resolution: $resolutionId"
    }
}
foreach ($uiScaleId in $requestedUIScales) {
    if ($allUIScales -cnotcontains $uiScaleId) {
        throw "Unsupported I3R preview UI scale: $uiScaleId"
    }
}
if ($All) {
    $selectedScenes = @($allScenes)
    $selectedResolutions = @($allResolutions)
    $selectedUIScales = @($allUIScales)
}
else {
    $selectedScenes = @($requestedScenes)
    $selectedResolutions = @($requestedResolutions)
    $selectedUIScales = @($requestedUIScales)
}
if ($selectedScenes.Count -eq 0 -or $selectedResolutions.Count -eq 0 -or $selectedUIScales.Count -eq 0) {
    throw 'At least one scene, resolution, and UI scale must be selected'
}
$resolutionMap = @{
    '1280x720' = @(1280, 720)
    '1366x768' = @(1366, 768)
    '1600x900' = @(1600, 900)
    '1920x1080' = @(1920, 1080)
}

$startedUtc = [DateTime]::UtcNow
$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$captureCases = New-Object System.Collections.Generic.List[object]
$fatalError = $null
$preflightCase = $null
$preflightReport = $null
$runRoot = $null
$mirrorRoot = $null
$matrixRoot = $null
$matrixReportPath = $null
$runnerPath = $null
$runnerSha256 = $null
$captureWindowPollution = $null
$captureWindowPollutionError = $null

try {
    $i1Invoker = Join-Path $repo 'tools\i1\invoke_i1.ps1'
    if (-not (Test-Path -LiteralPath $i1Invoker -PathType Leaf)) {
        throw "I1 isolated mirror entry is missing: $i1Invoker"
    }
    $preflightArguments = @(
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $i1Invoker,
        '-Profile', 'preflight',
        '-SourceMode', $SourceMode,
        '-RepoRoot', $repo
    )
    if (-not [string]::IsNullOrWhiteSpace($GodotExe)) {
        $preflightArguments += @('-GodotExe', $GodotExe)
    }
    $preflightRaw = Invoke-I0Process `
        -FilePath $windowsPowerShell `
        -Arguments $preflightArguments `
        -WorkingDirectory $repo `
        -TimeoutSeconds 1800
    $preflightText = $preflightRaw.stdout + "`n" + $preflightRaw.stderr
    $preflightReportPath = Get-I3RMatrixMarkedValue -Text $preflightText -Marker 'I1_REPORT_JSON='
    $preflightReportPath = Get-I0CanonicalPath -Path $preflightReportPath
    $preflightReport = Get-I3RMatrixJson -Path $preflightReportPath
    $preflightPassed = (
        -not $preflightRaw.timed_out -and
        $preflightRaw.exit_code -eq 0 -and
        [string]$preflightReport.profile -ceq 'preflight' -and
        [string]$preflightReport.source_mode -ceq $SourceMode -and
        [string]$preflightReport.overall_status -ceq 'PASS'
    )
    $preflightCase = [pscustomobject][ordered]@{
        status = if ($preflightPassed) { 'PASS' } else { 'FAIL' }
        report_path = $preflightReportPath
        report_sha256 = Get-I3RMatrixFileSha256 -Path $preflightReportPath
        process = ConvertTo-I3RMatrixProcessReport -ProcessResult $preflightRaw
    }
    $runRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.run_root)
    $mirrorRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.mirror_root)
    Assert-I0PathWithin -Path $mirrorRoot -Root $runRoot -Label 'I3R preview mirror'
    $matrixRoot = Get-I0CanonicalPath -Path (Join-Path $runRoot 'i3r_preview_matrix')
    $matrixReportPath = Get-I0CanonicalPath -Path (Join-Path $matrixRoot 'matrix_manifest.json')
    [void](New-Item -ItemType Directory -Path $matrixRoot -Force)
    if (-not $preflightPassed) {
        throw 'I1 isolated preflight did not pass; I3R preview generation was not started'
    }

    $projectRoot = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot 'Godot\GraytailGodot')
    $runnerPath = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot 'tools\i3r\godot_i3r_production_preview_matrix_runner.gd')
    $godotConsole = Get-I0CanonicalPath -Path ([string]$preflightReport.gates.runtime_links.console_executable.hardlink
    )
    foreach ($requiredPath in @($projectRoot, $runnerPath, $godotConsole)) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "I3R preview dependency is missing: $requiredPath"
        }
    }
    $runnerSha256 = Get-I3RMatrixFileSha256 -Path $runnerPath
    if (-not [string]::Equals($setupRunnerSha256, $runnerSha256, [System.StringComparison]::Ordinal)) {
        throw "I3R preview runner changed while the isolated mirror was being prepared: setup=$setupRunnerSha256 mirror=$runnerSha256"
    }

    foreach ($sceneId in $selectedScenes) {
        foreach ($resolutionId in $selectedResolutions) {
            $dimensions = @($resolutionMap[$resolutionId])
            $width = [int]$dimensions[0]
            $height = [int]$dimensions[1]
            foreach ($uiScaleId in $selectedUIScales) {
                $caseId = "${sceneId}__${resolutionId}__ui${uiScaleId}"
                $caseRoot = Get-I0CanonicalPath -Path (Join-Path $matrixRoot $caseId)
                [void](New-Item -ItemType Directory -Path $caseRoot -Force)
                $outputPath = Get-I0CanonicalPath -Path (Join-Path $caseRoot 'capture.png')
                $metadataPath = Get-I0CanonicalPath -Path (Join-Path $caseRoot 'metadata.json')
                $logPath = Get-I0CanonicalPath -Path (Join-Path $caseRoot 'godot.log')
                $environment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId ("I3R_PREVIEW_" + $caseId)
                $captureRaw = Invoke-I0Process `
                    -FilePath $godotConsole `
                    -Arguments @(
                        '--display-driver', 'windows',
                        '--rendering-driver', 'opengl3',
                        '--rendering-method', 'gl_compatibility',
                        '--audio-driver', 'Dummy',
                        '--path', $projectRoot,
                        '--log-file', $logPath,
                        '--script', $runnerPath,
                        '--',
                        "--scene=$sceneId",
                        "--width=$width",
                        "--height=$height",
                        "--ui-scale=$uiScaleId",
                        "--output=$outputPath",
                        "--metadata-output=$metadataPath"
                    ) `
                    -WorkingDirectory $projectRoot `
                    -Environment $environment `
                    -TimeoutSeconds 300
                $markerText = $captureRaw.stdout + "`n" + $captureRaw.stderr
                $diagnostics = Get-I3RMatrixDiagnostics -Text ($markerText + "`n" + (Get-I3RMatrixLogText -Path $logPath))
                $passLines = @((Normalize-I0ProcessText -Text $markerText) -split "`n" | Where-Object {
                    $_.Trim().StartsWith("I3R_PRODUCTION_PREVIEW=PASS scene=$sceneId size=${width}x${height} ui_scale=$uiScaleId ", [System.StringComparison]::Ordinal)
                })
                $failLines = @((Normalize-I0ProcessText -Text $markerText) -split "`n" | Where-Object {
                    $_.Trim().StartsWith('I3R_PRODUCTION_PREVIEW=FAIL', [System.StringComparison]::Ordinal)
                })
                $pngPresent = Test-Path -LiteralPath $outputPath -PathType Leaf
                $metadataPresent = Test-Path -LiteralPath $metadataPath -PathType Leaf
                $caseMetadata = if ($metadataPresent) { Get-I3RMatrixJson -Path $metadataPath } else { $null }
                $pngBytes = if ($pngPresent) { (Get-Item -LiteralPath $outputPath).Length } else { 0 }
                $pngSha256 = if ($pngBytes -gt 0) { Get-I3RMatrixFileSha256 -Path $outputPath } else { $null }
                $effectiveMetricsCanonical = if ($null -ne $caseMetadata) {
                    [string]$caseMetadata.effective_ui_metrics_canonical
                }
                else {
                    ''
                }
                $effectiveMetricsCalculatedSha256 = if (-not [string]::IsNullOrWhiteSpace($effectiveMetricsCanonical)) {
                    Get-I3RMatrixTextSha256 -Text $effectiveMetricsCanonical
                }
                else {
                    $null
                }
                $effectiveMetricsSha256 = if ($null -ne $caseMetadata) {
                    [string]$caseMetadata.effective_ui_metrics_sha256
                }
                else {
                    $null
                }
                $actualUIScaleScore = if ($null -ne $caseMetadata) {
                    [long]$caseMetadata.actual_ui_scale_score
                }
                else {
                    0
                }
                $effectiveMetricCount = if (
                    $null -ne $caseMetadata -and
                    $null -ne $caseMetadata.effective_ui_metrics
                ) {
                    [int]$caseMetadata.effective_ui_metrics.metric_count
                }
                else {
                    0
                }
                $authoritativeMetricsCanonical = if ($null -ne $caseMetadata) {
                    [string]$caseMetadata.authoritative_ui_metrics_canonical
                }
                else {
                    ''
                }
                $authoritativeMetricsCalculatedSha256 = if (-not [string]::IsNullOrWhiteSpace($authoritativeMetricsCanonical)) {
                    Get-I3RMatrixTextSha256 -Text $authoritativeMetricsCanonical
                }
                else {
                    $null
                }
                $authoritativeMetricsSha256 = if ($null -ne $caseMetadata) {
                    [string]$caseMetadata.authoritative_ui_metrics_sha256
                }
                else {
                    $null
                }
                $authoritativeUIScaleScore = if ($null -ne $caseMetadata) {
                    [long]$caseMetadata.authoritative_ui_scale_score
                }
                else {
                    0
                }
                $authoritativeProbeCount = if (
                    $null -ne $caseMetadata -and
                    $null -ne $caseMetadata.authoritative_ui_metrics
                ) {
                    [int]$caseMetadata.authoritative_ui_metrics.probe_count
                }
                else {
                    0
                }
                $expectedAuthoritativeProbeNames = @($authoritativeProbeNamesByScene[$sceneId])
                $reportedExpectedProbeNames = @()
                $reportedAuthoritativeProbeNames = @()
                $visibleMetricsOnly = $false
                $authoritativeProbeNamesValid = $false
                if ($null -ne $caseMetadata) {
                    $visibleMetricsOnly = @(
                        $caseMetadata.effective_ui_metrics.controls | Where-Object {
                            -not [bool]$_.visible_in_tree
                        }
                    ).Count -eq 0
                    $reportedExpectedProbeNames = @(
                        $caseMetadata.authoritative_ui_metrics.expected_probe_names |
                            ForEach-Object { [string]$_ }
                    )
                    $reportedAuthoritativeProbeNames = @(
                        $caseMetadata.authoritative_ui_metrics.probes |
                            ForEach-Object { [string]$_.node_name }
                    )
                    $authoritativeProbeNamesValid = (
                        $expectedAuthoritativeProbeNames.Count -ge 2 -and
                        $expectedAuthoritativeProbeNames.Count -le 4 -and
                        $reportedExpectedProbeNames.Count -eq $expectedAuthoritativeProbeNames.Count -and
                        $reportedAuthoritativeProbeNames.Count -eq $expectedAuthoritativeProbeNames.Count
                    )
                    if ($authoritativeProbeNamesValid) {
                        for ($probeIndex = 0; $probeIndex -lt $expectedAuthoritativeProbeNames.Count; $probeIndex++) {
                            if (
                                [string]$reportedExpectedProbeNames[$probeIndex] -cne
                                    [string]$expectedAuthoritativeProbeNames[$probeIndex] -or
                                [string]$reportedAuthoritativeProbeNames[$probeIndex] -cne
                                    [string]$expectedAuthoritativeProbeNames[$probeIndex] -or
                                -not [bool]$caseMetadata.authoritative_ui_metrics.probes[$probeIndex].visible_in_tree -or
                                [long]$caseMetadata.authoritative_ui_metrics.probes[$probeIndex].rect_size_milli[0] -le 0 -or
                                [long]$caseMetadata.authoritative_ui_metrics.probes[$probeIndex].rect_size_milli[1] -le 0
                            ) {
                                $authoritativeProbeNamesValid = $false
                                break
                            }
                        }
                    }
                }
                $captureFrameContractValid = $false
                if ($null -ne $caseMetadata) {
                    $logicalCanvasWidth = [int]$caseMetadata.production_content_scale_size[0]
                    $logicalCanvasHeight = [int]$caseMetadata.production_content_scale_size[1]
                    if ($logicalCanvasWidth -gt 0 -and $logicalCanvasHeight -gt 0) {
                        $expectedRendererScale = [Math]::Min(
                            [double]$width / [double]$logicalCanvasWidth,
                            [double]$height / [double]$logicalCanvasHeight
                        )
                        $expectedRendererWidth = [int][Math]::Floor(
                            [double]$logicalCanvasWidth * $expectedRendererScale + 0.0001
                        )
                        $expectedRendererHeight = [int][Math]::Floor(
                            [double]$logicalCanvasHeight * $expectedRendererScale + 0.0001
                        )
                        $paddingLeft = [int]$caseMetadata.letterbox_padding.left
                        $paddingTop = [int]$caseMetadata.letterbox_padding.top
                        $paddingRight = [int]$caseMetadata.letterbox_padding.right
                        $paddingBottom = [int]$caseMetadata.letterbox_padding.bottom
                        $captureFrameContractValid = (
                            [string]$caseMetadata.capture_frame_policy -ceq 'production_keep_aspect_physical_frame' -and
                            [int]$caseMetadata.capture_frame_size[0] -eq $width -and
                            [int]$caseMetadata.capture_frame_size[1] -eq $height -and
                            [int]$caseMetadata.renderer_content_size[0] -eq $expectedRendererWidth -and
                            [int]$caseMetadata.renderer_content_size[1] -eq $expectedRendererHeight -and
                            $paddingLeft -eq [int][Math]::Floor(($width - $expectedRendererWidth) / 2.0) -and
                            $paddingTop -eq [int][Math]::Floor(($height - $expectedRendererHeight) / 2.0) -and
                            $paddingLeft + $expectedRendererWidth + $paddingRight -eq $width -and
                            $paddingTop + $expectedRendererHeight + $paddingBottom -eq $height
                        )
                    }
                }
                $metadataValid = (
                    $null -ne $caseMetadata -and
                    [int]$caseMetadata.schema_version -eq 5 -and
                    [string]$caseMetadata.status -ceq 'GENERATED_REVIEW_REQUIRED' -and
                    [string]$caseMetadata.visual_acceptance -ceq 'NOT_RUN' -and
                    [string]$caseMetadata.production_scene_path -ceq 'res://scenes/main/main.tscn' -and
                    [int]$caseMetadata.production_main_instances -eq 1 -and
                    [string]$caseMetadata.scene -ceq $sceneId -and
                    [int]$caseMetadata.physical_size[0] -eq $width -and
                    [int]$caseMetadata.physical_size[1] -eq $height -and
                    [int]$caseMetadata.ui_scale_percent -eq [int]$uiScaleId -and
                    [Math]::Abs([double]$caseMetadata.ui_scale_factor - ([double]$uiScaleId / 100.0)) -le 0.001 -and
                    [string]$caseMetadata.ui_scale_mode -ceq 'production_visible_authoritative_control_metrics' -and
                    [int]$caseMetadata.effective_ui_metrics.schema_version -eq 2 -and
                    [string]$caseMetadata.effective_ui_metrics.scene -ceq $sceneId -and
                    [string]$caseMetadata.effective_ui_metrics.visibility_policy -ceq 'is_visible_in_tree' -and
                    -not [string]::IsNullOrWhiteSpace([string]$caseMetadata.effective_ui_metrics.root_path) -and
                    $effectiveMetricCount -gt 0 -and
                    @($caseMetadata.effective_ui_metrics.controls).Count -eq $effectiveMetricCount -and
                    $visibleMetricsOnly -and
                    [long]$caseMetadata.effective_ui_metrics.actual_font_size_score -eq $actualUIScaleScore -and
                    $actualUIScaleScore -gt 0 -and
                    [regex]::IsMatch([string]$effectiveMetricsSha256, '\A[0-9A-F]{64}\z') -and
                    [string]$effectiveMetricsCalculatedSha256 -ceq [string]$effectiveMetricsSha256 -and
                    [int]$caseMetadata.authoritative_ui_metrics.schema_version -eq 1 -and
                    [string]$caseMetadata.authoritative_ui_metrics.scene -ceq $sceneId -and
                    [string]$caseMetadata.authoritative_ui_metrics.visibility_policy -ceq 'is_visible_in_tree' -and
                    $authoritativeProbeCount -eq $expectedAuthoritativeProbeNames.Count -and
                    @($caseMetadata.authoritative_ui_metrics.probes).Count -eq $authoritativeProbeCount -and
                    $authoritativeProbeNamesValid -and
                    [long]$caseMetadata.authoritative_ui_metrics.actual_font_size_score -eq $authoritativeUIScaleScore -and
                    $authoritativeUIScaleScore -gt 0 -and
                    [regex]::IsMatch([string]$authoritativeMetricsSha256, '\A[0-9A-F]{64}\z') -and
                    [string]$authoritativeMetricsCalculatedSha256 -ceq [string]$authoritativeMetricsSha256 -and
                    [Math]::Abs([double]$caseMetadata.canvas_content_scale_factor - 1.0) -le 0.001 -and
                    [bool]$caseMetadata.logical_canvas_preserved -and
                    $captureFrameContractValid -and
                    -not [string]::IsNullOrWhiteSpace([string]$caseMetadata.route) -and
                    [string]$caseMetadata.png_sha256 -ceq [string]$pngSha256
                )
                $generated = (
                    -not $captureRaw.timed_out -and
                    $captureRaw.exit_code -eq 0 -and
                    $passLines.Count -eq 1 -and
                    $failLines.Count -eq 0 -and
                    $diagnostics.blocking.Count -eq 0 -and
                    $pngBytes -gt 0 -and
                    $metadataValid
                )
                [void]$captureCases.Add([pscustomobject][ordered]@{
                    id = $caseId
                    scene = $sceneId
                    resolution = $resolutionId
                    width = $width
                    height = $height
                    ui_scale_percent = [int]$uiScaleId
                    status = if ($generated) { 'GENERATED_REVIEW_REQUIRED' } else { 'FAIL' }
                    visual_acceptance = 'NOT_RUN'
                    output_path = $outputPath
                    metadata_path = $metadataPath
                    png_bytes = $pngBytes
                    png_sha256 = $pngSha256
                    effective_ui_metric_count = $effectiveMetricCount
                    effective_ui_metrics_sha256 = $effectiveMetricsSha256
                    actual_ui_scale_score = $actualUIScaleScore
                    authoritative_probe_names = @($reportedAuthoritativeProbeNames)
                    authoritative_ui_metrics_sha256 = $authoritativeMetricsSha256
                    authoritative_ui_scale_score = $authoritativeUIScaleScore
                    metadata_valid = $metadataValid
                    blocking_diagnostics = $diagnostics.blocking
                    cleanup_diagnostics = $diagnostics.cleanup
                    process = ConvertTo-I3RMatrixProcessReport -ProcessResult $captureRaw
                })
                if ($generated) {
                    Write-Output "I3R_PREVIEW_CASE=$caseId GENERATED_REVIEW_REQUIRED"
                }
                else {
                    Write-Output "I3R_PREVIEW_CASE=$caseId FAIL"
                }
            }
        }
    }
}
catch {
    $fatalError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }
}

try {
    if ($null -ne $preflightReport -and $null -ne $preflightCase -and [string]$preflightCase.status -ceq 'PASS') {
        $executionManifestPath = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot 'tools\i1\validation_manifest.json')
        $executionManifest = Get-I3RMatrixJson -Path $executionManifestPath
        $gitTimeout = [int]$executionManifest.timeouts_seconds.git_probe
        $postCaptureGit = Get-I0GitSnapshot -RepoRoot $repo -TimeoutSeconds $gitTimeout
        $postCaptureBusiness = Get-I0BusinessHashSnapshot `
            -RepoRoot $repo `
            -BusinessRoots @($executionManifest.business_roots) `
            -ExcludedDirectoryNames @($executionManifest.mirror.excluded_directory_names)
        $baselineGit = $preflightReport.pollution_guard.after_git
        $baselineBusiness = $preflightReport.pollution_guard.after_business
        $gitComparison = Compare-I0GitSnapshot -Before $baselineGit -After $postCaptureGit
        $businessUnchanged = (
            [int]$baselineBusiness.file_count -eq [int]$postCaptureBusiness.file_count -and
            [string]$baselineBusiness.fingerprint_sha256 -ceq [string]$postCaptureBusiness.fingerprint_sha256
        )
        $captureWindowPollution = [pscustomobject][ordered]@{
            status = if ([bool]$gitComparison.unchanged -and $businessUnchanged) { 'PASS' } else { 'FAIL' }
            git = $gitComparison
            business = [pscustomobject][ordered]@{
                unchanged = $businessUnchanged
                before_file_count = [int]$baselineBusiness.file_count
                after_file_count = [int]$postCaptureBusiness.file_count
                before_fingerprint_sha256 = [string]$baselineBusiness.fingerprint_sha256
                after_fingerprint_sha256 = [string]$postCaptureBusiness.fingerprint_sha256
            }
        }
    }
}
catch {
    $captureWindowPollutionError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }
}

$expectedCaseCount = $selectedScenes.Count * $selectedResolutions.Count * $selectedUIScales.Count
$failedCases = @($captureCases | Where-Object { [string]$_.status -ceq 'FAIL' })
$matrixComplete = ($captureCases.Count -eq $expectedCaseCount)
$scaleEffectChecks = New-Object System.Collections.Generic.List[object]
if ($selectedUIScales.Count -gt 1) {
    foreach ($sceneId in $selectedScenes) {
        foreach ($resolutionId in $selectedResolutions) {
            $groupCases = @($captureCases | Where-Object {
                [string]$_.scene -ceq $sceneId -and [string]$_.resolution -ceq $resolutionId
            } | Sort-Object -Property ui_scale_percent)
            $uniqueHashes = @($groupCases | Where-Object {
                -not [string]::IsNullOrWhiteSpace([string]$_.png_sha256)
            } | Select-Object -ExpandProperty png_sha256 -Unique)
            $uniqueMetricHashes = @($groupCases | Where-Object {
                -not [string]::IsNullOrWhiteSpace([string]$_.effective_ui_metrics_sha256)
            } | Select-Object -ExpandProperty effective_ui_metrics_sha256 -Unique)
            $uniqueAuthoritativeHashes = @($groupCases | Where-Object {
                -not [string]::IsNullOrWhiteSpace([string]$_.authoritative_ui_metrics_sha256)
            } | Select-Object -ExpandProperty authoritative_ui_metrics_sha256 -Unique)
            $authoritativeScoresStrictlyIncreasing = $true
            for ($scoreIndex = 1; $scoreIndex -lt $groupCases.Count; $scoreIndex++) {
                if (
                    [long]$groupCases[$scoreIndex].authoritative_ui_scale_score -le
                    [long]$groupCases[$scoreIndex - 1].authoritative_ui_scale_score
                ) {
                    $authoritativeScoresStrictlyIncreasing = $false
                    break
                }
            }
            $checkPassed = (
                $groupCases.Count -eq $selectedUIScales.Count -and
                @($groupCases | Where-Object { [string]$_.status -ceq 'FAIL' }).Count -eq 0 -and
                $uniqueAuthoritativeHashes.Count -eq $selectedUIScales.Count -and
                $authoritativeScoresStrictlyIncreasing
            )
            [void]$scaleEffectChecks.Add([pscustomobject][ordered]@{
                id = "${sceneId}__${resolutionId}"
                status = if ($checkPassed) { 'PASS' } else { 'FAIL' }
                expected_ui_scale_count = $selectedUIScales.Count
                capture_count = $groupCases.Count
                authoritative_probe_names = @($authoritativeProbeNamesByScene[$sceneId])
                unique_authoritative_ui_metrics_sha256_count = $uniqueAuthoritativeHashes.Count
                authoritative_ui_scale_scores_strictly_increasing = $authoritativeScoresStrictlyIncreasing
                unique_effective_ui_metrics_sha256_count = $uniqueMetricHashes.Count
                unique_png_sha256_count = $uniqueHashes.Count
                captures = @($groupCases | ForEach-Object {
                    [pscustomobject][ordered]@{
                        ui_scale_percent = [int]$_.ui_scale_percent
                        authoritative_ui_metrics_sha256 = [string]$_.authoritative_ui_metrics_sha256
                        authoritative_ui_scale_score = [long]$_.authoritative_ui_scale_score
                        effective_ui_metrics_sha256 = [string]$_.effective_ui_metrics_sha256
                        actual_ui_scale_score = [long]$_.actual_ui_scale_score
                        png_sha256 = [string]$_.png_sha256
                    }
                })
            })
        }
    }
}
$failedScaleEffectChecks = @($scaleEffectChecks | Where-Object { [string]$_.status -ceq 'FAIL' })
$scaleEffectPassed = ($selectedUIScales.Count -le 1 -or $failedScaleEffectChecks.Count -eq 0)
$captureWindowPollutionPassed = (
    $null -eq $captureWindowPollutionError -and
    $null -ne $captureWindowPollution -and
    [string]$captureWindowPollution.status -ceq 'PASS'
)
$overallPassed = (
    $null -eq $fatalError -and
    $matrixComplete -and
    $failedCases.Count -eq 0 -and
    $scaleEffectPassed -and
    $captureWindowPollutionPassed
)
$overallStatus = if ($overallPassed) { 'PASS_WITH_VISUAL_REVIEW_REQUIRED' } else { 'FAIL' }
$finishedUtc = [DateTime]::UtcNow
$report = [pscustomobject][ordered]@{
    schema_version = 3
    suite_id = 'I3R_production_preview_matrix'
    status = $overallStatus
    visual_acceptance = 'NOT_RUN'
    visual_acceptance_notice = 'PNG generation and structural route checks are diagnostic evidence; composition, overlap, readability, animation feel, and interaction quality still require human review.'
    production_scene_path = 'res://scenes/main/main.tscn'
    standard_run_fixed_seed = 730031
    tutorial_route = 'production_deploy_map_catalog_to_tutorial_5x5'
    execution_mode = 'isolated_i1_mirror'
    source_mode = $SourceMode
    all_matrix = [bool]$All
    selected_scenes = @($selectedScenes)
    selected_resolutions = @($selectedResolutions)
    selected_ui_scales = @($selectedUIScales | ForEach-Object { [int]$_ })
    expected_case_count = $expectedCaseCount
    generated_case_count = @($captureCases | Where-Object { [string]$_.status -ceq 'GENERATED_REVIEW_REQUIRED' }).Count
    matrix_complete = $matrixComplete
    ui_scale_effect_guard = [pscustomobject][ordered]@{
        status = if ($scaleEffectPassed) { 'PASS' } else { 'FAIL' }
        policy = 'Every selected UI scale must produce a distinct stable visible authoritative-probe SHA and a strictly increasing authoritative actual-font-size score for each scene and resolution group. Overall visible metrics and PNG SHA diversity are diagnostic only.'
        applicable = $selectedUIScales.Count -gt 1
        checks = $scaleEffectChecks.ToArray()
    }
    started_utc = $startedUtc.ToString('o')
    finished_utc = $finishedUtc.ToString('o')
    run_root = $runRoot
    mirror_root = $mirrorRoot
    evidence_root = $matrixRoot
    workspace_root = $workspaceRoot
    source = if ($null -ne $preflightReport) { $preflightReport.source } else { $null }
    mirror_fidelity = if ($null -ne $preflightReport) { $preflightReport.mirror.fidelity } else { $null }
    preflight_source_pollution_guard = if ($null -ne $preflightReport) { $preflightReport.pollution_guard } else { $null }
    capture_window_source_pollution_guard = [pscustomobject][ordered]@{
        status = if ($captureWindowPollutionPassed) { 'PASS' } else { 'FAIL' }
        result = $captureWindowPollution
        error = $captureWindowPollutionError
    }
    capture_runner = [pscustomobject][ordered]@{
        setup_path = $setupRunnerPath
        setup_sha256 = $setupRunnerSha256
        execution_path = $runnerPath
        execution_sha256 = $runnerSha256
        hashes_match = (
            -not [string]::IsNullOrWhiteSpace([string]$runnerSha256) -and
            [string]::Equals($setupRunnerSha256, $runnerSha256, [System.StringComparison]::Ordinal)
        )
    }
    invoke_script = [pscustomobject][ordered]@{
        path = $PSCommandPath
        sha256 = $setupInvokerSha256
    }
    preflight = $preflightCase
    captures = $captureCases.ToArray()
    fatal_error = $fatalError
}

if ($null -ne $matrixReportPath) {
    Write-I0Json -Value $report -Path $matrixReportPath
    Write-Output "I3R_PREVIEW_MATRIX_REPORT=$matrixReportPath"
}
elseif ($null -ne $fatalError) {
    Write-Error ("I3R production preview matrix failed before its report path was available: " + $fatalError.message)
}
Write-Output "I3R_PREVIEW_MATRIX_STATUS=$overallStatus"
if (-not $overallPassed) {
    exit 1
}
