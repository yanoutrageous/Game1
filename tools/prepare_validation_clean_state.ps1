param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$repoPath = Resolve-Path -LiteralPath $RepoRoot
Push-Location $repoPath
try {
    $statusLines = @(git status --porcelain=v1)
    $blocking = @()
    $safeGenerated = @()
    $requiresManual = @()
    foreach ($line in $statusLines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $xy = $line.Substring(0, 2)
        $path = $line.Substring(3)
        $normalized = $path -replace "\\", "/"
        if ($normalized -eq "Godot/GraytailGodot/project.godot") {
            $requiresManual += [pscustomobject]@{status=$xy; path=$path; reason="pre_existing_project_godot_unresolved"}
        } elseif ($normalized -match "^(README\.md|AGENTS\.md|AUDIT_ENTRYPOINT\.md|docs/|tools/)") {
            $blocking += [pscustomobject]@{status=$xy; path=$path; reason="g40_working_change"}
        } elseif ($normalized -match "\.gd\.uid$|\.uid$|\.import$|\.translation$|^Godot/GraytailGodot/\.godot/") {
            $safeGenerated += [pscustomobject]@{status=$xy; path=$path; reason="generated_metadata_candidate_requires_gate"}
        } else {
            $requiresManual += [pscustomobject]@{status=$xy; path=$path; reason="unknown_dirty_requires_review"}
        }
    }

    Write-Output "G40_VALIDATION_CLEAN_STATE_DRY_RUN=PASS_WITH_NOTES"
    Write-Output "mutation_performed=false"
    Write-Output "blocking_dirty_count=$($blocking.Count)"
    Write-Output "safe_generated_candidates=$($safeGenerated.Count)"
    Write-Output "requires_manual_review=$($requiresManual.Count)"
    Write-Output ""
    Write-Output "## blocking_dirty"
    $blocking | Format-Table -AutoSize | Out-String -Width 220 | Write-Output
    Write-Output "## safe_generated_candidates"
    $safeGenerated | Format-Table -AutoSize | Out-String -Width 220 | Write-Output
    Write-Output "## requires_manual_review"
    $requiresManual | Format-Table -AutoSize | Out-String -Width 220 | Write-Output
    Write-Output "## suggested_commands"
    Write-Output "No command is executed by this script."
    Write-Output "Later audited gates may decide exact git restore/remove commands for generated metadata."
    Write-Output "Do not stage project.godot unless a later metadata/config remediation gate approves it."
} finally {
    Pop-Location
}
