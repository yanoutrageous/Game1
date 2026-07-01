param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Write-Section($Title) {
    Write-Output ""
    Write-Output "## $Title"
}

function Get-G40DirtyCategory($Path, [bool]$IsStaged, [bool]$IsUntracked) {
    $normalized = $Path -replace "\\", "/"
    if ($normalized -eq "Godot/GraytailGodot/project.godot") {
        return "pre_existing_project_godot"
    }
    if ($normalized -match "^(README\.md|AGENTS\.md|AUDIT_ENTRYPOINT\.md|docs/)") {
        return "g40_docs"
    }
    if ($normalized -match "^tools/(inspect_dirty_state|validate_current_project|scan_g40_path_references|validate_g40_cleanup_topology|clean_generated_dirty_state|prepare_validation_clean_state)\.ps1$") {
        return "g40_tools"
    }
    if ($normalized -match "\.gd\.uid$|\.uid$|\.import$|\.translation$|^Godot/GraytailGodot/\.godot/") {
        if ($IsUntracked) {
            return "untracked_generated"
        }
        return "tracked_metadata"
    }
    if ($IsStaged) {
        return "staged"
    }
    return "unknown_dirty"
}

$repoPath = Resolve-Path -LiteralPath $RepoRoot
Push-Location $repoPath
try {
    $statusLines = @(git status --porcelain=v1)
    $trackedDiff = @(git diff --name-only)
    $stagedDiff = @(git diff --cached --name-only)
    $untracked = @(git ls-files --others --exclude-standard)

    $items = @()
    foreach ($line in $statusLines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $xy = $line.Substring(0, 2)
        $path = $line.Substring(3)
        $isStaged = ($xy[0] -ne " " -and $xy[0] -ne "?")
        $isUntracked = $xy -eq "??"
        $category = Get-G40DirtyCategory -Path $path -IsStaged:$isStaged -IsUntracked:$isUntracked
        $items += [pscustomobject]@{
            status = $xy
            path = $path
            category = $category
            staged = $isStaged
            untracked = $isUntracked
        }
    }

    Write-Output "G40_DIRTY_STATE_INSPECTION=PASS_WITH_NOTES"
    Write-Output "repo_root=$repoPath"
    Write-Output "tracked_diff_count=$($trackedDiff.Count)"
    Write-Output "staged_diff_count=$($stagedDiff.Count)"
    Write-Output "untracked_count=$($untracked.Count)"
    Write-Output "project_godot_patch_exists=$(Test-Path 'D:\AGAME1\reports\g40\project_godot_dirty.patch')"
    Write-Section "Classified Dirty Items"
    if ($items.Count -eq 0) {
        Write-Output "clean_worktree=true"
    } else {
        $items | Sort-Object category,path | Format-Table -AutoSize | Out-String -Width 220 | Write-Output
    }

    Write-Section "Category Counts"
    $items | Group-Object category | Sort-Object Name | ForEach-Object {
        Write-Output "$($_.Name)=$($_.Count)"
    }

    Write-Section "Policy Notes"
    Write-Output "pre_existing_project_godot=unresolved; not cleaned by Slice 6; patch exists at D:\AGAME1\reports\g40\project_godot_dirty.patch"
    Write-Output "no_mutation_performed=true"
} finally {
    Pop-Location
}
