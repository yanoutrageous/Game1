[CmdletBinding()]
param(
    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$RegistryPath = '',

    [string]$OutputRoot = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-I4Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-I4TextSha256 {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        return ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $algorithm.Dispose()
    }
}

function Write-I4Text {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Text
    )
    [System.IO.File]::WriteAllText(
        $Path,
        $Text,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function ConvertTo-I4ProcessArgument {
    param([Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
    if ($Value.Contains('"')) {
        throw "Process arguments containing a quote are not supported: $Value"
    }
    if ($Value.Length -eq 0) {
        return '""'
    }
    if ($Value -notmatch '\s') {
        return $Value
    }
    if ($Value.EndsWith('\')) {
        return '"' + $Value + '\\"'
    }
    return '"' + $Value + '"'
}

function Get-I4NormalizedDiff {
    param(
        [Parameter(Mandatory = $true)][string]$EntryCommit,
        [Parameter(Mandatory = $true)][string]$Path
    )
    $arguments = @(
        '-C', $script:resolvedRoot,
        '-c', 'core.quotepath=false',
        'diff',
        '--no-ext-diff',
        '--no-color',
        '--binary',
        $EntryCommit
    )
    if ($script:SourceMode -ceq 'head') {
        $arguments += 'HEAD'
    }
    $arguments += @('--', $Path)
    # The reviewed diff contains Chinese player-facing copy. PowerShell 5
    # otherwise decodes external-process stdout with the host console codepage,
    # so the same Git bytes hash differently between the Codex terminal and a
    # hidden validation process. Read Git with an explicit UTF-8 StreamReader
    # and normalize only line endings before hashing.
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'git.exe'
    $startInfo.Arguments = (
        @($arguments | ForEach-Object {
            ConvertTo-I4ProcessArgument -Value ([string]$_)
        }) -join ' '
    )
    $startInfo.WorkingDirectory = $script:resolvedRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = (New-Object System.Text.UTF8Encoding($false))
    $startInfo.StandardErrorEncoding = (New-Object System.Text.UTF8Encoding($false))
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $stdout = ''
    $stderr = ''
    $exitCode = -1
    try {
        if (-not $process.Start()) {
            throw "Unable to start Git while deriving the reviewed diff for $Path"
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $exitCode = $process.ExitCode
    }
    finally {
        $process.Dispose()
    }
    if ($exitCode -ne 0) {
        throw "Unable to derive the reviewed diff for ${Path}: $($stderr.Trim())"
    }
    if ([string]::IsNullOrEmpty($stdout)) {
        return ''
    }
    $normalized = $stdout.Replace("`r`n", "`n").Replace("`r", "`n")
    if (-not $normalized.EndsWith("`n")) {
        $normalized += "`n"
    }
    return $normalized
}

function Get-I4ChangedExistingTestPaths {
    param([Parameter(Mandatory = $true)][string]$EntryCommit)
    $arguments = @(
        '-C', $script:resolvedRoot,
        '-c', 'core.quotepath=false',
        'diff',
        '--no-renames',
        '--name-status',
        '--diff-filter=MD',
        $EntryCommit
    )
    if ($script:SourceMode -ceq 'head') {
        $arguments += 'HEAD'
    }
    $arguments += @('--', 'Godot/GraytailGodot/tests')
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $rows = @(& git.exe @arguments 2>$null)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($exitCode -ne 0) {
        throw 'Unable to enumerate tests changed since the I4 entry commit.'
    }
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($row in $rows) {
        $parts = ([string]$row) -split "`t"
        if ($parts.Count -ne 2) {
            throw "Unexpected Git name-status row: $row"
        }
        $status = $parts[0]
        $path = $parts[1].Replace('\', '/')
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            & git.exe -C $script:resolvedRoot cat-file -e "$EntryCommit`:$path" 2>$null
            $existsAtEntry = $LASTEXITCODE -eq 0
        }
        finally {
            $ErrorActionPreference = $previousErrorActionPreference
        }
        if (-not $existsAtEntry) {
            continue
        }
        if ($status -cne 'M') {
            throw "A pre-I4 test was deleted instead of dispositioned: status=$status path=$path"
        }
        [void]$paths.Add($path)
    }
    return @($paths.ToArray() | Sort-Object -CaseSensitive)
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}
$script:resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd('\')
$observedRoot = (& git.exe -C $script:resolvedRoot rev-parse --show-toplevel).Trim()
if (
    $LASTEXITCODE -ne 0 -or
    (Resolve-Path -LiteralPath $observedRoot).Path.TrimEnd('\') -ne $script:resolvedRoot
) {
    throw "RepoRoot is not the active Git worktree root: $script:resolvedRoot"
}
$script:SourceMode = $SourceMode

if ([string]::IsNullOrWhiteSpace($RegistryPath)) {
    $RegistryPath = Join-Path $script:resolvedRoot 'tools\i4\legacy_assertion_disposition.json'
}
$resolvedRegistryPath = (Resolve-Path -LiteralPath $RegistryPath).Path
$registry = [System.IO.File]::ReadAllText(
    $resolvedRegistryPath,
    [System.Text.Encoding]::UTF8
) | ConvertFrom-Json
if ([int]$registry.schema_version -ne 1) {
    throw "Unsupported legacy-assertion registry schema: $($registry.schema_version)"
}
$entryCommit = [string]$registry.entry_commit
if ($entryCommit -notmatch '^[0-9a-f]{40}$') {
    throw "Registry entry_commit is not a full lowercase SHA: $entryCommit"
}
& git.exe -C $script:resolvedRoot merge-base --is-ancestor $entryCommit HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "I4 entry commit is not an ancestor of HEAD: $entryCommit"
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $OutputRoot = Join-Path $script:resolvedRoot ".tmp\i4\legacy_assertions\$runId"
}
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $script:resolvedRoot '.tmp')).TrimEnd('\')
if (
    -not $resolvedOutputRoot.StartsWith(
        $tmpRoot + '\',
        [System.StringComparison]::OrdinalIgnoreCase
    )
) {
    throw "OutputRoot must stay below the repository .tmp directory: $resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $resolvedOutputRoot -Force)

$statusBefore = @(
    & git.exe -c core.quotepath=false -C $script:resolvedRoot status --porcelain=v1 --untracked-files=all
)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read initial Git status.'
}

$actualPaths = @(Get-I4ChangedExistingTestPaths -EntryCommit $entryCommit)
$registryFiles = @($registry.files)
$registeredPaths = @(
    $registryFiles |
        ForEach-Object { [string]$_.path } |
        Sort-Object -CaseSensitive
)
if (@($registeredPaths | Select-Object -Unique).Count -ne $registeredPaths.Count) {
    throw 'The legacy-assertion registry contains duplicate file paths.'
}
$pathDifference = @(
    Compare-Object `
        -ReferenceObject $actualPaths `
        -DifferenceObject $registeredPaths `
        -CaseSensitive
)
if ($pathDifference.Count -ne 0) {
    throw (
        "Legacy-assertion registry is not the exact changed pre-I4 test set: {0}" -f
        (($pathDifference | ForEach-Object { "$($_.SideIndicator)$($_.InputObject)" }) -join ', ')
    )
}

$allowedDispositions = @(
    'STILL_AUTHORITATIVE',
    'SUPERSEDED_WITH_REPLACEMENT',
    'INVALID_WITH_EVIDENCE'
)
$reviewedFiles = New-Object System.Collections.Generic.List[object]
$dispositionCount = 0
$supersededCount = 0
$invalidCount = 0
foreach ($entry in $registryFiles) {
    $path = [string]$entry.path
    $fullPath = Join-Path $script:resolvedRoot $path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Reviewed test file is absent from the current source: $path"
    }
    $diffText = Get-I4NormalizedDiff -EntryCommit $entryCommit -Path $path
    if ([string]::IsNullOrEmpty($diffText)) {
        throw "Registry includes a pre-I4 test with no current diff: $path"
    }
    $actualDiffSha = Get-I4TextSha256 -Text $diffText
    $expectedDiffSha = ([string]$entry.diff_sha256).ToUpperInvariant()
    if ($actualDiffSha -cne $expectedDiffSha) {
        throw "Reviewed diff changed without renewed disposition: path=$path expected=$expectedDiffSha actual=$actualDiffSha"
    }
    $actualFileSha = Get-I4Sha256 -Path $fullPath
    $expectedFileSha = ([string]$entry.current_file_sha256).ToUpperInvariant()
    if ($actualFileSha -cne $expectedFileSha) {
        throw "Reviewed file hash changed without renewed disposition: path=$path expected=$expectedFileSha actual=$actualFileSha"
    }
    $dispositions = @($entry.dispositions)
    if ($dispositions.Count -eq 0) {
        throw "Reviewed test file has no assertion dispositions: $path"
    }
    $ids = @($dispositions | ForEach-Object { [string]$_.id })
    if (@($ids | Select-Object -Unique).Count -ne $ids.Count) {
        throw "Reviewed test file contains duplicate disposition ids: $path"
    }
    foreach ($disposition in $dispositions) {
        $kind = [string]$disposition.disposition
        if ($kind -cnotin $allowedDispositions) {
            throw "Unknown assertion disposition: path=$path id=$($disposition.id) disposition=$kind"
        }
        if ([string]::IsNullOrWhiteSpace([string]$disposition.verification)) {
            throw "Assertion disposition has no concrete verification: path=$path id=$($disposition.id)"
        }
        switch ($kind) {
            'STILL_AUTHORITATIVE' {
                if ([string]::IsNullOrWhiteSpace([string]$disposition.authority_preserved)) {
                    throw "STILL_AUTHORITATIVE lacks the preserved authority: path=$path id=$($disposition.id)"
                }
            }
            'SUPERSEDED_WITH_REPLACEMENT' {
                foreach ($field in @('old_assertion', 'reason', 'replacement_gate', 'scope_preserved')) {
                    if ([string]::IsNullOrWhiteSpace([string]$disposition.$field)) {
                        throw "Superseded assertion lacks $field`: path=$path id=$($disposition.id)"
                    }
                }
                $requirementIds = @($disposition.replacement_requirement_ids)
                if (
                    $requirementIds.Count -eq 0 -or
                    @($requirementIds | Where-Object { [string]$_ -notmatch '^I4-R\d{3}$' }).Count -ne 0
                ) {
                    throw "Superseded assertion lacks valid I4 replacement requirement ids: path=$path id=$($disposition.id)"
                }
                $supersededCount += 1
            }
            'INVALID_WITH_EVIDENCE' {
                if (
                    [string]::IsNullOrWhiteSpace([string]$disposition.invalid_reason) -or
                    [string]::IsNullOrWhiteSpace([string]$disposition.evidence)
                ) {
                    throw "Invalid assertion lacks reason/evidence: path=$path id=$($disposition.id)"
                }
                $invalidCount += 1
            }
        }
        $dispositionCount += 1
    }
    [void]$reviewedFiles.Add([pscustomobject][ordered]@{
        path = $path
        diff_sha256 = $actualDiffSha
        current_file_sha256 = $actualFileSha
        disposition_count = $dispositions.Count
        disposition_ids = $ids
        review_status = 'COMPLETE'
    })
}

$statusAfter = @(
    & git.exe -c core.quotepath=false -C $script:resolvedRoot status --porcelain=v1 --untracked-files=all
)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read final Git status.'
}
if (
    @(
        Compare-Object `
            -ReferenceObject $statusBefore `
            -DifferenceObject $statusAfter `
            -CaseSensitive
    ).Count -ne 0
) {
    throw 'Legacy-assertion audit polluted the active worktree.'
}

$head = (& git.exe -C $script:resolvedRoot rev-parse HEAD).Trim()
$headTree = (& git.exe -C $script:resolvedRoot rev-parse 'HEAD^{tree}').Trim()
$report = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = 'PASS'
    source_mode = $SourceMode
    entry_commit = $entryCommit
    head = $head
    head_tree = $headTree
    registry_path = $resolvedRegistryPath
    registry_sha256 = Get-I4Sha256 -Path $resolvedRegistryPath
    changed_existing_test_count = $actualPaths.Count
    registered_test_count = $registeredPaths.Count
    disposition_count = $dispositionCount
    superseded_with_replacement_count = $supersededCount
    invalid_with_evidence_count = $invalidCount
    exact_changed_file_set = $true
    worktree_status_unchanged = $true
    reviewed_files = $reviewedFiles.ToArray()
}
$reportPath = Join-Path $resolvedOutputRoot 'legacy_assertion_audit.json'
Write-I4Text -Path $reportPath -Text (($report | ConvertTo-Json -Depth 20) + "`r`n")
$reportSha = Get-I4Sha256 -Path $reportPath
Write-Output (
    "I4_LEGACY_ASSERTION_AUDIT=PASS source_mode={0} files={1} dispositions={2} superseded={3} invalid={4} report={5} sha256={6}" -f
    $SourceMode,
    $actualPaths.Count,
    $dispositionCount,
    $supersededCount,
    $invalidCount,
    $reportPath,
    $reportSha
)
