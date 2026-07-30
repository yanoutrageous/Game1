[CmdletBinding()]
param(
    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [string]$RepoRoot = '',

    [string]$GodotExe = '',

    [string]$OutputRoot = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Get-I4Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
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

function Get-I4PngSize {
    param([Parameter(Mandatory = $true)][string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if (
        $bytes.Length -lt 24 -or
        $bytes[0] -ne 0x89 -or
        $bytes[1] -ne 0x50 -or
        $bytes[2] -ne 0x4E -or
        $bytes[3] -ne 0x47
    ) {
        throw "Capture is not a decodable PNG header: $Path"
    }
    $widthBytes = [byte[]]@($bytes[16], $bytes[17], $bytes[18], $bytes[19])
    $heightBytes = [byte[]]@($bytes[20], $bytes[21], $bytes[22], $bytes[23])
    if ([BitConverter]::IsLittleEndian) {
        [Array]::Reverse($widthBytes)
        [Array]::Reverse($heightBytes)
    }
    return [pscustomobject]@{
        width = [BitConverter]::ToUInt32($widthBytes, 0)
        height = [BitConverter]::ToUInt32($heightBytes, 0)
    }
}

function Get-I4RelativeOutputPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (
        -not $fullPath.StartsWith(
            $script:resolvedOutputRoot.TrimEnd('\') + '\',
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {
        throw "Evidence path escaped OutputRoot: $fullPath"
    }
    return $fullPath.Substring($script:resolvedOutputRoot.TrimEnd('\').Length + 1).Replace('\', '/')
}

function Invoke-I4GodotCapture {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Runner,
        [Parameter(Mandatory = $true)][string[]]$UserArguments,
        [Parameter(Mandatory = $true)][string]$PassRegex,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds
    )
    $stdoutPath = Join-Path $script:logRoot "$Id.stdout.log"
    $stderrPath = Join-Path $script:logRoot "$Id.stderr.log"
    $engineLogPath = Join-Path $script:logRoot "$Id.engine.log"
    $arguments = @(
        '--disable-vsync',
        '--max-fps', '0',
        '--audio-driver', 'Dummy',
        '--path', $script:projectRoot,
        '--log-file', $engineLogPath,
        '--script', $Runner,
        '--'
    ) + $UserArguments
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $script:GodotExe
    $startInfo.Arguments = (@(
        $arguments | ForEach-Object {
            ConvertTo-I4ProcessArgument -Value ([string]$_)
        }
    ) -join ' ')
    $startInfo.WorkingDirectory = $script:projectRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $startInfo.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $started = [DateTime]::UtcNow
    $stdout = ''
    $stderr = ''
    $exitCode = -1
    try {
        if (-not $process.Start()) {
            throw "Could not start real-render capture process: $Id"
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            try {
                $process.Kill()
                $process.WaitForExit()
            }
            catch {
            }
            throw "Real-render capture timed out after ${TimeoutSeconds}s: $Id"
        }
        $process.WaitForExit()
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $exitCode = $process.ExitCode
    }
    finally {
        $process.Dispose()
    }
    Write-I4Text -Path $stdoutPath -Text $stdout
    Write-I4Text -Path $stderrPath -Text $stderr
    $engineText = ''
    if (Test-Path -LiteralPath $engineLogPath -PathType Leaf) {
        $engineText = [System.IO.File]::ReadAllText(
            $engineLogPath,
            [System.Text.Encoding]::UTF8
        )
    }
    $combined = $stdout + "`n" + $stderr + "`n" + $engineText
    if ($exitCode -ne 0 -or -not [regex]::IsMatch($combined, $PassRegex)) {
        throw "Real-render capture failed or omitted its exact marker: $Id"
    }
    $diagnosticLines = @(
        [regex]::Matches(
            $combined,
            '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$'
        ) | ForEach-Object { $_.Value.Trim() } | Select-Object -Unique
    )
    $cleanupDiagnostics = @(
        $diagnosticLines | Where-Object {
            $_ -cmatch '^WARNING: ObjectDB instances leaked at exit \(run with --verbose for details\)\.$' -or
            $_ -cmatch '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
        }
    )
    $blockingDiagnostics = @(
        $diagnosticLines | Where-Object {
            $_ -cnotin $cleanupDiagnostics
        }
    )
    if ($blockingDiagnostics.Count -gt 0) {
        throw "Real-render capture emitted a blocking diagnostic: $Id"
    }
    return [pscustomobject][ordered]@{
        id = $Id
        status = 'PASS'
        runner = $Runner
        timeout_seconds = $TimeoutSeconds
        started_utc = $started.ToString('o')
        finished_utc = [DateTime]::UtcNow.ToString('o')
        stdout_path = Get-I4RelativeOutputPath -Path $stdoutPath
        stdout_sha256 = Get-I4Sha256 -Path $stdoutPath
        stderr_path = Get-I4RelativeOutputPath -Path $stderrPath
        stderr_sha256 = Get-I4Sha256 -Path $stderrPath
        engine_log_path = Get-I4RelativeOutputPath -Path $engineLogPath
        engine_log_sha256 = if (Test-Path -LiteralPath $engineLogPath -PathType Leaf) {
            Get-I4Sha256 -Path $engineLogPath
        }
        else {
            ''
        }
        cleanup_diagnostics = $cleanupDiagnostics
        blocking_diagnostics = $blockingDiagnostics
    }
}

function Add-I4ImageEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Surface,
        [Parameter(Mandatory = $true)][string]$RenderState,
        [Parameter(Mandatory = $true)][string]$CaseId,
        [Parameter(Mandatory = $true)][string[]]$CensusStateIds
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Expected real-render evidence is missing: $Path"
    }
    $fullPath = (Resolve-Path -LiteralPath $Path).Path
    if ($script:imagePathSet.ContainsKey($fullPath)) {
        throw "One PNG was registered more than once: $fullPath"
    }
    if (-not $script:caseById.ContainsKey($CaseId)) {
        throw "Unknown matrix case for image evidence: $CaseId"
    }
    $case = $script:caseById[$CaseId]
    $size = Get-I4PngSize -Path $fullPath
    if (
        [int]$size.width -ne [int]$case.width -or
        [int]$size.height -ne [int]$case.height
    ) {
        throw (
            "PNG dimensions do not match matrix case {0}: actual={1}x{2} expected={3}x{4} path={5}" -f
            $CaseId,
            $size.width,
            $size.height,
            $case.width,
            $case.height,
            $fullPath
        )
    }
    $normalizedStateIds = @(
        $CensusStateIds |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Unique
    )
    if ($normalizedStateIds.Count -eq 0) {
        throw "Image evidence has no census row association: $fullPath"
    }
    foreach ($stateId in $normalizedStateIds) {
        if (-not $script:censusByStateId.ContainsKey($stateId)) {
            throw "Image evidence references a nonexistent census state: $stateId"
        }
    }
    $relativePath = Get-I4RelativeOutputPath -Path $fullPath
    $image = [pscustomobject][ordered]@{
        surface = $Surface
        render_state = $RenderState
        matrix_case = $CaseId
        width = [int]$size.width
        height = [int]$size.height
        ui_scale_percent = [int]$case.ui_scale_percent
        census_state_ids = $normalizedStateIds
        bytes = (Get-Item -LiteralPath $fullPath).Length
        sha256 = Get-I4Sha256 -Path $fullPath
        path = $relativePath
    }
    [void]$script:images.Add($image)
    $script:imagePathSet[$fullPath] = $true
    foreach ($stateId in $normalizedStateIds) {
        $coverageKey = $stateId + "`n" + $CaseId
        if (-not $script:coverageIndex.ContainsKey($coverageKey)) {
            $script:coverageIndex[$coverageKey] = New-Object System.Collections.Generic.List[string]
        }
        $paths = $script:coverageIndex[$coverageKey]
        if (-not $paths.Contains($relativePath)) {
            [void]$paths.Add($relativePath)
        }
    }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
}
$resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd('\')
$observedRoot = (& git.exe -C $resolvedRoot rev-parse --show-toplevel).Trim()
if (
    $LASTEXITCODE -ne 0 -or
    (Resolve-Path -LiteralPath $observedRoot).Path.TrimEnd('\') -ne $resolvedRoot
) {
    throw "RepoRoot is not the active Git worktree root: $resolvedRoot"
}

if ([string]::IsNullOrWhiteSpace($GodotExe)) {
    foreach ($candidate in @(
        $env:I1_GODOT_EXE,
        $env:GODOT4,
        $env:GODOT_EXE,
        'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
    )) {
        if (
            -not [string]::IsNullOrWhiteSpace($candidate) -and
            (Test-Path -LiteralPath $candidate -PathType Leaf)
        ) {
            $GodotExe = (Resolve-Path -LiteralPath $candidate).Path
            break
        }
    }
}
if (
    [string]::IsNullOrWhiteSpace($GodotExe) -or
    -not (Test-Path -LiteralPath $GodotExe -PathType Leaf)
) {
    throw 'Godot 4.6.3 console executable could not be resolved.'
}
$script:GodotExe = (Resolve-Path -LiteralPath $GodotExe).Path

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $OutputRoot = Join-Path $resolvedRoot ".tmp\i4\census_matrix\$runId"
}
$script:resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot).TrimEnd('\')
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot '.tmp')).TrimEnd('\')
if (
    -not $script:resolvedOutputRoot.StartsWith(
        $tmpRoot + '\',
        [System.StringComparison]::OrdinalIgnoreCase
    )
) {
    throw "OutputRoot must stay below the repository .tmp directory: $script:resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $script:resolvedOutputRoot -Force)
$script:logRoot = Join-Path $script:resolvedOutputRoot 'logs'
[void](New-Item -ItemType Directory -Path $script:logRoot -Force)
$script:projectRoot = Join-Path $resolvedRoot 'Godot\GraytailGodot'

$statusBefore = @(
    & git.exe -c core.quotepath=false -C $resolvedRoot status --porcelain=v1 --untracked-files=all
)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read initial Git status.'
}
if ($SourceMode -ceq 'head' -and $statusBefore.Count -ne 0) {
    throw 'SourceMode=head requires an entirely clean worktree.'
}
$head = (& git.exe -C $resolvedRoot rev-parse HEAD).Trim()
$headTree = (& git.exe -C $resolvedRoot rev-parse 'HEAD^{tree}').Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to resolve the capture Git identity.'
}

$matrix = @(
    [pscustomobject]@{ id = '1280x720-ui100'; width = 1280; height = 720; ui_scale = 1.0; ui_scale_percent = 100 },
    [pscustomobject]@{ id = '1280x720-ui125'; width = 1280; height = 720; ui_scale = 1.25; ui_scale_percent = 125 },
    [pscustomobject]@{ id = '1280x720-ui150'; width = 1280; height = 720; ui_scale = 1.5; ui_scale_percent = 150 },
    [pscustomobject]@{ id = '1366x768-ui100'; width = 1366; height = 768; ui_scale = 1.0; ui_scale_percent = 100 },
    [pscustomobject]@{ id = '1366x768-ui125'; width = 1366; height = 768; ui_scale = 1.25; ui_scale_percent = 125 },
    [pscustomobject]@{ id = '1366x768-ui150'; width = 1366; height = 768; ui_scale = 1.5; ui_scale_percent = 150 },
    [pscustomobject]@{ id = '1600x900-ui100'; width = 1600; height = 900; ui_scale = 1.0; ui_scale_percent = 100 },
    [pscustomobject]@{ id = '1600x900-ui125'; width = 1600; height = 900; ui_scale = 1.25; ui_scale_percent = 125 },
    [pscustomobject]@{ id = '1600x900-ui150'; width = 1600; height = 900; ui_scale = 1.5; ui_scale_percent = 150 },
    [pscustomobject]@{ id = '1920x1080-ui100'; width = 1920; height = 1080; ui_scale = 1.0; ui_scale_percent = 100 },
    [pscustomobject]@{ id = '1920x1080-ui125'; width = 1920; height = 1080; ui_scale = 1.25; ui_scale_percent = 125 },
    [pscustomobject]@{ id = '1920x1080-ui150'; width = 1920; height = 1080; ui_scale = 1.5; ui_scale_percent = 150 }
)
$script:caseById = @{}
foreach ($case in $matrix) {
    $script:caseById[[string]$case.id] = $case
}

$censusRoot = Join-Path $script:resolvedOutputRoot 'census'
[void](New-Item -ItemType Directory -Path $censusRoot -Force)
$censusBuildLog = Join-Path $script:logRoot 'content_census.stdout.log'
$buildScript = Join-Path $resolvedRoot 'tools\i4\build_i4_content_census.ps1'
$censusOutput = @(
    & powershell.exe `
        -NoProfile `
        -NonInteractive `
        -ExecutionPolicy Bypass `
        -File $buildScript `
        -SourceMode $SourceMode `
        -RepoRoot $resolvedRoot `
        -GodotExe $script:GodotExe `
        -OutputRoot $censusRoot 2>&1
)
$censusExitCode = $LASTEXITCODE
$censusText = ($censusOutput | ForEach-Object { [string]$_ }) -join "`n"
Write-I4Text -Path $censusBuildLog -Text ($censusText + "`n")
if (
    $censusExitCode -ne 0 -or
    $censusText -notmatch '(?m)^I4_CONTENT_CENSUS_WRAPPER=PASS '
) {
    throw 'The current content census failed or omitted its exact PASS marker.'
}
$censusPath = Join-Path $censusRoot 'content_census.json'
$censusWrapperPath = Join-Path $censusRoot 'wrapper_report.json'
foreach ($requiredPath in @($censusPath, $censusWrapperPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Content-census artifact is missing: $requiredPath"
    }
}
$census = [System.IO.File]::ReadAllText(
    $censusPath,
    [System.Text.Encoding]::UTF8
) | ConvertFrom-Json
$censusRows = @($census.rows)
if (
    [string]$census.status -cne 'PASS' -or
    $censusRows.Count -ne [int]$census.summary.total_rows -or
    [int]$census.summary.high_risk_rows -ne $censusRows.Count
) {
    throw 'Content census is not a complete all-high-risk I4 census.'
}
$script:censusByStateId = @{}
foreach ($row in $censusRows) {
    $stateId = [string]$row.state_id
    if ([string]::IsNullOrWhiteSpace($stateId)) {
        throw 'Content census contains a blank state_id.'
    }
    if ($script:censusByStateId.ContainsKey($stateId)) {
        throw "Content census contains a duplicate state_id: $stateId"
    }
    $script:censusByStateId[$stateId] = $row
}

$startedUtc = [DateTime]::UtcNow
$script:images = New-Object System.Collections.Generic.List[object]
$script:imagePathSet = @{}
$script:coverageIndex = @{}
$processes = New-Object System.Collections.Generic.List[object]
$savedCommit = [Environment]::GetEnvironmentVariable('I4_EVIDENCE_COMMIT', 'Process')
[Environment]::SetEnvironmentVariable('I4_EVIDENCE_COMMIT', $head, 'Process')

try {
    Write-Output 'I4_CENSUS_MATRIX_PROGRESS phase=deploy status=START'
    $deployRoot = Join-Path $script:resolvedOutputRoot 'captures\deploy'
    [void](New-Item -ItemType Directory -Path $deployRoot -Force)
    [void]$processes.Add((
        Invoke-I4GodotCapture `
            -Id 'deploy_census_matrix' `
            -Runner 'res://tests/i4_deploy_information_layout_runner.gd' `
            -UserArguments @(
                "--output=$($deployRoot.Replace('\', '/'))",
                '--capture-scope=census'
            ) `
            -PassRegex '(?m)^I4_DEPLOY_INFORMATION_LAYOUT=PASS .*screenshots=204\r?$' `
            -TimeoutSeconds 900
    ))
    $deployFiles = @(Get-ChildItem -LiteralPath $deployRoot -Filter '*.png' -File)
    $expectedDeployImages = (
        ([int]$census.summary.deploy_filters + [int]$census.summary.deploy_summaries) *
        $matrix.Count
    )
    if ($deployFiles.Count -ne $expectedDeployImages) {
        throw "Deploy census produced $($deployFiles.Count) PNG files; expected $expectedDeployImages."
    }
    foreach ($file in $deployFiles) {
        if (
            $file.BaseName -notmatch
            '^deploy_(?<case>\d+x\d+-ui\d+)__(?<kind>filter|summary)__(?<a>[^_]+)(?:__(?<b>.+))?$'
        ) {
            throw "Unrecognized Deploy census filename: $($file.Name)"
        }
        $caseId = [string]$Matches.case
        if ([string]$Matches.kind -ceq 'filter') {
            $stateId = 'deploy/{0}/filter/{1}' -f $Matches.a, $Matches.b
        }
        else {
            $stateId = 'deploy/summary/{0}' -f $Matches.a
        }
        Add-I4ImageEvidence `
            -Path $file.FullName `
            -Surface 'deploy' `
            -RenderState $file.BaseName `
            -CaseId $caseId `
            -CensusStateIds @($stateId)
    }
    Write-Output "I4_CENSUS_MATRIX_PROGRESS phase=deploy status=PASS images=$($deployFiles.Count)"

    $longTermRoot = Join-Path $script:resolvedOutputRoot 'captures\long_term'
    $assetRoot = Join-Path $script:resolvedOutputRoot 'captures\long_term_assets'
    [void](New-Item -ItemType Directory -Path $longTermRoot -Force)
    [void](New-Item -ItemType Directory -Path $assetRoot -Force)
    foreach ($case in $matrix) {
        $caseId = [string]$case.id
        Write-Output "I4_CENSUS_MATRIX_PROGRESS phase=long_term case=$caseId status=START"
        [void]$processes.Add((
            Invoke-I4GodotCapture `
                -Id "long_term_$caseId" `
                -Runner 'res://tests/art23_long_term_matrix_capture_runner.gd' `
                -UserArguments @(
                    "--output-dir=$($longTermRoot.Replace('\', '/'))",
                    "--width=$($case.width)",
                    "--height=$($case.height)",
                    "--ui-scale=$($case.ui_scale)"
                ) `
                -PassRegex (
                    '(?m)^ART23_MATRIX_CAPTURE=PASS states=25 size={0}x{1} ui_scale={2} ' -f
                    $case.width,
                    $case.height,
                    $case.ui_scale_percent
                ) `
                -TimeoutSeconds 420
        ))
        $caseLongTermFiles = @(
            Get-ChildItem -LiteralPath $longTermRoot -Filter (
                "*__$($case.width)x$($case.height)__ui$($case.ui_scale_percent).png"
            ) -File
        )
        if ($caseLongTermFiles.Count -ne [int]$census.summary.long_term_pages) {
            throw (
                "LongTerm case {0} produced {1} pages; expected {2}." -f
                $caseId,
                $caseLongTermFiles.Count,
                $census.summary.long_term_pages
            )
        }
        foreach ($file in $caseLongTermFiles) {
            if (
                $file.BaseName -notmatch
                '^(?<module>[^_]+(?:_[^_]+)*)__' +
                '(?<page>[^_]+(?:_[^_]+)*)__\d+x\d+__ui\d+$'
            ) {
                throw "Unrecognized LongTerm page filename: $($file.Name)"
            }
            $moduleId = [string]$Matches.module
            $pageId = [string]$Matches.page
            Add-I4ImageEvidence `
                -Path $file.FullName `
                -Surface 'long_term' `
                -RenderState "$moduleId/$pageId" `
                -CaseId $caseId `
                -CensusStateIds @(
                    "long_term/page/$moduleId/$pageId",
                    "long_term/module/$moduleId"
                )
        }

        Write-Output "I4_CENSUS_MATRIX_PROGRESS phase=long_term_assets case=$caseId status=START"
        [void]$processes.Add((
            Invoke-I4GodotCapture `
                -Id "long_term_assets_$caseId" `
                -Runner 'res://tests/i4_long_term_asset_board_runner.gd' `
                -UserArguments @(
                    "--output-dir=$($assetRoot.Replace('\', '/'))",
                    "--width=$($case.width)",
                    "--height=$($case.height)",
                    "--ui-scale=$($case.ui_scale)"
                ) `
                -PassRegex (
                    '(?m)^I4_LONG_TERM_ASSET_BOARD=PASS assets=58 pages=8 size={0}x{1} ui_scale={2} ' -f
                    $case.width,
                    $case.height,
                    $case.ui_scale_percent
                ) `
                -TimeoutSeconds 420
        ))
        $assetIndexPath = Join-Path $assetRoot (
            'long_term_assets__{0}x{1}__ui{2}.json' -f
            $case.width,
            $case.height,
            $case.ui_scale_percent
        )
        if (-not (Test-Path -LiteralPath $assetIndexPath -PathType Leaf)) {
            throw "LongTerm asset-board index is missing: $assetIndexPath"
        }
        $assetIndex = [System.IO.File]::ReadAllText(
            $assetIndexPath,
            [System.Text.Encoding]::UTF8
        ) | ConvertFrom-Json
        if (
            [string]$assetIndex.status -cne 'PASS' -or
            [int]$assetIndex.asset_count -ne [int]$census.summary.long_term_assets -or
            [int]$assetIndex.page_count -ne 8 -or
            @($assetIndex.rows).Count -ne [int]$census.summary.long_term_assets
        ) {
            throw "LongTerm asset-board index is incomplete for $caseId."
        }
        foreach ($pageGroup in @($assetIndex.rows | Group-Object image)) {
            $assetStateIds = @(
                $pageGroup.Group | ForEach-Object {
                    'long_term/asset/' + [string]$_.asset_id
                }
            )
            Add-I4ImageEvidence `
                -Path (Join-Path $assetRoot $pageGroup.Name) `
                -Surface 'long_term_asset_board' `
                -RenderState ([System.IO.Path]::GetFileNameWithoutExtension($pageGroup.Name)) `
                -CaseId $caseId `
                -CensusStateIds $assetStateIds
        }
        Write-Output (
            "I4_CENSUS_MATRIX_PROGRESS phase=long_term case=$caseId status=PASS " +
            "pages=$($caseLongTermFiles.Count) asset_pages=$($assetIndex.page_count)"
        )
    }

    $baseRequests = @(
        [pscustomobject]@{ state = 'main_menu'; census = @('main_menu/default') },
        [pscustomobject]@{ state = 'settings'; census = @('settings/general') },
        [pscustomobject]@{ state = 'run'; census = @('run/surface/hud', 'run/surface/minimap', 'run/surface/quick_bag_empty', 'run/room/normal') },
        [pscustomobject]@{ state = 'map'; census = @('run/surface/map_overlay') },
        [pscustomobject]@{ state = 'inventory_items'; census = @('run/surface/inventory') },
        [pscustomobject]@{ state = 'ground_loot_visual'; census = @('run/surface/ground_loot') },
        [pscustomobject]@{ state = 'chest_open'; census = @('run/room/chest', 'run/surface/interaction') },
        [pscustomobject]@{ state = 'event_options'; census = @('run/room/event') },
        [pscustomobject]@{ state = 'mine'; census = @('run/room/mine') },
        [pscustomobject]@{ state = 'monster'; census = @('run/room/monster') },
        [pscustomobject]@{ state = 'exit'; census = @('run/room/exit') },
        [pscustomobject]@{ state = 'quick_bag_one'; census = @('run/surface/quick_bag_one') },
        [pscustomobject]@{ state = 'quick_bag_three'; census = @('run/surface/quick_bag_three') },
        [pscustomobject]@{ state = 'quick_bag_overflow'; census = @('run/surface/quick_bag_overflow') },
        [pscustomobject]@{ state = 'pause'; census = @('modal/pause') },
        [pscustomobject]@{ state = 'pause_settings'; census = @('modal/settings') },
        [pscustomobject]@{ state = 'exit_confirm'; census = @('modal/confirm') },
        [pscustomobject]@{ state = 'result_success'; census = @('result/success') },
        [pscustomobject]@{ state = 'result_failure'; census = @('result/failure') },
        [pscustomobject]@{ state = 'result_abandon'; census = @('result/abandon') },
        [pscustomobject]@{ state = 'result_save_failed'; census = @('result/save_failure', 'modal/failure') }
    )
    $debugScenarios = @(
        [pscustomobject]@{ id = 'demo_7x7'; seed = 1001 },
        [pscustomobject]@{ id = 'combat_room'; seed = 1101 },
        [pscustomobject]@{ id = 'full_backpack'; seed = 1201 },
        [pscustomobject]@{ id = 'duplicate_items'; seed = 1301 },
        [pscustomobject]@{ id = 'terminal_success_failure'; seed = 1401 },
        [pscustomobject]@{ id = 'persistence_failure'; seed = 1501 }
    )
    if ($debugScenarios.Count -ne [int]$census.summary.scenarios) {
        throw 'Debug scenario capture registry does not match the current census.'
    }
    $productionRoot = Join-Path $script:resolvedOutputRoot 'captures\production'
    [void](New-Item -ItemType Directory -Path $productionRoot -Force)
    foreach ($case in $matrix) {
        $caseId = [string]$case.id
        Write-Output "I4_CENSUS_MATRIX_PROGRESS phase=production case=$caseId status=START"
        $caseProductionRoot = Join-Path $productionRoot $caseId
        $debugRoot = Join-Path $caseProductionRoot 'debug'
        [void](New-Item -ItemType Directory -Path $caseProductionRoot -Force)
        [void](New-Item -ItemType Directory -Path $debugRoot -Force)
        $batchRequests = New-Object System.Collections.Generic.List[object]
        foreach ($definition in $baseRequests) {
            $state = [string]$definition.state
            $outputPath = Join-Path $caseProductionRoot "$state.png"
            [void]$batchRequests.Add([pscustomobject][ordered]@{
                state = $state
                width = [int]$case.width
                height = [int]$case.height
                'ui-scale' = [double]$case.ui_scale
                output = $outputPath.Replace('\', '/')
            })
        }
        foreach ($scenario in $debugScenarios) {
            [void]$batchRequests.Add([pscustomobject][ordered]@{
                state = 'debug_scenario_quad'
                scenario = [string]$scenario.id
                seed = [int]$scenario.seed
                width = [int]$case.width
                height = [int]$case.height
                'ui-scale' = [double]$case.ui_scale
                'output-dir' = $debugRoot.Replace('\', '/')
            })
        }
        $batchManifestPath = Join-Path $caseProductionRoot 'batch_manifest.json'
        Write-I4Text `
            -Path $batchManifestPath `
            -Text (([pscustomobject][ordered]@{
                schema_version = 1
                standard_id = 'I4-QA-FROZEN-1'
                matrix_case = $caseId
                requests = $batchRequests.ToArray()
            } | ConvertTo-Json -Depth 20) + "`r`n")
        [void]$processes.Add((
            Invoke-I4GodotCapture `
                -Id "production_$caseId" `
                -Runner 'res://tests/art25_production_visual_capture_runner.gd' `
                -UserArguments @(
                    "--batch-manifest=$($batchManifestPath.Replace('\', '/'))"
                ) `
                -PassRegex (
                    '(?m)^ART25_PRODUCTION_BATCH=PASS states={0} manifest=' -f
                    $batchRequests.Count
                ) `
                -TimeoutSeconds 1200
        ))
        foreach ($definition in $baseRequests) {
            $state = [string]$definition.state
            $stateIds = @($definition.census | ForEach-Object { [string]$_ })
            Add-I4ImageEvidence `
                -Path (Join-Path $caseProductionRoot "$state.png") `
                -Surface 'production' `
                -RenderState $state `
                -CaseId $caseId `
                -CensusStateIds $stateIds
        }
        foreach ($scenario in $debugScenarios) {
            foreach ($taint in @('clean', 'tainted')) {
                foreach ($panel in @('collapsed', 'expanded')) {
                    $fileName = (
                        '{0}__{1}__{2}__{3}x{4}__ui{5}.png' -f
                        $scenario.id,
                        $taint,
                        $panel,
                        $case.width,
                        $case.height,
                        $case.ui_scale_percent
                    )
                    Add-I4ImageEvidence `
                        -Path (Join-Path $debugRoot $fileName) `
                        -Surface 'debug_scenario' `
                        -RenderState "$($scenario.id)/$taint/$panel" `
                        -CaseId $caseId `
                        -CensusStateIds @(
                            "debug/$($scenario.id)/$taint/$panel"
                        )
                }
            }
        }
        Write-Output (
            "I4_CENSUS_MATRIX_PROGRESS phase=production case=$caseId status=PASS " +
            "images=$($baseRequests.Count + ($debugScenarios.Count * 4))"
        )
    }
}
finally {
    [Environment]::SetEnvironmentVariable('I4_EVIDENCE_COMMIT', $savedCommit, 'Process')
}

$coverageRows = New-Object System.Collections.Generic.List[object]
$missingCoverage = New-Object System.Collections.Generic.List[string]
foreach ($row in $censusRows) {
    $stateId = [string]$row.state_id
    foreach ($case in $matrix) {
        $caseId = [string]$case.id
        $coverageKey = $stateId + "`n" + $caseId
        if (-not $script:coverageIndex.ContainsKey($coverageKey)) {
            [void]$missingCoverage.Add("$stateId@$caseId")
            continue
        }
        [void]$coverageRows.Add([pscustomobject][ordered]@{
            state_id = $stateId
            category = [string]$row.category
            matrix_case = $caseId
            width = [int]$case.width
            height = [int]$case.height
            ui_scale_percent = [int]$case.ui_scale_percent
            risk_flags = @($row.risk_flags)
            image_paths = @($script:coverageIndex[$coverageKey].ToArray())
        })
    }
}
if ($missingCoverage.Count -gt 0) {
    throw (
        "The census matrix has $($missingCoverage.Count) uncovered row/case cells. " +
        "First: $($missingCoverage[0])"
    )
}
$expectedCoverageCells = $censusRows.Count * $matrix.Count
if ($coverageRows.Count -ne $expectedCoverageCells) {
    throw "Coverage row count=$($coverageRows.Count), expected=$expectedCoverageCells."
}

$expectedImageCount = (
    (($census.summary.deploy_filters + $census.summary.deploy_summaries) * $matrix.Count) +
    ($census.summary.long_term_pages * $matrix.Count) +
    (8 * $matrix.Count) +
    (($baseRequests.Count + ($debugScenarios.Count * 4)) * $matrix.Count)
)
if ($script:images.Count -ne $expectedImageCount) {
    throw "Capture image count=$($script:images.Count), expected=$expectedImageCount."
}

$duplicatePixelHashes = @(
    $script:images |
        Group-Object sha256 |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object {
            [pscustomobject][ordered]@{
                sha256 = $_.Name
                image_count = $_.Count
                states = @(
                    $_.Group | ForEach-Object {
                        "$($_.matrix_case)/$($_.surface)/$($_.render_state)"
                    }
                )
            }
        }
)

$statusAfter = @(
    & git.exe -c core.quotepath=false -C $resolvedRoot status --porcelain=v1 --untracked-files=all
)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to read final Git status.'
}
$worktreeUnchanged = @(
    Compare-Object `
        -ReferenceObject $statusBefore `
        -DifferenceObject $statusAfter `
        -CaseSensitive
).Count -eq 0
if (-not $worktreeUnchanged) {
    throw 'Census-matrix capture changed the active worktree.'
}

$coveragePath = Join-Path $script:resolvedOutputRoot 'census_matrix_coverage.json'
$coverageReport = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = 'PASS'
    capture_status = 'CAPTURE_COMPLETE'
    visual_status = 'VISUAL_CANDIDATE'
    manual_original_review_required = $true
    census_path = Get-I4RelativeOutputPath -Path $censusPath
    census_sha256 = Get-I4Sha256 -Path $censusPath
    census_rows = $censusRows.Count
    matrix_cases = $matrix
    expected_row_case_cells = $expectedCoverageCells
    covered_row_case_cells = $coverageRows.Count
    missing_row_case_cells = @()
    rows = $coverageRows.ToArray()
}
Write-I4Text `
    -Path $coveragePath `
    -Text (($coverageReport | ConvertTo-Json -Depth 30) + "`r`n")

$manifestPath = Join-Path $script:resolvedOutputRoot 'capture_manifest.json'
$manifest = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = 'PASS'
    capture_status = 'CAPTURE_COMPLETE'
    visual_status = 'VISUAL_CANDIDATE'
    visual_pass_forbidden_without_manual_original_ledger = $true
    source_mode = $SourceMode
    head = $head
    head_tree = $headTree
    census_tree = [string]$census.tree
    census_sha256 = Get-I4Sha256 -Path $censusPath
    census_wrapper_sha256 = Get-I4Sha256 -Path $censusWrapperPath
    coverage_path = Get-I4RelativeOutputPath -Path $coveragePath
    coverage_sha256 = Get-I4Sha256 -Path $coveragePath
    godot_executable = $script:GodotExe
    godot_version = ((& $script:GodotExe --version) -join "`n").Trim()
    started_utc = $startedUtc.ToString('o')
    finished_utc = [DateTime]::UtcNow.ToString('o')
    worktree_unchanged = $worktreeUnchanged
    census_summary = $census.summary
    matrix = $matrix
    row_case_cells = $coverageRows.Count
    image_count = $script:images.Count
    duplicate_pixel_hashes = $duplicatePixelHashes
    processes = $processes.ToArray()
    images = $script:images.ToArray()
}
Write-I4Text `
    -Path $manifestPath `
    -Text (($manifest | ConvertTo-Json -Depth 30) + "`r`n")

Write-Output (
    (
        'I4_CENSUS_MATRIX_CAPTURE=PASS rows={0} matrix={1} cells={2} images={3} ' +
        'capture_status=CAPTURE_COMPLETE visual_status=VISUAL_CANDIDATE manifest={4} sha256={5}'
    ) -f
    $censusRows.Count,
    $matrix.Count,
    $coverageRows.Count,
    $script:images.Count,
    $manifestPath,
    (Get-I4Sha256 -Path $manifestPath)
)
