param(
    [string]$RepoRoot = ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))),

    [string]$GitRepoRoot = "",

    [ValidateSet("worktree", "head")]
    [string]$SourceMode = "worktree",

    [string]$ManifestPath = (Join-Path $PSScriptRoot "validation_manifest.json"),

    [string]$ExpectedManifestSha256 = "",

    [string]$ReportPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$script:I1Failures = New-Object System.Collections.Generic.List[string]
$script:I1Checks = New-Object System.Collections.Generic.List[object]


function Get-I1FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}


function Get-I1JsonFileSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)
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


function Test-I1PathWithin {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root,
        [switch]$AllowRoot
    )
    $fullPath = Get-I1FullPath -Path $Path
    $fullRoot = Get-I1FullPath -Path $Root
    if ($AllowRoot -and [string]::Equals($fullPath, $fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $fullPath.StartsWith($fullRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)
}


function Add-I1Check {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][bool]$Passed,
        [Parameter(Mandatory = $true)][string]$Detail
    )
    [void]$script:I1Checks.Add([pscustomobject][ordered]@{
        id = $Id
        status = if ($Passed) { 'PASS' } else { 'FAIL' }
        detail = $Detail
    })
    if (-not $Passed) {
        [void]$script:I1Failures.Add("${Id}: $Detail")
    }
}


function Test-I1SafeRelativePath {
    param([AllowEmptyString()][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or [System.IO.Path]::IsPathRooted($Path)) {
        return $false
    }
    $segments = @($Path.Replace('\', '/').Split('/'))
    return @($segments | Where-Object { [string]::IsNullOrWhiteSpace($_) -or $_ -in @('.', '..') }).Count -eq 0
}


function Resolve-I1RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )
    if (-not (Test-I1SafeRelativePath -Path $RelativePath)) {
        throw "Unsafe relative path: $RelativePath"
    }
    $resolved = Get-I1FullPath -Path (Join-Path $Root $RelativePath.Replace('/', '\'))
    if (-not (Test-I1PathWithin -Path $resolved -Root $Root)) {
        throw "Relative path escapes root: $RelativePath"
    }
    return $resolved
}


function Get-I1RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Root
    )
    $fullPath = Get-I1FullPath -Path $Path
    $fullRoot = Get-I1FullPath -Path $Root
    if (-not (Test-I1PathWithin -Path $fullPath -Root $fullRoot)) {
        throw "Path is outside root: $fullPath"
    }
    return $fullPath.Substring($fullRoot.Length + 1).Replace('\', '/')
}


function Get-I1DuplicateValues {
    param([object[]]$Values)
    return @($Values | ForEach-Object { [string]$_ } | Group-Object -CaseSensitive | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
}


function Test-I1SameSet {
    param([object[]]$Left, [object[]]$Right)
    $leftValues = @($Left | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    $rightValues = @($Right | ForEach-Object { [string]$_ } | Sort-Object -Unique)
    return @(Compare-Object -ReferenceObject $leftValues -DifferenceObject $rightValues -CaseSensitive).Count -eq 0
}


function Test-I1RelativePathCoveredByRoots {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][object[]]$Roots
    )
    $pathValue = $RelativePath.Replace('\', '/').Trim('/')
    foreach ($rootValue in $Roots) {
        $root = ([string]$rootValue).Replace('\', '/').Trim('/')
        if ([string]::Equals($pathValue, $root, [System.StringComparison]::OrdinalIgnoreCase) -or $pathValue.StartsWith($root + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }
    return $false
}


function Add-I1ExactCleanupContractChecks {
    param(
        [Parameter(Mandatory = $true)][string]$IdPrefix,
        [object[]]$Diagnostics = @()
    )
    $values = @()
    if ($null -ne $Diagnostics) {
        $values = @($Diagnostics | ForEach-Object { [string]$_ })
    }
    $duplicates = @(Get-I1DuplicateValues -Values $values)
    $duplicateDetail = if ($duplicates.Count -eq 0) { 'unique' } else { $duplicates -join ' || ' }
    Add-I1Check -Id ($IdPrefix + '_UNIQUE') -Passed ($duplicates.Count -eq 0) -Detail $duplicateDetail
    for ($index = 0; $index -lt $values.Count; $index++) {
        $value = $values[$index]
        $valid = (-not [string]::IsNullOrWhiteSpace($value)) -and ($value.IndexOfAny(@([char]10, [char]13)) -lt 0) -and ($value -match '^(?:WARNING: ObjectDB instances leaked at exit \(run with --verbose for details\)\.|ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.)$')
        Add-I1Check -Id ($IdPrefix + '_LINE_' + $index) -Passed $valid -Detail $value
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


$repo = $null
$gitRepo = $null
$manifest = $null
$manifestRaw = $null
$manifestSha256 = $null
$registeredRunnerIds = @()
$inventoryPaths = @()
$excludedRecords = @()
$fatalError = $null

try {
    $repo = Get-I1FullPath -Path $RepoRoot
    if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
        throw "Repository or snapshot root does not exist: $repo"
    }

    $gitCandidate = if ([string]::IsNullOrWhiteSpace($GitRepoRoot)) { $repo } else { Get-I1FullPath -Path $GitRepoRoot }
    $gitOutput = @(& git.exe -C $gitCandidate rev-parse --show-toplevel 2>&1)
    $gitExitCode = $LASTEXITCODE
    if ($gitExitCode -ne 0) {
        throw "Unable to resolve active Git worktree root: $($gitOutput -join ' ')"
    }
    $gitRepo = Get-I1FullPath -Path ([string]$gitOutput[-1])
    Add-I1Check -Id 'ACTIVE_GIT_ROOT' -Passed ([string]::Equals($gitRepo, $gitCandidate, [System.StringComparison]::OrdinalIgnoreCase)) -Detail "resolved=$gitRepo requested=$gitCandidate"

    $approvedManifestPath = Get-I1FullPath -Path (Join-Path $PSScriptRoot 'validation_manifest.json')
    $requestedManifestPath = Get-I1FullPath -Path $ManifestPath
    Add-I1Check -Id 'COLOCATED_MANIFEST' -Passed ([string]::Equals($approvedManifestPath, $requestedManifestPath, [System.StringComparison]::OrdinalIgnoreCase)) -Detail "manifest=$requestedManifestPath"
    if (-not (Test-Path -LiteralPath $requestedManifestPath -PathType Leaf)) {
        throw "I1 validation manifest is missing: $requestedManifestPath"
    }
    $manifestSnapshot = Get-I1JsonFileSnapshot -Path $requestedManifestPath
    $manifestSha256 = [string]$manifestSnapshot.sha256
    Add-I1Check -Id 'MANIFEST_SHA256_BINDING' -Passed ([string]::IsNullOrWhiteSpace($ExpectedManifestSha256) -or [string]::Equals($manifestSha256, $ExpectedManifestSha256.ToUpperInvariant(), [System.StringComparison]::Ordinal)) -Detail "expected=$ExpectedManifestSha256 actual=$manifestSha256"
    $manifestRaw = [string]$manifestSnapshot.raw
    $manifest = $manifestSnapshot.value

    Add-I1Check -Id 'MANIFEST_SCHEMA' -Passed (([int]$manifest.schema_version -eq 1) -and ([string]$manifest.suite_id -ceq 'I1-V1_unified_headless_baseline') -and ([string]$manifest.path_policy -ceq 'runtime_parameters')) -Detail "schema=$($manifest.schema_version) suite=$($manifest.suite_id) policy=$($manifest.path_policy)"
    Add-I1Check -Id 'NO_LEGACY_COUNT_ASSERTIONS' -Passed ($manifestRaw -notmatch '"(?:expected_runner_case_count|asset_manifest_expected_data_row_count)"') -Detail 'No fixed total-runner or asset-row assertion is allowed in I1-V1.'
    Add-I1Check -Id 'MIRROR_RUN_ROOT_FIXED' -Passed ([string]$manifest.mirror.run_root_relative_path -ceq '.tmp/i1') -Detail ([string]$manifest.mirror.run_root_relative_path)
    Add-I1Check -Id 'MIRROR_DIRECTORY_FIXED' -Passed ([string]$manifest.mirror.worktree_directory -ceq 'worktree') -Detail ([string]$manifest.mirror.worktree_directory)
    Add-I1Check -Id 'I0_LIBRARY_PATH_FIXED' -Passed ([string]$manifest.godot.i0_library_relative_path -ceq 'tools/i0/i0_test_lib.ps1') -Detail ([string]$manifest.godot.i0_library_relative_path)

    $requiredBusinessRoots = @('Godot/GraytailGodot', 'tools')
    $businessRootValues = @($manifest.business_roots | ForEach-Object { ([string]$_).Replace('\', '/').Trim('/') })
    $businessRootDuplicates = @(Get-I1DuplicateValues -Values $businessRootValues)
    $businessRootDuplicateDetail = if ($businessRootDuplicates.Count -eq 0) { 'unique' } else { $businessRootDuplicates -join ',' }
    Add-I1Check -Id 'BUSINESS_ROOTS_EXACT' -Passed (Test-I1SameSet -Left $businessRootValues -Right $requiredBusinessRoots) -Detail ($businessRootValues -join ',')
    Add-I1Check -Id 'BUSINESS_ROOTS_UNIQUE' -Passed ($businessRootDuplicates.Count -eq 0) -Detail $businessRootDuplicateDetail
    foreach ($businessRootRelative in $businessRootValues) {
        $businessRoot = Resolve-I1RelativePath -Root $repo -RelativePath $businessRootRelative
        Add-I1Check -Id ('BUSINESS_ROOT_' + ($businessRootRelative -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed (Test-Path -LiteralPath $businessRoot -PathType Container) -Detail $businessRootRelative
    }

    $requiredSupportPaths = @(
        [string]$manifest.godot.toolchain_lock_relative_path,
        [string]$manifest.godot.i0_library_relative_path,
        [string]$manifest.godot.environment_probe_relative_path,
        [string]$manifest.i0_manifest_relative_path,
        [string]$manifest.godot.project_relative_path,
        'tools/i0/bootstrap_toolchain.ps1',
        'tools/i1/invoke_i1.ps1',
        'tools/i1/invoke_i1_preview.ps1',
        'tools/i1/validate_static.ps1',
        'tools/i1/validation_manifest.json'
    )
    foreach ($relativePath in $requiredSupportPaths) {
        $supportPath = Resolve-I1RelativePath -Root $repo -RelativePath $relativePath
        Add-I1Check -Id ('SUPPORT_PATH_' + ($relativePath -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed (Test-Path -LiteralPath $supportPath) -Detail $relativePath
        Add-I1Check -Id ('SUPPORT_HASH_COVERAGE_' + ($relativePath -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed (Test-I1RelativePathCoveredByRoots -RelativePath $relativePath -Roots $businessRootValues) -Detail $relativePath
    }
    $attributesRelativePath = '.gitattributes'
    $attributesPath = Resolve-I1RelativePath -Root $repo -RelativePath $attributesRelativePath
    Add-I1Check -Id 'CONTROL_PLANE_PATH_GITATTRIBUTES' -Passed (Test-Path -LiteralPath $attributesPath -PathType Leaf) -Detail $attributesRelativePath
    $attributeLines = if (Test-Path -LiteralPath $attributesPath -PathType Leaf) { @(Get-Content -LiteralPath $attributesPath | ForEach-Object { $_.Trim() }) } else { @() }
    $requiredEolContracts = @(
        '/.gitattributes text eol=lf',
        '/tools/i1/validation_manifest.json text eol=lf',
        '/tools/i1/invoke_i1.ps1 text eol=lf',
        '/tools/i1/invoke_i1_preview.ps1 text eol=lf',
        '/tools/i0/i0_test_lib.ps1 text eol=lf'
    )
    foreach ($eolContract in $requiredEolContracts) {
        Add-I1Check -Id ('CONTROL_PLANE_EOL_' + ($eolContract -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed ($attributeLines -ccontains $eolContract) -Detail $eolContract
    }
    $invokeSource = Get-Content -LiteralPath (Resolve-I1RelativePath -Root $repo -RelativePath 'tools/i1/invoke_i1.ps1') -Raw
    $previewSource = Get-Content -LiteralPath (Resolve-I1RelativePath -Root $repo -RelativePath 'tools/i1/invoke_i1_preview.ps1') -Raw
    Add-I1Check -Id 'MAIN_BINDS_GITATTRIBUTES' -Passed ($invokeSource.IndexOf("relative_path = '.gitattributes'", [System.StringComparison]::Ordinal) -ge 0) -Detail '.gitattributes is a main control-plane binding'
    Add-I1Check -Id 'PREVIEW_BINDS_GITATTRIBUTES' -Passed ($previewSource.IndexOf("relative_path = '.gitattributes'", [System.StringComparison]::Ordinal) -ge 0) -Detail '.gitattributes is a preview control-plane binding'

    $requiredExcludedNames = @('.tmp', 'reports', 'runtimes')
    $approvedExcludedNames = @('.git', '.godot', '.tmp', '__pycache__', 'reports', 'runtimes')
    $actualExcludedNames = @($manifest.mirror.excluded_directory_names | ForEach-Object { [string]$_ })
    Add-I1Check -Id 'MIRROR_EXCLUSION_SET_EXACT' -Passed (Test-I1SameSet -Left $actualExcludedNames -Right $approvedExcludedNames) -Detail ($actualExcludedNames -join ',')
    foreach ($name in $requiredExcludedNames) {
        Add-I1Check -Id ('MIRROR_EXCLUDES_' + $name.Replace('.', 'DOT').ToUpperInvariant()) -Passed ($actualExcludedNames -ccontains $name) -Detail "excluded directory name=$name"
    }
    $forbiddenPaths = @($manifest.mirror.forbidden_relative_paths | ForEach-Object { ([string]$_).Replace('\', '/') })
    Add-I1Check -Id 'MIRROR_FORBIDDEN_SET_EXACT' -Passed (Test-I1SameSet -Left $forbiddenPaths -Right @('.tmp', 'reports', 'tools/runtimes')) -Detail ($forbiddenPaths -join ',')
    foreach ($relativePath in @('.tmp', 'reports', 'tools/runtimes')) {
        Add-I1Check -Id ('MIRROR_FORBIDS_' + ($relativePath -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed ($forbiddenPaths -ccontains $relativePath) -Detail "forbidden mirror path=$relativePath"
    }

    $requiredRunnerIds = @($manifest.required_runner_ids | ForEach-Object { [string]$_ })
    $requiredDuplicates = @(Get-I1DuplicateValues -Values $requiredRunnerIds)
    $requiredDuplicateDetail = if ($requiredDuplicates.Count -eq 0) { 'unique' } else { $requiredDuplicates -join ',' }
    Add-I1Check -Id 'REQUIRED_RUNNER_IDS_UNIQUE' -Passed ($requiredDuplicates.Count -eq 0) -Detail $requiredDuplicateDetail

    $runnerById = @{}
    $registeredPathSet = @{}
    foreach ($runner in @($manifest.runners)) {
        $runnerId = [string]$runner.id
        if ($runnerId -notmatch '^[A-Z0-9_]+$') {
            Add-I1Check -Id 'RUNNER_ID_FORMAT' -Passed $false -Detail "unsafe runner id=$runnerId"
            continue
        }
        if ($runnerById.ContainsKey($runnerId)) {
            Add-I1Check -Id ('RUNNER_DUPLICATE_' + $runnerId) -Passed $false -Detail "duplicate runner id=$runnerId"
            continue
        }
        $runnerById[$runnerId] = $runner
        $relativePath = [string]$runner.relative_path
        try {
            $runnerPath = Resolve-I1RelativePath -Root $repo -RelativePath $relativePath
            Add-I1Check -Id ('RUNNER_FILE_' + $runnerId) -Passed (Test-Path -LiteralPath $runnerPath -PathType Leaf) -Detail $relativePath
            Add-I1Check -Id ('RUNNER_HASH_COVERAGE_' + $runnerId) -Passed (Test-I1RelativePathCoveredByRoots -RelativePath $relativePath -Roots $businessRootValues) -Detail $relativePath
            $registeredPathSet[$relativePath.Replace('\', '/')] = $true
        }
        catch {
            Add-I1Check -Id ('RUNNER_FILE_' + $runnerId) -Passed $false -Detail $_.Exception.Message
        }

        $passMarker = [string]$runner.pass_marker
        $failMarker = [string]$runner.fail_marker
        $markerValid = (-not [string]::IsNullOrWhiteSpace($passMarker)) -and (-not [string]::IsNullOrWhiteSpace($failMarker)) -and ($passMarker -cne $failMarker) -and ($passMarker.IndexOfAny(@([char]10, [char]13)) -lt 0) -and ($failMarker.IndexOfAny(@([char]10, [char]13)) -lt 0)
        Add-I1Check -Id ('RUNNER_MARKERS_' + $runnerId) -Passed $markerValid -Detail "pass=$passMarker fail=$failMarker"
        $passRegex = [string](Get-I1PropertyValue -Object $runner -Name 'pass_line_regex' -Default '')
        if (-not [string]::IsNullOrWhiteSpace($passRegex)) {
            $regexValid = $passRegex.StartsWith('^', [System.StringComparison]::Ordinal) -and $passRegex.EndsWith('$', [System.StringComparison]::Ordinal)
            try { [void][regex]::new($passRegex) } catch { $regexValid = $false }
            Add-I1Check -Id ('RUNNER_PASS_REGEX_' + $runnerId) -Passed $regexValid -Detail $passRegex
        }
        foreach ($rawUserArg in @((Get-I1PropertyValue -Object $runner -Name 'user_args' -Default @()))) {
            $userArg = [string]$rawUserArg
            Add-I1Check -Id ('RUNNER_ARG_' + $runnerId + '_' + ($userArg -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed ($userArg.Length -ge 3 -and $userArg.Length -le 128 -and $userArg -match '^--[a-z0-9][a-z0-9._-]*(=[a-z0-9][a-z0-9._-]*)?$') -Detail $userArg
        }
        $runnerTimeout = Get-I1PropertyValue -Object $runner -Name 'timeout_seconds' -Default $manifest.timeouts_seconds.runner
        Add-I1Check -Id ('RUNNER_TIMEOUT_' + $runnerId) -Passed (([int]$runnerTimeout -ge 1) -and ([int]$runnerTimeout -le 3600)) -Detail ([string]$runnerTimeout)
    }
    $registeredRunnerIds = @($runnerById.Keys | Sort-Object)

    foreach ($requiredRunnerId in $requiredRunnerIds) {
        Add-I1Check -Id ('REQUIRED_REGISTERED_' + $requiredRunnerId) -Passed $runnerById.ContainsKey($requiredRunnerId) -Detail $requiredRunnerId
    }
    foreach ($registeredRunnerId in $registeredRunnerIds) {
        Add-I1Check -Id ('REGISTERED_REQUIRED_' + $registeredRunnerId) -Passed ($requiredRunnerIds -ccontains $registeredRunnerId) -Detail $registeredRunnerId
    }

    $legacyCleanupPatterns = $manifest.diagnostics.PSObject.Properties['cleanup_patterns']
    Add-I1Check -Id 'NO_BROAD_CLEANUP_PATTERNS' -Passed ($null -eq $legacyCleanupPatterns) -Detail 'cleanup diagnostics must be exact gate/runner contracts'
    $gateCleanupMap = Get-I1PropertyValue -Object $manifest.diagnostics -Name 'expected_cleanup_diagnostics_by_gate' -Default ([pscustomobject]@{})
    $requiredGateCleanupIds = @('editor_bootstrap', 'environment_isolation')
    $gateCleanupIds = @($gateCleanupMap.PSObject.Properties | ForEach-Object { [string]$_.Name })
    Add-I1Check -Id 'GATE_CLEANUP_CONTRACT_KEYS' -Passed (Test-I1SameSet -Left $gateCleanupIds -Right $requiredGateCleanupIds) -Detail ($gateCleanupIds -join ',')
    foreach ($gateId in $requiredGateCleanupIds) {
        $gateProperty = $gateCleanupMap.PSObject.Properties[$gateId]
        $expected = @()
        if ($null -ne $gateProperty) {
            $expected = @($gateProperty.Value)
        }
        Add-I1ExactCleanupContractChecks -IdPrefix ('GATE_CLEANUP_' + $gateId.ToUpperInvariant()) -Diagnostics $expected
        Add-I1Check -Id ('GATE_CLEANUP_' + $gateId.ToUpperInvariant() + '_EMPTY') -Passed ($expected.Count -eq 0) -Detail 'bootstrap and environment isolation expect no cleanup diagnostics'
    }

    $runnerCleanupMap = Get-I1PropertyValue -Object $manifest.diagnostics -Name 'expected_cleanup_diagnostics_by_runner' -Default ([pscustomobject]@{})
    $runnerCleanupIds = @($runnerCleanupMap.PSObject.Properties | ForEach-Object { [string]$_.Name })
    Add-I1Check -Id 'RUNNER_CLEANUP_CONTRACT_KEYS' -Passed (Test-I1SameSet -Left $runnerCleanupIds -Right $requiredRunnerIds) -Detail 'cleanup keys must equal required_runner_ids'
    foreach ($runnerId in $requiredRunnerIds) {
        $cleanupProperty = $runnerCleanupMap.PSObject.Properties[$runnerId]
        $expected = @()
        if ($null -ne $cleanupProperty) {
            $expected = @($cleanupProperty.Value)
        }
        Add-I1Check -Id ('RUNNER_CLEANUP_CONTRACT_' + $runnerId + '_PRESENT') -Passed ($null -ne $cleanupProperty) -Detail $runnerId
        Add-I1ExactCleanupContractChecks -IdPrefix ('RUNNER_CLEANUP_' + $runnerId) -Diagnostics $expected
    }

    $previewCleanupMap = Get-I1PropertyValue -Object $manifest.diagnostics -Name 'preview_capture_expected_cleanup_diagnostics_by_scene' -Default ([pscustomobject]@{})
    $requiredPreviewSceneIds = @('main_menu', 'deploy', 'long_term', 'run', 'combat', 'inventory', 'map', 'result_success', 'result_failure')
    $previewCleanupIds = @($previewCleanupMap.PSObject.Properties | ForEach-Object { [string]$_.Name })
    Add-I1Check -Id 'PREVIEW_CLEANUP_CONTRACT_KEYS' -Passed (Test-I1SameSet -Left $previewCleanupIds -Right $requiredPreviewSceneIds) -Detail ($previewCleanupIds -join ',')
    foreach ($sceneId in $requiredPreviewSceneIds) {
        $cleanupProperty = $previewCleanupMap.PSObject.Properties[$sceneId]
        $expected = @()
        if ($null -ne $cleanupProperty) {
            $expected = @($cleanupProperty.Value)
        }
        Add-I1Check -Id ('PREVIEW_CLEANUP_CONTRACT_' + $sceneId.ToUpperInvariant() + '_PRESENT') -Passed ($null -ne $cleanupProperty) -Detail $sceneId
        Add-I1ExactCleanupContractChecks -IdPrefix ('PREVIEW_CLEANUP_' + $sceneId.ToUpperInvariant()) -Diagnostics $expected
    }

    $expectedProfiles = @('preflight', 'quick', 'core', 'ui', 'performance', 'full')
    foreach ($profileName in $expectedProfiles) {
        $profileProperty = $manifest.profiles.PSObject.Properties[$profileName]
        if ($null -eq $profileProperty) {
            Add-I1Check -Id ('PROFILE_' + $profileName.ToUpperInvariant()) -Passed $false -Detail 'profile is missing'
            continue
        }
        $profileIds = @($profileProperty.Value.runner_ids | ForEach-Object { [string]$_ })
        $profileDuplicates = @(Get-I1DuplicateValues -Values $profileIds)
        $profileDuplicateDetail = if ($profileDuplicates.Count -eq 0) { 'unique' } else { $profileDuplicates -join ',' }
        Add-I1Check -Id ('PROFILE_UNIQUE_' + $profileName.ToUpperInvariant()) -Passed ($profileDuplicates.Count -eq 0) -Detail $profileDuplicateDetail
        foreach ($profileId in $profileIds) {
            Add-I1Check -Id ('PROFILE_' + $profileName.ToUpperInvariant() + '_REGISTERED_' + $profileId) -Passed $runnerById.ContainsKey($profileId) -Detail $profileId
        }
    }
    $preflightIds = @($manifest.profiles.preflight.runner_ids)
    Add-I1Check -Id 'PREFLIGHT_HAS_NO_RUNNERS' -Passed ($preflightIds.Count -eq 0) -Detail 'preflight only validates infrastructure and isolation'
    Add-I1Check -Id 'PERFORMANCE_PROFILE_EXACT' -Passed (Test-I1SameSet -Left @($manifest.profiles.performance.runner_ids) -Right @('I2_COMBAT_FRAME_BASELINE')) -Detail 'performance profile must run the frozen I2 combat workload only'
    Add-I1Check -Id 'FULL_PROFILE_COMPLETE' -Passed (Test-I1SameSet -Left @($manifest.profiles.full.runner_ids) -Right $requiredRunnerIds) -Detail 'full profile must equal required_runner_ids as a set'

    $i0ManifestPath = Resolve-I1RelativePath -Root $repo -RelativePath ([string]$manifest.i0_manifest_relative_path)
    $i0Manifest = Get-Content -LiteralPath $i0ManifestPath -Raw | ConvertFrom-Json
    $i0CurrentIds = @($i0Manifest.runners | ForEach-Object { [string]$_.id })
    $i0RequiredIds = @($manifest.i0_required_runner_ids | ForEach-Object { [string]$_ })
    Add-I1Check -Id 'I0_REQUIRED_IDS_UNIQUE' -Passed (@(Get-I1DuplicateValues -Values $i0RequiredIds).Count -eq 0) -Detail 'I0 required IDs are unique'
    Add-I1Check -Id 'I0_REGISTRATION_COMPLETE' -Passed (Test-I1SameSet -Left $i0CurrentIds -Right $i0RequiredIds) -Detail 'I1 I0 registration must match the current I0 manifest IDs; no count constant is used'
    foreach ($i0Runner in @($i0Manifest.runners)) {
        $i0Id = [string]$i0Runner.id
        if (-not $runnerById.ContainsKey($i0Id)) {
            continue
        }
        $i1Runner = $runnerById[$i0Id]
        $sameContract = ([string]$i1Runner.relative_path -ceq [string]$i0Runner.relative_path) -and ([string]$i1Runner.pass_marker -ceq [string]$i0Runner.pass_marker) -and ([string]$i1Runner.fail_marker -ceq [string]$i0Runner.fail_marker)
        $i0Args = @((Get-I1PropertyValue -Object $i0Runner -Name 'user_args' -Default @()) | ForEach-Object { [string]$_ })
        $i1Args = @((Get-I1PropertyValue -Object $i1Runner -Name 'user_args' -Default @()) | ForEach-Object { [string]$_ })
        $sameContract = $sameContract -and (@(Compare-Object -ReferenceObject $i0Args -DifferenceObject $i1Args -CaseSensitive).Count -eq 0)
        Add-I1Check -Id ('I0_CONTRACT_' + $i0Id) -Passed $sameContract -Detail 'path, markers, and user args must match I0'
    }

    $exclusionPathSet = @{}
    $exclusionIds = @()
    $excludedRecords = @($manifest.exclusions)
    foreach ($exclusion in $excludedRecords) {
        $exclusionId = [string]$exclusion.id
        $exclusionIds += $exclusionId
        $category = [string]$exclusion.category
        $disposition = [string]$exclusion.disposition
        $reason = [string]$exclusion.reason
        $validExclusion = ($exclusionId -match '^[A-Z0-9_]+$') -and ($category -in @('capture', 'performance', 'visible')) -and ($disposition -ceq 'EXCLUDED_NON_SLICE') -and (-not [string]::IsNullOrWhiteSpace($reason))
        Add-I1Check -Id ('EXCLUSION_' + $exclusionId) -Passed $validExclusion -Detail "$category/$disposition"
        $relativeValue = Get-I1PropertyValue -Object $exclusion -Name 'relative_path' -Default $null
        if ($null -ne $relativeValue -and -not [string]::IsNullOrWhiteSpace([string]$relativeValue)) {
            $relativePath = ([string]$relativeValue).Replace('\', '/')
            try {
                $exclusionPath = Resolve-I1RelativePath -Root $repo -RelativePath $relativePath
                Add-I1Check -Id ('EXCLUSION_FILE_' + $exclusionId) -Passed (Test-Path -LiteralPath $exclusionPath -PathType Leaf) -Detail $relativePath
                $exclusionPathSet[$relativePath] = $true
            }
            catch {
                Add-I1Check -Id ('EXCLUSION_FILE_' + $exclusionId) -Passed $false -Detail $_.Exception.Message
            }
        }
    }
    Add-I1Check -Id 'EXCLUSION_IDS_UNIQUE' -Passed (@(Get-I1DuplicateValues -Values $exclusionIds).Count -eq 0) -Detail 'exclusion IDs are unique'
    foreach ($requiredCategory in @('capture', 'performance', 'visible')) {
        Add-I1Check -Id ('EXCLUSION_CATEGORY_' + $requiredCategory.ToUpperInvariant()) -Passed (@($excludedRecords | Where-Object { [string]$_.category -ceq $requiredCategory }).Count -gt 0) -Detail "$requiredCategory must be explicitly non-slice"
    }

    $inventory = New-Object System.Collections.Generic.List[string]
    foreach ($source in @($manifest.inventory.sources)) {
        $inventoryRootRelative = [string]$source.root
        $inventoryRoot = Resolve-I1RelativePath -Root $repo -RelativePath $inventoryRootRelative
        if (-not (Test-Path -LiteralPath $inventoryRoot -PathType Container)) {
            Add-I1Check -Id ('INVENTORY_ROOT_' + ($inventoryRootRelative -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed $false -Detail $inventoryRootRelative
            continue
        }
        $fileNameRegex = [string]$source.file_name_regex
        try { [void][regex]::new($fileNameRegex) } catch { throw "Invalid inventory regex for ${inventoryRootRelative}: $fileNameRegex" }
        $recurse = [bool]$source.recurse
        foreach ($file in @(Get-ChildItem -LiteralPath $inventoryRoot -File -Recurse:$recurse | Where-Object { $_.Name -match $fileNameRegex })) {
            [void]$inventory.Add((Get-I1RelativePath -Path $file.FullName -Root $repo))
        }
    }
    $inventoryPaths = @($inventory.ToArray() | Sort-Object -Unique)
    foreach ($inventoryPath in $inventoryPaths) {
        $registered = $registeredPathSet.ContainsKey($inventoryPath)
        $excluded = $exclusionPathSet.ContainsKey($inventoryPath)
        Add-I1Check -Id ('INVENTORY_CLASSIFIED_' + ($inventoryPath -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed ($registered -xor $excluded) -Detail "$inventoryPath registered=$registered excluded=$excluded"
    }
    foreach ($registeredPath in @($registeredPathSet.Keys)) {
        Add-I1Check -Id ('REGISTERED_INVENTORY_' + ($registeredPath -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed ($inventoryPaths -ccontains $registeredPath) -Detail $registeredPath
    }
    foreach ($excludedPath in @($exclusionPathSet.Keys)) {
        Add-I1Check -Id ('EXCLUDED_INVENTORY_' + ($excludedPath -replace '[^A-Za-z0-9]+', '_').Trim('_').ToUpperInvariant()) -Passed ($inventoryPaths -ccontains $excludedPath) -Detail $excludedPath
    }
}
catch {
    $fatalError = [pscustomobject][ordered]@{
        message = $_.Exception.Message
        type = $_.Exception.GetType().FullName
        script_stack_trace = $_.ScriptStackTrace
    }
    [void]$script:I1Failures.Add("FATAL: $($_.Exception.Message)")
}

$report = [pscustomobject][ordered]@{
    suite_id = 'I1-V1_unified_headless_baseline'
    source_mode = $SourceMode
    manifest_sha256 = $manifestSha256
    expected_manifest_sha256 = $ExpectedManifestSha256
    repo_root = $repo
    active_git_root = $gitRepo
    status = if ($script:I1Failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
    registered_runner_ids = @($registeredRunnerIds)
    inventory_paths = @($inventoryPaths)
    exclusions = @($excludedRecords | ForEach-Object {
        [pscustomobject][ordered]@{
            id = [string]$_.id
            relative_path = Get-I1PropertyValue -Object $_ -Name 'relative_path' -Default $null
            category = [string]$_.category
            status = [string]$_.disposition
            reason = [string]$_.reason
        }
    })
    checks = $script:I1Checks.ToArray()
    failures = $script:I1Failures.ToArray()
    fatal_error = $fatalError
}

if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $fullReportPath = Get-I1FullPath -Path $ReportPath
    if ($null -ne $gitRepo -and -not (Test-I1PathWithin -Path $fullReportPath -Root $gitRepo)) {
        throw "Static report path must stay inside the active worktree: $fullReportPath"
    }
    $reportParent = Split-Path -Parent $fullReportPath
    [void](New-Item -ItemType Directory -Path $reportParent -Force)
    [System.IO.File]::WriteAllText($fullReportPath, (($report | ConvertTo-Json -Depth 30) + "`r`n"), (New-Object System.Text.UTF8Encoding($false)))
}

Write-Output ('I1_STATIC_VALIDATION_JSON=' + ($report | ConvertTo-Json -Depth 30 -Compress))
if ([string]$report.status -cne 'PASS') {
    exit 1
}
