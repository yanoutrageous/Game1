Set-StrictMode -Version 2.0

$script:I0WorkspaceRoot = "D:\AGAME1"


function Get-I0CanonicalPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
}


function Test-I0PathWithin {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Root,

        [switch]$AllowRoot
    )

    $fullPath = Get-I0CanonicalPath -Path $Path
    $fullRoot = Get-I0CanonicalPath -Path $Root
    if ($AllowRoot -and [string]::Equals($fullPath, $fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $fullPath.StartsWith($fullRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)
}


function Assert-I0PathWithin {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Root,

        [switch]$AllowRoot,

        [string]$Label = "path"
    )

    if (-not (Test-I0PathWithin -Path $Path -Root $Root -AllowRoot:$AllowRoot)) {
        throw "$Label escapes the allowed root. path=$Path root=$Root"
    }
}


function Assert-I0NoReparseExistingAncestor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$Root = $script:I0WorkspaceRoot,

        [string]$Label = "path"
    )

    $fullPath = Get-I0CanonicalPath -Path $Path
    $fullRoot = Get-I0CanonicalPath -Path $Root
    Assert-I0PathWithin -Path $fullPath -Root $fullRoot -AllowRoot -Label $Label
    $cursor = $fullPath
    while (-not (Test-Path -LiteralPath $cursor)) {
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or [string]::Equals($parent, $cursor, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "$Label has no existing ancestor inside root: $fullPath"
        }
        $cursor = Get-I0CanonicalPath -Path $parent
    }
    while ($true) {
        $item = Get-Item -LiteralPath $cursor -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "$Label crosses a reparse point, refusing access: $cursor"
        }
        if ([string]::Equals($cursor, $fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parent = Get-I0CanonicalPath -Path (Split-Path -Parent $cursor)
        if (-not (Test-I0PathWithin -Path $parent -Root $fullRoot -AllowRoot)) {
            throw "$Label existing ancestor escaped root during validation: $parent"
        }
        $cursor = $parent
    }
}


function Get-I0RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Root
    )

    $fullPath = Get-I0CanonicalPath -Path $Path
    $fullRoot = Get-I0CanonicalPath -Path $Root
    Assert-I0PathWithin -Path $fullPath -Root $fullRoot -AllowRoot -Label "relative path input"
    if ([string]::Equals($fullPath, $fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return ""
    }
    return $fullPath.Substring($fullRoot.Length + 1).Replace('\', '/')
}


function ConvertTo-I0CommandLineArgument {
    param(
        [AllowEmptyString()]
        [string]$Value
    )

    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') {
        return $Value
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append('"')
    $backslashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq [char]92) {
            $backslashes += 1
            continue
        }
        if ($character -eq [char]34) {
            if ($backslashes -gt 0) {
                [void]$builder.Append(('\' * ($backslashes * 2)))
            }
            [void]$builder.Append('\"')
            $backslashes = 0
            continue
        }
        if ($backslashes -gt 0) {
            [void]$builder.Append(('\' * $backslashes))
            $backslashes = 0
        }
        [void]$builder.Append($character)
    }
    if ($backslashes -gt 0) {
        [void]$builder.Append(('\' * ($backslashes * 2)))
    }
    [void]$builder.Append('"')
    return $builder.ToString()
}


function Invoke-I0Process {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string[]]$Arguments = @(),

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory,

        [hashtable]$Environment = @{},

        [ValidateRange(1, 3600)]
        [int]$TimeoutSeconds = 60
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "Executable not found: $FilePath"
    }
    if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
        throw "Working directory not found: $WorkingDirectory"
    }

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $FilePath
    $startInfo.WorkingDirectory = $WorkingDirectory
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.Arguments = (($Arguments | ForEach-Object { ConvertTo-I0CommandLineArgument -Value ([string]$_) }) -join ' ')
    foreach ($key in $Environment.Keys) {
        $startInfo.EnvironmentVariables[[string]$key] = [string]$Environment[$key]
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    if (-not $process.Start()) {
        throw "Failed to start process: $FilePath"
    }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
    if ($timedOut) {
        $taskkill = Join-Path $env:SystemRoot "System32\taskkill.exe"
        if (Test-Path -LiteralPath $taskkill -PathType Leaf) {
            $killInfo = New-Object System.Diagnostics.ProcessStartInfo
            $killInfo.FileName = $taskkill
            $killInfo.Arguments = "/PID $($process.Id) /T /F"
            $killInfo.UseShellExecute = $false
            $killInfo.CreateNoWindow = $true
            [void][System.Diagnostics.Process]::Start($killInfo).WaitForExit(10000)
        }
        if (-not $process.HasExited) {
            try { $process.Kill() } catch { }
        }
    }
    if (-not $process.HasExited) {
        [void]$process.WaitForExit(10000)
    }
    $stopwatch.Stop()

    $stdout = ""
    $stderr = ""
    $streamTasksCompleted = $false
    try {
        $streamTasksCompleted = [System.Threading.Tasks.Task]::WaitAll([System.Threading.Tasks.Task[]]@($stdoutTask, $stderrTask), 10000)
    }
    catch {
        $streamTasksCompleted = $false
    }
    if ($streamTasksCompleted -and $stdoutTask.IsCompleted -and -not $stdoutTask.IsFaulted -and -not $stdoutTask.IsCanceled) {
        $stdout = [string]$stdoutTask.Result
    }
    else {
        $stdout = "[I0 stdout unavailable: bounded stream wait did not complete successfully]"
    }
    if ($streamTasksCompleted -and $stderrTask.IsCompleted -and -not $stderrTask.IsFaulted -and -not $stderrTask.IsCanceled) {
        $stderr = [string]$stderrTask.Result
    }
    else {
        $stderr = "[I0 stderr unavailable: bounded stream wait did not complete successfully]"
    }
    $exitCode = if ($timedOut -or -not $process.HasExited) { -1 } else { $process.ExitCode }
    $process.Dispose()

    return [pscustomobject][ordered]@{
        file_path = $FilePath
        arguments = @($Arguments)
        command_line = "$FilePath $($startInfo.Arguments)"
        working_directory = $WorkingDirectory
        exit_code = $exitCode
        timed_out = $timedOut
        duration_ms = [int64]$stopwatch.ElapsedMilliseconds
        stdout = $stdout
        stderr = $stderr
    }
}


function Get-I0GitExecutable {
    $command = Get-Command git.exe -ErrorAction Stop
    return $command.Source
}


function Invoke-I0Git {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [int]$TimeoutSeconds = 30,

        [switch]$AllowFailure
    )

    $result = Invoke-I0Process -FilePath (Get-I0GitExecutable) -Arguments (@('-C', $RepoRoot) + $Arguments) -WorkingDirectory $RepoRoot -Environment @{ GIT_OPTIONAL_LOCKS = '0'; GIT_TERMINAL_PROMPT = '0' } -TimeoutSeconds $TimeoutSeconds
    if (-not $AllowFailure -and ($result.timed_out -or $result.exit_code -ne 0)) {
        throw "git command failed: $($result.command_line)`n$($result.stderr)"
    }
    return $result
}


function Normalize-I0ProcessText {
    param([AllowEmptyString()][string]$Text)
    return $Text.Replace("`r`n", "`n").TrimEnd("`r", "`n")
}


function Get-I0GitSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [int]$TimeoutSeconds = 30
    )

    $head = Invoke-I0Git -RepoRoot $RepoRoot -Arguments @('rev-parse', '--verify', 'HEAD') -TimeoutSeconds $TimeoutSeconds
    $branch = Invoke-I0Git -RepoRoot $RepoRoot -Arguments @('symbolic-ref', '--quiet', 'HEAD') -TimeoutSeconds $TimeoutSeconds -AllowFailure
    $status = Invoke-I0Git -RepoRoot $RepoRoot -Arguments @('-c', 'core.quotepath=false', 'status', '--porcelain=v2', '--branch', '--untracked-files=all') -TimeoutSeconds $TimeoutSeconds
    $stashRef = Invoke-I0Git -RepoRoot $RepoRoot -Arguments @('rev-parse', '--verify', 'refs/stash') -TimeoutSeconds $TimeoutSeconds -AllowFailure
    $stashList = Invoke-I0Git -RepoRoot $RepoRoot -Arguments @('stash', 'list', '--format=%H|%gd|%gs') -TimeoutSeconds $TimeoutSeconds
    $indexPathResult = Invoke-I0Git -RepoRoot $RepoRoot -Arguments @('rev-parse', '--git-path', 'index') -TimeoutSeconds $TimeoutSeconds
    $indexPathText = Normalize-I0ProcessText -Text $indexPathResult.stdout
    $indexPath = if ([System.IO.Path]::IsPathRooted($indexPathText)) { Get-I0CanonicalPath -Path $indexPathText } else { Get-I0CanonicalPath -Path (Join-Path $RepoRoot $indexPathText) }
    Assert-I0PathWithin -Path $indexPath -Root $script:I0WorkspaceRoot -Label "Git index"
    Assert-I0NoReparseExistingAncestor -Path $indexPath -Root $script:I0WorkspaceRoot -Label "Git index"
    $indexSha256 = if (Test-Path -LiteralPath $indexPath -PathType Leaf) { (Get-FileHash -LiteralPath $indexPath -Algorithm SHA256).Hash.ToUpperInvariant() } else { '(missing)' }
    $showRef = Invoke-I0Git -RepoRoot $RepoRoot -Arguments @('show-ref', '--head', '--dereference') -TimeoutSeconds $TimeoutSeconds
    $showRefText = Normalize-I0ProcessText -Text $showRef.stdout

    return [pscustomobject][ordered]@{
        head = (Normalize-I0ProcessText -Text $head.stdout)
        branch = if ($branch.exit_code -eq 0) { Normalize-I0ProcessText -Text $branch.stdout } else { '(detached)' }
        status_porcelain_v2 = Normalize-I0ProcessText -Text $status.stdout
        stash_ref = if ($stashRef.exit_code -eq 0) { Normalize-I0ProcessText -Text $stashRef.stdout } else { '(missing)' }
        stash_list = Normalize-I0ProcessText -Text $stashList.stdout
        index_sha256 = $indexSha256
        show_ref_sha256 = Get-I0Sha256Text -Text $showRefText
    }
}


function Compare-I0GitSnapshot {
    param(
        [Parameter(Mandatory = $true)]$Before,
        [Parameter(Mandatory = $true)]$After
    )

    $differences = New-Object System.Collections.Generic.List[string]
    foreach ($property in @('head', 'branch', 'status_porcelain_v2', 'stash_ref', 'stash_list', 'index_sha256', 'show_ref_sha256')) {
        if ([string]$Before.$property -cne [string]$After.$property) {
            [void]$differences.Add($property)
        }
    }
    return [pscustomobject][ordered]@{
        unchanged = ($differences.Count -eq 0)
        changed_fields = $differences.ToArray()
    }
}


function Get-I0Sha256Text {
    param([Parameter(Mandatory = $true)][string]$Text)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($Text)
        return ([System.BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToUpperInvariant()
    }
    finally {
        $algorithm.Dispose()
    }
}


function Assert-I0TreeHasNoReparseEntries {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [string]$Label = 'tree'
    )
    $treeRoot = Get-I0CanonicalPath -Path $Root
    Assert-I0NoReparseExistingAncestor -Path $treeRoot -Root $script:I0WorkspaceRoot -Label $Label
    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push($treeRoot)
    while ($pending.Count -gt 0) {
        $directory = $pending.Pop()
        foreach ($entry in @(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop)) {
            if (($entry.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Label contains a reparse entry; refusing recursive access: $($entry.FullName)"
            }
            if ($entry.PSIsContainer) {
                $pending.Push($entry.FullName)
            }
        }
    }
}


function Get-I0BusinessHashSnapshot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [object[]]$BusinessRoots,

        [object[]]$ExcludedDirectoryNames = @('.git', '.godot', '__pycache__')
    )

    $repo = Get-I0CanonicalPath -Path $RepoRoot
    Assert-I0NoReparseExistingAncestor -Path $repo -Root $script:I0WorkspaceRoot -Label "business snapshot repo"
    $excludedNames = @($ExcludedDirectoryNames | ForEach-Object {
        $name = [string]$_
        if ($name -notmatch '^[A-Za-z0-9_.-]+$' -or $name -in @('.', '..')) {
            throw "Unsafe excluded directory name for business hashing: $name"
        }
        $name.ToLowerInvariant()
    })
    $entries = @{}
    foreach ($relativeRootValue in $BusinessRoots) {
        $relativeRoot = ([string]$relativeRootValue).Replace('/', '\')
        $businessRoot = Get-I0CanonicalPath -Path (Join-Path $repo $relativeRoot)
        Assert-I0PathWithin -Path $businessRoot -Root $repo -Label "business root"
        if (-not (Test-Path -LiteralPath $businessRoot -PathType Container)) {
            throw "Business root not found: $businessRoot"
        }
        Assert-I0TreeHasNoReparseEntries -Root $businessRoot -Label "business root"
        $files = @(Get-ChildItem -LiteralPath $businessRoot -File -Force -Recurse | Where-Object {
            $relativeToBusinessRoot = Get-I0RelativePath -Path $_.FullName -Root $businessRoot
            $directorySegments = @($relativeToBusinessRoot.Split('/') | Select-Object -SkipLast 1 | ForEach-Object { $_.ToLowerInvariant() })
            @($directorySegments | Where-Object { $excludedNames -contains $_ }).Count -eq 0
        } | Sort-Object FullName)
        foreach ($file in $files) {
            if (($file.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Reparse-point business file is not allowed in I0 hashing: $($file.FullName)"
            }
            $relativePath = Get-I0RelativePath -Path $file.FullName -Root $repo
            if ($entries.ContainsKey($relativePath)) {
                throw "Duplicate business file in hash roots: $relativePath"
            }
            $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
            $entries[$relativePath] = "$($file.Length)|$hash"
        }
    }

    $fingerprintBuilder = New-Object System.Text.StringBuilder
    foreach ($relativePath in @($entries.Keys | Sort-Object)) {
        [void]$fingerprintBuilder.Append($relativePath)
        [void]$fingerprintBuilder.Append('|')
        [void]$fingerprintBuilder.Append($entries[$relativePath])
        [void]$fingerprintBuilder.Append("`n")
    }
    return [pscustomobject][ordered]@{
        file_count = $entries.Count
        fingerprint_sha256 = Get-I0Sha256Text -Text $fingerprintBuilder.ToString()
        entries = $entries
    }
}


function Compare-I0BusinessHashSnapshot {
    param(
        [Parameter(Mandatory = $true)]$Before,
        [Parameter(Mandatory = $true)]$After
    )

    $differences = New-Object System.Collections.Generic.List[object]
    $allPaths = @((@($Before.entries.Keys) + @($After.entries.Keys)) | Sort-Object -Unique)
    foreach ($relativePath in $allPaths) {
        $beforeValue = if ($Before.entries.ContainsKey($relativePath)) { [string]$Before.entries[$relativePath] } else { '(missing)' }
        $afterValue = if ($After.entries.ContainsKey($relativePath)) { [string]$After.entries[$relativePath] } else { '(missing)' }
        if ($beforeValue -cne $afterValue) {
            [void]$differences.Add([pscustomobject][ordered]@{
                relative_path = $relativePath
                before = $beforeValue
                after = $afterValue
            })
        }
    }
    return [pscustomobject][ordered]@{
        unchanged = ($differences.Count -eq 0)
        before_file_count = $Before.file_count
        after_file_count = $After.file_count
        before_fingerprint_sha256 = $Before.fingerprint_sha256
        after_fingerprint_sha256 = $After.fingerprint_sha256
        differences = @($differences.ToArray() | Select-Object -First 100)
        difference_count = $differences.Count
    }
}


function Copy-I0WorktreeMirror {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRepo,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$RuntimeTempRoot,

        [object[]]$ExcludedDirectoryNames = @('.git', '.godot', '__pycache__'),

        [int]$TimeoutSeconds = 600
    )

    $source = Get-I0CanonicalPath -Path $SourceRepo
    $destinationPath = Get-I0CanonicalPath -Path $Destination
    $tempRoot = Get-I0CanonicalPath -Path $RuntimeTempRoot
    Assert-I0PathWithin -Path $source -Root $script:I0WorkspaceRoot -Label "mirror source"
    Assert-I0NoReparseExistingAncestor -Path $source -Root $script:I0WorkspaceRoot -Label "mirror source"
    Assert-I0PathWithin -Path $destinationPath -Root $tempRoot -Label "mirror destination"
    Assert-I0NoReparseExistingAncestor -Path $destinationPath -Root $script:I0WorkspaceRoot -Label "mirror destination"
    if (Test-Path -LiteralPath $destinationPath) {
        throw "Refusing to copy into an existing mirror destination: $destinationPath"
    }
    Assert-I0TreeHasNoReparseEntries -Root $source -Label "mirror source"
    [void](New-Item -ItemType Directory -Path $destinationPath -Force)

    $arguments = @($source, $destinationPath, '/E', '/COPY:DAT', '/DCOPY:DAT', '/R:1', '/W:1', '/XJ', '/NFL', '/NDL', '/NJH', '/NJS', '/NP')
    $excludedPaths = New-Object System.Collections.Generic.List[string]
    foreach ($nameValue in $ExcludedDirectoryNames) {
        $name = [string]$nameValue
        if ($name -notmatch '^[A-Za-z0-9_.-]+$' -or $name -in @('.', '..')) {
            throw "Unsafe excluded directory name in validation manifest: $name"
        }
        foreach ($directory in @(Get-ChildItem -LiteralPath $source -Directory -Force -Recurse -ErrorAction Stop | Where-Object { $_.Name -ceq $name })) {
            [void]$excludedPaths.Add($directory.FullName)
        }
        $topLevel = Join-Path $source $name
        if (Test-Path -LiteralPath $topLevel -PathType Container) {
            [void]$excludedPaths.Add($topLevel)
        }
    }
    if ($excludedPaths.Count -gt 0) {
        $arguments += '/XD'
        $arguments += @($excludedPaths | Sort-Object -Unique)
    }

    $robocopy = Join-Path $env:SystemRoot 'System32\robocopy.exe'
    $result = Invoke-I0Process -FilePath $robocopy -Arguments $arguments -WorkingDirectory $source -TimeoutSeconds $TimeoutSeconds
    if ($result.timed_out -or $result.exit_code -lt 0 -or $result.exit_code -gt 7) {
        throw "robocopy failed with exit code $($result.exit_code): $($result.stderr) $($result.stdout)"
    }
    return $result
}


function Copy-I0HeadMirror {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRepo,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [string]$RuntimeTempRoot,

        [int]$TimeoutSeconds = 600
    )

    $source = Get-I0CanonicalPath -Path $SourceRepo
    $destinationPath = Get-I0CanonicalPath -Path $Destination
    $tempRoot = Get-I0CanonicalPath -Path $RuntimeTempRoot
    Assert-I0PathWithin -Path $source -Root $script:I0WorkspaceRoot -Label "HEAD mirror source"
    Assert-I0NoReparseExistingAncestor -Path $source -Root $script:I0WorkspaceRoot -Label "HEAD mirror source"
    Assert-I0PathWithin -Path $destinationPath -Root $tempRoot -Label "HEAD mirror destination"
    Assert-I0NoReparseExistingAncestor -Path $destinationPath -Root $script:I0WorkspaceRoot -Label "HEAD mirror destination"
    if (Test-Path -LiteralPath $destinationPath) {
        throw "Refusing to export HEAD into an existing mirror destination: $destinationPath"
    }

    $runRoot = Get-I0CanonicalPath -Path (Split-Path -Parent $destinationPath)
    Assert-I0PathWithin -Path $runRoot -Root $tempRoot -Label "HEAD mirror run root"
    $headIndexPath = Get-I0CanonicalPath -Path (Join-Path $runRoot 'head-export.index')
    Assert-I0PathWithin -Path $headIndexPath -Root $runRoot -Label "HEAD export index"
    Assert-I0NoReparseExistingAncestor -Path $headIndexPath -Root $script:I0WorkspaceRoot -Label "HEAD export index"
    if (Test-Path -LiteralPath $headIndexPath) {
        throw "Refusing to overwrite an existing HEAD export index: $headIndexPath"
    }

    [void](New-Item -ItemType Directory -Path $destinationPath)
    $environment = @{
        GIT_INDEX_FILE = $headIndexPath
        GIT_OPTIONAL_LOCKS = '0'
        GIT_TERMINAL_PROMPT = '0'
    }
    $git = Get-I0GitExecutable
    $readTree = Invoke-I0Process `
        -FilePath $git `
        -Arguments @('-C', $source, 'read-tree', 'HEAD') `
        -WorkingDirectory $source `
        -Environment $environment `
        -TimeoutSeconds $TimeoutSeconds
    if ($readTree.timed_out -or $readTree.exit_code -ne 0) {
        throw "Unable to create isolated HEAD index: $($readTree.stderr) $($readTree.stdout)"
    }

    $prefix = $destinationPath.TrimEnd('\') + '\'
    $checkoutIndex = Invoke-I0Process `
        -FilePath $git `
        -Arguments @('-C', $source, 'checkout-index', '--all', "--prefix=$prefix") `
        -WorkingDirectory $source `
        -Environment $environment `
        -TimeoutSeconds $TimeoutSeconds
    if ($checkoutIndex.timed_out -or $checkoutIndex.exit_code -ne 0) {
        throw "Unable to export isolated HEAD mirror: $($checkoutIndex.stderr) $($checkoutIndex.stdout)"
    }
    Assert-I0TreeHasNoReparseEntries -Root $destinationPath -Label "HEAD mirror"

    $head = Invoke-I0Git -RepoRoot $source -Arguments @('rev-parse', '--verify', 'HEAD') -TimeoutSeconds $TimeoutSeconds
    $tree = Invoke-I0Git -RepoRoot $source -Arguments @('rev-parse', '--verify', 'HEAD^{tree}') -TimeoutSeconds $TimeoutSeconds
    return [pscustomobject][ordered]@{
        read_tree_process = $readTree
        checkout_process = $checkoutIndex
        head = Normalize-I0ProcessText -Text $head.stdout
        tree = Normalize-I0ProcessText -Text $tree.stdout
        isolated_index_path = $headIndexPath
    }
}


function New-I0GodotRuntimeLinks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallRoot,

        [Parameter(Mandatory = $true)]
        [string]$MainExecutableName,

        [Parameter(Mandatory = $true)]
        [string]$ConsoleExecutableName,

        [Parameter(Mandatory = $true)]
        [string]$RunRoot
    )

    foreach ($name in @($MainExecutableName, $ConsoleExecutableName)) {
        if ([System.IO.Path]::IsPathRooted($name) -or $name -ne [System.IO.Path]::GetFileName($name) -or $name -match '[:\\/]') {
            throw "Unsafe Godot executable basename: $name"
        }
    }
    $install = Get-I0CanonicalPath -Path $InstallRoot
    Assert-I0PathWithin -Path $install -Root $script:I0WorkspaceRoot -Label "Godot install root"
    Assert-I0NoReparseExistingAncestor -Path $install -Root $script:I0WorkspaceRoot -Label "Godot install root"
    $run = Get-I0CanonicalPath -Path $RunRoot
    Assert-I0PathWithin -Path $run -Root $script:I0WorkspaceRoot -Label "I0 run root"
    Assert-I0NoReparseExistingAncestor -Path $run -Root $script:I0WorkspaceRoot -Label "I0 run root"
    $engineRoot = Join-Path $run 'engine_without_self_contained_marker'
    Assert-I0NoReparseExistingAncestor -Path $engineRoot -Root $script:I0WorkspaceRoot -Label "engine hardlink root"
    if (Test-Path -LiteralPath $engineRoot) {
        throw "Engine link directory already exists: $engineRoot"
    }
    [void](New-Item -ItemType Directory -Path $engineRoot)

    $links = [ordered]@{}
    foreach ($name in @($MainExecutableName, $ConsoleExecutableName)) {
        $source = Join-Path $install $name
        $target = Join-Path $engineRoot $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Godot executable missing: $source"
        }
        [void](New-Item -ItemType HardLink -Path $target -Target $source)
        $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToUpperInvariant()
        $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToUpperInvariant()
        if ($sourceHash -cne $targetHash) {
            throw "Godot hardlink hash mismatch: $name"
        }
        $links[$name] = [pscustomobject][ordered]@{
            source = $source
            hardlink = $target
            bytes = (Get-Item -LiteralPath $target).Length
            sha256 = $targetHash
        }
    }
    if (Test-Path -LiteralPath (Join-Path $engineRoot '_sc_')) {
        throw "I0 runtime link directory must not contain _sc_"
    }
    return [pscustomobject][ordered]@{
        engine_root = $engineRoot
        main_executable = $links[$MainExecutableName]
        console_executable = $links[$ConsoleExecutableName]
        self_contained_marker_present = $false
    }
}


function New-I0ProcessEnvironment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RunRoot,

        [Parameter(Mandatory = $true)]
        [string]$CaseId
    )

    if ($CaseId -notmatch '^[A-Za-z0-9_.-]+$') {
        throw "Unsafe process environment case id: $CaseId"
    }
    $caseRoot = Get-I0CanonicalPath -Path (Join-Path $RunRoot ("process_env\" + $CaseId))
    Assert-I0PathWithin -Path $caseRoot -Root $RunRoot -Label "process environment root"
    Assert-I0NoReparseExistingAncestor -Path $caseRoot -Root $script:I0WorkspaceRoot -Label "process environment root"
    $userHome = Join-Path $caseRoot 'user_home'
    $appData = Join-Path $caseRoot 'appdata\Roaming'
    $localAppData = Join-Path $caseRoot 'appdata\Local'
    $temp = Join-Path $caseRoot 'temp'
    $godotUserHome = Join-Path $caseRoot 'godot_user_home'
    $xdgData = Join-Path $caseRoot 'xdg\data'
    $xdgConfig = Join-Path $caseRoot 'xdg\config'
    $xdgCache = Join-Path $caseRoot 'xdg\cache'
    foreach ($directory in @($userHome, $appData, $localAppData, $temp, $godotUserHome, $xdgData, $xdgConfig, $xdgCache)) {
        Assert-I0PathWithin -Path $directory -Root $RunRoot -Label "process environment directory"
        [void](New-Item -ItemType Directory -Path $directory -Force)
    }
    return @{
        USERPROFILE = $userHome
        HOME = $userHome
        APPDATA = $appData
        LOCALAPPDATA = $localAppData
        TEMP = $temp
        TMP = $temp
        GODOT_USER_HOME = $godotUserHome
        XDG_DATA_HOME = $xdgData
        XDG_CONFIG_HOME = $xdgConfig
        XDG_CACHE_HOME = $xdgCache
        GODOT_SILENCE_ROOT_WARNING = '1'
    }
}


function Write-I0Json {
    param(
        [Parameter(Mandatory = $true)]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = Get-I0CanonicalPath -Path $Path
    Assert-I0PathWithin -Path $fullPath -Root $script:I0WorkspaceRoot -Label "JSON report path"
    Assert-I0NoReparseExistingAncestor -Path $fullPath -Root $script:I0WorkspaceRoot -Label "JSON report path"
    $parent = Split-Path -Parent $fullPath
    [void](New-Item -ItemType Directory -Path $parent -Force)
    $json = $Value | ConvertTo-Json -Depth 30
    [System.IO.File]::WriteAllText($fullPath, $json + "`r`n", (New-Object System.Text.UTF8Encoding($false)))
}


function Get-I0PublicBusinessSnapshot {
    param([Parameter(Mandatory = $true)]$Snapshot)
    return [pscustomobject][ordered]@{
        file_count = $Snapshot.file_count
        fingerprint_sha256 = $Snapshot.fingerprint_sha256
    }
}
