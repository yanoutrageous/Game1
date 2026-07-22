[CmdletBinding()]
param(
    [string]$RepoRoot = '',
    [string]$PythonExe = 'python'
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (& git rev-parse --show-toplevel).Trim()
}
if ([string]::IsNullOrWhiteSpace($RepoRoot) -or -not (Test-Path -LiteralPath $RepoRoot -PathType Container)) {
    throw "Unable to resolve active Git worktree root: $RepoRoot"
}

$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$observedRoot = (& git -C $resolvedRoot rev-parse --show-toplevel).Trim()
if ((Resolve-Path -LiteralPath $observedRoot).Path -ne $resolvedRoot) {
    throw "RepoRoot is not the active worktree root: $resolvedRoot"
}

$validator = Join-Path $resolvedRoot 'tools/i3/import_base_sources.py'
if (-not (Test-Path -LiteralPath $validator -PathType Leaf)) {
    throw "Missing I3 Base validator: $validator"
}

& $PythonExe $validator --repo-root $resolvedRoot --mode committed
if ($LASTEXITCODE -ne 0) {
    throw "I3 Base committed verification failed with exit code $LASTEXITCODE"
}
