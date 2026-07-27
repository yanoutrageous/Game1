param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ArchiveRoot,

    [switch]$Apply
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1")


function Get-I1VerifyWorkspaceRoot {
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


function Get-I1VerifyBytesSha256 {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $algorithm.ComputeHash($Bytes)
    }
    finally {
        $algorithm.Dispose()
    }
    return (-join @($hashBytes | ForEach-Object { $_.ToString("X2") }))
}


function Get-I1VerifyFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Test-I1VerifyByteArrayEqual {
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


function Assert-I1VerifyLeafName {
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


function Assert-I1VerifyRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or
        [System.IO.Path]::IsPathRooted($Path) -or
        $Path -match '[:\\]' -or
        $Path -match '[<>"|?*\x00-\x1F]') {
        throw "Unsafe $Label value: $Path"
    }
    foreach ($segment in @($Path.Split('/'))) {
        if ([string]::IsNullOrWhiteSpace($segment) -or
            $segment -eq '.' -or
            $segment -eq '..' -or
            $segment.EndsWith(".", [System.StringComparison]::Ordinal) -or
            $segment.EndsWith(" ", [System.StringComparison]::Ordinal)) {
            throw "Unsafe segment in ${Label}: $Path"
        }
        $deviceStem = $segment.Split('.')[0]
        if ($deviceStem -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') {
            throw "Reserved Windows device segment in ${Label}: $Path"
        }
    }
}


function Assert-I1VerifyJsonProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Name]) {
        throw "$Label is missing required property: $Name"
    }
}


function Get-I1VerifyPropertyValue {
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


function ConvertTo-I1VerifyInt64 {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Label,
        [int64]$Minimum = 0,
        [int64]$Maximum = [int64]::MaxValue
    )

    if (-not (
        $Value -is [byte] -or
        $Value -is [sbyte] -or
        $Value -is [int16] -or
        $Value -is [uint16] -or
        $Value -is [int32] -or
        $Value -is [uint32] -or
        $Value -is [int64]
    )) {
        throw "$Label must be an integer"
    }
    $converted = [int64]$Value
    if ($converted -lt $Minimum -or $converted -gt $Maximum) {
        throw "$Label is outside the allowed range: $converted"
    }
    return $converted
}


function Assert-I1VerifyUtcTimestamp {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Value -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        throw "$Label must be a non-empty string"
    }
    try {
        $timestamp = [datetime]::ParseExact(
            [string]$Value,
            "o",
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind
        )
    }
    catch {
        throw "$Label is not a round-trip timestamp: $Value"
    }
    if ($timestamp.Kind -ne [System.DateTimeKind]::Utc -or
        $timestamp.ToString(
            "o",
            [System.Globalization.CultureInfo]::InvariantCulture
        ) -cne [string]$Value) {
        throw "$Label must be a canonical UTC round-trip timestamp: $Value"
    }
}


function Assert-I1VerifyNoAlternateDataStreams {
    param([Parameter(Mandatory = $true)][string]$Path)

    $streams = @(Get-Item -LiteralPath $Path -Stream * -Force -ErrorAction Stop)
    if ($streams.Count -ne 1 -or [string]$streams[0].Stream -cne ':$DATA') {
        $streamNames = @($streams | ForEach-Object { [string]$_.Stream }) -join ','
        throw "Alternate data streams are forbidden: $Path streams=$streamNames"
    }
}


function Assert-I1VerifyRegularFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I0PathWithin -Path $Path -Root $AllowedRoot -Label $Label
    Assert-I0NoReparseExistingAncestor -Path $Path -Root $WorkspaceRoot -Label $Label
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label is missing or is not a file: $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($item.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0 -or
        ($item.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
        throw "$Label is not a permitted regular file: $Path"
    }
    Assert-I1VerifyNoAlternateDataStreams -Path $Path
}


function Assert-I1VerifyArchiveTreeSafety {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $pending = New-Object System.Collections.Stack
    $pending.Push($ArchiveRoot)
    while ($pending.Count -gt 0) {
        $directory = [string]$pending.Pop()
        foreach ($entry in @(Get-ChildItem -LiteralPath $directory -Force)) {
            $entryPath = Get-I0CanonicalPath -Path $entry.FullName
            Assert-I0PathWithin `
                -Path $entryPath `
                -Root $ArchiveRoot `
                -Label "archive tree entry"
            Assert-I0NoReparseExistingAncestor `
                -Path $entryPath `
                -Root $WorkspaceRoot `
                -Label "archive tree entry"
            if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse points are forbidden in the archive tree: $entryPath"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
                throw "Device entries are forbidden in the archive tree: $entryPath"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
                $pending.Push($entryPath)
            }
            else {
                Assert-I1VerifyNoAlternateDataStreams -Path $entryPath
            }
        }
    }
}


function Resolve-I1VerifyRelativeFile {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I1VerifyRelativePath -Path $RelativePath -Label $Label
    $resolved = Get-I0CanonicalPath -Path (
        Join-Path $Root $RelativePath.Replace('/', '\')
    )
    Assert-I0PathWithin -Path $resolved -Root $Root -Label $Label
    $roundTrip = (Get-I0RelativePath -Path $resolved -Root $Root).Replace('\', '/')
    if ($roundTrip -cne $RelativePath) {
        throw "$Label changes after Windows path normalization: $RelativePath"
    }
    return $resolved
}


function Read-I1VerifyStrictJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $text = $strictUtf8.GetString($bytes)
        $value = $text | ConvertFrom-Json
    }
    catch {
        throw "$Label is not strict UTF-8 JSON: $Path"
    }
    if ($null -eq $value -or $value -is [array]) {
        throw "$Label root must be a JSON object: $Path"
    }
    return [pscustomobject][ordered]@{
        bytes = $bytes
        value = $value
        sha256 = Get-I1VerifyBytesSha256 -Bytes $bytes
    }
}


function Assert-I1VerifyShaSidecar {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedSha256,
        [Parameter(Mandatory = $true)][string]$ExpectedFileName,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $text = $strictUtf8.GetString($bytes)
    }
    catch {
        throw "$Label is not strict UTF-8: $Path"
    }
    $expected = "$ExpectedSha256  $ExpectedFileName`n"
    if ($text -cne $expected) {
        throw "$Label does not have the canonical expected content: $Path"
    }
    return $bytes
}


function Get-I1VerifyObjectPath {
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


function Assert-I1VerifyExpectedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Record,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I1VerifyRegularFile `
        -Path $Path `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $AllowedRoot `
        -Label $Label
    $before = Get-Item -LiteralPath $Path -Force
    $expectedLength = ConvertTo-I1VerifyInt64 `
        -Value $Record.length `
        -Label "$Label length"
    if ([int64]$before.Length -ne $expectedLength) {
        throw "$Label length mismatch: $Path"
    }
    $mtimeTicks = [int64]$before.LastWriteTimeUtc.Ticks
    $attributes = [int64]$before.Attributes
    $actualSha256 = Get-I1VerifyFileSha256 -Path $Path
    $after = Get-Item -LiteralPath $Path -Force
    if ([int64]$after.Length -ne $expectedLength -or
        [int64]$after.LastWriteTimeUtc.Ticks -ne $mtimeTicks -or
        [int64]$after.Attributes -ne $attributes) {
        throw "$Label changed while it was being verified: $Path"
    }
    if ($Record.sha256 -isnot [string] -or
        [string]$Record.sha256 -notmatch '^[0-9A-F]{64}$' -or
        $actualSha256 -cne [string]$Record.sha256) {
        throw "$Label SHA-256 mismatch: $Path"
    }
    Assert-I1VerifyNoAlternateDataStreams -Path $Path
}


function Assert-I1VerifyEvidenceRecord {
    param(
        [Parameter(Mandatory = $true)]$Record,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($null -eq $Record -or $Record -is [array]) {
        throw "$Label is not an object"
    }
    foreach ($property in @("path", "sha256", "length", "mtime_utc", "attributes")) {
        Assert-I1VerifyJsonProperty -Object $Record -Name $property -Label $Label
    }
    if ($Record.path -isnot [string]) {
        throw "$Label path must be a string"
    }
    Assert-I1VerifyRelativePath -Path ([string]$Record.path) -Label "$Label path"
    if ($Record.sha256 -isnot [string] -or
        [string]$Record.sha256 -notmatch '^[0-9A-F]{64}$') {
        throw "$Label SHA-256 is invalid"
    }
    [void](ConvertTo-I1VerifyInt64 -Value $Record.length -Label "$Label length")
    [void](ConvertTo-I1VerifyInt64 `
        -Value $Record.attributes `
        -Label "$Label attributes" `
        -Maximum ([int64][int]::MaxValue))
    $recordAttributes = [System.IO.FileAttributes][int][int64]$Record.attributes
    if (($recordAttributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($recordAttributes -band [System.IO.FileAttributes]::Directory) -ne 0 -or
        ($recordAttributes -band [System.IO.FileAttributes]::Device) -ne 0) {
        throw "$Label attributes describe a forbidden entry"
    }
    Assert-I1VerifyUtcTimestamp -Value $Record.mtime_utc -Label "$Label mtime_utc"
}


function Write-I1VerifyAtomicFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot
    )

    Assert-I0PathWithin -Path $Path -Root $ArchiveRoot -Label "verification proof"
    $directory = Get-I0CanonicalPath -Path (Split-Path -Parent $Path)
    Assert-I0PathWithin -Path $directory -Root $ArchiveRoot -Label "verification proof directory"
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "verification proof directory"
    [void](New-Item -ItemType Directory -Path $directory -Force)
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "verification proof directory"
    if (Test-Path -LiteralPath $Path) {
        Assert-I1VerifyRegularFile `
            -Path $Path `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $ArchiveRoot `
            -Label "existing verification proof"
    }

    $temporaryPath = Join-Path $directory (
        ".{0}.tmp.{1}.{2}" -f
        [System.IO.Path]::GetFileName($Path),
        $PID,
        ([guid]::NewGuid().ToString("N"))
    )
    $backupPath = Join-Path $directory (
        ".{0}.backup.{1}.{2}" -f
        [System.IO.Path]::GetFileName($Path),
        $PID,
        ([guid]::NewGuid().ToString("N"))
    )
    try {
        [System.IO.File]::WriteAllBytes($temporaryPath, $Bytes)
        Assert-I1VerifyRegularFile `
            -Path $temporaryPath `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $ArchiveRoot `
            -Label "temporary verification proof"
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
    $actual = [System.IO.File]::ReadAllBytes($Path)
    if (-not (Test-I1VerifyByteArrayEqual -Left $actual -Right $Bytes)) {
        throw "Verification proof changed during atomic publication: $Path"
    }
}


$result = $null
$exitCode = 0
$mutationMayHaveOccurred = $false

try {
    if ($PSVersionTable.PSEdition -cne "Desktop" -or
        $PSVersionTable.PSVersion.Major -ne 5 -or
        $PSVersionTable.PSVersion.Minor -lt 1) {
        throw "I1 snapshot archive verification requires Windows PowerShell 5.1 Desktop"
    }

    $repoCandidate = Get-I0CanonicalPath -Path (Join-Path $PSScriptRoot "..\..")
    $repoResult = Invoke-I0Git `
        -RepoRoot $repoCandidate `
        -Arguments @("rev-parse", "--path-format=absolute", "--show-toplevel")
    $resolvedRepo = Get-I0CanonicalPath -Path (
        Normalize-I0ProcessText -Text $repoResult.stdout
    )
    if (-not [string]::Equals(
        $repoCandidate,
        $resolvedRepo,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Verification script is not running from the selected Git worktree"
    }
    $commonResult = Invoke-I0Git `
        -RepoRoot $resolvedRepo `
        -Arguments @("rev-parse", "--path-format=absolute", "--git-common-dir")
    $gitCommon = Get-I0CanonicalPath -Path (
        Normalize-I0ProcessText -Text $commonResult.stdout
    )
    $workspaceRoot = Get-I1VerifyWorkspaceRoot `
        -RepoRoot $resolvedRepo `
        -GitCommon $gitCommon
    [void](Set-I0WorkspaceRoot -Path $workspaceRoot)

    $expectedArchiveRoot = Get-I0CanonicalPath -Path (
        Join-Path $workspaceRoot ".tmp\i1_snapshot_archive"
    )
    $resolvedArchiveRoot = Get-I0CanonicalPath -Path $ArchiveRoot
    if (-not [string]::Equals(
        $resolvedArchiveRoot,
        $expectedArchiveRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "ArchiveRoot must be the git-common workspace's exact .tmp\\i1_snapshot_archive. expected=$expectedArchiveRoot"
    }
    if (-not (Test-Path -LiteralPath $resolvedArchiveRoot -PathType Container)) {
        throw "ArchiveRoot does not exist: $resolvedArchiveRoot"
    }
    Assert-I0NoReparseExistingAncestor `
        -Path $resolvedArchiveRoot `
        -Root $workspaceRoot `
        -Label "ArchiveRoot"
    $archiveRootItem = Get-Item -LiteralPath $resolvedArchiveRoot -Force
    if (($archiveRootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "ArchiveRoot is a reparse point: $resolvedArchiveRoot"
    }
    Assert-I1VerifyArchiveTreeSafety `
        -ArchiveRoot $resolvedArchiveRoot `
        -WorkspaceRoot $workspaceRoot

    $indexPath = Get-I0CanonicalPath -Path (Join-Path $resolvedArchiveRoot "index.json")
    $indexShaPath = Get-I0CanonicalPath -Path (Join-Path $resolvedArchiveRoot "index.sha256")
    Assert-I1VerifyRegularFile `
        -Path $indexPath `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $resolvedArchiveRoot `
        -Label "archive index"
    Assert-I1VerifyRegularFile `
        -Path $indexShaPath `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $resolvedArchiveRoot `
        -Label "archive index sidecar"
    $indexDocument = Read-I1VerifyStrictJson -Path $indexPath -Label "archive index"
    $indexSidecarBytes = Assert-I1VerifyShaSidecar `
        -Path $indexShaPath `
        -ExpectedSha256 $indexDocument.sha256 `
        -ExpectedFileName "index.json" `
        -Label "archive index sidecar"
    Assert-I1VerifyJsonProperty `
        -Object $indexDocument.value `
        -Name "schema_version" `
        -Label "archive index"
    Assert-I1VerifyJsonProperty `
        -Object $indexDocument.value `
        -Name "snapshots" `
        -Label "archive index"
    $indexSchema = ConvertTo-I1VerifyInt64 `
        -Value $indexDocument.value.schema_version `
        -Label "archive index schema_version" `
        -Minimum 1 `
        -Maximum 1
    if ($indexSchema -ne 1) {
        throw "Unsupported archive index schema: $indexSchema"
    }

    if ($indexDocument.value.snapshots -isnot [array]) {
        throw "Archive index snapshots must be an array"
    }
    $indexEntries = @($indexDocument.value.snapshots)
    $seenSnapshots = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $objectLengthByHash = @{}
    $evidenceCache = @{}
    $namespaceCountByName = @{}
    $manifestBindingLines = New-Object System.Collections.Generic.List[string]
    $manifestStabilityRecords = New-Object System.Collections.Generic.List[object]
    [int64]$snapshotLogicalBytes = 0
    [int64]$snapshotFileCount = 0
    [int64]$evidenceFileCount = 0
    [int64]$evidenceLogicalBytes = 0
    $previousSnapshotKey = $null

    foreach ($entry in $indexEntries) {
        if ($null -eq $entry -or $entry -is [array]) {
            throw "Archive index contains a non-object snapshot entry"
        }
        foreach ($property in @(
            "namespace",
            "run_id",
            "manifest_path",
            "manifest_sha256",
            "report_sha256",
            "file_count",
            "logical_bytes"
        )) {
            Assert-I1VerifyJsonProperty `
                -Object $entry `
                -Name $property `
                -Label "archive index snapshot entry"
        }
        if ($entry.namespace -isnot [string] -or $entry.run_id -isnot [string]) {
            throw "Archive index namespace and run_id must be strings"
        }
        $namespace = [string]$entry.namespace
        $runId = [string]$entry.run_id
        Assert-I1VerifyLeafName -Value $namespace -Label "index namespace"
        Assert-I1VerifyLeafName -Value $runId -Label "index run_id"
        if (-not $namespaceCountByName.ContainsKey($namespace)) {
            $namespaceCountByName[$namespace] = 0
        }
        $namespaceCountByName[$namespace] = [int64]$namespaceCountByName[$namespace] + 1
        $snapshotKey = "$namespace`0$runId"
        if (-not $seenSnapshots.Add($snapshotKey)) {
            throw "Duplicate case-insensitive snapshot identity in archive index: $namespace/$runId"
        }
        if ($null -ne $previousSnapshotKey -and
            [System.StringComparer]::Ordinal.Compare(
                [string]$previousSnapshotKey,
                $snapshotKey
            ) -ge 0) {
            throw "Archive index snapshots are not in strict ordinal identity order: $namespace/$runId"
        }
        $previousSnapshotKey = $snapshotKey

        if ($entry.manifest_path -isnot [string]) {
            throw "Archive index manifest_path must be a string: $namespace/$runId"
        }
        $expectedManifestRelative = "snapshots/$namespace/$runId/manifest.json"
        if ([string]$entry.manifest_path -cne $expectedManifestRelative) {
            throw "Archive index manifest_path is not canonical: $($entry.manifest_path)"
        }
        $manifestPath = Resolve-I1VerifyRelativeFile `
            -Root $resolvedArchiveRoot `
            -RelativePath $expectedManifestRelative `
            -Label "archive manifest path"
        $manifestShaPath = Get-I0CanonicalPath -Path (
            Join-Path (Split-Path -Parent $manifestPath) "manifest.sha256"
        )
        Assert-I1VerifyRegularFile `
            -Path $manifestPath `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedArchiveRoot `
            -Label "archive manifest"
        Assert-I1VerifyRegularFile `
            -Path $manifestShaPath `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedArchiveRoot `
            -Label "archive manifest sidecar"
        $manifestDocument = Read-I1VerifyStrictJson `
            -Path $manifestPath `
            -Label "archive manifest"
        if ($entry.manifest_sha256 -isnot [string] -or
            [string]$entry.manifest_sha256 -notmatch '^[0-9A-F]{64}$' -or
            [string]$entry.manifest_sha256 -cne $manifestDocument.sha256) {
            throw "Archive index manifest SHA-256 binding mismatch: $namespace/$runId"
        }
        [void]$manifestBindingLines.Add(
            "$namespace/$runId=$($manifestDocument.sha256)"
        )
        $manifestSidecarBytes = Assert-I1VerifyShaSidecar `
            -Path $manifestShaPath `
            -ExpectedSha256 $manifestDocument.sha256 `
            -ExpectedFileName "manifest.json" `
            -Label "archive manifest sidecar"

        $manifest = $manifestDocument.value
        foreach ($property in @(
            "schema_version",
            "namespace",
            "run_id",
            "runs_root",
            "report",
            "evidence",
            "files"
        )) {
            Assert-I1VerifyJsonProperty `
                -Object $manifest `
                -Name $property `
                -Label "archive manifest"
        }
        [void](ConvertTo-I1VerifyInt64 `
            -Value $manifest.schema_version `
            -Label "archive manifest schema_version" `
            -Minimum 1 `
            -Maximum 1)
        if ([string]$manifest.namespace -cne $namespace -or
            [string]$manifest.run_id -cne $runId) {
            throw "Archive manifest identity does not match its index entry: $namespace/$runId"
        }
        if ($manifest.runs_root -isnot [string] -or
            -not [System.IO.Path]::IsPathRooted([string]$manifest.runs_root)) {
            throw "Archive manifest runs_root must be an absolute path: $namespace/$runId"
        }
        $runsRoot = Get-I0CanonicalPath -Path ([string]$manifest.runs_root)
        Assert-I0PathWithin `
            -Path $runsRoot `
            -Root $workspaceRoot `
            -Label "manifest runs_root"
        Assert-I0NoReparseExistingAncestor `
            -Path $runsRoot `
            -Root $workspaceRoot `
            -Label "manifest runs_root"
        if (-not (Test-Path -LiteralPath $runsRoot -PathType Container)) {
            throw "Manifest runs_root no longer exists: $runsRoot"
        }
        $runRoot = Get-I0CanonicalPath -Path (Join-Path $runsRoot $runId)
        Assert-I0PathWithin -Path $runRoot -Root $runsRoot -Label "manifest run root"
        Assert-I0NoReparseExistingAncestor `
            -Path $runRoot `
            -Root $workspaceRoot `
            -Label "manifest run root"
        if (-not (Test-Path -LiteralPath $runRoot -PathType Container)) {
            throw "Manifest run root no longer exists: $runRoot"
        }

        if ($manifest.files -isnot [array] -or $manifest.evidence -isnot [array]) {
            throw "Archive manifest files and evidence must be arrays: $namespace/$runId"
        }
        $files = @($manifest.files)
        $seenFilePaths = New-Object "System.Collections.Generic.HashSet[string]" (
            [System.StringComparer]::OrdinalIgnoreCase
        )
        $filePathSet = New-Object "System.Collections.Generic.HashSet[string]" (
            [System.StringComparer]::OrdinalIgnoreCase
        )
        $previousFilePath = $null
        [int64]$manifestLogicalBytes = 0
        foreach ($record in $files) {
            Assert-I1VerifyEvidenceRecord `
                -Record $record `
                -Label "manifest file record"
            $relativePath = [string]$record.path
            if (-not $seenFilePaths.Add($relativePath)) {
                throw "Duplicate case-insensitive file path in manifest: $relativePath"
            }
            if ($null -ne $previousFilePath -and
                [System.StringComparer]::Ordinal.Compare(
                    [string]$previousFilePath,
                    $relativePath
                ) -ge 0) {
                throw "Manifest file paths are not in strict ordinal order: $relativePath"
            }
            $previousFilePath = $relativePath
            [void]$filePathSet.Add($relativePath)
            $recordLength = [int64]$record.length
            $manifestLogicalBytes += $recordLength
            $recordSha256 = [string]$record.sha256
            if ($objectLengthByHash.ContainsKey($recordSha256)) {
                if ([int64]$objectLengthByHash[$recordSha256] -ne $recordLength) {
                    throw "SHA-256 collision with different lengths across manifests: $recordSha256"
                }
            }
            else {
                $objectLengthByHash[$recordSha256] = $recordLength
            }
        }
        foreach ($record in $files) {
            $segments = @(([string]$record.path).Split('/'))
            $prefix = ""
            for ($segmentIndex = 0; $segmentIndex -lt ($segments.Count - 1); $segmentIndex++) {
                $prefix = if ($segmentIndex -eq 0) {
                    [string]$segments[$segmentIndex]
                }
                else {
                    "$prefix/$($segments[$segmentIndex])"
                }
                if ($filePathSet.Contains($prefix)) {
                    throw "Manifest file path is also used as a parent directory: $prefix"
                }
            }
        }

        $indexFileCount = ConvertTo-I1VerifyInt64 `
            -Value $entry.file_count `
            -Label "index file_count"
        $indexLogicalBytes = ConvertTo-I1VerifyInt64 `
            -Value $entry.logical_bytes `
            -Label "index logical_bytes"
        if ($indexFileCount -ne $files.Count -or
            $indexLogicalBytes -ne $manifestLogicalBytes) {
            throw "Archive index inventory binding mismatch: $namespace/$runId"
        }
        $snapshotFileCount += $files.Count
        $snapshotLogicalBytes += $manifestLogicalBytes

        $report = $manifest.report
        if ($null -eq $report) {
            if ($null -ne $entry.report_sha256) {
                throw "Archive index reports a SHA-256 for a manifest with no report: $namespace/$runId"
            }
        }
        else {
            Assert-I1VerifyEvidenceRecord -Record $report -Label "manifest report record"
            if ([string]$report.path -cne "report.json") {
                throw "Manifest report path is not canonical: $namespace/$runId"
            }
            if ($entry.report_sha256 -isnot [string] -or
                [string]$entry.report_sha256 -cne [string]$report.sha256) {
                throw "Archive index report SHA-256 binding mismatch: $namespace/$runId"
            }
            $reportPath = Resolve-I1VerifyRelativeFile `
                -Root $runRoot `
                -RelativePath ([string]$report.path) `
                -Label "manifest report"
            $reportCacheKey = $reportPath.ToLowerInvariant()
            if (-not $evidenceCache.ContainsKey($reportCacheKey)) {
                Assert-I1VerifyExpectedFile `
                    -Path $reportPath `
                    -Record $report `
                    -WorkspaceRoot $workspaceRoot `
                    -AllowedRoot $runRoot `
                    -Label "manifest report"
                $evidenceCache[$reportCacheKey] = [pscustomobject][ordered]@{
                    sha256 = [string]$report.sha256
                    length = [int64]$report.length
                }
                $evidenceFileCount += 1
                $evidenceLogicalBytes += [int64]$report.length
            }
            elseif (
                [string]$evidenceCache[$reportCacheKey].sha256 -cne [string]$report.sha256 -or
                [int64]$evidenceCache[$reportCacheKey].length -ne [int64]$report.length
            ) {
                throw "Evidence path has conflicting SHA-256 records: $reportPath"
            }
        }

        $previousEvidencePath = $null
        $seenEvidencePaths = New-Object "System.Collections.Generic.HashSet[string]" (
            [System.StringComparer]::OrdinalIgnoreCase
        )
        foreach ($evidenceRecord in @($manifest.evidence)) {
            Assert-I1VerifyEvidenceRecord `
                -Record $evidenceRecord `
                -Label "manifest evidence record"
            $evidenceRelative = [string]$evidenceRecord.path
            if (-not $seenEvidencePaths.Add($evidenceRelative)) {
                throw "Duplicate case-insensitive evidence path: $evidenceRelative"
            }
            if ($null -ne $previousEvidencePath -and
                [System.StringComparer]::Ordinal.Compare(
                    [string]$previousEvidencePath,
                    $evidenceRelative
                ) -ge 0) {
                throw "Manifest evidence paths are not in strict ordinal order: $evidenceRelative"
            }
            $previousEvidencePath = $evidenceRelative
            $evidencePath = Resolve-I1VerifyRelativeFile `
                -Root $runRoot `
                -RelativePath $evidenceRelative `
                -Label "manifest evidence"
            $evidenceCacheKey = $evidencePath.ToLowerInvariant()
            if (-not $evidenceCache.ContainsKey($evidenceCacheKey)) {
                Assert-I1VerifyExpectedFile `
                    -Path $evidencePath `
                    -Record $evidenceRecord `
                    -WorkspaceRoot $workspaceRoot `
                    -AllowedRoot $runRoot `
                    -Label "manifest evidence"
                $evidenceCache[$evidenceCacheKey] = [pscustomobject][ordered]@{
                    sha256 = [string]$evidenceRecord.sha256
                    length = [int64]$evidenceRecord.length
                }
                $evidenceFileCount += 1
                $evidenceLogicalBytes += [int64]$evidenceRecord.length
            }
            elseif (
                [string]$evidenceCache[$evidenceCacheKey].sha256 -cne [string]$evidenceRecord.sha256 -or
                [int64]$evidenceCache[$evidenceCacheKey].length -ne [int64]$evidenceRecord.length
            ) {
                throw "Evidence path has conflicting SHA-256 records: $evidencePath"
            }
        }

        [void]$manifestStabilityRecords.Add([pscustomobject][ordered]@{
            path = $manifestPath
            bytes = $manifestDocument.bytes
            sidecar_path = $manifestShaPath
            sidecar_bytes = $manifestSidecarBytes
        })
    }

    $snapshotsRoot = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "snapshots"
    )
    Assert-I0PathWithin `
        -Path $snapshotsRoot `
        -Root $resolvedArchiveRoot `
        -Label "archive snapshots root"
    Assert-I0NoReparseExistingAncestor `
        -Path $snapshotsRoot `
        -Root $workspaceRoot `
        -Label "archive snapshots root"
    if (-not (Test-Path -LiteralPath $snapshotsRoot -PathType Container)) {
        throw "Archive snapshots root is missing: $snapshotsRoot"
    }
    $enumeratedSnapshots = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($namespaceDirectory in @(Get-ChildItem -LiteralPath $snapshotsRoot -Directory -Force)) {
        if (($namespaceDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse namespace directory in archive snapshots: $($namespaceDirectory.FullName)"
        }
        Assert-I1VerifyLeafName `
            -Value ([string]$namespaceDirectory.Name) `
            -Label "archived namespace"
        foreach ($runDirectory in @(Get-ChildItem -LiteralPath $namespaceDirectory.FullName -Directory -Force)) {
            if (($runDirectory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse run directory in archive snapshots: $($runDirectory.FullName)"
            }
            Assert-I1VerifyLeafName `
                -Value ([string]$runDirectory.Name) `
                -Label "archived run_id"
            $enumeratedKey = "$($namespaceDirectory.Name)`0$($runDirectory.Name)"
            if (-not $enumeratedSnapshots.Add($enumeratedKey)) {
                throw "Duplicate case-insensitive snapshot directory identity: $enumeratedKey"
            }
        }
    }
    if ($enumeratedSnapshots.Count -ne $seenSnapshots.Count) {
        throw "Archive index does not enumerate every snapshot directory"
    }
    foreach ($snapshotKey in $seenSnapshots) {
        if (-not $enumeratedSnapshots.Contains($snapshotKey)) {
            throw "Archive index references a missing snapshot directory: $snapshotKey"
        }
    }

    [string[]]$uniqueObjectHashes = @(
        $objectLengthByHash.Keys | ForEach-Object { [string]$_ }
    )
    [System.Array]::Sort($uniqueObjectHashes, [System.StringComparer]::Ordinal)
    [int64]$uniqueObjectBytes = 0
    $objectBindingLines = New-Object System.Collections.Generic.List[string]
    foreach ($objectSha256 in $uniqueObjectHashes) {
        $objectLength = [int64]$objectLengthByHash[$objectSha256]
        [void]$objectBindingLines.Add("$objectSha256`:$objectLength")
        $objectPath = Get-I1VerifyObjectPath `
            -ArchiveRoot $resolvedArchiveRoot `
            -Sha256 $objectSha256
        Assert-I1VerifyExpectedFile `
            -Path $objectPath `
            -Record ([pscustomobject][ordered]@{
                sha256 = $objectSha256
                length = $objectLength
            }) `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedArchiveRoot `
            -Label "archive CAS object"
        $uniqueObjectBytes += $objectLength
    }

    $objectsRoot = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "objects\sha256"
    )
    Assert-I0PathWithin `
        -Path $objectsRoot `
        -Root $resolvedArchiveRoot `
        -Label "archive CAS root"
    Assert-I0NoReparseExistingAncestor `
        -Path $objectsRoot `
        -Root $workspaceRoot `
        -Label "archive CAS root"
    if (-not (Test-Path -LiteralPath $objectsRoot -PathType Container)) {
        throw "Archive CAS root is missing: $objectsRoot"
    }
    $enumeratedObjects = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($objectItem in @(
        Get-ChildItem -LiteralPath $objectsRoot -Recurse -Force -File
    )) {
        $objectName = [string]$objectItem.Name
        if ($objectName -notmatch '^[0-9a-f]{64}$') {
            throw "Archive CAS contains a non-canonical object name: $($objectItem.FullName)"
        }
        $objectSha256 = $objectName.ToUpperInvariant()
        if (-not $enumeratedObjects.Add($objectSha256)) {
            throw "Archive CAS contains a duplicate case-insensitive object: $objectSha256"
        }
        $expectedObjectPath = Get-I1VerifyObjectPath `
            -ArchiveRoot $resolvedArchiveRoot `
            -Sha256 $objectSha256
        if (-not [string]::Equals(
            $expectedObjectPath,
            (Get-I0CanonicalPath -Path $objectItem.FullName),
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Archive CAS object is stored at a non-canonical path: $($objectItem.FullName)"
        }
    }
    if ($enumeratedObjects.Count -ne $uniqueObjectHashes.Count) {
        throw "Archive CAS contains missing or unreferenced objects"
    }
    foreach ($objectSha256 in $uniqueObjectHashes) {
        if (-not $enumeratedObjects.Contains($objectSha256)) {
            throw "Archive CAS enumeration is missing a referenced object: $objectSha256"
        }
    }

    foreach ($stabilityRecord in $manifestStabilityRecords) {
        $manifestBytesAfter = [System.IO.File]::ReadAllBytes(
            [string]$stabilityRecord.path
        )
        if (-not (Test-I1VerifyByteArrayEqual `
            -Left $manifestBytesAfter `
            -Right ([byte[]]$stabilityRecord.bytes))) {
            throw "Archive manifest changed during global verification: $($stabilityRecord.path)"
        }
        $sidecarBytesAfter = [System.IO.File]::ReadAllBytes(
            [string]$stabilityRecord.sidecar_path
        )
        if (-not (Test-I1VerifyByteArrayEqual `
            -Left $sidecarBytesAfter `
            -Right ([byte[]]$stabilityRecord.sidecar_bytes))) {
            throw "Archive manifest sidecar changed during global verification: $($stabilityRecord.sidecar_path)"
        }
    }
    $indexBytesAfter = [System.IO.File]::ReadAllBytes($indexPath)
    if (-not (Test-I1VerifyByteArrayEqual `
        -Left $indexBytesAfter `
        -Right ([byte[]]$indexDocument.bytes))) {
        throw "Archive index changed during global verification: $indexPath"
    }
    $indexSidecarBytesAfter = [System.IO.File]::ReadAllBytes($indexShaPath)
    if (-not (Test-I1VerifyByteArrayEqual `
        -Left $indexSidecarBytesAfter `
        -Right ([byte[]]$indexSidecarBytes))) {
        throw "Archive index sidecar changed during global verification: $indexShaPath"
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    $manifestSetBytes = $encoding.GetBytes(
        ([string]::Join("`n", $manifestBindingLines.ToArray()) + "`n")
    )
    $objectSetBytes = $encoding.GetBytes(
        ([string]::Join("`n", $objectBindingLines.ToArray()) + "`n")
    )
    $namespaceCounts = New-Object System.Collections.Generic.List[object]
    [string[]]$namespaceNames = @(
        $namespaceCountByName.Keys | ForEach-Object { [string]$_ }
    )
    [System.Array]::Sort($namespaceNames, [System.StringComparer]::Ordinal)
    foreach ($namespaceName in $namespaceNames) {
        [void]$namespaceCounts.Add([pscustomobject][ordered]@{
            namespace = $namespaceName
            snapshot_count = [int64]$namespaceCountByName[$namespaceName]
        })
    }

    $verifierPath = Get-I0CanonicalPath -Path $MyInvocation.MyCommand.Path
    $archiveToolPath = Get-I0CanonicalPath -Path (
        Join-Path $PSScriptRoot "archive_i1_worktrees.ps1"
    )
    $restoreToolPath = Get-I0CanonicalPath -Path (
        Join-Path $PSScriptRoot "restore_i1_worktree_archive.ps1"
    )
    $sharedLibraryPath = Get-I0CanonicalPath -Path (
        Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1"
    )
    foreach ($toolPath in @(
        $verifierPath,
        $archiveToolPath,
        $restoreToolPath,
        $sharedLibraryPath
    )) {
        Assert-I1VerifyRegularFile `
            -Path $toolPath `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedRepo `
            -Label "archive governance tool"
    }

    $verifierSha256 = Get-I1VerifyFileSha256 -Path $verifierPath
    $proof = [pscustomobject][ordered]@{
        schema_version = 1
        verified_at_utc = [DateTime]::UtcNow.ToString(
            "yyyy-MM-ddTHH:mm:ss.fffffffZ",
            [System.Globalization.CultureInfo]::InvariantCulture
        )
        archive_root = $resolvedArchiveRoot
        archive_volume_root = [System.IO.Path]::GetPathRoot($resolvedArchiveRoot)
        index_sha256 = $indexDocument.sha256
        index_sidecar_file_sha256 = Get-I1VerifyBytesSha256 -Bytes $indexSidecarBytes
        snapshot_count = $indexEntries.Count
        namespace_snapshot_counts = $namespaceCounts.ToArray()
        snapshot_file_count = $snapshotFileCount
        snapshot_logical_bytes = $snapshotLogicalBytes
        manifest_set_sha256 = Get-I1VerifyBytesSha256 -Bytes $manifestSetBytes
        unique_object_count = $uniqueObjectHashes.Count
        unique_object_bytes = $uniqueObjectBytes
        unique_object_set_sha256 = Get-I1VerifyBytesSha256 -Bytes $objectSetBytes
        evidence_file_count = $evidenceFileCount
        evidence_logical_bytes = $evidenceLogicalBytes
        tool_sha256 = [pscustomobject][ordered]@{
            verifier = $verifierSha256
            archive = Get-I1VerifyFileSha256 -Path $archiveToolPath
            restore = Get-I1VerifyFileSha256 -Path $restoreToolPath
            i0_test_lib = Get-I1VerifyFileSha256 -Path $sharedLibraryPath
        }
        environment = [pscustomobject][ordered]@{
            powershell_edition = [string]$PSVersionTable.PSEdition
            powershell_version = [string]$PSVersionTable.PSVersion
            clr_version = [string]$PSVersionTable.CLRVersion
            os_version = [string][System.Environment]::OSVersion.VersionString
        }
        verification = [pscustomobject][ordered]@{
            index_sidecar_sha256 = $true
            index_manifest_binding = $true
            manifest_sidecar_sha256 = $true
            cas_object_length_and_sha256_once_per_unique_object = $true
            cas_has_no_unreferenced_objects = $true
            report_log_artifact_preview_evidence_length_and_sha256 = $true
            reparse_points_rejected = $true
            alternate_data_streams_rejected = $true
            path_traversal_rejected = $true
        }
    }
    $proofBytes = $encoding.GetBytes(($proof | ConvertTo-Json -Depth 10 -Compress))
    $proofSha256 = Get-I1VerifyBytesSha256 -Bytes $proofBytes
    $proofRoot = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "verification_proofs"
    )
    $proofPath = Get-I0CanonicalPath -Path (
        Join-Path $proofRoot "archive-verification.json"
    )
    $proofShaPath = Get-I0CanonicalPath -Path (
        Join-Path $proofRoot "archive-verification.sha256"
    )
    $proofShaBytes = $encoding.GetBytes(
        "$proofSha256  archive-verification.json`n"
    )

    if ($Apply) {
        $mutationMayHaveOccurred = $true
        Write-I1VerifyAtomicFile `
            -Path $proofPath `
            -Bytes $proofBytes `
            -WorkspaceRoot $workspaceRoot `
            -ArchiveRoot $resolvedArchiveRoot
        Write-I1VerifyAtomicFile `
            -Path $proofShaPath `
            -Bytes $proofShaBytes `
            -WorkspaceRoot $workspaceRoot `
            -ArchiveRoot $resolvedArchiveRoot
        Assert-I1VerifyRegularFile `
            -Path $proofPath `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedArchiveRoot `
            -Label "global verification proof"
        Assert-I1VerifyRegularFile `
            -Path $proofShaPath `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedArchiveRoot `
            -Label "global verification proof sidecar"
        if ((Get-I1VerifyFileSha256 -Path $proofPath) -cne $proofSha256) {
            throw "Global verification proof SHA-256 mismatch after publication"
        }
        [void](Assert-I1VerifyShaSidecar `
            -Path $proofShaPath `
            -ExpectedSha256 $proofSha256 `
            -ExpectedFileName "archive-verification.json" `
            -Label "global verification proof sidecar")
    }

    $result = [pscustomobject][ordered]@{
        schema_version = 1
        status = "PASS"
        mode = if ($Apply) { "apply" } else { "dry_run" }
        apply_requested = [bool]$Apply
        mutation_may_have_occurred = $mutationMayHaveOccurred
        selected_git_worktree = $resolvedRepo
        git_common_workspace = $workspaceRoot
        archive_root = $resolvedArchiveRoot
        index_path = $indexPath
        index_sha256 = $indexDocument.sha256
        snapshot_count = $indexEntries.Count
        snapshot_file_count = $snapshotFileCount
        snapshot_logical_bytes = $snapshotLogicalBytes
        unique_object_count = $uniqueObjectHashes.Count
        unique_object_bytes = $uniqueObjectBytes
        evidence_file_count = $evidenceFileCount
        evidence_logical_bytes = $evidenceLogicalBytes
        proof_path = $proofPath
        proof_sha256_path = $proofShaPath
        proof_sha256 = $proofSha256
        proof_written = [bool]$Apply
    }
}
catch {
    $exitCode = 1
    $result = [pscustomobject][ordered]@{
        schema_version = 1
        status = "FAIL"
        mode = if ($Apply) { "apply" } else { "dry_run" }
        apply_requested = [bool]$Apply
        mutation_may_have_occurred = $mutationMayHaveOccurred
        error = $_.Exception.Message
    }
}

Write-Output (
    "I1_SNAPSHOT_ARCHIVE_VERIFY_JSON=" +
    ($result | ConvertTo-Json -Depth 20 -Compress)
)
exit $exitCode
