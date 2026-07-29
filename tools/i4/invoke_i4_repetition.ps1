[CmdletBinding()]
param(
    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$GodotExe = '',

    [string]$OutputRoot = '',

    [ValidateRange(1, 50)]
    [int]$CriticalIterations = 10,

    [ValidateRange(1, 20)]
    [int]$JourneyIterations = 3,

    [string[]]$CriticalRunnerIds = @(
        'I4_DEBUG_SANDBOX',
        'I4_QUANTITY_TRANSACTION',
        'I4_DEPLOY_INFORMATION_LAYOUT',
        'I4_IN_RUN_ITEM_AGGREGATION',
        'I4_IN_RUN_VISUAL_PHYSICS',
        'I4_LONG_TERM_NAVIGATION'
    )
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-I4Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-I4WorktreeIdentity {
    param([Parameter(Mandatory = $true)][string]$Root)
    $head = (& git.exe -C $Root rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to resolve HEAD for the I4 repetition identity.'
    }
    $status = @(& git.exe -c core.quotepath=false -C $Root status --porcelain=v1 --untracked-files=all)
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to resolve worktree status for the I4 repetition identity.'
    }
    $records = New-Object System.Collections.Generic.List[string]
    [void]$records.Add('HEAD|' + $head)
    foreach ($rawLine in @($status | Sort-Object)) {
        $line = [string]$rawLine
        if ($line.Length -lt 4) {
            continue
        }
        $path = $line.Substring(3)
        if ($path.Contains(' -> ')) {
            $path = $path.Split(@(' -> '), [System.StringSplitOptions]::None)[-1]
        }
        $path = $path.Trim('"').Replace('/', '\')
        $fullPath = Join-Path $Root $path
        $contentIdentity = if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            Get-I4Sha256 -Path $fullPath
        }
        else {
            'MISSING'
        }
        [void]$records.Add($line + '|' + $contentIdentity)
    }
    $payload = [System.Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $fingerprint = -join @($algorithm.ComputeHash($payload) | ForEach-Object { $_.ToString('X2') })
    }
    finally {
        $algorithm.Dispose()
    }
    return [pscustomobject][ordered]@{
        head = $head
        fingerprint_sha256 = $fingerprint
        status = $status
    }
}

function Write-I4Json {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Path
    )
    [System.IO.File]::WriteAllText(
        $Path,
        (($Value | ConvertTo-Json -Depth 30) + "`r`n"),
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Get-I4Runner {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$Id
    )
    $matches = @($Manifest.runners | Where-Object { [string]$_.id -ceq $Id })
    if ($matches.Count -ne 1) {
        throw "Expected one manifest runner for $Id, found $($matches.Count)."
    }
    return $matches[0]
}

function Get-I4RunnerCleanupContract {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$Id
    )
    $property = $Manifest.diagnostics.expected_cleanup_diagnostics_by_runner.PSObject.Properties[$Id]
    if ($null -eq $property) {
        throw "Runner cleanup contract is missing: $Id"
    }
    return @($property.Value | ForEach-Object { [string]$_ })
}

function ConvertTo-I4ProcessArgument {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
    if ($Value.Contains('"')) {
        throw "Process arguments containing a quote are not supported: $Value"
    }
    if ($Value.Length -eq 0) {
        return '""'
    }
    if ($Value -notmatch '\s') {
        return $Value
    }
    if ($Value.EndsWith('\')) {
        return '"' + $Value + '\\"'
    }
    return '"' + $Value + '"'
}

function Invoke-I4RunnerProcess {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)]$Runner,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$ExpectedCleanup,
        [Parameter(Mandatory = $true)][int]$Iteration,
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$RunRoot
    )
    $caseId = '{0}_{1}_{2:d2}' -f $Kind.ToLowerInvariant(), $Id.ToLowerInvariant(), $Iteration
    $caseRoot = Join-Path $RunRoot $caseId
    $runtimeRoot = Join-Path $caseRoot 'runtime'
    $stdoutPath = Join-Path $caseRoot 'stdout.log'
    $stderrPath = Join-Path $caseRoot 'stderr.log'
    $engineLogPath = Join-Path $caseRoot 'engine.log'
    [void](New-Item -ItemType Directory -Path $runtimeRoot -Force)

    $runnerPath = 'res://' + ([string]$Runner.relative_path).Substring('Godot/GraytailGodot/'.Length)
    $arguments = @(
        '--headless',
        '--path', $ProjectRoot,
        '--log-file', $engineLogPath,
        '--script', $runnerPath
    )
    $userArgs = @()
    $userArgsProperty = $Runner.PSObject.Properties['user_args']
    if ($null -ne $userArgsProperty) {
        $userArgs = @($userArgsProperty.Value | ForEach-Object { [string]$_ })
    }
    if ($userArgs.Count -gt 0) {
        $arguments += '--'
        $arguments += $userArgs
    }

    $timeoutSeconds = 180
    $timeoutProperty = $Runner.PSObject.Properties['timeout_seconds']
    if ($null -ne $timeoutProperty) {
        $timeoutSeconds = [int]$timeoutProperty.Value
    }
    $environmentNames = @('APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP')
    $savedEnvironment = @{}
    foreach ($name in $environmentNames) {
        $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $runtimeRoot, 'Process')
    }

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $process = $null
    $processId = $null
    $exitCode = -1
    $stdout = ''
    $stderr = ''
    $timedOut = $false
    try {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo
        $startInfo.FileName = $Executable
        $startInfo.Arguments = (@($arguments | ForEach-Object {
            ConvertTo-I4ProcessArgument -Value ([string]$_)
        }) -join ' ')
        $startInfo.WorkingDirectory = $ProjectRoot
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        try {
            $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
            $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
        }
        catch {
        }
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $startInfo
        if (-not $process.Start()) {
            throw "Could not start Godot process for $Id."
        }
        $processId = $process.Id
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $exited = $process.WaitForExit($timeoutSeconds * 1000)
        if (-not $exited) {
            $timedOut = $true
            try {
                $process.Kill()
                $process.WaitForExit()
            }
            catch {
            }
        }
        else {
            $process.WaitForExit()
            $stdout = $stdoutTask.GetAwaiter().GetResult()
            $stderr = $stderrTask.GetAwaiter().GetResult()
            $exitCode = $process.ExitCode
        }
    }
    finally {
        $stopwatch.Stop()
        [System.IO.File]::WriteAllText(
            $stdoutPath,
            $stdout,
            (New-Object System.Text.UTF8Encoding($false))
        )
        [System.IO.File]::WriteAllText(
            $stderrPath,
            $stderr,
            (New-Object System.Text.UTF8Encoding($false))
        )
        if ($null -ne $process) {
            $process.Dispose()
        }
        foreach ($name in $environmentNames) {
            [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
        }
    }

    $engineLog = if (Test-Path -LiteralPath $engineLogPath) {
        [System.IO.File]::ReadAllText($engineLogPath, [System.Text.Encoding]::UTF8)
    } else { '' }
    $markerText = ($stdout + "`n" + $stderr).Replace("`r`n", "`n").Replace("`r", "`n")
    $diagnosticText = $markerText + "`n" + $engineLog.Replace("`r`n", "`n").Replace("`r", "`n")
    $lines = @($markerText -split "`n")

    $passRegex = ''
    $passRegexProperty = $Runner.PSObject.Properties['pass_line_regex']
    if ($null -ne $passRegexProperty) {
        $passRegex = [string]$passRegexProperty.Value
    }
    $passCount = if ([string]::IsNullOrWhiteSpace($passRegex)) {
        @($lines | Where-Object { $_.Trim() -ceq [string]$Runner.pass_marker }).Count
    }
    else {
        @($lines | Where-Object { [regex]::IsMatch($_.Trim(), $passRegex) }).Count
    }
    $failCount = @($lines | Where-Object {
        $_.Trim().StartsWith([string]$Runner.fail_marker, [System.StringComparison]::Ordinal)
    }).Count

    $diagnostics = @(
        [regex]::Matches(
            $diagnosticText,
            '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$'
        ) | ForEach-Object { $_.Value.Trim() } | Sort-Object -Unique
    )
    $blockingDiagnostics = @($diagnostics | Where-Object { $ExpectedCleanup -cnotcontains $_ })
    $cleanupDiagnostics = @($diagnostics | Where-Object { $ExpectedCleanup -ccontains $_ })
    $missingExpected = @($ExpectedCleanup | Where-Object { $diagnostics -cnotcontains $_ })
    $passed = (
        -not $timedOut -and
        $exitCode -eq 0 -and
        $passCount -eq 1 -and
        $failCount -eq 0 -and
        $blockingDiagnostics.Count -eq 0 -and
        $missingExpected.Count -eq 0
    )
    $status = if ($passed -and $cleanupDiagnostics.Count -gt 0) {
        'PASS_WITH_CLEANUP_DIAGNOSTIC'
    }
    elseif ($passed) {
        'PASS'
    }
    else {
        'FAIL'
    }
    return [pscustomobject][ordered]@{
        kind = $Kind
        runner_id = $Id
        iteration = $Iteration
        status = $status
        process_id = $processId
        new_process = $true
        exit_code = $exitCode
        timed_out = $timedOut
        duration_ms = [int64]$stopwatch.ElapsedMilliseconds
        pass_marker_count = $passCount
        fail_marker_count = $failCount
        expected_cleanup_diagnostics = $ExpectedCleanup
        cleanup_diagnostics = $cleanupDiagnostics
        missing_expected_cleanup_diagnostics = $missingExpected
        blocking_diagnostics = $blockingDiagnostics
        stdout_path = $stdoutPath
        stderr_path = $stderrPath
        engine_log_path = $engineLogPath
        runtime_root = $runtimeRoot
    }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}
$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd('\')
$observedRoot = (& git.exe -C $resolvedRoot rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or (Resolve-Path -LiteralPath $observedRoot).Path.TrimEnd('\') -ne $resolvedRoot) {
    throw "RepoRoot is not the active Git worktree root: $resolvedRoot"
}
if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    $GodotExe = 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw "Godot executable is missing: $GodotExe"
}
$sourceIdentity = Get-I4WorktreeIdentity -Root $resolvedRoot
if ($SourceMode -ceq 'head' -and @($sourceIdentity.status).Count -ne 0) {
    throw 'SourceMode=head requires an entirely clean worktree.'
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $OutputRoot = Join-Path $resolvedRoot ".tmp\i4\repetition\$runId"
}
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot '.tmp')).TrimEnd('\')
if (-not $resolvedOutputRoot.StartsWith($tmpRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputRoot must stay below the repository .tmp directory: $resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $resolvedOutputRoot -Force)

$projectRoot = Join-Path $resolvedRoot 'Godot\GraytailGodot'
$manifestPath = Join-Path $resolvedRoot 'tools\i1\validation_manifest.json'
$manifest = [System.IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$head = (& git.exe -C $resolvedRoot rev-parse HEAD).Trim()
$headTree = (& git.exe -C $resolvedRoot rev-parse 'HEAD^{tree}').Trim()
$startedUtc = [DateTime]::UtcNow
$records = New-Object System.Collections.Generic.List[object]
$failure = $null

try {
    foreach ($runnerId in $CriticalRunnerIds) {
        $runner = Get-I4Runner -Manifest $manifest -Id $runnerId
        $cleanup = @(Get-I4RunnerCleanupContract -Manifest $manifest -Id $runnerId)
        for ($iteration = 1; $iteration -le $CriticalIterations; $iteration++) {
            $recordResult = @(
                Invoke-I4RunnerProcess `
                    -Id $runnerId `
                    -Runner $runner `
                    -ExpectedCleanup $cleanup `
                    -Iteration $iteration `
                    -Kind 'critical' `
                    -Executable $GodotExe `
                    -ProjectRoot $projectRoot `
                    -RunRoot $resolvedOutputRoot
            )
            if ($recordResult.Count -ne 1) {
                $resultTypes = @($recordResult | ForEach-Object { $_.GetType().FullName }) -join ','
                throw "Runner process returned $($recordResult.Count) records: $resultTypes"
            }
            $record = $recordResult[0]
            [void]$records.Add($record)
            Write-Output (
                'I4_REPETITION critical {0} {1}/{2}={3} process={4}' -f
                $runnerId,
                $iteration,
                $CriticalIterations,
                $record.status,
                $record.process_id
            )
            if ([string]$record.status -ceq 'FAIL') {
                throw "Critical repetition failed: $runnerId iteration $iteration"
            }
        }
    }

    $journeyId = 'I3R_OUT_OF_RUN_PRODUCTION_JOURNEY'
    $journeyRunner = Get-I4Runner -Manifest $manifest -Id $journeyId
    $journeyCleanup = @(Get-I4RunnerCleanupContract -Manifest $manifest -Id $journeyId)
    for ($iteration = 1; $iteration -le $JourneyIterations; $iteration++) {
        $recordResult = @(
            Invoke-I4RunnerProcess `
                -Id $journeyId `
                -Runner $journeyRunner `
                -ExpectedCleanup $journeyCleanup `
                -Iteration $iteration `
                -Kind 'journey' `
                -Executable $GodotExe `
                -ProjectRoot $projectRoot `
                -RunRoot $resolvedOutputRoot
        )
        if ($recordResult.Count -ne 1) {
            $resultTypes = @($recordResult | ForEach-Object { $_.GetType().FullName }) -join ','
            throw "Journey process returned $($recordResult.Count) records: $resultTypes"
        }
        $record = $recordResult[0]
        [void]$records.Add($record)
        Write-Output (
            'I4_REPETITION journey {0} {1}/{2}={3} process={4}' -f
            $journeyId,
            $iteration,
            $JourneyIterations,
            $record.status,
            $record.process_id
        )
        if ([string]$record.status -ceq 'FAIL') {
            throw "Production journey repetition failed at iteration $iteration"
        }
    }
}
catch {
    $failure = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }
}

$finishedUtc = [DateTime]::UtcNow
$sourceIdentityAfter = Get-I4WorktreeIdentity -Root $resolvedRoot
$worktreeUnchanged = (
    [string]$sourceIdentity.fingerprint_sha256 -ceq [string]$sourceIdentityAfter.fingerprint_sha256 -and
    @(Compare-Object -ReferenceObject @($sourceIdentity.status) -DifferenceObject @($sourceIdentityAfter.status) -CaseSensitive).Count -eq 0
)
$criticalRecords = @($records | Where-Object { [string]$_.kind -ceq 'critical' })
$journeyRecords = @($records | Where-Object { [string]$_.kind -ceq 'journey' })
$criticalComplete = (
    $criticalRecords.Count -eq ($CriticalRunnerIds.Count * $CriticalIterations) -and
    @($criticalRecords | Where-Object { [string]$_.status -ceq 'FAIL' }).Count -eq 0
)
$journeyComplete = (
    $journeyRecords.Count -eq $JourneyIterations -and
    @($journeyRecords | Where-Object { [string]$_.status -ceq 'FAIL' }).Count -eq 0
)
$overallStatus = if ($null -eq $failure -and $criticalComplete -and $journeyComplete -and $worktreeUnchanged) { 'PASS' } else { 'FAIL' }
$reportPath = Join-Path $resolvedOutputRoot 'repetition_report.json'
$report = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = $overallStatus
    head = $head
    head_tree = $headTree
    source_mode = $SourceMode
    source_fingerprint_sha256 = [string]$sourceIdentity.fingerprint_sha256
    worktree_status_before = @($sourceIdentity.status)
    worktree_status_after = @($sourceIdentityAfter.status)
    worktree_unchanged = $worktreeUnchanged
    godot_executable = (Resolve-Path -LiteralPath $GodotExe).Path
    godot_version = ((& $GodotExe --version) -join "`n").Trim()
    started_utc = $startedUtc.ToString('o')
    finished_utc = $finishedUtc.ToString('o')
    duration_ms = [int64]($finishedUtc - $startedUtc).TotalMilliseconds
    critical_runner_ids = $CriticalRunnerIds
    critical_iterations_required = $CriticalIterations
    critical_processes_observed = @(
        $criticalRecords | ForEach-Object { $_.process_id } | Sort-Object -Unique
    ).Count
    critical_complete = $criticalComplete
    journey_runner_id = 'I3R_OUT_OF_RUN_PRODUCTION_JOURNEY'
    journey_iterations_required = $JourneyIterations
    journey_processes_observed = @(
        $journeyRecords | ForEach-Object { $_.process_id } | Sort-Object -Unique
    ).Count
    journey_complete = $journeyComplete
    failure = $failure
    records = $records.ToArray()
}
Write-I4Json -Value $report -Path $reportPath
$reportSha = Get-I4Sha256 -Path $reportPath

$summaryFormat = (
    'I4_REPETITION={0} critical={1}x{2} critical_processes={3} journey={4}/{5} ' +
    'journey_processes={6} report={7} sha256={8}'
)
$summaryArguments = [object[]]@(
    $overallStatus,
    $CriticalRunnerIds.Count,
    $CriticalIterations,
    $report.critical_processes_observed,
    $journeyRecords.Count,
    $JourneyIterations,
    $report.journey_processes_observed,
    $reportPath,
    $reportSha
)
Write-Output ([string]::Format($summaryFormat, $summaryArguments))
if ($overallStatus -cne 'PASS') {
    exit 1
}
