[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$RunsRoot = "",

    [string[]]$RunId = @(),

    [string[]]$RemoveDuplicateWorktreeRunId = @(),

    [string[]]$RemoveCommittedWorktreeRunId = @(),

    [string[]]$RemoveScratchDirectoryName = @(),

    [switch]$SkipTransient,

    [switch]$Apply
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0


function Get-I1PruneCanonicalPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}


function Test-I1PrunePathWithin {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )

    $candidate = Get-I1PruneCanonicalPath -Path $Path
    $boundary = (Get-I1PruneCanonicalPath -Path $Root) + '\'
    return $candidate.StartsWith($boundary, [System.StringComparison]::OrdinalIgnoreCase)
}


function Get-I1PruneRepoRoot {
    param([Parameter(Mandatory = $true)][string]$Path)

    $output = @(& git -C $Path rev-parse --show-toplevel 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to resolve Git root from: $Path`n$($output -join [Environment]::NewLine)"
    }
    return Get-I1PruneCanonicalPath -Path ([string]$output[-1])
}


function Get-I1PruneTargetInspection {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Prune target does not exist: $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Refusing reparse-point target: $Path"
    }
    [int64]$total = if ($item.PSIsContainer) { 0 } else { [int64]$item.Length }
    if ($item.PSIsContainer) {
        Get-ChildItem -LiteralPath $Path -Recurse -Force | ForEach-Object {
            if (($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Refusing target containing a reparse point: $($_.FullName)"
            }
            if (-not $_.PSIsContainer) {
                $total += [int64]$_.Length
            }
        }
    }
    return [pscustomobject][ordered]@{
        logical_bytes = $total
        reparse_points = 0
    }
}


function Get-I1PruneReportIdentity {
    param([Parameter(Mandatory = $true)][string]$RunPath)

    $reportPath = Join-Path $RunPath "report.json"
    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
        throw "Duplicate worktree removal requires report.json: $RunPath"
    }
    $reportText = Get-Content -LiteralPath $reportPath -Raw
    # Read only the fixed-format identity fields. This also supports historical
    # reports whose captured engine output exceeds Windows PowerShell 5.1's JSON
    # parser limits. Every field must resolve to one unique value.
    $headValues = @(
        [regex]::Matches($reportText, '"head"\s*:\s*"([0-9a-fA-F]{40})"') |
            ForEach-Object { $_.Groups[1].Value.ToLowerInvariant() } |
            Select-Object -Unique
    )
    $fingerprintValues = @(
        [regex]::Matches($reportText, '"before_fingerprint_sha256"\s*:\s*"([0-9a-fA-F]{64})"') |
            ForEach-Object { $_.Groups[1].Value.ToUpperInvariant() } |
            Select-Object -Unique
    )
    $fileCountValues = @(
        [regex]::Matches($reportText, '"before_file_count"\s*:\s*([0-9]+)') |
            ForEach-Object { [int64]$_.Groups[1].Value } |
            Select-Object -Unique
    )
    $sourceModeValues = @(
        [regex]::Matches($reportText, '"source_mode"\s*:\s*"([^"]+)"') |
            ForEach-Object { $_.Groups[1].Value } |
            Select-Object -Unique
    )
    $dirtyValues = @(
        [regex]::Matches($reportText, '"protected_dirty_state_included"\s*:\s*(true|false)') |
            ForEach-Object { $_.Groups[1].Value } |
            Select-Object -Unique
    )
    if (
        $headValues.Count -ne 1 -or
        $fingerprintValues.Count -ne 1 -or
        $fileCountValues.Count -ne 1 -or
        $sourceModeValues.Count -ne 1 -or
        $dirtyValues.Count -ne 1
    ) {
        throw "Historical report identity is missing or ambiguous: $reportPath"
    }
    $head = [string]$headValues[0]
    $fingerprint = [string]$fingerprintValues[0]
    [int64]$fileCount = [int64]$fileCountValues[0]
    $sourceMode = [string]$sourceModeValues[0]
    $protectedDirtyStateIncluded = [string]$dirtyValues[0] -ceq "true"
    if ([string]::IsNullOrWhiteSpace($head) -or [string]::IsNullOrWhiteSpace($fingerprint) -or $fileCount -le 0) {
        throw "report.json lacks source/fingerprint identity: $reportPath"
    }
    return [pscustomobject][ordered]@{
        head = $head
        fingerprint = $fingerprint
        file_count = $fileCount
        source_mode = $sourceMode
        protected_dirty_state_included = $protectedDirtyStateIncluded
        report_path = $reportPath
        report_sha256 = (Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash
    }
}


if ([string]::IsNullOrWhiteSpace($RunsRoot)) {
    $scriptRepoRoot = Get-I1PruneRepoRoot -Path $PSScriptRoot
    $RunsRoot = Join-Path $scriptRepoRoot ".tmp\i1"
}
if (-not (Test-Path -LiteralPath $RunsRoot -PathType Container)) {
    throw "I1 runs root does not exist: $RunsRoot"
}

$runs = Get-I1PruneCanonicalPath -Path (Resolve-Path -LiteralPath $RunsRoot).ProviderPath
$candidateRepo = Split-Path -Parent (Split-Path -Parent $runs)
$repoRoot = Get-I1PruneRepoRoot -Path $candidateRepo
$expectedRunsRoot = Get-I1PruneCanonicalPath -Path (Join-Path $repoRoot ".tmp\i1")
if (-not [string]::Equals($runs, $expectedRunsRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RunsRoot must be the selected Git worktree's .tmp\\i1 directory: expected=$expectedRunsRoot actual=$runs"
}

$runPattern = '^\d{8}T\d{9}Z_[0-9a-f]{8}$'
$allRunDirectories = @(
    Get-ChildItem -LiteralPath $runs -Directory |
        Where-Object { $_.Name -match $runPattern } |
        Sort-Object Name
)
$runById = @{}
foreach ($runDirectory in $allRunDirectories) {
    $runById[$runDirectory.Name] = $runDirectory
}
$reportIdentityCache = @{}
$reportIdentityFailure = @{}


function Get-I1PruneCachedReportIdentity {
    param(
        [Parameter(Mandatory = $true)]$RunDirectory,
        [switch]$Required
    )

    $identityRunId = [string]$RunDirectory.Name
    if ($reportIdentityCache.ContainsKey($identityRunId)) {
        return $reportIdentityCache[$identityRunId]
    }
    if ($reportIdentityFailure.ContainsKey($identityRunId)) {
        if ($Required) {
            throw [string]$reportIdentityFailure[$identityRunId]
        }
        return $null
    }
    try {
        $identity = Get-I1PruneReportIdentity -RunPath $RunDirectory.FullName
        $reportIdentityCache[$identityRunId] = $identity
        return $identity
    } catch {
        $message = $_.Exception.Message
        $reportIdentityFailure[$identityRunId] = $message
        if ($Required) {
            throw $message
        }
        return $null
    }
}

$selectedRunIds = @()
if ($RunId.Count -eq 0) {
    $selectedRunIds = @($allRunDirectories | ForEach-Object { $_.Name })
} else {
    $selectedRunIds = @($RunId | Select-Object -Unique)
}
foreach ($selectedRunId in $selectedRunIds) {
    if (-not $runById.ContainsKey($selectedRunId)) {
        throw "Unknown I1 run id: $selectedRunId"
    }
}

$removeWorktreeIds = @($RemoveDuplicateWorktreeRunId | Select-Object -Unique)
foreach ($removeWorktreeId in $removeWorktreeIds) {
    if (-not $runById.ContainsKey($removeWorktreeId)) {
        throw "Unknown duplicate-worktree run id: $removeWorktreeId"
    }
}

$removeCommittedWorktreeIds = @($RemoveCommittedWorktreeRunId | Select-Object -Unique)
foreach ($removeCommittedWorktreeId in $removeCommittedWorktreeIds) {
    if (-not $runById.ContainsKey($removeCommittedWorktreeId)) {
        throw "Unknown committed-worktree run id: $removeCommittedWorktreeId"
    }
    if ($removeWorktreeIds -contains $removeCommittedWorktreeId) {
        throw "A worktree run id cannot be both duplicate and committed: $removeCommittedWorktreeId"
    }
    $committedIdentity = Get-I1PruneCachedReportIdentity -RunDirectory $runById[$removeCommittedWorktreeId] -Required
    if (
        [bool]$committedIdentity.protected_dirty_state_included -or
        [string]$committedIdentity.source_mode -cne "head"
    ) {
        throw "Committed worktree removal requires a clean head-mode report: $removeCommittedWorktreeId"
    }
    $commitProbe = @(& git -C $repoRoot cat-file -e "$($committedIdentity.head)^{commit}" 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Committed worktree source commit is not reachable: run=$removeCommittedWorktreeId head=$($committedIdentity.head)"
    }
}
$removeAnyWorktreeIds = @($removeWorktreeIds + $removeCommittedWorktreeIds | Select-Object -Unique)

$replacementByRemovedRun = @{}
foreach ($removeWorktreeId in $removeWorktreeIds) {
    $removedIdentity = Get-I1PruneCachedReportIdentity -RunDirectory $runById[$removeWorktreeId] -Required
    $replacement = $null
    foreach ($candidate in $allRunDirectories) {
        if ($candidate.Name -eq $removeWorktreeId -or $removeWorktreeIds -contains $candidate.Name) {
            continue
        }
        if (-not (Test-Path -LiteralPath (Join-Path $candidate.FullName "worktree") -PathType Container)) {
            continue
        }
        $candidateReport = Join-Path $candidate.FullName "report.json"
        if (-not (Test-Path -LiteralPath $candidateReport -PathType Leaf)) {
            continue
        }
        $candidateIdentity = Get-I1PruneCachedReportIdentity -RunDirectory $candidate
        if ($null -eq $candidateIdentity) {
            continue
        }
        $sameSourceIdentity = $candidateIdentity.head -ceq $removedIdentity.head
        $candidateIsCommittedSnapshot = -not [bool]$candidateIdentity.protected_dirty_state_included
        if (
            ($sameSourceIdentity -or $candidateIsCommittedSnapshot) -and
            $candidateIdentity.fingerprint -ceq $removedIdentity.fingerprint -and
            $candidateIdentity.file_count -eq $removedIdentity.file_count
        ) {
            $replacement = $candidate
            break
        }
    }
    if ($null -eq $replacement) {
        throw "Refusing unique dirty worktree removal; no retained source/fingerprint-equivalent mirror exists: $removeWorktreeId"
    }
    $replacementByRemovedRun[$removeWorktreeId] = $replacement.Name
}

$scratchDirectoryNames = @($RemoveScratchDirectoryName | Select-Object -Unique)
foreach ($scratchDirectoryName in $scratchDirectoryNames) {
    if (
        [string]::IsNullOrWhiteSpace($scratchDirectoryName) -or
        [System.IO.Path]::GetFileName($scratchDirectoryName) -cne $scratchDirectoryName -or
        $scratchDirectoryName -match $runPattern
    ) {
        throw "Scratch cleanup requires an explicit non-run directory name: $scratchDirectoryName"
    }
    $scratchPath = Join-Path $runs $scratchDirectoryName
    if (-not (Test-Path -LiteralPath $scratchPath -PathType Container)) {
        throw "Unknown scratch directory: $scratchDirectoryName"
    }
    foreach ($retainedEvidenceName in @("report.json", "preview_report.json")) {
        if (Test-Path -LiteralPath (Join-Path $scratchPath $retainedEvidenceName) -PathType Leaf) {
            throw "Refusing scratch directory containing retained evidence: $scratchPath"
        }
    }
}

$plan = New-Object System.Collections.Generic.List[object]
foreach ($selectedRunId in $selectedRunIds) {
    $runPath = Get-I1PruneCanonicalPath -Path $runById[$selectedRunId].FullName
    if (-not (Test-I1PrunePathWithin -Path $runPath -Root $runs)) {
        throw "Run path escaped RunsRoot: $runPath"
    }

    if (-not $SkipTransient) {
        foreach ($component in @(
            [pscustomobject]@{ kind = "process_env"; relative_path = "process_env" },
            [pscustomobject]@{ kind = "engine_hardlink_view"; relative_path = "engine_without_self_contained_marker" }
        )) {
            $target = Join-Path $runPath $component.relative_path
            if (Test-Path -LiteralPath $target -PathType Container) {
                [void]$plan.Add([pscustomobject][ordered]@{
                    run_id = $selectedRunId
                    kind = $component.kind
                    path = Get-I1PruneCanonicalPath -Path $target
                    replacement_run_id = ""
                })
            }
        }
        if (-not ($removeAnyWorktreeIds -contains $selectedRunId)) {
            $cacheTarget = Join-Path $runPath "worktree\Godot\GraytailGodot\.godot"
            if (Test-Path -LiteralPath $cacheTarget -PathType Container) {
                [void]$plan.Add([pscustomobject][ordered]@{
                    run_id = $selectedRunId
                    kind = "godot_cache"
                    path = Get-I1PruneCanonicalPath -Path $cacheTarget
                    replacement_run_id = ""
                })
            }
        }
    }

    if ($removeWorktreeIds -contains $selectedRunId) {
        $worktreeTarget = Join-Path $runPath "worktree"
        if (Test-Path -LiteralPath $worktreeTarget -PathType Container) {
            [void]$plan.Add([pscustomobject][ordered]@{
                run_id = $selectedRunId
                kind = "duplicate_worktree"
                path = Get-I1PruneCanonicalPath -Path $worktreeTarget
                replacement_run_id = [string]$replacementByRemovedRun[$selectedRunId]
            })
        }
    }
    if ($removeCommittedWorktreeIds -contains $selectedRunId) {
        $worktreeTarget = Join-Path $runPath "worktree"
        if (Test-Path -LiteralPath $worktreeTarget -PathType Container) {
            [void]$plan.Add([pscustomobject][ordered]@{
                run_id = $selectedRunId
                kind = "committed_worktree"
                path = Get-I1PruneCanonicalPath -Path $worktreeTarget
                replacement_run_id = ""
            })
        }
    }
}

foreach ($scratchDirectoryName in $scratchDirectoryNames) {
    [void]$plan.Add([pscustomobject][ordered]@{
        run_id = ""
        kind = "historical_scratch"
        path = Get-I1PruneCanonicalPath -Path (Join-Path $runs $scratchDirectoryName)
        replacement_run_id = ""
    })
}

$reportHashesBefore = @{}
foreach ($entry in $plan) {
    $targetBoundary = $runs
    if (-not [string]::IsNullOrWhiteSpace([string]$entry.run_id)) {
        $runPath = $runById[$entry.run_id].FullName
        $targetBoundary = $runPath
        $reportPath = Join-Path $runPath "report.json"
        if (Test-Path -LiteralPath $reportPath -PathType Leaf) {
            $reportHashesBefore[$entry.run_id] = (Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash
        }
    }
    if (-not (Test-I1PrunePathWithin -Path $entry.path -Root $targetBoundary)) {
        throw "Prune target escaped its allowed boundary: $($entry.path)"
    }
    $inspection = Get-I1PruneTargetInspection -Path $entry.path
    Add-Member -InputObject $entry -NotePropertyName logical_bytes -NotePropertyValue ([int64]$inspection.logical_bytes)
}

[int64]$logicalBytes = 0
foreach ($entry in $plan) {
    $logicalBytes += [int64]$entry.logical_bytes
}

[int64]$freeBefore = (Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($runs).Substring(0, 1))).Free
$deletedCount = 0
if ($Apply) {
    foreach ($entry in $plan) {
        if ($PSCmdlet.ShouldProcess($entry.path, "Remove I1 $($entry.kind)")) {
            Remove-Item -LiteralPath $entry.path -Recurse -Force
            $deletedCount += 1
        }
    }
}
[int64]$freeAfter = (Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($runs).Substring(0, 1))).Free

foreach ($runIdWithReport in $reportHashesBefore.Keys) {
    $reportPath = Join-Path $runById[$runIdWithReport].FullName "report.json"
    if (-not (Test-Path -LiteralPath $reportPath -PathType Leaf)) {
        throw "Prune operation removed retained report: $reportPath"
    }
    $reportHashAfter = (Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash
    if ($reportHashAfter -cne $reportHashesBefore[$runIdWithReport]) {
        throw "Prune operation changed retained report: $reportPath"
    }
}

$remainingTargetCount = @($plan | Where-Object { Test-Path -LiteralPath $_.path }).Count
$result = [pscustomobject][ordered]@{
    status = if ($Apply) { "APPLIED" } else { "DRY_RUN" }
    repo_root = $repoRoot
    runs_root = $runs
    selected_run_count = $selectedRunIds.Count
    planned_target_count = $plan.Count
    deleted_target_count = $deletedCount
    remaining_target_count = $remainingTargetCount
    logical_bytes = $logicalBytes
    free_bytes_before = $freeBefore
    free_bytes_after = $freeAfter
    physical_bytes_freed = if ($Apply) { $freeAfter - $freeBefore } else { [int64]0 }
    retained_report_count = $reportHashesBefore.Count
    plan = $plan.ToArray()
}

Write-Output ("I1_EVIDENCE_PRUNE_JSON=" + ($result | ConvertTo-Json -Depth 8 -Compress))
