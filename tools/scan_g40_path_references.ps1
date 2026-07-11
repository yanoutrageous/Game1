param(
    [string]$AgameRoot = "D:\AGAME1"
)

$ErrorActionPreference = "Stop"

$pattern = "D:\\AGAME1\\Base Docs|D:\\AGAME1\\Base Art|D:\\AGAME1\\Connection|D:\\AGAME1\\Draw|D:\\AGAME1\\_codex_workflow|D:\\AGAME1\\_codex_reports|D:\\AGAME1\\handoff_packages"
$targets = @(
    "README_CURRENT_ENTRYPOINTS.md",
    "INDEX.md",
    "reports/g40/topology_rebuild_log.md",
    "reports/g40/g40_initial_state.md",
    "reports/g40/path_reference_impact.md",
    "reports/g40/cleanup_decisions.md",
    "reports/g40/repo_worktree_inventory.md",
    "reports/g40/path_reference_migration_log.md",
    "active/Game1_work/README.md",
    "active/Game1_work/AGENTS.md",
    "active/Game1_work/AUDIT_ENTRYPOINT.md",
    "active/Game1_work/docs/README.md",
    "active/Game1_work/docs/INDEX.md",
    "active/Game1_work/docs/10_current",
    "active/Game1_work/docs/00_governance"
)

Push-Location $AgameRoot
try {
    $lines = @()
    if (Get-Command rg -ErrorAction SilentlyContinue) {
        $lines = @(rg -n $pattern @targets 2>$null)
    } else {
        foreach ($target in $targets) {
            if (Test-Path $target) {
                $lines += Select-String -Path $target -Pattern $pattern -Recurse | ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line)" }
            }
        }
    }

    $items = @()
    foreach ($line in $lines) {
        if ($line -notmatch "^(.*?):(\d+):(.*)$") { continue }
        $path = $matches[1] -replace "/", "\"
        $lineNo = [int]$matches[2]
        $text = $matches[3].Trim()
        $severity = "unknown"
        if ($text -match "Legacy path before G40|Moved to:|Do not use as current canonical path|Legacy label|legacy path") {
            $severity = "current_legacy_mapping"
        } elseif ($path -match "SOURCE_REGISTRY\.md" -and $text -match "^\| .*D:\\AGAME1\\(sources|handoff)\\.*\| .*D:\\AGAME1\\") {
            $severity = "current_legacy_mapping"
        } elseif ($path -match "REPORT|P2_EXECUTION_REPORT|UPDATE_REPORT") {
            $severity = "historical_allowed"
        } elseif ($path -match "reports\\g40|topology_rebuild_log|g40_initial_state|path_reference_impact|cleanup_decisions|repo_worktree_inventory|path_reference_migration_log") {
            $severity = "historical_allowed"
        }
        $items += [pscustomobject]@{severity=$severity; path=$path; line=$lineNo; text=$text}
    }

    $unknown = @($items | Where-Object { $_.severity -eq "unknown" })
    Write-Output "G40_PATH_REFERENCE_SCAN=PASS_WITH_NOTES"
    Write-Output "legacy_hit_count=$($items.Count)"
    Write-Output "unknown_count=$($unknown.Count)"
    $items | Group-Object severity | Sort-Object Name | ForEach-Object {
        Write-Output "$($_.Name)=$($_.Count)"
    }
    Write-Output ""
    Write-Output "## Scoped Hits"
    $items | Sort-Object severity,path,line | Format-Table -AutoSize | Out-String -Width 260 | Write-Output
    if ($unknown.Count -gt 0) {
        Write-Output "unknown_warning=unknown hits require later Slice 7/9 review before cleanup decisions"
    }
} finally {
    Pop-Location
}
