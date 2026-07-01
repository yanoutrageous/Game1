param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$AgameRoot = "D:\AGAME1"
)

$ErrorActionPreference = "Stop"

function Test-RequiredPath($Path, $Label, [ref]$Failures) {
    if (Test-Path -LiteralPath $Path) {
        Write-Output "$Label=OK $Path"
    } else {
        Write-Output "$Label=MISSING $Path"
        $Failures.Value += 1
    }
}

function Invoke-G40Helper($ScriptName, $MarkerPattern) {
    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Output "$ScriptName=MISSING"
        $script:helperFailures += 1
        return
    }
    Write-Output ""
    Write-Output "## helper: $ScriptName"
    $command = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + $scriptPath + '" 2>NUL'
    $output = @(& cmd.exe /d /c $command)
    $markerLines = @($output | Select-String -Pattern $MarkerPattern)
    if ($markerLines.Count -eq 0) {
        Write-Output "$ScriptName=NO_MARKER"
        $script:helperFailures += 1
        return
    }
    $markerLines | ForEach-Object { Write-Output $_.Line }
}

$failures = 0
$repoPath = Resolve-Path -LiteralPath $RepoRoot
Push-Location $repoPath
try {
    $branch = (git branch --show-current).Trim()
    $head = (git rev-parse HEAD).Trim()
    $main = (git rev-parse main).Trim()
    $originMain = (git rev-parse origin/main).Trim()
    $statusLines = @(git status --porcelain=v1)
    $staged = @(git diff --cached --name-only)
    $projectGodotDirty = $statusLines | Where-Object { $_ -match "Godot/GraytailGodot/project\.godot$" }

    Write-Output "G40_CURRENT_PROJECT_VALIDATION=PASS_WITH_NOTES"
    Write-Output "repo_root=$repoPath"
    Write-Output "branch=$branch"
    Write-Output "head=$head"
    Write-Output "main=$main"
    Write-Output "origin_main=$originMain"
    Write-Output "dirty_count=$($statusLines.Count)"
    Write-Output "staged_count=$($staged.Count)"
    Write-Output "pre_existing_project_godot_dirty=$([bool]$projectGodotDirty)"
    Write-Output "g40_cleanup_in_progress=true"
    Write-Output "duplicate_execution_partial=true"
    Write-Output "duplicate_remaining_manual_and_reference_review=true"
    Write-Output "manual_playtest_claimed=false"
    Write-Output "gameplay_runtime_pass_claimed=false"
    Write-Output "clean_worktree_required=false"

    $slice17Manifest = Join-Path $AgameRoot "reports\g40\duplicate_resolution_plan_current_paths_after_slice16.csv"
    if (Test-Path -LiteralPath $slice17Manifest) {
        $slice17Rows = @(Import-Csv -LiteralPath $slice17Manifest)
        $slice17Existing = @($slice17Rows | Where-Object { $_.actual_current_exists -eq "True" })
        $slice17Missing = @($slice17Rows | Where-Object {
            $_.actual_current_exists -ne "True" -and
            $_.presence_status_after_slice16 -ne "path_unclassified_missing_columns"
        })
        $slice17Unclassified = @($slice17Rows | Where-Object {
            $_.presence_status_after_slice16 -eq "path_unclassified_missing_columns"
        })
        $slice17Manual = @($slice17Existing | Where-Object { $_.decision -eq "needs_manual_decision" })
        $slice17Blocked = @($slice17Existing | Where-Object { $_.blocked_by_reference -eq "True" })
        $slice17Protected = @($slice17Existing | Where-Object { $_.protected -eq "True" })
        $slice17Active = @($slice17Existing | Where-Object { $_.active_repo -eq "True" })
        $slice17Workflow = @($slice17Existing | Where-Object { $_.current_root_category -eq "workflow" })

        Write-Output "duplicate_manifest_after_slice16=OK $slice17Manifest"
        Write-Output "duplicate_manifest_after_slice16_total_rows=$($slice17Rows.Count)"
        Write-Output "duplicate_manifest_after_slice16_existing_rows=$($slice17Existing.Count)"
        Write-Output "duplicate_manifest_after_slice16_missing_rows=$($slice17Missing.Count)"
        Write-Output "duplicate_manifest_after_slice16_unclassified_rows=$($slice17Unclassified.Count)"
        Write-Output "duplicate_remaining_needs_manual_decision_after_slice16=$($slice17Manual.Count)"
        Write-Output "duplicate_remaining_blocked_by_reference_after_slice16=$($slice17Blocked.Count)"
        Write-Output "duplicate_protected_source_rows_still_present_after_slice16=$($slice17Protected.Count)"
        Write-Output "duplicate_active_repo_rows_still_present_after_slice16=$($slice17Active.Count)"
        Write-Output "duplicate_workflow_cache_report_rows_still_present_after_slice16=$($slice17Workflow.Count)"

        $slice18Closure = Join-Path $AgameRoot "reports\g40\generated_cache_duplicate_policy_closure_after_slice17.csv"
        if (Test-Path -LiteralPath $slice18Closure) {
            $slice18Rows = @(Import-Csv -LiteralPath $slice18Closure)
            $slice18BadRows = @($slice18Rows | Where-Object {
                $_.slice18_decision -ne "generated-ignore" -or
                $_.slice18_action -ne "processed_by_policy_no_delete" -or
                $_.slice18_physical_action -ne "none" -or
                $_.slice18_deleted -ne "False" -or
                $_.slice18_archived -ne "False"
            })
            $slice18PathSet = @{}
            foreach ($row in $slice18Rows) {
                if (-not [string]::IsNullOrWhiteSpace($row.current_file_path)) {
                    $slice18PathSet[$row.current_file_path] = $true
                }
            }
            $slice18RemainingExisting = @($slice17Existing | Where-Object {
                -not $slice18PathSet.ContainsKey($_.current_file_path)
            })
            $slice18Manual = @($slice18RemainingExisting | Where-Object { $_.decision -eq "needs_manual_decision" })
            $slice18Blocked = @($slice18RemainingExisting | Where-Object { $_.blocked_by_reference -eq "True" })
            $slice18Protected = @($slice18RemainingExisting | Where-Object { $_.protected -eq "True" })
            $slice18Active = @($slice18RemainingExisting | Where-Object { $_.active_repo -eq "True" })
            $slice18WorkflowNotActionable = @($slice18RemainingExisting | Where-Object {
                $_.current_root_category -eq "workflow" -and $_.block_reason_9b -eq "not_actionable_in_9b"
            })
            $slice18WorkflowStateReceipt = @($slice18RemainingExisting | Where-Object {
                $_.current_root_category -eq "workflow" -and $_.block_reason_9b -eq "workflow_state_policy_or_receipt_manual_decision"
            })

            Write-Output "duplicate_generated_cache_policy_closure_after_slice18=OK $slice18Closure"
            Write-Output "duplicate_generated_cache_policy_closed_after_slice18=$($slice18Rows.Count)"
            Write-Output "duplicate_generated_cache_policy_bad_rows_after_slice18=$($slice18BadRows.Count)"
            Write-Output "duplicate_generated_cache_deleted_after_slice18=false"
            Write-Output "duplicate_generated_cache_archived_after_slice18=false"
            Write-Output "duplicate_existing_rows_not_policy_closed_after_slice18=$($slice18RemainingExisting.Count)"
            Write-Output "duplicate_remaining_needs_manual_decision_after_slice18=$($slice18Manual.Count)"
            Write-Output "duplicate_remaining_blocked_by_reference_after_slice18=$($slice18Blocked.Count)"
            Write-Output "duplicate_protected_source_rows_still_present_after_slice18=$($slice18Protected.Count)"
            Write-Output "duplicate_active_repo_rows_still_present_after_slice18=$($slice18Active.Count)"
            Write-Output "duplicate_workflow_not_actionable_rows_after_slice18=$($slice18WorkflowNotActionable.Count)"
            Write-Output "duplicate_workflow_state_receipt_rows_after_slice18=$($slice18WorkflowStateReceipt.Count)"
            if ($slice18Rows.Count -ne 10002 -or $slice18BadRows.Count -ne 0) {
                $failures += 1
            }
        } else {
            Write-Output "duplicate_generated_cache_policy_closure_after_slice18=MISSING $slice18Closure"
        }
    } else {
        Write-Output "duplicate_manifest_after_slice16=MISSING $slice17Manifest"
    }

    if ($staged.Count -gt 0) {
        Write-Output "staged_warning=staged files exist; G40 slices should keep staged empty until commit gate"
    }

    Test-RequiredPath (Join-Path $repoPath "docs\README.md") "docs_readme" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\INDEX.md") "docs_index" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\10_current\CURRENT_STATE.md") "current_state" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\10_current\CAPABILITY_MATRIX.yaml") "capability_matrix" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\00_governance\DOC_PLACEMENT_STANDARD.md") "doc_placement_standard" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\00_governance\SOURCE_REGISTRY.md") "source_registry" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\00_governance\DUPLICATE_DOC_LEDGER.md") "duplicate_doc_ledger" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\40_validation\VALIDATION_INDEX.md") "validation_index" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\50_stages\active\STAGE_INDEX.md") "active_stage_index" ([ref]$failures)
    Test-RequiredPath (Join-Path $repoPath "docs\50_stages\closed\STAGE_INDEX.md") "closed_stage_index" ([ref]$failures)

    foreach ($path in @("active","sources","handoff","archive","reports","workflow","tools","external")) {
        Test-RequiredPath (Join-Path $AgameRoot $path) "topology_$path" ([ref]$failures)
    }
    foreach ($path in @("sources\docs","sources\docs_governance","sources\art","sources\draw","handoff\connection")) {
        Test-RequiredPath (Join-Path $AgameRoot $path) "canonical_$($path -replace '\\','_')" ([ref]$failures)
    }

    Write-Output ""
    Write-Output "## current_gate helpers"
    $script:helperFailures = 0
    Invoke-G40Helper "inspect_dirty_state.ps1" "G40_DIRTY_STATE_INSPECTION|tracked_diff_count|staged_diff_count|untracked_count|pre_existing_project_godot"
    Invoke-G40Helper "scan_g40_path_references.ps1" "G40_PATH_REFERENCE_SCAN|legacy_hit_count|unknown_count|current_legacy_mapping|historical_allowed"
    Invoke-G40Helper "validate_g40_cleanup_topology.ps1" "G40_TOPOLOGY_VALIDATION|G40_TOPOLOGY_VALIDATION_RESULT|warning_count|phase="
    Invoke-G40Helper "clean_generated_dirty_state.ps1" "G40_GENERATED_DIRTY_DRY_RUN|apply_requested|mutation_performed|candidate_count"
    Invoke-G40Helper "prepare_validation_clean_state.ps1" "G40_VALIDATION_CLEAN_STATE_DRY_RUN|mutation_performed|blocking_dirty_count|safe_generated_candidates|requires_manual_review"

    Write-Output ""
    Write-Output "## optional_regression_not_run_in_current_g40_gate"
    Write-Output "Godot smoke=not_run"
    Write-Output "gameplay runtime=not_run"
    Write-Output "manual playtest=not_run"
    Write-Output "historical full validators=not_run"

    if ($failures -gt 0 -or $script:helperFailures -gt 0) {
        Write-Output "G40_CURRENT_PROJECT_VALIDATION_RESULT=FAIL"
        Write-Output "G40_UNIFIED_VALIDATION=FAIL"
        exit 1
    }

    Write-Output "G40_CURRENT_PROJECT_VALIDATION_RESULT=PASS_WITH_NOTES"
    Write-Output "G40_UNIFIED_VALIDATION=PASS_WITH_NOTES"
} finally {
    Pop-Location
}
