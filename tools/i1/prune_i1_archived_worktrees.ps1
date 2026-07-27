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

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ArchiveRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedIndexSha256,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedGlobalProofSha256,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$RepresentativeRestoreProof,

    [switch]$Apply
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1")


function Get-I1PruneWorkspaceRoot {
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
            [string]::Equals(
                $parent,
                $candidate,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            break
        }
        $candidate = Get-I0CanonicalPath -Path $parent
    }
    throw "Unable to derive git-common workspace. repo=$RepoRoot git_common=$GitCommon"
}


function Assert-I1PruneLeafName {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Value) -or
        $Value -ne [System.IO.Path]::GetFileName($Value) -or
        $Value -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$' -or
        $Value.EndsWith(".", [System.StringComparison]::Ordinal) -or
        $Value.EndsWith(" ", [System.StringComparison]::Ordinal) -or
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


function Assert-I1PruneRelativePath {
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
    $segments = @($Path.Split('/'))
    if ($segments.Count -eq 0) {
        throw "Unsafe empty $Label"
    }
    foreach ($segment in $segments) {
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


function Get-I1PruneFileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I1PruneBytesSha256 {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $algorithm.ComputeHash($Bytes)
    }
    finally {
        $algorithm.Dispose()
    }
    return (-join @($hashBytes | ForEach-Object { $_.ToString("X2") }))
}


function Test-I1PruneByteArrayEqual {
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


function Read-I1PruneLockedStreamBytes {
    param([Parameter(Mandatory = $true)][System.IO.FileStream]$Stream)

    $Stream.Position = 0
    $memory = New-Object System.IO.MemoryStream
    try {
        $Stream.CopyTo($memory)
        return $memory.ToArray()
    }
    finally {
        $memory.Dispose()
        $Stream.Position = 0
    }
}


function Get-I1PruneStreamSha256 {
    param([Parameter(Mandatory = $true)][System.IO.FileStream]$Stream)

    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $Stream.Position = 0
        $hashBytes = $algorithm.ComputeHash($Stream)
        $Stream.Position = 0
    }
    finally {
        $algorithm.Dispose()
    }
    return (-join @($hashBytes | ForEach-Object { $_.ToString("X2") }))
}


function Add-I1PruneHeldReadLock {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$ExpectedBytes,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)]$LockStreams,
        [Parameter(Mandatory = $true)][hashtable]$LockRecordByPath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $resolvedPath = Get-I0CanonicalPath -Path $Path
    $expectedSha256 = Get-I1PruneBytesSha256 -Bytes $ExpectedBytes
    if ($LockRecordByPath.ContainsKey($resolvedPath)) {
        if ([string]$LockRecordByPath[$resolvedPath].sha256 -cne $expectedSha256) {
            throw "One critical archive path has conflicting expected bytes: $resolvedPath"
        }
        return $LockRecordByPath[$resolvedPath]
    }
    Assert-I1PruneRegularFile `
        -Path $resolvedPath `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $ArchiveRoot `
        -Label $Label
    $before = Get-Item -LiteralPath $resolvedPath -Force
    try {
        $stream = [System.IO.File]::Open(
            $resolvedPath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::Read
        )
    }
    catch {
        throw "Unable to acquire a held read lock for ${Label}: $resolvedPath error=$($_.Exception.Message)"
    }
    [void]$LockStreams.Add($stream)
    $actualBytes = Read-I1PruneLockedStreamBytes -Stream $stream
    if (-not (Test-I1PruneByteArrayEqual -Left $actualBytes -Right $ExpectedBytes)) {
        throw "$Label changed before its held read lock was established: $resolvedPath"
    }
    $after = Get-Item -LiteralPath $resolvedPath -Force
    if ([int64]$after.Length -ne [int64]$before.Length -or
        [int64]$after.LastWriteTimeUtc.Ticks -ne
        [int64]$before.LastWriteTimeUtc.Ticks -or
        [int64]$after.Attributes -ne [int64]$before.Attributes) {
        throw "$Label metadata changed while its held read lock was established: $resolvedPath"
    }
    $record = [pscustomobject][ordered]@{
        path = $resolvedPath
        allowed_root = Get-I0CanonicalPath -Path $ArchiveRoot
        sha256 = $expectedSha256
        length = [int64]$before.Length
        mtime_utc_ticks = [int64]$before.LastWriteTimeUtc.Ticks
        attributes = [int64]$before.Attributes
        stream = $stream
        label = $Label
    }
    $LockRecordByPath[$resolvedPath] = $record
    return $record
}


function Assert-I1PruneHeldReadLocksValid {
    param(
        [Parameter(Mandatory = $true)][hashtable]$LockRecordByPath,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot
    )

    foreach ($record in $LockRecordByPath.Values) {
        $path = Get-I0CanonicalPath -Path ([string]$record.path)
        $allowedRoot = Get-I0CanonicalPath -Path ([string]$record.allowed_root)
        Assert-I0PathWithin `
            -Path $allowedRoot `
            -Root $WorkspaceRoot `
            -AllowRoot `
            -Label "critical bound-file allowed root"
        Assert-I1PruneRegularFile `
            -Path $path `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $allowedRoot `
            -Label ([string]$record.label)
        if ($record.stream -isnot [System.IO.FileStream] -or
            -not $record.stream.CanRead -or
            $record.stream.SafeFileHandle.IsClosed) {
            throw "A critical bound-file read lock is no longer valid: $path"
        }
        $current = Get-Item -LiteralPath $path -Force
        if ([int64]$current.Length -ne [int64]$record.length -or
            [int64]$current.LastWriteTimeUtc.Ticks -ne
            [int64]$record.mtime_utc_ticks -or
            [int64]$current.Attributes -ne [int64]$record.attributes -or
            [int64]$record.stream.Length -ne [int64]$record.length) {
            throw "A critical bound file changed while its read lock was held: $path"
        }
        $actualSha256 = Get-I1PruneStreamSha256 -Stream $record.stream
        if ($actualSha256 -cne [string]$record.sha256) {
            throw "A critical bound file no longer matches its locked SHA-256: $path"
        }
    }
}


function Get-I1PrunePropertyValue {
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


function Assert-I1PruneJsonProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($null -eq $Object -or $null -eq $Object.PSObject.Properties[$Name]) {
        throw "$Label is missing required property: $Name"
    }
}


function ConvertTo-I1PruneInt64 {
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


function ConvertTo-I1PruneUtcTimestamp {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace([string]$Value)) {
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
    return $timestamp
}


function ConvertFrom-I1PruneStrictJsonBytes {
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $value = $strictUtf8.GetString($Bytes) | ConvertFrom-Json
    }
    catch {
        throw "$Label is not strict UTF-8 JSON"
    }
    if ($null -eq $value -or $value -is [array]) {
        throw "$Label root must be a JSON object"
    }
    return $value
}


function Read-I1PruneStrictJsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    return [pscustomobject][ordered]@{
        bytes = $bytes
        sha256 = Get-I1PruneBytesSha256 -Bytes $bytes
        value = ConvertFrom-I1PruneStrictJsonBytes -Bytes $bytes -Label $Label
    }
}


function Assert-I1PruneNoAlternateDataStreams {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][bool]$IsDirectory
    )

    $streams = @(Get-Item -LiteralPath $Path -Stream * -Force -ErrorAction Stop)
    foreach ($stream in $streams) {
        if ([string]$stream.Stream -cne ':$DATA') {
            throw "Alternate data streams are forbidden: $Path stream=$($stream.Stream)"
        }
    }
    if (-not $IsDirectory -and
        ($streams.Count -ne 1 -or [string]$streams[0].Stream -cne ':$DATA')) {
        throw "A regular file must expose exactly one default data stream: $Path"
    }
}


function Assert-I1PruneRegularFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I0PathWithin -Path $Path -Root $AllowedRoot -Label $Label
    Assert-I0NoReparseExistingAncestor -Path $Path -Root $WorkspaceRoot -Label $Label
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label is missing or is not a regular file: $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($item.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0 -or
        ($item.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
        throw "$Label is not a permitted regular file: $Path"
    }
    Assert-I1PruneNoAlternateDataStreams -Path $Path -IsDirectory $false
}


function Assert-I1PruneRegularDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$Label,
        [switch]$AllowRoot
    )

    Assert-I0PathWithin -Path $Path -Root $AllowedRoot -AllowRoot:$AllowRoot -Label $Label
    Assert-I0NoReparseExistingAncestor -Path $Path -Root $WorkspaceRoot -Label $Label
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "$Label is missing or is not a directory: $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($item.Attributes -band [System.IO.FileAttributes]::Directory) -eq 0 -or
        ($item.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
        throw "$Label is not a permitted regular directory: $Path"
    }
    Assert-I1PruneNoAlternateDataStreams -Path $Path -IsDirectory $true
}


function Assert-I1PruneTreeSafety {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $treeRoot = Get-I0CanonicalPath -Path $Root
    Assert-I1PruneRegularDirectory `
        -Path $treeRoot `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $treeRoot `
        -AllowRoot `
        -Label $Label
    $pending = New-Object System.Collections.Stack
    $pending.Push($treeRoot)
    while ($pending.Count -gt 0) {
        $directory = [string]$pending.Pop()
        foreach ($entry in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
            $entryPath = Get-I0CanonicalPath -Path $entry.FullName
            Assert-I0PathWithin -Path $entryPath -Root $treeRoot -Label "$Label entry"
            $relative = (Get-I0RelativePath -Path $entryPath -Root $treeRoot).Replace('\', '/')
            Assert-I1PruneRelativePath -Path $relative -Label "$Label relative path"
            $roundTrip = Get-I0CanonicalPath -Path (
                Join-Path $treeRoot $relative.Replace('/', '\')
            )
            if (-not [string]::Equals(
                $entryPath,
                $roundTrip,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                throw "$Label path changes after Windows normalization: $relative"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Label contains a reparse point: $entryPath"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
                throw "$Label contains a device entry: $entryPath"
            }
            $isDirectory = (
                ($entry.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0
            )
            Assert-I1PruneNoAlternateDataStreams `
                -Path $entryPath `
                -IsDirectory $isDirectory
            if ($isDirectory) {
                $pending.Push($entryPath)
            }
        }
    }
}


function Assert-I1PruneShaSidecar {
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
    $expectedText = "$ExpectedSha256  $ExpectedFileName`n"
    if ($text -cne $expectedText) {
        throw "$Label does not have the canonical expected content: $Path"
    }
    return $bytes
}


function Resolve-I1PruneRelativeFile {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I1PruneRelativePath -Path $RelativePath -Label $Label
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


function Get-I1PruneStableFileRecord {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I1PruneRegularFile `
        -Path $Path `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $AllowedRoot `
        -Label $Label
    $before = Get-Item -LiteralPath $Path -Force
    $length = [int64]$before.Length
    $mtimeTicks = [int64]$before.LastWriteTimeUtc.Ticks
    $attributes = [int64]$before.Attributes
    $sha256 = Get-I1PruneFileSha256 -Path $Path
    $after = Get-Item -LiteralPath $Path -Force
    if ([int64]$after.Length -ne $length -or
        [int64]$after.LastWriteTimeUtc.Ticks -ne $mtimeTicks -or
        [int64]$after.Attributes -ne $attributes) {
        throw "$Label changed while it was being inventoried: $Path"
    }
    Assert-I1PruneNoAlternateDataStreams -Path $Path -IsDirectory $false
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


function Get-I1PruneDirectoryRecord {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileSystemInfo]$Item,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    return [pscustomobject][ordered]@{
        path = $RelativePath
        mtime_utc = $Item.LastWriteTimeUtc.ToString(
            "o",
            [System.Globalization.CultureInfo]::InvariantCulture
        )
        attributes = [int64]$Item.Attributes
    }
}


function Assert-I1PruneManifestFileRecord {
    param(
        [Parameter(Mandatory = $true)]$Record,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($null -eq $Record -or $Record -is [array]) {
        throw "$Label is not a JSON object"
    }
    foreach ($property in @("path", "sha256", "length", "mtime_utc", "attributes")) {
        Assert-I1PruneJsonProperty -Object $Record -Name $property -Label $Label
    }
    if ($Record.path -isnot [string]) {
        throw "$Label path must be a string"
    }
    Assert-I1PruneRelativePath -Path ([string]$Record.path) -Label "$Label path"
    if ($Record.sha256 -isnot [string] -or
        [string]$Record.sha256 -notmatch '^[0-9A-F]{64}$') {
        throw "$Label SHA-256 is invalid"
    }
    [void](ConvertTo-I1PruneInt64 -Value $Record.length -Label "$Label length")
    $attributes = ConvertTo-I1PruneInt64 `
        -Value $Record.attributes `
        -Label "$Label attributes" `
        -Maximum ([int64][int]::MaxValue)
    $fileAttributes = [System.IO.FileAttributes][int]$attributes
    if (($fileAttributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
        ($fileAttributes -band [System.IO.FileAttributes]::Directory) -ne 0 -or
        ($fileAttributes -band [System.IO.FileAttributes]::Device) -ne 0) {
        throw "$Label attributes describe a forbidden file"
    }
    [void](ConvertTo-I1PruneUtcTimestamp `
        -Value $Record.mtime_utc `
        -Label "$Label mtime_utc")
}


function Assert-I1PruneRecordSetEqual {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Expected,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Actual,
        [Parameter(Mandatory = $true)][string[]]$Properties,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($Actual.Count -ne $Expected.Count) {
        throw "$Label count mismatch. expected=$($Expected.Count) actual=$($Actual.Count)"
    }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        foreach ($property in $Properties) {
            if ([string]$Actual[$index].$property -cne
                [string]$Expected[$index].$property) {
                throw "$Label mismatch. path=$($Expected[$index].path) property=$property"
            }
        }
    }
}


function Get-I1PruneRecordSetSha256 {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Records,
        [Parameter(Mandatory = $true)][string[]]$Properties
    )

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($record in $Records) {
        $values = New-Object System.Collections.Generic.List[string]
        foreach ($property in $Properties) {
            [void]$values.Add([string]$record.$property)
        }
        [void]$lines.Add([string]::Join("`t", $values.ToArray()))
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $text = if ($lines.Count -eq 0) {
        ""
    }
    else {
        [string]::Join("`n", $lines.ToArray()) + "`n"
    }
    return Get-I1PruneBytesSha256 -Bytes $encoding.GetBytes($text)
}


function Get-I1PruneFileTypeSummary {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Records
    )

    $stats = @{}
    foreach ($record in $Records) {
        $extension = [System.IO.Path]::GetExtension([string]$record.path)
        if ([string]::IsNullOrWhiteSpace($extension)) {
            $extension = "<none>"
        }
        else {
            $extension = $extension.ToLowerInvariant()
        }
        if (-not $stats.ContainsKey($extension)) {
            $stats[$extension] = [pscustomobject][ordered]@{
                extension = $extension
                file_count = [int64]0
                logical_bytes = [int64]0
            }
        }
        $stats[$extension].file_count = [int64]$stats[$extension].file_count + 1
        $stats[$extension].logical_bytes = (
            [int64]$stats[$extension].logical_bytes + [int64]$record.length
        )
    }
    [string[]]$extensions = @($stats.Keys | ForEach-Object { [string]$_ })
    [System.Array]::Sort($extensions, [System.StringComparer]::Ordinal)
    $result = New-Object System.Collections.Generic.List[object]
    foreach ($extension in $extensions) {
        [void]$result.Add($stats[$extension])
    }
    return $result.ToArray()
}


function Assert-I1PruneGitPointer {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Worktree,
        [Parameter(Mandatory = $true)][string]$GitCommon,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -gt 4096) {
        throw "The excluded .git pointer is unexpectedly large: $Path"
    }
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $text = $strictUtf8.GetString($bytes)
    }
    catch {
        throw "The excluded .git pointer is not strict UTF-8: $Path"
    }
    $match = [regex]::Match(
        $text,
        '\Agitdir: (?<target>[^\r\n]+)(?:\r?\n)?\z',
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    )
    if (-not $match.Success) {
        throw "The excluded .git file is not a canonical gitdir pointer: $Path"
    }
    $pointerValue = [string]$match.Groups["target"].Value
    $pointerTarget = if ([System.IO.Path]::IsPathRooted($pointerValue)) {
        Get-I0CanonicalPath -Path $pointerValue
    }
    else {
        Get-I0CanonicalPath -Path (Join-Path $Worktree $pointerValue)
    }
    Assert-I0PathWithin `
        -Path $pointerTarget `
        -Root $GitCommon `
        -AllowRoot `
        -Label "excluded .git pointer target"
    Assert-I0NoReparseExistingAncestor `
        -Path $pointerTarget `
        -Root $WorkspaceRoot `
        -Label "excluded .git pointer target"
    if (-not (Test-Path -LiteralPath $pointerTarget -PathType Container)) {
        throw "The excluded .git pointer target is missing: $pointerTarget"
    }
    return $pointerTarget
}


function Get-I1PruneWorktreeInventory {
    param(
        [Parameter(Mandatory = $true)][string]$Worktree,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$GitCommon
    )

    $worktreePath = Get-I0CanonicalPath -Path $Worktree
    Assert-I1PruneRegularDirectory `
        -Path $worktreePath `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $WorkspaceRoot `
        -Label "I1 source worktree"

    $pending = New-Object System.Collections.Stack
    $pending.Push([pscustomobject]@{
        directory = $worktreePath
        exclusion = ""
    })
    $includedByPath = @{}
    $excludedByPath = @{}
    $directoriesByPath = @{}
    $gitPointerTarget = $null

    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        foreach ($entry in @(
            Get-ChildItem -LiteralPath $current.directory -Force -ErrorAction Stop
        )) {
            $entryPath = Get-I0CanonicalPath -Path $entry.FullName
            Assert-I0PathWithin `
                -Path $entryPath `
                -Root $worktreePath `
                -Label "I1 source worktree entry"
            $relative = (
                Get-I0RelativePath -Path $entryPath -Root $worktreePath
            ).Replace('\', '/')
            Assert-I1PruneRelativePath `
                -Path $relative `
                -Label "I1 source worktree relative path"
            $roundTrip = Get-I0CanonicalPath -Path (
                Join-Path $worktreePath $relative.Replace('/', '\')
            )
            if (-not [string]::Equals(
                $entryPath,
                $roundTrip,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                throw "Source path changes after Windows path normalization: $relative"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse points are forbidden in I1 source worktrees: $entryPath"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
                throw "Device entries are forbidden in I1 source worktrees: $entryPath"
            }
            $isDirectory = (
                ($entry.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0
            )
            Assert-I1PruneNoAlternateDataStreams `
                -Path $entryPath `
                -IsDirectory $isDirectory

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
            if ($isRootGit -and $isDirectory) {
                throw "A real .git directory is forbidden in an archived I1 worktree: $entryPath"
            }
            if ($isGodotCacheRoot -and -not $isDirectory) {
                throw "The excluded Godot .godot cache root must be a directory: $entryPath"
            }

            $exclusion = [string]$current.exclusion
            if ($isRootGit) {
                $exclusion = "git_pointer"
            }
            elseif ($isGodotCacheRoot) {
                $exclusion = "godot_cache"
            }

            if ($isDirectory) {
                if ($directoriesByPath.ContainsKey($relative)) {
                    throw "Duplicate case-insensitive directory path: $relative"
                }
                $directoriesByPath[$relative] = [pscustomobject][ordered]@{
                    exclusion = $exclusion
                    record = Get-I1PruneDirectoryRecord `
                        -Item $entry `
                        -RelativePath $relative
                }
                $pending.Push([pscustomobject]@{
                    directory = $entryPath
                    exclusion = $exclusion
                })
                continue
            }

            $record = Get-I1PruneStableFileRecord `
                -Path $entryPath `
                -RelativePath $relative `
                -WorkspaceRoot $WorkspaceRoot `
                -AllowedRoot $worktreePath `
                -Label "I1 source worktree file"
            if ($exclusion -ceq "git_pointer") {
                $gitPointerTarget = Assert-I1PruneGitPointer `
                    -Path $entryPath `
                    -Worktree $worktreePath `
                    -GitCommon $GitCommon `
                    -WorkspaceRoot $WorkspaceRoot
            }
            if ([string]::IsNullOrEmpty($exclusion)) {
                if ($includedByPath.ContainsKey($relative)) {
                    throw "Duplicate case-insensitive included file path: $relative"
                }
                $includedByPath[$relative] = $record
            }
            else {
                if ($excludedByPath.ContainsKey($relative)) {
                    throw "Duplicate case-insensitive excluded file path: $relative"
                }
                $excludedByPath[$relative] = [pscustomobject][ordered]@{
                    exclusion = $exclusion
                    record = $record
                }
            }
        }
    }

    [string[]]$includedPaths = @(
        $includedByPath.Keys | ForEach-Object { [string]$_ }
    )
    [System.Array]::Sort($includedPaths, [System.StringComparer]::Ordinal)
    $included = New-Object System.Collections.Generic.List[object]
    foreach ($path in $includedPaths) {
        [void]$included.Add($includedByPath[$path])
    }

    [string[]]$excludedPaths = @(
        $excludedByPath.Keys | ForEach-Object { [string]$_ }
    )
    [System.Array]::Sort($excludedPaths, [System.StringComparer]::Ordinal)
    $excluded = New-Object System.Collections.Generic.List[object]
    foreach ($path in $excludedPaths) {
        [void]$excluded.Add($excludedByPath[$path].record)
    }

    [string[]]$directoryPaths = @(
        $directoriesByPath.Keys | ForEach-Object { [string]$_ }
    )
    [System.Array]::Sort($directoryPaths, [System.StringComparer]::Ordinal)
    $directories = New-Object System.Collections.Generic.List[object]
    foreach ($path in $directoryPaths) {
        [void]$directories.Add($directoriesByPath[$path].record)
    }

    $exclusionSummaries = New-Object System.Collections.Generic.List[object]
    foreach ($definition in @(
        [pscustomobject]@{
            key = "git_pointer"
            path = ".git"
            entry_type = "gitdir_pointer_file"
        },
        [pscustomobject]@{
            key = "godot_cache"
            path = "Godot/GraytailGodot/.godot"
            entry_type = "regenerable_cache_directory"
        }
    )) {
        $files = @(
            $excludedByPath.Values |
                Where-Object { [string]$_.exclusion -ceq [string]$definition.key } |
                ForEach-Object { $_.record } |
                Sort-Object -Property path
        )
        $dirs = @(
            $directoriesByPath.Values |
                Where-Object { [string]$_.exclusion -ceq [string]$definition.key } |
                ForEach-Object { $_.record } |
                Sort-Object -Property path
        )
        [int64]$bytes = 0
        foreach ($file in $files) {
            $bytes += [int64]$file.length
        }
        [void]$exclusionSummaries.Add([pscustomobject][ordered]@{
            path = [string]$definition.path
            entry_type = [string]$definition.entry_type
            present = ($files.Count -gt 0 -or $dirs.Count -gt 0)
            file_count = $files.Count
            directory_count = $dirs.Count
            logical_bytes = $bytes
            file_type_summary = @(
                Get-I1PruneFileTypeSummary -Records $files
            )
            file_record_set_sha256 = Get-I1PruneRecordSetSha256 `
                -Records $files `
                -Properties @("path", "sha256", "length", "mtime_utc", "attributes")
            directory_record_set_sha256 = Get-I1PruneRecordSetSha256 `
                -Records $dirs `
                -Properties @("path", "mtime_utc", "attributes")
            gitdir_target = if ([string]$definition.key -ceq "git_pointer") {
                $gitPointerTarget
            }
            else {
                $null
            }
        })
    }

    [int64]$includedBytes = 0
    foreach ($record in $included) {
        $includedBytes += [int64]$record.length
    }
    [int64]$excludedBytes = 0
    foreach ($record in $excluded) {
        $excludedBytes += [int64]$record.length
    }

    return [pscustomobject][ordered]@{
        included_records = $included.ToArray()
        excluded_file_records = $excluded.ToArray()
        directory_records = $directories.ToArray()
        included_file_count = $included.Count
        included_logical_bytes = $includedBytes
        excluded_file_count = $excluded.Count
        excluded_logical_bytes = $excludedBytes
        directory_count = $directories.Count
        exclusions = $exclusionSummaries.ToArray()
    }
}


function Assert-I1PruneInventoryEqual {
    param(
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)]$Actual,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I1PruneRecordSetEqual `
        -Expected @($Expected.included_records) `
        -Actual @($Actual.included_records) `
        -Properties @("path", "sha256", "length", "mtime_utc", "attributes") `
        -Label "$Label included files"
    Assert-I1PruneRecordSetEqual `
        -Expected @($Expected.excluded_file_records) `
        -Actual @($Actual.excluded_file_records) `
        -Properties @("path", "sha256", "length", "mtime_utc", "attributes") `
        -Label "$Label excluded files"
    Assert-I1PruneRecordSetEqual `
        -Expected @($Expected.directory_records) `
        -Actual @($Actual.directory_records) `
        -Properties @("path", "mtime_utc", "attributes") `
        -Label "$Label directories"
}


function Assert-I1PruneInventoryMetadataStable {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)]$ExpectedInventory,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $rootPath = Get-I0CanonicalPath -Path $Root
    Assert-I1PruneRegularDirectory `
        -Path $rootPath `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $rootPath `
        -AllowRoot `
        -Label $Label

    $expectedFiles = @{}
    foreach ($record in @(
        @($ExpectedInventory.included_records) +
        @($ExpectedInventory.excluded_file_records)
    )) {
        $relative = [string]$record.path
        if ($expectedFiles.ContainsKey($relative)) {
            throw "Duplicate expected file path in ${Label}: $relative"
        }
        $expectedFiles[$relative] = $record
    }
    $expectedDirectories = @{}
    foreach ($record in @($ExpectedInventory.directory_records)) {
        $relative = [string]$record.path
        if ($expectedDirectories.ContainsKey($relative)) {
            throw "Duplicate expected directory path in ${Label}: $relative"
        }
        $expectedDirectories[$relative] = $record
    }

    $seenFiles = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $seenDirectories = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $pending = New-Object System.Collections.Stack
    $pending.Push($rootPath)
    while ($pending.Count -gt 0) {
        $directory = [string]$pending.Pop()
        foreach ($entry in @(
            Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop
        )) {
            $entryPath = Get-I0CanonicalPath -Path $entry.FullName
            Assert-I0PathWithin `
                -Path $entryPath `
                -Root $rootPath `
                -Label "$Label entry"
            $relative = (
                Get-I0RelativePath -Path $entryPath -Root $rootPath
            ).Replace('\', '/')
            Assert-I1PruneRelativePath `
                -Path $relative `
                -Label "$Label relative path"
            $roundTrip = Get-I0CanonicalPath -Path (
                Join-Path $rootPath $relative.Replace('/', '\')
            )
            if (-not [string]::Equals(
                $entryPath,
                $roundTrip,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                throw "$Label path changes after Windows normalization: $relative"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Label contains a reparse point: $entryPath"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
                throw "$Label contains a device entry: $entryPath"
            }
            $isDirectory = (
                ($entry.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0
            )
            Assert-I1PruneNoAlternateDataStreams `
                -Path $entryPath `
                -IsDirectory $isDirectory

            if ($isDirectory) {
                if (-not $expectedDirectories.ContainsKey($relative) -or
                    -not $seenDirectories.Add($relative)) {
                    throw "$Label contains an unexpected directory: $relative"
                }
                $expected = $expectedDirectories[$relative]
                if ([int64]$entry.LastWriteTimeUtc.Ticks -ne
                    [datetime]::ParseExact(
                        [string]$expected.mtime_utc,
                        "o",
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::RoundtripKind
                    ).Ticks -or
                    [int64]$entry.Attributes -ne [int64]$expected.attributes) {
                    throw "$Label directory metadata changed: $relative"
                }
                $pending.Push($entryPath)
                continue
            }

            if (-not $expectedFiles.ContainsKey($relative) -or
                -not $seenFiles.Add($relative)) {
                throw "$Label contains an unexpected file: $relative"
            }
            $expected = $expectedFiles[$relative]
            if ([int64]$entry.Length -ne [int64]$expected.length -or
                [int64]$entry.LastWriteTimeUtc.Ticks -ne
                [datetime]::ParseExact(
                    [string]$expected.mtime_utc,
                    "o",
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::RoundtripKind
                ).Ticks -or
                [int64]$entry.Attributes -ne [int64]$expected.attributes) {
                throw "$Label file metadata changed: $relative"
            }
        }
    }
    if ($seenFiles.Count -ne $expectedFiles.Count -or
        $seenDirectories.Count -ne $expectedDirectories.Count) {
        throw "$Label is missing inventoried files or directories"
    }
}


function Open-I1PruneTombstoneFileLocks {
    param(
        [Parameter(Mandatory = $true)][string]$Tombstone,
        [Parameter(Mandatory = $true)]$ExpectedInventory,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$GitCommon
    )

    $tombstonePath = Get-I0CanonicalPath -Path $Tombstone
    $expectedByPath = @{}
    foreach ($record in @(
        @($ExpectedInventory.included_records) +
        @($ExpectedInventory.excluded_file_records)
    )) {
        $relative = [string]$record.path
        if ($expectedByPath.ContainsKey($relative)) {
            throw "Duplicate expected tombstone file path: $relative"
        }
        $expectedByPath[$relative] = $record
    }
    [string[]]$relativePaths = @(
        $expectedByPath.Keys | ForEach-Object { [string]$_ }
    )
    [System.Array]::Sort($relativePaths, [System.StringComparer]::Ordinal)
    $streams = New-Object "System.Collections.Generic.List[System.IO.FileStream]"
    $lockRecords = New-Object System.Collections.Generic.List[object]
    $share = [System.IO.FileShare](
        [System.IO.FileShare]::Read -bor [System.IO.FileShare]::Delete
    )
    try {
        foreach ($relative in $relativePaths) {
            $expected = $expectedByPath[$relative]
            $filePath = Resolve-I1PruneRelativeFile `
                -Root $tombstonePath `
                -RelativePath $relative `
                -Label "tombstone file lock path"
            Assert-I1PruneRegularFile `
                -Path $filePath `
                -WorkspaceRoot $WorkspaceRoot `
                -AllowedRoot $tombstonePath `
                -Label "tombstone file"
            $before = Get-Item -LiteralPath $filePath -Force
            if ([int64]$before.Length -ne [int64]$expected.length -or
                [int64]$before.LastWriteTimeUtc.Ticks -ne
                [datetime]::ParseExact(
                    [string]$expected.mtime_utc,
                    "o",
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::RoundtripKind
                ).Ticks -or
                [int64]$before.Attributes -ne [int64]$expected.attributes) {
                throw "Tombstone file metadata differs from the preflight inventory: $relative"
            }
            try {
                $stream = [System.IO.File]::Open(
                    $filePath,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    $share
                )
            }
            catch {
                throw "Unable to lock tombstone file against content writes: $filePath error=$($_.Exception.Message)"
            }
            [void]$streams.Add($stream)
            if (-not $stream.CanRead -or
                $stream.SafeFileHandle.IsClosed -or
                [int64]$stream.Length -ne [int64]$expected.length) {
                throw "Tombstone file lock is invalid: $filePath"
            }
            $actualSha256 = Get-I1PruneStreamSha256 -Stream $stream
            $after = Get-Item -LiteralPath $filePath -Force
            if ([int64]$after.Length -ne [int64]$before.Length -or
                [int64]$after.LastWriteTimeUtc.Ticks -ne
                [int64]$before.LastWriteTimeUtc.Ticks -or
                [int64]$after.Attributes -ne [int64]$before.Attributes) {
                throw "Tombstone file changed while its write-denying lock was established: $relative"
            }
            Assert-I1PruneNoAlternateDataStreams `
                -Path $filePath `
                -IsDirectory $false
            if ($actualSha256 -cne [string]$expected.sha256) {
                throw "Tombstone file content differs from the archived preflight inventory: $relative"
            }
            if ($relative -ceq ".git") {
                [void](Assert-I1PruneGitPointer `
                    -Path $filePath `
                    -Worktree $tombstonePath `
                    -GitCommon $GitCommon `
                    -WorkspaceRoot $WorkspaceRoot)
            }
            [void]$lockRecords.Add([pscustomobject][ordered]@{
                path = $filePath
                relative_path = $relative
                sha256 = [string]$expected.sha256
                length = [int64]$expected.length
                mtime_utc = [string]$expected.mtime_utc
                attributes = [int64]$expected.attributes
                stream = $stream
            })
        }
        return [pscustomobject][ordered]@{
            streams = $streams
            records = $lockRecords.ToArray()
            file_count = $streams.Count
            file_access = "Read"
            file_share = "Read|Delete"
            content_sha256_verified_from_held_streams = $true
        }
    }
    catch {
        for ($index = $streams.Count - 1; $index -ge 0; $index--) {
            try {
                $streams[$index].Dispose()
            }
            catch {
            }
        }
        throw
    }
}


function Close-I1PruneTombstoneFileLocks {
    param([AllowNull()]$LockResult)

    if ($null -eq $LockResult) {
        return
    }
    for ($index = $LockResult.streams.Count - 1; $index -ge 0; $index--) {
        try {
            $LockResult.streams[$index].Dispose()
        }
        catch {
        }
    }
}


function Assert-I1PruneLockedTombstoneStructure {
    param(
        [Parameter(Mandatory = $true)][string]$Tombstone,
        [Parameter(Mandatory = $true)]$ExpectedInventory,
        [Parameter(Mandatory = $true)]$LockResult,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $tombstonePath = Get-I0CanonicalPath -Path $Tombstone
    $expectedFiles = @{}
    foreach ($record in @(
        @($ExpectedInventory.included_records) +
        @($ExpectedInventory.excluded_file_records)
    )) {
        $expectedFiles[[string]$record.path] = $record
    }
    if ($LockResult.file_count -ne $expectedFiles.Count) {
        throw "Not every expected tombstone file has a held write-denying lock"
    }
    foreach ($lockRecord in @($LockResult.records)) {
        if ($lockRecord.stream -isnot [System.IO.FileStream] -or
            -not $lockRecord.stream.CanRead -or
            $lockRecord.stream.SafeFileHandle.IsClosed -or
            [int64]$lockRecord.stream.Length -ne [int64]$lockRecord.length) {
            throw "A tombstone file lock became invalid: $($lockRecord.relative_path)"
        }
    }

    Assert-I1PruneInventoryMetadataStable `
        -Root $tombstonePath `
        -ExpectedInventory $ExpectedInventory `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "locked tombstone"
}


function Assert-I1PruneIncludedMatchesManifest {
    param(
        [Parameter(Mandatory = $true)][object[]]$ManifestRecords,
        [Parameter(Mandatory = $true)]$Inventory,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I1PruneRecordSetEqual `
        -Expected $ManifestRecords `
        -Actual @($Inventory.included_records) `
        -Properties @("path", "sha256", "length", "mtime_utc", "attributes") `
        -Label $Label
}


function Get-I1PruneManifestBinding {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)]$IndexEntry,
        [Parameter(Mandatory = $true)][string]$ExpectedNamespace,
        [Parameter(Mandatory = $true)][string]$ExpectedRunId
    )

    $expectedRelative = "snapshots/$ExpectedNamespace/$ExpectedRunId/manifest.json"
    if ($IndexEntry.manifest_path -isnot [string] -or
        [string]$IndexEntry.manifest_path -cne $expectedRelative) {
        throw "Index manifest path is not canonical: $ExpectedNamespace/$ExpectedRunId"
    }
    if ($IndexEntry.manifest_sha256 -isnot [string] -or
        [string]$IndexEntry.manifest_sha256 -notmatch '^[0-9A-F]{64}$') {
        throw "Index manifest SHA-256 is invalid: $ExpectedNamespace/$ExpectedRunId"
    }
    $manifestPath = Resolve-I1PruneRelativeFile `
        -Root $ArchiveRoot `
        -RelativePath $expectedRelative `
        -Label "archive manifest"
    $manifestShaPath = Get-I0CanonicalPath -Path (
        Join-Path (Split-Path -Parent $manifestPath) "manifest.sha256"
    )
    Assert-I1PruneRegularFile `
        -Path $manifestPath `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $ArchiveRoot `
        -Label "archive manifest"
    Assert-I1PruneRegularFile `
        -Path $manifestShaPath `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $ArchiveRoot `
        -Label "archive manifest sidecar"
    $document = Read-I1PruneStrictJsonFile `
        -Path $manifestPath `
        -Label "archive manifest"
    if ($document.sha256 -cne [string]$IndexEntry.manifest_sha256) {
        throw "Archive manifest does not match its index SHA-256: $ExpectedNamespace/$ExpectedRunId"
    }
    $sidecarBytes = Assert-I1PruneShaSidecar `
        -Path $manifestShaPath `
        -ExpectedSha256 $document.sha256 `
        -ExpectedFileName "manifest.json" `
        -Label "archive manifest sidecar"

    $manifest = $document.value
    foreach ($property in @(
        "schema_version",
        "namespace",
        "run_id",
        "runs_root",
        "worktree",
        "selected_git_worktree",
        "git_common_workspace",
        "exclusions",
        "report",
        "evidence",
        "files"
    )) {
        Assert-I1PruneJsonProperty `
            -Object $manifest `
            -Name $property `
            -Label "archive manifest"
    }
    $schemaVersion = ConvertTo-I1PruneInt64 `
        -Value $manifest.schema_version `
        -Label "archive manifest schema_version" `
        -Minimum 1 `
        -Maximum 1
    if ($schemaVersion -ne 1 -or
        [string]$manifest.namespace -cne $ExpectedNamespace -or
        [string]$manifest.run_id -cne $ExpectedRunId) {
        throw "Archive manifest identity mismatch: $ExpectedNamespace/$ExpectedRunId"
    }
    if ($manifest.files -isnot [array] -or $manifest.evidence -isnot [array]) {
        throw "Archive manifest files and evidence must be arrays: $ExpectedNamespace/$ExpectedRunId"
    }
    $files = @($manifest.files)
    $seenPaths = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $filePathSet = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $previousPath = $null
    [int64]$logicalBytes = 0
    $uniqueObjects = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::Ordinal
    )
    $objectLengthBySha = @{}
    foreach ($record in $files) {
        Assert-I1PruneManifestFileRecord `
            -Record $record `
            -Label "archive manifest file record"
        $path = [string]$record.path
        if (-not $seenPaths.Add($path)) {
            throw "Duplicate case-insensitive manifest file path: $path"
        }
        if ($null -ne $previousPath -and
            [System.StringComparer]::Ordinal.Compare(
                [string]$previousPath,
                $path
            ) -ge 0) {
            throw "Manifest file paths are not in strict ordinal order: $path"
        }
        $previousPath = $path
        [void]$filePathSet.Add($path)
        $recordSha256 = [string]$record.sha256
        $recordLength = [int64]$record.length
        if ($objectLengthBySha.ContainsKey($recordSha256) -and
            [int64]$objectLengthBySha[$recordSha256] -ne $recordLength) {
            throw "Manifest uses one SHA-256 with different lengths: $recordSha256"
        }
        $objectLengthBySha[$recordSha256] = $recordLength
        [void]$uniqueObjects.Add($recordSha256)
        $logicalBytes += $recordLength
    }
    foreach ($record in $files) {
        $segments = @(([string]$record.path).Split('/'))
        $prefix = ""
        for ($index = 0; $index -lt ($segments.Count - 1); $index++) {
            $prefix = if ($index -eq 0) {
                [string]$segments[$index]
            }
            else {
                "$prefix/$($segments[$index])"
            }
            if ($filePathSet.Contains($prefix)) {
                throw "Manifest file path is also used as a parent directory: $prefix"
            }
        }
    }
    $exclusions = @($manifest.exclusions)
    if ($exclusions.Count -ne 2 -or
        [string]$exclusions[0] -cne ".git" -or
        [string]$exclusions[1] -cne "Godot/GraytailGodot/.godot") {
        throw "Archive manifest exclusions do not match the approved exclusion set"
    }
    $indexFileCount = ConvertTo-I1PruneInt64 `
        -Value $IndexEntry.file_count `
        -Label "archive index file_count"
    $indexLogicalBytes = ConvertTo-I1PruneInt64 `
        -Value $IndexEntry.logical_bytes `
        -Label "archive index logical_bytes"
    if ($indexFileCount -ne $files.Count -or
        $indexLogicalBytes -ne $logicalBytes) {
        throw "Archive index inventory does not match its manifest: $ExpectedNamespace/$ExpectedRunId"
    }
    $report = Get-I1PrunePropertyValue -Object $manifest -Name "report"
    if ($null -eq $report) {
        if ($null -ne $IndexEntry.report_sha256) {
            throw "Archive index binds a report SHA for a manifest without a report"
        }
    }
    else {
        Assert-I1PruneManifestFileRecord `
            -Record $report `
            -Label "archive manifest report record"
        if ([string]$report.path -cne "report.json" -or
            $IndexEntry.report_sha256 -isnot [string] -or
            [string]$IndexEntry.report_sha256 -cne [string]$report.sha256) {
            throw "Archive index report binding does not match its manifest"
        }
    }
    return [pscustomobject][ordered]@{
        path = $manifestPath
        sidecar_path = $manifestShaPath
        bytes = $document.bytes
        sidecar_bytes = $sidecarBytes
        sha256 = $document.sha256
        manifest = $manifest
        files = $files
        file_count = $files.Count
        logical_bytes = $logicalBytes
        unique_object_count = $uniqueObjects.Count
    }
}


function Get-I1PruneRetainedEvidenceState {
    param(
        [Parameter(Mandatory = $true)]$Manifest,
        [Parameter(Mandatory = $true)][string]$RunRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $expectedByPath = @{}
    $recordsToRegister = New-Object System.Collections.Generic.List[object]
    $report = Get-I1PrunePropertyValue -Object $Manifest -Name "report"
    if ($null -ne $report) {
        Assert-I1PruneManifestFileRecord -Record $report -Label "manifest report record"
        if ([string]$report.path -cne "report.json") {
            throw "Manifest report path is not canonical: $($report.path)"
        }
        [void]$recordsToRegister.Add($report)
    }
    foreach ($evidence in @($Manifest.evidence)) {
        Assert-I1PruneManifestFileRecord `
            -Record $evidence `
            -Label "manifest evidence record"
        [void]$recordsToRegister.Add($evidence)
    }

    foreach ($record in $recordsToRegister) {
        $path = [string]$record.path
        if ($expectedByPath.ContainsKey($path)) {
            foreach ($property in @("sha256", "length", "mtime_utc", "attributes")) {
                if ([string]$expectedByPath[$path].$property -cne
                    [string]$record.$property) {
                    throw "Retained evidence has conflicting manifest records: $path"
                }
            }
            continue
        }
        $expectedByPath[$path] = $record
    }

    [string[]]$paths = @($expectedByPath.Keys | ForEach-Object { [string]$_ })
    [System.Array]::Sort($paths, [System.StringComparer]::Ordinal)
    $actual = New-Object System.Collections.Generic.List[object]
    foreach ($path in $paths) {
        $filePath = Resolve-I1PruneRelativeFile `
            -Root $RunRoot `
            -RelativePath $path `
            -Label "retained run evidence"
        $record = Get-I1PruneStableFileRecord `
            -Path $filePath `
            -RelativePath $path `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $RunRoot `
            -Label "retained run evidence"
        Assert-I1PruneRecordSetEqual `
            -Expected @($expectedByPath[$path]) `
            -Actual @($record) `
            -Properties @("path", "sha256", "length", "mtime_utc", "attributes") `
            -Label "retained run evidence"
        [void]$actual.Add($record)
    }
    [int64]$logicalBytes = 0
    foreach ($record in $actual) {
        $logicalBytes += [int64]$record.length
    }
    return [pscustomobject][ordered]@{
        records = $actual.ToArray()
        file_count = $actual.Count
        logical_bytes = $logicalBytes
        record_set_sha256 = Get-I1PruneRecordSetSha256 `
            -Records $actual.ToArray() `
            -Properties @("path", "sha256", "length", "mtime_utc", "attributes")
    }
}


function Assert-I1PruneRetainedEvidenceEqual {
    param(
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)]$Actual
    )

    Assert-I1PruneRecordSetEqual `
        -Expected @($Expected.records) `
        -Actual @($Actual.records) `
        -Properties @("path", "sha256", "length", "mtime_utc", "attributes") `
        -Label "retained report/evidence"
}


function Assert-I1PruneNoProcessReference {
    param([Parameter(Mandatory = $true)][string]$Worktree)

    $needle = $Worktree.Replace('\', '/')
    foreach ($process in @(Get-CimInstance Win32_Process)) {
        if ([int]$process.ProcessId -eq $PID -or
            [string]::IsNullOrWhiteSpace([string]$process.CommandLine)) {
            continue
        }
        $commandLine = ([string]$process.CommandLine).Replace('\', '/')
        if ($commandLine.IndexOf(
            $needle,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -ge 0) {
            throw "A process still references the worktree. pid=$($process.ProcessId) path=$Worktree"
        }
    }
}


function Assert-I1PruneCasRecordsStable {
    param(
        [Parameter(Mandatory = $true)][string]$ObjectsRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$ExpectedRecords
    )

    Assert-I1PruneTreeSafety `
        -Root $ObjectsRoot `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive CAS root"
    $expectedByPath = @{}
    foreach ($record in $ExpectedRecords) {
        $recordPath = Get-I0CanonicalPath -Path ([string]$record.path)
        if ($expectedByPath.ContainsKey($recordPath)) {
            throw "Duplicate expected CAS path in stability records: $recordPath"
        }
        $expectedByPath[$recordPath] = $record
    }

    $seen = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($objectFile in @(
        Get-ChildItem -LiteralPath $ObjectsRoot -Recurse -Force -File
    )) {
        $objectPath = Get-I0CanonicalPath -Path $objectFile.FullName
        Assert-I1PruneRegularFile `
            -Path $objectPath `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $ArchiveRoot `
            -Label "archive CAS object"
        if (-not $expectedByPath.ContainsKey($objectPath)) {
            throw "Archive CAS gained an object after content verification: $objectPath"
        }
        if (-not $seen.Add($objectPath)) {
            throw "Archive CAS contains a duplicate case-insensitive path: $objectPath"
        }
        $expected = $expectedByPath[$objectPath]
        $current = Get-Item -LiteralPath $objectPath -Force
        if ([int64]$current.Length -ne [int64]$expected.length -or
            [int64]$current.LastWriteTimeUtc.Ticks -ne [int64]$expected.mtime_utc_ticks -or
            [int64]$current.Attributes -ne [int64]$expected.attributes) {
            throw "Archive CAS object metadata changed after content verification: $objectPath"
        }
        $objectName = [string]$current.Name
        if ($objectName -notmatch '^[0-9a-f]{64}$' -or
            $objectName.ToUpperInvariant() -cne [string]$expected.sha256) {
            throw "Archive CAS object filename no longer matches its stable SHA binding: $objectPath"
        }
        $expectedObjectPath = Get-I0CanonicalPath -Path (
            Join-Path $ObjectsRoot (
                "{0}\{1}\{2}" -f
                ([string]$expected.sha256).Substring(0, 2).ToLowerInvariant(),
                ([string]$expected.sha256).Substring(2, 2).ToLowerInvariant(),
                ([string]$expected.sha256).ToLowerInvariant()
            )
        )
        if (-not [string]::Equals(
            $objectPath,
            $expectedObjectPath,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Archive CAS object moved from its canonical path: $objectPath"
        }
    }
    if ($seen.Count -ne $ExpectedRecords.Count) {
        throw "Archive CAS object set changed after content verification"
    }
    foreach ($record in $ExpectedRecords) {
        if (-not $seen.Contains((Get-I0CanonicalPath -Path ([string]$record.path)))) {
            throw "Archive CAS object disappeared after content verification: $($record.path)"
        }
    }
}


function Assert-I1PruneCasContentHashes {
    param(
        [Parameter(Mandatory = $true)][string]$ObjectsRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$ExpectedRecords
    )

    Assert-I1PruneCasRecordsStable `
        -ObjectsRoot $ObjectsRoot `
        -WorkspaceRoot $WorkspaceRoot `
        -ArchiveRoot $ArchiveRoot `
        -ExpectedRecords $ExpectedRecords
    foreach ($record in $ExpectedRecords) {
        $objectPath = Get-I0CanonicalPath -Path ([string]$record.path)
        Assert-I1PruneRegularFile `
            -Path $objectPath `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $ArchiveRoot `
            -Label "archive CAS object"
        $before = Get-Item -LiteralPath $objectPath -Force
        if ([int64]$before.Length -ne [int64]$record.length -or
            [int64]$before.LastWriteTimeUtc.Ticks -ne [int64]$record.mtime_utc_ticks -or
            [int64]$before.Attributes -ne [int64]$record.attributes) {
            throw "Archive CAS object changed before SHA-256 verification: $objectPath"
        }
        $lockStream = Get-I1PrunePropertyValue -Object $record -Name "lock_stream"
        if ($null -eq $lockStream -or $lockStream -isnot [System.IO.FileStream]) {
            throw "Archive CAS object has no held read lock: $objectPath"
        }
        if (-not $lockStream.CanRead -or $lockStream.SafeFileHandle.IsClosed) {
            throw "Archive CAS object read lock is no longer valid: $objectPath"
        }
        if ([int64]$lockStream.Length -ne [int64]$record.length) {
            throw "Archive CAS object lock length changed: $objectPath"
        }
        $actualSha256 = Get-I1PruneStreamSha256 -Stream $lockStream
        $after = Get-Item -LiteralPath $objectPath -Force
        if ([int64]$after.Length -ne [int64]$record.length -or
            [int64]$after.LastWriteTimeUtc.Ticks -ne [int64]$record.mtime_utc_ticks -or
            [int64]$after.Attributes -ne [int64]$record.attributes) {
            throw "Archive CAS object changed during SHA-256 verification: $objectPath"
        }
        Assert-I1PruneNoAlternateDataStreams -Path $objectPath -IsDirectory $false
        if ($actualSha256 -cne [string]$record.sha256) {
            throw "Archive CAS object content SHA-256 does not match its filename: $objectPath"
        }
    }
    Assert-I1PruneCasRecordsStable `
        -ObjectsRoot $ObjectsRoot `
        -WorkspaceRoot $WorkspaceRoot `
        -ArchiveRoot $ArchiveRoot `
        -ExpectedRecords $ExpectedRecords
}


function Assert-I1PruneRestoreProof {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Namespace,
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$ManifestSha256,
        [Parameter(Mandatory = $true)][string]$ExpectedProofSha256,
        [Parameter(Mandatory = $true)][string]$ExpectedIndexSha256,
        [Parameter(Mandatory = $true)][string]$ExpectedRestoreToolSha256,
        [Parameter(Mandatory = $true)][bool]$ApplyRequested,
        [Parameter(Mandatory = $true)]$ManifestBinding
    )

    $proofRoot = Get-I0CanonicalPath -Path (
        Join-Path $ArchiveRoot "restore_proofs\$Namespace\$RunId"
    )
    Assert-I0PathWithin -Path $proofRoot -Root $ArchiveRoot -Label "restore proof root"
    $proofStem = "{0}.{1}.{2}.v2" -f
        $ManifestSha256,
        $ExpectedIndexSha256,
        $ExpectedRestoreToolSha256
    $proofPath = Get-I0CanonicalPath -Path (
        Join-Path $proofRoot "$proofStem.json"
    )
    $proofShaPath = Get-I0CanonicalPath -Path (
        Join-Path $proofRoot "$proofStem.sha256"
    )
    Assert-I1PruneRegularFile `
        -Path $proofPath `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $ArchiveRoot `
        -Label "representative restore proof"
    Assert-I1PruneRegularFile `
        -Path $proofShaPath `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $ArchiveRoot `
        -Label "representative restore proof sidecar"
    $document = Read-I1PruneStrictJsonFile `
        -Path $proofPath `
        -Label "representative restore proof"
    if ($document.sha256 -cne $ExpectedProofSha256) {
        throw "Representative restore proof does not match its explicit CLI proof SHA-256 pin: $Namespace/$RunId"
    }
    $proofShaBytes = Assert-I1PruneShaSidecar `
        -Path $proofShaPath `
        -ExpectedSha256 $document.sha256 `
        -ExpectedFileName "$proofStem.json" `
        -Label "representative restore proof sidecar"
    $proof = $document.value
    foreach ($property in @(
        "schema_version",
        "archive_root",
        "index_sha256",
        "index_sidecar",
        "namespace",
        "run_id",
        "manifest_sha256",
        "file_count",
        "logical_bytes",
        "unique_object_count",
        "tool_sha256",
        "tool_files",
        "environment",
        "restore_boundary",
        "verification"
    )) {
        Assert-I1PruneJsonProperty `
            -Object $proof `
            -Name $property `
            -Label "representative restore proof"
    }
    [void](ConvertTo-I1PruneInt64 `
        -Value $proof.schema_version `
        -Label "restore proof schema_version" `
        -Minimum 2 `
        -Maximum 2)
    if ([string]$proof.archive_root -cne $ArchiveRoot -or
        [string]$proof.index_sha256 -cne $ExpectedIndexSha256 -or
        [string]$proof.namespace -cne $Namespace -or
        [string]$proof.run_id -cne $RunId -or
        [string]$proof.manifest_sha256 -cne $ManifestSha256) {
        throw "Representative restore proof identity mismatch: $Namespace/$RunId"
    }
    if ((ConvertTo-I1PruneInt64 `
            -Value $proof.file_count `
            -Label "restore proof file_count") -ne
        [int64]$ManifestBinding.file_count -or
        (ConvertTo-I1PruneInt64 `
            -Value $proof.logical_bytes `
            -Label "restore proof logical_bytes") -ne
        [int64]$ManifestBinding.logical_bytes -or
        (ConvertTo-I1PruneInt64 `
            -Value $proof.unique_object_count `
            -Label "restore proof unique_object_count") -ne
        [int64]$ManifestBinding.unique_object_count) {
        throw "Representative restore proof inventory mismatch: $Namespace/$RunId"
    }
    $verification = $proof.verification
    foreach ($property in @(
        "real_apply_restore_completed",
        "archive_index_sidecar_sha256",
        "manifest_sidecar_sha256",
        "object_length_and_sha256",
        "tool_files_regular_no_reparse_no_ads",
        "copy_method",
        "hardlinks_used_for_restore",
        "restored_path_length_sha256_mtime_attributes",
        "restored_verification_passes",
        "verification_sequence",
        "restore_boundary_enforced"
    )) {
        Assert-I1PruneJsonProperty `
            -Object $verification `
            -Name $property `
            -Label "restore proof verification"
    }
    if ($verification.real_apply_restore_completed -isnot [bool] -or
        [bool]$verification.real_apply_restore_completed -ne $true -or
        $verification.archive_index_sidecar_sha256 -isnot [bool] -or
        [bool]$verification.archive_index_sidecar_sha256 -ne $true -or
        $verification.manifest_sidecar_sha256 -isnot [bool] -or
        [bool]$verification.manifest_sidecar_sha256 -ne $true -or
        $verification.object_length_and_sha256 -isnot [bool] -or
        [bool]$verification.object_length_and_sha256 -ne $true -or
        $verification.tool_files_regular_no_reparse_no_ads -isnot [bool] -or
        [bool]$verification.tool_files_regular_no_reparse_no_ads -ne $true -or
        [string]$verification.copy_method -cne "System.IO.File.Copy" -or
        $verification.hardlinks_used_for_restore -isnot [bool] -or
        [bool]$verification.hardlinks_used_for_restore -ne $false -or
        $verification.restored_path_length_sha256_mtime_attributes -isnot [bool] -or
        [bool]$verification.restored_path_length_sha256_mtime_attributes -ne $true -or
        (ConvertTo-I1PruneInt64 `
            -Value $verification.restored_verification_passes `
            -Label "restore proof restored_verification_passes") -ne 2 -or
        $verification.verification_sequence -isnot [array] -or
        @($verification.verification_sequence).Count -ne 2 -or
        [string]$verification.verification_sequence[0] -cne
        "isolated_staging_tree" -or
        [string]$verification.verification_sequence[1] -notin @(
            "isolated_staging_tree",
            "published_final_tree"
        ) -or
        $verification.restore_boundary_enforced -isnot [bool] -or
        [bool]$verification.restore_boundary_enforced -ne $true) {
        throw "Representative restore proof does not satisfy the deletion gate: $Namespace/$RunId"
    }

    $indexSidecar = $proof.index_sidecar
    foreach ($property in @("path", "sha256", "canonical_format_verified")) {
        Assert-I1PruneJsonProperty `
            -Object $indexSidecar `
            -Name $property `
            -Label "restore proof index_sidecar"
    }
    $indexSidecarPath = Get-I0CanonicalPath -Path (
        Join-Path $ArchiveRoot "index.sha256"
    )
    if ([string]$indexSidecar.path -cne "index.sha256" -or
        $indexSidecar.sha256 -isnot [string] -or
        [string]$indexSidecar.sha256 -notmatch '^[0-9A-F]{64}$' -or
        (Get-I1PruneFileSha256 -Path $indexSidecarPath) -cne
        [string]$indexSidecar.sha256 -or
        $indexSidecar.canonical_format_verified -isnot [bool] -or
        [bool]$indexSidecar.canonical_format_verified -ne $true) {
        throw "Representative restore proof index sidecar binding mismatch: $Namespace/$RunId"
    }

    $proofToolSha256 = $proof.tool_sha256
    $proofToolFiles = $proof.tool_files
    Assert-I1PruneJsonProperty `
        -Object $proofToolSha256 `
        -Name "restore" `
        -Label "restore proof tool_sha256"
    if ([string]$proofToolSha256.restore -cne $ExpectedRestoreToolSha256) {
        throw "Representative restore proof restore-tool binding mismatch: $Namespace/$RunId"
    }
    $repoRoot = Get-I0CanonicalPath -Path (Join-Path $PSScriptRoot "..\..")
    $toolBindings = @(
        [pscustomobject]@{
            name = "verifier"
            path = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "verify_i1_snapshot_archive.ps1"
            )
        },
        [pscustomobject]@{
            name = "archive"
            path = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "archive_i1_worktrees.ps1"
            )
        },
        [pscustomobject]@{
            name = "restore"
            path = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "restore_i1_worktree_archive.ps1"
            )
        },
        [pscustomobject]@{
            name = "i0_test_lib"
            path = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1"
            )
        }
    )
    foreach ($toolBinding in $toolBindings) {
        Assert-I1PruneJsonProperty `
            -Object $proofToolSha256 `
            -Name $toolBinding.name `
            -Label "restore proof tool_sha256"
        Assert-I1PruneJsonProperty `
            -Object $proofToolFiles `
            -Name $toolBinding.name `
            -Label "restore proof tool_files"
        Assert-I1PruneRegularFile `
            -Path $toolBinding.path `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $repoRoot `
            -Label "restore proof bound tool"
        $expectedToolSha256 = [string](
            Get-I1PrunePropertyValue `
                -Object $proofToolSha256 `
                -Name $toolBinding.name
        )
        $toolFile = Get-I1PrunePropertyValue `
            -Object $proofToolFiles `
            -Name $toolBinding.name
        foreach ($property in @("path", "length")) {
            Assert-I1PruneJsonProperty `
                -Object $toolFile `
                -Name $property `
                -Label "restore proof tool file"
        }
        $expectedRelativeToolPath = (
            Get-I0RelativePath -Path $toolBinding.path -Root $repoRoot
        ).Replace('\', '/')
        if ($expectedToolSha256 -notmatch '^[0-9A-F]{64}$' -or
            (Get-I1PruneFileSha256 -Path $toolBinding.path) -cne
            $expectedToolSha256 -or
            [string]$toolFile.path -cne $expectedRelativeToolPath -or
            (ConvertTo-I1PruneInt64 `
                -Value $toolFile.length `
                -Label "restore proof tool length") -ne
            [int64](Get-Item -LiteralPath $toolBinding.path -Force).Length) {
            throw "Representative restore proof tool binding mismatch: $($toolBinding.name)"
        }
    }

    $restoreBoundary = $proof.restore_boundary
    foreach ($property in @(
        "restore_root",
        "planned_restore_path",
        "isolated_restore_root",
        "restored_removed_after_verify"
    )) {
        Assert-I1PruneJsonProperty `
            -Object $restoreBoundary `
            -Name $property `
            -Label "restore proof restore_boundary"
    }
    $expectedRestoreRoot = Get-I0CanonicalPath -Path (
        Join-Path $WorkspaceRoot ".tmp\i1_snapshot_restore"
    )
    $proofRestoreRoot = Get-I0CanonicalPath -Path (
        [string]$restoreBoundary.restore_root
    )
    $proofPlannedRestorePath = Get-I0CanonicalPath -Path (
        [string]$restoreBoundary.planned_restore_path
    )
    $proofIsolatedRestoreRoot = Get-I0CanonicalPath -Path (
        [string]$restoreBoundary.isolated_restore_root
    )
    if (-not [string]::Equals(
        $proofRestoreRoot,
        $expectedRestoreRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    ) -or -not (Test-I0PathWithin `
        -Path $proofPlannedRestorePath `
        -Root $proofRestoreRoot) -or
        -not (Test-I0PathWithin `
            -Path $proofIsolatedRestoreRoot `
            -Root $proofRestoreRoot) -or
        $restoreBoundary.restored_removed_after_verify -isnot [bool]) {
        throw "Representative restore proof restore boundary mismatch: $Namespace/$RunId"
    }
    if ($proof.environment -is [array] -or $null -eq $proof.environment) {
        throw "Representative restore proof environment binding is invalid"
    }
    $applyEligible = $true
    $compatibility = "schema_v2_archive_index_tool_cli_proof_sha256_bound"

    $public = [pscustomobject][ordered]@{
        namespace = $Namespace
        run_id = $RunId
        manifest_sha256 = $ManifestSha256
        proof_path = $proofPath
        proof_sha256_path = $proofShaPath
        proof_sha256 = $document.sha256
        proof_sha256_cli_pinned = $true
        schema_version = 2
        archive_root_bound = $true
        index_sha256_bound = $true
        tool_sha256_bound = $true
        apply_eligible = $applyEligible
        compatibility = $compatibility
        verified = $true
    }
    return [pscustomobject][ordered]@{
        public = $public
        path = $proofPath
        bytes = $document.bytes
        sidecar_path = $proofShaPath
        sidecar_bytes = $proofShaBytes
        sha256 = $document.sha256
    }
}


function Write-I1PruneAtomicNewFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot
    )

    Assert-I0PathWithin -Path $Path -Root $ArchiveRoot -Label "prune transaction file"
    if (Test-Path -LiteralPath $Path) {
        throw "Prune transaction file already exists: $Path"
    }
    $directory = Get-I0CanonicalPath -Path (Split-Path -Parent $Path)
    Assert-I0PathWithin `
        -Path $directory `
        -Root $ArchiveRoot `
        -Label "prune transaction directory"
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "prune transaction directory"
    [void](New-Item -ItemType Directory -Path $directory -Force)
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "prune transaction directory"

    $temporaryPath = Get-I0CanonicalPath -Path (
        Join-Path $directory (
            ".{0}.tmp.{1}.{2}" -f
            [System.IO.Path]::GetFileName($Path),
            $PID,
            ([guid]::NewGuid().ToString("N"))
        )
    )
    Assert-I0PathWithin `
        -Path $temporaryPath `
        -Root $directory `
        -Label "prune transaction temporary file"
    try {
        [System.IO.File]::WriteAllBytes($temporaryPath, $Bytes)
        Assert-I1PruneRegularFile `
            -Path $temporaryPath `
            -WorkspaceRoot $WorkspaceRoot `
            -AllowedRoot $ArchiveRoot `
            -Label "prune transaction temporary file"
        [System.IO.File]::Move($temporaryPath, $Path)
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
    Assert-I1PruneRegularFile `
        -Path $Path `
        -WorkspaceRoot $WorkspaceRoot `
        -AllowedRoot $ArchiveRoot `
        -Label "prune transaction file"
    $actual = [System.IO.File]::ReadAllBytes($Path)
    if (-not (Test-I1PruneByteArrayEqual -Left $actual -Right $Bytes)) {
        throw "Prune transaction file changed during atomic publication: $Path"
    }
}


function Write-I1PruneTransactionStage {
    param(
        [Parameter(Mandatory = $true)]$Target,
        [Parameter(Mandatory = $true)][string]$Stage,
        [Parameter(Mandatory = $true)][int]$Sequence,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$IndexSha256,
        [Parameter(Mandatory = $true)][string]$GlobalProofSha256,
        [Parameter(Mandatory = $true)][string]$PrunerSha256,
        [AllowNull()]$PreviousReceipt
    )

    $fileStem = "{0:D2}-{1}" -f $Sequence, $Stage
    $receiptPath = Get-I0CanonicalPath -Path (
        Join-Path $Target.receipt_root "$fileStem.json"
    )
    $sidecarPath = Get-I0CanonicalPath -Path (
        Join-Path $Target.receipt_root "$fileStem.sha256"
    )
    $receipt = [pscustomobject][ordered]@{
        schema_version = 1
        transaction_id = "$($Target.namespace)/$($Target.run_id)/$($Target.manifest.sha256)"
        sequence = $Sequence
        stage = $Stage
        recorded_at_utc = [DateTime]::UtcNow.ToString(
            "yyyy-MM-ddTHH:mm:ss.fffffffZ",
            [System.Globalization.CultureInfo]::InvariantCulture
        )
        namespace = $Target.namespace
        run_id = $Target.run_id
        runs_root = $Target.runs_root
        run_root = $Target.run_root
        worktree = $Target.worktree
        tombstone = $Target.tombstone
        manifest_path = $Target.manifest.path
        manifest_sha256 = $Target.manifest.sha256
        archive_index_sha256 = $IndexSha256
        global_verification_proof_sha256 = $GlobalProofSha256
        representative_restore_proof = $Target.representative_restore_proof
        pruner_sha256 = $PrunerSha256
        archive_cas_gate = [pscustomobject][ordered]@{
            unique_object_count = $casUniqueObjectCount
            unique_object_bytes = $casUniqueObjectBytes
            every_object_content_sha256_matches_filename = $casContentSha256Verified
            held_stream_file_access = "Read"
            held_stream_file_share = "Read"
            held_stream_count = $casLockStreams.Count
            read_locks_held_until_finally = $casReadLocksHeldThroughPrune
        }
        tombstone_file_gate = [pscustomobject][ordered]@{
            runtime_guid_suffix = $Target.public.tombstone_runtime_guid_suffix
            held_stream_file_access = "Read"
            held_stream_file_share = $Target.public.tombstone_file_lock_share
            held_stream_count = $Target.public.tombstone_file_lock_count
            content_sha256_verified_from_held_streams = (
                $Target.public.tombstone_file_lock_count -eq
                ($Target.inventory.included_file_count +
                $Target.inventory.excluded_file_count)
            )
        }
        previous_receipt = if ($null -eq $PreviousReceipt) {
            $null
        }
        else {
            [pscustomobject][ordered]@{
                path = $PreviousReceipt.path
                sha256 = $PreviousReceipt.sha256
            }
        }
        source_inventory = [pscustomobject][ordered]@{
            included_file_count = $Target.inventory.included_file_count
            included_logical_bytes = $Target.inventory.included_logical_bytes
            included_record_set_sha256 = Get-I1PruneRecordSetSha256 `
                -Records @($Target.inventory.included_records) `
                -Properties @("path", "sha256", "length", "mtime_utc", "attributes")
            excluded_file_count = $Target.inventory.excluded_file_count
            excluded_logical_bytes = $Target.inventory.excluded_logical_bytes
            excluded_record_set_sha256 = Get-I1PruneRecordSetSha256 `
                -Records @($Target.inventory.excluded_file_records) `
                -Properties @("path", "sha256", "length", "mtime_utc", "attributes")
            directory_count = $Target.inventory.directory_count
            directory_record_set_sha256 = Get-I1PruneRecordSetSha256 `
                -Records @($Target.inventory.directory_records) `
                -Properties @("path", "mtime_utc", "attributes")
            exclusions = $Target.inventory.exclusions
        }
        retained_report_and_evidence = [pscustomobject][ordered]@{
            file_count = $Target.evidence.file_count
            logical_bytes = $Target.evidence.logical_bytes
            record_set_sha256 = $Target.evidence.record_set_sha256
        }
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $bytes = $encoding.GetBytes(($receipt | ConvertTo-Json -Depth 20 -Compress))
    $sha256 = Get-I1PruneBytesSha256 -Bytes $bytes
    $sidecarBytes = $encoding.GetBytes(
        "$sha256  $([System.IO.Path]::GetFileName($receiptPath))`n"
    )
    Write-I1PruneAtomicNewFile `
        -Path $receiptPath `
        -Bytes $bytes `
        -WorkspaceRoot $WorkspaceRoot `
        -ArchiveRoot $ArchiveRoot
    Write-I1PruneAtomicNewFile `
        -Path $sidecarPath `
        -Bytes $sidecarBytes `
        -WorkspaceRoot $WorkspaceRoot `
        -ArchiveRoot $ArchiveRoot
    if ((Get-I1PruneFileSha256 -Path $receiptPath) -cne $sha256) {
        throw "Prune transaction receipt SHA-256 verification failed: $receiptPath"
    }
    [void](Assert-I1PruneShaSidecar `
        -Path $sidecarPath `
        -ExpectedSha256 $sha256 `
        -ExpectedFileName ([System.IO.Path]::GetFileName($receiptPath)) `
        -Label "prune transaction receipt sidecar")
    return [pscustomobject][ordered]@{
        stage = $Stage
        path = $receiptPath
        sidecar_path = $sidecarPath
        sha256 = $sha256
    }
}


function Assert-I1PruneBoundFilesStable {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileStream]$IndexLock,
        [Parameter(Mandatory = $true)][byte[]]$IndexBytes,
        [Parameter(Mandatory = $true)][string]$IndexShaPath,
        [Parameter(Mandatory = $true)][byte[]]$IndexShaBytes,
        [Parameter(Mandatory = $true)][string]$GlobalProofPath,
        [Parameter(Mandatory = $true)][byte[]]$GlobalProofBytes,
        [Parameter(Mandatory = $true)][string]$GlobalProofShaPath,
        [Parameter(Mandatory = $true)][byte[]]$GlobalProofShaBytes,
        [Parameter(Mandatory = $true)][object[]]$ManifestBindings
    )

    $indexAfter = Read-I1PruneLockedStreamBytes -Stream $IndexLock
    if (-not (Test-I1PruneByteArrayEqual -Left $indexAfter -Right $IndexBytes)) {
        throw "Archive index changed while the prune lock was held"
    }
    if (-not (Test-I1PruneByteArrayEqual `
        -Left ([System.IO.File]::ReadAllBytes($IndexShaPath)) `
        -Right $IndexShaBytes)) {
        throw "Archive index sidecar changed while the prune lock was held"
    }
    if (-not (Test-I1PruneByteArrayEqual `
        -Left ([System.IO.File]::ReadAllBytes($GlobalProofPath)) `
        -Right $GlobalProofBytes)) {
        throw "Global archive verification proof changed during pruning"
    }
    if (-not (Test-I1PruneByteArrayEqual `
        -Left ([System.IO.File]::ReadAllBytes($GlobalProofShaPath)) `
        -Right $GlobalProofShaBytes)) {
        throw "Global archive verification proof sidecar changed during pruning"
    }
    foreach ($binding in $ManifestBindings) {
        if (-not (Test-I1PruneByteArrayEqual `
            -Left ([System.IO.File]::ReadAllBytes([string]$binding.path)) `
            -Right ([byte[]]$binding.bytes))) {
            throw "Archive manifest changed during pruning: $($binding.path)"
        }
        if (-not (Test-I1PruneByteArrayEqual `
            -Left ([System.IO.File]::ReadAllBytes([string]$binding.sidecar_path)) `
            -Right ([byte[]]$binding.sidecar_bytes))) {
            throw "Archive manifest sidecar changed during pruning: $($binding.sidecar_path)"
        }
    }
}


$mode = if ($Apply) { "apply" } else { "dry_run" }
$result = $null
$exitCode = 0
$archiveLockStream = $null
$mutationMayHaveOccurred = $false
$worktreeRemovalMayHaveStarted = $false
$worktreeRemovalPerformed = $false
$preflightCompleted = $false
$removedCount = 0
$targetPublicResults = New-Object System.Collections.Generic.List[object]
$targetStates = New-Object System.Collections.Generic.List[object]
$verifiedRestoreProofs = New-Object System.Collections.Generic.List[object]
$compatibilityNotes = New-Object System.Collections.Generic.List[string]
$casLockStreams = New-Object "System.Collections.Generic.List[System.IO.FileStream]"
$casStabilityRecords = New-Object System.Collections.Generic.List[object]
$casUniqueObjectCount = 0
$casUniqueObjectBytes = [int64]0
$casContentSha256Verified = $false
$casReadLocksHeldThroughPrune = $false
$casMetadataStabilityCheckCount = 0
$casPostBatchContentReverified = $false
$criticalReadLockStreams = New-Object "System.Collections.Generic.List[System.IO.FileStream]"
$criticalReadLockRecordByPath = @{}
$criticalReadLocksValidated = $false
$proofBoundToolRecords = New-Object System.Collections.Generic.List[object]
$proofBoundToolLocksHeld = $false
$prunerSelfLockHeld = $false
$restoreProofStabilityRecords = New-Object System.Collections.Generic.List[object]
$resolvedRepo = $null
$workspaceRoot = $null
$resolvedArchiveRoot = $null
$resolvedRunsRoot = $null
$indexPath = $null
$indexSha256 = $null
$globalProofPath = $null
$globalProofSha256 = $null
$globalProofRestoreToolSha256 = $null
$prunerPath = $null
$prunerInitialBytes = $null
$prunerInitialSha256 = $null
$lockAnchor = $null

try {
    if ($PSVersionTable.PSEdition -cne "Desktop" -or
        $PSVersionTable.PSVersion.Major -ne 5 -or
        $PSVersionTable.PSVersion.Minor -lt 1) {
        throw "I1 archived-worktree pruning requires Windows PowerShell 5.1 Desktop"
    }
    $ExpectedIndexSha256 = $ExpectedIndexSha256.ToUpperInvariant()
    $ExpectedGlobalProofSha256 = $ExpectedGlobalProofSha256.ToUpperInvariant()
    if ($ExpectedIndexSha256 -notmatch '^[0-9A-F]{64}$') {
        throw "ExpectedIndexSha256 must be an uppercase-normalizable SHA-256"
    }
    if ($ExpectedGlobalProofSha256 -notmatch '^[0-9A-F]{64}$') {
        throw "ExpectedGlobalProofSha256 must be an uppercase-normalizable SHA-256"
    }
    Assert-I1PruneLeafName -Value $Namespace -Label "Namespace"

    $repoCandidate = Get-I0CanonicalPath -Path (Join-Path $PSScriptRoot "..\..")
    $scriptRepoResult = Invoke-I0Git `
        -RepoRoot $repoCandidate `
        -Arguments @("rev-parse", "--path-format=absolute", "--show-toplevel")
    $scriptRepo = Get-I0CanonicalPath -Path (
        Normalize-I0ProcessText -Text $scriptRepoResult.stdout
    )
    if (-not [string]::Equals(
        $repoCandidate,
        $scriptRepo,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Prune script is not running from its selected Git worktree"
    }
    $scriptCommonResult = Invoke-I0Git `
        -RepoRoot $scriptRepo `
        -Arguments @("rev-parse", "--path-format=absolute", "--git-common-dir")
    $gitCommon = Get-I0CanonicalPath -Path (
        Normalize-I0ProcessText -Text $scriptCommonResult.stdout
    )
    $workspaceRoot = Get-I1PruneWorkspaceRoot `
        -RepoRoot $scriptRepo `
        -GitCommon $gitCommon
    [void](Set-I0WorkspaceRoot -Path $workspaceRoot)
    $prunerPath = Get-I0CanonicalPath -Path (
        Join-Path $PSScriptRoot "prune_i1_archived_worktrees.ps1"
    )
    if (-not [string]::Equals(
        (Get-I0CanonicalPath -Path $PSCommandPath),
        $prunerPath,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "The executing pruner path is not its exact governed tool path"
    }
    Assert-I1PruneRegularFile `
        -Path $prunerPath `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $scriptRepo `
        -Label "executing archived-worktree pruner"
    $prunerInitialBytes = [System.IO.File]::ReadAllBytes($prunerPath)
    $prunerInitialSha256 = Get-I1PruneBytesSha256 -Bytes $prunerInitialBytes

    $resolvedRunsRoot = Get-I0CanonicalPath -Path $RunsRoot
    if (-not (Test-Path -LiteralPath $resolvedRunsRoot -PathType Container) -or
        -not [string]::Equals(
            (Split-Path -Leaf $resolvedRunsRoot),
            "i1",
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        throw "RunsRoot must be an existing exact .tmp\\i1 directory: $resolvedRunsRoot"
    }
    $tmpRoot = Get-I0CanonicalPath -Path (Split-Path -Parent $resolvedRunsRoot)
    if (-not [string]::Equals(
        (Split-Path -Leaf $tmpRoot),
        ".tmp",
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot must end in .tmp\\i1: $resolvedRunsRoot"
    }
    $selectedRepo = Get-I0CanonicalPath -Path (Split-Path -Parent $tmpRoot)
    $selectedRepoResult = Invoke-I0Git `
        -RepoRoot $selectedRepo `
        -Arguments @("rev-parse", "--path-format=absolute", "--show-toplevel")
    $resolvedRepo = Get-I0CanonicalPath -Path (
        Normalize-I0ProcessText -Text $selectedRepoResult.stdout
    )
    if (-not [string]::Equals(
        $selectedRepo,
        $resolvedRepo,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot is not the selected Git worktree's .tmp\\i1"
    }
    $expectedRunsRoot = Get-I0CanonicalPath -Path (
        Join-Path $resolvedRepo ".tmp\i1"
    )
    if (-not [string]::Equals(
        $resolvedRunsRoot,
        $expectedRunsRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot is not the selected Git worktree's exact .tmp\\i1 path"
    }
    $selectedCommonResult = Invoke-I0Git `
        -RepoRoot $resolvedRepo `
        -Arguments @("rev-parse", "--path-format=absolute", "--git-common-dir")
    $selectedGitCommon = Get-I0CanonicalPath -Path (
        Normalize-I0ProcessText -Text $selectedCommonResult.stdout
    )
    if (-not [string]::Equals(
        $selectedGitCommon,
        $gitCommon,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot does not belong to the prune script's git-common workspace"
    }
    Assert-I0PathWithin `
        -Path $resolvedRepo `
        -Root $workspaceRoot `
        -AllowRoot `
        -Label "selected Git worktree"
    Assert-I0NoReparseExistingAncestor `
        -Path $resolvedRunsRoot `
        -Root $workspaceRoot `
        -Label "RunsRoot"

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
    Assert-I1PruneRegularDirectory `
        -Path $resolvedArchiveRoot `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $workspaceRoot `
        -Label "ArchiveRoot"
    if (-not [string]::Equals(
        [System.IO.Path]::GetPathRoot($resolvedRunsRoot),
        [System.IO.Path]::GetPathRoot($resolvedArchiveRoot),
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "RunsRoot and ArchiveRoot must be on the same workspace volume"
    }

    $seenRunIds = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    [string[]]$requestedRunIds = @($RunId | ForEach-Object {
        $value = [string]$_
        Assert-I1PruneLeafName -Value $value -Label "RunId"
        if (-not $seenRunIds.Add($value)) {
            throw "Duplicate RunId: $value"
        }
        $value
    })
    if ($requestedRunIds.Count -eq 0) {
        throw "At least one explicit RunId is required"
    }
    [System.Array]::Sort($requestedRunIds, [System.StringComparer]::Ordinal)

    $indexPath = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "index.json"
    )
    $indexShaPath = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "index.sha256"
    )
    Assert-I1PruneRegularFile `
        -Path $indexPath `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $resolvedArchiveRoot `
        -Label "archive index lock anchor"
    Assert-I1PruneRegularFile `
        -Path $indexShaPath `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $resolvedArchiveRoot `
        -Label "archive index sidecar"
    $lockAnchor = $indexPath
    try {
        $archiveLockStream = [System.IO.File]::Open(
            $indexPath,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::None
        )
    }
    catch {
        throw "Unable to acquire the exclusive ArchiveRoot lock on index.json: $($_.Exception.Message)"
    }

    Assert-I1PruneTreeSafety `
        -Root $resolvedArchiveRoot `
        -WorkspaceRoot $workspaceRoot `
        -Label "ArchiveRoot"

    $indexBytes = Read-I1PruneLockedStreamBytes -Stream $archiveLockStream
    $indexSha256 = Get-I1PruneBytesSha256 -Bytes $indexBytes
    if ($indexSha256 -cne $ExpectedIndexSha256) {
        throw "Archive index does not match ExpectedIndexSha256"
    }
    $indexShaBytes = Assert-I1PruneShaSidecar `
        -Path $indexShaPath `
        -ExpectedSha256 $indexSha256 `
        -ExpectedFileName "index.json" `
        -Label "archive index sidecar"
    $index = ConvertFrom-I1PruneStrictJsonBytes `
        -Bytes $indexBytes `
        -Label "archive index"
    foreach ($property in @("schema_version", "snapshots")) {
        Assert-I1PruneJsonProperty `
            -Object $index `
            -Name $property `
            -Label "archive index"
    }
    [void](ConvertTo-I1PruneInt64 `
        -Value $index.schema_version `
        -Label "archive index schema_version" `
        -Minimum 1 `
        -Maximum 1)
    if ($index.snapshots -isnot [array]) {
        throw "Archive index snapshots must be an array"
    }
    $indexEntries = @($index.snapshots)
    $indexByKey = @{}
    $previousIndexKey = $null
    $manifestBindingLines = New-Object System.Collections.Generic.List[string]
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
            Assert-I1PruneJsonProperty `
                -Object $entry `
                -Name $property `
                -Label "archive index entry"
        }
        if ($entry.namespace -isnot [string] -or $entry.run_id -isnot [string]) {
            throw "Archive index namespace and run_id must be strings"
        }
        $entryNamespace = [string]$entry.namespace
        $entryRunId = [string]$entry.run_id
        Assert-I1PruneLeafName -Value $entryNamespace -Label "index namespace"
        Assert-I1PruneLeafName -Value $entryRunId -Label "index run_id"
        $indexKey = "$entryNamespace`0$entryRunId"
        if ($indexByKey.ContainsKey($indexKey)) {
            throw "Duplicate case-insensitive archive index identity: $entryNamespace/$entryRunId"
        }
        if ($null -ne $previousIndexKey -and
            [System.StringComparer]::Ordinal.Compare(
                [string]$previousIndexKey,
                $indexKey
            ) -ge 0) {
            throw "Archive index is not in strict ordinal identity order"
        }
        $previousIndexKey = $indexKey
        $expectedManifestRelative = (
            "snapshots/$entryNamespace/$entryRunId/manifest.json"
        )
        if ($entry.manifest_path -isnot [string] -or
            [string]$entry.manifest_path -cne $expectedManifestRelative) {
            throw "Archive index manifest_path is not canonical: $entryNamespace/$entryRunId"
        }
        Assert-I1PruneRelativePath `
            -Path ([string]$entry.manifest_path) `
            -Label "index manifest_path"
        if ($entry.manifest_sha256 -isnot [string] -or
            [string]$entry.manifest_sha256 -notmatch '^[0-9A-F]{64}$') {
            throw "Archive index manifest SHA-256 is invalid: $entryNamespace/$entryRunId"
        }
        [void](ConvertTo-I1PruneInt64 `
            -Value $entry.file_count `
            -Label "archive index file_count")
        [void](ConvertTo-I1PruneInt64 `
            -Value $entry.logical_bytes `
            -Label "archive index logical_bytes")
        $indexByKey[$indexKey] = $entry
        [void]$manifestBindingLines.Add(
            "$entryNamespace/$entryRunId=$($entry.manifest_sha256)"
        )
    }

    $globalProofPath = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "verification_proofs\archive-verification.json"
    )
    $globalProofShaPath = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "verification_proofs\archive-verification.sha256"
    )
    Assert-I1PruneRegularFile `
        -Path $globalProofPath `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $resolvedArchiveRoot `
        -Label "global archive verification proof"
    Assert-I1PruneRegularFile `
        -Path $globalProofShaPath `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $resolvedArchiveRoot `
        -Label "global archive verification proof sidecar"
    $globalProofDocument = Read-I1PruneStrictJsonFile `
        -Path $globalProofPath `
        -Label "global archive verification proof"
    $globalProofSha256 = $globalProofDocument.sha256
    if ($globalProofSha256 -cne $ExpectedGlobalProofSha256) {
        throw "Global archive verification proof does not match ExpectedGlobalProofSha256"
    }
    $globalProofShaBytes = Assert-I1PruneShaSidecar `
        -Path $globalProofShaPath `
        -ExpectedSha256 $globalProofSha256 `
        -ExpectedFileName "archive-verification.json" `
        -Label "global archive verification proof sidecar"
    $globalProof = $globalProofDocument.value
    foreach ($property in @(
        "schema_version",
        "archive_root",
        "archive_volume_root",
        "index_sha256",
        "snapshot_count",
        "manifest_set_sha256",
        "unique_object_count",
        "unique_object_bytes",
        "unique_object_set_sha256",
        "verification"
    )) {
        Assert-I1PruneJsonProperty `
            -Object $globalProof `
            -Name $property `
            -Label "global archive verification proof"
    }
    [void](ConvertTo-I1PruneInt64 `
        -Value $globalProof.schema_version `
        -Label "global proof schema_version" `
        -Minimum 1 `
        -Maximum 1)
    if ([string]$globalProof.archive_root -cne $resolvedArchiveRoot -or
        [string]$globalProof.archive_volume_root -cne
        [System.IO.Path]::GetPathRoot($resolvedArchiveRoot) -or
        [string]$globalProof.index_sha256 -cne $indexSha256 -or
        (ConvertTo-I1PruneInt64 `
            -Value $globalProof.snapshot_count `
            -Label "global proof snapshot_count") -ne $indexEntries.Count) {
        throw "Global archive verification proof identity/index binding mismatch"
    }
    $indexSidecarHashProperty = Get-I1PrunePropertyValue `
        -Object $globalProof `
        -Name "index_sidecar_file_sha256"
    if ($null -ne $indexSidecarHashProperty -and
        [string]$indexSidecarHashProperty -cne
        (Get-I1PruneBytesSha256 -Bytes $indexShaBytes)) {
        throw "Global proof index sidecar file SHA-256 mismatch"
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $manifestSetText = (
        [string]::Join("`n", $manifestBindingLines.ToArray()) + "`n"
    )
    if ([string]$globalProof.manifest_set_sha256 -cne
        (Get-I1PruneBytesSha256 -Bytes $encoding.GetBytes($manifestSetText))) {
        throw "Global proof manifest-set binding does not match the archive index"
    }

    $proofStatusProperty = Get-I1PrunePropertyValue `
        -Object $globalProof `
        -Name "status"
    if ($null -eq $proofStatusProperty) {
        [void]$compatibilityNotes.Add(
            "global_proof_schema_v1_has_no_top_level_status; PASS is derived from every required verification boolean"
        )
    }
    elseif ($proofStatusProperty -isnot [string] -or
        [string]$proofStatusProperty -cne "PASS") {
        throw "Global archive verification proof status is not PASS"
    }
    $requiredGlobalVerification = @(
        "index_sidecar_sha256",
        "index_manifest_binding",
        "manifest_sidecar_sha256",
        "cas_object_length_and_sha256_once_per_unique_object",
        "cas_has_no_unreferenced_objects",
        "report_log_artifact_preview_evidence_length_and_sha256",
        "reparse_points_rejected",
        "alternate_data_streams_rejected",
        "path_traversal_rejected"
    )
    foreach ($property in $requiredGlobalVerification) {
        Assert-I1PruneJsonProperty `
            -Object $globalProof.verification `
            -Name $property `
            -Label "global proof verification"
        $value = Get-I1PrunePropertyValue `
            -Object $globalProof.verification `
            -Name $property
        if ($value -isnot [bool] -or [bool]$value -ne $true) {
            throw "Global proof verification field is not PASS: $property"
        }
    }

    $toolSha = Get-I1PrunePropertyValue -Object $globalProof -Name "tool_sha256"
    $toolBindingsStatus = $null
    if ($null -eq $toolSha) {
        $toolBindingsStatus = "legacy_missing_tool_sha256"
        [void]$compatibilityNotes.Add(
            "global_proof_has_no_tool_sha256; accepted as a legacy schema-v1 proof and reported explicitly"
        )
        if ($Apply) {
            throw "Apply rejects a global verification proof without tool_sha256 bindings"
        }
    }
    else {
        $toolPaths = [ordered]@{
            verifier = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "verify_i1_snapshot_archive.ps1"
            )
            archive = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "archive_i1_worktrees.ps1"
            )
            restore = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "restore_i1_worktree_archive.ps1"
            )
            i0_test_lib = Get-I0CanonicalPath -Path (
                Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1"
            )
        }
        foreach ($name in $toolPaths.Keys) {
            Assert-I1PruneJsonProperty `
                -Object $toolSha `
                -Name $name `
                -Label "global proof tool_sha256"
            $expectedToolSha = [string](
                Get-I1PrunePropertyValue -Object $toolSha -Name $name
            )
            if ($expectedToolSha -notmatch '^[0-9A-F]{64}$') {
                throw "Global proof tool SHA-256 is invalid: $name"
            }
            Assert-I1PruneRegularFile `
                -Path ([string]$toolPaths[$name]) `
                -WorkspaceRoot $workspaceRoot `
                -AllowedRoot $scriptRepo `
                -Label "archive governance tool"
            if ((Get-I1PruneFileSha256 -Path ([string]$toolPaths[$name])) -cne
                $expectedToolSha) {
                throw "Global proof tool SHA-256 no longer matches: $name"
            }
            $proofBoundToolItem = Get-Item `
                -LiteralPath ([string]$toolPaths[$name]) `
                -Force
            [void]$proofBoundToolRecords.Add(
                [pscustomobject][ordered]@{
                    name = [string]$name
                    path = [string]$toolPaths[$name]
                    sha256 = $expectedToolSha
                    length = [int64]$proofBoundToolItem.Length
                }
            )
        }
        $globalProofRestoreToolSha256 = [string](
            Get-I1PrunePropertyValue -Object $toolSha -Name "restore"
        )
        $toolBindingsStatus = "bound_current_tools"
    }

    $objectsRoot = Get-I0CanonicalPath -Path (
        Join-Path $resolvedArchiveRoot "objects\sha256"
    )
    Assert-I1PruneRegularDirectory `
        -Path $objectsRoot `
        -WorkspaceRoot $workspaceRoot `
        -AllowedRoot $resolvedArchiveRoot `
        -Label "archive CAS root"
    Assert-I1PruneTreeSafety `
        -Root $objectsRoot `
        -WorkspaceRoot $workspaceRoot `
        -Label "archive CAS root"
    $objectLines = New-Object System.Collections.Generic.List[string]
    [int64]$objectBytes = 0
    $seenObjects = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($objectFile in @(
        Get-ChildItem -LiteralPath $objectsRoot -Recurse -Force -File
    )) {
        $objectName = [string]$objectFile.Name
        if ($objectName -notmatch '^[0-9a-f]{64}$') {
            throw "Archive CAS contains a non-canonical object name: $($objectFile.FullName)"
        }
        $objectSha = $objectName.ToUpperInvariant()
        if (-not $seenObjects.Add($objectSha)) {
            throw "Archive CAS contains a duplicate case-insensitive object: $objectSha"
        }
        $expectedObjectPath = Get-I0CanonicalPath -Path (
            Join-Path $objectsRoot (
                "{0}\{1}\{2}" -f
                $objectSha.Substring(0, 2).ToLowerInvariant(),
                $objectSha.Substring(2, 2).ToLowerInvariant(),
                $objectSha.ToLowerInvariant()
            )
        )
        if (-not [string]::Equals(
            $expectedObjectPath,
            (Get-I0CanonicalPath -Path $objectFile.FullName),
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Archive CAS object is stored at a non-canonical path: $($objectFile.FullName)"
        }
        Assert-I1PruneRegularFile `
            -Path $expectedObjectPath `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedArchiveRoot `
            -Label "archive CAS object"
        $before = Get-Item -LiteralPath $expectedObjectPath -Force
        try {
            $objectLockStream = [System.IO.File]::Open(
                $expectedObjectPath,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::Read
            )
        }
        catch {
            throw "Unable to acquire a read-only CAS object lock: $expectedObjectPath error=$($_.Exception.Message)"
        }
        [void]$casLockStreams.Add($objectLockStream)
        if (-not $objectLockStream.CanRead -or
            $objectLockStream.SafeFileHandle.IsClosed -or
            [int64]$objectLockStream.Length -ne [int64]$before.Length) {
            throw "CAS object read lock is invalid or has an unexpected length: $expectedObjectPath"
        }
        $actualObjectSha = Get-I1PruneStreamSha256 -Stream $objectLockStream
        $after = Get-Item -LiteralPath $expectedObjectPath -Force
        if ([int64]$after.Length -ne [int64]$before.Length -or
            [int64]$after.LastWriteTimeUtc.Ticks -ne
            [int64]$before.LastWriteTimeUtc.Ticks -or
            [int64]$after.Attributes -ne [int64]$before.Attributes) {
            throw "Archive CAS object changed while its held stream was hashed: $expectedObjectPath"
        }
        Assert-I1PruneNoAlternateDataStreams `
            -Path $expectedObjectPath `
            -IsDirectory $false
        if ($actualObjectSha -cne $objectSha) {
            throw "Archive CAS object content SHA-256 does not match its filename: $expectedObjectPath"
        }
        [void]$casStabilityRecords.Add([pscustomobject][ordered]@{
            path = $expectedObjectPath
            sha256 = $objectSha
            length = [int64]$before.Length
            mtime_utc_ticks = [int64]$before.LastWriteTimeUtc.Ticks
            attributes = [int64]$before.Attributes
            lock_stream = $objectLockStream
        })
        [void]$objectLines.Add("$objectSha`:$([int64]$before.Length)")
        $objectBytes += [int64]$before.Length
    }
    $objectLineArray = $objectLines.ToArray()
    [System.Array]::Sort($objectLineArray, [System.StringComparer]::Ordinal)
    $objectSetText = if ($objectLineArray.Count -eq 0) {
        ""
    }
    else {
        [string]::Join("`n", $objectLineArray) + "`n"
    }
    if ($seenObjects.Count -ne
        (ConvertTo-I1PruneInt64 `
            -Value $globalProof.unique_object_count `
            -Label "global proof unique_object_count") -or
        $objectBytes -ne
        (ConvertTo-I1PruneInt64 `
            -Value $globalProof.unique_object_bytes `
            -Label "global proof unique_object_bytes") -or
        [string]$globalProof.unique_object_set_sha256 -cne
        (Get-I1PruneBytesSha256 -Bytes $encoding.GetBytes($objectSetText))) {
        throw "Current archive CAS inventory no longer matches the global proof"
    }
    $casUniqueObjectCount = $seenObjects.Count
    $casUniqueObjectBytes = $objectBytes
    $casContentSha256Verified = $true
    Assert-I1PruneCasRecordsStable `
        -ObjectsRoot $objectsRoot `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot `
        -ExpectedRecords $casStabilityRecords.ToArray()
    $casMetadataStabilityCheckCount += 1
    $casReadLocksHeldThroughPrune = (
        $casLockStreams.Count -eq $casUniqueObjectCount
    )
    if (-not $casReadLocksHeldThroughPrune) {
        throw "Not every globally verified CAS object has a held read-only lock"
    }

    $restoreProofSpecs = @{}
    foreach ($proofSpecValue in @($RepresentativeRestoreProof)) {
        $proofSpec = [string]$proofSpecValue
        $match = [regex]::Match(
            $proofSpec,
            '^([^/=]+)/([^=]+)=([0-9A-Fa-f]{64})@([0-9A-Fa-f]{64})$',
            [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
        )
        if (-not $match.Success) {
            throw "RepresentativeRestoreProof must be Namespace/RunId=MANIFEST_SHA256@PROOF_SHA256: $proofSpec"
        }
        $proofNamespace = [string]$match.Groups[1].Value
        $proofRunId = [string]$match.Groups[2].Value
        $proofManifestSha = $match.Groups[3].Value.ToUpperInvariant()
        $proofExpectedSha = $match.Groups[4].Value.ToUpperInvariant()
        Assert-I1PruneLeafName `
            -Value $proofNamespace `
            -Label "RepresentativeRestoreProof Namespace"
        Assert-I1PruneLeafName `
            -Value $proofRunId `
            -Label "RepresentativeRestoreProof RunId"
        $proofKey = "$proofNamespace`0$proofRunId"
        if ($restoreProofSpecs.ContainsKey($proofKey)) {
            throw "Duplicate RepresentativeRestoreProof: $proofNamespace/$proofRunId"
        }
        if (-not $indexByKey.ContainsKey($proofKey)) {
            throw "RepresentativeRestoreProof is not present in the archive index: $proofNamespace/$proofRunId"
        }
        $proofIndexEntry = $indexByKey[$proofKey]
        if ([string]$proofIndexEntry.manifest_sha256 -cne $proofManifestSha) {
            throw "RepresentativeRestoreProof manifest SHA-256 does not match the index: $proofNamespace/$proofRunId"
        }
        $restoreProofSpecs[$proofKey] = [pscustomobject][ordered]@{
            namespace = $proofNamespace
            run_id = $proofRunId
            manifest_sha256 = $proofManifestSha
            expected_proof_sha256 = $proofExpectedSha
            index_entry = $proofIndexEntry
        }
    }
    if ($restoreProofSpecs.Count -eq 0) {
        throw "At least one explicit RepresentativeRestoreProof is required"
    }
    if ($null -eq $globalProofRestoreToolSha256) {
        throw "Representative restore proof v2 requires a global proof with a restore tool SHA-256 binding"
    }

    $representativeForSelectedNamespace = $null
    $representativeManifestBindings = New-Object System.Collections.Generic.List[object]
    [string[]]$restoreProofKeys = @(
        $restoreProofSpecs.Keys | ForEach-Object { [string]$_ }
    )
    [System.Array]::Sort($restoreProofKeys, [System.StringComparer]::Ordinal)
    foreach ($proofKey in $restoreProofKeys) {
        $spec = $restoreProofSpecs[$proofKey]
        $binding = Get-I1PruneManifestBinding `
            -ArchiveRoot $resolvedArchiveRoot `
            -WorkspaceRoot $workspaceRoot `
            -IndexEntry $spec.index_entry `
            -ExpectedNamespace $spec.namespace `
            -ExpectedRunId $spec.run_id
        [void]$representativeManifestBindings.Add($binding)
        $verifiedProof = Assert-I1PruneRestoreProof `
            -ArchiveRoot $resolvedArchiveRoot `
            -WorkspaceRoot $workspaceRoot `
            -Namespace $spec.namespace `
            -RunId $spec.run_id `
            -ManifestSha256 $spec.manifest_sha256 `
            -ExpectedProofSha256 $spec.expected_proof_sha256 `
            -ExpectedIndexSha256 $indexSha256 `
            -ExpectedRestoreToolSha256 $globalProofRestoreToolSha256 `
            -ApplyRequested ([bool]$Apply) `
            -ManifestBinding $binding
        [void]$restoreProofStabilityRecords.Add($verifiedProof)
        [void]$verifiedRestoreProofs.Add($verifiedProof.public)
        if ([string]$spec.namespace -ceq $Namespace -and
            $null -eq $representativeForSelectedNamespace) {
            $representativeForSelectedNamespace = $verifiedProof.public
        }
    }
    if ($null -eq $representativeForSelectedNamespace) {
        throw "The selected Namespace has no verified representative restore proof: $Namespace"
    }

    $manifestBindingsForStability = New-Object System.Collections.Generic.List[object]
    foreach ($binding in $representativeManifestBindings) {
        [void]$manifestBindingsForStability.Add($binding)
    }
    foreach ($requestedRunId in $requestedRunIds) {
        $indexKey = "$Namespace`0$requestedRunId"
        if (-not $indexByKey.ContainsKey($indexKey)) {
            throw "Requested target is not present in the archive index: $Namespace/$requestedRunId"
        }
        $indexEntry = $indexByKey[$indexKey]
        $manifestBinding = Get-I1PruneManifestBinding `
            -ArchiveRoot $resolvedArchiveRoot `
            -WorkspaceRoot $workspaceRoot `
            -IndexEntry $indexEntry `
            -ExpectedNamespace $Namespace `
            -ExpectedRunId $requestedRunId
        [void]$manifestBindingsForStability.Add($manifestBinding)

        $manifestRunsRoot = Get-I0CanonicalPath -Path (
            [string]$manifestBinding.manifest.runs_root
        )
        if (-not [string]::Equals(
            $manifestRunsRoot,
            $resolvedRunsRoot,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Manifest runs_root does not match explicit RunsRoot: $Namespace/$requestedRunId"
        }
        $manifestSelectedRepo = Get-I0CanonicalPath -Path (
            [string]$manifestBinding.manifest.selected_git_worktree
        )
        $manifestWorkspace = Get-I0CanonicalPath -Path (
            [string]$manifestBinding.manifest.git_common_workspace
        )
        if (-not [string]::Equals(
            $manifestSelectedRepo,
            $resolvedRepo,
            [System.StringComparison]::OrdinalIgnoreCase
        ) -or -not [string]::Equals(
            $manifestWorkspace,
            $workspaceRoot,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Manifest repository/workspace identity mismatch: $Namespace/$requestedRunId"
        }

        $runRoot = Get-I0CanonicalPath -Path (
            Join-Path $resolvedRunsRoot $requestedRunId
        )
        Assert-I1PruneRegularDirectory `
            -Path $runRoot `
            -WorkspaceRoot $workspaceRoot `
            -AllowedRoot $resolvedRunsRoot `
            -Label "I1 run root"
        $worktree = Get-I0CanonicalPath -Path (Join-Path $runRoot "worktree")
        Assert-I0PathWithin -Path $worktree -Root $runRoot -Label "I1 worktree"
        if (-not [string]::Equals(
            (Get-I0CanonicalPath -Path ([string]$manifestBinding.manifest.worktree)),
            $worktree,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Manifest worktree does not match the exact derived worktree path: $Namespace/$requestedRunId"
        }
        $tombstone = Get-I0CanonicalPath -Path (
            Join-Path $runRoot (
                ".archived_worktree_prune_{0}_{1}" -f
                $manifestBinding.sha256.Substring(0, 16),
                ([guid]::NewGuid().ToString("N"))
            )
        )
        Assert-I0PathWithin `
            -Path $tombstone `
            -Root $runRoot `
            -Label "prune tombstone"
        if (Test-Path -LiteralPath $tombstone) {
            throw "A prune tombstone already exists and requires explicit recovery: $tombstone"
        }
        if (-not [string]::Equals(
            [System.IO.Path]::GetPathRoot($worktree),
            [System.IO.Path]::GetPathRoot($tombstone),
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
            throw "Worktree and tombstone must be on the same volume"
        }

        $receiptRoot = Get-I0CanonicalPath -Path (
            Join-Path $resolvedArchiveRoot (
                "prune_transactions\{0}\{1}\{2}" -f
                $Namespace,
                $requestedRunId,
                $manifestBinding.sha256
            )
        )
        Assert-I0PathWithin `
            -Path $receiptRoot `
            -Root $resolvedArchiveRoot `
            -Label "prune transaction root"
        if (Test-Path -LiteralPath $receiptRoot) {
            throw "A prune transaction already exists and requires explicit review: $receiptRoot"
        }

        Assert-I1PruneNoProcessReference -Worktree $worktree
        $inventory = Get-I1PruneWorktreeInventory `
            -Worktree $worktree `
            -WorkspaceRoot $workspaceRoot `
            -GitCommon $gitCommon
        Assert-I1PruneIncludedMatchesManifest `
            -ManifestRecords @($manifestBinding.files) `
            -Inventory $inventory `
            -Label "source worktree versus archive manifest"
        $evidence = Get-I1PruneRetainedEvidenceState `
            -Manifest $manifestBinding.manifest `
            -RunRoot $runRoot `
            -WorkspaceRoot $workspaceRoot

        $public = [pscustomobject][ordered]@{
            namespace = $Namespace
            run_id = $requestedRunId
            worktree = $worktree
            tombstone = $tombstone
            manifest_path = $manifestBinding.path
            manifest_sha256 = $manifestBinding.sha256
            included_file_count = $inventory.included_file_count
            included_logical_bytes = $inventory.included_logical_bytes
            excluded_file_count = $inventory.excluded_file_count
            excluded_logical_bytes = $inventory.excluded_logical_bytes
            directory_count = $inventory.directory_count
            exclusions = $inventory.exclusions
            retained_evidence_file_count = $evidence.file_count
            retained_evidence_logical_bytes = $evidence.logical_bytes
            receipt_root = $receiptRoot
            planned_receipts = @(
                "01-planned.json",
                "02-tombstoned.json",
                "03-delete_started.json",
                "04-removed.json"
            )
            state = "preflight_pass"
            last_receipt_path = $null
            last_receipt_sha256 = $null
            tombstone_runtime_guid_suffix = $true
            tombstone_file_lock_count = 0
            tombstone_file_lock_share = "Read|Delete"
            worktree_removed = $false
        }
        $target = [pscustomobject][ordered]@{
            namespace = $Namespace
            run_id = $requestedRunId
            runs_root = $resolvedRunsRoot
            run_root = $runRoot
            worktree = $worktree
            tombstone = $tombstone
            receipt_root = $receiptRoot
            manifest = $manifestBinding
            inventory = $inventory
            evidence = $evidence
            representative_restore_proof = $representativeForSelectedNamespace
            public = $public
        }
        [void]$targetStates.Add($target)
        [void]$targetPublicResults.Add($public)
    }

    [void](Add-I1PruneHeldReadLock `
        -Path $indexShaPath `
        -ExpectedBytes $indexShaBytes `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot `
        -LockStreams $criticalReadLockStreams `
        -LockRecordByPath $criticalReadLockRecordByPath `
        -Label "archive index sidecar")
    [void](Add-I1PruneHeldReadLock `
        -Path $globalProofPath `
        -ExpectedBytes $globalProofDocument.bytes `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot `
        -LockStreams $criticalReadLockStreams `
        -LockRecordByPath $criticalReadLockRecordByPath `
        -Label "global archive verification proof")
    [void](Add-I1PruneHeldReadLock `
        -Path $globalProofShaPath `
        -ExpectedBytes $globalProofShaBytes `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot `
        -LockStreams $criticalReadLockStreams `
        -LockRecordByPath $criticalReadLockRecordByPath `
        -Label "global archive verification proof sidecar")
    foreach ($binding in $manifestBindingsForStability) {
        [void](Add-I1PruneHeldReadLock `
            -Path ([string]$binding.path) `
            -ExpectedBytes ([byte[]]$binding.bytes) `
            -WorkspaceRoot $workspaceRoot `
            -ArchiveRoot $resolvedArchiveRoot `
            -LockStreams $criticalReadLockStreams `
            -LockRecordByPath $criticalReadLockRecordByPath `
            -Label "archive manifest")
        [void](Add-I1PruneHeldReadLock `
            -Path ([string]$binding.sidecar_path) `
            -ExpectedBytes ([byte[]]$binding.sidecar_bytes) `
            -WorkspaceRoot $workspaceRoot `
            -ArchiveRoot $resolvedArchiveRoot `
            -LockStreams $criticalReadLockStreams `
            -LockRecordByPath $criticalReadLockRecordByPath `
            -Label "archive manifest sidecar")
    }
    foreach ($proofBinding in $restoreProofStabilityRecords) {
        [void](Add-I1PruneHeldReadLock `
            -Path ([string]$proofBinding.path) `
            -ExpectedBytes ([byte[]]$proofBinding.bytes) `
            -WorkspaceRoot $workspaceRoot `
            -ArchiveRoot $resolvedArchiveRoot `
            -LockStreams $criticalReadLockStreams `
            -LockRecordByPath $criticalReadLockRecordByPath `
            -Label "representative restore proof")
        [void](Add-I1PruneHeldReadLock `
            -Path ([string]$proofBinding.sidecar_path) `
            -ExpectedBytes ([byte[]]$proofBinding.sidecar_bytes) `
            -WorkspaceRoot $workspaceRoot `
            -ArchiveRoot $resolvedArchiveRoot `
            -LockStreams $criticalReadLockStreams `
            -LockRecordByPath $criticalReadLockRecordByPath `
            -Label "representative restore proof sidecar")
    }
    if ($toolBindingsStatus -eq "bound_current_tools") {
        if ($proofBoundToolRecords.Count -ne 4) {
            throw "Exactly four global-proof-bound governance tools must be locked"
        }
        foreach ($toolRecord in $proofBoundToolRecords) {
            $toolBytes = [System.IO.File]::ReadAllBytes([string]$toolRecord.path)
            if ([int64]$toolBytes.Length -ne [int64]$toolRecord.length -or
                (Get-I1PruneBytesSha256 -Bytes $toolBytes) -cne
                [string]$toolRecord.sha256) {
                throw "A global-proof-bound governance tool changed before its held lock: $($toolRecord.name)"
            }
            [void](Add-I1PruneHeldReadLock `
                -Path ([string]$toolRecord.path) `
                -ExpectedBytes $toolBytes `
                -WorkspaceRoot $workspaceRoot `
                -ArchiveRoot $scriptRepo `
                -LockStreams $criticalReadLockStreams `
                -LockRecordByPath $criticalReadLockRecordByPath `
                -Label "global-proof-bound governance tool: $($toolRecord.name)")
        }
        $proofBoundToolLocksHeld = $true
    }
    [void](Add-I1PruneHeldReadLock `
        -Path $prunerPath `
        -ExpectedBytes $prunerInitialBytes `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $scriptRepo `
        -LockStreams $criticalReadLockStreams `
        -LockRecordByPath $criticalReadLockRecordByPath `
        -Label "executing archived-worktree pruner")
    $prunerSelfLockHeld = $true
    Assert-I1PruneHeldReadLocksValid `
        -LockRecordByPath $criticalReadLockRecordByPath `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot
    $criticalReadLocksValidated = $true

    Assert-I1PruneBoundFilesStable `
        -IndexLock $archiveLockStream `
        -IndexBytes $indexBytes `
        -IndexShaPath $indexShaPath `
        -IndexShaBytes $indexShaBytes `
        -GlobalProofPath $globalProofPath `
        -GlobalProofBytes $globalProofDocument.bytes `
        -GlobalProofShaPath $globalProofShaPath `
        -GlobalProofShaBytes $globalProofShaBytes `
        -ManifestBindings $manifestBindingsForStability.ToArray()
    Assert-I1PruneCasRecordsStable `
        -ObjectsRoot $objectsRoot `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot `
        -ExpectedRecords $casStabilityRecords.ToArray()
    $casMetadataStabilityCheckCount += 1
    $preflightCompleted = $true

    $prunerSha256 = $prunerInitialSha256
    if ($Apply) {
        $mutationMayHaveOccurred = $true

        foreach ($target in $targetStates) {
            $receipt = Write-I1PruneTransactionStage `
                -Target $target `
                -Stage "planned" `
                -Sequence 1 `
                -WorkspaceRoot $workspaceRoot `
                -ArchiveRoot $resolvedArchiveRoot `
                -IndexSha256 $indexSha256 `
                -GlobalProofSha256 $globalProofSha256 `
                -PrunerSha256 $prunerSha256 `
                -PreviousReceipt $null
            $target.public.state = "planned"
            $target.public.last_receipt_path = $receipt.path
            $target.public.last_receipt_sha256 = $receipt.sha256
        }

        foreach ($target in $targetStates) {
            Assert-I1PruneNoProcessReference -Worktree $target.worktree
            Assert-I1PruneInventoryMetadataStable `
                -Root $target.worktree `
                -ExpectedInventory $target.inventory `
                -WorkspaceRoot $workspaceRoot `
                -Label "source changed after batch preflight"
            $evidenceBefore = Get-I1PruneRetainedEvidenceState `
                -Manifest $target.manifest.manifest `
                -RunRoot $target.run_root `
                -WorkspaceRoot $workspaceRoot
            Assert-I1PruneRetainedEvidenceEqual `
                -Expected $target.evidence `
                -Actual $evidenceBefore
            if (Test-Path -LiteralPath $target.tombstone) {
                throw "Prune tombstone appeared after batch preflight: $($target.tombstone)"
            }

            $worktreeRemovalMayHaveStarted = $true
            [System.IO.Directory]::Move($target.worktree, $target.tombstone)
            $target.public.state = "tombstoned"
            if (Test-Path -LiteralPath $target.worktree) {
                throw "Worktree still exists after atomic tombstone rename: $($target.worktree)"
            }
            $previousReceipt = [pscustomobject][ordered]@{
                path = $target.public.last_receipt_path
                sha256 = $target.public.last_receipt_sha256
            }
            $receipt = Write-I1PruneTransactionStage `
                -Target $target `
                -Stage "tombstoned" `
                -Sequence 2 `
                -WorkspaceRoot $workspaceRoot `
                -ArchiveRoot $resolvedArchiveRoot `
                -IndexSha256 $indexSha256 `
                -GlobalProofSha256 $globalProofSha256 `
                -PrunerSha256 $prunerSha256 `
                -PreviousReceipt $previousReceipt
            $target.public.last_receipt_path = $receipt.path
            $target.public.last_receipt_sha256 = $receipt.sha256

            $tombstoneLockResult = $null
            try {
                $tombstoneLockResult = Open-I1PruneTombstoneFileLocks `
                    -Tombstone $target.tombstone `
                    -ExpectedInventory $target.inventory `
                    -WorkspaceRoot $workspaceRoot `
                    -GitCommon $gitCommon
                $target.public.tombstone_file_lock_count = (
                    $tombstoneLockResult.file_count
                )
                $evidenceAfterRename = Get-I1PruneRetainedEvidenceState `
                    -Manifest $target.manifest.manifest `
                    -RunRoot $target.run_root `
                    -WorkspaceRoot $workspaceRoot
                Assert-I1PruneRetainedEvidenceEqual `
                    -Expected $target.evidence `
                    -Actual $evidenceAfterRename

                $previousReceipt = [pscustomobject][ordered]@{
                    path = $target.public.last_receipt_path
                    sha256 = $target.public.last_receipt_sha256
                }
                $receipt = Write-I1PruneTransactionStage `
                    -Target $target `
                    -Stage "delete_started" `
                    -Sequence 3 `
                    -WorkspaceRoot $workspaceRoot `
                    -ArchiveRoot $resolvedArchiveRoot `
                    -IndexSha256 $indexSha256 `
                    -GlobalProofSha256 $globalProofSha256 `
                    -PrunerSha256 $prunerSha256 `
                    -PreviousReceipt $previousReceipt
                $target.public.state = "delete_started"
                $target.public.last_receipt_path = $receipt.path
                $target.public.last_receipt_sha256 = $receipt.sha256

                $resolvedDeleteTarget = Get-I0CanonicalPath -Path $target.tombstone
                if (-not [string]::Equals(
                    $resolvedDeleteTarget,
                    $target.tombstone,
                    [System.StringComparison]::OrdinalIgnoreCase
                )) {
                    throw "Delete target no longer matches its exact tombstone path"
                }
                Assert-I0PathWithin `
                    -Path $resolvedDeleteTarget `
                    -Root $target.run_root `
                    -Label "prune tombstone delete target"
                Assert-I1PruneLockedTombstoneStructure `
                    -Tombstone $resolvedDeleteTarget `
                    -ExpectedInventory $target.inventory `
                    -LockResult $tombstoneLockResult `
                    -WorkspaceRoot $workspaceRoot
                Assert-I1PruneBoundFilesStable `
                    -IndexLock $archiveLockStream `
                    -IndexBytes $indexBytes `
                    -IndexShaPath $indexShaPath `
                    -IndexShaBytes $indexShaBytes `
                    -GlobalProofPath $globalProofPath `
                    -GlobalProofBytes $globalProofDocument.bytes `
                    -GlobalProofShaPath $globalProofShaPath `
                    -GlobalProofShaBytes $globalProofShaBytes `
                    -ManifestBindings @($target.manifest)
                Assert-I1PruneHeldReadLocksValid `
                    -LockRecordByPath $criticalReadLockRecordByPath `
                    -WorkspaceRoot $workspaceRoot `
                    -ArchiveRoot $resolvedArchiveRoot
                Remove-Item -LiteralPath $resolvedDeleteTarget -Recurse -Force
                if (Test-Path -LiteralPath $resolvedDeleteTarget) {
                    throw "Tombstone deletion did not complete: $resolvedDeleteTarget"
                }
                $worktreeRemovalPerformed = $true
                $removedCount += 1
                $target.public.worktree_removed = $true

                $evidenceAfterDelete = Get-I1PruneRetainedEvidenceState `
                    -Manifest $target.manifest.manifest `
                    -RunRoot $target.run_root `
                    -WorkspaceRoot $workspaceRoot
                Assert-I1PruneRetainedEvidenceEqual `
                    -Expected $target.evidence `
                    -Actual $evidenceAfterDelete
                Assert-I1PruneBoundFilesStable `
                    -IndexLock $archiveLockStream `
                    -IndexBytes $indexBytes `
                    -IndexShaPath $indexShaPath `
                    -IndexShaBytes $indexShaBytes `
                    -GlobalProofPath $globalProofPath `
                    -GlobalProofBytes $globalProofDocument.bytes `
                    -GlobalProofShaPath $globalProofShaPath `
                    -GlobalProofShaBytes $globalProofShaBytes `
                    -ManifestBindings @($target.manifest)
                Assert-I1PruneHeldReadLocksValid `
                    -LockRecordByPath $criticalReadLockRecordByPath `
                    -WorkspaceRoot $workspaceRoot `
                    -ArchiveRoot $resolvedArchiveRoot

                $previousReceipt = [pscustomobject][ordered]@{
                    path = $target.public.last_receipt_path
                    sha256 = $target.public.last_receipt_sha256
                }
                $receipt = Write-I1PruneTransactionStage `
                    -Target $target `
                    -Stage "removed" `
                    -Sequence 4 `
                    -WorkspaceRoot $workspaceRoot `
                    -ArchiveRoot $resolvedArchiveRoot `
                    -IndexSha256 $indexSha256 `
                    -GlobalProofSha256 $globalProofSha256 `
                    -PrunerSha256 $prunerSha256 `
                    -PreviousReceipt $previousReceipt
                $target.public.state = "removed"
                $target.public.last_receipt_path = $receipt.path
                $target.public.last_receipt_sha256 = $receipt.sha256
            }
            finally {
                Close-I1PruneTombstoneFileLocks `
                    -LockResult $tombstoneLockResult
            }
        }
        Assert-I1PruneCasContentHashes `
            -ObjectsRoot $objectsRoot `
            -WorkspaceRoot $workspaceRoot `
            -ArchiveRoot $resolvedArchiveRoot `
            -ExpectedRecords $casStabilityRecords.ToArray()
        $casMetadataStabilityCheckCount += 2
        $casPostBatchContentReverified = $true
    }
    else {
        foreach ($target in $targetStates) {
            $target.public.state = "dry_run_planned"
        }
    }

    Assert-I1PruneBoundFilesStable `
        -IndexLock $archiveLockStream `
        -IndexBytes $indexBytes `
        -IndexShaPath $indexShaPath `
        -IndexShaBytes $indexShaBytes `
        -GlobalProofPath $globalProofPath `
        -GlobalProofBytes $globalProofDocument.bytes `
        -GlobalProofShaPath $globalProofShaPath `
        -GlobalProofShaBytes $globalProofShaBytes `
        -ManifestBindings $manifestBindingsForStability.ToArray()
    Assert-I1PruneCasRecordsStable `
        -ObjectsRoot $objectsRoot `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot `
        -ExpectedRecords $casStabilityRecords.ToArray()
    $casMetadataStabilityCheckCount += 1
    Assert-I1PruneHeldReadLocksValid `
        -LockRecordByPath $criticalReadLockRecordByPath `
        -WorkspaceRoot $workspaceRoot `
        -ArchiveRoot $resolvedArchiveRoot

    $result = [pscustomobject][ordered]@{
        schema_version = 1
        status = "PASS"
        mode = $mode
        apply_requested = [bool]$Apply
        mutation_may_have_occurred = $mutationMayHaveOccurred
        preflight_completed_for_all_targets = $preflightCompleted
        worktree_removal_may_have_started = $worktreeRemovalMayHaveStarted
        worktree_removal_performed = $worktreeRemovalPerformed
        worktree_removed_count = $removedCount
        selected_git_worktree = $resolvedRepo
        git_common_workspace = $workspaceRoot
        runs_root = $resolvedRunsRoot
        namespace = $Namespace
        archive_root = $resolvedArchiveRoot
        exclusive_lock_anchor = $lockAnchor
        exclusive_lock_file_share = "None"
        index_path = $indexPath
        index_sha256 = $indexSha256
        global_proof_path = $globalProofPath
        global_proof_sha256 = $globalProofSha256
        global_proof_tool_binding = $toolBindingsStatus
        cas_gate = [pscustomobject][ordered]@{
            unique_object_count = $casUniqueObjectCount
            unique_object_bytes = $casUniqueObjectBytes
            every_object_content_sha256_matches_filename = $casContentSha256Verified
            held_stream_file_access = "Read"
            held_stream_file_share = "Read"
            held_stream_count = $casLockStreams.Count
            read_locks_held_until_finally = $casReadLocksHeldThroughPrune
            metadata_stability_check_count = $casMetadataStabilityCheckCount
            post_batch_content_reverified = $casPostBatchContentReverified
            hash_policy = "one global preflight pass; one post-batch pass only for Apply; never once per run"
        }
        critical_archive_file_gate = [pscustomobject][ordered]@{
            held_stream_file_access = "Read"
            held_stream_file_share = "Read"
            held_stream_count = $criticalReadLockStreams.Count
            includes_index_sidecar_global_proof_manifests_restore_proofs = $true
            proof_bound_governance_tool_count = $proofBoundToolRecords.Count
            proof_bound_governance_tool_locks_held = $proofBoundToolLocksHeld
            executing_pruner_self_lock_held = $prunerSelfLockHeld
            executing_pruner_sha256 = $prunerInitialSha256
            locks_validated = $criticalReadLocksValidated
            locks_held_until_finally = ($criticalReadLockStreams.Count -gt 0)
        }
        compatibility_notes = $compatibilityNotes.ToArray()
        representative_restore_proofs = $verifiedRestoreProofs.ToArray()
        target_count = $targetPublicResults.Count
        targets = $targetPublicResults.ToArray()
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
        preflight_completed_for_all_targets = $preflightCompleted
        worktree_removal_may_have_started = $worktreeRemovalMayHaveStarted
        worktree_removal_performed = $worktreeRemovalPerformed
        worktree_removed_count = $removedCount
        selected_git_worktree = $resolvedRepo
        git_common_workspace = $workspaceRoot
        runs_root = $resolvedRunsRoot
        namespace = $Namespace
        archive_root = $resolvedArchiveRoot
        exclusive_lock_anchor = $lockAnchor
        index_sha256 = $indexSha256
        global_proof_path = $globalProofPath
        global_proof_sha256 = $globalProofSha256
        cas_gate = [pscustomobject][ordered]@{
            unique_object_count = $casUniqueObjectCount
            unique_object_bytes = $casUniqueObjectBytes
            every_object_content_sha256_matches_filename = $casContentSha256Verified
            held_stream_file_access = "Read"
            held_stream_file_share = "Read"
            held_stream_count = $casLockStreams.Count
            read_locks_held_through_failure = $casReadLocksHeldThroughPrune
            metadata_stability_check_count = $casMetadataStabilityCheckCount
            post_batch_content_reverified = $casPostBatchContentReverified
        }
        critical_archive_file_gate = [pscustomobject][ordered]@{
            held_stream_file_access = "Read"
            held_stream_file_share = "Read"
            held_stream_count = $criticalReadLockStreams.Count
            proof_bound_governance_tool_count = $proofBoundToolRecords.Count
            proof_bound_governance_tool_locks_held = $proofBoundToolLocksHeld
            executing_pruner_self_lock_held = $prunerSelfLockHeld
            executing_pruner_sha256 = $prunerInitialSha256
            locks_validated = $criticalReadLocksValidated
            locks_held_until_finally = ($criticalReadLockStreams.Count -gt 0)
        }
        compatibility_notes = $compatibilityNotes.ToArray()
        representative_restore_proofs = $verifiedRestoreProofs.ToArray()
        targets = $targetPublicResults.ToArray()
        error = $_.Exception.Message
    }
}
finally {
    for ($index = $criticalReadLockStreams.Count - 1; $index -ge 0; $index--) {
        try {
            $criticalReadLockStreams[$index].Dispose()
        }
        catch {
        }
    }
    for ($index = $casLockStreams.Count - 1; $index -ge 0; $index--) {
        try {
            $casLockStreams[$index].Dispose()
        }
        catch {
        }
    }
    if ($null -ne $archiveLockStream) {
        $archiveLockStream.Dispose()
        $archiveLockStream = $null
    }
}

Write-Output (
    "I1_ARCHIVED_WORKTREE_PRUNE_JSON=" +
    ($result | ConvertTo-Json -Depth 30 -Compress)
)
exit $exitCode
