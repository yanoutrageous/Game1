[CmdletBinding()]
param(
    [ValidateSet('worktree', 'head')]
    [string]$SourceMode = 'worktree',

    [ValidateSet('deploy', 'long_term', 'production', 'all')]
    [string]$Profile = 'all',

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

function Invoke-I4GodotCapture {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Runner,
        [Parameter(Mandatory = $true)][string[]]$UserArguments,
        [Parameter(Mandatory = $true)][string]$PassRegex,
        [Parameter(Mandatory = $true)][string]$LogRoot,
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )
    $stdoutPath = Join-Path $LogRoot "$Id.stdout.log"
    $stderrPath = Join-Path $LogRoot "$Id.stderr.log"
    $engineLogPath = Join-Path $LogRoot "$Id.engine.log"
    $arguments = @(
        '--path', $ProjectRoot,
        '--log-file', $engineLogPath,
        '--script', $Runner,
        '--'
    ) + $UserArguments
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Executable
    $startInfo.Arguments = (@(
        $arguments | ForEach-Object {
            ConvertTo-I4ProcessArgument -Value ([string]$_)
        }
    ) -join ' ')
    $startInfo.WorkingDirectory = $ProjectRoot
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
    try {
        if (-not $process.Start()) {
            throw "Could not start real-render capture process: $Id"
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(180000)) {
            try {
                $process.Kill()
                $process.WaitForExit()
            }
            catch {
            }
            throw "Real-render capture timed out: $Id"
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
    $combined = $stdout + "`n" + $stderr
    if ($exitCode -ne 0 -or -not [regex]::IsMatch($combined, $PassRegex)) {
        throw "Real-render capture failed or omitted its marker: $Id"
    }
    $diagnosticLines = @(
        [regex]::Matches(
            $combined,
            '(?im)^\s*(?:SCRIPT ERROR:|ERROR:|FATAL:|CRASH:|WARNING:)\s*.*$'
        ) | ForEach-Object { $_.Value.Trim() }
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
        started_utc = $started.ToString('o')
        finished_utc = [DateTime]::UtcNow.ToString('o')
        stdout_path = $stdoutPath
        stdout_sha256 = Get-I4Sha256 -Path $stdoutPath
        stderr_path = $stderrPath
        stderr_sha256 = Get-I4Sha256 -Path $stderrPath
        engine_log_path = $engineLogPath
        cleanup_diagnostics = $cleanupDiagnostics
        blocking_diagnostics = $blockingDiagnostics
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
    $GodotExe = 'E:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe'
}
if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw "Godot executable is missing: $GodotExe"
}
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $OutputRoot = Join-Path $resolvedRoot ".tmp\i4\real_render\$runId"
}
$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
$tmpRoot = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot '.tmp')).TrimEnd('\')
if (
    -not $resolvedOutputRoot.StartsWith(
        $tmpRoot + '\',
        [System.StringComparison]::OrdinalIgnoreCase
    )
) {
    throw "OutputRoot must stay below the repository .tmp directory: $resolvedOutputRoot"
}
[void](New-Item -ItemType Directory -Path $resolvedOutputRoot -Force)
$logRoot = Join-Path $resolvedOutputRoot 'logs'
[void](New-Item -ItemType Directory -Path $logRoot -Force)

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
$projectRoot = Join-Path $resolvedRoot 'Godot\GraytailGodot'
$startedUtc = [DateTime]::UtcNow
$processes = New-Object System.Collections.Generic.List[object]
$expectedFiles = New-Object System.Collections.Generic.List[object]
$savedCommit = [Environment]::GetEnvironmentVariable('I4_EVIDENCE_COMMIT', 'Process')
[Environment]::SetEnvironmentVariable('I4_EVIDENCE_COMMIT', $head, 'Process')

try {
    if ($Profile -in @('deploy', 'all')) {
        $deployRoot = Join-Path $resolvedOutputRoot 'deploy'
        [void](New-Item -ItemType Directory -Path $deployRoot -Force)
        [void]$processes.Add((
            Invoke-I4GodotCapture `
                -Id 'deploy_matrix' `
                -Runner 'res://tests/i4_deploy_information_layout_runner.gd' `
                -UserArguments @("--output=$($deployRoot.Replace('\', '/'))") `
                -PassRegex '(?m)^I4_DEPLOY_INFORMATION_LAYOUT=PASS .*screenshots=12\r?$' `
                -LogRoot $logRoot `
                -Executable $GodotExe `
                -ProjectRoot $projectRoot
        ))
        foreach ($file in @(Get-ChildItem -LiteralPath $deployRoot -Filter '*.png' -File)) {
            [void]$expectedFiles.Add([pscustomobject]@{
                surface = 'deploy'
                state = $file.BaseName
                path = $file.FullName
            })
        }
        if (@($expectedFiles | Where-Object { $_.surface -ceq 'deploy' }).Count -ne 12) {
            throw 'Deploy matrix did not produce exactly 12 PNG files.'
        }
    }

    if ($Profile -in @('long_term', 'all')) {
        $longTermRoot = Join-Path $resolvedOutputRoot 'long_term'
        [void](New-Item -ItemType Directory -Path $longTermRoot -Force)
        [void]$processes.Add((
            Invoke-I4GodotCapture `
                -Id 'long_term_matrix' `
                -Runner 'res://tests/art23_long_term_matrix_capture_runner.gd' `
                -UserArguments @(
                    "--output-dir=$($longTermRoot.Replace('\', '/'))",
                    '--width=1280',
                    '--height=720'
                ) `
                -PassRegex '(?m)^ART23_MATRIX_CAPTURE=PASS states=25 size=1280x720 ' `
                -LogRoot $logRoot `
                -Executable $GodotExe `
                -ProjectRoot $projectRoot
        ))
        foreach ($file in @(Get-ChildItem -LiteralPath $longTermRoot -Filter '*.png' -File)) {
            [void]$expectedFiles.Add([pscustomobject]@{
                surface = 'long_term'
                state = $file.BaseName
                path = $file.FullName
            })
        }
        if (@($expectedFiles | Where-Object { $_.surface -ceq 'long_term' }).Count -ne 25) {
            throw 'Long-term matrix did not produce exactly 25 PNG files.'
        }
    }

    if ($Profile -in @('production', 'all')) {
        $productionRoot = Join-Path $resolvedOutputRoot 'production'
        [void](New-Item -ItemType Directory -Path $productionRoot -Force)
        $states = @(
            'debug_settings',
            'debug_sandbox',
            'debug_panel',
            'run',
            'map',
            'inventory_items',
            'chest_open',
            'event_options',
            'monster',
            'mine',
            'exit',
            'ground_loot_visual',
            'result_success',
            'result_save_failed'
        )
        foreach ($state in $states) {
            $outputPath = Join-Path $productionRoot "$state.png"
            [void]$processes.Add((
                Invoke-I4GodotCapture `
                    -Id "production_$state" `
                    -Runner 'res://tests/art25_production_visual_capture_runner.gd' `
                    -UserArguments @(
                        "--state=$state",
                        "--output=$($outputPath.Replace('\', '/'))"
                    ) `
                    -PassRegex ("(?m)^ART25_PRODUCTION_CAPTURE=PASS state={0} size=1280x720 " -f [regex]::Escape($state)) `
                    -LogRoot $logRoot `
                    -Executable $GodotExe `
                    -ProjectRoot $projectRoot
            ))
            [void]$expectedFiles.Add([pscustomobject]@{
                surface = 'production'
                state = $state
                path = $outputPath
            })
        }
    }
}
finally {
    [Environment]::SetEnvironmentVariable('I4_EVIDENCE_COMMIT', $savedCommit, 'Process')
}

$images = New-Object System.Collections.Generic.List[object]
foreach ($entry in $expectedFiles) {
    if (-not (Test-Path -LiteralPath $entry.path -PathType Leaf)) {
        throw "Expected capture is missing: $($entry.path)"
    }
    $size = Get-I4PngSize -Path $entry.path
    [void]$images.Add([pscustomobject][ordered]@{
        surface = $entry.surface
        state = $entry.state
        width = $size.width
        height = $size.height
        bytes = (Get-Item -LiteralPath $entry.path).Length
        sha256 = Get-I4Sha256 -Path $entry.path
        path = $entry.path
    })
}
$duplicatePixelHashes = @(
    $images |
        Group-Object sha256 |
        Where-Object { $_.Count -gt 1 } |
        ForEach-Object {
            [pscustomobject]@{
                sha256 = $_.Name
                states = @($_.Group | ForEach-Object { "$($_.surface)/$($_.state)" })
            }
        }
)
if ($duplicatePixelHashes.Count -gt 0) {
    throw 'Semantically distinct requested capture states produced identical PNG hashes.'
}

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
    throw 'Real-render capture changed the active worktree.'
}

$manifestPath = Join-Path $resolvedOutputRoot 'capture_manifest.json'
$manifest = [pscustomobject][ordered]@{
    schema_version = 1
    standard_id = 'I4-QA-FROZEN-1'
    status = 'PASS'
    visual_status = 'VISUAL_CANDIDATE'
    visual_pass_forbidden_without_manual_ledger = $true
    source_mode = $SourceMode
    profile = $Profile
    head = $head
    head_tree = $headTree
    godot_executable = (Resolve-Path -LiteralPath $GodotExe).Path
    godot_version = ((& $GodotExe --version) -join "`n").Trim()
    started_utc = $startedUtc.ToString('o')
    finished_utc = [DateTime]::UtcNow.ToString('o')
    worktree_unchanged = $worktreeUnchanged
    image_count = $images.Count
    duplicate_pixel_hashes = $duplicatePixelHashes
    processes = $processes.ToArray()
    images = $images.ToArray()
}
Write-I4Text -Path $manifestPath -Text (($manifest | ConvertTo-Json -Depth 30) + "`r`n")

Write-Output (
    'I4_REAL_RENDER_CAPTURE=PASS profile={0} images={1} visual_status=VISUAL_CANDIDATE manifest={2} sha256={3}' -f
    $Profile,
    $images.Count,
    $manifestPath,
    (Get-I4Sha256 -Path $manifestPath)
)
