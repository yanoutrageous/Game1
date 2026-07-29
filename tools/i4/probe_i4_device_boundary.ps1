[CmdletBinding()]
param(
    [string]$RepoRoot = '',

    [string]$GodotExe = '',

    [string]$OutputRoot = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-I4Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
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

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $OutputRoot = Join-Path $resolvedRoot ".tmp\i4\device\$runId"
}
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot '.tmp')).TrimEnd('\')
if (-not $resolvedOutputRoot.StartsWith($tmpRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputRoot must stay below the repository .tmp directory: $resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $resolvedOutputRoot -Force)

$projectRoot = Join-Path $resolvedRoot 'Godot\GraytailGodot'
$runnerPath = Join-Path $resolvedRoot 'tools\i4\godot_i4_device_probe_runner.gd'
$runtimeReportPath = Join-Path $resolvedOutputRoot 'device_runtime.json'
$stdoutPath = Join-Path $resolvedOutputRoot 'stdout.log'
$stderrPath = Join-Path $resolvedOutputRoot 'stderr.log'
$engineLogPath = Join-Path $resolvedOutputRoot 'engine.log'
$reportPath = Join-Path $resolvedOutputRoot 'device_boundary_report.json'

$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = (Resolve-Path -LiteralPath $GodotExe).Path
$startInfo.Arguments = @(
    '--path', ('"{0}"' -f $projectRoot),
    '--log-file', ('"{0}"' -f $engineLogPath),
    '--script', ('"{0}"' -f $runnerPath),
    '--',
    ('"--output={0}"' -f $runtimeReportPath.Replace('\', '/'))
) -join ' '
$startInfo.WorkingDirectory = $projectRoot
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $startInfo
$startedUtc = [DateTime]::UtcNow
try {
    if (-not $process.Start()) {
        throw 'Could not start the real-renderer Godot device probe.'
    }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(60000)) {
        try {
            $process.Kill()
            $process.WaitForExit()
        }
        catch {
        }
        throw 'The real-renderer Godot device probe timed out.'
    }
    $process.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
}
finally {
    $process.Dispose()
}
[System.IO.File]::WriteAllText($stdoutPath, $stdout, (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllText($stderrPath, $stderr, (New-Object System.Text.UTF8Encoding($false)))

if ($exitCode -ne 0) {
    throw "Godot device probe failed with exit code $exitCode. See $stderrPath"
}
if ($stdout -notmatch '(?m)^I4_DEVICE_PROBE=PASS ') {
    throw 'Godot device probe omitted its PASS marker.'
}
if ($stdout + "`n" + $stderr -match '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:)\s*') {
    throw 'Godot device probe emitted a blocking diagnostic.'
}
if (-not (Test-Path -LiteralPath $runtimeReportPath -PathType Leaf)) {
    throw 'Godot device probe did not write its runtime report.'
}

$runtime = [System.IO.File]::ReadAllText($runtimeReportPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$head = (& git.exe -C $resolvedRoot rev-parse HEAD).Trim()
$headTree = (& git.exe -C $resolvedRoot rev-parse 'HEAD^{tree}').Trim()
$physicalControllerStatus = if ([int]$runtime.joypad_count -gt 0) { 'DETECTED_NOT_FUNCTIONALLY_ACCEPTED' } else { 'BLOCKED_NOT_RUN' }
$audioStatus = if (-not [string]::IsNullOrWhiteSpace([string]$runtime.audio.driver)) { 'ROUTE_DETECTED_NOT_FUNCTIONALLY_ACCEPTED' } else { 'BLOCKED_NOT_RUN' }
$gpuStatus = if (-not [string]::IsNullOrWhiteSpace([string]$runtime.renderer.adapter_name)) { 'MEASURED_NOT_ACCEPTED' } else { 'BLOCKED_NOT_RUN' }

$report = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = 'PASS'
    probe_meaning = 'BOUNDARY_INVENTORY_ONLY'
    started_utc = $startedUtc.ToString('o')
    finished_utc = [DateTime]::UtcNow.ToString('o')
    head = $head
    head_tree = $headTree
    godot_executable = (Resolve-Path -LiteralPath $GodotExe).Path
    godot_version = ((& $GodotExe --version) -join "`n").Trim()
    runtime = $runtime
    physical_controller_gate = $physicalControllerStatus
    audio_gate = $audioStatus
    gpu_gate = $gpuStatus
    runtime_report_path = $runtimeReportPath
    runtime_report_sha256 = Get-I4Sha256 -Path $runtimeReportPath
    stdout_path = $stdoutPath
    stderr_path = $stderrPath
    engine_log_path = $engineLogPath
}
Write-I4Json -Value $report -Path $reportPath

Write-Output (
    'I4_DEVICE_BOUNDARY=PASS joypads={0} controller={1} audio={2} gpu={3} report={4} sha256={5}' -f
    [int]$runtime.joypad_count,
    $physicalControllerStatus,
    $audioStatus,
    $gpuStatus,
    $reportPath,
    (Get-I4Sha256 -Path $reportPath)
)
