param(
    [ValidateSet("baseline", "remediated")]
    [string]$Profile = "baseline",

    [ValidateSet("worktree", "head")]
    [string]$SourceMode = "worktree",

    [string]$RepoRoot = ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))),

    [string]$WorkspaceRoot = "",

    [string]$RuntimeTempRoot = "",

    [string]$ReportRoot = "",

    [string]$GodotInstallRoot = "",

    [string]$ManifestPath = (Join-Path $PSScriptRoot "validation_manifest.json")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

. (Join-Path $PSScriptRoot "i0_test_lib.ps1")


function Get-I0DefaultWorkspaceRoot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

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
    throw "Unable to derive a common I0 workspace root for repo=$repo git_common=$gitCommon"
}


function ConvertTo-I0ProcessReport {
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


function Get-I0MarkedJson {
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


function Get-I0EngineDiagnostics {
    param([Parameter(Mandatory = $true)][string]$Text)
    return @([regex]::Matches($Text, '(?im)^\s*(?:SCRIPT ERROR|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$') | ForEach-Object { $_.Value.Trim() })
}


function Get-I0EngineDiagnosticClassification {
    param([Parameter(Mandatory = $true)][string]$Text)
    $cleanup = New-Object System.Collections.Generic.List[string]
    $blocking = New-Object System.Collections.Generic.List[string]
    foreach ($diagnostic in @(Get-I0EngineDiagnostics -Text $Text)) {
        if ($diagnostic -match '^WARNING:\s+ObjectDB instances leaked at exit \(run with --verbose for details\)\.$' -or
            $diagnostic -match '^ERROR:\s+\d+ resources still in use at exit \(run with --verbose for details\)\.$') {
            [void]$cleanup.Add($diagnostic)
        }
        else {
            [void]$blocking.Add($diagnostic)
        }
    }
    return [pscustomobject][ordered]@{
        blocking_diagnostics = $blocking.ToArray()
        cleanup_diagnostics = $cleanup.ToArray()
    }
}


function Get-I0ExactMarkerLineCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    return @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.Trim() -ceq $Marker }).Count
}


function Get-I0FailMarkerLineCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )
    return @((Normalize-I0ProcessText -Text $Text) -split "`n" | Where-Object { $_.Trim().StartsWith($Marker, [System.StringComparison]::Ordinal) }).Count
}


function Get-I0VerifiedToolchainLock {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$InstallRoot,
        [Parameter(Mandatory = $true)]$ValidationManifest
    )

    $lockPath = Get-I0CanonicalPath -Path (Join-Path $RepoRoot 'tools\i0\toolchain.lock.json')
    Assert-I0NoReparseExistingAncestor -Path $lockPath -Root $WorkspaceRoot -Label 'I0.1 toolchain lock'
    if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) {
        throw "I0.1 toolchain lock is missing: $lockPath"
    }
    $lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
    $approved = [ordered]@{
        version = '4.6.3'
        archive_sha256 = 'e39986a178d585ce7ac198fb8de6ea436366dc0cc00e594810c2e3e104c04b90'
        main_sha256 = 'ef90e929ba1a6a4322860285d97f40f4aa349c90329a91b0e8b55b8df0f4cb00'
        console_sha256 = '63b3b2208819714c9677fbfdd8217c5b7dee8ecf5f383502e826bc9e2227ff5a'
        main_size = [int64]172409864
        console_size = [int64]198152
    }
    if ([int]$lock.schema_version -ne 3 -or [string]$lock.stage -cne 'I0.1' -or [string]$lock.path_policy -cne 'runtime_parameter') {
        throw 'I0.1 toolchain lock schema or stage is unsupported'
    }
    if ([string]$lock.godot.version -cne $approved.version -or [string]$lock.godot.archive_sha256 -cne $approved.archive_sha256) {
        throw 'I0.1 Godot version or official archive SHA-256 differs from the approved lock identity'
    }
    if ([string]$lock.godot.executable -cne [string]$ValidationManifest.godot.main_executable -or [string]$lock.godot.console_executable -cne [string]$ValidationManifest.godot.console_executable) {
        throw 'I0.1 toolchain executable names differ from the I0.2 validation manifest'
    }
    if ([string]$lock.godot.executable_sha256 -cne $approved.main_sha256 -or [string]$lock.godot.console_executable_sha256 -cne $approved.console_sha256) {
        throw 'I0.1 executable SHA-256 values differ from the approved byte identities'
    }
    if ([int64]$lock.godot.executable_size_bytes -ne $approved.main_size -or [int64]$lock.godot.console_executable_size_bytes -ne $approved.console_size) {
        throw 'I0.1 executable sizes differ from the approved byte identities'
    }

    $installRoot = Get-I0CanonicalPath -Path $InstallRoot
    $expectedInstallRoot = Get-I0CanonicalPath -Path (Join-Path $WorkspaceRoot ("tools\runtimes\godot\" + $approved.version))
    if (-not [string]::Equals($installRoot, $expectedInstallRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "I0.2 Godot install root is not the approved version directory: $installRoot"
    }
    Assert-I0NoReparseExistingAncestor -Path $installRoot -Root $WorkspaceRoot -Label 'Godot install root'
    $mainPath = Join-Path $installRoot ([string]$lock.godot.executable)
    $consolePath = Join-Path $installRoot ([string]$lock.godot.console_executable)
    $installManifestPath = Join-Path $installRoot 'install-manifest.json'
    foreach ($path in @($mainPath, $consolePath, $installManifestPath)) {
        Assert-I0NoReparseExistingAncestor -Path $path -Root $WorkspaceRoot -Label 'Godot installed file'
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Godot installed file is missing: $path"
        }
    }
    $mainItem = Get-Item -LiteralPath $mainPath
    $consoleItem = Get-Item -LiteralPath $consolePath
    $mainHash = (Get-FileHash -LiteralPath $mainPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $consoleHash = (Get-FileHash -LiteralPath $consolePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($mainItem.Length -ne $approved.main_size -or $mainHash -cne $approved.main_sha256) {
        throw 'Installed Godot main executable does not match the pinned I0.1 bytes'
    }
    if ($consoleItem.Length -ne $approved.console_size -or $consoleHash -cne $approved.console_sha256) {
        throw 'Installed Godot console executable does not match the pinned I0.1 bytes'
    }
    $installManifest = Get-Content -LiteralPath $installManifestPath -Raw | ConvertFrom-Json
    if ([string]$installManifest.version -cne $approved.version -or [string]$installManifest.archive_sha256 -cne $approved.archive_sha256 -or [string]$installManifest.main_exe_sha256 -cne $approved.main_sha256 -or [string]$installManifest.console_exe_sha256 -cne $approved.console_sha256) {
        throw 'Installed Godot manifest does not match the I0.1 lock'
    }
    return [pscustomobject][ordered]@{
        status = 'PASS'
        lock_path = $lockPath
        install_manifest_path = $installManifestPath
        install_root = $installRoot
        version = $approved.version
        version_regex = [string]$lock.godot.version_regex
        archive_sha256 = $approved.archive_sha256
        main_executable = $mainPath
        main_size_bytes = $mainItem.Length
        main_sha256 = $mainHash
        console_executable = $consolePath
        console_size_bytes = $consoleItem.Length
        console_sha256 = $consoleHash
    }
}


if ($PSVersionTable.PSEdition -cne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -lt 1) {
    throw "I0.2 requires Windows PowerShell 5.1 Desktop; current=$($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)"
}

$repo = Get-I0CanonicalPath -Path $RepoRoot
$workspaceRoot = if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    Get-I0DefaultWorkspaceRoot -RepoRoot $repo
}
else {
    Get-I0CanonicalPath -Path $WorkspaceRoot
}
[void](Set-I0WorkspaceRoot -Path $workspaceRoot)
$approvedManifestPath = Get-I0CanonicalPath -Path (Join-Path $PSScriptRoot 'validation_manifest.json')
$requestedManifestPath = Get-I0CanonicalPath -Path $ManifestPath
if (-not [string]::Equals($requestedManifestPath, $approvedManifestPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "I0.2 only accepts its colocated validation manifest: $approvedManifestPath"
}
Assert-I0NoReparseExistingAncestor -Path $requestedManifestPath -Root $workspaceRoot -Label 'I0.2 validation manifest'
$manifest = Get-Content -LiteralPath $requestedManifestPath -Raw | ConvertFrom-Json
if ([int]$manifest.schema_version -ne 2 -or [string]$manifest.path_policy -cne 'runtime_parameters') {
    throw 'I0.2 validation manifest schema or path policy is unsupported'
}
Assert-I0PathWithin -Path $repo -Root $workspaceRoot -Label "active repo"
Assert-I0NoReparseExistingAncestor -Path $repo -Root $workspaceRoot -Label "active repo"

$runtimeTempRoot = if ([string]::IsNullOrWhiteSpace($RuntimeTempRoot)) {
    Get-I0CanonicalPath -Path (Join-Path $workspaceRoot 'tools\runtimes\.tmp\i0')
}
else {
    Get-I0CanonicalPath -Path $RuntimeTempRoot
}
$reportRoot = if ([string]::IsNullOrWhiteSpace($ReportRoot)) {
    Get-I0CanonicalPath -Path (Join-Path $workspaceRoot 'reports\i0')
}
else {
    Get-I0CanonicalPath -Path $ReportRoot
}
$godotInstallRoot = if ([string]::IsNullOrWhiteSpace($GodotInstallRoot)) {
    Get-I0CanonicalPath -Path (Join-Path $workspaceRoot 'tools\runtimes\godot\4.6.3')
}
else {
    Get-I0CanonicalPath -Path $GodotInstallRoot
}
Assert-I0PathWithin -Path $runtimeTempRoot -Root $workspaceRoot -Label "I0 runtime temp root"
Assert-I0PathWithin -Path $reportRoot -Root $workspaceRoot -Label "I0 report root"
Assert-I0PathWithin -Path $godotInstallRoot -Root $workspaceRoot -Label "I0 Godot install root"
Assert-I0NoReparseExistingAncestor -Path $runtimeTempRoot -Root $workspaceRoot -Label "I0 runtime temp root"
Assert-I0NoReparseExistingAncestor -Path $reportRoot -Root $workspaceRoot -Label "I0 report root"
[void](Assert-I0NoReparseExistingAncestor -Path $godotInstallRoot -Root $workspaceRoot -Label "I0 Godot install root")
[void](New-Item -ItemType Directory -Path $runtimeTempRoot -Force)
[void](New-Item -ItemType Directory -Path $reportRoot -Force)

$runId = ([DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '_' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
$runRoot = Get-I0CanonicalPath -Path (Join-Path $runtimeTempRoot $runId)
Assert-I0PathWithin -Path $runRoot -Root $runtimeTempRoot -Label "I0 run root"
Assert-I0NoReparseExistingAncestor -Path $runRoot -Root $workspaceRoot -Label "I0 run root"
if (Test-Path -LiteralPath $runRoot) {
    throw "Generated I0 run root already exists: $runRoot"
}
[void](New-Item -ItemType Directory -Path $runRoot)

$reportPath = Join-Path $reportRoot ("I0.2_" + $runId + ".json")
$worktreeDirectory = [string]$manifest.mirror.worktree_directory
if ($worktreeDirectory -notmatch '^[A-Za-z0-9_.-]+$' -or $worktreeDirectory -in @('.', '..')) {
    throw "Unsafe mirror worktree directory name: $worktreeDirectory"
}
$mirrorRoot = Get-I0CanonicalPath -Path (Join-Path $runRoot $worktreeDirectory)
Assert-I0PathWithin -Path $mirrorRoot -Root $runRoot -Label 'I0 mirror root'
Assert-I0NoReparseExistingAncestor -Path $mirrorRoot -Root $workspaceRoot -Label 'I0 mirror root'
$staticReportPath = Join-Path $runRoot 'artifacts\static_validation.json'
$logsRoot = Join-Path $runRoot 'logs'
foreach ($writePath in @($staticReportPath, $logsRoot, $reportPath)) {
    Assert-I0NoReparseExistingAncestor -Path $writePath -Root $workspaceRoot -Label "I0 output path"
}
[void](New-Item -ItemType Directory -Path (Split-Path -Parent $staticReportPath) -Force)
[void](New-Item -ItemType Directory -Path $logsRoot -Force)

$startedUtc = [DateTime]::UtcNow
$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$fatalError = $null
$beforeGit = $null
$afterGit = $null
$beforeBusiness = $null
$afterBusiness = $null
$gitPollution = $null
$businessPollution = $null
$pollutionGuardError = $null
$mirrorFidelity = $null
$mirrorCopy = $null
$mirrorSource = $null
$runtimeLinks = $null
$toolchainVerification = $null
$documentEncodingCase = $null
$engineVersionCase = $null
$staticCase = $null
$staticData = $null
$editorBootstrapCase = $null
$environmentCase = $null
$environmentData = $null
$runnerCases = New-Object System.Collections.Generic.List[object]

try {
    $gitTimeout = [int]$manifest.timeouts_seconds.git_probe
    $beforeGit = Get-I0GitSnapshot -RepoRoot $repo -TimeoutSeconds $gitTimeout
    $beforeBusiness = Get-I0BusinessHashSnapshot -RepoRoot $repo -BusinessRoots @($manifest.business_roots) -ExcludedDirectoryNames @($manifest.mirror.excluded_directory_names)
    $toolchainVerification = Get-I0VerifiedToolchainLock -RepoRoot $repo -WorkspaceRoot $workspaceRoot -InstallRoot $godotInstallRoot -ValidationManifest $manifest

    if ($SourceMode -eq 'worktree') {
        $mirrorCopyRaw = Copy-I0WorktreeMirror `
            -SourceRepo $repo `
            -Destination $mirrorRoot `
            -RuntimeTempRoot $runtimeTempRoot `
            -ExcludedDirectoryNames @($manifest.mirror.excluded_directory_names) `
            -TimeoutSeconds ([int]$manifest.timeouts_seconds.mirror_copy)
        $mirrorCopy = ConvertTo-I0ProcessReport -ProcessResult $mirrorCopyRaw
        $mirrorBusiness = Get-I0BusinessHashSnapshot -RepoRoot $mirrorRoot -BusinessRoots @($manifest.business_roots) -ExcludedDirectoryNames @($manifest.mirror.excluded_directory_names)
        $mirrorFidelity = Compare-I0BusinessHashSnapshot -Before $beforeBusiness -After $mirrorBusiness
        $mirrorSource = [pscustomobject][ordered]@{
            mode = 'worktree'
            head = $beforeGit.head
            tree = '(worktree mirror)'
            protected_dirty_state_included = $true
        }
        if (-not $mirrorFidelity.unchanged) {
            throw "Isolated worktree mirror business hash does not match the active repo"
        }
    }
    else {
        $headMirror = Copy-I0HeadMirror `
            -SourceRepo $repo `
            -Destination $mirrorRoot `
            -RuntimeTempRoot $runtimeTempRoot `
            -TimeoutSeconds ([int]$manifest.timeouts_seconds.mirror_copy)
        $mirrorCopy = ConvertTo-I0ProcessReport -ProcessResult $headMirror.checkout_process
        $mirrorBusiness = Get-I0BusinessHashSnapshot -RepoRoot $mirrorRoot -BusinessRoots @($manifest.business_roots) -ExcludedDirectoryNames @($manifest.mirror.excluded_directory_names)
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
            read_tree_process = ConvertTo-I0ProcessReport -ProcessResult $headMirror.read_tree_process
        }
    }

    if ($SourceMode -eq 'worktree') {
        $documentEncodingRoot = $repo
        $documentEncodingScript = Join-Path $repo (([string]$manifest.static_contract.document_encoding_validator_relative_path).Replace('/', '\'))
        $documentEncodingArguments = @(
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy', 'Bypass',
            '-File', $documentEncodingScript,
            '-RepoRoot', $repo,
            '-WorkspaceRoot', $workspaceRoot,
            '-RuntimeTempRoot', $runtimeTempRoot,
            '-SourceMode', 'worktree',
            '-GitRepoRoot', $repo
        )
    }
    else {
        $documentEncodingRoot = $mirrorRoot
        $documentEncodingScript = Join-Path $mirrorRoot (([string]$manifest.static_contract.document_encoding_validator_relative_path).Replace('/', '\'))
        $documentEncodingArguments = @(
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy', 'Bypass',
            '-File', $documentEncodingScript,
            '-RepoRoot', $mirrorRoot,
            '-WorkspaceRoot', $workspaceRoot,
            '-RuntimeTempRoot', $runtimeTempRoot,
            '-SourceMode', 'head',
            '-GitRepoRoot', $repo,
            '-ExpectedHead', $headMirror.head
        )
    }
    Assert-I0PathWithin -Path $documentEncodingScript -Root $documentEncodingRoot -Label 'document encoding validator'
    Assert-I0NoReparseExistingAncestor -Path $documentEncodingScript -Root $workspaceRoot -Label 'document encoding validator'
    $documentEncodingRaw = Invoke-I0Process `
        -FilePath $windowsPowerShell `
        -Arguments $documentEncodingArguments `
        -WorkingDirectory $documentEncodingRoot `
        -TimeoutSeconds ([int]$manifest.timeouts_seconds.document_encoding)
    $documentEncodingData = $null
    $documentEncodingParseError = $null
    try {
        $documentEncodingData = Get-I0MarkedJson -Text $documentEncodingRaw.stdout -Marker 'I0_DOCUMENT_ENCODING_JSON='
    }
    catch {
        $documentEncodingParseError = $_.Exception.Message
    }
    $documentEncodingPass = (
        -not $documentEncodingRaw.timed_out -and
        $documentEncodingRaw.exit_code -eq 0 -and
        $null -ne $documentEncodingData -and
        [string]$documentEncodingData.status -eq 'PASS_WITH_RECORDED_LIMITATION' -and
        [string]$documentEncodingData.source_mode -eq $SourceMode -and
        [int]$documentEncodingData.error_count -eq 0 -and
        [bool]$documentEncodingData.head_unchanged -and
        [bool]$documentEncodingData.expected_head_verified -and
        [bool]$documentEncodingData.git_status_unchanged
    )
    $documentEncodingCase = [pscustomobject][ordered]@{
        status = if ($documentEncodingPass) { 'PASS_WITH_RECORDED_LIMITATION' } else { 'FAIL' }
        parse_error = $documentEncodingParseError
        process = ConvertTo-I0ProcessReport -ProcessResult $documentEncodingRaw
        result = $documentEncodingData
    }
    if (-not $documentEncodingPass) {
        throw 'Document encoding gate failed'
    }

    $runtimeLinks = New-I0GodotRuntimeLinks `
        -InstallRoot $godotInstallRoot `
        -MainExecutableName ([string]$manifest.godot.main_executable) `
        -ConsoleExecutableName ([string]$manifest.godot.console_executable) `
        -RunRoot $runRoot
    $godotConsole = [string]$runtimeLinks.console_executable.hardlink
    $versionEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId 'engine_version'
    $versionRaw = Invoke-I0Process `
        -FilePath $godotConsole `
        -Arguments @('--version') `
        -WorkingDirectory ([string]$runtimeLinks.engine_root) `
        -Environment $versionEnvironment `
        -TimeoutSeconds 30
    $versionText = (Normalize-I0ProcessText -Text ($versionRaw.stdout + "`n" + $versionRaw.stderr)).Trim()
    $versionPass = (-not $versionRaw.timed_out -and $versionRaw.exit_code -eq 0 -and [regex]::IsMatch($versionText, [string]$toolchainVerification.version_regex))
    $engineVersionCase = [pscustomobject][ordered]@{
        status = if ($versionPass) { 'PASS' } else { 'FAIL' }
        expected_prefix = [string]$manifest.godot.version_prefix
        expected_regex = [string]$toolchainVerification.version_regex
        observed = $versionText
        process = ConvertTo-I0ProcessReport -ProcessResult $versionRaw
    }
    if (-not $versionPass) {
        throw "Godot version preflight failed: $versionText"
    }

    $mirrorStaticScript = Join-Path $mirrorRoot 'tools\i0\validate_static_baseline.ps1'
    $mirrorManifest = Join-Path $mirrorRoot 'tools\i0\validation_manifest.json'
    $staticRaw = Invoke-I0Process `
        -FilePath $windowsPowerShell `
        -Arguments @(
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy', 'Bypass',
            '-File', $mirrorStaticScript,
            '-RepoRoot', $mirrorRoot,
            '-WorkspaceRoot', $workspaceRoot,
            '-ManifestPath', $mirrorManifest,
            '-SourceMode', $SourceMode,
            '-Profile', $Profile,
            '-ReportPath', $staticReportPath
        ) `
        -WorkingDirectory $mirrorRoot `
        -TimeoutSeconds ([int]$manifest.timeouts_seconds.static_validation)
    if (Test-Path -LiteralPath $staticReportPath -PathType Leaf) {
        $staticData = Get-Content -LiteralPath $staticReportPath -Raw | ConvertFrom-Json
    }
    $staticPass = (-not $staticRaw.timed_out -and $staticRaw.exit_code -eq 0 -and $null -ne $staticData -and [string]$staticData.overall_status -eq 'PASS')
    $staticCase = [pscustomobject][ordered]@{
        status = if ($staticPass) { 'PASS' } else { 'FAIL' }
        process = ConvertTo-I0ProcessReport -ProcessResult $staticRaw
        result = $staticData
    }
    if (-not $staticPass) {
        throw "Static characterization contract failed"
    }

    $projectRoot = Join-Path $mirrorRoot (([string]$manifest.godot.project_relative_path).Replace('/', '\'))
    $probeScript = Join-Path $mirrorRoot (([string]$manifest.godot.environment_probe_relative_path).Replace('/', '\'))
    Assert-I0PathWithin -Path $projectRoot -Root $mirrorRoot -Label "mirrored Godot project"
    Assert-I0PathWithin -Path $probeScript -Root $mirrorRoot -Label "mirrored environment probe"
    $editorBootstrapLog = Join-Path $logsRoot 'editor_bootstrap.log'
    $editorBootstrapEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId 'editor_bootstrap'
    $editorBootstrapRaw = Invoke-I0Process `
        -FilePath $godotConsole `
        -Arguments @('--headless', '--editor', '--import', '--quit', '--path', $projectRoot, '--log-file', $editorBootstrapLog) `
        -WorkingDirectory $projectRoot `
        -Environment $editorBootstrapEnvironment `
        -TimeoutSeconds ([int]$manifest.timeouts_seconds.editor_bootstrap)
    $editorBootstrapCombined = $editorBootstrapRaw.stdout + "`n" + $editorBootstrapRaw.stderr
    $editorBootstrapDiagnostics = Get-I0EngineDiagnosticClassification -Text $editorBootstrapCombined
    $classCachePath = Join-Path $projectRoot '.godot\global_script_class_cache.cfg'
    $classCachePresent = Test-Path -LiteralPath $classCachePath -PathType Leaf
    $editorBootstrapPass = (-not $editorBootstrapRaw.timed_out -and $editorBootstrapRaw.exit_code -eq 0 -and $editorBootstrapDiagnostics.blocking_diagnostics.Count -eq 0 -and $classCachePresent)
    $editorBootstrapCase = [pscustomobject][ordered]@{
        status = if ($editorBootstrapPass -and $editorBootstrapDiagnostics.cleanup_diagnostics.Count -gt 0) { 'PASS_WITH_CLEANUP_DIAGNOSTIC' } elseif ($editorBootstrapPass) { 'PASS' } else { 'FAIL' }
        class_cache_path = $classCachePath
        class_cache_present = $classCachePresent
        blocking_diagnostics = $editorBootstrapDiagnostics.blocking_diagnostics
        cleanup_diagnostics = $editorBootstrapDiagnostics.cleanup_diagnostics
        process = ConvertTo-I0ProcessReport -ProcessResult $editorBootstrapRaw
    }
    if (-not $editorBootstrapPass) {
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
        -TimeoutSeconds ([int]$manifest.timeouts_seconds.environment_probe)
    $probeCombined = $probeRaw.stdout + "`n" + $probeRaw.stderr
    $probeDiagnostics = Get-I0EngineDiagnosticClassification -Text $probeCombined
    try {
        $environmentData = Get-I0MarkedJson -Text $probeCombined -Marker 'I0_ENVIRONMENT_PROBE_JSON='
    }
    catch {
        $environmentData = [pscustomobject]@{ status = 'FAIL'; failures = @($_.Exception.Message) }
    }
    $environmentPass = (-not $probeRaw.timed_out -and $probeRaw.exit_code -eq 0 -and [string]$environmentData.status -eq 'PASS' -and $probeDiagnostics.blocking_diagnostics.Count -eq 0)
    $environmentCase = [pscustomobject][ordered]@{
        status = if ($environmentPass -and $probeDiagnostics.cleanup_diagnostics.Count -gt 0) { 'PASS_WITH_CLEANUP_DIAGNOSTIC' } elseif ($environmentPass) { 'PASS' } else { 'FAIL' }
        blocking_diagnostics = $probeDiagnostics.blocking_diagnostics
        cleanup_diagnostics = $probeDiagnostics.cleanup_diagnostics
        result = $environmentData
        process = ConvertTo-I0ProcessReport -ProcessResult $probeRaw
    }
    if (-not $environmentPass) {
        throw "Godot res:// and user:// isolation probe failed"
    }

    foreach ($runner in $manifest.runners) {
        $runnerId = [string]$runner.id
        if ($runnerId -notmatch '^[A-Z0-9_]+$') {
            throw "Unsafe runner id in validation manifest: $runnerId"
        }
        $runnerPath = Get-I0CanonicalPath -Path (Join-Path $mirrorRoot (([string]$runner.relative_path).Replace('/', '\')))
        Assert-I0PathWithin -Path $runnerPath -Root $mirrorRoot -Label "Godot runner"
        if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
            throw "Godot runner missing from mirror: $runnerPath"
        }
        $runnerUserArgs = @()
        if ($null -ne $runner.PSObject.Properties['user_args']) {
            foreach ($rawUserArg in @($runner.user_args)) {
                $userArg = [string]$rawUserArg
                if ($userArg.Length -lt 3 -or $userArg.Length -gt 128 -or $userArg -notmatch '^--[a-z0-9][a-z0-9._-]*(=[a-z0-9][a-z0-9._-]*)?$') {
                    throw "Unsafe Godot user argument for ${runnerId}: $userArg"
                }
                $runnerUserArgs += $userArg
            }
        }
        $runnerLog = Join-Path $logsRoot ($runnerId + '.log')
        $runnerEnvironment = New-I0ProcessEnvironment -RunRoot $runRoot -CaseId $runnerId
        $runnerArguments = @('--headless', '--path', $projectRoot, '--log-file', $runnerLog, '--script', $runnerPath)
        if ($runnerUserArgs.Count -gt 0) {
            $runnerArguments += '--'
            $runnerArguments += $runnerUserArgs
        }
        $runnerRaw = Invoke-I0Process `
            -FilePath $godotConsole `
            -Arguments $runnerArguments `
            -WorkingDirectory $projectRoot `
            -Environment $runnerEnvironment `
            -TimeoutSeconds ([int]$manifest.timeouts_seconds.runner)
        $runnerCombined = $runnerRaw.stdout + "`n" + $runnerRaw.stderr
        $engineDiagnostics = Get-I0EngineDiagnosticClassification -Text $runnerCombined
        $passMarkerLineCount = Get-I0ExactMarkerLineCount -Text $runnerCombined -Marker ([string]$runner.pass_marker)
        $failMarkerLineCount = Get-I0FailMarkerLineCount -Text $runnerCombined -Marker ([string]$runner.fail_marker)
        $runnerPass = (-not $runnerRaw.timed_out -and $runnerRaw.exit_code -eq 0 -and $passMarkerLineCount -eq 1 -and $failMarkerLineCount -eq 0 -and $engineDiagnostics.blocking_diagnostics.Count -eq 0)
        [void]$runnerCases.Add([pscustomobject][ordered]@{
            id = $runnerId
            relative_path = [string]$runner.relative_path
            user_args = $runnerUserArgs
            coverage = @($runner.coverage)
            status = if ($runnerPass -and $engineDiagnostics.cleanup_diagnostics.Count -gt 0) { 'PASS_WITH_CLEANUP_DIAGNOSTIC' } elseif ($runnerPass) { 'PASS' } else { 'FAIL' }
            pass_marker_line_count = $passMarkerLineCount
            fail_marker_line_count = $failMarkerLineCount
            blocking_diagnostics = $engineDiagnostics.blocking_diagnostics
            cleanup_diagnostics = $engineDiagnostics.cleanup_diagnostics
            process = ConvertTo-I0ProcessReport -ProcessResult $runnerRaw
        })
    }
}
catch {
    $fatalError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
        script_stack_trace = $_.ScriptStackTrace
    }
}

try {
    if ($null -ne $beforeGit) {
        $afterGit = Get-I0GitSnapshot -RepoRoot $repo -TimeoutSeconds ([int]$manifest.timeouts_seconds.git_probe)
        $gitPollution = Compare-I0GitSnapshot -Before $beforeGit -After $afterGit
    }
    if ($null -ne $beforeBusiness) {
        $afterBusiness = Get-I0BusinessHashSnapshot -RepoRoot $repo -BusinessRoots @($manifest.business_roots) -ExcludedDirectoryNames @($manifest.mirror.excluded_directory_names)
        $businessPollution = Compare-I0BusinessHashSnapshot -Before $beforeBusiness -After $afterBusiness
    }
}
catch {
    $pollutionGuardError = [pscustomobject][ordered]@{
        message = "Pollution guard post-snapshot failed: $($_.Exception.Message)"
        type = $_.Exception.GetType().FullName
        script_stack_trace = $_.ScriptStackTrace
    }
}

$runnerResults = $runnerCases.ToArray()
$runnerPassCount = @($runnerResults | Where-Object { $_.status -like 'PASS*' }).Count
$runnerExpectedCount = @($manifest.runners).Count
$pollutionPass = ($null -eq $pollutionGuardError -and $null -ne $gitPollution -and $gitPollution.unchanged -and $null -ne $businessPollution -and $businessPollution.unchanged)
$allCasesPass = (
    $null -eq $fatalError -and
    $null -ne $mirrorFidelity -and $mirrorFidelity.unchanged -and
    $null -ne $toolchainVerification -and $toolchainVerification.status -eq 'PASS' -and
    $null -ne $documentEncodingCase -and $documentEncodingCase.status -eq 'PASS_WITH_RECORDED_LIMITATION' -and
    $null -ne $engineVersionCase -and $engineVersionCase.status -eq 'PASS' -and
    $null -ne $staticCase -and $staticCase.status -eq 'PASS' -and
    $null -ne $editorBootstrapCase -and $editorBootstrapCase.status -like 'PASS*' -and
    $null -ne $environmentCase -and $environmentCase.status -like 'PASS*' -and
    $runnerPassCount -eq $runnerExpectedCount -and
    $pollutionPass
)
$cleanupDiagnosticCount = 0
if ($null -ne $editorBootstrapCase) { $cleanupDiagnosticCount += @($editorBootstrapCase.cleanup_diagnostics).Count }
if ($null -ne $environmentCase) { $cleanupDiagnosticCount += @($environmentCase.cleanup_diagnostics).Count }
foreach ($runnerResult in $runnerResults) { $cleanupDiagnosticCount += @($runnerResult.cleanup_diagnostics).Count }
$recordedLimitationCount = if ($null -ne $documentEncodingCase -and $documentEncodingCase.status -eq 'PASS_WITH_RECORDED_LIMITATION') { 1 } else { 0 }
$overallLabel = if (-not $allCasesPass) {
    'FAIL'
}
elseif ($Profile -eq 'baseline' -and ($cleanupDiagnosticCount -gt 0 -or $recordedLimitationCount -gt 0)) {
    'PASS_WITH_EXPECTED_REDS_AND_NOTES'
}
elseif ($Profile -eq 'baseline') {
    'PASS_WITH_EXPECTED_REDS'
}
elseif ($cleanupDiagnosticCount -gt 0 -or $recordedLimitationCount -gt 0) {
    'PASS_WITH_NOTES'
}
else {
    'PASS'
}
$characterizationLabel = if (-not $allCasesPass) {
    'FAIL'
}
elseif ($Profile -eq 'baseline' -and ($cleanupDiagnosticCount -gt 0 -or $recordedLimitationCount -gt 0)) {
    'PASS_WITH_EXPECTED_REDS_AND_NOTES'
}
elseif ($Profile -eq 'baseline') {
    'PASS_WITH_EXPECTED_REDS'
}
elseif ($cleanupDiagnosticCount -gt 0 -or $recordedLimitationCount -gt 0) {
    'PASS_REMEDIATED_WITH_NOTES'
}
else {
    'PASS_REMEDIATED'
}
$completedUtc = [DateTime]::UtcNow
$report = [pscustomobject][ordered]@{
    schema_version = 2
    suite_id = [string]$manifest.suite_id
    run_id = $runId
    profile = $Profile
    source_mode = $SourceMode
    overall_status = $overallLabel
    characterization_status = $characterizationLabel
    cleanup_diagnostic_count = $cleanupDiagnosticCount
    recorded_limitation_count = $recordedLimitationCount
    started_utc = $startedUtc.ToString('o')
    completed_utc = $completedUtc.ToString('o')
    duration_ms = [int64]($completedUtc - $startedUtc).TotalMilliseconds
    powershell = [pscustomobject][ordered]@{
        edition = $PSVersionTable.PSEdition
        version = $PSVersionTable.PSVersion.ToString()
    }
    paths = [pscustomobject][ordered]@{
        workspace_root = $workspaceRoot
        active_repo = $repo
        run_root = $runRoot
        mirror_root = $mirrorRoot
        report_path = $reportPath
    }
    fatal_error = $fatalError
    mirror = [pscustomobject][ordered]@{
        source = $mirrorSource
        copy_process = $mirrorCopy
        fidelity = $mirrorFidelity
    }
    runtime_links = $runtimeLinks
    toolchain_verification = $toolchainVerification
    document_encoding = $documentEncodingCase
    engine_version = $engineVersionCase
    static_characterization = $staticCase
    editor_bootstrap = $editorBootstrapCase
    environment_probe = $environmentCase
    godot_runners = $runnerResults
    runner_summary = [pscustomobject][ordered]@{
        expected_count = $runnerExpectedCount
        executed_count = $runnerResults.Count
        pass_count = $runnerPassCount
    }
    pollution_guard = [pscustomobject][ordered]@{
        status = if ($pollutionPass) { 'PASS' } else { 'FAIL' }
        error = $pollutionGuardError
        git_before = $beforeGit
        git_after = $afterGit
        git_comparison = $gitPollution
        business_before = if ($null -ne $beforeBusiness) { Get-I0PublicBusinessSnapshot -Snapshot $beforeBusiness } else { $null }
        business_after = if ($null -ne $afterBusiness) { Get-I0PublicBusinessSnapshot -Snapshot $afterBusiness } else { $null }
        business_comparison = $businessPollution
    }
}

Write-I0Json -Value $report -Path $reportPath
Write-Output "I0_TEST_REPORT=$reportPath"
Write-Output "I0_TEST_RUN_ROOT=$runRoot"
Write-Output "I0_TEST_STATUS=$($report.overall_status)"
if ($allCasesPass) {
    exit 0
}
exit 1
