param(
    [string]$Scene = "run",

    [string]$Resolution = "1280x720",

    [switch]$All,

    [ValidateSet("worktree", "head")]
    [string]$SourceMode = "worktree",

    [string]$RepoRoot = ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))),

    [string]$GodotExe = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1")


function Get-I1PreviewWorkspaceRoot {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $repo = Get-I0CanonicalPath -Path $RepoRoot
    $commonResult = Invoke-I0Git -RepoRoot $repo -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir')
    $gitCommon = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $commonResult.stdout)
    $candidate = $repo
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-I0PathWithin -Path $gitCommon -Root $candidate -AllowRoot) {
            return $candidate
        }
        $parent = Split-Path -Parent $candidate
        if ([string]::IsNullOrWhiteSpace($parent) -or [string]::Equals($parent, $candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $candidate = Get-I0CanonicalPath -Path $parent
    }
    throw "Unable to derive preview workspace root for repo=$repo git_common=$gitCommon"
}


function ConvertTo-I1PreviewProcessReport {
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


function Get-I1PreviewMarkedValue {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    $lines = @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.StartsWith($Marker, [System.StringComparison]::Ordinal) })
    if ($lines.Count -ne 1) {
        throw "Expected exactly one $Marker line, found $($lines.Count)"
    }
    return $lines[0].Substring($Marker.Length)
}


function Get-I1PreviewFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I1PreviewJsonFileSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "JSON file is missing: $Path"
    }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $algorithm.ComputeHash($bytes)
    }
    finally {
        $algorithm.Dispose()
    }
    $sha256 = -join @($hashBytes | ForEach-Object { $_.ToString('X2') })
    $raw = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) {
        $raw = $raw.Substring(1)
    }
    return [pscustomobject][ordered]@{
        raw = $raw
        sha256 = $sha256
        value = ($raw | ConvertFrom-Json)
    }
}


function Get-I1PreviewExactLineCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$ExpectedLine
    )
    return @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.Trim() -ceq $ExpectedLine }).Count
}


function Get-I1PreviewFailLineCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    return @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.Trim().StartsWith($Marker, [System.StringComparison]::Ordinal) }).Count
}


function Get-I1PreviewDiagnostics {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [object[]]$ExpectedCleanupDiagnostics = @()
    )
    $blocking = New-Object System.Collections.Generic.List[string]
    $cleanup = New-Object System.Collections.Generic.List[string]
    $missingExpected = New-Object System.Collections.Generic.List[string]
    $expectedValues = @($ExpectedCleanupDiagnostics | ForEach-Object { [string]$_ })
    $acceptedExpected = New-Object System.Collections.Generic.List[string]
    foreach ($expectedValue in $ExpectedCleanupDiagnostics) {
        $expected = [string]$expectedValue
        if (@($acceptedExpected | Where-Object { [string]::Equals([string]$_, $expected, [System.StringComparison]::Ordinal) }).Count -gt 0) {
            throw "Duplicate expected preview cleanup diagnostic: $expected"
        }
        [void]$acceptedExpected.Add($expected)
    }
    $seen = New-Object System.Collections.Generic.List[string]
    foreach ($match in @([regex]::Matches($Text, '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$'))) {
        $diagnostic = $match.Value.Trim()
        if (@($seen | Where-Object { [string]::Equals([string]$_, $diagnostic, [System.StringComparison]::Ordinal) }).Count -gt 0) {
            continue
        }
        [void]$seen.Add($diagnostic)
        if (@($expectedValues | Where-Object { [string]::Equals([string]$_, $diagnostic, [System.StringComparison]::Ordinal) }).Count -gt 0) {
            [void]$cleanup.Add($diagnostic)
        }
        else {
            [void]$blocking.Add($diagnostic)
        }
    }
    foreach ($expected in $expectedValues) {
        if (@($seen | Where-Object { [string]::Equals([string]$_, $expected, [System.StringComparison]::Ordinal) }).Count -eq 0) {
            [void]$missingExpected.Add($expected)
        }
    }
    return [pscustomobject][ordered]@{
        expected_cleanup_diagnostics = $expectedValues
        blocking = $blocking.ToArray()
        cleanup = $cleanup.ToArray()
        missing_expected_cleanup_diagnostics = $missingExpected.ToArray()
        cleanup_contract_matches = ($missingExpected.Count -eq 0)
    }
}


function Get-I1PreviewLogText {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return Get-Content -LiteralPath $Path -Raw
    }
    return ''
}


if ($PSVersionTable.PSEdition -cne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -lt 1) {
    throw "I1 production preview requires Windows PowerShell 5.1 Desktop; current=$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
}

$requestedRepo = Get-I0CanonicalPath -Path $RepoRoot
$resolvedRepoResult = Invoke-I0Git -RepoRoot $requestedRepo -Arguments @('rev-parse', '--show-toplevel')
$repo = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $resolvedRepoResult.stdout)
if (-not [string]::Equals($requestedRepo, $repo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RepoRoot must be the active Git worktree root: requested=$requestedRepo resolved=$repo"
}
$workspaceRoot = Get-I1PreviewWorkspaceRoot -RepoRoot $repo
[void](Set-I0WorkspaceRoot -Path $workspaceRoot)
Assert-I0PathWithin -Path $repo -Root $workspaceRoot -AllowRoot -Label 'active repo'
Assert-I0NoReparseExistingAncestor -Path $repo -Root $workspaceRoot -Label 'active repo'

$manifestPath = Join-Path $repo 'tools\i1\validation_manifest.json'
$setupManifestSnapshot = Get-I1PreviewJsonFileSnapshot -Path $manifestPath
$setupManifestSha256 = [string]$setupManifestSnapshot.sha256
$manifest = $setupManifestSnapshot.value
if ([int]$manifest.schema_version -ne 1 -or [string]$manifest.suite_id -cne 'I1-V1_unified_headless_baseline') {
    throw 'Unsupported I1 manifest identity'
}
$setupControlPlaneFiles = @(
    [pscustomobject][ordered]@{
        relative_path = '.gitattributes'
        setup_path = Get-I0CanonicalPath -Path (Join-Path $repo '.gitattributes')
        setup_sha256 = Get-I1PreviewFileSha256 -Path (Join-Path $repo '.gitattributes')
    },
    [pscustomobject][ordered]@{
        relative_path = 'tools/i1/invoke_i1_preview.ps1'
        setup_path = Get-I0CanonicalPath -Path $PSCommandPath
        setup_sha256 = Get-I1PreviewFileSha256 -Path $PSCommandPath
    },
    [pscustomobject][ordered]@{
        relative_path = 'tools/i1/invoke_i1.ps1'
        setup_path = Get-I0CanonicalPath -Path (Join-Path $repo 'tools\i1\invoke_i1.ps1')
        setup_sha256 = Get-I1PreviewFileSha256 -Path (Join-Path $repo 'tools\i1\invoke_i1.ps1')
    },
    [pscustomobject][ordered]@{
        relative_path = 'tools/i0/i0_test_lib.ps1'
        setup_path = Get-I0CanonicalPath -Path (Join-Path $repo 'tools\i0\i0_test_lib.ps1')
        setup_sha256 = Get-I1PreviewFileSha256 -Path (Join-Path $repo 'tools\i0\i0_test_lib.ps1')
    }
)

$allScenes = @('main_menu', 'deploy', 'long_term', 'run', 'combat', 'inventory', 'map', 'result_success', 'result_failure')
$allResolutions = @('1280x720', '1600x900', '1920x1080')
$requestedScenes = @($Scene.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
$requestedResolutions = @($Resolution.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
foreach ($sceneId in $requestedScenes) {
    if ($allScenes -cnotcontains $sceneId) {
        throw "Unsupported preview scene: $sceneId"
    }
}
foreach ($resolutionId in $requestedResolutions) {
    if ($allResolutions -cnotcontains $resolutionId) {
        throw "Unsupported preview resolution: $resolutionId"
    }
}
if ($All) {
    $selectedScenes = @($allScenes)
    $selectedResolutions = @($allResolutions)
}
else {
    $selectedScenes = @($requestedScenes)
    $selectedResolutions = @($requestedResolutions)
}
if ($selectedScenes.Count -eq 0) {
    throw 'At least one preview scene must be selected'
}
if ($selectedResolutions.Count -eq 0) {
    throw 'At least one preview resolution must be selected'
}
$resolutionMap = @{
    '1280x720' = @(1280, 720)
    '1600x900' = @(1600, 900)
    '1920x1080' = @(1920, 1080)
}

$startedUtc = [DateTime]::UtcNow
$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$beforeGit = $null
$afterGit = $null
$beforeBusiness = $null
$afterBusiness = $null
$gitPollution = $null
$businessPollution = $null
$pollutionError = $null
$fatalError = $null
$preflightCase = $null
$preflightReport = $null
$preflightReportSha256 = $null
$runRoot = $null
$mirrorRoot = $null
$executionManifestPath = $null
$executionManifestSha256 = $null
$executionManifest = $null
$manifestHashesMatch = $false
$controlPlaneBindings = @()
$controlPlaneBindingPass = $false
$runnerPath = $null
$captureRunnerSha256 = $null
$previewReportPath = $null
$captureCases = New-Object System.Collections.Generic.List[object]
$overallStatus = 'FAIL'

try {
    $gitTimeout = [int]$manifest.timeouts_seconds.git_probe
    $beforeGit = Get-I0GitSnapshot -RepoRoot $repo -TimeoutSeconds $gitTimeout
    $beforeBusiness = Get-I0BusinessHashSnapshot -RepoRoot $repo -BusinessRoots @($manifest.business_roots) -ExcludedDirectoryNames @($manifest.mirror.excluded_directory_names)

    $preflightScript = Join-Path $repo 'tools\i1\invoke_i1.ps1'
    $preflightArguments = @(
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $preflightScript,
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
    $preflightReportPath = Get-I1PreviewMarkedValue -Text $preflightText -Marker 'I1_REPORT_JSON='
    $preflightReportPath = Get-I0CanonicalPath -Path $preflightReportPath
    Assert-I0PathWithin -Path $preflightReportPath -Root (Join-Path $repo '.tmp\i1') -Label 'I1 preflight report'
    if (-not (Test-Path -LiteralPath $preflightReportPath -PathType Leaf)) {
        throw "I1 preflight report is missing: $preflightReportPath"
    }
    $preflightReportSnapshot = Get-I1PreviewJsonFileSnapshot -Path $preflightReportPath
    $preflightReportSha256 = [string]$preflightReportSnapshot.sha256
    $preflightReport = $preflightReportSnapshot.value
    $preflightPassed = (
        -not $preflightRaw.timed_out -and
        $preflightRaw.exit_code -eq 0 -and
        [string]$preflightReport.suite_id -ceq 'I1-V1_unified_headless_baseline' -and
        [string]$preflightReport.profile -ceq 'preflight' -and
        [string]$preflightReport.source_mode -ceq $SourceMode -and
        [string]$preflightReport.overall_status -ceq 'PASS' -and
        [string]$preflightReport.manifest_binding.status -ceq 'PASS' -and
        [string]$preflightReport.control_plane_binding.status -ceq 'PASS'
    )
    $preflightCase = [pscustomobject][ordered]@{
        status = if ($preflightPassed) { 'PASS' } else { 'FAIL' }
        report_path = $preflightReportPath
        report_sha256 = $preflightReportSha256
        process = ConvertTo-I1PreviewProcessReport -ProcessResult $preflightRaw
    }
    if (-not $preflightPassed) {
        throw 'I1 preflight did not pass; production preview was not started'
    }

    $runRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.run_root)
    $mirrorRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.mirror_root)
    Assert-I0PathWithin -Path $mirrorRoot -Root $runRoot -Label 'preview mirror'
    $expectedPreflightReportPath = Get-I0CanonicalPath -Path (Join-Path $runRoot 'report.json')
    if (-not [string]::Equals($preflightReportPath, $expectedPreflightReportPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Preflight report path does not belong to its reported run root: $preflightReportPath"
    }

    $executionManifestPath = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot 'tools\i1\validation_manifest.json')
    $executionManifestSnapshot = Get-I1PreviewJsonFileSnapshot -Path $executionManifestPath
    $executionManifestSha256 = [string]$executionManifestSnapshot.sha256
    $executionManifest = $executionManifestSnapshot.value
    $manifestHashesMatch = [string]::Equals($setupManifestSha256, $executionManifestSha256, [System.StringComparison]::Ordinal)
    if (-not $manifestHashesMatch -or -not [string]::Equals([string]$preflightReport.manifest_binding.execution_sha256, $executionManifestSha256, [System.StringComparison]::Ordinal)) {
        throw "Preview manifest binding failed: setup=$setupManifestSha256 execution=$executionManifestSha256 preflight=$($preflightReport.manifest_binding.execution_sha256)"
    }
    if ([int]$executionManifest.schema_version -ne 1 -or [string]$executionManifest.suite_id -cne 'I1-V1_unified_headless_baseline' -or [string]$executionManifest.path_policy -cne 'runtime_parameters') {
        throw 'Mirrored preview manifest has an unsupported identity'
    }

    $controlPlaneBindings = @($setupControlPlaneFiles | ForEach-Object {
        $executionPath = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot (([string]$_.relative_path).Replace('/', '\')))
        Assert-I0PathWithin -Path $executionPath -Root $mirrorRoot -Label 'mirrored preview control-plane input'
        $executionSha256 = Get-I1PreviewFileSha256 -Path $executionPath
        [pscustomobject][ordered]@{
            relative_path = [string]$_.relative_path
            setup_path = [string]$_.setup_path
            setup_sha256 = [string]$_.setup_sha256
            execution_path = $executionPath
            execution_sha256 = $executionSha256
            hashes_match = [string]::Equals([string]$_.setup_sha256, $executionSha256, [System.StringComparison]::Ordinal)
        }
    })
    $controlPlaneBindingPass = (@($controlPlaneBindings | Where-Object { -not [bool]$_.hashes_match }).Count -eq 0)
    if (-not $controlPlaneBindingPass) {
        $mismatches = @($controlPlaneBindings | Where-Object { -not [bool]$_.hashes_match } | ForEach-Object { [string]$_.relative_path })
        throw ("Preview {0} control-plane binding failed: {1}" -f $SourceMode, ($mismatches -join ', '))
    }
    $manifest = $executionManifest

    $previewRoot = Join-Path $runRoot 'previews'
    $previewLogsRoot = Join-Path $runRoot 'logs\preview'
    $previewReportPath = Join-Path $runRoot 'preview_report.json'
    foreach ($path in @($previewRoot, $previewLogsRoot, $previewReportPath)) {
        Assert-I0PathWithin -Path $path -Root $runRoot -Label 'preview output'
        Assert-I0NoReparseExistingAncestor -Path $path -Root $workspaceRoot -Label 'preview output'
    }
    [void](New-Item -ItemType Directory -Path $previewRoot -Force)
    [void](New-Item -ItemType Directory -Path $previewLogsRoot -Force)

    $projectRoot = Join-Path $mirrorRoot (([string]$manifest.godot.project_relative_path).Replace('/', '\'))
    $runnerPath = Join-Path $mirrorRoot 'Godot\GraytailGodot\tests\i1_production_preview_capture_runner.gd'
    $godotConsole = Get-I0CanonicalPath -Path ([string]$preflightReport.gates.runtime_links.console_executable.hardlink)
    foreach ($path in @($projectRoot, $runnerPath, $godotConsole)) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Preview dependency is missing: $path"
        }
    }
    $captureRunnerSha256 = Get-I1PreviewFileSha256 -Path $runnerPath

    foreach ($sceneId in $selectedScenes) {
        foreach ($resolutionId in $selectedResolutions) {
            $dimensions = @($resolutionMap[$resolutionId])
            $width = [int]$dimensions[0]
            $height = [int]$dimensions[1]
            $caseId = "preview_${sceneId}_${resolutionId}"
            $outputPath = Get-I0CanonicalPath -Path (Join-Path $previewRoot ("{0}__{1}.png" -f $sceneId, $resolutionId))
            $logPath = Join-Path $previewLogsRoot ($caseId + '.log')
            $environment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId $caseId
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
                    "--output=$outputPath"
                ) `
                -WorkingDirectory $projectRoot `
                -Environment $environment `
                -TimeoutSeconds 240
            $markerText = $captureRaw.stdout + "`n" + $captureRaw.stderr
            $diagnosticText = $markerText + "`n" + (Get-I1PreviewLogText -Path $logPath)
            $cleanupProperty = $manifest.diagnostics.preview_capture_expected_cleanup_diagnostics_by_scene.PSObject.Properties[$sceneId]
            if ($null -eq $cleanupProperty) {
                throw "Preview cleanup contract is missing: $sceneId"
            }
            $expectedCleanup = @($cleanupProperty.Value | ForEach-Object { [string]$_ })
            $diagnostics = Get-I1PreviewDiagnostics -Text $diagnosticText -ExpectedCleanupDiagnostics $expectedCleanup
            $expectedMarker = "I1_PRODUCTION_PREVIEW=PASS scene=$sceneId size=${width}x${height} output=$outputPath"
            $passMarkerCount = Get-I1PreviewExactLineCount -Text $markerText -ExpectedLine $expectedMarker
            $failMarkerCount = Get-I1PreviewFailLineCount -Text $markerText -Marker 'I1_PRODUCTION_PREVIEW=FAIL'
            $pngPresent = Test-Path -LiteralPath $outputPath -PathType Leaf
            $pngBytes = if ($pngPresent) { (Get-Item -LiteralPath $outputPath).Length } else { 0 }
            $pngSha256 = if ($pngPresent -and $pngBytes -gt 0) { Get-I1PreviewFileSha256 -Path $outputPath } else { $null }
            $generated = (-not $captureRaw.timed_out -and $captureRaw.exit_code -eq 0 -and $passMarkerCount -eq 1 -and $failMarkerCount -eq 0 -and $diagnostics.blocking.Count -eq 0 -and $diagnostics.cleanup_contract_matches -and $pngPresent -and $pngBytes -gt 0 -and -not [string]::IsNullOrWhiteSpace($pngSha256))
            [void]$captureCases.Add([pscustomobject][ordered]@{
                scene = $sceneId
                resolution = $resolutionId
                width = $width
                height = $height
                status = if ($generated) { 'GENERATED_REVIEW_REQUIRED' } else { 'FAIL' }
                visual_acceptance = 'NOT_RUN'
                output_path = $outputPath
                png_bytes = $pngBytes
                png_sha256 = $pngSha256
                expected_marker = $expectedMarker
                pass_marker_line_count = $passMarkerCount
                fail_marker_line_count = $failMarkerCount
                expected_cleanup_diagnostics = $diagnostics.expected_cleanup_diagnostics
                blocking_diagnostics = $diagnostics.blocking
                cleanup_diagnostics = $diagnostics.cleanup
                missing_expected_cleanup_diagnostics = $diagnostics.missing_expected_cleanup_diagnostics
                cleanup_contract_matches = $diagnostics.cleanup_contract_matches
                process = ConvertTo-I1PreviewProcessReport -ProcessResult $captureRaw
            })
            if ($generated) {
                Write-Output $expectedMarker
            }
            else {
                Write-Output ("I1_PRODUCTION_PREVIEW=FAIL scene={0} size={1}x{2}" -f $sceneId, $width, $height)
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
    if ($null -ne $beforeGit) {
        $afterGit = Get-I0GitSnapshot -RepoRoot $repo -TimeoutSeconds ([int]$manifest.timeouts_seconds.git_probe)
        $gitPollution = Compare-I0GitSnapshot -Before $beforeGit -After $afterGit
    }
    if ($null -ne $beforeBusiness) {
        $afterBusiness = Get-I0BusinessHashSnapshot -RepoRoot $repo -BusinessRoots @($manifest.business_roots) -ExcludedDirectoryNames @($manifest.mirror.excluded_directory_names)
        $businessPollution = Compare-I0BusinessHashSnapshot -Before $beforeBusiness -After $afterBusiness
    }
}
catch {
    $pollutionError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }
}

$failedCaptures = @($captureCases | Where-Object { [string]$_.status -ceq 'FAIL' })
$expectedCaptureCount = $selectedScenes.Count * $selectedResolutions.Count
$captureSetComplete = ($captureCases.Count -eq $expectedCaptureCount)
$pollutionPassed = ($null -eq $pollutionError -and $null -ne $gitPollution -and [bool]$gitPollution.unchanged -and $null -ne $businessPollution -and [bool]$businessPollution.unchanged)
$overallPassed = ($null -eq $fatalError -and $manifestHashesMatch -and $controlPlaneBindingPass -and $captureSetComplete -and $failedCaptures.Count -eq 0 -and $pollutionPassed)
$overallStatus = if ($overallPassed) { 'PASS_WITH_VISUAL_REVIEW_REQUIRED' } else { 'FAIL' }
$finishedUtc = [DateTime]::UtcNow

$previewReport = [pscustomobject][ordered]@{
    schema_version = 1
    suite_id = 'I1_production_preview'
    status = $overallStatus
    visual_acceptance = 'NOT_RUN'
    source_mode = $SourceMode
    all_matrix = [bool]$All
    selected_scenes = @($selectedScenes)
    selected_resolutions = @($selectedResolutions)
    started_utc = $startedUtc.ToString('o')
    finished_utc = $finishedUtc.ToString('o')
    run_root = $runRoot
    mirror_root = $mirrorRoot
    source = if ($null -eq $preflightReport) { $null } else { $preflightReport.source }
    mirror_fidelity = if ($null -eq $preflightReport) { $null } else { $preflightReport.mirror.fidelity }
    manifest_binding = [pscustomobject][ordered]@{
        status = if ($null -ne $executionManifestSha256 -and $manifestHashesMatch) { 'PASS' } else { 'FAIL' }
        setup_path = $manifestPath
        setup_sha256 = $setupManifestSha256
        execution_path = $executionManifestPath
        execution_sha256 = $executionManifestSha256
        preflight_execution_sha256 = if ($null -eq $preflightReport) { $null } else { $preflightReport.manifest_binding.execution_sha256 }
        hashes_match = $manifestHashesMatch
    }
    control_plane_binding = [pscustomobject][ordered]@{
        status = if ($controlPlaneBindingPass) { 'PASS' } else { 'FAIL' }
        required_mode = if ($SourceMode -ceq 'head') { 'preview_invoke_and_library_equal_head_mirror' } else { 'preview_invoke_and_library_equal_worktree_mirror' }
        files = @($controlPlaneBindings)
    }
    capture_runner = [pscustomobject][ordered]@{
        path = $runnerPath
        sha256 = $captureRunnerSha256
    }
    preflight = $preflightCase
    captures = $captureCases.ToArray()
    capture_set_complete = $captureSetComplete
    pollution_guard = [pscustomobject][ordered]@{
        status = if ($pollutionPassed) { 'PASS' } else { 'FAIL' }
        git = $gitPollution
        business = $businessPollution
        error = $pollutionError
    }
    fatal_error = $fatalError
}

if ($null -ne $previewReportPath) {
    Write-I0Json -Value $previewReport -Path $previewReportPath
    Write-Output ("I1_PREVIEW_REPORT_JSON=$previewReportPath")
}
elseif ($null -ne $fatalError) {
    Write-Error ("I1 production preview failed before its report path was available: " + $fatalError.message)
}
Write-Output ("I1_PREVIEW_STATUS=$overallStatus")
if ($overallStatus -cne 'PASS_WITH_VISUAL_REVIEW_REQUIRED') {
    exit 1
}
