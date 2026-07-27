param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RunsRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$RunId,

    [string[]]$AllowMissingReportRunId = @(),

    [string]$ArchiveRoot = "",

    [string[]]$RestoreProof = @(),

    [switch]$Apply,

    [switch]$RemoveAfterVerify
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1")

$script:I1ArchiveVerifiedObjectCache = @{}


function Assert-I1ArchiveLeafName {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or
        $Value -ne [System.IO.Path]::GetFileName($Value) -or
        $Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or
        $Value.EndsWith(".", [System.StringComparison]::Ordinal) -or
        $Value -match '[:\\/]' -or
        $Value -eq '.' -or
        $Value -eq '..') {
        throw "Unsafe $Label value: $Value"
    }
    $deviceStem = $Value.Split('.')[0]
    if ($deviceStem -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') {
        throw "Reserved Windows device name is not allowed for ${Label}: $Value"
    }
}


function Get-I1ArchiveWorkspaceRoot {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$GitCommon
    )

    $candidate = Get-I0CanonicalPath -Path $RepoRoot
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-I0PathWithin -Path $GitCommon -Root $candidate -AllowRoot) {
            return $candidate
        }
        $parent = Split-Path -Parent $candidate
        if ([string]::IsNullOrWhiteSpace($parent) -or
            [string]::Equals($parent, $candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $candidate = Get-I0CanonicalPath -Path $parent
    }
    throw "Unable to derive git-common workspace. repo=$RepoRoot git_common=$GitCommon"
}


function Get-I1ArchiveSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I1ArchiveBytesSha256 {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $algorithm.ComputeHash($Bytes)
    }
    finally {
        $algorithm.Dispose()
    }
    return (-join @($hashBytes | ForEach-Object { $_.ToString('X2') }))
}


function Test-I1ArchiveByteArrayEqual {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Left,
        [Parameter(Mandatory = $true)][byte[]]$Right
    )

    if ($Left.Length -ne $Right.Length) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $false
        }
    }
    return $true
}


function Get-I1ArchiveStableFileRecord {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $before = Get-Item -LiteralPath $Path -Force
    if (($before.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Reparse-point files are not archivable: $Path"
    }
    if (($before.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
        throw "Expected an archive file, found a directory: $Path"
    }
    foreach ($stream in @(Get-Item -LiteralPath $Path -Stream * -ErrorAction Stop)) {
        if ([string]$stream.Stream -cne ':$DATA') {
            throw "Alternate data streams are forbidden in I1 snapshots: $Path stream=$($stream.Stream)"
        }
    }
    $length = [int64]$before.Length
    $mtimeTicks = [int64]$before.LastWriteTimeUtc.Ticks
    $attributes = [int64]$before.Attributes
    $sha256 = Get-I1ArchiveSha256 -Path $Path
    $after = Get-Item -LiteralPath $Path -Force
    if ([int64]$after.Length -ne $length -or
        [int64]$after.LastWriteTimeUtc.Ticks -ne $mtimeTicks -or
        [int64]$after.Attributes -ne $attributes) {
        throw "File changed while it was being inventoried: $Path"
    }

    return [pscustomobject][ordered]@{
        path = $RelativePath
        sha256 = $sha256
        length = $length
        mtime_utc = $before.LastWriteTimeUtc.ToString(
            "o",
            [System.Globalization.CultureInfo]::InvariantCulture
        )
        attributes = $attributes
    }
}


function Get-I1ArchiveWorktreeInventory {
    param([Parameter(Mandatory = $true)][string]$Worktree)

    $worktreePath = Get-I0CanonicalPath -Path $Worktree
    if (-not (Test-Path -LiteralPath $worktreePath -PathType Container)) {
        throw "I1 worktree is missing: $worktreePath"
    }
    $worktreeItem = Get-Item -LiteralPath $worktreePath -Force
    if (($worktreeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "I1 worktree root is a reparse point: $worktreePath"
    }

    $pending = New-Object System.Collections.Stack
    $pending.Push([pscustomobject]@{
        directory = $worktreePath
        excluded = $false
    })
    $pathByRelative = @{}

    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($entry in @(Get-ChildItem -LiteralPath $current.directory -Force)) {
            $entryPath = Get-I0CanonicalPath -Path $entry.FullName
            Assert-I0PathWithin -Path $entryPath -Root $worktreePath -Label "archive inventory entry"
            if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse points are forbidden in I1 snapshot worktrees: $entryPath"
            }

            $relative = (Get-I0RelativePath -Path $entryPath -Root $worktreePath).Replace('\', '/')
            $isRootGit = [string]::Equals(
                $relative,
                ".git",
                [System.StringComparison]::OrdinalIgnoreCase
            )
            $isGodotCacheRoot = [string]::Equals(
                $relative,
                "Godot/GraytailGodot/.godot",
                [System.StringComparison]::OrdinalIgnoreCase
            )
            $excluded = [bool]$current.excluded -or $isRootGit -or $isGodotCacheRoot
            $isDirectory = (($entry.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0)

            if ($isDirectory) {
                $pending.Push([pscustomobject]@{
                    directory = $entryPath
                    excluded = $excluded
                })
                continue
            }
            if ($excluded) {
                continue
            }
            if ($pathByRelative.ContainsKey($relative)) {
                throw "Duplicate case-insensitive relative path in worktree: $relative"
            }
            $pathByRelative[$relative] = $entryPath
        }
    }

    [string[]]$relativePaths = @($pathByRelative.Keys | ForEach-Object { [string]$_ })
    [System.Array]::Sort($relativePaths, [System.StringComparer]::Ordinal)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($relative in $relativePaths) {
        [void]$records.Add((Get-I1ArchiveStableFileRecord `
            -Path ([string]$pathByRelative[$relative]) `
            -RelativePath $relative))
    }
    return $records.ToArray()
}


function Get-I1ArchiveObjectPath {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$Sha256
    )

    if ($Sha256 -notmatch '^[0-9A-F]{64}$') {
        throw "Invalid SHA-256 object key: $Sha256"
    }
    return Get-I0CanonicalPath -Path (Join-Path $ArchiveRoot (
        "objects\sha256\{0}\{1}\{2}" -f
        $Sha256.Substring(0, 2).ToLowerInvariant(),
        $Sha256.Substring(2, 2).ToLowerInvariant(),
        $Sha256.ToLowerInvariant()
    ))
}


function Assert-I1ArchiveObject {
    param(
        [Parameter(Mandatory = $true)][string]$ObjectPath,
        [Parameter(Mandatory = $true)][string]$Sha256,
        [Parameter(Mandatory = $true)][int64]$Length
    )

    if (-not (Test-Path -LiteralPath $ObjectPath -PathType Leaf)) {
        throw "Archive object is missing: $ObjectPath"
    }
    $item = Get-Item -LiteralPath $ObjectPath -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Archive object is a reparse point: $ObjectPath"
    }
    foreach ($stream in @(Get-Item -LiteralPath $ObjectPath -Stream * -ErrorAction Stop)) {
        if ([string]$stream.Stream -cne ':$DATA') {
            throw "Alternate data streams are forbidden on archive objects: $ObjectPath stream=$($stream.Stream)"
        }
    }
    if ([int64]$item.Length -ne $Length) {
        throw "Archive object length mismatch: $ObjectPath"
    }
    $cacheKey = "{0}|{1}|{2}|{3}|{4}" -f (
        (Get-I0CanonicalPath -Path $ObjectPath).ToLowerInvariant()
    ), $Length, ([int64]$item.LastWriteTimeUtc.Ticks), ([int64]$item.Attributes), $Sha256
    if ($script:I1ArchiveVerifiedObjectCache.ContainsKey($cacheKey)) {
        return
    }
    $actualSha = Get-I1ArchiveSha256 -Path $ObjectPath
    if (-not [string]::Equals($actualSha, $Sha256, [System.StringComparison]::Ordinal)) {
        throw "Archive object SHA-256 mismatch: $ObjectPath"
    }
    $script:I1ArchiveVerifiedObjectCache[$cacheKey] = $true
}


function Ensure-I1ArchiveObject {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)]$Record,
        [Parameter(Mandatory = $true)][bool]$ApplyChanges
    )

    $objectPath = Get-I1ArchiveObjectPath -ArchiveRoot $ArchiveRoot -Sha256 ([string]$Record.sha256)
    Assert-I0PathWithin -Path $objectPath -Root $ArchiveRoot -Label "archive object"
    Assert-I0NoReparseExistingAncestor `
        -Path $objectPath `
        -Root $WorkspaceRoot `
        -Label "archive object"
    if (Test-Path -LiteralPath $objectPath) {
        Assert-I1ArchiveObject `
            -ObjectPath $objectPath `
            -Sha256 ([string]$Record.sha256) `
            -Length ([int64]$Record.length)
        return [pscustomobject][ordered]@{
            path = $objectPath
            created = $false
        }
    }
    if (-not $ApplyChanges) {
        return [pscustomobject][ordered]@{
            path = $objectPath
            created = $true
        }
    }

    $objectDirectory = Split-Path -Parent $objectPath
    Assert-I0NoReparseExistingAncestor `
        -Path $objectDirectory `
        -Root $WorkspaceRoot `
        -Label "archive object directory"
    [void](New-Item -ItemType Directory -Path $objectDirectory -Force)
    Assert-I0NoReparseExistingAncestor `
        -Path $objectDirectory `
        -Root $WorkspaceRoot `
        -Label "archive object directory"

    $temporaryPath = Join-Path $objectDirectory (
        ".{0}.tmp.{1}.{2}" -f
        ([System.IO.Path]::GetFileName($objectPath)),
        $PID,
        ([guid]::NewGuid().ToString("N"))
    )
    $created = $true
    try {
        Copy-Item `
            -LiteralPath $SourcePath `
            -Destination $temporaryPath `
            -ErrorAction Stop
        Assert-I1ArchiveObject `
            -ObjectPath $temporaryPath `
            -Sha256 ([string]$Record.sha256) `
            -Length ([int64]$Record.length)
        try {
            Move-Item -LiteralPath $temporaryPath -Destination $objectPath -ErrorAction Stop
        }
        catch {
            if (-not (Test-Path -LiteralPath $objectPath -PathType Leaf)) {
                throw
            }
            $created = $false
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
    Assert-I1ArchiveObject `
        -ObjectPath $objectPath `
        -Sha256 ([string]$Record.sha256) `
        -Length ([int64]$Record.length)
    return [pscustomobject][ordered]@{
        path = $objectPath
        created = $created
    }
}


function Get-I1ArchiveManifestBytes {
    param([Parameter(Mandatory = $true)]$Manifest)

    $json = $Manifest | ConvertTo-Json -Depth 20 -Compress
    $encoding = New-Object System.Text.UTF8Encoding($false)
    return $encoding.GetBytes($json)
}


function Write-I1ArchiveImmutableFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    Assert-I0NoReparseExistingAncestor `
        -Path $Path `
        -Root $WorkspaceRoot `
        -Label "immutable archive file"
    if (Test-Path -LiteralPath $Path) {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Immutable archive path is not a file: $Path"
        }
        $existingItem = Get-Item -LiteralPath $Path -Force
        if (($existingItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Immutable archive file is a reparse point: $Path"
        }
        foreach ($stream in @(Get-Item -LiteralPath $Path -Stream * -ErrorAction Stop)) {
            if ([string]$stream.Stream -cne ':$DATA') {
                throw "Alternate data streams are forbidden on immutable archive files: $Path stream=$($stream.Stream)"
            }
        }
        $existing = [System.IO.File]::ReadAllBytes($Path)
        if (-not (Test-I1ArchiveByteArrayEqual -Left $existing -Right $Bytes)) {
            throw "Immutable archive file already exists with different content: $Path"
        }
        return
    }

    $directory = Split-Path -Parent $Path
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "archive snapshot directory"
    [void](New-Item -ItemType Directory -Path $directory -Force)
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "archive snapshot directory"
    $temporaryPath = Join-Path $directory (
        ".{0}.tmp.{1}.{2}" -f
        ([System.IO.Path]::GetFileName($Path)),
        $PID,
        ([guid]::NewGuid().ToString("N"))
    )
    try {
        [System.IO.File]::WriteAllBytes($temporaryPath, $Bytes)
        Move-Item -LiteralPath $temporaryPath -Destination $Path -ErrorAction Stop
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}


function Assert-I1ArchiveManifest {
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][byte[]]$ExpectedBytes,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Archive manifest is missing: $ManifestPath"
    }
    $manifestItem = Get-Item -LiteralPath $ManifestPath -Force
    if (($manifestItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Archive manifest is a reparse point: $ManifestPath"
    }
    foreach ($stream in @(Get-Item -LiteralPath $ManifestPath -Stream * -ErrorAction Stop)) {
        if ([string]$stream.Stream -cne ':$DATA') {
            throw "Alternate data streams are forbidden on archive manifests: $ManifestPath stream=$($stream.Stream)"
        }
    }
    $actualBytes = [System.IO.File]::ReadAllBytes($ManifestPath)
    $actualSha = Get-I1ArchiveBytesSha256 -Bytes $actualBytes
    if (-not [string]::Equals($actualSha, $ExpectedSha256, [System.StringComparison]::Ordinal)) {
        throw "Archive manifest SHA-256 mismatch: $ManifestPath"
    }
    if (-not (Test-I1ArchiveByteArrayEqual -Left $actualBytes -Right $ExpectedBytes)) {
        throw "Archive manifest bytes are not deterministic: $ManifestPath"
    }
    try {
        [void]([System.Text.Encoding]::UTF8.GetString($actualBytes) | ConvertFrom-Json)
    }
    catch {
        throw "Archive manifest is not valid JSON: $ManifestPath"
    }
}


function Assert-I1ArchiveSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][byte[]]$ManifestBytes,
        [Parameter(Mandatory = $true)][string]$ManifestSha256,
        [Parameter(Mandatory = $true)][object[]]$Records
    )

    Assert-I1ArchiveManifest `
        -ManifestPath $ManifestPath `
        -ExpectedBytes $ManifestBytes `
        -ExpectedSha256 $ManifestSha256
    $verified = @{}
    foreach ($record in $Records) {
        $sha256 = [string]$record.sha256
        if ($verified.ContainsKey($sha256)) {
            continue
        }
        $objectPath = Get-I1ArchiveObjectPath -ArchiveRoot $ArchiveRoot -Sha256 $sha256
        Assert-I1ArchiveObject `
            -ObjectPath $objectPath `
            -Sha256 $sha256 `
            -Length ([int64]$record.length)
        $verified[$sha256] = $true
    }
}


function Assert-I1ArchiveSourceMatches {
    param(
        [Parameter(Mandatory = $true)][string]$Worktree,
        [Parameter(Mandatory = $true)][object[]]$ExpectedRecords
    )

    $actualRecords = @(Get-I1ArchiveWorktreeInventory -Worktree $Worktree)
    if ($actualRecords.Count -ne $ExpectedRecords.Count) {
        throw "Worktree file count changed after archiving: $Worktree"
    }
    for ($index = 0; $index -lt $ExpectedRecords.Count; $index++) {
        $expected = $ExpectedRecords[$index]
        $actual = $actualRecords[$index]
        foreach ($property in @("path", "sha256", "length", "mtime_utc", "attributes")) {
            if ([string]$actual.$property -cne [string]$expected.$property) {
                throw "Worktree changed after archiving. path=$($expected.path) property=$property"
            }
        }
    }
}


function Assert-I1ArchiveNoProcessReference {
    param([Parameter(Mandatory = $true)][string]$Worktree)

    $needle = $Worktree.Replace('\', '/')
    foreach ($process in @(Get-CimInstance Win32_Process)) {
        if ([int]$process.ProcessId -eq $PID -or [string]::IsNullOrWhiteSpace([string]$process.CommandLine)) {
            continue
        }
        $commandLine = ([string]$process.CommandLine).Replace('\', '/')
        if ($commandLine.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            throw "A process still references the worktree. pid=$($process.ProcessId) path=$Worktree"
        }
    }
}


function Get-I1ArchiveReportRecord {
    param([Parameter(Mandatory = $true)][string]$ReportPath)

    if (-not (Test-Path -LiteralPath $ReportPath -PathType Leaf)) {
        return $null
    }
    return Get-I1ArchiveStableFileRecord -Path $ReportPath -RelativePath "report.json"
}


function Get-I1ArchivePropertyValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}


function Get-I1ArchiveUniqueReportValue {
    param(
        [Parameter(Mandatory = $true)][string]$ReportText,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Field,
        [ValidateSet("raw", "lower", "upper", "bool", "int64")]
        [string]$Kind = "raw"
    )

    $values = @(
        [regex]::Matches(
            $ReportText,
            $Pattern,
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        ) |
            ForEach-Object {
                $value = [string]$_.Groups[1].Value
                switch ($Kind) {
                    "lower" { $value.ToLowerInvariant() }
                    "upper" { $value.ToUpperInvariant() }
                    "bool" { $value.ToLowerInvariant() }
                    "int64" { [int64]$value }
                    default { $value }
                }
            } |
            Select-Object -Unique
    )
    if ($values.Count -gt 1) {
        throw "Historical report identity field is ambiguous: $Field"
    }
    if ($values.Count -eq 0) {
        return $null
    }
    if ($Kind -ceq "bool") {
        return [string]$values[0] -ceq "true"
    }
    return $values[0]
}


function Get-I1ArchiveObservedReportValues {
    param(
        [Parameter(Mandatory = $true)][string]$ReportText,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [ValidateSet("raw", "lower", "upper", "bool", "int64")]
        [string]$Kind = "raw"
    )

    return @(
        [regex]::Matches(
            $ReportText,
            $Pattern,
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        ) |
            ForEach-Object {
                $value = [string]$_.Groups[1].Value
                switch ($Kind) {
                    "lower" { $value.ToLowerInvariant() }
                    "upper" { $value.ToUpperInvariant() }
                    "bool" { [string]$value.ToLowerInvariant() -ceq "true" }
                    "int64" { [int64]$value }
                    default { $value }
                }
            } |
            Select-Object -Unique
    )
}


function Get-I1ArchiveReportIdentity {
    param([Parameter(Mandatory = $true)][string]$ReportPath)

    if (-not (Test-Path -LiteralPath $ReportPath -PathType Leaf)) {
        return $null
    }
    # Historical reports can contain captured engine output too large for
    # Windows PowerShell 5.1's JSON parser. Bind the complete report by SHA-256,
    # require run_id to remain unambiguous, and retain every observed value for
    # descriptive fields because older reports legitimately repeat them.
    $reportText = [System.IO.File]::ReadAllText($ReportPath)
    return [pscustomobject][ordered]@{
        schema_version_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Kind "int64" -Pattern '"schema_version"\s*:\s*([0-9]+)'
        suite_id_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Pattern '"suite_id"\s*:\s*"([^"]+)"'
        run_id = Get-I1ArchiveUniqueReportValue -ReportText $reportText -Field "run_id" -Pattern '"run_id"\s*:\s*"([^"]+)"'
        profile_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Pattern '"profile"\s*:\s*"([^"]+)"'
        source_mode_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Pattern '"source_mode"\s*:\s*"([^"]+)"'
        overall_status_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Pattern '"overall_status"\s*:\s*"([^"]+)"'
        source_head_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Kind "lower" -Pattern '"head"\s*:\s*"([0-9a-fA-F]{40})"'
        source_tree_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Pattern '"tree"\s*:\s*"([^"]+)"'
        source_protected_dirty_state_included_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Kind "bool" -Pattern '"protected_dirty_state_included"\s*:\s*(true|false)'
        mirror_before_fingerprint_sha256_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Kind "upper" -Pattern '"before_fingerprint_sha256"\s*:\s*"([0-9a-fA-F]{64})"'
        mirror_after_fingerprint_sha256_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Kind "upper" -Pattern '"after_fingerprint_sha256"\s*:\s*"([0-9a-fA-F]{64})"'
        mirror_unchanged_observed = Get-I1ArchiveObservedReportValues -ReportText $reportText -Kind "bool" -Pattern '"unchanged"\s*:\s*(true|false)'
    }
}


function Get-I1ArchiveEvidenceInventory {
    param([Parameter(Mandatory = $true)][string]$RunRoot)

    $runRootPath = Get-I0CanonicalPath -Path $RunRoot
    $pathByRelative = @{}
    foreach ($fileName in @("report.json", "preview_report.json", "head-export.index")) {
        $filePath = Get-I0CanonicalPath -Path (Join-Path $runRootPath $fileName)
        if (Test-Path -LiteralPath $filePath -PathType Leaf) {
            $pathByRelative[$fileName] = $filePath
        }
    }

    foreach ($directoryName in @("log", "logs", "artifact", "artifacts", "preview", "previews")) {
        $directoryPath = Get-I0CanonicalPath -Path (Join-Path $runRootPath $directoryName)
        if (-not (Test-Path -LiteralPath $directoryPath -PathType Container)) {
            continue
        }
        $directoryItem = Get-Item -LiteralPath $directoryPath -Force
        if (($directoryItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse evidence directory in I1 run: $directoryPath"
        }
        $pending = New-Object System.Collections.Stack
        $pending.Push($directoryPath)
        while ($pending.Count -gt 0) {
            $current = [string]$pending.Pop()
            foreach ($entry in @(Get-ChildItem -LiteralPath $current -Force)) {
                $entryPath = Get-I0CanonicalPath -Path $entry.FullName
                Assert-I0PathWithin -Path $entryPath -Root $runRootPath -Label "run evidence"
                if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "Reparse points are forbidden in I1 run evidence: $entryPath"
                }
                if (($entry.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
                    $pending.Push($entryPath)
                    continue
                }
                $relative = (Get-I0RelativePath -Path $entryPath -Root $runRootPath).Replace('\', '/')
                if ($pathByRelative.ContainsKey($relative)) {
                    throw "Duplicate case-insensitive evidence path: $relative"
                }
                $pathByRelative[$relative] = $entryPath
            }
        }
    }

    [string[]]$relativePaths = @($pathByRelative.Keys | ForEach-Object { [string]$_ })
    [System.Array]::Sort($relativePaths, [System.StringComparer]::Ordinal)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($relative in $relativePaths) {
        [void]$records.Add((Get-I1ArchiveStableFileRecord `
            -Path ([string]$pathByRelative[$relative]) `
            -RelativePath $relative))
    }
    return $records.ToArray()
}


function Assert-I1ArchiveRecordSetEqual {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Expected,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Actual,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Actual.Count -ne $Expected.Count) {
        throw "$Label file count changed"
    }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        foreach ($property in @("path", "sha256", "length", "mtime_utc", "attributes")) {
            if ([string]$Actual[$index].$property -cne [string]$Expected[$index].$property) {
                throw "$Label changed. path=$($Expected[$index].path) property=$property"
            }
        }
    }
}


function Assert-I1ArchiveRestoreProof {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Namespace,
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$ManifestSha256,
        [Parameter(Mandatory = $true)][object[]]$Records
    )

    $proofRoot = Get-I0CanonicalPath -Path (Join-Path $ArchiveRoot (
        "restore_proofs\{0}\{1}" -f $Namespace, $RunId
    ))
    Assert-I0PathWithin -Path $proofRoot -Root $ArchiveRoot -Label "restore proof root"
    Assert-I0NoReparseExistingAncestor `
        -Path $proofRoot `
        -Root $WorkspaceRoot `
        -Label "restore proof root"
    $proofPath = Get-I0CanonicalPath -Path (Join-Path $proofRoot "$ManifestSha256.json")
    $proofShaPath = Get-I0CanonicalPath -Path (Join-Path $proofRoot "$ManifestSha256.sha256")
    foreach ($proofFile in @($proofPath, $proofShaPath)) {
        Assert-I0PathWithin -Path $proofFile -Root $ArchiveRoot -Label "restore proof file"
        if (-not (Test-Path -LiteralPath $proofFile -PathType Leaf)) {
            throw "Independent restore proof is missing: $proofFile"
        }
        $proofItem = Get-Item -LiteralPath $proofFile -Force
        if (($proofItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Independent restore proof is a reparse point: $proofFile"
        }
        foreach ($stream in @(Get-Item -LiteralPath $proofFile -Stream * -ErrorAction Stop)) {
            if ([string]$stream.Stream -cne ':$DATA') {
                throw "Alternate data streams are forbidden on restore proofs: $proofFile stream=$($stream.Stream)"
            }
        }
    }

    $proofBytes = [System.IO.File]::ReadAllBytes($proofPath)
    $proofSha256 = Get-I1ArchiveBytesSha256 -Bytes $proofBytes
    $expectedSidecar = "$proofSha256  $ManifestSha256.json`n"
    $actualSidecar = [System.Text.Encoding]::UTF8.GetString(
        [System.IO.File]::ReadAllBytes($proofShaPath)
    )
    if ($actualSidecar -cne $expectedSidecar) {
        throw "Independent restore proof SHA-256 sidecar mismatch: $proofShaPath"
    }
    try {
        $proof = [System.Text.Encoding]::UTF8.GetString($proofBytes) | ConvertFrom-Json
    }
    catch {
        throw "Independent restore proof is not valid JSON: $proofPath"
    }
    if ([int64](Get-I1ArchivePropertyValue -Object $proof -Name "schema_version") -ne 1 -or
        [string](Get-I1ArchivePropertyValue -Object $proof -Name "namespace") -cne $Namespace -or
        [string](Get-I1ArchivePropertyValue -Object $proof -Name "run_id") -cne $RunId -or
        [string](Get-I1ArchivePropertyValue -Object $proof -Name "manifest_sha256") -cne $ManifestSha256) {
        throw "Independent restore proof identity mismatch: $proofPath"
    }

    [int64]$logicalBytes = 0
    $uniqueHashes = @{}
    foreach ($record in $Records) {
        $logicalBytes += [int64]$record.length
        $uniqueHashes[[string]$record.sha256] = $true
    }
    if ([int64](Get-I1ArchivePropertyValue -Object $proof -Name "file_count") -ne $Records.Count -or
        [int64](Get-I1ArchivePropertyValue -Object $proof -Name "logical_bytes") -ne $logicalBytes -or
        [int64](Get-I1ArchivePropertyValue -Object $proof -Name "unique_object_count") -ne $uniqueHashes.Count) {
        throw "Independent restore proof inventory mismatch: $proofPath"
    }
    $verification = Get-I1ArchivePropertyValue -Object $proof -Name "verification"
    if ($null -eq $verification -or
        [bool](Get-I1ArchivePropertyValue -Object $verification -Name "manifest_sidecar_sha256") -ne $true -or
        [bool](Get-I1ArchivePropertyValue -Object $verification -Name "object_length_and_sha256") -ne $true -or
        [string](Get-I1ArchivePropertyValue -Object $verification -Name "copy_method") -cne "System.IO.File.Copy" -or
        [bool](Get-I1ArchivePropertyValue -Object $verification -Name "hardlinks_used_for_restore") -ne $false -or
        [bool](Get-I1ArchivePropertyValue -Object $verification -Name "restored_path_length_sha256_mtime_attributes") -ne $true -or
        [int64](Get-I1ArchivePropertyValue -Object $verification -Name "restored_verification_passes") -lt 2) {
        throw "Independent restore proof does not satisfy the deletion gate: $proofPath"
    }
}


function Write-I1ArchiveAtomicFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $directory = Split-Path -Parent $Path
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "archive index directory"
    [void](New-Item -ItemType Directory -Path $directory -Force)
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "archive index directory"
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
            ($item.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
            throw "Archive index target is not a regular file: $Path"
        }
    }

    $temporaryPath = Join-Path $directory (
        ".{0}.tmp.{1}.{2}" -f
        ([System.IO.Path]::GetFileName($Path)),
        $PID,
        ([guid]::NewGuid().ToString("N"))
    )
    $backupPath = Join-Path $directory (
        ".{0}.backup.{1}.{2}" -f
        ([System.IO.Path]::GetFileName($Path)),
        $PID,
        ([guid]::NewGuid().ToString("N"))
    )
    try {
        [System.IO.File]::WriteAllBytes($temporaryPath, $Bytes)
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [System.IO.File]::Replace($temporaryPath, $Path, $backupPath, $true)
            if (Test-Path -LiteralPath $backupPath) {
                Remove-Item -LiteralPath $backupPath -Force
            }
        }
        else {
            [System.IO.File]::Move($temporaryPath, $Path)
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $backupPath) {
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        }
    }
}


function Update-I1ArchiveIndex {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $snapshotsRoot = Get-I0CanonicalPath -Path (Join-Path $ArchiveRoot "snapshots")
    Assert-I0NoReparseExistingAncestor `
        -Path $snapshotsRoot `
        -Root $WorkspaceRoot `
        -Label "archive snapshots root"
    $recordByKey = @{}
    if (Test-Path -LiteralPath $snapshotsRoot -PathType Container) {
        foreach ($namespaceDirectory in @(Get-ChildItem -LiteralPath $snapshotsRoot -Directory -Force)) {
            if (($namespaceDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse namespace directory in archive snapshots: $($namespaceDirectory.FullName)"
            }
            $namespaceValue = [string]$namespaceDirectory.Name
            Assert-I1ArchiveLeafName -Value $namespaceValue -Label "archived Namespace"
            foreach ($runDirectory in @(Get-ChildItem -LiteralPath $namespaceDirectory.FullName -Directory -Force)) {
                if (($runDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "Reparse run directory in archive snapshots: $($runDirectory.FullName)"
                }
                $runIdValue = [string]$runDirectory.Name
                Assert-I1ArchiveLeafName -Value $runIdValue -Label "archived RunId"
                $manifestPath = Get-I0CanonicalPath -Path (Join-Path $runDirectory.FullName "manifest.json")
                $relativeManifest = (
                    Get-I0RelativePath -Path $manifestPath -Root $ArchiveRoot
                ).Replace('\', '/')
                $manifestRecord = Get-I1ArchiveStableFileRecord `
                    -Path $manifestPath `
                    -RelativePath $relativeManifest
                $manifestBytes = [System.IO.File]::ReadAllBytes($manifestPath)
                $manifest = [System.Text.Encoding]::UTF8.GetString($manifestBytes) | ConvertFrom-Json
                if ([string](Get-I1ArchivePropertyValue -Object $manifest -Name "namespace") -cne $namespaceValue -or
                    [string](Get-I1ArchivePropertyValue -Object $manifest -Name "run_id") -cne $runIdValue) {
                    throw "Snapshot directory identity does not match manifest: $manifestPath"
                }
                $files = @(Get-I1ArchivePropertyValue -Object $manifest -Name "files")
                [int64]$logicalBytes = 0
                foreach ($file in $files) {
                    $logicalBytes += [int64](Get-I1ArchivePropertyValue -Object $file -Name "length")
                }
                $report = Get-I1ArchivePropertyValue -Object $manifest -Name "report"
                $key = "$namespaceValue`0$runIdValue"
                if ($recordByKey.ContainsKey($key)) {
                    throw "Duplicate archive snapshot identity: $namespaceValue/$runIdValue"
                }
                $recordByKey[$key] = [pscustomobject][ordered]@{
                    namespace = $namespaceValue
                    run_id = $runIdValue
                    manifest_path = $relativeManifest
                    manifest_sha256 = [string]$manifestRecord.sha256
                    report_sha256 = if ($null -eq $report) {
                        $null
                    }
                    else {
                        [string](Get-I1ArchivePropertyValue -Object $report -Name "sha256")
                    }
                    file_count = $files.Count
                    logical_bytes = $logicalBytes
                }
            }
        }
    }

    [string[]]$keys = @($recordByKey.Keys | ForEach-Object { [string]$_ })
    [System.Array]::Sort($keys, [System.StringComparer]::Ordinal)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($key in $keys) {
        [void]$records.Add($recordByKey[$key])
    }
    $index = [pscustomobject][ordered]@{
        schema_version = 1
        snapshots = $records.ToArray()
    }
    $indexBytes = Get-I1ArchiveManifestBytes -Manifest $index
    $indexSha256 = Get-I1ArchiveBytesSha256 -Bytes $indexBytes
    $indexPath = Get-I0CanonicalPath -Path (Join-Path $ArchiveRoot "index.json")
    $indexShaPath = Get-I0CanonicalPath -Path (Join-Path $ArchiveRoot "index.sha256")
    Write-I1ArchiveAtomicFile -Path $indexPath -Bytes $indexBytes -WorkspaceRoot $WorkspaceRoot
    $shaBytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes(
        "$indexSha256  index.json`n"
    )
    Write-I1ArchiveAtomicFile -Path $indexShaPath -Bytes $shaBytes -WorkspaceRoot $WorkspaceRoot
    if ((Get-I1ArchiveSha256 -Path $indexPath) -cne $indexSha256) {
        throw "Global archive index SHA-256 verification failed: $indexPath"
    }
    $actualShaLine = [System.Text.Encoding]::UTF8.GetString(
        [System.IO.File]::ReadAllBytes($indexShaPath)
    )
    if ($actualShaLine -cne "$indexSha256  index.json`n") {
        throw "Global archive index sidecar verification failed: $indexShaPath"
    }
    return [pscustomobject][ordered]@{
        path = $indexPath
        sha256 = $indexSha256
        snapshot_count = $records.Count
    }
}


$mode = if ($Apply) {
    if ($RemoveAfterVerify) { "apply_remove_after_verify" } else { "apply" }
}
else {
    "dry_run"
}
$result = $null
$exitCode = 0
$mutationMayHaveOccurred = $false
$worktreeRemovalPerformed = $false
$worktreeRemovalMayHaveStarted = $false

try {
    if ($PSVersionTable.PSEdition -cne "Desktop" -or
        $PSVersionTable.PSVersion.Major -ne 5 -or
        $PSVersionTable.PSVersion.Minor -lt 1) {
        throw "I1 snapshot archive requires Windows PowerShell 5.1 Desktop"
    }
    if ($RemoveAfterVerify -and -not $Apply) {
        throw "-RemoveAfterVerify requires -Apply"
    }

    $resolvedRunsRoot = Get-I0CanonicalPath -Path $RunsRoot
    if (-not (Test-Path -LiteralPath $resolvedRunsRoot -PathType Container)) {
        throw "RunsRoot does not exist: $resolvedRunsRoot"
    }
    if (-not [string]::Equals(
        (Split-Path -Leaf $resolvedRunsRoot),
        "i1",
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot must end in .tmp\\i1: $resolvedRunsRoot"
    }
    $tmpRoot = Get-I0CanonicalPath -Path (Split-Path -Parent $resolvedRunsRoot)
    if (-not [string]::Equals(
        (Split-Path -Leaf $tmpRoot),
        ".tmp",
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot must be the selected worktree's .tmp\\i1: $resolvedRunsRoot"
    }
    $selectedRepo = Get-I0CanonicalPath -Path (Split-Path -Parent $tmpRoot)
    $repoResult = Invoke-I0Git `
        -RepoRoot $selectedRepo `
        -Arguments @("rev-parse", "--path-format=absolute", "--show-toplevel")
    $resolvedRepo = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $repoResult.stdout)
    if (-not [string]::Equals(
        $selectedRepo,
        $resolvedRepo,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot is not the selected Git worktree's .tmp\\i1. selected=$selectedRepo git=$resolvedRepo"
    }
    $expectedRunsRoot = Get-I0CanonicalPath -Path (Join-Path $resolvedRepo ".tmp\i1")
    if (-not [string]::Equals(
        $resolvedRunsRoot,
        $expectedRunsRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot is not the selected Git worktree's exact .tmp\\i1 path"
    }

    $commonResult = Invoke-I0Git `
        -RepoRoot $resolvedRepo `
        -Arguments @("rev-parse", "--path-format=absolute", "--git-common-dir")
    $gitCommon = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $commonResult.stdout)
    $workspaceRoot = Get-I1ArchiveWorkspaceRoot -RepoRoot $resolvedRepo -GitCommon $gitCommon
    [void](Set-I0WorkspaceRoot -Path $workspaceRoot)
    Assert-I0PathWithin -Path $resolvedRepo -Root $workspaceRoot -AllowRoot -Label "selected Git worktree"
    Assert-I0NoReparseExistingAncestor `
        -Path $resolvedRunsRoot `
        -Root $workspaceRoot `
        -Label "RunsRoot"

    $expectedArchiveRoot = Get-I0CanonicalPath -Path (Join-Path $workspaceRoot ".tmp\i1_snapshot_archive")
    $resolvedArchiveRoot = if ([string]::IsNullOrWhiteSpace($ArchiveRoot)) {
        $expectedArchiveRoot
    }
    else {
        Get-I0CanonicalPath -Path $ArchiveRoot
    }
    if (-not [string]::Equals(
        $resolvedArchiveRoot,
        $expectedArchiveRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "ArchiveRoot must be the git-common workspace's .tmp\\i1_snapshot_archive. expected=$expectedArchiveRoot"
    }
    Assert-I0NoReparseExistingAncestor `
        -Path $resolvedArchiveRoot `
        -Root $workspaceRoot `
        -Label "ArchiveRoot"
    if (-not [string]::Equals(
        [System.IO.Path]::GetPathRoot($resolvedRunsRoot),
        [System.IO.Path]::GetPathRoot($resolvedArchiveRoot),
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot and ArchiveRoot must be on the git-common workspace volume"
    }

    Assert-I1ArchiveLeafName -Value $Namespace -Label "Namespace"
    if ($null -eq $RunId -or @($RunId).Count -eq 0) {
        throw "At least one explicit RunId is required"
    }
    $seenRunIds = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    [string[]]$requestedRunIds = @($RunId | ForEach-Object {
        Assert-I1ArchiveLeafName -Value ([string]$_) -Label "RunId"
        if (-not $seenRunIds.Add([string]$_)) {
            throw "Duplicate RunId: $_"
        }
        [string]$_
    })
    [System.Array]::Sort($requestedRunIds, [System.StringComparer]::Ordinal)

    $allowedMissingReports = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($allowedRunIdValue in @($AllowMissingReportRunId)) {
        $allowedRunId = [string]$allowedRunIdValue
        Assert-I1ArchiveLeafName -Value $allowedRunId -Label "AllowMissingReportRunId"
        if (-not $seenRunIds.Contains($allowedRunId)) {
            throw "AllowMissingReportRunId is not present in RunId: $allowedRunId"
        }
        if (-not $allowedMissingReports.Add($allowedRunId)) {
            throw "Duplicate AllowMissingReportRunId: $allowedRunId"
        }
    }

    $restoreProofByKey = @{}
    foreach ($proofValue in @($RestoreProof)) {
        $proof = [string]$proofValue
        $match = [regex]::Match(
            $proof,
            '^([^/=]+)/([^=]+)=([0-9A-Fa-f]{64})$',
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        if (-not $match.Success) {
            throw "RestoreProof must be Namespace/RunId=MANIFEST_SHA256: $proof"
        }
        $proofNamespace = $match.Groups[1].Value
        $proofRunId = $match.Groups[2].Value
        $proofSha256 = $match.Groups[3].Value.ToUpperInvariant()
        Assert-I1ArchiveLeafName -Value $proofNamespace -Label "RestoreProof Namespace"
        Assert-I1ArchiveLeafName -Value $proofRunId -Label "RestoreProof RunId"
        if (-not [string]::Equals(
            $proofNamespace,
            $Namespace,
            [System.StringComparison]::Ordinal
        ) -or -not $seenRunIds.Contains($proofRunId)) {
            throw "RestoreProof does not match the requested Namespace/RunId: $proof"
        }
        $proofKey = "$proofNamespace/$proofRunId"
        if ($restoreProofByKey.ContainsKey($proofKey)) {
            throw "Duplicate RestoreProof: $proofKey"
        }
        $restoreProofByKey[$proofKey] = $proofSha256
    }
    if ($RemoveAfterVerify -and $restoreProofByKey.Count -ne $requestedRunIds.Count) {
        throw "-RemoveAfterVerify requires one external RestoreProof per requested Namespace/RunId"
    }

    if ($Apply) {
        $mutationMayHaveOccurred = $true
        [void](New-Item -ItemType Directory -Path $resolvedArchiveRoot -Force)
        Assert-I0NoReparseExistingAncestor `
            -Path $resolvedArchiveRoot `
            -Root $workspaceRoot `
            -Label "ArchiveRoot"
    }

    $snapshotResults = New-Object System.Collections.Generic.List[object]
    $archiveIndexResult = $null
    foreach ($requestedRunId in $requestedRunIds) {
        $runRoot = Get-I0CanonicalPath -Path (Join-Path $resolvedRunsRoot $requestedRunId)
        Assert-I0PathWithin -Path $runRoot -Root $resolvedRunsRoot -Label "I1 run root"
        if (-not (Test-Path -LiteralPath $runRoot -PathType Container)) {
            throw "Explicit I1 run is missing: $runRoot"
        }
        Assert-I0NoReparseExistingAncestor `
            -Path $runRoot `
            -Root $workspaceRoot `
            -Label "I1 run root"

        $worktree = Get-I0CanonicalPath -Path (Join-Path $runRoot "worktree")
        Assert-I0PathWithin -Path $worktree -Root $runRoot -Label "I1 run worktree"
        $records = @(Get-I1ArchiveWorktreeInventory -Worktree $worktree)
        $reportPath = Get-I0CanonicalPath -Path (Join-Path $runRoot "report.json")
        $reportRecord = Get-I1ArchiveReportRecord -ReportPath $reportPath
        if ($null -eq $reportRecord -and -not $allowedMissingReports.Contains($requestedRunId)) {
            throw "report.json is missing; explicitly allow this RunId with -AllowMissingReportRunId: $requestedRunId"
        }
        $reportIdentity = Get-I1ArchiveReportIdentity -ReportPath $reportPath
        if ($null -ne $reportIdentity -and
            -not [string]::IsNullOrWhiteSpace([string]$reportIdentity.run_id) -and
            -not [string]::Equals(
                [string]$reportIdentity.run_id,
                $requestedRunId,
                [System.StringComparison]::Ordinal
            )) {
            throw "report.json run_id does not match the requested RunId: $reportPath"
        }
        $evidenceRecords = @(Get-I1ArchiveEvidenceInventory -RunRoot $runRoot)

        $uniqueBySha = @{}
        foreach ($record in $records) {
            $sha256 = [string]$record.sha256
            if ($uniqueBySha.ContainsKey($sha256)) {
                if ([int64]$uniqueBySha[$sha256].length -ne [int64]$record.length) {
                    throw "SHA-256 collision with different lengths in snapshot: $sha256"
                }
                continue
            }
            $sourcePath = Get-I0CanonicalPath -Path (Join-Path $worktree (
                ([string]$record.path).Replace('/', '\')
            ))
            Assert-I0PathWithin -Path $sourcePath -Root $worktree -Label "archive source file"
            $uniqueBySha[$sha256] = [pscustomobject][ordered]@{
                source_path = $sourcePath
                length = [int64]$record.length
                record = $record
            }
        }

        [string[]]$uniqueHashes = @($uniqueBySha.Keys | ForEach-Object { [string]$_ })
        [System.Array]::Sort($uniqueHashes, [System.StringComparer]::Ordinal)
        [int64]$newObjectBytes = 0
        [int64]$reusedObjectBytes = 0
        $newObjectCount = 0
        $reusedObjectCount = 0
        foreach ($hash in $uniqueHashes) {
            $source = $uniqueBySha[$hash]
            $objectResult = Ensure-I1ArchiveObject `
                -ArchiveRoot $resolvedArchiveRoot `
                -WorkspaceRoot $workspaceRoot `
                -SourcePath ([string]$source.source_path) `
                -Record $source.record `
                -ApplyChanges ([bool]$Apply)
            if ($objectResult.created) {
                $newObjectCount += 1
                $newObjectBytes += [int64]$source.length
            }
            else {
                $reusedObjectCount += 1
                $reusedObjectBytes += [int64]$source.length
            }
        }

        $manifest = [pscustomobject][ordered]@{
            schema_version = 1
            namespace = $Namespace
            run_id = $requestedRunId
            runs_root = $resolvedRunsRoot
            worktree = $worktree
            selected_git_worktree = $resolvedRepo
            git_common_workspace = $workspaceRoot
            exclusions = @(
                ".git",
                "Godot/GraytailGodot/.godot"
            )
            report = if ($null -eq $reportRecord) {
                $null
            }
            else {
                [pscustomobject][ordered]@{
                    path = "report.json"
                    sha256 = [string]$reportRecord.sha256
                    length = [int64]$reportRecord.length
                    mtime_utc = [string]$reportRecord.mtime_utc
                    attributes = [int64]$reportRecord.attributes
                    identity = $reportIdentity
                }
            }
            evidence = $evidenceRecords
            files = $records
        }
        $manifestBytes = Get-I1ArchiveManifestBytes -Manifest $manifest
        $manifestSha256 = Get-I1ArchiveBytesSha256 -Bytes $manifestBytes
        $snapshotRoot = Get-I0CanonicalPath -Path (Join-Path $resolvedArchiveRoot (
            "snapshots\{0}\{1}" -f $Namespace, $requestedRunId
        ))
        Assert-I0PathWithin -Path $snapshotRoot -Root $resolvedArchiveRoot -Label "archive snapshot"
        $manifestPath = Get-I0CanonicalPath -Path (Join-Path $snapshotRoot "manifest.json")
        $manifestShaPath = Get-I0CanonicalPath -Path (Join-Path $snapshotRoot "manifest.sha256")

        if ($Apply) {
            Write-I1ArchiveImmutableFile `
                -Path $manifestPath `
                -Bytes $manifestBytes `
                -WorkspaceRoot $workspaceRoot
            $shaLine = "$manifestSha256  manifest.json`n"
            $shaBytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($shaLine)
            Write-I1ArchiveImmutableFile `
                -Path $manifestShaPath `
                -Bytes $shaBytes `
                -WorkspaceRoot $workspaceRoot
            Assert-I1ArchiveSnapshot `
                -ArchiveRoot $resolvedArchiveRoot `
                -ManifestPath $manifestPath `
                -ManifestBytes $manifestBytes `
                -ManifestSha256 $manifestSha256 `
                -Records $records
            $actualShaLine = [System.Text.Encoding]::UTF8.GetString(
                [System.IO.File]::ReadAllBytes($manifestShaPath)
            )
            if ($actualShaLine -cne $shaLine) {
                throw "Manifest SHA-256 sidecar mismatch: $manifestShaPath"
            }
            if ($null -ne $reportRecord) {
                $actualReport = Get-I1ArchiveReportRecord -ReportPath $reportPath
                if ($null -eq $actualReport -or
                    [string]$actualReport.sha256 -cne [string]$reportRecord.sha256) {
                    throw "report.json changed during archive: $reportPath"
                }
            }
            $actualEvidence = @(Get-I1ArchiveEvidenceInventory -RunRoot $runRoot)
            Assert-I1ArchiveRecordSetEqual `
                -Expected $evidenceRecords `
                -Actual $actualEvidence `
                -Label "I1 run evidence"
            $archiveIndexResult = Update-I1ArchiveIndex `
                -ArchiveRoot $resolvedArchiveRoot `
                -WorkspaceRoot $workspaceRoot
        }

        $removed = $false
        $removalTombstone = $null
        if ($RemoveAfterVerify) {
            $restoreProofKey = "$Namespace/$requestedRunId"
            if (-not $restoreProofByKey.ContainsKey($restoreProofKey) -or
                -not [string]::Equals(
                    [string]$restoreProofByKey[$restoreProofKey],
                    $manifestSha256,
                    [System.StringComparison]::Ordinal
                )) {
                throw "External RestoreProof does not match the deterministic manifest: $restoreProofKey"
            }
            Assert-I1ArchiveRestoreProof `
                -ArchiveRoot $resolvedArchiveRoot `
                -WorkspaceRoot $workspaceRoot `
                -Namespace $Namespace `
                -RunId $requestedRunId `
                -ManifestSha256 $manifestSha256 `
                -Records $records
            Assert-I1ArchiveNoProcessReference -Worktree $worktree
            Assert-I1ArchiveSnapshot `
                -ArchiveRoot $resolvedArchiveRoot `
                -ManifestPath $manifestPath `
                -ManifestBytes $manifestBytes `
                -ManifestSha256 $manifestSha256 `
                -Records $records
            Assert-I1ArchiveSourceMatches -Worktree $worktree -ExpectedRecords $records
            $actualEvidence = @(Get-I1ArchiveEvidenceInventory -RunRoot $runRoot)
            Assert-I1ArchiveRecordSetEqual `
                -Expected $evidenceRecords `
                -Actual $actualEvidence `
                -Label "I1 run evidence"
            $worktreeItem = Get-Item -LiteralPath $worktree -Force
            if (($worktreeItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Verified worktree became a reparse point before removal: $worktree"
            }
            $removalTombstone = Get-I0CanonicalPath -Path (Join-Path $runRoot (
                ".archived_worktree_remove_{0}" -f $manifestSha256.Substring(0, 16)
            ))
            Assert-I0PathWithin `
                -Path $removalTombstone `
                -Root $runRoot `
                -Label "archive removal tombstone"
            if (Test-Path -LiteralPath $removalTombstone) {
                throw "Archive removal tombstone already exists: $removalTombstone"
            }

            $worktreeRemovalMayHaveStarted = $true
            [System.IO.Directory]::Move($worktree, $removalTombstone)
            if (Test-Path -LiteralPath $worktree) {
                throw "Worktree path still exists after atomic tombstone rename: $worktree"
            }
            Assert-I0NoReparseExistingAncestor `
                -Path $removalTombstone `
                -Root $workspaceRoot `
                -Label "archive removal tombstone"
            Assert-I1ArchiveSourceMatches `
                -Worktree $removalTombstone `
                -ExpectedRecords $records
            Remove-Item -LiteralPath $removalTombstone -Recurse -Force
            if (Test-Path -LiteralPath $removalTombstone) {
                throw "Verified tombstone removal did not complete: $removalTombstone"
            }
            $worktreeRemovalPerformed = $true
            Assert-I1ArchiveSnapshot `
                -ArchiveRoot $resolvedArchiveRoot `
                -ManifestPath $manifestPath `
                -ManifestBytes $manifestBytes `
                -ManifestSha256 $manifestSha256 `
                -Records $records
            if ($null -ne $reportRecord) {
                $actualReport = Get-I1ArchiveReportRecord -ReportPath $reportPath
                if ($null -eq $actualReport -or
                    [string]$actualReport.sha256 -cne [string]$reportRecord.sha256) {
                    throw "report.json was not preserved after worktree removal: $reportPath"
                }
            }
            $actualEvidence = @(Get-I1ArchiveEvidenceInventory -RunRoot $runRoot)
            Assert-I1ArchiveRecordSetEqual `
                -Expected $evidenceRecords `
                -Actual $actualEvidence `
                -Label "I1 run evidence"
            $removed = $true
        }

        [int64]$logicalBytes = 0
        foreach ($record in $records) {
            $logicalBytes += [int64]$record.length
        }
        [void]$snapshotResults.Add([pscustomobject][ordered]@{
            run_id = $requestedRunId
            worktree = $worktree
            file_count = $records.Count
            logical_bytes = $logicalBytes
            unique_object_count = $uniqueHashes.Count
            evidence_file_count = $evidenceRecords.Count
            new_object_count = $newObjectCount
            new_object_bytes = $newObjectBytes
            reused_object_count = $reusedObjectCount
            reused_object_bytes = $reusedObjectBytes
            report_sha256 = if ($null -eq $reportRecord) { $null } else { [string]$reportRecord.sha256 }
            manifest_path = $manifestPath
            manifest_sha256 = $manifestSha256
            verified = [bool]$Apply
            worktree_removed = $removed
            removal_tombstone = $removalTombstone
        })
    }

    $result = [pscustomobject][ordered]@{
        schema_version = 1
        status = "PASS"
        mode = $mode
        apply_requested = [bool]$Apply
        mutation_may_have_occurred = $mutationMayHaveOccurred
        worktree_removal_may_have_started = $worktreeRemovalMayHaveStarted
        worktree_removal_performed = $worktreeRemovalPerformed
        selected_git_worktree = $resolvedRepo
        runs_root = $resolvedRunsRoot
        namespace = $Namespace
        archive_root = $resolvedArchiveRoot
        archive_index = $archiveIndexResult
        snapshot_count = $snapshotResults.Count
        snapshots = $snapshotResults.ToArray()
    }
}
catch {
    $exitCode = 1
    $result = [pscustomobject][ordered]@{
        schema_version = 1
        status = "FAIL"
        mode = $mode
        apply_requested = [bool]$Apply
        mutation_may_have_occurred = $mutationMayHaveOccurred
        worktree_removal_may_have_started = $worktreeRemovalMayHaveStarted
        worktree_removal_performed = $worktreeRemovalPerformed
        error = $_.Exception.Message
    }
}

Write-Output ("I1_SNAPSHOT_ARCHIVE_JSON=" + ($result | ConvertTo-Json -Depth 20 -Compress))
exit $exitCode
