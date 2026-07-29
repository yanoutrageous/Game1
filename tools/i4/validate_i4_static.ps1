[CmdletBinding()]
param(
    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$GodotExe = '',

    [string]$PythonExe = 'python',

    [string]$UERoot = '',

    [string]$OutputRoot = '',

    [switch]$GovernanceOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-I4Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

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

function Write-I4Json {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Path
    )
    Write-I4Text -Path $Path -Text (($Value | ConvertTo-Json -Depth 30) + "`r`n")
}

function Invoke-I4Captured {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][scriptblock]$Command,
        [Parameter(Mandatory = $true)][string]$LogPath
    )
    $started = [DateTime]::UtcNow
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $Command 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $text = ($output | ForEach-Object { [string]$_ }) -join "`r`n"
    Write-I4Text -Path $LogPath -Text ($text + "`r`n")
    return [pscustomobject][ordered]@{
        label = $Label
        exit_code = $exitCode
        status = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
        started_utc = $started.ToString('o')
        finished_utc = [DateTime]::UtcNow.ToString('o')
        log_path = $LogPath
        log_sha256 = Get-I4Sha256 -Path $LogPath
        text = $text
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

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $OutputRoot = Join-Path $resolvedRoot ".tmp\i4\static\$runId"
}
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot '.tmp')).TrimEnd('\')
if (-not $resolvedOutputRoot.StartsWith($tmpRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputRoot must stay below the repository .tmp directory: $resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $resolvedOutputRoot -Force)

$requiredPaths = @(
    'docs\20_product\I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md',
    'docs\20_product\I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md',
    'docs\00_governance\I4_EXECUTION_LEDGER.md',
    'docs\00_governance\I4_REQUIREMENT_MATRIX.md',
    'docs\30_engineering\godot\I4_REPRODUCIBLE_PRODUCTION_VALIDATION_RUNBOOK.md',
    'tools\i4\build_i4_content_census.ps1',
    'tools\i4\capture_i4_real_render.ps1',
    'tools\i4\godot_i4_content_census_runner.gd',
    'tools\i4\invoke_i4.ps1',
    'tools\i4\invoke_i4_repetition.ps1',
    'tools\i1\validation_manifest.json'
)
foreach ($relativePath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath (Join-Path $resolvedRoot $relativePath) -PathType Leaf)) {
        throw "Missing I4 validation input: $relativePath"
    }
}

$statusBefore = @(& git.exe -C $resolvedRoot status --porcelain=v1 --untracked-files=all)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read initial Git status.'
}
$changedPaths = @(
    $statusBefore | ForEach-Object {
        $line = [string]$_
        if ($line.Length -lt 4) { return }
        $path = $line.Substring(3)
        if ($path.Contains(' -> ')) {
            $path = $path.Split(@(' -> '), [System.StringSplitOptions]::None)[-1]
        }
        $path.Trim('"').Replace('\', '/')
    }
)
$protectedPattern = '(^|/)(project\.godot|[^/]+\.(?:tscn|tres|res|uid|translation)|\.godot(?:/|$)|\.import(?:/|$))'
$protectedDirty = @($changedPaths | Where-Object { $_ -match $protectedPattern })
if ($protectedDirty.Count -gt 0) {
    throw "Protected Godot files are dirty without an I4 gate: $($protectedDirty -join ', ')"
}

$i4RunnerFiles = @(Get-ChildItem -LiteralPath (Join-Path $resolvedRoot 'Godot\GraytailGodot\tests') -Filter 'i4_*.gd' -File)
$fixedFrameViolations = New-Object System.Collections.Generic.List[string]
foreach ($runnerFile in $i4RunnerFiles) {
    $text = [System.IO.File]::ReadAllText($runnerFile.FullName, [System.Text.Encoding]::UTF8)
    if ($text -match '(?m)^\s*func\s+_frames\s*\(' -or $text -match '(?m)await\s+_frames\s*\(') {
        [void]$fixedFrameViolations.Add($runnerFile.FullName.Substring($resolvedRoot.Length + 1).Replace('\', '/'))
    }
}
if ($fixedFrameViolations.Count -gt 0) {
    throw "I4 critical runner still contains a fixed-frame correctness helper: $($fixedFrameViolations -join ', ')"
}

$manifestPath = Join-Path $resolvedRoot 'tools\i1\validation_manifest.json'
$manifest = [System.IO.File]::ReadAllText($manifestPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$requiredI4RunnerIds = @(
    'I4_DEBUG_SANDBOX',
    'I4_QUANTITY_TRANSACTION',
    'I4_DEPLOY_QUANTITY_UI',
    'I4_IN_RUN_ITEM_AGGREGATION',
    'I4_DEPLOY_INFORMATION_LAYOUT',
    'I4_FONT_ROLE_RASTER',
    'I4_LONG_TERM_NAVIGATION',
    'I4_IN_RUN_VISUAL_PHYSICS'
)
$registeredIds = @($manifest.runners | ForEach-Object { [string]$_.id })
foreach ($runnerId in $requiredI4RunnerIds) {
    if ($registeredIds -cnotcontains $runnerId) {
        throw "I4 runner is not registered in the unified manifest: $runnerId"
    }
    $runner = @($manifest.runners | Where-Object { [string]$_.id -ceq $runnerId })[0]
    $regexProperty = $runner.PSObject.Properties['pass_line_regex']
    if (
        $null -eq $regexProperty -or
        [string]::IsNullOrWhiteSpace([string]$regexProperty.Value) -or
        -not ([string]$regexProperty.Value).StartsWith('^') -or
        -not ([string]$regexProperty.Value).EndsWith('$')
    ) {
        throw "I4 runner lacks an anchored full-line PASS regex: $runnerId"
    }
    if ($null -eq $manifest.diagnostics.expected_cleanup_diagnostics_by_runner.PSObject.Properties[$runnerId]) {
        throw "I4 runner lacks an explicit cleanup-diagnostic contract: $runnerId"
    }
}

$qualityLog = Join-Path $resolvedOutputRoot 'quality_standard_tests.log'
$quality = Invoke-I4Captured -Label 'quality_standard_tests' -LogPath $qualityLog -Command {
    & $PythonExe -B -m unittest tools.i4.tests.test_i4_quality_standard
}
if ($quality.exit_code -ne 0 -or $quality.text -notmatch '(?m)^Ran 12 tests') {
    throw 'I4 quality-standard governance tests failed or did not run all 12 tests.'
}

$i3rLog = Join-Path $resolvedOutputRoot 'i3r_governance.log'
$i3rScript = Join-Path $resolvedRoot 'tools\i3r\invoke_i3r.ps1'
$i3rArguments = @(
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy', 'Bypass',
    '-File', $i3rScript,
    '-RepoRoot', $resolvedRoot,
    '-PythonExe', $PythonExe,
    '-GovernanceOnly'
)
if (-not [string]::IsNullOrWhiteSpace($UERoot)) {
    $i3rArguments += @('-UERoot', $UERoot)
}
$i3r = Invoke-I4Captured -Label 'i3r_governance' -LogPath $i3rLog -Command {
    & powershell.exe @i3rArguments
}
if ($i3r.exit_code -ne 0 -or $i3r.text -notmatch '(?m)^I3R_VALIDATION=PASS scope=governance$') {
    throw 'I3R governance verification failed.'
}

$i1 = $null
$i1ReportPath = ''
if (-not $GovernanceOnly) {
    $i1Log = Join-Path $resolvedOutputRoot 'i1_preflight.log'
    $i1Script = Join-Path $resolvedRoot 'tools\i1\invoke_i1.ps1'
    $i1Arguments = @(
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy', 'Bypass',
        '-File', $i1Script,
        '-Profile', 'preflight',
        '-SourceMode', $SourceMode,
        '-RepoRoot', $resolvedRoot,
        '-GodotExe', $GodotExe
    )
    $i1 = Invoke-I4Captured -Label 'i1_preflight' -LogPath $i1Log -Command {
        & powershell.exe @i1Arguments
    }
    if ($i1.exit_code -ne 0 -or $i1.text -notmatch '(?m)^I1_TEST_STATUS=PASS$') {
        throw 'Unified I1 preflight/static validation failed.'
    }
    $reportMatch = [regex]::Match($i1.text, '(?m)^I1_REPORT_JSON=(.+)$')
    if (-not $reportMatch.Success) {
        throw 'Unified I1 preflight omitted its report path.'
    }
    $i1ReportPath = $reportMatch.Groups[1].Value.Trim()
    if (-not (Test-Path -LiteralPath $i1ReportPath -PathType Leaf)) {
        throw "Unified I1 preflight report is missing: $i1ReportPath"
    }
    $i1Report = [System.IO.File]::ReadAllText($i1ReportPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    if ([string]$i1Report.overall_status -cne 'PASS') {
        throw 'Unified I1 preflight JSON did not report PASS.'
    }
}

$statusAfter = @(& git.exe -C $resolvedRoot status --porcelain=v1 --untracked-files=all)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read final Git status.'
}
if (@(Compare-Object -ReferenceObject $statusBefore -DifferenceObject $statusAfter -CaseSensitive).Count -ne 0) {
    throw 'I4 static validation polluted the active worktree.'
}

$head = (& git.exe -C $resolvedRoot rev-parse HEAD).Trim()
$headTree = (& git.exe -C $resolvedRoot rev-parse 'HEAD^{tree}').Trim()
$reportPath = Join-Path $resolvedOutputRoot 'static_report.json'
$report = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = 'PASS'
    source_mode = $SourceMode
    head = $head
    head_tree = $headTree
    governance_only = [bool]$GovernanceOnly
    required_paths = $requiredPaths
    protected_dirty = $protectedDirty
    i4_runner_count = $i4RunnerFiles.Count
    fixed_frame_correctness_helpers = $fixedFrameViolations.ToArray()
    manifest_sha256 = Get-I4Sha256 -Path $manifestPath
    registered_i4_runner_ids = $requiredI4RunnerIds
    quality_standard_tests = $quality
    i3r_governance = $i3r
    i1_preflight = $i1
    i1_report_path = $i1ReportPath
    i1_report_sha256 = if ([string]::IsNullOrWhiteSpace($i1ReportPath)) { '' } else { Get-I4Sha256 -Path $i1ReportPath }
    worktree_status_unchanged = $true
}
Write-I4Json -Value $report -Path $reportPath

$summaryFormat = (
    'I4_STATIC=PASS source_mode={0} quality=12/12 i4_runners={1} protected_dirty=0 ' +
    'fixed_frame_helpers=0 report={2} sha256={3}'
)
$summaryArguments = [object[]]@(
    $SourceMode,
    $i4RunnerFiles.Count,
    $reportPath,
    (Get-I4Sha256 -Path $reportPath)
)
Write-Output ([string]::Format($summaryFormat, $summaryArguments))
