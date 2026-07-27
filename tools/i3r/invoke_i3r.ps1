[CmdletBinding()]
param(
    [ValidateSet('preflight', 'quick', 'core', 'ui', 'performance', 'full')]
    [string]$Profile = 'quick',

    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$GodotExe = '',

    [string]$PythonExe = 'python',

    [string]$UERoot = '',

    [switch]$GovernanceOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}
$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$observedRoot = (& git.exe -C $resolvedRoot rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or (Resolve-Path -LiteralPath $observedRoot).Path -ne $resolvedRoot) {
    throw "RepoRoot is not the active Git worktree root: $resolvedRoot"
}

$baseValidator = Join-Path $resolvedRoot 'tools\i3\validate_i3_base.ps1'
$overlayBuilder = Join-Path $resolvedRoot 'tools\i3r\build_base_governance_overlay.py'
$sfxImportGate = Join-Path $resolvedRoot 'tools\i3r\import_ue_generated_sfx.py'
$longTermCurrentValidator = Join-Path $resolvedRoot 'tools\i3r\validate_i3r_long_term_current.ps1'
$i1Invoker = Join-Path $resolvedRoot 'tools\i1\invoke_i1.ps1'
foreach ($requiredPath in @($baseValidator, $overlayBuilder, $sfxImportGate, $longTermCurrentValidator, $i1Invoker)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Missing I3R validation dependency: $requiredPath"
    }
}

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $baseValidator `
    -RepoRoot $resolvedRoot `
    -PythonExe $PythonExe
if ($LASTEXITCODE -ne 0) {
    throw "Immutable I3 Base verification failed with exit code $LASTEXITCODE"
}

& $PythonExe $overlayBuilder --repo-root $resolvedRoot --mode verify
if ($LASTEXITCODE -ne 0) {
    throw "I3R Base governance overlay verification failed with exit code $LASTEXITCODE"
}

$sfxArguments = @(
    $sfxImportGate,
    '--repo-root', $resolvedRoot,
    '--mode', 'verify'
)
if (-not [string]::IsNullOrWhiteSpace($UERoot)) {
    $resolvedUERoot = (Resolve-Path -LiteralPath $UERoot).Path
    $sfxArguments += @('--ue-root', $resolvedUERoot)
}
& $PythonExe @sfxArguments
if ($LASTEXITCODE -ne 0) {
    throw "I3R UE-generated SFX registry/runtime verification failed with exit code $LASTEXITCODE"
}

$longTermArguments = @(
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy', 'Bypass',
    '-File', $longTermCurrentValidator,
    '-RepoRoot', $resolvedRoot
)
& powershell.exe @longTermArguments
if ($LASTEXITCODE -ne 0) {
    throw "I3R current LongTerm governance verification failed with exit code $LASTEXITCODE"
}

if ($GovernanceOnly) {
    Write-Output 'I3R_VALIDATION=PASS scope=governance'
    exit 0
}

$i1Arguments = @(
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy', 'Bypass',
    '-File', $i1Invoker,
    '-Profile', $Profile,
    '-SourceMode', $SourceMode,
    '-RepoRoot', $resolvedRoot
)
if (-not [string]::IsNullOrWhiteSpace($GodotExe)) {
    $i1Arguments += @('-GodotExe', $GodotExe)
}
& powershell.exe @i1Arguments
if ($LASTEXITCODE -ne 0) {
    throw "I1 $Profile validation failed with exit code $LASTEXITCODE"
}

Write-Output "I3R_VALIDATION=PASS scope=$Profile source_mode=$SourceMode"
