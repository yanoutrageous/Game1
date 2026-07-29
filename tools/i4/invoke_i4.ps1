[CmdletBinding()]
param(
    [ValidateSet('governance', 'preflight', 'full')]
    [string]$Profile = 'preflight',

    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$GodotExe = '',

    [string]$PythonExe = 'python',

    [string]$UERoot = '',

    [string]$OutputRoot = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Write-I4Text {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Text
    )
    [System.IO.File]::WriteAllText(
        $Path,
        $Text,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Get-I4Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Invoke-I4Step {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$RequiredMarker,
        [Parameter(Mandatory = $true)][string]$LogPath
    )
    $started = [DateTime]::UtcNow
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(
            & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
                -File $ScriptPath @Arguments 2>&1
        )
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    $text = ($output | ForEach-Object { [string]$_ }) -join "`r`n"
    Write-I4Text -Path $LogPath -Text ($text + "`r`n")
    $markerFound = [regex]::IsMatch($text, $RequiredMarker)
    return [pscustomobject][ordered]@{
        id = $Id
        status = if ($exitCode -eq 0 -and $markerFound) { 'PASS' } else { 'FAIL' }
        exit_code = $exitCode
        required_marker = $RequiredMarker
        marker_found = $markerFound
        started_utc = $started.ToString('o')
        finished_utc = [DateTime]::UtcNow.ToString('o')
        log_path = $LogPath
        log_sha256 = Get-I4Sha256 -Path $LogPath
    }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}
$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd('\')
$observedRoot = (& git.exe -C $resolvedRoot rev-parse --show-toplevel).Trim()
if (
    $LASTEXITCODE -ne 0 -or
    (Resolve-Path -LiteralPath $observedRoot).Path.TrimEnd('\') -ne $resolvedRoot
) {
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
    $OutputRoot = Join-Path $resolvedRoot ".tmp\i4\invoke\$runId"
}
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot '.tmp')).TrimEnd('\')
if (
    -not $resolvedOutputRoot.StartsWith(
        $tmpRoot + '\',
        [System.StringComparison]::OrdinalIgnoreCase
    )
) {
    throw "OutputRoot must stay below the repository .tmp directory: $resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $resolvedOutputRoot -Force)

$statusBefore = @(
    & git.exe -c core.quotepath=false -C $resolvedRoot status --porcelain=v1 --untracked-files=all
)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read the initial worktree status.'
}
if ($SourceMode -ceq 'head' -and $statusBefore.Count -ne 0) {
    throw 'SourceMode=head requires an entirely clean worktree.'
}

$head = (& git.exe -C $resolvedRoot rev-parse HEAD).Trim()
$headTree = (& git.exe -C $resolvedRoot rev-parse 'HEAD^{tree}').Trim()
$startedUtc = [DateTime]::UtcNow
$steps = New-Object System.Collections.Generic.List[object]
$failure = ''

try {
    $staticArguments = @(
        '-SourceMode', $SourceMode,
        '-RepoRoot', $resolvedRoot,
        '-GodotExe', $GodotExe,
        '-PythonExe', $PythonExe,
        '-OutputRoot', (Join-Path $resolvedOutputRoot 'static')
    )
    if (-not [string]::IsNullOrWhiteSpace($UERoot)) {
        $staticArguments += @('-UERoot', $UERoot)
    }
    if ($Profile -ceq 'governance') {
        $staticArguments += '-GovernanceOnly'
    }
    $static = Invoke-I4Step `
        -Id 'static' `
        -ScriptPath (Join-Path $PSScriptRoot 'validate_i4_static.ps1') `
        -Arguments $staticArguments `
        -RequiredMarker '(?m)^I4_STATIC=PASS ' `
        -LogPath (Join-Path $resolvedOutputRoot 'static.log')
    [void]$steps.Add($static)
    if ($static.status -cne 'PASS') {
        throw 'I4 static validation failed.'
    }

    if ($Profile -cne 'governance') {
        $census = Invoke-I4Step `
            -Id 'content_census' `
            -ScriptPath (Join-Path $PSScriptRoot 'build_i4_content_census.ps1') `
            -Arguments @(
                '-SourceMode', $SourceMode,
                '-RepoRoot', $resolvedRoot,
                '-GodotExe', $GodotExe,
                '-OutputRoot', (Join-Path $resolvedOutputRoot 'content_census')
            ) `
            -RequiredMarker '(?m)^I4_CONTENT_CENSUS_WRAPPER=PASS ' `
            -LogPath (Join-Path $resolvedOutputRoot 'content_census.log')
        [void]$steps.Add($census)
        if ($census.status -cne 'PASS') {
            throw 'I4 content census failed.'
        }

        $criticalIterations = if ($Profile -ceq 'full') { 10 } else { 1 }
        $journeyIterations = if ($Profile -ceq 'full') { 3 } else { 1 }
        $repetition = Invoke-I4Step `
            -Id 'repetition' `
            -ScriptPath (Join-Path $PSScriptRoot 'invoke_i4_repetition.ps1') `
            -Arguments @(
                '-SourceMode', $SourceMode,
                '-RepoRoot', $resolvedRoot,
                '-GodotExe', $GodotExe,
                '-OutputRoot', (Join-Path $resolvedOutputRoot 'repetition'),
                '-CriticalIterations', [string]$criticalIterations,
                '-JourneyIterations', [string]$journeyIterations
            ) `
            -RequiredMarker '(?m)^I4_REPETITION=PASS ' `
            -LogPath (Join-Path $resolvedOutputRoot 'repetition.log')
        [void]$steps.Add($repetition)
        if ($repetition.status -cne 'PASS') {
            throw 'I4 repetition validation failed.'
        }

        if ($Profile -ceq 'full') {
            $device = Invoke-I4Step `
                -Id 'device_boundary' `
                -ScriptPath (Join-Path $PSScriptRoot 'probe_i4_device_boundary.ps1') `
                -Arguments @(
                    '-RepoRoot', $resolvedRoot,
                    '-GodotExe', $GodotExe,
                    '-OutputRoot', (Join-Path $resolvedOutputRoot 'device')
                ) `
                -RequiredMarker '(?m)^I4_DEVICE_BOUNDARY=PASS ' `
                -LogPath (Join-Path $resolvedOutputRoot 'device.log')
            [void]$steps.Add($device)
            if ($device.status -cne 'PASS') {
                throw 'I4 device-boundary inventory failed.'
            }
        }
    }
}
catch {
    $failure = $_.Exception.Message
}

$statusAfter = @(
    & git.exe -c core.quotepath=false -C $resolvedRoot status --porcelain=v1 --untracked-files=all
)
if ($LASTEXITCODE -ne 0) {
    $failure = 'Unable to read the final worktree status.'
}
$worktreeUnchanged = @(
    Compare-Object `
        -ReferenceObject $statusBefore `
        -DifferenceObject $statusAfter `
        -CaseSensitive
).Count -eq 0
if (-not $worktreeUnchanged -and [string]::IsNullOrWhiteSpace($failure)) {
    $failure = 'I4 unified validation changed the active worktree.'
}

$automationStatus = if (
    [string]::IsNullOrWhiteSpace($failure) -and
    @($steps | Where-Object { $_.status -cne 'PASS' }).Count -eq 0 -and
    $worktreeUnchanged
) { 'PASS' } else { 'FAIL' }
$stageAcceptance = switch ($Profile) {
    'governance' { 'NOT_EVALUATED' }
    'preflight' { 'AUTOMATION_PREFLIGHT_ONLY' }
    default { 'BLOCKED_EXTERNAL_DEVICE_AND_DYNAMIC_ACCEPTANCE' }
}

$reportPath = Join-Path $resolvedOutputRoot 'i4_report.json'
$report = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    automation_status = $automationStatus
    stage_acceptance = $stageAcceptance
    profile = $Profile
    source_mode = $SourceMode
    head = $head
    head_tree = $headTree
    godot_executable = (Resolve-Path -LiteralPath $GodotExe).Path
    godot_version = ((& $GodotExe --version) -join "`n").Trim()
    started_utc = $startedUtc.ToString('o')
    finished_utc = [DateTime]::UtcNow.ToString('o')
    worktree_status_before = $statusBefore
    worktree_status_after = $statusAfter
    worktree_unchanged = $worktreeUnchanged
    failure = $failure
    steps = $steps.ToArray()
}
Write-I4Text -Path $reportPath -Text (($report | ConvertTo-Json -Depth 30) + "`r`n")
$reportSha = Get-I4Sha256 -Path $reportPath

Write-Output (
    'I4_VALIDATION={0} profile={1} source_mode={2} stage_acceptance={3} report={4} sha256={5}' -f
    $automationStatus,
    $Profile,
    $SourceMode,
    $stageAcceptance,
    $reportPath,
    $reportSha
)
if ($automationStatus -cne 'PASS') {
    exit 1
}
