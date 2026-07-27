[CmdletBinding()]
param(
    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$GodotExe = '',

    [ValidateRange(960, 3840)]
    [int]$Width = 1280,

    [ValidateRange(540, 2160)]
    [int]$Height = 720,

    [switch]$InteractiveCombat,

    [ValidateRange(60, 3600)]
    [int]$AutomaticTimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot '..\i0\i0_test_lib.ps1')

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}


function Get-I3RGalleryWorkspaceRoot {
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
    throw "Unable to derive I3R state-gallery workspace root for repo=$repoPath git_common=$gitCommon"
}


function Get-I3RGalleryMarkedValue {
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


function Get-I3RGalleryJson {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "JSON file is missing: $Path"
    }
    $raw = [System.IO.File]::ReadAllText(
        (Get-I0CanonicalPath -Path $Path),
        (New-Object System.Text.UTF8Encoding($false))
    )
    return ($raw | ConvertFrom-Json)
}


function Get-I3RGallerySha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I3RGalleryDiagnostics {
    param([AllowEmptyString()][string]$Text)

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


function Invoke-I3RGalleryInteractiveProcess {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][hashtable]$Environment
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "Executable not found: $FilePath"
    }
    if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
        throw "Working directory not found: $WorkingDirectory"
    }
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $false
    $startInfo.RedirectStandardOutput = $false
    $startInfo.RedirectStandardError = $false
    $startInfo.Arguments = (($Arguments | ForEach-Object {
        ConvertTo-I0CommandLineArgument -Value ([string]$_)
    }) -join ' ')
    foreach ($key in $Environment.Keys) {
        $startInfo.EnvironmentVariables[[string]$key] = [string]$Environment[$key]
    }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    if (-not $process.Start()) {
        throw "Failed to start interactive process: $FilePath"
    }
    Write-Host 'I3R interactive combat is live. Use the production controls in the Godot window; close that window to finish validation.'
    $process.WaitForExit()
    $stopwatch.Stop()
    $exitCode = $process.ExitCode
    $process.Dispose()
    return [pscustomobject][ordered]@{
        file_path = $FilePath
        arguments = @($Arguments)
        working_directory = $WorkingDirectory
        exit_code = $exitCode
        timed_out = $false
        duration_ms = [int64]$stopwatch.ElapsedMilliseconds
        stdout = ''
        stderr = ''
        interactive_wait_without_timeout = $true
    }
}


function ConvertTo-I3RGalleryProcessReport {
    param([Parameter(Mandatory = $true)]$ProcessResult)

    return [pscustomobject][ordered]@{
        file_path = $ProcessResult.file_path
        arguments = @($ProcessResult.arguments)
        working_directory = $ProcessResult.working_directory
        exit_code = $ProcessResult.exit_code
        timed_out = $ProcessResult.timed_out
        duration_ms = $ProcessResult.duration_ms
        stdout = Normalize-I0ProcessText -Text ([string]$ProcessResult.stdout)
        stderr = Normalize-I0ProcessText -Text ([string]$ProcessResult.stderr)
        interactive_wait_without_timeout = (
            $ProcessResult.PSObject.Properties.Name -contains 'interactive_wait_without_timeout' -and
            [bool]$ProcessResult.interactive_wait_without_timeout
        )
    }
}


if (
    $PSVersionTable.PSEdition -cne 'Desktop' -or
    $PSVersionTable.PSVersion.Major -ne 5 -or
    $PSVersionTable.PSVersion.Minor -lt 1
) {
    throw "I3R production state gallery requires Windows PowerShell 5.1 Desktop; current=$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
}

$requestedRepo = Get-I0CanonicalPath -Path $RepoRoot
$resolvedRepoResult = Invoke-I0Git -RepoRoot $requestedRepo -Arguments @('rev-parse', '--show-toplevel')
$repo = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $resolvedRepoResult.stdout)
if (-not [string]::Equals($requestedRepo, $repo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RepoRoot must be the active Git worktree root: requested=$requestedRepo resolved=$repo"
}
$workspaceRoot = Get-I3RGalleryWorkspaceRoot -RepoRoot $repo
[void](Set-I0WorkspaceRoot -Path $workspaceRoot)

$setupRunnerPath = Get-I0CanonicalPath -Path (
    Join-Path $repo 'tools\i3r\godot_i3r_production_state_gallery_runner.gd'
)
if (-not (Test-Path -LiteralPath $setupRunnerPath -PathType Leaf)) {
    throw "I3R state-gallery runner is missing: $setupRunnerPath"
}
$setupRunnerSha256 = Get-I3RGallerySha256 -Path $setupRunnerPath
$setupInvokerSha256 = Get-I3RGallerySha256 -Path $PSCommandPath
$startedUtc = [DateTime]::UtcNow
$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$preflightCase = $null
$preflightReport = $null
$runRoot = $null
$mirrorRoot = $null
$galleryRoot = $null
$galleryManifestPath = $null
$wrapperReportPath = $null
$runnerPath = $null
$runnerSha256 = $null
$captureProcess = $null
$diagnostics = $null
$validationRows = New-Object System.Collections.Generic.List[object]
$fatalError = $null

try {
    $i1Invoker = Get-I0CanonicalPath -Path (Join-Path $repo 'tools\i1\invoke_i1.ps1')
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
    $preflightText = [string]$preflightRaw.stdout + "`n" + [string]$preflightRaw.stderr
    $preflightReportPath = Get-I3RGalleryMarkedValue `
        -Text $preflightText `
        -Marker 'I1_REPORT_JSON='
    $preflightReportPath = Get-I0CanonicalPath -Path $preflightReportPath
    $preflightReport = Get-I3RGalleryJson -Path $preflightReportPath
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
        report_sha256 = Get-I3RGallerySha256 -Path $preflightReportPath
        process = ConvertTo-I3RGalleryProcessReport -ProcessResult $preflightRaw
    }
    $runRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.run_root)
    $mirrorRoot = Get-I0CanonicalPath -Path ([string]$preflightReport.mirror_root)
    Assert-I0PathWithin -Path $mirrorRoot -Root $runRoot -Label 'I3R state-gallery mirror'
    $galleryRoot = Get-I0CanonicalPath -Path (Join-Path $runRoot 'i3r_production_state_gallery')
    $galleryManifestPath = Get-I0CanonicalPath -Path (Join-Path $galleryRoot 'manifest.json')
    $wrapperReportPath = Get-I0CanonicalPath -Path (Join-Path $galleryRoot 'wrapper_report.json')
    [void](New-Item -ItemType Directory -Path $galleryRoot -Force)
    if (-not $preflightPassed) {
        throw 'I1 isolated preflight did not pass; state-gallery generation was not started'
    }

    $projectRoot = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot 'Godot\GraytailGodot')
    $runnerPath = Get-I0CanonicalPath -Path (
        Join-Path $mirrorRoot 'tools\i3r\godot_i3r_production_state_gallery_runner.gd'
    )
    $godotConsole = Get-I0CanonicalPath -Path (
        [string]$preflightReport.gates.runtime_links.console_executable.hardlink
    )
    foreach ($requiredPath in @($projectRoot, $runnerPath, $godotConsole)) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "I3R state-gallery dependency is missing: $requiredPath"
        }
    }
    $runnerSha256 = Get-I3RGallerySha256 -Path $runnerPath
    if (-not [string]::Equals(
        $setupRunnerSha256,
        $runnerSha256,
        [System.StringComparison]::Ordinal
    )) {
        throw "I3R state-gallery runner changed while the isolated mirror was prepared: setup=$setupRunnerSha256 mirror=$runnerSha256"
    }

    $logPath = Get-I0CanonicalPath -Path (Join-Path $galleryRoot 'godot.log')
    $environment = New-I0ProcessEnvironment `
        -RunRoot $runRoot `
        -CaseId 'I3R_PRODUCTION_STATE_GALLERY'
    $godotArguments = @(
        '--display-driver', 'windows',
        '--rendering-driver', 'opengl3',
        '--rendering-method', 'gl_compatibility',
        '--audio-driver', 'Dummy',
        '--path', $projectRoot,
        '--log-file', $logPath,
        '--script', $runnerPath,
        '--',
        "--output-dir=$galleryRoot",
        "--manifest-output=$galleryManifestPath",
        "--width=$Width",
        "--height=$Height",
        ("--interactive-combat=" + ([bool]$InteractiveCombat).ToString().ToLowerInvariant())
    )
    if ($InteractiveCombat) {
        $captureRaw = Invoke-I3RGalleryInteractiveProcess `
            -FilePath $godotConsole `
            -Arguments $godotArguments `
            -WorkingDirectory $projectRoot `
            -Environment $environment
    }
    else {
        $captureRaw = Invoke-I0Process `
            -FilePath $godotConsole `
            -Arguments $godotArguments `
            -WorkingDirectory $projectRoot `
            -Environment $environment `
            -TimeoutSeconds $AutomaticTimeoutSeconds
    }
    $captureProcess = ConvertTo-I3RGalleryProcessReport -ProcessResult $captureRaw
    $logText = ''
    if (Test-Path -LiteralPath $logPath -PathType Leaf) {
        $logText = [System.IO.File]::ReadAllText(
            $logPath,
            (New-Object System.Text.UTF8Encoding($false))
        )
    }
    $diagnostics = Get-I3RGalleryDiagnostics -Text (
        [string]$captureRaw.stdout + "`n" + [string]$captureRaw.stderr + "`n" + $logText
    )
    if ($captureRaw.timed_out -or $captureRaw.exit_code -ne 0) {
        throw "Godot state-gallery process failed: exit=$($captureRaw.exit_code) timed_out=$($captureRaw.timed_out)"
    }
    if ($diagnostics.blocking.Count -gt 0) {
        throw "Godot state-gallery emitted blocking diagnostics: $($diagnostics.blocking -join ' | ')"
    }
    if (-not $InteractiveCombat) {
        $passLines = @((Normalize-I0ProcessText -Text (
            [string]$captureRaw.stdout + "`n" + [string]$captureRaw.stderr
        )) -split "`n" | Where-Object {
            $_.Trim().StartsWith(
                'I3R_PRODUCTION_STATE_GALLERY=PASS status=PASS_WITH_VISUAL_REVIEW_REQUIRED ',
                [System.StringComparison]::Ordinal
            )
        })
        if ($passLines.Count -ne 1) {
            throw "Automatic state gallery emitted $($passLines.Count) PASS markers"
        }
    }

    $manifest = Get-I3RGalleryJson -Path $galleryManifestPath
    $expectedCases = @(
        'chest_closed',
        'chest_open_contents',
        'event_modal',
        'ground_loot_nearby',
        'door_available',
        'mine_armed_before',
        'mine_triggered_after',
        'mine_departed_clear',
        'exit_summary',
        'door_combat_locked',
        'combat_enemy_telegraph',
        'combat_player_attack_geometry'
    )
    if ([string]$manifest.status -cne 'PASS_WITH_VISUAL_REVIEW_REQUIRED') {
        throw "State-gallery manifest status is not PASS_WITH_VISUAL_REVIEW_REQUIRED: $($manifest.status)"
    }
    if ([string]$manifest.visual_acceptance -cne 'NOT_RUN') {
        throw "State-gallery manifest incorrectly claims visual acceptance: $($manifest.visual_acceptance)"
    }
    if ([int]$manifest.production_main_instances -ne 1) {
        throw "State-gallery did not instantiate production main exactly once"
    }
    if ([int]$manifest.fixed_seed -ne 13) {
        throw "State-gallery fixed seed is not 13"
    }
    if ([bool]$manifest.legacy_art24_hand_drawn_preview_instantiated) {
        throw "State-gallery claims the forbidden legacy ART24 preview was instantiated"
    }
    if ([bool]$manifest.player_journey_claim) {
        throw "State-gallery incorrectly claims to be a player journey"
    }
    if ([bool]$manifest.interactive_combat -ne [bool]$InteractiveCombat) {
        throw "State-gallery interactive flag does not match the wrapper request"
    }
    $manifestCases = @($manifest.cases)
    if (
        $manifestCases.Count -ne $expectedCases.Count -or
        [int]$manifest.generated_case_count -ne $expectedCases.Count -or
        -not [bool]$manifest.cases_complete
    ) {
        throw "State-gallery case count is incomplete: manifest=$($manifestCases.Count) expected=$($expectedCases.Count)"
    }

    foreach ($stateId in $expectedCases) {
        $matching = @($manifestCases | Where-Object {
            [string]$_.state_id -ceq $stateId
        })
        if ($matching.Count -ne 1) {
            throw "State-gallery expected exactly one case for $stateId, found $($matching.Count)"
        }
        $case = $matching[0]
        if (
            [string]$case.status -cne 'GENERATED_REVIEW_REQUIRED' -or
            -not [bool]$case.assertions_pass -or
            [bool]$case.player_journey
        ) {
            throw "State-gallery case contract failed for $stateId"
        }
        $pngPath = Get-I0CanonicalPath -Path ([string]$case.png_path)
        $metadataPath = Get-I0CanonicalPath -Path ([string]$case.metadata_path)
        $shaPath = Get-I0CanonicalPath -Path ([string]$case.sha256_path)
        foreach ($artifactPath in @($pngPath, $metadataPath, $shaPath)) {
            Assert-I0PathWithin -Path $artifactPath -Root $galleryRoot -Label "$stateId artifact"
            if (
                -not (Test-Path -LiteralPath $artifactPath -PathType Leaf) -or
                (Get-Item -LiteralPath $artifactPath).Length -le 0
            ) {
                throw "State-gallery artifact is missing or empty: $artifactPath"
            }
        }
        $pngSha256 = Get-I3RGallerySha256 -Path $pngPath
        $metadataSha256 = Get-I3RGallerySha256 -Path $metadataPath
        if (-not [string]::Equals(
            $pngSha256,
            [string]$case.png_sha256,
            [System.StringComparison]::Ordinal
        )) {
            throw "State-gallery PNG SHA mismatch for $stateId"
        }
        if (-not [string]::Equals(
            $metadataSha256,
            [string]$case.metadata_sha256,
            [System.StringComparison]::Ordinal
        )) {
            throw "State-gallery metadata SHA mismatch for $stateId"
        }
        $metadata = Get-I3RGalleryJson -Path $metadataPath
        if (
            [string]$metadata.state_id -cne $stateId -or
            [string]$metadata.status -cne 'GENERATED_REVIEW_REQUIRED' -or
            [string]$metadata.visual_acceptance -cne 'NOT_RUN' -or
            [int]$metadata.production_main_instances -ne 1 -or
            [int]$metadata.fixed_seed -ne 13 -or
            [bool]$metadata.player_journey -or
            [bool]$metadata.legacy_art24_hand_drawn_preview_instantiated -or
            [string]::IsNullOrWhiteSpace([string]$metadata.fixture_method)
        ) {
            throw "State-gallery metadata contract failed for $stateId"
        }
        $sidecar = [System.IO.File]::ReadAllText(
            $shaPath,
            (New-Object System.Text.UTF8Encoding($false))
        )
        if (
            -not $sidecar.Contains($pngSha256) -or
            -not $sidecar.Contains($metadataSha256)
        ) {
            throw "State-gallery SHA sidecar does not cover PNG and metadata for $stateId"
        }
        [void]$validationRows.Add([pscustomobject][ordered]@{
            state_id = $stateId
            status = 'PASS'
            fixture_method = [string]$metadata.fixture_method
            authority_fields_mutated = @($metadata.authority_fields_mutated)
            png_path = $pngPath
            png_bytes = (Get-Item -LiteralPath $pngPath).Length
            png_sha256 = $pngSha256
            metadata_path = $metadataPath
            metadata_sha256 = $metadataSha256
            sha256_path = $shaPath
        })
    }
}
catch {
    $fatalError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
        script_stack = $_.ScriptStackTrace
    }
}

$overallPassed = (
    $null -eq $fatalError -and
    $null -ne $preflightCase -and
    [string]$preflightCase.status -ceq 'PASS' -and
    $validationRows.Count -eq $expectedCases.Count
)
$overallStatus = if ($overallPassed) {
    'PASS_WITH_VISUAL_REVIEW_REQUIRED'
}
else {
    'FAIL'
}
$finishedUtc = [DateTime]::UtcNow
$report = [pscustomobject][ordered]@{
    schema_version = 1
    suite_id = 'I3R_production_state_gallery_wrapper'
    status = $overallStatus
    visual_acceptance = 'NOT_RUN'
    visual_acceptance_notice = 'Structural generation passed only when all production states, files, metadata, and hashes validate. Human visual review remains required.'
    production_scene_path = 'res://scenes/main/main.tscn'
    production_main_instances_expected = 1
    fixed_seed = 13
    source_mode = $SourceMode
    execution_mode = 'isolated_i1_mirror'
    interactive_combat = [bool]$InteractiveCombat
    interactive_wait_without_timeout = [bool]$InteractiveCombat
    width = $Width
    height = $Height
    started_utc = $startedUtc.ToString('o')
    finished_utc = $finishedUtc.ToString('o')
    workspace_root = $workspaceRoot
    run_root = $runRoot
    mirror_root = $mirrorRoot
    evidence_root = $galleryRoot
    gallery_manifest_path = $galleryManifestPath
    gallery_manifest_sha256 = if (
        $null -ne $galleryManifestPath -and
        (Test-Path -LiteralPath $galleryManifestPath -PathType Leaf)
    ) {
        Get-I3RGallerySha256 -Path $galleryManifestPath
    }
    else {
        $null
    }
    runner = [pscustomobject][ordered]@{
        setup_path = $setupRunnerPath
        setup_sha256 = $setupRunnerSha256
        execution_path = $runnerPath
        execution_sha256 = $runnerSha256
        hashes_match = (
            -not [string]::IsNullOrWhiteSpace([string]$runnerSha256) -and
            [string]::Equals(
                $setupRunnerSha256,
                $runnerSha256,
                [System.StringComparison]::Ordinal
            )
        )
    }
    invoke_script = [pscustomobject][ordered]@{
        path = $PSCommandPath
        sha256 = $setupInvokerSha256
        powershell_contract = 'Windows PowerShell 5.1 Desktop'
    }
    preflight = $preflightCase
    process = $captureProcess
    diagnostics = $diagnostics
    validated_cases = $validationRows.ToArray()
    fatal_error = $fatalError
}

if ($null -ne $wrapperReportPath) {
    Write-I0Json -Value $report -Path $wrapperReportPath
    Write-Output "I3R_STATE_GALLERY_REPORT=$wrapperReportPath"
}

if ($overallPassed) {
    Write-Output (
        "I3R_STATE_GALLERY=PASS status=$overallStatus cases=$($validationRows.Count) " +
        "manifest=$galleryManifestPath report=$wrapperReportPath interactive=$([bool]$InteractiveCombat)"
    )
    exit 0
}

if ($null -ne $fatalError) {
    Write-Error (
        "I3R_STATE_GALLERY=FAIL reason=$($fatalError.message) " +
        "report=$wrapperReportPath"
    )
}
else {
    Write-Error "I3R_STATE_GALLERY=FAIL report=$wrapperReportPath"
}
exit 1
