[CmdletBinding()]
param(
    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

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

function Get-I4WorktreeFingerprint {
    param([Parameter(Mandatory = $true)][string]$Root)
    $records = New-Object System.Collections.Generic.List[string]
    foreach ($relativeRoot in @('Godot\GraytailGodot', 'tools\i4')) {
        $fullRoot = Join-Path $Root $relativeRoot
        foreach ($file in @(Get-ChildItem -LiteralPath $fullRoot -File -Recurse | Where-Object {
            $_.FullName -notmatch '[\\/](?:\.godot|\.tmp|__pycache__)[\\/]'
        } | Sort-Object FullName)) {
            $relative = $file.FullName.Substring($Root.Length + 1).Replace('\', '/')
            [void]$records.Add($relative + '|' + (Get-I4Sha256 -Path $file.FullName))
        }
    }
    $payload = [System.Text.Encoding]::UTF8.GetBytes(($records -join "`n"))
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (-join @($algorithm.ComputeHash($payload) | ForEach-Object { $_.ToString('X2') }))
    }
    finally {
        $algorithm.Dispose()
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

if ($SourceMode -ceq 'head') {
    $trackedDirty = @(& git.exe -C $resolvedRoot status --porcelain=v1 --untracked-files=all)
    if ($LASTEXITCODE -ne 0 -or $trackedDirty.Count -ne 0) {
        throw 'SourceMode=head requires an entirely clean worktree so the census is bound to HEAD.'
    }
}

if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    foreach ($candidate in @(
        $env:I1_GODOT_EXE,
        $env:GODOT4,
        $env:GODOT_EXE,
        'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $GodotExe = (Resolve-Path -LiteralPath $candidate).Path
            break
        }
    }
}
if ([string]::IsNullOrWhiteSpace($GodotExe) -or -not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw 'Godot 4.6.3 console executable could not be resolved.'
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $OutputRoot = Join-Path $resolvedRoot ".tmp\i4\content_census\$runId"
}
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot '.tmp')).TrimEnd('\')
if (-not $resolvedOutputRoot.StartsWith($tmpRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputRoot must stay below the repository .tmp directory: $resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $resolvedOutputRoot -Force)

$projectRoot = Join-Path $resolvedRoot 'Godot\GraytailGodot'
$runner = Join-Path $resolvedRoot 'tools\i4\godot_i4_content_census_runner.gd'
$censusPath = Join-Path $resolvedOutputRoot 'content_census.json'
$logPath = Join-Path $resolvedOutputRoot 'runtime.log'
$wrapperPath = Join-Path $resolvedOutputRoot 'wrapper_report.json'
foreach ($required in @($projectRoot, $runner)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing I4 content-census dependency: $required"
    }
}

$head = (& git.exe -C $resolvedRoot rev-parse HEAD).Trim()
$headTree = (& git.exe -C $resolvedRoot rev-parse 'HEAD^{tree}').Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to resolve Git identity for the census.'
}
$fingerprint = if ($SourceMode -ceq 'head') { $headTree } else { Get-I4WorktreeFingerprint -Root $resolvedRoot }
$runnerTree = if ($SourceMode -ceq 'head') { $headTree } else { 'WORKTREE:' + $fingerprint }
$outputArgument = $censusPath.Replace('\', '/')

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $runtimeOutput = @(
        & $GodotExe `
            --headless `
            --path $projectRoot `
            --log-file $logPath `
            --script $runner `
            -- `
            "--output=$outputArgument" `
            "--source-mode=$SourceMode" `
            "--commit=$head" `
            "--tree=$runnerTree" 2>&1
    )
    $runtimeExitCode = $LASTEXITCODE
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
$runtimeText = ($runtimeOutput | ForEach-Object { [string]$_ }) -join "`n"
$runtimeOutput | ForEach-Object { Write-Output $_ }

if ($runtimeExitCode -ne 0) {
    throw "I4 content-census runner failed with exit code $runtimeExitCode"
}
if ($runtimeText -notmatch '(?m)^I4_CONTENT_CENSUS=PASS ') {
    throw 'I4 content-census runner omitted its exact PASS marker.'
}
if ($runtimeText -match '(?m)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:)\s*') {
    throw 'I4 content-census runner emitted a blocking engine diagnostic.'
}
if (-not (Test-Path -LiteralPath $censusPath -PathType Leaf)) {
    throw 'I4 content-census report was not written.'
}

$censusRaw = [System.IO.File]::ReadAllText($censusPath, [System.Text.Encoding]::UTF8)
$census = $censusRaw | ConvertFrom-Json
if ([string]$census.status -cne 'PASS') {
    throw 'I4 content-census JSON did not report PASS.'
}
$summary = $census.summary
if (
    [int]$summary.deploy_tabs -ne 5 -or
    [int]$summary.deploy_summaries -ne 4 -or
    [int]$summary.long_term_modules -ne 6 -or
    [int]$summary.long_term_pages -ne 25 -or
    [int]$summary.long_term_assets -ne 58 -or
    [int]$summary.room_types -ne 6 -or
    [int]$summary.scenarios -ne 6
) {
    throw 'I4 content-census summary is incomplete.'
}

$wrapper = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = 'PASS'
    source_mode = $SourceMode
    head = $head
    head_tree = $headTree
    source_fingerprint_sha256 = $fingerprint
    godot_executable = $GodotExe
    godot_version = (& $GodotExe --version).Trim()
    project_root = $projectRoot
    runner = $runner
    census_path = $censusPath
    census_sha256 = Get-I4Sha256 -Path $censusPath
    runtime_log = $logPath
    runtime_exit_code = $runtimeExitCode
    summary = $summary
}
[System.IO.File]::WriteAllText(
    $wrapperPath,
    (($wrapper | ConvertTo-Json -Depth 20) + "`r`n"),
    (New-Object System.Text.UTF8Encoding($false))
)

Write-Output (
    'I4_CONTENT_CENSUS_WRAPPER=PASS rows={0} sha256={1} report={2}' -f
    [int]$summary.total_rows,
    [string]$wrapper.census_sha256,
    $wrapperPath
)
