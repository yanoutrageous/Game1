param(
    [string]$RepoRoot = ([System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))),

    [ValidateSet("worktree", "head")]
    [string]$SourceMode = "worktree",

    [string]$GitRepoRoot = "",

    [string]$ExpectedHead = "",

    [string]$WorkspaceRoot = "",

    [string]$RuntimeTempRoot = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0
$nativeUtf8 = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $nativeUtf8
$OutputEncoding = $nativeUtf8

$repo = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\')
$gitRepo = if ([string]::IsNullOrWhiteSpace($GitRepoRoot)) {
    $repo
}
else {
    [System.IO.Path]::GetFullPath($GitRepoRoot).TrimEnd('\')
}

$workspace = if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\')
}
else {
    $gitCommonProbe = @(& git.exe -C $gitRepo rev-parse --path-format=absolute --git-common-dir 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to resolve Git common directory for document encoding gate: $($gitCommonProbe -join "`n")"
    }
    $gitCommonProbeText = [string]($gitCommonProbe | Select-Object -Last 1)
    if ([string]::IsNullOrWhiteSpace($gitCommonProbeText)) {
        throw "Git common directory probe returned no path"
    }
    $gitCommonProbePath = [System.IO.Path]::GetFullPath($gitCommonProbeText.Trim()).TrimEnd('\')
    $candidate = $repo
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        $candidatePrefix = $candidate.TrimEnd('\') + '\'
        if (
            [string]::Equals($gitCommonProbePath, $candidate, [System.StringComparison]::OrdinalIgnoreCase) -or
            $gitCommonProbePath.StartsWith($candidatePrefix, [System.StringComparison]::OrdinalIgnoreCase)
        ) {
            break
        }
        $parent = Split-Path -Parent $candidate
        if ([string]::IsNullOrWhiteSpace($parent) -or [string]::Equals($parent, $candidate, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Unable to derive a common workspace for document encoding gate: repo=$repo git_common=$gitCommonProbePath"
        }
        $candidate = [System.IO.Path]::GetFullPath($parent).TrimEnd('\')
    }
    $candidate
}
$runtimeTemp = if (-not [string]::IsNullOrWhiteSpace($RuntimeTempRoot)) {
    [System.IO.Path]::GetFullPath($RuntimeTempRoot).TrimEnd('\')
}
else {
    [System.IO.Path]::GetFullPath((Join-Path $workspace 'tools\runtimes\.tmp\i0')).TrimEnd('\')
}

if ($SourceMode -eq 'worktree') {
    if (-not [string]::Equals($repo, $gitRepo, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Worktree document encoding root and Git root differ: repo=$repo git_repo=$gitRepo"
    }
}
else {
    if (-not $repo.StartsWith($runtimeTemp + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "HEAD document encoding root escaped the I0 runtime root: $repo"
    }
    if ($ExpectedHead -notmatch '\A[0-9a-fA-F]{40}\z') {
        throw "HEAD document encoding requires an exact 40-character commit id: $ExpectedHead"
    }
}
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    throw "Document encoding root does not exist: $repo"
}

function Assert-NoReparsePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$StopRoot
    )

    $cursor = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
    $stop = [System.IO.Path]::GetFullPath($StopRoot).TrimEnd('\')
    while ($true) {
        if (-not (Test-Path -LiteralPath $cursor)) {
            throw "Encoding inventory path is missing: $cursor"
        }
        $item = Get-Item -LiteralPath $cursor -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Encoding inventory path is a reparse point: $cursor"
        }
        if ([string]::Equals($cursor, $stop, [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or [string]::Equals($parent, $cursor, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Encoding inventory path escaped the approved root: $Path"
        }
        $cursor = $parent.TrimEnd('\')
    }
}

function Get-NormalizedLfSha256 {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    $normalized = New-Object System.Collections.Generic.List[byte]
    for ($index = 0; $index -lt $Bytes.Length; $index += 1) {
        if ($Bytes[$index] -eq 13 -and $index + 1 -lt $Bytes.Length -and $Bytes[$index + 1] -eq 10) {
            [void]$normalized.Add([byte]10)
            $index += 1
        }
        else {
            [void]$normalized.Add($Bytes[$index])
        }
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($normalized.ToArray()))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function Get-GitText {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $output = & git -C $gitRepo @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed for document encoding gate: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return ($output -join "`n")
}

if (
    -not [string]::Equals($repo, $workspace, [System.StringComparison]::OrdinalIgnoreCase) -and
    -not $repo.StartsWith($workspace + '\', [System.StringComparison]::OrdinalIgnoreCase)
) {
    throw "Document encoding root escaped the workspace: $repo"
}
Assert-NoReparsePath -Path $repo -StopRoot $workspace
if (
    -not [string]::Equals($gitRepo, $workspace, [System.StringComparison]::OrdinalIgnoreCase) -and
    -not $gitRepo.StartsWith($workspace + '\', [System.StringComparison]::OrdinalIgnoreCase)
) {
    throw "Document encoding Git root escaped the workspace: $gitRepo"
}
Assert-NoReparsePath -Path $gitRepo -StopRoot $workspace
$docsRoot = Join-Path $repo 'docs'
Assert-NoReparsePath -Path $docsRoot -StopRoot $workspace

$gitAdminEntry = Join-Path $gitRepo '.git'
if (-not (Test-Path -LiteralPath $gitAdminEntry)) {
    throw "Document encoding gate requires a Git admin entry: $gitAdminEntry"
}
Assert-NoReparsePath -Path $gitAdminEntry -StopRoot $workspace
$gitTopLevel = [System.IO.Path]::GetFullPath((Get-GitText -Arguments @('rev-parse', '--show-toplevel')).Trim()).TrimEnd('\')
if (-not [string]::Equals($gitTopLevel, $gitRepo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Git top-level differs from the approved Git root: $gitTopLevel"
}
$gitDirectoryRaw = (Get-GitText -Arguments @('rev-parse', '--path-format=absolute', '--git-dir')).Trim()
$gitDirectory = if ([System.IO.Path]::IsPathRooted($gitDirectoryRaw)) { [System.IO.Path]::GetFullPath($gitDirectoryRaw) } else { [System.IO.Path]::GetFullPath((Join-Path $gitRepo $gitDirectoryRaw)) }
if (
    -not [string]::Equals($gitDirectory.TrimEnd('\'), $workspace, [System.StringComparison]::OrdinalIgnoreCase) -and
    -not $gitDirectory.StartsWith($workspace + '\', [System.StringComparison]::OrdinalIgnoreCase)
) {
    throw "Git admin directory escaped the workspace: $gitDirectory"
}
Assert-NoReparsePath -Path $gitDirectory -StopRoot $workspace
$gitCommonRaw = (Get-GitText -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir')).Trim()
$gitCommon = if ([System.IO.Path]::IsPathRooted($gitCommonRaw)) { [System.IO.Path]::GetFullPath($gitCommonRaw) } else { [System.IO.Path]::GetFullPath((Join-Path $gitRepo $gitCommonRaw)) }
if (
    -not [string]::Equals($gitCommon.TrimEnd('\'), $workspace, [System.StringComparison]::OrdinalIgnoreCase) -and
    -not $gitCommon.StartsWith($workspace + '\', [System.StringComparison]::OrdinalIgnoreCase)
) {
    throw "Git common directory escaped the workspace: $gitCommon"
}
Assert-NoReparsePath -Path $gitCommon -StopRoot $workspace
$alternatesPath = Join-Path $gitCommon 'objects\info\alternates'
if (Test-Path -LiteralPath $alternatesPath) {
    throw "Git object alternates are forbidden for the document encoding gate: $alternatesPath"
}

$gitStatusBefore = Get-GitText -Arguments @('status', '--porcelain=v2', '--branch', '--untracked-files=all')
$headBefore = (Get-GitText -Arguments @('rev-parse', '--verify', 'HEAD')).Trim()
if ($SourceMode -eq 'head' -and -not [string]::Equals($headBefore, $ExpectedHead, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Active Git HEAD differs from the requested document encoding commit: expected=$ExpectedHead actual=$headBefore"
}
if ($SourceMode -eq 'worktree') {
    $rawInventory = & git -C $gitRepo -c core.quotepath=false ls-files --cached --others --exclude-standard -z -- docs 2>&1
}
else {
    $rawInventory = & git -C $gitRepo -c core.quotepath=false ls-tree -r -z --name-only $ExpectedHead -- docs 2>&1
}
if ($LASTEXITCODE -ne 0) {
    throw "Git document inventory failed: $rawInventory"
}
$inventory = @([string]$rawInventory -split [char]0 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($inventory.Count -eq 0) {
    throw 'Git document inventory is empty.'
}

$textExtensions = @('.md', '.txt', '.yaml', '.yml', '.json', '.csv', '.tsv', '.toml', '.ini', '.cfg', '.xml', '.html', '.css', '.js', '.ts', '.svg', '.ps1', '.py', '.gd', '.godot')
$binaryExtensions = @('.png', '.jpg')
$specialTextNames = @('.gitignore', '.gitattributes')
$allowedInvalid = [ordered]@{
    'docs/00_governance/P2_EXECUTION_REPORT.md' = '339F5894B0073B8E01A0E9F29119974EE672C458D7EBF127D7408BC4FB4259C9'
    'docs/20_product/PRODUCT_CONTRACT.md' = 'A084706612E6B1C5939AEDFE7A34BF04F69F97B20EAB080971CFA30E48F6D88E'
    'docs/30_engineering/adr/README.md' = '751CA1D949B5B0F234F4EE4C22D0D7B4FEDEF76092FB252502CFB76A6A60834D'
    'docs/30_engineering/architecture/README.md' = 'EAE2C7A825C993427918D27E9B9242D800D1FB16424351C8F2604EFADC8A757E'
    'docs/90_archive/generated_reports/README.md' = 'FE0F51B01FD0772EBC936341D0250264E9EF6A5EDB4513804E9F8E12790C0D65'
}

$ledgerPath = Join-Path $repo 'docs\00_governance\TEXT_ENCODING_LEDGER.md'
Assert-NoReparsePath -Path $ledgerPath -StopRoot $workspace
$ledgerEncoding = New-Object System.Text.UTF8Encoding($false, $true)
$ledgerText = [System.IO.File]::ReadAllText($ledgerPath, $ledgerEncoding)
foreach ($allowedPath in $allowedInvalid.Keys) {
    $ledgerRowMarker = '| `' + $allowedPath + '` | `' + [string]$allowedInvalid[$allowedPath] + '` |'
    if ($ledgerText.IndexOf($ledgerRowMarker, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Encoding ledger does not contain the exact path/hash exception: $allowedPath"
    }
}

$errors = New-Object System.Collections.Generic.List[string]
$exceptionsObserved = New-Object System.Collections.Generic.List[object]
$seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$allowedSeen = @{}
$textCount = 0
$binaryCount = 0
$binaryMagicMismatchCount = 0
$strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)

foreach ($relativeRaw in $inventory) {
    $relative = $relativeRaw.Replace('\', '/')
    if (-not $seen.Add($relative)) {
        [void]$errors.Add("duplicate or case-colliding inventory path: $relative")
        continue
    }
    if (-not $relative.StartsWith('docs/', [System.StringComparison]::Ordinal)) {
        [void]$errors.Add("inventory path is outside docs: $relative")
        continue
    }
    $absolute = [System.IO.Path]::GetFullPath((Join-Path $repo $relative.Replace('/', '\')))
    $approvedPrefix = $docsRoot.TrimEnd('\') + '\'
    if (-not $absolute.StartsWith($approvedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        [void]$errors.Add("inventory path escaped docs: $relative")
        continue
    }
    try {
        Assert-NoReparsePath -Path $absolute -StopRoot $workspace
    }
    catch {
        [void]$errors.Add($_.Exception.Message)
        continue
    }

    $name = [System.IO.Path]::GetFileName($absolute)
    $extension = [System.IO.Path]::GetExtension($absolute).ToLowerInvariant()
    $isText = ($specialTextNames -contains $name) -or ($textExtensions -contains $extension)
    $isBinary = $binaryExtensions -contains $extension
    if (-not $isText -and -not $isBinary) {
        [void]$errors.Add("unknown document file type: $relative")
        continue
    }
    if ($isBinary) {
        $binaryCount += 1
        try {
            $binaryBytes = [System.IO.File]::ReadAllBytes($absolute)
            $hasPngMagic = (
                $binaryBytes.Length -ge 8 -and
                $binaryBytes[0] -eq 137 -and $binaryBytes[1] -eq 80 -and $binaryBytes[2] -eq 78 -and $binaryBytes[3] -eq 71 -and
                $binaryBytes[4] -eq 13 -and $binaryBytes[5] -eq 10 -and $binaryBytes[6] -eq 26 -and $binaryBytes[7] -eq 10
            )
            $hasJpegMagic = ($binaryBytes.Length -ge 3 -and $binaryBytes[0] -eq 255 -and $binaryBytes[1] -eq 216 -and $binaryBytes[2] -eq 255)
            if (-not $hasPngMagic -and -not $hasJpegMagic) {
                [void]$errors.Add("known image extension has neither PNG nor JPEG magic: $relative")
            }
            elseif (($extension -eq '.png' -and $hasJpegMagic) -or ($extension -eq '.jpg' -and $hasPngMagic)) {
                $binaryMagicMismatchCount += 1
            }
        }
        catch {
            [void]$errors.Add("unreadable binary document evidence: $relative :: $($_.Exception.Message)")
        }
        continue
    }

    $textCount += 1
    try {
        $bytes = [System.IO.File]::ReadAllBytes($absolute)
    }
    catch {
        [void]$errors.Add("unreadable document: $relative :: $($_.Exception.Message)")
        continue
    }

    try {
        [void]$strictUtf8.GetString($bytes)
    }
    catch [System.Text.DecoderFallbackException] {
        $hash = Get-NormalizedLfSha256 -Bytes $bytes
        if ($allowedInvalid.Contains($relative) -and [string]::Equals([string]$allowedInvalid[$relative], $hash, [System.StringComparison]::Ordinal)) {
            $allowedSeen[$relative] = $true
            [void]$exceptionsObserved.Add([pscustomobject][ordered]@{
                path = $relative
                normalized_lf_sha256 = $hash
                first_invalid_index = $_.Exception.Index
            })
        }
        else {
            [void]$errors.Add("invalid UTF-8: $relative :: normalized_lf_sha256=$hash :: first_invalid_index=$($_.Exception.Index)")
        }
    }
}

foreach ($allowedPath in $allowedInvalid.Keys) {
    if (-not $allowedSeen.ContainsKey($allowedPath)) {
        [void]$errors.Add("required historical encoding exception was not observed exactly: $allowedPath")
    }
}
if ($inventory.Count -ne ($textCount + $binaryCount)) {
    [void]$errors.Add("inventory accounting mismatch: total=$($inventory.Count), text=$textCount, binary=$binaryCount")
}

$headAfter = (Get-GitText -Arguments @('rev-parse', '--verify', 'HEAD')).Trim()
$headUnchanged = [string]::Equals($headBefore, $headAfter, [System.StringComparison]::OrdinalIgnoreCase)
if (-not $headUnchanged) {
    [void]$errors.Add("Git HEAD changed while running the read-only document encoding gate: before=$headBefore after=$headAfter")
}
$expectedHeadVerified = (
    $SourceMode -eq 'worktree' -or
    (
        [string]::Equals($headBefore, $ExpectedHead, [System.StringComparison]::OrdinalIgnoreCase) -and
        [string]::Equals($headAfter, $ExpectedHead, [System.StringComparison]::OrdinalIgnoreCase)
    )
)
if (-not $expectedHeadVerified) {
    [void]$errors.Add("Requested HEAD was not stable throughout the document encoding gate: expected=$ExpectedHead before=$headBefore after=$headAfter")
}
$gitStatusAfter = Get-GitText -Arguments @('status', '--porcelain=v2', '--branch', '--untracked-files=all')
if ($gitStatusBefore -cne $gitStatusAfter) {
    [void]$errors.Add('Git status changed while running the read-only document encoding gate.')
}

$status = if ($errors.Count -eq 0) { 'PASS_WITH_RECORDED_LIMITATION' } else { 'FAIL' }
$result = [pscustomobject][ordered]@{
    schema_version = 2
    gate = 'I0_DOCUMENT_ENCODING'
    status = $status
    source_mode = $SourceMode
    repo_root = $repo
    git_repo_root = $gitRepo
    expected_head = $ExpectedHead
    head_before = $headBefore
    head_after = $headAfter
    head_unchanged = $headUnchanged
    expected_head_verified = $expectedHeadVerified
    inventory_total = $inventory.Count
    text_scanned = $textCount
    known_binary_skipped = $binaryCount
    known_binary_magic_validated = $binaryCount
    image_extension_magic_mismatch_count = $binaryMagicMismatchCount
    allowed_invalid_count = $allowedInvalid.Count
    observed_invalid_count = $exceptionsObserved.Count
    observed_exceptions = $exceptionsObserved.ToArray()
    error_count = $errors.Count
    errors = $errors.ToArray()
    ledger_contract_verified = $true
    git_status_unchanged = ($gitStatusBefore -ceq $gitStatusAfter)
}

Write-Output ('I0_DOCUMENT_ENCODING_JSON=' + ($result | ConvertTo-Json -Depth 10 -Compress))
Write-Output ('I0_DOCUMENT_ENCODING=' + $status)
if ($errors.Count -eq 0) {
    exit 0
}
exit 1
