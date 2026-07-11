[CmdletBinding()]
param(
    [string]$WorkspaceRoot = 'D:\AGAME1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$ApprovedWorkspaceRoot = [IO.Path]::GetFullPath('D:\AGAME1').TrimEnd('\')

function Stop-I0 {
    param([string]$Message)
    throw "[I0.1 STOP] $Message"
}

function Get-FullPath {
    param([string]$Path)
    return [IO.Path]::GetFullPath($Path).TrimEnd('\')
}

function Assert-UnderWorkspace {
    param([string]$Path, [string]$Label)
    $full = Get-FullPath $Path
    if ($full -eq $script:WorkspaceFull) {
        return $full
    }
    if (-not $full.StartsWith($script:WorkspaceFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
        Stop-I0 "$Label escaped workspace: $full"
    }
    return $full
}

function Assert-SafeLeafName {
    param([string]$Value, [string]$Label)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Stop-I0 "$Label is empty"
    }
    if ([IO.Path]::IsPathRooted($Value) -or $Value -eq '.' -or $Value -eq '..') {
        Stop-I0 "$Label is not a safe leaf name: $Value"
    }
    if ($Value -ne [IO.Path]::GetFileName($Value) -or $Value.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        Stop-I0 "$Label contains a path separator, ADS marker, or invalid filename character: $Value"
    }
    if ($Value.EndsWith('.', [StringComparison]::Ordinal) -or $Value.EndsWith(' ', [StringComparison]::Ordinal)) {
        Stop-I0 "$Label has a Windows-ambiguous trailing character: $Value"
    }
    $deviceStem = $Value.Split('.')[0]
    if ($deviceStem -match '^(?i:CON|PRN|AUX|NUL|CLOCK\$|CONIN\$|CONOUT\$|COM[1-9]|LPT[1-9])$') {
        Stop-I0 "$Label is a reserved Windows device name: $Value"
    }
    return $Value
}

function Get-DirectChildPath {
    param([string]$Parent, [string]$Leaf, [string]$Label)
    $parentFull = Assert-UnderWorkspace $Parent "$Label parent"
    $safeLeaf = Assert-SafeLeafName $Leaf $Label
    $childFull = Get-FullPath (Join-Path $parentFull $safeLeaf)
    if ((Split-Path -Parent $childFull).TrimEnd('\') -ne $parentFull.TrimEnd('\')) {
        Stop-I0 "$Label did not resolve as a direct child of $parentFull"
    }
    return (Assert-UnderWorkspace $childFull $Label)
}

function Assert-NoReparseExisting {
    param([string]$Path, [string]$Label)
    $full = Assert-UnderWorkspace $Path $Label
    $cursor = $full
    while (-not (Test-Path -LiteralPath $cursor)) {
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) {
            Stop-I0 "$Label has no existing in-workspace ancestor: $full"
        }
        $cursor = $parent
    }
    while ($true) {
        $item = Get-Item -LiteralPath $cursor -Force
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Stop-I0 "$Label crosses reparse point: $cursor"
        }
        if ($cursor -eq $script:WorkspaceFull) {
            break
        }
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or -not $parent.StartsWith($script:WorkspaceFull, [StringComparison]::OrdinalIgnoreCase)) {
            Stop-I0 "$Label ancestor escaped workspace: $cursor"
        }
        $cursor = $parent.TrimEnd('\')
    }
    return $full
}

function New-SafeDirectory {
    param([string]$Path, [string]$Label)
    $full = Assert-NoReparseExisting $Path $Label
    if (Test-Path -LiteralPath $full) {
        $item = Get-Item -LiteralPath $full -Force
        if (-not $item.PSIsContainer) {
            Stop-I0 "$Label exists but is not a directory: $full"
        }
        return $full
    }
    New-Item -ItemType Directory -Path $full | Out-Null
    return (Assert-NoReparseExisting $full $Label)
}

function Assert-ExpectedFile {
    param(
        [string]$Path,
        [long]$ExpectedSize,
        [string]$ExpectedSha256,
        [string]$Label
    )
    $full = Assert-NoReparseExisting $Path $Label
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Stop-I0 "$Label is missing: $full"
    }
    $item = Get-Item -LiteralPath $full -Force
    if ($item.Length -ne $ExpectedSize) {
        Stop-I0 "$Label size mismatch: $($item.Length)"
    }
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash.ToLowerInvariant()
    if ($hash -ne $ExpectedSha256.ToLowerInvariant()) {
        Stop-I0 "$Label SHA-256 mismatch: $hash"
    }
    return $hash
}

function New-ControlledProcessEnvironment {
    param([string]$InstallRoot)
    $environmentRoot = Get-DirectChildPath $InstallRoot 'process-env' 'Process environment root'
    $null = New-SafeDirectory $environmentRoot 'Process environment root'
    foreach ($name in @('temp', 'appdata', 'localappdata')) {
        $null = New-SafeDirectory (Get-DirectChildPath $environmentRoot $name "Process environment $name") "Process environment $name"
    }
    return $environmentRoot
}

function Use-ControlledProcessEnvironment {
    param([string]$EnvironmentRoot)
    $root = Assert-NoReparseExisting $EnvironmentRoot 'Process environment root'
    foreach ($name in @('temp', 'appdata', 'localappdata')) {
        $path = Get-DirectChildPath $root $name "Process environment $name"
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            Stop-I0 "Process environment directory is missing: $path"
        }
        $null = Assert-NoReparseExisting $path "Process environment $name"
    }
    [Environment]::SetEnvironmentVariable('TEMP', (Join-Path $root 'temp'), 'Process')
    [Environment]::SetEnvironmentVariable('TMP', (Join-Path $root 'temp'), 'Process')
    [Environment]::SetEnvironmentVariable('APPDATA', (Join-Path $root 'appdata'), 'Process')
    [Environment]::SetEnvironmentVariable('LOCALAPPDATA', (Join-Path $root 'localappdata'), 'Process')
}

function Restore-ProcessEnvironment {
    param([hashtable]$Original)
    foreach ($name in @('TEMP', 'TMP', 'APPDATA', 'LOCALAPPDATA')) {
        [Environment]::SetEnvironmentVariable($name, $Original[$name], 'Process')
    }
}

function Invoke-NativeChecked {
    param([string]$Exe, [string[]]$Arguments)
    $priorErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $Exe @Arguments 2>&1)
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $priorErrorAction
    }
    if ($code -ne 0) {
        Stop-I0 "$Exe exited $code`n$($output -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { $_.ToString() })
}

function Invoke-DownloadNoCache {
    param([string]$Uri, [string]$Destination)
    $destinationFull = Assert-NoReparseExisting $Destination 'Download destination'
    if (Test-Path -LiteralPath $destinationFull) {
        Stop-I0 "Download destination already exists: $destinationFull"
    }
    $request = [Net.HttpWebRequest]::Create($Uri)
    $request.Method = 'GET'
    $request.UserAgent = 'AGAME1-I0-Toolchain'
    $request.AllowAutoRedirect = $true
    $request.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy ([System.Net.Cache.RequestCacheLevel]::BypassCache)
    $response = $null
    $sourceStream = $null
    $targetStream = $null
    try {
        $response = $request.GetResponse()
        $sourceStream = $response.GetResponseStream()
        $targetStream = [IO.File]::Open($destinationFull, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $sourceStream.CopyTo($targetStream)
        $targetStream.Flush()
    }
    finally {
        if ($null -ne $targetStream) { $targetStream.Dispose() }
        if ($null -ne $sourceStream) { $sourceStream.Dispose() }
        if ($null -ne $response) { $response.Dispose() }
    }
}

function Write-Utf8CreateNew {
    param([string]$Path, [string]$Content, [string]$Label)
    $full = Assert-NoReparseExisting $Path $Label
    $bytes = $Utf8NoBom.GetBytes($Content)
    $stream = $null
    try {
        $stream = [IO.File]::Open($full, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
    }
    finally {
        if ($null -ne $stream) { $stream.Dispose() }
    }
}

function Assert-Archive {
    param([string]$Path, [object]$Spec)
    $full = Assert-NoReparseExisting $Path 'Godot archive'
    $null = Assert-ExpectedFile $full ([long]$Spec.archive_size_bytes) ([string]$Spec.archive_sha256) 'Godot archive'
    return $full
}

function Assert-ZipContract {
    param([string]$Archive, [string]$ExtractRoot, [object]$Spec)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $extractFull = Get-FullPath $ExtractRoot
    $expected = @([string]$Spec.executable, [string]$Spec.console_executable)
    $actual = @()
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        foreach ($entry in $zip.Entries) {
            $relative = $entry.FullName.Replace('/', '\')
            if ([string]::IsNullOrEmpty($entry.Name) -or $relative -ne $entry.Name) {
                Stop-I0 "Godot ZIP contains a directory or non-root member: $($entry.FullName)"
            }
            $destination = [IO.Path]::GetFullPath((Join-Path $extractFull $relative))
            if (-not $destination.StartsWith($extractFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
                Stop-I0 "ZIP entry escaped extraction root: $($entry.FullName)"
            }
            $actual += $relative
        }
    }
    finally {
        $zip.Dispose()
    }
    $delta = @(Compare-Object -CaseSensitive -ReferenceObject ($expected | Sort-Object -CaseSensitive) -DifferenceObject ($actual | Sort-Object -CaseSensitive))
    if ($actual.Count -ne $expected.Count -or $delta.Count -ne 0) {
        Stop-I0 "Unexpected Godot ZIP members: $($actual -join ', ')"
    }
}

function Get-ExpectedSignature {
    param(
        [string]$Path,
        [object]$Spec,
        [long]$ExpectedSize,
        [string]$ExpectedSha256,
        [string]$Label
    )
    $null = Assert-ExpectedFile $Path $ExpectedSize $ExpectedSha256 $Label
    $signature = Get-AuthenticodeSignature -LiteralPath $Path
    $status = $signature.Status.ToString()
    $message = [string]$signature.StatusMessage
    $isValid = $signature.Status -eq [System.Management.Automation.SignatureStatus]::Valid
    $isExpectedUntrustedRoot = (
        [bool]$Spec.allow_untrusted_root_chain_status -and
        $signature.Status -eq [System.Management.Automation.SignatureStatus]::UnknownError -and
        $message.IndexOf([string]$Spec.untrusted_root_message_contains, [StringComparison]::OrdinalIgnoreCase) -ge 0
    )
    if (-not $isValid -and -not $isExpectedUntrustedRoot) {
        Stop-I0 "Unexpected Authenticode status for ${Path}: $status / $message"
    }
    if ($signature.SignatureType.ToString() -ne [string]$Spec.signature_type) {
        Stop-I0 "Unexpected signature type for ${Path}: $($signature.SignatureType)"
    }
    if ($null -eq $signature.SignerCertificate) {
        Stop-I0 "Authenticode signer certificate is absent for $Path"
    }
    $subject = [string]$signature.SignerCertificate.Subject
    $signerThumbprint = ([string]$signature.SignerCertificate.Thumbprint).ToLowerInvariant()
    $signerSerial = ([string]$signature.SignerCertificate.SerialNumber).ToLowerInvariant()
    if ($subject -ne [string]$Spec.signer_subject) {
        Stop-I0 "Unexpected Authenticode signer for ${Path}: $subject"
    }
    if ($signerThumbprint -ne ([string]$Spec.signer_thumbprint_sha1).ToLowerInvariant()) {
        Stop-I0 "Unexpected Authenticode signer thumbprint for ${Path}: $signerThumbprint"
    }
    if ($signerSerial -ne ([string]$Spec.signer_serial_hex).ToLowerInvariant()) {
        Stop-I0 "Unexpected Authenticode signer serial for ${Path}: $signerSerial"
    }
    if ([bool]$Spec.timestamp_certificate_required -and $null -eq $signature.TimeStamperCertificate) {
        Stop-I0 "Authenticode timestamp certificate is absent for $Path"
    }
    $timestamperSubject = if ($null -ne $signature.TimeStamperCertificate) { [string]$signature.TimeStamperCertificate.Subject } else { $null }
    $timestamperThumbprint = if ($null -ne $signature.TimeStamperCertificate) { ([string]$signature.TimeStamperCertificate.Thumbprint).ToLowerInvariant() } else { $null }
    $timestamperSerial = if ($null -ne $signature.TimeStamperCertificate) { ([string]$signature.TimeStamperCertificate.SerialNumber).ToLowerInvariant() } else { $null }
    if ($timestamperSubject -ne [string]$Spec.timestamper_subject -or $timestamperThumbprint -ne ([string]$Spec.timestamper_thumbprint_sha1).ToLowerInvariant() -or $timestamperSerial -ne ([string]$Spec.timestamper_serial_hex).ToLowerInvariant()) {
        Stop-I0 "Unexpected Authenticode timestamper certificate for $Path"
    }
    $classification = if ($isValid) { 'SYSTEM_TRUSTED' } else { 'CHAIN_UNTRUSTED_RECORDED' }
    return [pscustomobject]@{
        signature_type = [string]$signature.SignatureType
        system_status = $status
        system_status_message = $message
        system_chain_trusted = $isValid
        verification_classification = $classification
        signer_subject = $subject
        signer_thumbprint_sha1 = $signerThumbprint
        signer_serial_hex = $signerSerial
        signer_issuer = [string]$signature.SignerCertificate.Issuer
        signer_not_before = $signature.SignerCertificate.NotBefore.ToUniversalTime().ToString('o')
        signer_not_after = $signature.SignerCertificate.NotAfter.ToUniversalTime().ToString('o')
        timestamper_subject = $timestamperSubject
        timestamper_thumbprint_sha1 = $timestamperThumbprint
        timestamper_serial_hex = $timestamperSerial
        byte_integrity_sha256 = $ExpectedSha256.ToLowerInvariant()
    }
}

function Test-GodotInstall {
    param([string]$InstallRoot, [object]$Spec)
    $root = Assert-NoReparseExisting $InstallRoot 'Godot install'
    if (-not (Test-Path -LiteralPath $root -PathType Container)) {
        Stop-I0 "Godot install directory missing: $root"
    }
    $manifestPath = Get-DirectChildPath $root 'install-manifest.json' 'Godot install manifest'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Stop-I0 "Godot install manifest missing: $manifestPath"
    }
    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    if ([int]$manifest.schema_version -ne 2 -or [string]$manifest.stage -ne 'I0.1') {
        Stop-I0 'Installed Godot manifest schema or stage differs from I0.1 lock'
    }
    if ([string]$manifest.version -ne [string]$Spec.version) {
        Stop-I0 'Installed Godot version identity differs from lock'
    }
    if ([string]$manifest.archive_sha256 -ne [string]$Spec.archive_sha256) {
        Stop-I0 'Installed Godot archive identity differs from lock'
    }
    if ([string]$manifest.main_exe_sha256 -ne [string]$Spec.executable_sha256 -or [string]$manifest.console_exe_sha256 -ne [string]$Spec.console_executable_sha256) {
        Stop-I0 'Installed Godot manifest executable identity differs from lock'
    }
    $mainExe = Get-DirectChildPath $root ([string]$Spec.executable) 'Installed Godot executable'
    $consoleExe = Get-DirectChildPath $root ([string]$Spec.console_executable) 'Installed Godot console executable'
    $marker = Get-DirectChildPath $root ([string]$Spec.self_contained_marker) 'Godot self-contained marker'
    foreach ($path in @($mainExe, $consoleExe, $marker)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Stop-I0 "Installed Godot file missing: $path"
        }
    }
    if ((Get-Item -LiteralPath $marker).Length -ne 0) {
        Stop-I0 'Godot _sc_ marker is not zero bytes'
    }
    $mainHash = Assert-ExpectedFile $mainExe ([long]$Spec.executable_size_bytes) ([string]$Spec.executable_sha256) 'Installed Godot executable'
    $consoleHash = Assert-ExpectedFile $consoleExe ([long]$Spec.console_executable_size_bytes) ([string]$Spec.console_executable_sha256) 'Installed Godot console executable'
    $mainSignature = Get-ExpectedSignature $mainExe $Spec ([long]$Spec.executable_size_bytes) ([string]$Spec.executable_sha256) 'Installed Godot executable'
    $consoleSignature = Get-ExpectedSignature $consoleExe $Spec ([long]$Spec.console_executable_size_bytes) ([string]$Spec.console_executable_sha256) 'Installed Godot console executable'
    $versionLines = @(Invoke-NativeChecked $consoleExe @('--version'))
    $version = [string]($versionLines | Select-Object -Last 1)
    if ($version -notmatch [string]$Spec.version_regex) {
        Stop-I0 "Godot version mismatch: $version"
    }
    return [pscustomobject]@{
        root = $root
        main_exe = $mainExe
        console_exe = $consoleExe
        main_exe_sha256 = $mainHash
        console_exe_sha256 = $consoleHash
        main_signature = $mainSignature
        console_signature = $consoleSignature
        version_output = $version
        manifest = $manifestPath
    }
}

$WorkspaceFull = Get-FullPath $WorkspaceRoot
if ($WorkspaceFull -ne $ApprovedWorkspaceRoot) {
    Stop-I0 "Workspace root is outside the immutable I0 authorization boundary: $WorkspaceFull"
}
$ScriptFull = (Resolve-Path -LiteralPath $PSCommandPath).ProviderPath
if (-not $ScriptFull.StartsWith($ApprovedWorkspaceRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    Stop-I0 "Bootstrap script is outside the immutable I0 authorization boundary: $ScriptFull"
}
$LockPath = Join-Path $PSScriptRoot 'toolchain.lock.json'
if (-not (Test-Path -LiteralPath $LockPath -PathType Leaf)) {
    Stop-I0 "Toolchain lock missing: $LockPath"
}
$Lock = Get-Content -Raw -Encoding UTF8 -LiteralPath $LockPath | ConvertFrom-Json
if ([int]$Lock.schema_version -ne 2 -or [string]$Lock.stage -ne 'I0.1') {
    Stop-I0 'Toolchain lock schema or stage is unsupported'
}
if ([string]$Lock.runtime_root -ne 'tools\runtimes') {
    Stop-I0 "Toolchain runtime root is not the approved project-local path: $($Lock.runtime_root)"
}
$null = Assert-SafeLeafName ([string]$Lock.godot.version) 'Godot version directory'
$null = Assert-SafeLeafName ([string]$Lock.godot.archive_filename) 'Godot archive filename'
$null = Assert-SafeLeafName ([string]$Lock.godot.executable) 'Godot executable filename'
$null = Assert-SafeLeafName ([string]$Lock.godot.console_executable) 'Godot console executable filename'
$null = Assert-SafeLeafName ([string]$Lock.godot.self_contained_marker) 'Godot self-contained marker filename'
if ([string]$Lock.godot.executable -eq [string]$Lock.godot.console_executable) {
    Stop-I0 'Godot executable filenames must be distinct'
}

$ExpectedWorkspace = Get-FullPath ([string]$Lock.workspace_root)
if ($ExpectedWorkspace -ne $ApprovedWorkspaceRoot -or $WorkspaceFull -ne $ExpectedWorkspace) {
    Stop-I0 "Lock and requested workspace must both resolve exactly to $ApprovedWorkspaceRoot"
}
$WorkspaceFull = (Resolve-Path -LiteralPath $WorkspaceFull).ProviderPath.TrimEnd('\')
if ($WorkspaceFull -ne $ExpectedWorkspace) {
    Stop-I0 'Workspace root resolution changed'
}
if (((Get-Item -LiteralPath $WorkspaceFull -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
    Stop-I0 'Workspace root is a reparse point'
}

$RepoRoot = Get-FullPath (Join-Path $PSScriptRoot '..\..')
$null = Assert-UnderWorkspace $RepoRoot 'Repo root'
$RuntimeRoot = Get-FullPath (Join-Path $WorkspaceFull ([string]$Lock.runtime_root))
$StagingRoot = Get-FullPath (Join-Path $RuntimeRoot '.staging')
$CacheRoot = Get-FullPath (Join-Path $RuntimeRoot 'cache')
$GodotParent = Get-FullPath (Join-Path $RuntimeRoot 'godot')
$FinalRoot = Get-DirectChildPath $GodotParent ([string]$Lock.godot.version) 'Godot final version directory'
$ReportRoot = Get-FullPath (Join-Path $WorkspaceFull 'reports\i0')
$ReportPath = Get-DirectChildPath $ReportRoot 'I0.1_TOOLCHAIN_CURRENT.json' 'I0.1 toolchain report'
foreach ($path in @($RuntimeRoot, $StagingRoot, $CacheRoot, $GodotParent, $FinalRoot, $ReportRoot, $ReportPath)) {
    $null = Assert-UnderWorkspace $path 'Toolchain target'
}

$OriginalProcessEnvironment = @{}
foreach ($name in @('TEMP', 'TMP', 'APPDATA', 'LOCALAPPDATA')) {
    $OriginalProcessEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}
$OriginalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol

$Verified = $null
$ExecutionMode = $null
$ArchiveMode = $null
try {
    if (Test-Path -LiteralPath $FinalRoot) {
        $ProcessEnv = Get-DirectChildPath $FinalRoot 'process-env' 'Installed process environment root'
        Use-ControlledProcessEnvironment $ProcessEnv
        $Verified = Test-GodotInstall $FinalRoot $Lock.godot
        $ExecutionMode = 'EXISTING_VERIFIED'
        $ArchiveMode = [string](Get-Content -Raw -Encoding UTF8 -LiteralPath $Verified.manifest | ConvertFrom-Json).archive_mode
    }
    else {
        $null = New-SafeDirectory $RuntimeRoot 'Runtime root'
        $null = New-SafeDirectory $StagingRoot 'Staging root'
        $null = New-SafeDirectory $CacheRoot 'Cache root'
        $null = New-SafeDirectory $GodotParent 'Godot parent'
        $Stage = Get-DirectChildPath $StagingRoot ("godot-" + [guid]::NewGuid().ToString('N')) 'Godot staging directory'
        $null = New-SafeDirectory $Stage 'Godot staging directory'

        $CacheArchive = Get-DirectChildPath $CacheRoot ([string]$Lock.godot.archive_filename) 'Cached Godot archive'
        if (Test-Path -LiteralPath $CacheArchive) {
            $Archive = Assert-Archive $CacheArchive $Lock.godot
            $ArchiveMode = 'CACHE_VERIFIED'
        }
        else {
            $Download = Get-DirectChildPath $Stage ([string]$Lock.godot.archive_filename) 'Godot archive download'
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-DownloadNoCache -Uri ([string]$Lock.godot.immutable_url) -Destination $Download
            $Archive = Assert-Archive $Download $Lock.godot
            if (Test-Path -LiteralPath $CacheArchive) {
                Stop-I0 "Cache archive appeared concurrently: $CacheArchive"
            }
            Move-Item -LiteralPath $Archive -Destination $CacheArchive
            $Archive = Assert-Archive $CacheArchive $Lock.godot
            $ArchiveMode = 'DOWNLOADED_AND_VERIFIED'
        }

        $ExtractRoot = Get-DirectChildPath $Stage 'extract' 'Godot extraction root'
        $null = New-SafeDirectory $ExtractRoot 'Godot extraction root'
        Assert-ZipContract $Archive $ExtractRoot $Lock.godot
        Expand-Archive -LiteralPath $Archive -DestinationPath $ExtractRoot
        $MainExe = Get-DirectChildPath $ExtractRoot ([string]$Lock.godot.executable) 'Extracted Godot executable'
        $ConsoleExe = Get-DirectChildPath $ExtractRoot ([string]$Lock.godot.console_executable) 'Extracted Godot console executable'
        $MainHash = Assert-ExpectedFile $MainExe ([long]$Lock.godot.executable_size_bytes) ([string]$Lock.godot.executable_sha256) 'Extracted Godot executable'
        $ConsoleHash = Assert-ExpectedFile $ConsoleExe ([long]$Lock.godot.console_executable_size_bytes) ([string]$Lock.godot.console_executable_sha256) 'Extracted Godot console executable'
        $Marker = Get-DirectChildPath $ExtractRoot ([string]$Lock.godot.self_contained_marker) 'Godot self-contained marker'
        [IO.File]::WriteAllBytes($Marker, [byte[]]@())
        $ProcessEnv = New-ControlledProcessEnvironment $ExtractRoot
        Use-ControlledProcessEnvironment $ProcessEnv

        $MainSignature = Get-ExpectedSignature $MainExe $Lock.godot ([long]$Lock.godot.executable_size_bytes) ([string]$Lock.godot.executable_sha256) 'Extracted Godot executable'
        $ConsoleSignature = Get-ExpectedSignature $ConsoleExe $Lock.godot ([long]$Lock.godot.console_executable_size_bytes) ([string]$Lock.godot.console_executable_sha256) 'Extracted Godot console executable'
        $VersionLines = @(Invoke-NativeChecked $ConsoleExe @('--version'))
        $VersionOutput = [string]($VersionLines | Select-Object -Last 1)
        if ($VersionOutput -notmatch [string]$Lock.godot.version_regex) {
            Stop-I0 "Godot version mismatch after extraction: $VersionOutput"
        }
        $InstallManifest = [ordered]@{
            schema_version = 2
            stage = 'I0.1'
            version = [string]$Lock.godot.version
            archive_filename = [string]$Lock.godot.archive_filename
            archive_size_bytes = [long]$Lock.godot.archive_size_bytes
            archive_sha256 = [string]$Lock.godot.archive_sha256
            archive_url = [string]$Lock.godot.immutable_url
            release_api_url = [string]$Lock.godot.release_api_url
            release_asset_id = [long]$Lock.godot.release_asset_id
            archive_mode = $ArchiveMode
            main_exe_sha256 = $MainHash
            console_exe_sha256 = $ConsoleHash
            main_signature = $MainSignature
            console_signature = $ConsoleSignature
            version_output = $VersionOutput
            self_contained_marker = [string]$Lock.godot.self_contained_marker
            process_environment_root = 'process-env'
            installed_utc = [DateTime]::UtcNow.ToString('o')
        }
        $ManifestPath = Get-DirectChildPath $ExtractRoot 'install-manifest.json' 'Godot install manifest'
        Write-Utf8CreateNew $ManifestPath ($InstallManifest | ConvertTo-Json -Depth 6) 'Godot install manifest'

        if (Test-Path -LiteralPath $FinalRoot) {
            Stop-I0 "Final Godot directory appeared concurrently: $FinalRoot"
        }
        Move-Item -LiteralPath $ExtractRoot -Destination $FinalRoot
        $ProcessEnv = Get-DirectChildPath $FinalRoot 'process-env' 'Installed process environment root'
        Use-ControlledProcessEnvironment $ProcessEnv
        $Verified = Test-GodotInstall $FinalRoot $Lock.godot
        $ExecutionMode = $ArchiveMode
    }

    if ($Verified.main_signature.verification_classification -ne $Verified.console_signature.verification_classification) {
        Stop-I0 'Godot executables produced different Authenticode trust classifications'
    }
    $AuthenticodeClassification = [string]$Verified.main_signature.verification_classification
    $AllowedArchiveModes = [string[]]@('CACHE_VERIFIED', 'DOWNLOADED_AND_VERIFIED')
    if ([Array]::IndexOf($AllowedArchiveModes, $ArchiveMode) -lt 0) {
        Stop-I0 "Godot install manifest contains an unsupported archive mode: $ArchiveMode"
    }
    $OverallResult = if ($AuthenticodeClassification -eq 'SYSTEM_TRUSTED') { 'PASS' } else { 'PASS_WITH_RECORDED_LIMITATION' }
    $Report = [ordered]@{
        schema_version = 2
        stage = 'I0.1'
        result = $OverallResult
        pass_basis = 'OFFICIAL_RELEASE_ARCHIVE_AND_PINNED_EXECUTABLE_INTEGRITY'
        workspace_root = $WorkspaceFull
        repo_root = $RepoRoot
        runtime_root = $RuntimeRoot
        godot_root = $Verified.root
        godot_console = $Verified.console_exe
        godot_version = $Verified.version_output
        archive_integrity = 'PASS'
        archive_sha256 = [string]$Lock.godot.archive_sha256
        archive_release_api_url = [string]$Lock.godot.release_api_url
        archive_release_asset_id = [long]$Lock.godot.release_asset_id
        archive_mode = $ArchiveMode
        executable_integrity = 'PASS'
        main_exe_sha256 = [string]$Verified.main_exe_sha256
        console_exe_sha256 = [string]$Verified.console_exe_sha256
        authenticode_result = $AuthenticodeClassification
        godot_main_signature_system_status = [string]$Verified.main_signature.system_status
        godot_console_signature_system_status = [string]$Verified.console_signature.system_status
        godot_signature_chain_trusted = ($Verified.main_signature.system_chain_trusted -and $Verified.console_signature.system_chain_trusted)
        self_contained = $true
        controlled_process_environment = $true
        external_path_write_requested = $false
        path_or_registry_modified = $false
        completed_utc = [DateTime]::UtcNow.ToString('o')
    }
    if (Test-Path -LiteralPath $ReportPath) {
        $ExistingReport = Get-Content -Raw -Encoding UTF8 -LiteralPath $ReportPath | ConvertFrom-Json
        $ExpectedNames = @($Report.Keys | Sort-Object -CaseSensitive)
        $ActualNames = @($ExistingReport.PSObject.Properties.Name | Sort-Object -CaseSensitive)
        if (@(Compare-Object -CaseSensitive -ReferenceObject $ExpectedNames -DifferenceObject $ActualNames).Count -ne 0) {
            Stop-I0 "Existing I0.1 report field set differs from the current verifier: $ReportPath"
        }
        foreach ($name in $ExpectedNames) {
            if ($name -eq 'completed_utc') {
                $parsedUtc = [DateTime]::MinValue
                if (-not [DateTime]::TryParse([string]$ExistingReport.completed_utc, [ref]$parsedUtc)) {
                    Stop-I0 "Existing I0.1 report has an invalid completion timestamp: $ReportPath"
                }
                continue
            }
            $expectedJson = ConvertTo-Json -Compress -Depth 6 -InputObject $Report[$name]
            $actualJson = ConvertTo-Json -Compress -Depth 6 -InputObject $ExistingReport.$name
            if ($expectedJson -cne $actualJson) {
                Stop-I0 "Existing I0.1 report field '$name' differs from current verification: $ReportPath"
            }
        }
    }
    else {
        $null = New-SafeDirectory $ReportRoot 'I0 report root'
        Write-Utf8CreateNew $ReportPath ($Report | ConvertTo-Json -Depth 6) 'I0.1 toolchain report'
    }
}
finally {
    [Net.ServicePointManager]::SecurityProtocol = $OriginalSecurityProtocol
    Restore-ProcessEnvironment $OriginalProcessEnvironment
}

Write-Host "I0_TOOLCHAIN=$OverallResult"
Write-Host "I0_TOOLCHAIN_MODE=$ExecutionMode"
Write-Host "I0_GODOT_CONSOLE=$($Verified.console_exe)"
Write-Host "I0_GODOT_VERSION=$($Verified.version_output)"
Write-Host "I0_AUTHENTICODE=$AuthenticodeClassification"
Write-Host "I0_TOOLCHAIN_REPORT=$ReportPath"
