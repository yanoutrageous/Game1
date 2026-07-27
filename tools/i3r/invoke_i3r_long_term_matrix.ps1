[CmdletBinding()]
param(
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


function Get-I3RLongTermMatrixWorkspaceRoot {
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
    throw "Unable to derive I3R long-term matrix workspace root for repo=$repoPath git_common=$gitCommon"
}


function Get-I3RLongTermMatrixMarkedValue {
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


function Get-I3RLongTermMatrixFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I3RLongTermMatrixJson {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "JSON file is missing: $Path"
    }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    return ($raw | ConvertFrom-Json)
}


function Get-I3RLongTermMatrixPngDimensions {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read
    )
    try {
        $header = New-Object byte[] 24
        $read = $stream.Read($header, 0, $header.Length)
        if ($read -ne $header.Length) {
            throw "PNG header is truncated: $Path"
        }
        $signature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
        for ($index = 0; $index -lt $signature.Length; $index += 1) {
            if ($header[$index] -ne $signature[$index]) {
                throw "File does not have a valid PNG signature: $Path"
            }
        }
        $chunkType = [System.Text.Encoding]::ASCII.GetString($header, 12, 4)
        if ($chunkType -cne 'IHDR') {
            throw "PNG does not begin with an IHDR chunk: $Path"
        }
        $width = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($header, 16))
        $height = [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($header, 20))
        if ($width -le 0 -or $height -le 0) {
            throw "PNG has invalid dimensions ${width}x${height}: $Path"
        }
        return [pscustomobject][ordered]@{
            width = $width
            height = $height
        }
    }
    finally {
        $stream.Dispose()
    }
}


function ConvertTo-I3RLongTermMatrixProcessReport {
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


function Get-I3RLongTermMatrixLogText {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return Get-Content -LiteralPath $Path -Raw
    }
    return ''
}


function Get-I3RLongTermMatrixDiagnostics {
    param([Parameter(Mandatory = $true)][string]$Text)

    $blocking = New-Object System.Collections.Generic.List[string]
    $cleanup = New-Object System.Collections.Generic.List[string]
    $seen = New-Object System.Collections.Generic.List[string]
    foreach ($match in @([regex]::Matches($Text, '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$'))) {
        $diagnostic = $match.Value.Trim()
        if (@($seen | Where-Object {
            [string]::Equals([string]$_, $diagnostic, [System.StringComparison]::Ordinal)
        }).Count -gt 0) {
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
    throw "I3R long-term matrix requires Windows PowerShell 5.1 Desktop; current=$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
}

$requestedRepo = Get-I0CanonicalPath -Path $RepoRoot
$resolvedRepoResult = Invoke-I0Git -RepoRoot $requestedRepo -Arguments @('rev-parse', '--show-toplevel')
$repo = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $resolvedRepoResult.stdout)
if (-not [string]::Equals($requestedRepo, $repo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RepoRoot must be the active Git worktree root: requested=$requestedRepo resolved=$repo"
}
$workspaceRoot = Get-I3RLongTermMatrixWorkspaceRoot -RepoRoot $repo
[void](Set-I0WorkspaceRoot -Path $workspaceRoot)

$setupRunnerPath = Get-I0CanonicalPath -Path (
    Join-Path $repo 'Godot\GraytailGodot\tests\art23_long_term_matrix_capture_runner.gd'
)
if (-not (Test-Path -LiteralPath $setupRunnerPath -PathType Leaf)) {
    throw "Current long-term matrix runner is missing: $setupRunnerPath"
}
$setupRunnerSha256 = Get-I3RLongTermMatrixFileSha256 -Path $setupRunnerPath
$setupInvokerSha256 = Get-I3RLongTermMatrixFileSha256 -Path $PSCommandPath

$resolutions = @(
    [pscustomobject][ordered]@{ id = '1280x720'; width = 1280; height = 720 },
    [pscustomobject][ordered]@{ id = '1366x768'; width = 1366; height = 768 },
    [pscustomobject][ordered]@{ id = '1600x900'; width = 1600; height = 900 },
    [pscustomobject][ordered]@{ id = '1920x1080'; width = 1920; height = 1080 },
    [pscustomobject][ordered]@{ id = '2560x1440'; width = 2560; height = 1440 }
)
$stateIds = @(
    'task_archive__task',
    'task_archive__achievement',
    'task_archive__commission_record',
    'codex__map',
    'codex__monster',
    'codex__collectible',
    'codex__equipment',
    'codex__consumable',
    'codex__event',
    'codex__rule',
    'codex__lore',
    'research__unlock_interface',
    'research__research_entry',
    'talent__tree',
    'profile__qualification_level',
    'profile__history',
    'profile__statistics',
    'profile__milestone',
    'profile__title',
    'profile__badge',
    'collection_appearance__unique_display',
    'collection_appearance__appearance_config',
    'collection_appearance__display_content',
    'collection_appearance__badge_title',
    'collection_appearance__settlement_display'
)
$expectedMarkerCount = $resolutions.Count
$expectedPngCount = $resolutions.Count * $stateIds.Count

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
    $preflightReportPath = Get-I3RLongTermMatrixMarkedValue `
        -Text $preflightText `
        -Marker 'I1_REPORT_JSON='
    $preflightReportPath = Get-I0CanonicalPath -Path $preflightReportPath
    $preflightReport = Get-I3RLongTermMatrixJson -Path $preflightReportPath
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
        report_sha256 = Get-I3RLongTermMatrixFileSha256 -Path $preflightReportPath
        process = ConvertTo-I3RLongTermMatrixProcessReport -ProcessResult $preflightRaw
    }

    $runRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.run_root)
    $mirrorRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.mirror_root)
    Assert-I0PathWithin -Path $mirrorRoot -Root $runRoot -Label 'I3R long-term matrix mirror'
    $matrixRoot = Get-I0CanonicalPath -Path (Join-Path $runRoot 'i3r_long_term_matrix')
    Assert-I0PathWithin -Path $matrixRoot -Root $runRoot -Label 'I3R long-term matrix evidence'
    if (Test-I0PathWithin -Path $matrixRoot -Root $mirrorRoot -AllowRoot) {
        throw "I3R long-term matrix evidence must not be written inside the mirror: $matrixRoot"
    }
    $matrixReportPath = Get-I0CanonicalPath -Path (Join-Path $matrixRoot 'matrix_manifest.json')
    [void](New-Item -ItemType Directory -Path $matrixRoot -Force)
    if (-not $preflightPassed) {
        throw 'I1 isolated preflight did not pass; current long-term matrix capture was not started'
    }

    $projectRoot = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot 'Godot\GraytailGodot')
    $runnerPath = Get-I0CanonicalPath -Path (
        Join-Path $projectRoot 'tests\art23_long_term_matrix_capture_runner.gd'
    )
    $godotConsole = Get-I0CanonicalPath -Path (
        [string]$preflightReport.gates.runtime_links.console_executable.hardlink
    )
    foreach ($requiredPath in @($projectRoot, $runnerPath, $godotConsole)) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "I3R long-term matrix dependency is missing: $requiredPath"
        }
    }
    $runnerSha256 = Get-I3RLongTermMatrixFileSha256 -Path $runnerPath
    if (-not [string]::Equals($setupRunnerSha256, $runnerSha256, [System.StringComparison]::Ordinal)) {
        throw "Long-term matrix runner changed while the isolated mirror was prepared: setup=$setupRunnerSha256 mirror=$runnerSha256"
    }

    foreach ($resolution in $resolutions) {
        $resolutionId = [string]$resolution.id
        $width = [int]$resolution.width
        $height = [int]$resolution.height
        $caseRoot = Get-I0CanonicalPath -Path (Join-Path $matrixRoot $resolutionId)
        Assert-I0PathWithin -Path $caseRoot -Root $matrixRoot -Label 'I3R long-term matrix case'
        [void](New-Item -ItemType Directory -Path $caseRoot -Force)
        $logPath = Get-I0CanonicalPath -Path (Join-Path $caseRoot 'godot.log')
        $environment = New-I0ProcessEnvironment `
            -RunRoot $runRoot `
            -CaseId ("I3R_LONG_TERM_" + $resolutionId)
        $captureRaw = Invoke-I0Process `
            -FilePath $godotConsole `
            -Arguments @(
                '--display-driver', 'windows',
                '--rendering-driver', 'opengl3',
                '--rendering-method', 'gl_compatibility',
                '--audio-driver', 'Dummy',
                '--path', $projectRoot,
                '--log-file', $logPath,
                '--script', 'res://tests/art23_long_term_matrix_capture_runner.gd',
                '--',
                "--width=$width",
                "--height=$height",
                "--output-dir=$caseRoot"
            ) `
            -WorkingDirectory $projectRoot `
            -Environment $environment `
            -TimeoutSeconds 900

        $markerText = $captureRaw.stdout + "`n" + $captureRaw.stderr
        $allLogText = $markerText + "`n" + (Get-I3RLongTermMatrixLogText -Path $logPath)
        $diagnostics = Get-I3RLongTermMatrixDiagnostics -Text $allLogText
        $expectedMarkerPattern = (
            '^ART23_MATRIX_CAPTURE=PASS states=25 size=' +
            [regex]::Escape("${width}x${height}") +
            ' output=(.+)$'
        )
        $allPassMarkerLines = @((Normalize-I0ProcessText -Text $markerText) -split "`n" | Where-Object {
            $_.Trim().StartsWith('ART23_MATRIX_CAPTURE=PASS', [System.StringComparison]::Ordinal)
        })
        $matchingPassMarkerLines = @($allPassMarkerLines | Where-Object {
            $_.Trim() -match $expectedMarkerPattern
        })
        $markerOutputMatches = $false
        if ($matchingPassMarkerLines.Count -eq 1) {
            $markerMatch = [regex]::Match($matchingPassMarkerLines[0].Trim(), $expectedMarkerPattern)
            if ($markerMatch.Success) {
                $markerOutputPath = Get-I0CanonicalPath -Path $markerMatch.Groups[1].Value
                $markerOutputMatches = [string]::Equals(
                    $markerOutputPath,
                    $caseRoot,
                    [System.StringComparison]::OrdinalIgnoreCase
                )
            }
        }

        $expectedNames = @($stateIds | ForEach-Object {
            "${_}__${width}x${height}.png"
        })
        $actualFiles = @(Get-ChildItem -LiteralPath $caseRoot -File -Filter '*.png' | Sort-Object -Property Name)
        $actualNames = @($actualFiles | Select-Object -ExpandProperty Name)
        $missingNames = @($expectedNames | Where-Object { $actualNames -cnotcontains $_ })
        $unexpectedNames = @($actualNames | Where-Object { $expectedNames -cnotcontains $_ })
        $imageReports = New-Object System.Collections.Generic.List[object]
        foreach ($expectedName in $expectedNames) {
            $imagePath = Get-I0CanonicalPath -Path (Join-Path $caseRoot $expectedName)
            $present = Test-Path -LiteralPath $imagePath -PathType Leaf
            $bytes = if ($present) { (Get-Item -LiteralPath $imagePath).Length } else { 0 }
            $sha256 = if ($bytes -gt 0) {
                Get-I3RLongTermMatrixFileSha256 -Path $imagePath
            }
            else {
                $null
            }
            $dimensions = $null
            $dimensionError = $null
            if ($bytes -gt 0) {
                try {
                    $dimensions = Get-I3RLongTermMatrixPngDimensions -Path $imagePath
                }
                catch {
                    $dimensionError = $_.Exception.Message
                }
            }
            $dimensionsMatch = (
                $null -ne $dimensions -and
                [int]$dimensions.width -eq $width -and
                [int]$dimensions.height -eq $height
            )
            $valid = (
                $present -and
                $bytes -gt 0 -and
                -not [string]::IsNullOrWhiteSpace([string]$sha256) -and
                $dimensionsMatch
            )
            [void]$imageReports.Add([pscustomobject][ordered]@{
                file_name = $expectedName
                path = $imagePath
                status = if ($valid) { 'PASS' } else { 'FAIL' }
                bytes = $bytes
                sha256 = $sha256
                width = if ($null -ne $dimensions) { [int]$dimensions.width } else { $null }
                height = if ($null -ne $dimensions) { [int]$dimensions.height } else { $null }
                dimensions_match = $dimensionsMatch
                dimension_error = $dimensionError
            })
        }

        $failedImages = @($imageReports | Where-Object { [string]$_.status -ceq 'FAIL' })
        $casePassed = (
            -not $captureRaw.timed_out -and
            $captureRaw.exit_code -eq 0 -and
            $allPassMarkerLines.Count -eq 1 -and
            $matchingPassMarkerLines.Count -eq 1 -and
            $markerOutputMatches -and
            $diagnostics.blocking.Count -eq 0 -and
            $actualFiles.Count -eq $stateIds.Count -and
            $missingNames.Count -eq 0 -and
            $unexpectedNames.Count -eq 0 -and
            $failedImages.Count -eq 0
        )
        [void]$captureCases.Add([pscustomobject][ordered]@{
            id = $resolutionId
            width = $width
            height = $height
            status = if ($casePassed) { 'GENERATED_REVIEW_REQUIRED' } else { 'FAIL' }
            visual_acceptance = 'NOT_RUN'
            output_root = $caseRoot
            expected_png_count = $stateIds.Count
            observed_png_count = $actualFiles.Count
            valid_png_count = @($imageReports | Where-Object { [string]$_.status -ceq 'PASS' }).Count
            pass_marker_count = $allPassMarkerLines.Count
            pass_marker = if ($matchingPassMarkerLines.Count -eq 1) {
                $matchingPassMarkerLines[0].Trim()
            }
            else {
                $null
            }
            marker_output_matches = $markerOutputMatches
            missing_png = $missingNames
            unexpected_png = $unexpectedNames
            blocking_diagnostics = $diagnostics.blocking
            cleanup_diagnostics = $diagnostics.cleanup
            images = $imageReports.ToArray()
            process = ConvertTo-I3RLongTermMatrixProcessReport -ProcessResult $captureRaw
        })
        Write-Output (
            "I3R_LONG_TERM_MATRIX_CASE=$resolutionId " +
            "$(if ($casePassed) { 'GENERATED_REVIEW_REQUIRED' } else { 'FAIL' }) " +
            "generated=$(@($imageReports | Where-Object { [string]$_.status -ceq 'PASS' }).Count) " +
            "expected=$($stateIds.Count)"
        )
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
        $executionManifestPath = Get-I0CanonicalPath -Path (
            Join-Path $mirrorRoot 'tools\i1\validation_manifest.json'
        )
        $executionManifest = Get-I3RLongTermMatrixJson -Path $executionManifestPath
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

$failedCases = @($captureCases | Where-Object { [string]$_.status -ceq 'FAIL' })
$passMarkerCount = ($captureCases | Measure-Object -Property pass_marker_count -Sum).Sum
if ($null -eq $passMarkerCount) {
    $passMarkerCount = 0
}
$observedPngCount = ($captureCases | Measure-Object -Property observed_png_count -Sum).Sum
if ($null -eq $observedPngCount) {
    $observedPngCount = 0
}
$generatedPngCount = ($captureCases | Measure-Object -Property valid_png_count -Sum).Sum
if ($null -eq $generatedPngCount) {
    $generatedPngCount = 0
}
$captureWindowPollutionPassed = (
    $null -eq $captureWindowPollutionError -and
    $null -ne $captureWindowPollution -and
    [string]$captureWindowPollution.status -ceq 'PASS'
)
$matrixComplete = (
    $captureCases.Count -eq $resolutions.Count -and
    $failedCases.Count -eq 0 -and
    [int]$passMarkerCount -eq $expectedMarkerCount -and
    [int]$observedPngCount -eq $expectedPngCount -and
    [int]$generatedPngCount -eq $expectedPngCount
)
$overallPassed = (
    $null -eq $fatalError -and
    $null -ne $preflightCase -and
    [string]$preflightCase.status -ceq 'PASS' -and
    $matrixComplete -and
    $captureWindowPollutionPassed
)
$overallStatus = if ($overallPassed) { 'PASS_WITH_VISUAL_REVIEW_REQUIRED' } else { 'FAIL' }
$finishedUtc = [DateTime]::UtcNow

$report = [pscustomobject][ordered]@{
    schema_version = 1
    suite_id = 'I3R_current_long_term_matrix'
    status = $overallStatus
    visual_acceptance = 'NOT_RUN'
    visual_acceptance_notice = 'Structural capture success does not replace human review of hierarchy, overlap, readability, material coherence, or interaction feel.'
    historical_art23_boundary = 'The preserved art23 runner filename is reused only to capture the current runtime shell. Output is transient I3R evidence under the I1 run root and does not create or rewrite historical ART23 evidence.'
    execution_mode = 'isolated_i1_mirror'
    source_mode = $SourceMode
    resolutions = @($resolutions | ForEach-Object { [string]$_.id })
    expected_state_ids = $stateIds
    expected_resolution_count = $resolutions.Count
    expected_state_count_per_resolution = $stateIds.Count
    expected_pass_marker_count = $expectedMarkerCount
    pass_marker_count = [int]$passMarkerCount
    expected_png_count = $expectedPngCount
    observed_png_count = [int]$observedPngCount
    generated_png_count = [int]$generatedPngCount
    matrix_complete = $matrixComplete
    started_utc = $startedUtc.ToString('o')
    finished_utc = $finishedUtc.ToString('o')
    run_root = $runRoot
    mirror_root = $mirrorRoot
    evidence_root = $matrixRoot
    workspace_root = $workspaceRoot
    source = if ($null -ne $preflightReport) { $preflightReport.source } else { $null }
    mirror_fidelity = if ($null -ne $preflightReport) { $preflightReport.mirror.fidelity } else { $null }
    preflight_source_pollution_guard = if ($null -ne $preflightReport) {
        $preflightReport.pollution_guard
    }
    else {
        $null
    }
    capture_window_source_pollution_guard = [pscustomobject][ordered]@{
        status = if ($captureWindowPollutionPassed) { 'PASS' } else { 'FAIL' }
        result = $captureWindowPollution
        error = $captureWindowPollutionError
    }
    capture_runner = [pscustomobject][ordered]@{
        resource_path = 'res://tests/art23_long_term_matrix_capture_runner.gd'
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
    Write-Output "I3R_LONG_TERM_MATRIX_REPORT=$matrixReportPath"
}
elseif ($null -ne $fatalError) {
    Write-Error ("I3R long-term matrix failed before its report path was available: " + $fatalError.message)
}
Write-Output (
    "I3R_LONG_TERM_MATRIX_STATUS=$overallStatus " +
    "generated=$([int]$generatedPngCount) expected=$expectedPngCount"
)
if (-not $overallPassed) {
    exit 1
}
