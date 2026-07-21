param(
    [ValidateSet("preflight", "quick", "core", "ui", "performance", "full")]
    [string]$Profile = "quick",

    [ValidateSet("worktree", "head")]
    [string]$SourceMode = "worktree",

    [string]$RepoRoot = ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))),

    [string]$GodotExe = "",

    [string]$ManifestPath = (Join-Path $PSScriptRoot "validation_manifest.json")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "..\i0\i0_test_lib.ps1")


function Get-I1DefaultWorkspaceRoot {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $repo = Get-I0CanonicalPath -Path $RepoRoot
    $commonResult = Invoke-I0Git -RepoRoot $repo -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir')
    $gitCommon = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $commonResult.stdout)
    $candidate = $repo
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-I0PathWithin -Path $gitCommon -Root $candidate -AllowRoot) {
            return $candidate
        }
        $parent = Split-Path -Parent $candidate
        if ([string]::IsNullOrWhiteSpace($parent) -or [string]::Equals($parent, $candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $candidate = Get-I0CanonicalPath -Path $parent
    }
    throw "Unable to derive workspace root for repo=$repo git_common=$gitCommon"
}


function ConvertTo-I1ProcessReport {
    param([Parameter(Mandatory = $true)]$ProcessResult)
    return [pscustomobject][ordered]@{
        file_path = $ProcessResult.file_path
        arguments = @($ProcessResult.arguments)
        working_directory = $ProcessResult.working_directory
        exit_code = $ProcessResult.exit_code
        timed_out = $ProcessResult.timed_out
        duration_ms = $ProcessResult.duration_ms
        stdout = Normalize-I0ProcessText -Text $ProcessResult.stdout
        stderr = Normalize-I0ProcessText -Text $ProcessResult.stderr
    }
}


function Get-I1PropertyValue {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $Default
    }
    return $property.Value
}


function Test-I1SameStringSet {
    param([object[]]$Left, [object[]]$Right)
    $leftValues = @($Left | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $rightValues = @($Right | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    return @(Compare-Object -ReferenceObject $leftValues -DifferenceObject $rightValues -CaseSensitive).Count -eq 0
}


function Get-I1FileSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is missing for SHA-256: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}


function Get-I1JsonFileSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "JSON file is missing: $Path"
    }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $algorithm.ComputeHash($bytes)
    }
    finally {
        $algorithm.Dispose()
    }
    $sha256 = -join @($hashBytes | ForEach-Object { $_.ToString('X2') })
    $raw = [System.Text.Encoding]::UTF8.GetString($bytes)
    if ($raw.Length -gt 0 -and $raw[0] -eq [char]0xFEFF) {
        $raw = $raw.Substring(1)
    }
    return [pscustomobject][ordered]@{
        raw = $raw
        sha256 = $sha256
        value = ($raw | ConvertFrom-Json)
    }
}


function Get-I1LogText {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ''
    }
    return Get-Content -LiteralPath $Path -Raw
}


function Get-I1EngineDiagnosticClassification {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [object[]]$ExpectedCleanupDiagnostics = @()
    )
    $cleanup = New-Object System.Collections.Generic.List[string]
    $blocking = New-Object System.Collections.Generic.List[string]
    $missingExpected = New-Object System.Collections.Generic.List[string]
    $expectedValues = @($ExpectedCleanupDiagnostics | ForEach-Object { [string]$_ })
    $acceptedExpected = New-Object System.Collections.Generic.List[string]
    foreach ($expectedValue in $ExpectedCleanupDiagnostics) {
        $expected = [string]$expectedValue
        if (@($acceptedExpected | Where-Object { [string]::Equals([string]$_, $expected, [System.StringComparison]::Ordinal) }).Count -gt 0) {
            throw "Duplicate expected cleanup diagnostic: $expected"
        }
        [void]$acceptedExpected.Add($expected)
    }
    $seen = New-Object System.Collections.Generic.List[string]
    $diagnostics = @([regex]::Matches($Text, '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$') | ForEach-Object { $_.Value.Trim() })
    foreach ($diagnostic in $diagnostics) {
        if (@($seen | Where-Object { [string]::Equals([string]$_, $diagnostic, [System.StringComparison]::Ordinal) }).Count -gt 0) {
            continue
        }
        [void]$seen.Add($diagnostic)
        if (@($expectedValues | Where-Object { [string]::Equals([string]$_, $diagnostic, [System.StringComparison]::Ordinal) }).Count -gt 0) {
            [void]$cleanup.Add($diagnostic)
        }
        else {
            [void]$blocking.Add($diagnostic)
        }
    }
    foreach ($expected in $expectedValues) {
        if (@($seen | Where-Object { [string]::Equals([string]$_, $expected, [System.StringComparison]::Ordinal) }).Count -eq 0) {
            [void]$missingExpected.Add($expected)
        }
    }
    return [pscustomobject][ordered]@{
        expected_cleanup_diagnostics = $expectedValues
        blocking_diagnostics = $blocking.ToArray()
        cleanup_diagnostics = $cleanup.ToArray()
        missing_expected_cleanup_diagnostics = $missingExpected.ToArray()
        cleanup_contract_matches = ($missingExpected.Count -eq 0)
    }
}


function Get-I1ExactLineCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$ExpectedLine
    )
    return @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.Trim() -ceq $ExpectedLine }).Count
}


function Get-I1RegexLineCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Pattern
    )
    return @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { [regex]::IsMatch($_.Trim(), $Pattern) }).Count
}


function Get-I1FailMarkerCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    return @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.Trim().StartsWith($Marker, [System.StringComparison]::Ordinal) }).Count
}


function Get-I1MarkedJson {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    $matchingLines = @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.StartsWith($Marker, [System.StringComparison]::Ordinal) })
    if ($matchingLines.Count -ne 1) {
        throw "Expected exactly one $Marker line, found $($matchingLines.Count)"
    }
    return ($matchingLines[0].Substring($Marker.Length) | ConvertFrom-Json)
}


function Assert-I1MirrorExclusions {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [Parameter(Mandatory = $true)]$Manifest
    )
    foreach ($relativePathValue in @($Manifest.mirror.forbidden_relative_paths)) {
        $relativePath = ([string]$relativePathValue).Replace('/', '\')
        if ([System.IO.Path]::IsPathRooted($relativePath) -or $relativePath -match '(^|\\)\.\.(\\|$)') {
            throw "Unsafe forbidden mirror path: $relativePath"
        }
        $candidate = Get-I0CanonicalPath -Path (Join-Path $MirrorRoot $relativePath)
        Assert-I0PathWithin -Path $candidate -Root $MirrorRoot -Label 'forbidden mirror path'
        if (Test-Path -LiteralPath $candidate) {
            throw "Forbidden source tree was copied into the I1 mirror: $relativePath"
        }
    }
}


function Resolve-I1GodotExecutable {
    param(
        [AllowEmptyString()][string]$ExplicitPath,
        [Parameter(Mandatory = $true)]$Manifest
    )

    $candidate = $null
    $source = $null
    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        $candidate = $ExplicitPath
        $source = 'parameter:GodotExe'
    }
    else {
        foreach ($environmentNameValue in @($Manifest.godot.resolution_env_vars)) {
            $environmentName = [string]$environmentNameValue
            if ($environmentName -notmatch '^[A-Z][A-Z0-9_]+$') {
                throw "Unsafe Godot environment variable name in manifest: $environmentName"
            }
            $environmentValue = [System.Environment]::GetEnvironmentVariable($environmentName)
            if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
                $candidate = $environmentValue
                $source = "environment:$environmentName"
                break
            }
        }
    }
    if ($null -eq $candidate) {
        foreach ($commandNameValue in @($Manifest.godot.path_command_names)) {
            $commandName = [string]$commandNameValue
            if ($commandName -ne [System.IO.Path]::GetFileName($commandName) -or $commandName -match '[:\\/]') {
                throw "Unsafe Godot PATH command name in manifest: $commandName"
            }
            $command = Get-Command $commandName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -ne $command) {
                $candidate = $command.Source
                $source = "PATH:$commandName"
                break
            }
        }
    }
    if ($null -eq $candidate) {
        throw 'Locked Godot was not found. Supply -GodotExe, set I1_GODOT_EXE/GODOT4/GODOT_EXE, or add Godot to PATH.'
    }

    $candidatePath = Get-I0CanonicalPath -Path ([string]$candidate)
    if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        throw "Resolved Godot executable does not exist: source=$source path=$candidatePath"
    }
    $installRoot = Get-I0CanonicalPath -Path (Split-Path -Parent $candidatePath)
    $mainPath = Join-Path $installRoot ([string]$Manifest.godot.main_executable)
    $consolePath = Join-Path $installRoot ([string]$Manifest.godot.console_executable)
    foreach ($path in @($mainPath, $consolePath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Pinned Godot companion executable is missing: $path"
        }
    }
    return [pscustomobject][ordered]@{
        source = $source
        requested_path = $candidatePath
        install_root = $installRoot
        main_executable = $mainPath
        console_executable = $consolePath
    }
}


function New-I1GodotRuntimeLinks {
    param(
        [Parameter(Mandatory = $true)][string]$MainExecutablePath,
        [Parameter(Mandatory = $true)][string]$ConsoleExecutablePath,
        [Parameter(Mandatory = $true)][string]$RunRoot
    )

    $run = Get-I0CanonicalPath -Path $RunRoot
    Assert-I0PathWithin -Path $run -Root $script:I0WorkspaceRoot -Label 'I1 run root'
    Assert-I0NoReparseExistingAncestor -Path $run -Root $script:I0WorkspaceRoot -Label 'I1 run root'
    $engineRoot = Join-Path $run 'engine_without_self_contained_marker'
    if (Test-Path -LiteralPath $engineRoot) {
        throw "Engine link directory already exists: $engineRoot"
    }
    [void](New-Item -ItemType Directory -Path $engineRoot)

    $links = [ordered]@{}
    foreach ($sourcePathValue in @($MainExecutablePath, $ConsoleExecutablePath)) {
        $sourcePath = Get-I0CanonicalPath -Path ([string]$sourcePathValue)
        $name = [System.IO.Path]::GetFileName($sourcePath)
        $target = Join-Path $engineRoot $name
        try {
            [void](New-Item -ItemType HardLink -Path $target -Target $sourcePath)
        }
        catch {
            throw "Unable to create isolated Godot hardlink (source and .tmp/i1 must share a volume): source=$sourcePath target=$target error=$($_.Exception.Message)"
        }
        $sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($sourceHash -cne $targetHash) {
            throw "Godot hardlink byte identity mismatch: $name"
        }
        $links[$name] = [pscustomobject][ordered]@{
            source = $sourcePath
            hardlink = $target
            bytes = (Get-Item -LiteralPath $target).Length
            sha256 = $targetHash
        }
    }
    if (Test-Path -LiteralPath (Join-Path $engineRoot '_sc_')) {
        throw 'Isolated Godot engine directory must not contain _sc_'
    }
    return [pscustomobject][ordered]@{
        engine_root = $engineRoot
        main_executable = $links[[System.IO.Path]::GetFileName($MainExecutablePath)]
        console_executable = $links[[System.IO.Path]::GetFileName($ConsoleExecutablePath)]
        self_contained_marker_present = $false
    }
}


function Get-I1VerifiedToolchainLock {
    param(
        [Parameter(Mandatory = $true)][string]$SnapshotRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)]$ResolvedGodot,
        [Parameter(Mandatory = $true)]$Manifest
    )

    $lockPath = Get-I0CanonicalPath -Path (Join-Path $SnapshotRoot (([string]$Manifest.godot.toolchain_lock_relative_path).Replace('/', '\')))
    Assert-I0PathWithin -Path $lockPath -Root $SnapshotRoot -Label 'toolchain lock'
    Assert-I0NoReparseExistingAncestor -Path $lockPath -Root $WorkspaceRoot -Label 'toolchain lock'
    if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) {
        throw "Locked Godot descriptor is missing: $lockPath"
    }
    $lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
    if ([int]$lock.schema_version -ne 3 -or [string]$lock.stage -cne 'I0.1' -or [string]$lock.path_policy -cne 'runtime_parameter') {
        throw 'Unsupported I0.1 toolchain lock schema or stage'
    }
    if ([string]$lock.godot.version -cne [string]$Manifest.godot.version -or [string]$lock.godot.version_regex -cne [string]$Manifest.godot.version_regex) {
        throw 'Godot version identity differs between the I1 manifest and I0.1 lock'
    }
    if ([string]$lock.godot.executable -cne [string]$Manifest.godot.main_executable -or [string]$lock.godot.console_executable -cne [string]$Manifest.godot.console_executable) {
        throw 'Godot executable names differ between the I1 manifest and I0.1 lock'
    }

    $install = Get-I0CanonicalPath -Path ([string]$ResolvedGodot.install_root)
    $mainPath = Get-I0CanonicalPath -Path ([string]$ResolvedGodot.main_executable)
    $consolePath = Get-I0CanonicalPath -Path ([string]$ResolvedGodot.console_executable)
    $installManifestPath = Join-Path $install 'install-manifest.json'
    foreach ($path in @($mainPath, $consolePath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Godot installed file is missing: $path"
        }
    }

    $mainItem = Get-Item -LiteralPath $mainPath
    $consoleItem = Get-Item -LiteralPath $consolePath
    $mainHash = (Get-FileHash -LiteralPath $mainPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $consoleHash = (Get-FileHash -LiteralPath $consolePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($mainItem.Length -ne [int64]$lock.godot.executable_size_bytes -or $mainHash -cne [string]$lock.godot.executable_sha256) {
        throw 'Installed Godot main executable differs from the I0.1 lock'
    }
    if ($consoleItem.Length -ne [int64]$lock.godot.console_executable_size_bytes -or $consoleHash -cne [string]$lock.godot.console_executable_sha256) {
        throw 'Installed Godot console executable differs from the I0.1 lock'
    }

    $installManifestStatus = 'NOT_PRESENT_NOT_REQUIRED'
    if (Test-Path -LiteralPath $installManifestPath -PathType Leaf) {
        $installManifest = Get-Content -LiteralPath $installManifestPath -Raw | ConvertFrom-Json
        if ([string]$installManifest.version -cne [string]$lock.godot.version -or
            [string]$installManifest.archive_sha256 -cne [string]$lock.godot.archive_sha256 -or
            [string]$installManifest.main_exe_sha256 -cne [string]$lock.godot.executable_sha256 -or
            [string]$installManifest.console_exe_sha256 -cne [string]$lock.godot.console_executable_sha256) {
            throw 'Godot install manifest differs from the I0.1 lock'
        }
        $installManifestStatus = 'PASS'
    }

    return [pscustomobject][ordered]@{
        status = 'PASS'
        resolution_source = [string]$ResolvedGodot.source
        requested_executable = [string]$ResolvedGodot.requested_path
        lock_path = $lockPath
        install_manifest_path = $installManifestPath
        install_manifest_status = $installManifestStatus
        install_root = $install
        version = [string]$lock.godot.version
        version_regex = [string]$lock.godot.version_regex
        archive_sha256 = [string]$lock.godot.archive_sha256
        main_executable = $mainPath
        main_size_bytes = $mainItem.Length
        main_sha256 = $mainHash
        console_executable = $consolePath
        console_size_bytes = $consoleItem.Length
        console_sha256 = $consoleHash
    }
}


if ($PSVersionTable.PSEdition -cne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -lt 1) {
    throw "I1-V1 requires Windows PowerShell 5.1 Desktop; current=$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
}

$requestedRepo = Get-I0CanonicalPath -Path $RepoRoot
$resolvedRepoResult = Invoke-I0Git -RepoRoot $requestedRepo -Arguments @('rev-parse', '--show-toplevel')
$repo = Get-I0CanonicalPath -Path (Normalize-I0ProcessText -Text $resolvedRepoResult.stdout)
if (-not [string]::Equals($requestedRepo, $repo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RepoRoot must be the active Git worktree root: requested=$requestedRepo resolved=$repo"
}
$workspaceRoot = Get-I1DefaultWorkspaceRoot -RepoRoot $repo
[void](Set-I0WorkspaceRoot -Path $workspaceRoot)
Assert-I0PathWithin -Path $repo -Root $workspaceRoot -AllowRoot -Label 'active repo'
Assert-I0NoReparseExistingAncestor -Path $repo -Root $workspaceRoot -Label 'active repo'

$approvedManifestPath = Get-I0CanonicalPath -Path (Join-Path $PSScriptRoot 'validation_manifest.json')
$requestedManifestPath = Get-I0CanonicalPath -Path $ManifestPath
if (-not [string]::Equals($approvedManifestPath, $requestedManifestPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "I1-V1 only accepts its colocated manifest: $approvedManifestPath"
}
Assert-I0NoReparseExistingAncestor -Path $requestedManifestPath -Root $workspaceRoot -Label 'I1 manifest'
$setupManifestSnapshot = Get-I1JsonFileSnapshot -Path $requestedManifestPath
$setupManifestRaw = [string]$setupManifestSnapshot.raw
$setupManifestSha256 = [string]$setupManifestSnapshot.sha256
$setupManifest = $setupManifestSnapshot.value
if ([int]$setupManifest.schema_version -ne 1 -or [string]$setupManifest.suite_id -cne 'I1-V1_unified_headless_baseline' -or [string]$setupManifest.path_policy -cne 'runtime_parameters') {
    throw 'Unsupported I1-V1 manifest schema, suite, or path policy'
}
$approvedExcludedDirectoryNames = @('.git', '.godot', '.tmp', '__pycache__', 'reports', 'runtimes')
$approvedForbiddenRelativePaths = @('.tmp', 'reports', 'tools/runtimes')
$approvedBusinessRoots = @('Godot/GraytailGodot', 'tools')
if ([string]$setupManifest.mirror.run_root_relative_path -cne '.tmp/i1') {
    throw 'I1 setup manifest must use mirror.run_root_relative_path=.tmp/i1'
}
if ([string]$setupManifest.mirror.worktree_directory -cne 'worktree') {
    throw 'I1 setup manifest must use mirror.worktree_directory=worktree'
}
if (-not (Test-I1SameStringSet -Left @($setupManifest.mirror.excluded_directory_names) -Right $approvedExcludedDirectoryNames)) {
    throw 'I1 setup manifest has an unapproved mirror exclusion set'
}
if (-not (Test-I1SameStringSet -Left @($setupManifest.mirror.forbidden_relative_paths) -Right $approvedForbiddenRelativePaths)) {
    throw 'I1 setup manifest has an unapproved forbidden-path set'
}
if (-not (Test-I1SameStringSet -Left @($setupManifest.business_roots) -Right $approvedBusinessRoots)) {
    throw 'I1 setup manifest must hash Godot/GraytailGodot and tools'
}
if ([string]$setupManifest.godot.i0_library_relative_path -cne 'tools/i0/i0_test_lib.ps1') {
    throw 'I1 setup manifest has an unapproved I0 library path'
}

$setupControlPlaneFiles = @(
    [pscustomobject][ordered]@{
        relative_path = '.gitattributes'
        setup_path = Get-I0CanonicalPath -Path (Join-Path $repo '.gitattributes')
        setup_sha256 = Get-I1FileSha256 -Path (Join-Path $repo '.gitattributes')
    },
    [pscustomobject][ordered]@{
        relative_path = 'tools/i1/invoke_i1.ps1'
        setup_path = Get-I0CanonicalPath -Path $PSCommandPath
        setup_sha256 = Get-I1FileSha256 -Path $PSCommandPath
    },
    [pscustomobject][ordered]@{
        relative_path = 'tools/i0/i0_test_lib.ps1'
        setup_path = Get-I0CanonicalPath -Path (Join-Path $repo 'tools\i0\i0_test_lib.ps1')
        setup_sha256 = Get-I1FileSha256 -Path (Join-Path $repo 'tools\i0\i0_test_lib.ps1')
    }
)

$runtimeTempRoot = Get-I0CanonicalPath -Path (Join-Path $repo (([string]$setupManifest.mirror.run_root_relative_path).Replace('/', '\')))
Assert-I0PathWithin -Path $runtimeTempRoot -Root $repo -Label 'I1 runtime temp root'
Assert-I0NoReparseExistingAncestor -Path $runtimeTempRoot -Root $workspaceRoot -Label 'I1 runtime temp root'
$runId = ([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '_' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$runRoot = Get-I0CanonicalPath -Path (Join-Path $runtimeTempRoot $runId)
Assert-I0PathWithin -Path $runRoot -Root $runtimeTempRoot -Label 'I1 run root'
Assert-I0NoReparseExistingAncestor -Path $runRoot -Root $workspaceRoot -Label 'I1 run root'
$mirrorDirectoryName = [string]$setupManifest.mirror.worktree_directory
if ($mirrorDirectoryName -notmatch '^[A-Za-z0-9_.-]+$' -or $mirrorDirectoryName -in @('.', '..')) {
    throw "Unsafe I1 mirror directory name: $mirrorDirectoryName"
}
$mirrorRoot = Get-I0CanonicalPath -Path (Join-Path $runRoot $mirrorDirectoryName)
$logsRoot = Join-Path $runRoot 'logs'
$artifactsRoot = Join-Path $runRoot 'artifacts'
$staticReportPath = Join-Path $artifactsRoot 'static_validation.json'
$reportPath = Join-Path $runRoot 'report.json'
foreach ($path in @($mirrorRoot, $logsRoot, $artifactsRoot, $staticReportPath, $reportPath)) {
    Assert-I0PathWithin -Path $path -Root $runRoot -AllowRoot -Label 'I1 output path'
    Assert-I0NoReparseExistingAncestor -Path $path -Root $workspaceRoot -Label 'I1 output path'
}

$startedUtc = [DateTime]::UtcNow
$phaseTimings = [ordered]@{}
$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$fatalError = $null
$beforeGit = $null
$afterGit = $null
$beforeBusiness = $null
$afterBusiness = $null
$gitPollution = $null
$businessPollution = $null
$pollutionGuardError = $null
$tmpIgnoreCase = $null
$mirrorCase = $null
$mirrorSource = $null
$mirrorFidelity = $null
$executionManifest = $null
$executionManifestPath = $null
$executionManifestSha256 = $null
$manifestHashesMatch = $false
$controlPlaneBindings = @()
$controlPlaneBindingPass = $false
$toolchainVerification = $null
$runtimeLinks = $null
$engineVersionCase = $null
$staticCase = $null
$staticData = $null
$editorBootstrapCase = $null
$environmentCase = $null
$environmentData = $null
$selectedRunnerIds = @()
$runnerCases = New-Object System.Collections.Generic.List[object]
$overallStatus = 'FAIL'

try {
    $gitTimeout = [int]$setupManifest.timeouts_seconds.git_probe
    $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $beforeGit = Get-I0GitSnapshot -RepoRoot $repo -TimeoutSeconds $gitTimeout
    $phaseStopwatch.Stop()
    $phaseTimings['before_git_snapshot'] = [int64]$phaseStopwatch.ElapsedMilliseconds
    $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $beforeBusiness = Get-I0BusinessHashSnapshot -RepoRoot $repo -BusinessRoots @($setupManifest.business_roots) -ExcludedDirectoryNames @($setupManifest.mirror.excluded_directory_names)
    $phaseStopwatch.Stop()
    $phaseTimings['before_business_snapshot'] = [int64]$phaseStopwatch.ElapsedMilliseconds

    $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $ignoreProbe = Invoke-I0Git -RepoRoot $repo -Arguments @('check-ignore', '-q', '--', '.tmp/i1/i1-ignore-probe') -TimeoutSeconds $gitTimeout -AllowFailure
    $phaseStopwatch.Stop()
    $phaseTimings['git_ignore_probe'] = [int64]$phaseStopwatch.ElapsedMilliseconds
    $tmpIgnored = (-not $ignoreProbe.timed_out -and $ignoreProbe.exit_code -eq 0)
    $tmpIgnoreCase = [pscustomobject][ordered]@{
        status = if ($tmpIgnored) { 'PASS' } else { 'FAIL' }
        relative_probe = '.tmp/i1/i1-ignore-probe'
        process = ConvertTo-I1ProcessReport -ProcessResult $ignoreProbe
    }
    if (-not $tmpIgnored) {
        throw '.tmp/i1 is not ignored by Git; the harness would pollute the active worktree'
    }

    if (Test-Path -LiteralPath $runRoot) {
        throw "Generated I1 run root already exists: $runRoot"
    }
    [void](New-Item -ItemType Directory -Path $runRoot)
    [void](New-Item -ItemType Directory -Path $logsRoot)
    [void](New-Item -ItemType Directory -Path $artifactsRoot)

    if ($SourceMode -eq 'worktree') {
        $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $mirrorRaw = Copy-I0WorktreeMirror `
            -SourceRepo $repo `
            -Destination $mirrorRoot `
            -RuntimeTempRoot $runtimeTempRoot `
            -ExcludedDirectoryNames @($setupManifest.mirror.excluded_directory_names) `
            -TimeoutSeconds ([int]$setupManifest.timeouts_seconds.mirror_copy)
        $phaseStopwatch.Stop()
        $phaseTimings['worktree_mirror_copy'] = [int64]$phaseStopwatch.ElapsedMilliseconds
        $mirrorCase = [pscustomobject][ordered]@{
            status = 'PASS'
            mode = 'worktree'
            source_inspection = $mirrorRaw.source_inspection
            destination_inspection_duration_ms = $mirrorRaw.destination_inspection_duration_ms
            total_duration_ms = $mirrorRaw.total_duration_ms
            process = ConvertTo-I1ProcessReport -ProcessResult $mirrorRaw
        }
        $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $mirrorBusiness = Get-I0BusinessHashSnapshot -RepoRoot $mirrorRoot -BusinessRoots @($setupManifest.business_roots) -ExcludedDirectoryNames @($setupManifest.mirror.excluded_directory_names)
        $phaseStopwatch.Stop()
        $phaseTimings['mirror_business_snapshot'] = [int64]$phaseStopwatch.ElapsedMilliseconds
        $mirrorFidelity = Compare-I0BusinessHashSnapshot -Before $beforeBusiness -After $mirrorBusiness
        if (-not $mirrorFidelity.unchanged) {
            throw 'Worktree mirror business hash differs from the active source'
        }
        $mirrorSource = [pscustomobject][ordered]@{
            mode = 'worktree'
            head = $beforeGit.head
            tree = '(worktree mirror)'
            protected_dirty_state_included = $true
        }
    }
    else {
        $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $headMirror = Copy-I0HeadMirror `
            -SourceRepo $repo `
            -Destination $mirrorRoot `
            -RuntimeTempRoot $runtimeTempRoot `
            -TimeoutSeconds ([int]$setupManifest.timeouts_seconds.mirror_copy)
        $phaseStopwatch.Stop()
        $phaseTimings['head_mirror_copy'] = [int64]$phaseStopwatch.ElapsedMilliseconds
        $mirrorCase = [pscustomobject][ordered]@{
            status = 'PASS'
            mode = 'head'
            read_tree_process = ConvertTo-I1ProcessReport -ProcessResult $headMirror.read_tree_process
            checkout_process = ConvertTo-I1ProcessReport -ProcessResult $headMirror.checkout_process
        }
        $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $mirrorBusiness = Get-I0BusinessHashSnapshot -RepoRoot $mirrorRoot -BusinessRoots @($setupManifest.business_roots) -ExcludedDirectoryNames @($setupManifest.mirror.excluded_directory_names)
        $phaseStopwatch.Stop()
        $phaseTimings['mirror_business_snapshot'] = [int64]$phaseStopwatch.ElapsedMilliseconds
        $mirrorFidelity = [pscustomobject][ordered]@{
            unchanged = $true
            method = 'isolated_git_index_checkout'
            source_head = $headMirror.head
            source_tree = $headMirror.tree
            exported_business_file_count = $mirrorBusiness.file_count
            exported_business_fingerprint_sha256 = $mirrorBusiness.fingerprint_sha256
        }
        $mirrorSource = [pscustomobject][ordered]@{
            mode = 'head'
            head = $headMirror.head
            tree = $headMirror.tree
            protected_dirty_state_included = $false
            isolated_index_path = $headMirror.isolated_index_path
        }
    }
    Assert-I1MirrorExclusions -MirrorRoot $mirrorRoot -Manifest $setupManifest

    $executionManifestPath = Join-Path $mirrorRoot 'tools\i1\validation_manifest.json'
    $executionManifestSnapshot = Get-I1JsonFileSnapshot -Path $executionManifestPath
    $executionManifestSha256 = [string]$executionManifestSnapshot.sha256
    $executionManifest = $executionManifestSnapshot.value
    $manifestHashesMatch = [string]::Equals($setupManifestSha256, $executionManifestSha256, [System.StringComparison]::Ordinal)
    if ([int]$executionManifest.schema_version -ne 1 -or [string]$executionManifest.suite_id -cne 'I1-V1_unified_headless_baseline' -or [string]$executionManifest.path_policy -cne 'runtime_parameters') {
        throw 'Mirrored I1 manifest has an unsupported identity'
    }
    if (-not $manifestHashesMatch) {
        $bindingLabel = if ($SourceMode -ceq 'head') { 'HEAD' } else { 'worktree mirror' }
        throw "$bindingLabel manifest binding failed: setup=$setupManifestSha256 execution=$executionManifestSha256"
    }

    $controlPlaneBindings = @($setupControlPlaneFiles | ForEach-Object {
        $executionPath = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot (([string]$_.relative_path).Replace('/', '\')))
        Assert-I0PathWithin -Path $executionPath -Root $mirrorRoot -Label 'mirrored control-plane input'
        $executionSha256 = Get-I1FileSha256 -Path $executionPath
        [pscustomobject][ordered]@{
            relative_path = [string]$_.relative_path
            setup_path = [string]$_.setup_path
            setup_sha256 = [string]$_.setup_sha256
            execution_path = $executionPath
            execution_sha256 = $executionSha256
            hashes_match = [string]::Equals([string]$_.setup_sha256, $executionSha256, [System.StringComparison]::Ordinal)
        }
    })
    $controlPlaneBindingPass = (@($controlPlaneBindings | Where-Object { -not [bool]$_.hashes_match }).Count -eq 0)
    if (-not $controlPlaneBindingPass) {
        $mismatches = @($controlPlaneBindings | Where-Object { -not [bool]$_.hashes_match } | ForEach-Object { [string]$_.relative_path })
        throw ("{0} control-plane binding failed: {1}" -f $SourceMode, ($mismatches -join ', '))
    }

    $staticScript = Join-Path $mirrorRoot 'tools\i1\validate_static.ps1'
    $staticEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId 'static_validation'
    $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $staticRaw = Invoke-I0Process `
        -FilePath $windowsPowerShell `
        -Arguments @(
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy', 'Bypass',
            '-File', $staticScript,
            '-RepoRoot', $mirrorRoot,
            '-GitRepoRoot', $repo,
            '-SourceMode', $SourceMode,
            '-ManifestPath', $executionManifestPath,
            '-ExpectedManifestSha256', $executionManifestSha256,
            '-ReportPath', $staticReportPath
        ) `
        -WorkingDirectory $mirrorRoot `
        -Environment $staticEnvironment `
        -TimeoutSeconds ([int]$executionManifest.timeouts_seconds.static_validation)
    $phaseStopwatch.Stop()
    $phaseTimings['static_validation'] = [int64]$phaseStopwatch.ElapsedMilliseconds
    if (Test-Path -LiteralPath $staticReportPath -PathType Leaf) {
        $staticData = Get-Content -LiteralPath $staticReportPath -Raw | ConvertFrom-Json
    }
    $staticPass = (-not $staticRaw.timed_out -and $staticRaw.exit_code -eq 0 -and $null -ne $staticData -and [string]$staticData.status -ceq 'PASS')
    $staticCase = [pscustomobject][ordered]@{
        status = if ($staticPass) { 'PASS' } else { 'FAIL' }
        process = ConvertTo-I1ProcessReport -ProcessResult $staticRaw
        result = $staticData
    }
    if (-not $staticPass) {
        throw 'I1 static registration and inventory validation failed'
    }

    $profileProperty = $executionManifest.profiles.PSObject.Properties[$Profile]
    if ($null -eq $profileProperty) {
        throw "Profile is not registered in the mirrored manifest: $Profile"
    }
    $selectedRunnerIds = @($profileProperty.Value.runner_ids | ForEach-Object { [string]$_ })

    $resolvedGodot = Resolve-I1GodotExecutable -ExplicitPath $GodotExe -Manifest $executionManifest
    $toolchainVerification = Get-I1VerifiedToolchainLock -SnapshotRoot $mirrorRoot -WorkspaceRoot $workspaceRoot -ResolvedGodot $resolvedGodot -Manifest $executionManifest
    $runtimeLinks = New-I1GodotRuntimeLinks `
        -MainExecutablePath ([string]$toolchainVerification.main_executable) `
        -ConsoleExecutablePath ([string]$toolchainVerification.console_executable) `
        -RunRoot $runRoot
    $godotConsole = [string]$runtimeLinks.console_executable.hardlink

    $versionEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId 'engine_version'
    $versionRaw = Invoke-I0Process `
        -FilePath $godotConsole `
        -Arguments @('--version') `
        -WorkingDirectory ([string]$runtimeLinks.engine_root) `
        -Environment $versionEnvironment `
        -TimeoutSeconds ([int]$executionManifest.timeouts_seconds.engine_version)
    $versionText = (Normalize-I0ProcessText -Text ($versionRaw.stdout + "`n" + $versionRaw.stderr)).Trim()
    $versionPass = (-not $versionRaw.timed_out -and $versionRaw.exit_code -eq 0 -and [regex]::IsMatch($versionText, [string]$toolchainVerification.version_regex))
    $engineVersionCase = [pscustomobject][ordered]@{
        status = if ($versionPass) { 'PASS' } else { 'FAIL' }
        expected_regex = [string]$toolchainVerification.version_regex
        observed = $versionText
        process = ConvertTo-I1ProcessReport -ProcessResult $versionRaw
    }
    if (-not $versionPass) {
        throw "Locked Godot version preflight failed: $versionText"
    }

    $projectRoot = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot (([string]$executionManifest.godot.project_relative_path).Replace('/', '\')))
    $probeScript = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot (([string]$executionManifest.godot.environment_probe_relative_path).Replace('/', '\')))
    Assert-I0PathWithin -Path $projectRoot -Root $mirrorRoot -Label 'mirrored Godot project'
    Assert-I0PathWithin -Path $probeScript -Root $mirrorRoot -Label 'environment probe'

    $bootstrapLog = Join-Path $logsRoot 'editor_bootstrap.log'
    $bootstrapEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId 'editor_bootstrap'
    $bootstrapRaw = Invoke-I0Process `
        -FilePath $godotConsole `
        -Arguments @('--headless', '--editor', '--import', '--quit', '--path', $projectRoot, '--log-file', $bootstrapLog) `
        -WorkingDirectory $projectRoot `
        -Environment $bootstrapEnvironment `
        -TimeoutSeconds ([int]$executionManifest.timeouts_seconds.editor_bootstrap)
    $bootstrapDiagnosticText = $bootstrapRaw.stdout + "`n" + $bootstrapRaw.stderr + "`n" + (Get-I1LogText -Path $bootstrapLog)
    $bootstrapExpectedCleanup = @($executionManifest.diagnostics.expected_cleanup_diagnostics_by_gate.editor_bootstrap | ForEach-Object { [string]$_ })
    $bootstrapDiagnostics = Get-I1EngineDiagnosticClassification -Text $bootstrapDiagnosticText -ExpectedCleanupDiagnostics $bootstrapExpectedCleanup
    $classCachePath = Join-Path $projectRoot '.godot\global_script_class_cache.cfg'
    $classCachePresent = Test-Path -LiteralPath $classCachePath -PathType Leaf
    $bootstrapPass = (-not $bootstrapRaw.timed_out -and $bootstrapRaw.exit_code -eq 0 -and $bootstrapDiagnostics.blocking_diagnostics.Count -eq 0 -and $bootstrapDiagnostics.cleanup_contract_matches -and $classCachePresent)
    $editorBootstrapCase = [pscustomobject][ordered]@{
        status = if ($bootstrapPass -and $bootstrapDiagnostics.cleanup_diagnostics.Count -gt 0) { 'PASS_WITH_CLEANUP_DIAGNOSTIC' } elseif ($bootstrapPass) { 'PASS' } else { 'FAIL' }
        class_cache_path = $classCachePath
        class_cache_present = $classCachePresent
        expected_cleanup_diagnostics = $bootstrapDiagnostics.expected_cleanup_diagnostics
        blocking_diagnostics = $bootstrapDiagnostics.blocking_diagnostics
        cleanup_diagnostics = $bootstrapDiagnostics.cleanup_diagnostics
        missing_expected_cleanup_diagnostics = $bootstrapDiagnostics.missing_expected_cleanup_diagnostics
        cleanup_contract_matches = $bootstrapDiagnostics.cleanup_contract_matches
        process = ConvertTo-I1ProcessReport -ProcessResult $bootstrapRaw
    }
    if (-not $bootstrapPass) {
        throw 'Godot isolated editor bootstrap/import failed'
    }

    $probeLog = Join-Path $logsRoot 'environment_probe.log'
    $probeEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId 'environment_probe'
    $probeRaw = Invoke-I0Process `
        -FilePath $godotConsole `
        -Arguments @(
            '--headless',
            '--path', $projectRoot,
            '--log-file', $probeLog,
            '--script', $probeScript,
            '--',
            '--workspace-root', $workspaceRoot,
            '--mirror-root', $mirrorRoot,
            '--run-root', $runRoot
        ) `
        -WorkingDirectory $projectRoot `
        -Environment $probeEnvironment `
        -TimeoutSeconds ([int]$executionManifest.timeouts_seconds.environment_probe)
    $probeMarkerText = $probeRaw.stdout + "`n" + $probeRaw.stderr
    $probeDiagnosticText = $probeMarkerText + "`n" + (Get-I1LogText -Path $probeLog)
    $probeExpectedCleanup = @($executionManifest.diagnostics.expected_cleanup_diagnostics_by_gate.environment_isolation | ForEach-Object { [string]$_ })
    $probeDiagnostics = Get-I1EngineDiagnosticClassification -Text $probeDiagnosticText -ExpectedCleanupDiagnostics $probeExpectedCleanup
    try {
        $environmentData = Get-I1MarkedJson -Text $probeMarkerText -Marker 'I0_ENVIRONMENT_PROBE_JSON='
    }
    catch {
        $environmentData = [pscustomobject]@{ status = 'FAIL'; failures = @($_.Exception.Message) }
    }
    $environmentPass = (-not $probeRaw.timed_out -and $probeRaw.exit_code -eq 0 -and [string]$environmentData.status -ceq 'PASS' -and $probeDiagnostics.blocking_diagnostics.Count -eq 0 -and $probeDiagnostics.cleanup_contract_matches)
    $environmentCase = [pscustomobject][ordered]@{
        status = if ($environmentPass -and $probeDiagnostics.cleanup_diagnostics.Count -gt 0) { 'PASS_WITH_CLEANUP_DIAGNOSTIC' } elseif ($environmentPass) { 'PASS' } else { 'FAIL' }
        expected_cleanup_diagnostics = $probeDiagnostics.expected_cleanup_diagnostics
        blocking_diagnostics = $probeDiagnostics.blocking_diagnostics
        cleanup_diagnostics = $probeDiagnostics.cleanup_diagnostics
        missing_expected_cleanup_diagnostics = $probeDiagnostics.missing_expected_cleanup_diagnostics
        cleanup_contract_matches = $probeDiagnostics.cleanup_contract_matches
        result = $environmentData
        process = ConvertTo-I1ProcessReport -ProcessResult $probeRaw
    }
    if (-not $environmentPass) {
        throw 'Godot res:// and user:// isolation probe failed'
    }

    $runnerById = @{}
    foreach ($runner in @($executionManifest.runners)) {
        $runnerById[[string]$runner.id] = $runner
    }
    foreach ($runnerId in $selectedRunnerIds) {
        if (-not $runnerById.ContainsKey($runnerId)) {
            throw "Selected profile references an unregistered runner: $runnerId"
        }
        $runner = $runnerById[$runnerId]
        $runnerPath = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot (([string]$runner.relative_path).Replace('/', '\')))
        Assert-I0PathWithin -Path $runnerPath -Root $mirrorRoot -Label 'Godot runner'
        if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
            throw "Godot runner is missing from the mirror: $runnerPath"
        }
        $userArgs = @((Get-I1PropertyValue -Object $runner -Name 'user_args' -Default @()) | ForEach-Object { [string]$_ })
        $runnerLog = Join-Path $logsRoot ($runnerId + '.log')
        $runnerEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId $runnerId
        $runnerArguments = @('--headless', '--path', $projectRoot, '--log-file', $runnerLog, '--script', $runnerPath)
        if ($userArgs.Count -gt 0) {
            $runnerArguments += '--'
            $runnerArguments += $userArgs
        }
        $runnerTimeout = [int](Get-I1PropertyValue -Object $runner -Name 'timeout_seconds' -Default $executionManifest.timeouts_seconds.runner)
        $runnerRaw = Invoke-I0Process `
            -FilePath $godotConsole `
            -Arguments $runnerArguments `
            -WorkingDirectory $projectRoot `
            -Environment $runnerEnvironment `
            -TimeoutSeconds $runnerTimeout
        $runnerMarkerText = $runnerRaw.stdout + "`n" + $runnerRaw.stderr
        $runnerDiagnosticText = $runnerMarkerText + "`n" + (Get-I1LogText -Path $runnerLog)
        $runnerCleanupProperty = $executionManifest.diagnostics.expected_cleanup_diagnostics_by_runner.PSObject.Properties[$runnerId]
        if ($null -eq $runnerCleanupProperty) {
            throw "Runner cleanup contract is missing: $runnerId"
        }
        $runnerExpectedCleanup = @($runnerCleanupProperty.Value | ForEach-Object { [string]$_ })
        $runnerDiagnostics = Get-I1EngineDiagnosticClassification -Text $runnerDiagnosticText -ExpectedCleanupDiagnostics $runnerExpectedCleanup
        $passRegex = [string](Get-I1PropertyValue -Object $runner -Name 'pass_line_regex' -Default '')
        $passMarkerCount = if ([string]::IsNullOrWhiteSpace($passRegex)) {
            Get-I1ExactLineCount -Text $runnerMarkerText -ExpectedLine ([string]$runner.pass_marker)
        }
        else {
            Get-I1RegexLineCount -Text $runnerMarkerText -Pattern $passRegex
        }
        $failMarkerCount = Get-I1FailMarkerCount -Text $runnerMarkerText -Marker ([string]$runner.fail_marker)
        $runnerPass = (-not $runnerRaw.timed_out -and $runnerRaw.exit_code -eq 0 -and $passMarkerCount -eq 1 -and $failMarkerCount -eq 0 -and $runnerDiagnostics.blocking_diagnostics.Count -eq 0 -and $runnerDiagnostics.cleanup_contract_matches)
        $runnerStatus = if ($runnerPass -and $runnerDiagnostics.cleanup_diagnostics.Count -gt 0) { 'PASS_WITH_CLEANUP_DIAGNOSTIC' } elseif ($runnerPass) { 'PASS' } else { 'FAIL' }
        [void]$runnerCases.Add([pscustomobject][ordered]@{
            id = $runnerId
            relative_path = [string]$runner.relative_path
            user_args = $userArgs
            coverage = @($runner.coverage)
            status = $runnerStatus
            pass_match_mode = if ([string]::IsNullOrWhiteSpace($passRegex)) { 'exact_line' } else { 'anchored_full_line_regex' }
            pass_marker = [string]$runner.pass_marker
            pass_line_regex = $passRegex
            pass_marker_line_count = $passMarkerCount
            fail_marker = [string]$runner.fail_marker
            fail_marker_line_count = $failMarkerCount
            expected_cleanup_diagnostics = $runnerDiagnostics.expected_cleanup_diagnostics
            blocking_diagnostics = $runnerDiagnostics.blocking_diagnostics
            cleanup_diagnostics = $runnerDiagnostics.cleanup_diagnostics
            missing_expected_cleanup_diagnostics = $runnerDiagnostics.missing_expected_cleanup_diagnostics
            cleanup_contract_matches = $runnerDiagnostics.cleanup_contract_matches
            process = ConvertTo-I1ProcessReport -ProcessResult $runnerRaw
        })
        Write-Output ("I1_RUNNER {0}={1}" -f $runnerId, $runnerStatus)
    }
}
catch {
    $fatalError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }
}

try {
    if ($null -ne $beforeGit) {
        $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $afterGit = Get-I0GitSnapshot -RepoRoot $repo -TimeoutSeconds ([int]$setupManifest.timeouts_seconds.git_probe)
        $phaseStopwatch.Stop()
        $phaseTimings['after_git_snapshot'] = [int64]$phaseStopwatch.ElapsedMilliseconds
        $gitPollution = Compare-I0GitSnapshot -Before $beforeGit -After $afterGit
    }
    if ($null -ne $beforeBusiness) {
        $phaseStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $afterBusiness = Get-I0BusinessHashSnapshot -RepoRoot $repo -BusinessRoots @($setupManifest.business_roots) -ExcludedDirectoryNames @($setupManifest.mirror.excluded_directory_names)
        $phaseStopwatch.Stop()
        $phaseTimings['after_business_snapshot'] = [int64]$phaseStopwatch.ElapsedMilliseconds
        $businessPollution = Compare-I0BusinessHashSnapshot -Before $beforeBusiness -After $afterBusiness
    }
}
catch {
    $pollutionGuardError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
    }
}

$runnerIdsObserved = @($runnerCases | ForEach-Object { [string]$_.id })
$runnerRegistrationComplete = (@(Compare-Object -ReferenceObject @($selectedRunnerIds | Sort-Object) -DifferenceObject @($runnerIdsObserved | Sort-Object) -CaseSensitive).Count -eq 0)
$runnerFailures = @($runnerCases | Where-Object { [string]$_.status -ceq 'FAIL' })
$pollutionPass = ($null -eq $pollutionGuardError -and $null -ne $gitPollution -and [bool]$gitPollution.unchanged -and $null -ne $businessPollution -and [bool]$businessPollution.unchanged)
$overallPass = ($null -eq $fatalError -and $runnerRegistrationComplete -and $runnerFailures.Count -eq 0 -and $pollutionPass)
$overallStatus = if ($overallPass) { 'PASS' } else { 'FAIL' }
$finishedUtc = [DateTime]::UtcNow

$reportedExclusions = if ($null -eq $executionManifest) { @($setupManifest.exclusions) } else { @($executionManifest.exclusions) }
$report = [pscustomobject][ordered]@{
    schema_version = 1
    suite_id = 'I1-V1_unified_headless_baseline'
    run_id = $runId
    profile = $Profile
    source_mode = $SourceMode
    overall_status = $overallStatus
    started_utc = $startedUtc.ToString('o')
    finished_utc = $finishedUtc.ToString('o')
    duration_ms = [int64]($finishedUtc - $startedUtc).TotalMilliseconds
    phase_timings_ms = [pscustomobject]$phaseTimings
    active_repo = $repo
    workspace_root = $workspaceRoot
    run_root = $runRoot
    mirror_root = $mirrorRoot
    report_path = $reportPath
    source = $mirrorSource
    manifest_binding = [pscustomobject][ordered]@{
        status = if ($null -ne $executionManifestSha256 -and $manifestHashesMatch) { 'PASS' } else { 'FAIL' }
        required_mode = if ($SourceMode -ceq 'head') { 'active_setup_equals_head_mirror' } else { 'active_setup_equals_worktree_mirror' }
        setup_path = $requestedManifestPath
        setup_sha256 = $setupManifestSha256
        execution_path = $executionManifestPath
        execution_sha256 = $executionManifestSha256
        hashes_match = $manifestHashesMatch
    }
    control_plane_binding = [pscustomobject][ordered]@{
        status = if ($controlPlaneBindingPass) { 'PASS' } else { 'FAIL' }
        required_mode = if ($SourceMode -ceq 'head') { 'active_entry_and_library_equal_head_mirror' } else { 'active_entry_and_library_equal_worktree_mirror' }
        files = @($controlPlaneBindings)
    }
    mirror = [pscustomobject][ordered]@{
        case = $mirrorCase
        fidelity = $mirrorFidelity
        forbidden_paths_absent = ($null -eq $fatalError -or $null -ne $executionManifest)
    }
    selected_runner_ids = @($selectedRunnerIds)
    registration_complete = $runnerRegistrationComplete
    exclusions = @($reportedExclusions | ForEach-Object {
        [pscustomobject][ordered]@{
            id = [string]$_.id
            relative_path = Get-I1PropertyValue -Object $_ -Name 'relative_path' -Default $null
            category = [string]$_.category
            status = [string]$_.disposition
            reason = [string]$_.reason
        }
    })
    gates = [pscustomobject][ordered]@{
        git_ignore = $tmpIgnoreCase
        static_validation = $staticCase
        toolchain = $toolchainVerification
        runtime_links = $runtimeLinks
        engine_version = $engineVersionCase
        editor_bootstrap = $editorBootstrapCase
        environment_isolation = $environmentCase
    }
    runners = $runnerCases.ToArray()
    pollution_guard = [pscustomobject][ordered]@{
        status = if ($pollutionPass) { 'PASS' } else { 'FAIL' }
        git = $gitPollution
        business = $businessPollution
        before_git = $beforeGit
        after_git = $afterGit
        before_business = if ($null -eq $beforeBusiness) { $null } else { Get-I0PublicBusinessSnapshot -Snapshot $beforeBusiness }
        after_business = if ($null -eq $afterBusiness) { $null } else { Get-I0PublicBusinessSnapshot -Snapshot $afterBusiness }
        error = $pollutionGuardError
    }
    fatal_error = $fatalError
}

try {
    if (-not (Test-Path -LiteralPath $runRoot -PathType Container)) {
        [void](New-Item -ItemType Directory -Path $runRoot -Force)
    }
    Write-I0Json -Value $report -Path $reportPath
    Write-Output ("I1_REPORT_JSON=$reportPath")
}
catch {
    Write-Error ("Unable to write I1 JSON report: " + $_.Exception.Message)
    $overallStatus = 'FAIL'
}
Write-Output ("I1_TEST_STATUS=$overallStatus")
if ($overallStatus -cne 'PASS') {
    exit 1
}
