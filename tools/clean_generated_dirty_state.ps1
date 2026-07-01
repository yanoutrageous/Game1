param(
    [switch]$Apply,
    [switch]$AllowProjectGodot,
    [switch]$AllowTrackedMetadata,
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Is-GeneratedCandidate($Path) {
    $normalized = $Path -replace "\\", "/"
    return ($normalized -match "\.gd\.uid$|\.uid$|\.import$|\.translation$|^Godot/GraytailGodot/\.godot/")
}

$repoPath = Resolve-Path -LiteralPath $RepoRoot
Push-Location $repoPath
try {
    $statusLines = @(git status --porcelain=v1)
    $candidates = @()
    foreach ($line in $statusLines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $xy = $line.Substring(0, 2)
        $path = $line.Substring(3)
        if (Is-GeneratedCandidate $path -or $path -eq "Godot/GraytailGodot/project.godot") {
            $kind = "generated_metadata"
            if ($path -eq "Godot/GraytailGodot/project.godot") { $kind = "project_godot_refused" }
            elseif ($xy -ne "??") { $kind = "tracked_metadata_refused" }
            $candidates += [pscustomobject]@{status=$xy; path=$path; kind=$kind}
        }
    }

    if ($Apply) {
        Write-Output "G40_GENERATED_DIRTY_DRY_RUN=REFUSED"
        Write-Output "apply_requested=true"
        Write-Output "mutation_performed=false"
        Write-Error "Slice 6 refuses cleanup application. A later audited gate is required even when -Apply is supplied."
        exit 2
    }

    Write-Output "G40_GENERATED_DIRTY_DRY_RUN=PASS"
    Write-Output "apply_requested=false"
    Write-Output "mutation_performed=false"
    Write-Output "project_godot_default_policy=refused"
    Write-Output "tracked_metadata_default_policy=refused"
    Write-Output "candidate_count=$($candidates.Count)"
    if ($candidates.Count -gt 0) {
        $candidates | Sort-Object kind,path | Format-Table -AutoSize | Out-String -Width 220 | Write-Output
    }
} finally {
    Pop-Location
}
