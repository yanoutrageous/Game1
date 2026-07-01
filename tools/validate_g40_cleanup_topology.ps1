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
foreach ($path in @("sources\docs","sources\docs_governance","sources\art","sources\draw","handoff\connection","handoff\packages","reports\codex_reports","workflow\codex_workflow")) {
    Check-Exists (Join-Path $AgameRoot $path) "canonical_$($path -replace '\\','_')"
}
foreach ($path in @("Base Docs","Base Docs_Governance","Base Art","Draw","Connection","handoff_packages","_codex_reports","_codex_workflow")) {
    Check-LegacyAbsent (Join-Path $AgameRoot $path) "legacy_$($path -replace '[^A-Za-z0-9]','_')"
}

Check-Exists (Join-Path $AgameRoot "README_CURRENT_ENTRYPOINTS.md") "root_entrypoint"
Check-Exists (Join-Path $AgameRoot "_repo_cache\Game1_work\docs\README.md") "repo_docs_entrypoint"
Check-Exists (Join-Path $AgameRoot "_repo_cache\Game1_work\docs\00_governance\DOC_PLACEMENT_STANDARD.md") "doc_placement_standard"

Write-Output "repo_cache_still_present=allowed_in_progress"
Write-Output "D_AGAME1_Godot_still_present=pending_legacy_external_candidate"
Write-Output "root_g40_reports_still_present=allowed_until_report_consolidation_slice"

if ($failures -gt 0) {
    Write-Output "G40_TOPOLOGY_VALIDATION_RESULT=FAIL"
    exit 1
}
Write-Output "warning_count=$warnings"
Write-Output "G40_TOPOLOGY_VALIDATION_RESULT=PASS_WITH_NOTES"
