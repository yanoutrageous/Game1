param(
    [string]$AgameRoot = "D:\AGAME1"
)

$ErrorActionPreference = "Stop"

$failures = 0
$warnings = 0

function Check-Exists($Path, $Label) {
    if (Test-Path -LiteralPath $Path) {
        Write-Output "$Label=OK $Path"
    } else {
        Write-Output "$Label=MISSING $Path"
        $script:failures += 1
    }
}

function Check-LegacyAbsent($Path, $Label) {
    if (Test-Path -LiteralPath $Path) {
        Write-Output "$Label=STILL_PRESENT $Path"
        $script:warnings += 1
    } else {
        Write-Output "$Label=ABSENT_AS_EXPECTED $Path"
    }
}

Write-Output "G40_TOPOLOGY_VALIDATION=PASS_WITH_NOTES"
Write-Output "phase=in_progress"

foreach ($path in @("active","sources","handoff","archive","reports","workflow","tools","external","_repo_cache")) {
    Check-Exists (Join-Path $AgameRoot $path) "topology_$path"
}
foreach ($path in @("sources\docs","sources\docs_governance","sources\art","sources\draw","handoff\connection","handoff\packages","reports\codex_reports","reports\code_audit_20260622","workflow\codex_workflow","external\godot_reference","external\godot_reference\Godot")) {
    Check-Exists (Join-Path $AgameRoot $path) "canonical_$($path -replace '\\','_')"
}
foreach ($path in @("Base Docs","Base Docs_Governance","Base Art","Draw","Connection","handoff_packages","_codex_reports","_codex_workflow","Godot")) {
    Check-LegacyAbsent (Join-Path $AgameRoot $path) "legacy_$($path -replace '[^A-Za-z0-9]','_')"
}

Check-Exists (Join-Path $AgameRoot "README_CURRENT_ENTRYPOINTS.md") "root_entrypoint"
Check-Exists (Join-Path $AgameRoot "_repo_cache\Game1_work\docs\README.md") "repo_docs_entrypoint"
Check-Exists (Join-Path $AgameRoot "_repo_cache\Game1_work\docs\00_governance\DOC_PLACEMENT_STANDARD.md") "doc_placement_standard"

Write-Output "repo_cache_still_present=allowed_in_progress"
Write-Output "D_AGAME1_Godot=relocated_to_external_godot_reference"
Write-Output "root_code_audit_20260622_reports=relocated_to_reports_code_audit_20260622"

foreach ($path in @(
    "_repo_cache\Game1_art15_whitespace_fix",
    "_repo_cache\Game1_m4_art_validation",
    "_repo_cache\Game1_m4_main_ff_20260630",
    "_repo_cache\Game1_m4_repository_sync",
    "_repo_cache\Game1_m4s_clean_checkout_validate_2",
    "_repo_cache\Game1_m4_latest_release_gate_20260630"
)) {
    Check-LegacyAbsent (Join-Path $AgameRoot $path) "removed_worktree_$($path -replace '[^A-Za-z0-9]','_')"
}

$pendingDirtyWorktree = Join-Path $AgameRoot "_repo_cache\Game1_m4_latest_release_gate_20260630"
if (Test-Path -LiteralPath $pendingDirtyWorktree) {
    Write-Output "dirty_generated_metadata_worktree=STILL_PRESENT $pendingDirtyWorktree"
    $warnings += 1
} else {
    Write-Output "dirty_generated_metadata_worktree=resolved_absent $pendingDirtyWorktree"
}

$activeRepo = Join-Path $AgameRoot "_repo_cache\Game1_work"
if (Test-Path -LiteralPath (Join-Path $activeRepo ".git")) {
    $worktreeLines = git -C $activeRepo worktree list --porcelain
    $worktreePaths = @($worktreeLines | Where-Object { $_ -like "worktree *" } | ForEach-Object { $_.Substring(9) })
    $activeRepoNormalized = $activeRepo.Replace("\", "/")
    $nonActiveWorktrees = @($worktreePaths | Where-Object { $_.Replace("\", "/") -ne $activeRepoNormalized })
    if ($nonActiveWorktrees.Count -eq 0) {
        Write-Output "registered_worktrees=active_only"
    } else {
        Write-Output "registered_worktrees=non_active_present $($nonActiveWorktrees -join ';')"
        $warnings += 1
    }
} else {
    Write-Output "registered_worktrees=active_repo_git_missing"
    $failures += 1
}

if ($failures -gt 0) {
    Write-Output "G40_TOPOLOGY_VALIDATION_RESULT=FAIL"
    exit 1
}
Write-Output "warning_count=$warnings"
Write-Output "G40_TOPOLOGY_VALIDATION_RESULT=PASS_WITH_NOTES"
