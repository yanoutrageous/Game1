param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ArchiveRoot,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Namespace,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$RunId,

    [switch]$Apply,

    [switch]$RemoveRestoredAfterVerify
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1")


function Assert-I1RestoreLeafName {
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


function Get-I1RestoreWorkspaceRoot {
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


function Get-I1RestoreSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I1RestoreBytesSha256 {
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


function Test-I1RestoreByteArrayEqual {
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


function Assert-I1RestoreNoAlternateDataStreams {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected a regular file while checking alternate data streams: $Path"
    }
    $streams = @(Get-Item -LiteralPath $Path -Stream * -Force -ErrorAction Stop)
    if ($streams.Count -ne 1 -or
        [string]$streams[0].Stream -cne ':$DATA') {
        $streamNames = @($streams | ForEach-Object { [string]$_.Stream }) -join ','
        throw "Alternate data streams are forbidden: $Path streams=$streamNames"
    }
}


function Assert-I1RestoreRegularFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    Assert-I0NoReparseExistingAncestor -Path $Path -Root $WorkspaceRoot -Label $Label
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label is missing or is not a file: $Path"
    }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Label is a reparse point: $Path"
    }
    if (($item.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
        throw "$Label is a directory: $Path"
    }
    if (($item.Attributes -band [System.IO.FileAttributes]::Device) -ne 0) {
        throw "$Label is a device, not a regular file: $Path"
    }
    Assert-I1RestoreNoAlternateDataStreams -Path $Path
}


function Get-I1RestoreStableRegularFileBinding {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BoundaryRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $resolvedPath = Get-I0CanonicalPath -Path $Path
    $resolvedBoundaryRoot = Get-I0CanonicalPath -Path $BoundaryRoot
    Assert-I0PathWithin `
        -Path $resolvedPath `
        -Root $resolvedBoundaryRoot `
        -Label $Label
    Assert-I1RestoreRegularFile `
        -Path $resolvedPath `
        -WorkspaceRoot $WorkspaceRoot `
        -Label $Label

    $before = Get-Item -LiteralPath $resolvedPath -Force
    $length = [int64]$before.Length
    $mtimeTicks = [int64]$before.LastWriteTimeUtc.Ticks
    $attributes = [int64]$before.Attributes
    $sha256 = Get-I1RestoreSha256 -Path $resolvedPath
    $after = Get-Item -LiteralPath $resolvedPath -Force
    if ([int64]$after.Length -ne $length -or
        [int64]$after.LastWriteTimeUtc.Ticks -ne $mtimeTicks -or
        [int64]$after.Attributes -ne $attributes) {
        throw "$Label changed while it was being bound: $resolvedPath"
    }
    Assert-I1RestoreNoAlternateDataStreams -Path $resolvedPath

    $relativePath = (
        Get-I0RelativePath -Path $resolvedPath -Root $resolvedBoundaryRoot
    ).Replace('\', '/')
    Assert-I1RestoreRelativePath -Path $relativePath -Label "$Label relative path"

    return [pscustomobject][ordered]@{
        canonical_path = $resolvedPath
        boundary_root = $resolvedBoundaryRoot
        relative_path = $relativePath
        sha256 = $sha256
        length = $length
        mtime_ticks = $mtimeTicks
        attributes = $attributes
    }
}


function Assert-I1RestoreStableRegularFileBinding {
    param(
        [Parameter(Mandatory = $true)]$Binding,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $current = Get-I1RestoreStableRegularFileBinding `
        -Path ([string]$Binding.canonical_path) `
        -BoundaryRoot ([string]$Binding.boundary_root) `
        -WorkspaceRoot $WorkspaceRoot `
        -Label $Label
    foreach ($property in @(
        "canonical_path",
        "boundary_root",
        "relative_path",
        "sha256",
        "length",
        "mtime_ticks",
        "attributes"
    )) {
        if ([string]$current.$property -cne [string]$Binding.$property) {
            throw "$Label binding changed before proof publication: $property"
        }
    }
}


function Assert-I1RestoreJsonProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($null -eq $Object.PSObject.Properties[$Name]) {
        throw "$Label is missing required property: $Name"
    }
}


function ConvertTo-I1RestoreInt64 {
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


function ConvertTo-I1RestoreUtcTimestamp {
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
    return $timestamp
}


function Assert-I1RestoreRelativePath {
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


function Get-I1RestoreArchiveIndexBinding {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $indexPath = Get-I0CanonicalPath -Path (
        Join-Path $ArchiveRoot "index.json"
    )
    $indexSidecarPath = Get-I0CanonicalPath -Path (
        Join-Path $ArchiveRoot "index.sha256"
    )
    $indexBinding = Get-I1RestoreStableRegularFileBinding `
        -Path $indexPath `
        -BoundaryRoot $ArchiveRoot `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive index"
    $sidecarBinding = Get-I1RestoreStableRegularFileBinding `
        -Path $indexSidecarPath `
        -BoundaryRoot $ArchiveRoot `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive index SHA-256 sidecar"

    $sidecarBytes = [System.IO.File]::ReadAllBytes($indexSidecarPath)
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $sidecarText = $strictUtf8.GetString($sidecarBytes)
    }
    catch {
        throw "Archive index SHA-256 sidecar is not strict UTF-8: $indexSidecarPath"
    }
    if ($sidecarText -notmatch '\A(?<sha>[0-9A-F]{64})  index\.json\n\z') {
        throw "Archive index SHA-256 sidecar has an invalid canonical format: $indexSidecarPath"
    }
    if ([string]$Matches.sha -cne [string]$indexBinding.sha256) {
        throw "Archive index SHA-256 sidecar mismatch: $indexSidecarPath"
    }
    Assert-I1RestoreStableRegularFileBinding `
        -Binding $indexBinding `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive index"
    Assert-I1RestoreStableRegularFileBinding `
        -Binding $sidecarBinding `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive index SHA-256 sidecar"

    return [pscustomobject][ordered]@{
        archive_root = Get-I0CanonicalPath -Path $ArchiveRoot
        index = $indexBinding
        sidecar = $sidecarBinding
    }
}


function Assert-I1RestoreArchiveIndexBinding {
    param(
        [Parameter(Mandatory = $true)]$Binding,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $resolvedArchiveRoot = Get-I0CanonicalPath -Path $ArchiveRoot
    if (-not [string]::Equals(
        [string]$Binding.archive_root,
        $resolvedArchiveRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Archive index binding refers to a different archive root"
    }
    Assert-I1RestoreStableRegularFileBinding `
        -Binding $Binding.index `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive index"
    Assert-I1RestoreStableRegularFileBinding `
        -Binding $Binding.sidecar `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive index SHA-256 sidecar"

    $expectedSidecar = (
        "{0}  index.json`n" -f [string]$Binding.index.sha256
    )
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $actualSidecar = $strictUtf8.GetString(
        [System.IO.File]::ReadAllBytes([string]$Binding.sidecar.canonical_path)
    )
    if ($actualSidecar -cne $expectedSidecar) {
        throw "Archive index SHA-256 sidecar changed before proof publication"
    }
}


function Get-I1RestoreToolBindings {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$RestoreToolPath
    )

    $expectedRestoreToolPath = Get-I0CanonicalPath -Path (
        Join-Path $PSScriptRoot "restore_i1_worktree_archive.ps1"
    )
    $invokedRestoreToolPath = Get-I0CanonicalPath -Path $RestoreToolPath
    if (-not [string]::Equals(
        $invokedRestoreToolPath,
        $expectedRestoreToolPath,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Restore tool path does not match the executing script"
    }

    return [pscustomobject][ordered]@{
        verifier = Get-I1RestoreStableRegularFileBinding `
            -Path (Join-Path $PSScriptRoot "verify_i1_snapshot_archive.ps1") `
            -BoundaryRoot $RepoRoot `
            -WorkspaceRoot $WorkspaceRoot `
            -Label "archive verifier tool"
        archive = Get-I1RestoreStableRegularFileBinding `
            -Path (Join-Path $PSScriptRoot "archive_i1_worktrees.ps1") `
            -BoundaryRoot $RepoRoot `
            -WorkspaceRoot $WorkspaceRoot `
            -Label "archive creation tool"
        restore = Get-I1RestoreStableRegularFileBinding `
            -Path $invokedRestoreToolPath `
            -BoundaryRoot $RepoRoot `
            -WorkspaceRoot $WorkspaceRoot `
            -Label "restore tool"
        i0_test_lib = Get-I1RestoreStableRegularFileBinding `
            -Path (Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1") `
            -BoundaryRoot $RepoRoot `
            -WorkspaceRoot $WorkspaceRoot `
            -Label "I0 test library"
    }
}


function Assert-I1RestoreToolBindings {
    param(
        [Parameter(Mandatory = $true)]$Bindings,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    foreach ($name in @("verifier", "archive", "restore", "i0_test_lib")) {
        Assert-I1RestoreStableRegularFileBinding `
            -Binding $Bindings.$name `
            -WorkspaceRoot $WorkspaceRoot `
            -Label "bound $name tool"
    }
}


function Get-I1RestoreEnvironmentBinding {
    return [pscustomobject][ordered]@{
        powershell_edition = [string]$PSVersionTable.PSEdition
        powershell_version = [string]$PSVersionTable.PSVersion
        clr_version = [string]$PSVersionTable.CLRVersion
        os_version = [string][System.Environment]::OSVersion.VersionString
        os_platform = [string][System.Environment]::OSVersion.Platform
        os_service_pack = [string][System.Environment]::OSVersion.ServicePack
        is_64_bit_operating_system = [bool][System.Environment]::Is64BitOperatingSystem
        is_64_bit_process = [bool][System.Environment]::Is64BitProcess
    }
}


function Get-I1RestoreObjectPath {
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


function Assert-I1RestoreObject {
    param(
        [Parameter(Mandatory = $true)][string]$ObjectPath,
        [Parameter(Mandatory = $true)][string]$Sha256,
        [Parameter(Mandatory = $true)][int64]$Length,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot
    )

    Assert-I0PathWithin -Path $ObjectPath -Root $ArchiveRoot -Label "archive object"
    Assert-I1RestoreRegularFile `
        -Path $ObjectPath `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive object"
    $before = Get-Item -LiteralPath $ObjectPath -Force
    if ([int64]$before.Length -ne $Length) {
        throw "Archive object length mismatch: $ObjectPath"
    }
    $mtimeTicks = [int64]$before.LastWriteTimeUtc.Ticks
    $attributes = [int64]$before.Attributes
    $actualSha = Get-I1RestoreSha256 -Path $ObjectPath
    $after = Get-Item -LiteralPath $ObjectPath -Force
    if ([int64]$after.Length -ne $Length -or
        [int64]$after.LastWriteTimeUtc.Ticks -ne $mtimeTicks -or
        [int64]$after.Attributes -ne $attributes) {
        throw "Archive object changed while it was being verified: $ObjectPath"
    }
    Assert-I1RestoreNoAlternateDataStreams -Path $ObjectPath
    if (-not [string]::Equals($actualSha, $Sha256, [System.StringComparison]::Ordinal)) {
        throw "Archive object SHA-256 mismatch: $ObjectPath"
    }
}


function Get-I1RestoreManifestSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$ManifestPath,
        [Parameter(Mandatory = $true)][string]$ManifestShaPath,
        [Parameter(Mandatory = $true)][string]$ExpectedNamespace,
        [Parameter(Mandatory = $true)][string]$ExpectedRunId,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    Assert-I0PathWithin -Path $ManifestPath -Root $ArchiveRoot -Label "archive manifest"
    Assert-I0PathWithin -Path $ManifestShaPath -Root $ArchiveRoot -Label "manifest SHA-256 sidecar"
    Assert-I1RestoreRegularFile `
        -Path $ManifestPath `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "archive manifest"
    Assert-I1RestoreRegularFile `
        -Path $ManifestShaPath `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "manifest SHA-256 sidecar"

    $manifestBytes = [System.IO.File]::ReadAllBytes($ManifestPath)
    $manifestSha256 = Get-I1RestoreBytesSha256 -Bytes $manifestBytes
    $sidecarBytes = [System.IO.File]::ReadAllBytes($ManifestShaPath)
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $sidecarText = $strictUtf8.GetString($sidecarBytes)
    }
    catch {
        throw "Manifest SHA-256 sidecar is not strict UTF-8: $ManifestShaPath"
    }
    if ($sidecarText -notmatch '\A(?<sha>[0-9A-F]{64})  manifest\.json\n\z') {
        throw "Manifest SHA-256 sidecar has an invalid canonical format: $ManifestShaPath"
    }
    if (-not [string]::Equals(
        [string]$Matches.sha,
        $manifestSha256,
        [System.StringComparison]::Ordinal
    )) {
        throw "Manifest SHA-256 sidecar mismatch: $ManifestShaPath"
    }

    try {
        $manifestText = $strictUtf8.GetString($manifestBytes)
        $manifest = $manifestText | ConvertFrom-Json
    }
    catch {
        throw "Archive manifest is not strict UTF-8 JSON: $ManifestPath"
    }
    if ($null -eq $manifest -or $manifest -is [array]) {
        throw "Archive manifest root must be a JSON object: $ManifestPath"
    }
    foreach ($property in @("schema_version", "namespace", "run_id", "files")) {
        Assert-I1RestoreJsonProperty `
            -Object $manifest `
            -Name $property `
            -Label "archive manifest"
    }
    $schemaVersion = ConvertTo-I1RestoreInt64 `
        -Value $manifest.schema_version `
        -Label "manifest.schema_version" `
        -Minimum 1 `
        -Maximum 1
    if ($schemaVersion -ne 1) {
        throw "Unsupported archive manifest schema: $schemaVersion"
    }
    if ([string]$manifest.namespace -cne $ExpectedNamespace) {
        throw "Archive manifest namespace mismatch. expected=$ExpectedNamespace actual=$($manifest.namespace)"
    }
    if ([string]$manifest.run_id -cne $ExpectedRunId) {
        throw "Archive manifest run_id mismatch. expected=$ExpectedRunId actual=$($manifest.run_id)"
    }

    $records = New-Object System.Collections.Generic.List[object]
    $paths = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $filePaths = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $previousPath = $null
    foreach ($record in @($manifest.files)) {
        if ($null -eq $record -or $record -is [array]) {
            throw "Archive manifest contains a non-object file record"
        }
        foreach ($property in @("path", "sha256", "length", "mtime_utc", "attributes")) {
            Assert-I1RestoreJsonProperty `
                -Object $record `
                -Name $property `
                -Label "manifest file record"
        }
        if ($record.path -isnot [string]) {
            throw "manifest file path must be a string"
        }
        $relativePath = [string]$record.path
        Assert-I1RestoreRelativePath -Path $relativePath -Label "manifest file path"
        if (-not $paths.Add($relativePath)) {
            throw "Duplicate case-insensitive path in archive manifest: $relativePath"
        }
        if ($null -ne $previousPath -and
            [System.StringComparer]::Ordinal.Compare([string]$previousPath, $relativePath) -ge 0) {
            throw "Archive manifest file paths are not in strict ordinal order: $relativePath"
        }
        $previousPath = $relativePath

        if ($record.sha256 -isnot [string] -or
            [string]$record.sha256 -notmatch '^[0-9A-F]{64}$') {
            throw "Invalid manifest file SHA-256: $($record.sha256)"
        }
        $length = ConvertTo-I1RestoreInt64 `
            -Value $record.length `
            -Label "manifest file length"
        $attributes = ConvertTo-I1RestoreInt64 `
            -Value $record.attributes `
            -Label "manifest file attributes" `
            -Maximum ([int64][int]::MaxValue)
        $fileAttributes = [System.IO.FileAttributes][int]$attributes
        if (($fileAttributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 -or
            ($fileAttributes -band [System.IO.FileAttributes]::Directory) -ne 0 -or
            ($fileAttributes -band [System.IO.FileAttributes]::Device) -ne 0) {
            throw "Manifest file attributes describe a forbidden entry: $relativePath"
        }
        $mtime = ConvertTo-I1RestoreUtcTimestamp `
            -Value $record.mtime_utc `
            -Label "manifest file mtime_utc"

        [void]$records.Add([pscustomobject][ordered]@{
            path = $relativePath
            sha256 = [string]$record.sha256
            length = $length
            mtime_utc = [string]$record.mtime_utc
            mtime_value = $mtime
            attributes = $attributes
        })
        [void]$filePaths.Add($relativePath)
    }

    foreach ($record in $records) {
        $segments = @(([string]$record.path).Split('/'))
        if ($segments.Count -lt 2) {
            continue
        }
        $prefix = ""
        for ($index = 0; $index -lt ($segments.Count - 1); $index++) {
            $prefix = if ($index -eq 0) {
                [string]$segments[$index]
            }
            else {
                "$prefix/$($segments[$index])"
            }
            if ($filePaths.Contains($prefix)) {
                throw "Manifest file path is also used as a parent directory: $prefix"
            }
        }
    }

    [int64]$logicalBytes = 0
    $lengthByHash = @{}
    foreach ($record in $records) {
        $logicalBytes += [int64]$record.length
        $sha256 = [string]$record.sha256
        if ($lengthByHash.ContainsKey($sha256)) {
            if ([int64]$lengthByHash[$sha256] -ne [int64]$record.length) {
                throw "SHA-256 collision with different lengths in archive manifest: $sha256"
            }
        }
        else {
            $lengthByHash[$sha256] = [int64]$record.length
        }
    }

    [string[]]$uniqueHashes = @($lengthByHash.Keys | ForEach-Object { [string]$_ })
    [System.Array]::Sort($uniqueHashes, [System.StringComparer]::Ordinal)
    foreach ($sha256 in $uniqueHashes) {
        $objectPath = Get-I1RestoreObjectPath `
            -ArchiveRoot $ArchiveRoot `
            -Sha256 $sha256
        Assert-I1RestoreObject `
            -ObjectPath $objectPath `
            -Sha256 $sha256 `
            -Length ([int64]$lengthByHash[$sha256]) `
            -WorkspaceRoot $WorkspaceRoot `
            -ArchiveRoot $ArchiveRoot
    }

    Assert-I1RestoreNoAlternateDataStreams -Path $ManifestPath
    Assert-I1RestoreNoAlternateDataStreams -Path $ManifestShaPath
    $manifestShaAfter = Get-I1RestoreBytesSha256 `
        -Bytes ([System.IO.File]::ReadAllBytes($ManifestPath))
    if ($manifestShaAfter -cne $manifestSha256) {
        throw "Archive manifest changed while its objects were being verified: $ManifestPath"
    }
    $sidecarBytesAfter = [System.IO.File]::ReadAllBytes($ManifestShaPath)
    if (-not (Test-I1RestoreByteArrayEqual -Left $sidecarBytesAfter -Right $sidecarBytes)) {
        throw "Manifest SHA-256 sidecar changed while objects were being verified: $ManifestShaPath"
    }

    return [pscustomobject][ordered]@{
        manifest = $manifest
        manifest_sha256 = $manifestSha256
        records = $records.ToArray()
        file_count = $records.Count
        logical_bytes = $logicalBytes
        unique_hashes = $uniqueHashes
        unique_object_count = $uniqueHashes.Count
    }
}


function Get-I1RestoreStableFileRecord {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    Assert-I1RestoreRegularFile `
        -Path $Path `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "restored file"
    $before = Get-Item -LiteralPath $Path -Force
    $length = [int64]$before.Length
    $mtimeTicks = [int64]$before.LastWriteTimeUtc.Ticks
    $attributes = [int64]$before.Attributes
    $sha256 = Get-I1RestoreSha256 -Path $Path
    $after = Get-Item -LiteralPath $Path -Force
    if ([int64]$after.Length -ne $length -or
        [int64]$after.LastWriteTimeUtc.Ticks -ne $mtimeTicks -or
        [int64]$after.Attributes -ne $attributes) {
        throw "Restored file changed while it was being verified: $Path"
    }
    Assert-I1RestoreNoAlternateDataStreams -Path $Path

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


function Assert-I1RestoredFileMatches {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Expected,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $actual = Get-I1RestoreStableFileRecord `
        -Path $Path `
        -RelativePath ([string]$Expected.path) `
        -WorkspaceRoot $WorkspaceRoot
    foreach ($property in @("path", "sha256", "length", "mtime_utc", "attributes")) {
        if ([string]$actual.$property -cne [string]$Expected.$property) {
            throw "Restored file mismatch. path=$($Expected.path) property=$property"
        }
    }
}


function Get-I1RestoreTreeInventory {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $treeRoot = Get-I0CanonicalPath -Path $Root
    if (-not (Test-Path -LiteralPath $treeRoot -PathType Container)) {
        throw "Restored snapshot directory is missing: $treeRoot"
    }
    Assert-I0NoReparseExistingAncestor `
        -Path $treeRoot `
        -Root $WorkspaceRoot `
        -Label "restored snapshot directory"
    $rootItem = Get-Item -LiteralPath $treeRoot -Force
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Restored snapshot root is a reparse point: $treeRoot"
    }

    $pending = New-Object System.Collections.Stack
    $pending.Push($treeRoot)
    $paths = @{}
    while ($pending.Count -gt 0) {
        $directory = [string]$pending.Pop()
        foreach ($entry in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
            $entryPath = Get-I0CanonicalPath -Path $entry.FullName
            Assert-I0PathWithin `
                -Path $entryPath `
                -Root $treeRoot `
                -Label "restored tree entry"
            if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Restored tree contains a reparse point: $entryPath"
            }
            if (($entry.Attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
                $pending.Push($entryPath)
                continue
            }
            $relativePath = (Get-I0RelativePath -Path $entryPath -Root $treeRoot).Replace('\', '/')
            Assert-I1RestoreRelativePath -Path $relativePath -Label "restored file path"
            if ($paths.ContainsKey($relativePath)) {
                throw "Duplicate case-insensitive file in restored tree: $relativePath"
            }
            $paths[$relativePath] = $entryPath
        }
    }

    [string[]]$relativePaths = @($paths.Keys | ForEach-Object { [string]$_ })
    [System.Array]::Sort($relativePaths, [System.StringComparer]::Ordinal)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($relativePath in $relativePaths) {
        [void]$records.Add((Get-I1RestoreStableFileRecord `
            -Path ([string]$paths[$relativePath]) `
            -RelativePath $relativePath `
            -WorkspaceRoot $WorkspaceRoot))
    }
    return $records.ToArray()
}


function Assert-I1RestoreTreeMatches {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][object[]]$ExpectedRecords,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $actualRecords = @(Get-I1RestoreTreeInventory `
        -Root $Root `
        -WorkspaceRoot $WorkspaceRoot)
    if ($actualRecords.Count -ne $ExpectedRecords.Count) {
        throw "Restored snapshot file count mismatch: $Root"
    }
    for ($index = 0; $index -lt $ExpectedRecords.Count; $index++) {
        $expected = $ExpectedRecords[$index]
        $actual = $actualRecords[$index]
        foreach ($property in @("path", "sha256", "length", "mtime_utc", "attributes")) {
            if ([string]$actual.$property -cne [string]$expected.$property) {
                throw "Restored snapshot mismatch. path=$($expected.path) property=$property"
            }
        }
    }
}


function Remove-I1RestoredDirectorySafely {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExpectedPath,
        [Parameter(Mandatory = $true)][string]$AllowedRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    $resolvedPath = Get-I0CanonicalPath -Path $Path
    $resolvedExpected = Get-I0CanonicalPath -Path $ExpectedPath
    $resolvedAllowedRoot = Get-I0CanonicalPath -Path $AllowedRoot
    if (-not [string]::Equals(
        $resolvedPath,
        $resolvedExpected,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Restored-directory removal target does not match its exact expected path"
    }
    Assert-I0PathWithin `
        -Path $resolvedPath `
        -Root $resolvedAllowedRoot `
        -Label "restored-directory removal target"
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
        throw "Restored-directory removal target is missing: $resolvedPath"
    }
    Assert-I0NoReparseExistingAncestor `
        -Path $resolvedPath `
        -Root $WorkspaceRoot `
        -Label "restored-directory removal target"
    Assert-I0TreeHasNoReparseEntries `
        -Root $resolvedPath `
        -Label "restored-directory removal target"

    Remove-Item -LiteralPath $resolvedPath -Recurse -Force
    if (Test-Path -LiteralPath $resolvedPath) {
        throw "Restored-directory removal did not complete: $resolvedPath"
    }
    if (-not (Test-Path -LiteralPath $resolvedAllowedRoot -PathType Container)) {
        throw "Allowed restore staging root disappeared during removal: $resolvedAllowedRoot"
    }
    Assert-I0NoReparseExistingAncestor `
        -Path $resolvedAllowedRoot `
        -Root $WorkspaceRoot `
        -Label "restore staging root after removal"
    Assert-I0PathWithin `
        -Path $resolvedPath `
        -Root $resolvedAllowedRoot `
        -Label "removed restored-directory path"
}


function Write-I1RestoreImmutableFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot
    )

    Assert-I0PathWithin -Path $Path -Root $ArchiveRoot -Label "restore proof file"
    Assert-I0NoReparseExistingAncestor `
        -Path $Path `
        -Root $WorkspaceRoot `
        -Label "restore proof file"
    if (Test-Path -LiteralPath $Path) {
        Assert-I1RestoreRegularFile `
            -Path $Path `
            -WorkspaceRoot $WorkspaceRoot `
            -Label "restore proof file"
        $existing = [System.IO.File]::ReadAllBytes($Path)
        if (-not (Test-I1RestoreByteArrayEqual -Left $existing -Right $Bytes)) {
            throw "Immutable restore proof already exists with different content: $Path"
        }
        return
    }

    $directory = Get-I0CanonicalPath -Path (Split-Path -Parent $Path)
    Assert-I0PathWithin -Path $directory -Root $ArchiveRoot -Label "restore proof directory"
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "restore proof directory"
    [void](New-Item -ItemType Directory -Path $directory -Force)
    Assert-I0NoReparseExistingAncestor `
        -Path $directory `
        -Root $WorkspaceRoot `
        -Label "restore proof directory"

    $temporaryPath = Get-I0CanonicalPath -Path (Join-Path $directory (
        ".{0}.tmp.{1}.{2}" -f
        ([System.IO.Path]::GetFileName($Path)),
        $PID,
        ([guid]::NewGuid().ToString("N"))
    ))
    Assert-I0PathWithin -Path $temporaryPath -Root $directory -Label "restore proof temporary file"
    try {
        [System.IO.File]::WriteAllBytes($temporaryPath, $Bytes)
        Assert-I1RestoreNoAlternateDataStreams -Path $temporaryPath
        try {
            Move-Item -LiteralPath $temporaryPath -Destination $Path -ErrorAction Stop
        }
        catch {
            if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
                throw
            }
            $existing = [System.IO.File]::ReadAllBytes($Path)
            if (-not (Test-I1RestoreByteArrayEqual -Left $existing -Right $Bytes)) {
                throw "Concurrent immutable restore proof has different content: $Path"
            }
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
    Assert-I1RestoreRegularFile `
        -Path $Path `
        -WorkspaceRoot $WorkspaceRoot `
        -Label "restore proof file"
    $actual = [System.IO.File]::ReadAllBytes($Path)
    if (-not (Test-I1RestoreByteArrayEqual -Left $actual -Right $Bytes)) {
        throw "Restore proof bytes changed after atomic publication: $Path"
    }
}


function Write-I1RestoreProof {
    param(
        [Parameter(Mandatory = $true)][string]$ArchiveRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)]$IndexBinding,
        [Parameter(Mandatory = $true)]$ToolBindings,
        [Parameter(Mandatory = $true)]$EnvironmentBinding,
        [Parameter(Mandatory = $true)][string]$Namespace,
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$ManifestSha256,
        [Parameter(Mandatory = $true)][int]$FileCount,
        [Parameter(Mandatory = $true)][int64]$LogicalBytes,
        [Parameter(Mandatory = $true)][int]$UniqueObjectCount,
        [Parameter(Mandatory = $true)][string]$RestoreRoot,
        [Parameter(Mandatory = $true)][string]$PlannedRestorePath,
        [Parameter(Mandatory = $true)][string]$IsolatedRestoreRoot,
        [Parameter(Mandatory = $true)][bool]$RestoredRemovedAfterVerify,
        [Parameter(Mandatory = $true)][int]$RestoredVerificationPasses,
        [Parameter(Mandatory = $true)][string[]]$VerificationSequence,
        [Parameter(Mandatory = $true)][bool]$ApplyRequested
    )

    if (-not $ApplyRequested) {
        throw "A restore proof may only be published after a real -Apply restore"
    }
    if ($RestoredVerificationPasses -ne 2 -or
        $VerificationSequence.Count -ne 2) {
        throw "A restore proof requires exactly two completed full-tree verification passes"
    }
    Assert-I1RestoreArchiveIndexBinding `
        -Binding $IndexBinding `
        -ArchiveRoot $ArchiveRoot `
        -WorkspaceRoot $WorkspaceRoot
    Assert-I1RestoreToolBindings `
        -Bindings $ToolBindings `
        -WorkspaceRoot $WorkspaceRoot

    $resolvedRestoreRoot = Get-I0CanonicalPath -Path $RestoreRoot
    $resolvedPlannedRestorePath = Get-I0CanonicalPath -Path $PlannedRestorePath
    $resolvedIsolatedRestoreRoot = Get-I0CanonicalPath -Path $IsolatedRestoreRoot
    Assert-I0PathWithin `
        -Path $resolvedPlannedRestorePath `
        -Root $resolvedRestoreRoot `
        -Label "planned restored snapshot"
    Assert-I0PathWithin `
        -Path $resolvedIsolatedRestoreRoot `
        -Root $resolvedRestoreRoot `
        -Label "isolated restore root"

    $proofRoot = Get-I0CanonicalPath -Path (Join-Path $ArchiveRoot (
        "restore_proofs\{0}\{1}" -f $Namespace, $RunId
    ))
    Assert-I0PathWithin -Path $proofRoot -Root $ArchiveRoot -Label "restore proof root"
    $proofStem = "{0}.{1}.{2}.v2" -f
        $ManifestSha256,
        [string]$IndexBinding.index.sha256,
        [string]$ToolBindings.restore.sha256
    $proofPath = Get-I0CanonicalPath -Path (
        Join-Path $proofRoot "$proofStem.json"
    )
    $proofShaPath = Get-I0CanonicalPath -Path (
        Join-Path $proofRoot "$proofStem.sha256"
    )
    $proof = [pscustomobject][ordered]@{
        schema_version = 2
        archive_root = Get-I0CanonicalPath -Path $ArchiveRoot
        index_sha256 = [string]$IndexBinding.index.sha256
        index_sidecar = [pscustomobject][ordered]@{
            path = [string]$IndexBinding.sidecar.relative_path
            sha256 = [string]$IndexBinding.sidecar.sha256
            canonical_format_verified = $true
        }
        namespace = $Namespace
        run_id = $RunId
        manifest_sha256 = $ManifestSha256
        file_count = $FileCount
        logical_bytes = $LogicalBytes
        unique_object_count = $UniqueObjectCount
        tool_sha256 = [pscustomobject][ordered]@{
            verifier = [string]$ToolBindings.verifier.sha256
            archive = [string]$ToolBindings.archive.sha256
            restore = [string]$ToolBindings.restore.sha256
            i0_test_lib = [string]$ToolBindings.i0_test_lib.sha256
        }
        tool_files = [pscustomobject][ordered]@{
            verifier = [pscustomobject][ordered]@{
                path = [string]$ToolBindings.verifier.relative_path
                length = [int64]$ToolBindings.verifier.length
            }
            archive = [pscustomobject][ordered]@{
                path = [string]$ToolBindings.archive.relative_path
                length = [int64]$ToolBindings.archive.length
            }
            restore = [pscustomobject][ordered]@{
                path = [string]$ToolBindings.restore.relative_path
                length = [int64]$ToolBindings.restore.length
            }
            i0_test_lib = [pscustomobject][ordered]@{
                path = [string]$ToolBindings.i0_test_lib.relative_path
                length = [int64]$ToolBindings.i0_test_lib.length
            }
        }
        environment = $EnvironmentBinding
        restore_boundary = [pscustomobject][ordered]@{
            restore_root = $resolvedRestoreRoot
            planned_restore_path = $resolvedPlannedRestorePath
            isolated_restore_root = $resolvedIsolatedRestoreRoot
            restored_removed_after_verify = $RestoredRemovedAfterVerify
        }
        verification = [pscustomobject][ordered]@{
            real_apply_restore_completed = $true
            archive_index_sidecar_sha256 = $true
            manifest_sidecar_sha256 = $true
            object_length_and_sha256 = $true
            tool_files_regular_no_reparse_no_ads = $true
            copy_method = "System.IO.File.Copy"
            hardlinks_used_for_restore = $false
            restored_path_length_sha256_mtime_attributes = $true
            restored_verification_passes = $RestoredVerificationPasses
            verification_sequence = @($VerificationSequence)
            restore_boundary_enforced = $true
        }
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    $proofBytes = $encoding.GetBytes(($proof | ConvertTo-Json -Depth 10 -Compress))
    $proofSha256 = Get-I1RestoreBytesSha256 -Bytes $proofBytes
    $proofFileName = [System.IO.Path]::GetFileName($proofPath)
    $proofShaBytes = $encoding.GetBytes("$proofSha256  $proofFileName`n")

    Write-I1RestoreImmutableFile `
        -Path $proofPath `
        -Bytes $proofBytes `
        -ArchiveRoot $ArchiveRoot `
        -WorkspaceRoot $WorkspaceRoot
    Write-I1RestoreImmutableFile `
        -Path $proofShaPath `
        -Bytes $proofShaBytes `
        -ArchiveRoot $ArchiveRoot `
        -WorkspaceRoot $WorkspaceRoot

    $actualProofBytes = [System.IO.File]::ReadAllBytes($proofPath)
    if ((Get-I1RestoreBytesSha256 -Bytes $actualProofBytes) -cne $proofSha256) {
        throw "Restore proof SHA-256 verification failed: $proofPath"
    }
    $actualSidecar = [System.IO.File]::ReadAllBytes($proofShaPath)
    if (-not (Test-I1RestoreByteArrayEqual -Left $actualSidecar -Right $proofShaBytes)) {
        throw "Restore proof SHA-256 sidecar verification failed: $proofShaPath"
    }

    return [pscustomobject][ordered]@{
        proof_path = $proofPath
        proof_sha256_path = $proofShaPath
        proof_sha256 = $proofSha256
    }
}


$mode = if ($Apply) {
    if ($RemoveRestoredAfterVerify) {
        "apply_remove_restored_after_verify"
    }
    else {
        "apply"
    }
}
else {
    "dry_run"
}
$result = $null
$exitCode = 0
$mutationMayHaveOccurred = $false
$restoredRemovalPerformed = $false

try {
    if ($PSVersionTable.PSEdition -cne "Desktop" -or
        $PSVersionTable.PSVersion.Major -ne 5 -or
        $PSVersionTable.PSVersion.Minor -lt 1) {
        throw "I1 snapshot restore requires Windows PowerShell 5.1 Desktop"
    }
    if ($RemoveRestoredAfterVerify -and -not $Apply) {
        throw "-RemoveRestoredAfterVerify requires -Apply"
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
        throw "Restore script is not running from the selected Git worktree"
    }
    $commonResult = Invoke-I0Git `
        -RepoRoot $resolvedRepo `
        -Arguments @("rev-parse", "--path-format=absolute", "--git-common-dir")
    $gitCommon = Get-I0CanonicalPath -Path (
        Normalize-I0ProcessText -Text $commonResult.stdout
    )
    $workspaceRoot = Get-I1RestoreWorkspaceRoot `
        -RepoRoot $resolvedRepo `
        -GitCommon $gitCommon
    [void](Set-I0WorkspaceRoot -Path $workspaceRoot)
    Assert-I0PathWithin `
        -Path $resolvedRepo `
        -Root $workspaceRoot `
        -AllowRoot `
        -Label "selected Git worktree"

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
    $archiveIndexBinding = Get-I1RestoreArchiveIndexBinding `
        -ArchiveRoot $resolvedArchiveRoot `
        -WorkspaceRoot $workspaceRoot
    $toolBindings = Get-I1RestoreToolBindings `
        -RepoRoot $resolvedRepo `
        -WorkspaceRoot $workspaceRoot `
        -RestoreToolPath $PSCommandPath
    $environmentBinding = Get-I1RestoreEnvironmentBinding

    $restoreRoot = Get-I0CanonicalPath -Path (
        Join-Path $workspaceRoot ".tmp\i1_snapshot_restore"
    )
    $expectedRestoreRoot = Get-I0CanonicalPath -Path (
        Join-Path $workspaceRoot ".tmp\i1_snapshot_restore"
    )
    if (-not [string]::Equals(
        $restoreRoot,
        $expectedRestoreRoot,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        throw "Restore root does not match the exact workspace restore root"
    }
    Assert-I0NoReparseExistingAncestor `
        -Path $restoreRoot `
        -Root $workspaceRoot `
        -Label "restore root"

    Assert-I1RestoreLeafName -Value $Namespace -Label "Namespace"
    $seenRunIds = New-Object "System.Collections.Generic.HashSet[string]" (
        [System.StringComparer]::OrdinalIgnoreCase
    )
    [string[]]$requestedRunIds = @($RunId | ForEach-Object {
        Assert-I1RestoreLeafName -Value ([string]$_) -Label "RunId"
        if (-not $seenRunIds.Add([string]$_)) {
            throw "Duplicate RunId: $_"
        }
        [string]$_
    })
    if ($requestedRunIds.Count -eq 0) {
        throw "At least one RunId is required"
    }
    [System.Array]::Sort($requestedRunIds, [System.StringComparer]::Ordinal)

    if ($Apply) {
        $mutationMayHaveOccurred = $true
        [void](New-Item -ItemType Directory -Path $restoreRoot -Force)
        Assert-I0NoReparseExistingAncestor `
            -Path $restoreRoot `
            -Root $workspaceRoot `
            -Label "restore root"
    }

    $snapshotResults = New-Object System.Collections.Generic.List[object]
    foreach ($requestedRunId in $requestedRunIds) {
        $snapshotRoot = Get-I0CanonicalPath -Path (Join-Path $resolvedArchiveRoot (
            "snapshots\{0}\{1}" -f $Namespace, $requestedRunId
        ))
        Assert-I0PathWithin -Path $snapshotRoot -Root $resolvedArchiveRoot -Label "archive snapshot"
        Assert-I0NoReparseExistingAncestor `
            -Path $snapshotRoot `
            -Root $workspaceRoot `
            -Label "archive snapshot"
        $manifestPath = Get-I0CanonicalPath -Path (Join-Path $snapshotRoot "manifest.json")
        $manifestShaPath = Get-I0CanonicalPath -Path (Join-Path $snapshotRoot "manifest.sha256")
        $snapshot = Get-I1RestoreManifestSnapshot `
            -ManifestPath $manifestPath `
            -ManifestShaPath $manifestShaPath `
            -ExpectedNamespace $Namespace `
            -ExpectedRunId $requestedRunId `
            -ArchiveRoot $resolvedArchiveRoot `
            -WorkspaceRoot $workspaceRoot

        $finalRestorePath = Get-I0CanonicalPath -Path (Join-Path $restoreRoot (
            "{0}\{1}\{2}" -f
            $Namespace,
            $requestedRunId,
            $snapshot.manifest_sha256
        ))
        Assert-I0PathWithin -Path $finalRestorePath -Root $restoreRoot -Label "final restored snapshot"
        Assert-I0NoReparseExistingAncestor `
            -Path $finalRestorePath `
            -Root $workspaceRoot `
            -Label "final restored snapshot"
        if (Test-Path -LiteralPath $finalRestorePath) {
            throw "Final restored snapshot path already exists; refusing overwrite: $finalRestorePath"
        }

        $proofRoot = Get-I0CanonicalPath -Path (Join-Path $resolvedArchiveRoot (
            "restore_proofs\{0}\{1}" -f $Namespace, $requestedRunId
        ))
        $plannedProofStem = "{0}.{1}.{2}.v2" -f
            [string]$snapshot.manifest_sha256,
            [string]$archiveIndexBinding.index.sha256,
            [string]$toolBindings.restore.sha256
        $plannedProofPath = Get-I0CanonicalPath -Path (
            Join-Path $proofRoot "$plannedProofStem.json"
        )
        $plannedProofShaPath = Get-I0CanonicalPath -Path (
            Join-Path $proofRoot "$plannedProofStem.sha256"
        )
        $restoredPath = $null
        $restoredRemoved = $false
        $restoredVerificationPasses = 0
        [string[]]$verificationSequence = @()
        $proofResult = $null

        if ($Apply) {
            $stagingRoot = Get-I0CanonicalPath -Path (Join-Path $restoreRoot (
                ".staging\{0}\{1}" -f $Namespace, $requestedRunId
            ))
            Assert-I0PathWithin -Path $stagingRoot -Root $restoreRoot -Label "restore staging root"
            Assert-I0NoReparseExistingAncestor `
                -Path $stagingRoot `
                -Root $workspaceRoot `
                -Label "restore staging root"
            [void](New-Item -ItemType Directory -Path $stagingRoot -Force)
            Assert-I0NoReparseExistingAncestor `
                -Path $stagingRoot `
                -Root $workspaceRoot `
                -Label "restore staging root"

            $stagingPath = Get-I0CanonicalPath -Path (Join-Path $stagingRoot (
                "{0}.{1}.{2}" -f
                $snapshot.manifest_sha256,
                $PID,
                ([guid]::NewGuid().ToString("N"))
            ))
            Assert-I0PathWithin -Path $stagingPath -Root $stagingRoot -Label "isolated restore directory"
            if (Test-Path -LiteralPath $stagingPath) {
                throw "Isolated restore directory already exists: $stagingPath"
            }

            try {
                [void](New-Item -ItemType Directory -Path $stagingPath)
                Assert-I0NoReparseExistingAncestor `
                    -Path $stagingPath `
                    -Root $workspaceRoot `
                    -Label "isolated restore directory"

                foreach ($record in $snapshot.records) {
                    $relativeNative = ([string]$record.path).Replace('/', '\')
                    $destination = Get-I0CanonicalPath -Path (
                        Join-Path $stagingPath $relativeNative
                    )
                    Assert-I0PathWithin `
                        -Path $destination `
                        -Root $stagingPath `
                        -Label "restored file destination"
                    $roundTripRelative = (
                        Get-I0RelativePath -Path $destination -Root $stagingPath
                    ).Replace('\', '/')
                    if ($roundTripRelative -cne [string]$record.path) {
                        throw "Manifest path changes after Windows path normalization: $($record.path)"
                    }
                    Assert-I0NoReparseExistingAncestor `
                        -Path $destination `
                        -Root $workspaceRoot `
                        -Label "restored file destination"
                    if (Test-Path -LiteralPath $destination) {
                        throw "Restored file destination already exists: $destination"
                    }

                    $destinationParent = Get-I0CanonicalPath -Path (
                        Split-Path -Parent $destination
                    )
                    Assert-I0PathWithin `
                        -Path $destinationParent `
                        -Root $stagingPath `
                        -AllowRoot `
                        -Label "restored file directory"
                    Assert-I0NoReparseExistingAncestor `
                        -Path $destinationParent `
                        -Root $workspaceRoot `
                        -Label "restored file directory"
                    [void](New-Item -ItemType Directory -Path $destinationParent -Force)
                    Assert-I0NoReparseExistingAncestor `
                        -Path $destinationParent `
                        -Root $workspaceRoot `
                        -Label "restored file directory"

                    $objectPath = Get-I1RestoreObjectPath `
                        -ArchiveRoot $resolvedArchiveRoot `
                        -Sha256 ([string]$record.sha256)
                    Assert-I1RestoreObject `
                        -ObjectPath $objectPath `
                        -Sha256 ([string]$record.sha256) `
                        -Length ([int64]$record.length) `
                        -WorkspaceRoot $workspaceRoot `
                        -ArchiveRoot $resolvedArchiveRoot
                    [System.IO.File]::Copy($objectPath, $destination, $false)
                    [System.IO.File]::SetAttributes(
                        $destination,
                        [System.IO.FileAttributes]::Normal
                    )
                    [System.IO.File]::SetLastWriteTimeUtc(
                        $destination,
                        [datetime]$record.mtime_value
                    )
                    [System.IO.File]::SetAttributes(
                        $destination,
                        [System.IO.FileAttributes][int][int64]$record.attributes
                    )

                    Assert-I1RestoredFileMatches `
                        -Path $destination `
                        -Expected $record `
                        -WorkspaceRoot $workspaceRoot
                }

                Assert-I1RestoreTreeMatches `
                    -Root $stagingPath `
                    -ExpectedRecords $snapshot.records `
                    -WorkspaceRoot $workspaceRoot
                $restoredVerificationPasses++

                if ($RemoveRestoredAfterVerify) {
                    Assert-I1RestoreTreeMatches `
                        -Root $stagingPath `
                        -ExpectedRecords $snapshot.records `
                        -WorkspaceRoot $workspaceRoot
                    $restoredVerificationPasses++
                    [string[]]$verificationSequence = @(
                        "isolated_staging_tree",
                        "isolated_staging_tree"
                    )
                    Remove-I1RestoredDirectorySafely `
                        -Path $stagingPath `
                        -ExpectedPath $stagingPath `
                        -AllowedRoot $stagingRoot `
                        -WorkspaceRoot $workspaceRoot
                    $restoredRemovalPerformed = $true
                    $restoredRemoved = $true
                    $stagingPath = $null
                }
                else {
                    $finalParent = Get-I0CanonicalPath -Path (
                        Split-Path -Parent $finalRestorePath
                    )
                    Assert-I0PathWithin `
                        -Path $finalParent `
                        -Root $restoreRoot `
                        -Label "final restore parent"
                    Assert-I0NoReparseExistingAncestor `
                        -Path $finalParent `
                        -Root $workspaceRoot `
                        -Label "final restore parent"
                    [void](New-Item -ItemType Directory -Path $finalParent -Force)
                    Assert-I0NoReparseExistingAncestor `
                        -Path $finalParent `
                        -Root $workspaceRoot `
                        -Label "final restore parent"
                    if (Test-Path -LiteralPath $finalRestorePath) {
                        throw "Final restored snapshot path appeared during restore: $finalRestorePath"
                    }
                    [System.IO.Directory]::Move($stagingPath, $finalRestorePath)
                    $stagingPath = $null
                    Assert-I1RestoreTreeMatches `
                        -Root $finalRestorePath `
                        -ExpectedRecords $snapshot.records `
                        -WorkspaceRoot $workspaceRoot
                    $restoredVerificationPasses++
                    [string[]]$verificationSequence = @(
                        "isolated_staging_tree",
                        "published_final_tree"
                    )
                    $restoredPath = $finalRestorePath
                }

                $proofResult = Write-I1RestoreProof `
                    -ArchiveRoot $resolvedArchiveRoot `
                    -WorkspaceRoot $workspaceRoot `
                    -IndexBinding $archiveIndexBinding `
                    -ToolBindings $toolBindings `
                    -EnvironmentBinding $environmentBinding `
                    -Namespace $Namespace `
                    -RunId $requestedRunId `
                    -ManifestSha256 $snapshot.manifest_sha256 `
                    -FileCount $snapshot.file_count `
                    -LogicalBytes $snapshot.logical_bytes `
                    -UniqueObjectCount $snapshot.unique_object_count `
                    -RestoreRoot $restoreRoot `
                    -PlannedRestorePath $finalRestorePath `
                    -IsolatedRestoreRoot $stagingRoot `
                    -RestoredRemovedAfterVerify $restoredRemoved `
                    -RestoredVerificationPasses $restoredVerificationPasses `
                    -VerificationSequence $verificationSequence `
                    -ApplyRequested ([bool]$Apply)
            }
            catch {
                $primaryError = $_.Exception.Message
                if ($null -ne $stagingPath -and
                    (Test-Path -LiteralPath $stagingPath -PathType Container)) {
                    try {
                        Remove-I1RestoredDirectorySafely `
                            -Path $stagingPath `
                            -ExpectedPath $stagingPath `
                            -AllowedRoot $stagingRoot `
                            -WorkspaceRoot $workspaceRoot
                    }
                    catch {
                        throw "$primaryError Cleanup of the isolated restore directory also failed: $($_.Exception.Message)"
                    }
                }
                throw $primaryError
            }
        }

        [void]$snapshotResults.Add([pscustomobject][ordered]@{
            run_id = $requestedRunId
            manifest_path = $manifestPath
            manifest_sha256_path = $manifestShaPath
            manifest_sha256 = $snapshot.manifest_sha256
            file_count = $snapshot.file_count
            logical_bytes = $snapshot.logical_bytes
            unique_object_count = $snapshot.unique_object_count
            archive_verified = $true
            archive_index_sha256 = [string]$archiveIndexBinding.index.sha256
            restore_proof_schema_version = 2
            copy_method = if ($Apply) { "System.IO.File.Copy" } else { $null }
            hardlinks_used_for_restore = $false
            restored_verification_passes = $restoredVerificationPasses
            verification_sequence = @($verificationSequence)
            planned_restore_path = $finalRestorePath
            restored_path = $restoredPath
            restored_removed_after_verify = $restoredRemoved
            proof_path = if ($null -ne $proofResult) {
                $proofResult.proof_path
            }
            else {
                $plannedProofPath
            }
            proof_sha256_path = if ($null -ne $proofResult) {
                $proofResult.proof_sha256_path
            }
            else {
                $plannedProofShaPath
            }
            proof_sha256 = if ($null -ne $proofResult) {
                $proofResult.proof_sha256
            }
            else {
                $null
            }
        })
    }

    $result = [pscustomobject][ordered]@{
        schema_version = 1
        status = "PASS"
        mode = $mode
        apply_requested = [bool]$Apply
        mutation_may_have_occurred = $mutationMayHaveOccurred
        restored_removal_performed = $restoredRemovalPerformed
        selected_git_worktree = $resolvedRepo
        git_common_workspace = $workspaceRoot
        namespace = $Namespace
        archive_root = $resolvedArchiveRoot
        archive_index_sha256 = [string]$archiveIndexBinding.index.sha256
        restore_root = $restoreRoot
        restore_proof_schema_version = 2
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
        restored_removal_performed = $restoredRemovalPerformed
        error = $_.Exception.Message
    }
}

Write-Output ("I1_SNAPSHOT_RESTORE_JSON=" + ($result | ConvertTo-Json -Depth 20 -Compress))
exit $exitCode
