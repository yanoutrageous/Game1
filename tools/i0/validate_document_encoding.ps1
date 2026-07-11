param(
    [string]$RepoRoot = "D:\AGAME1\active\Game1_work"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$approvedRepo = [System.IO.Path]::GetFullPath('D:\AGAME1\active\Game1_work').TrimEnd('\')
$approvedWorkspace = [System.IO.Path]::GetFullPath('D:\AGAME1').TrimEnd('\')
$repo = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\')
if (-not [string]::Equals($repo, $approvedRepo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Document encoding root differs from the approved active repo: $repo"
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

    $output = & git -C $repo @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed for document encoding gate: git $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return ($output -join "`n")
}

if (-not $repo.StartsWith($approvedWorkspace + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Document encoding root escaped the approved workspace: $repo"
}
Assert-NoReparsePath -Path $repo -StopRoot $approvedWorkspace
$docsRoot = Join-Path $repo 'docs'
Assert-NoReparsePath -Path $docsRoot -StopRoot $approvedWorkspace

$gitAdmin = Join-Path $repo '.git'
if (-not (Test-Path -LiteralPath $gitAdmin -PathType Container)) {
    throw "Document encoding gate requires a self-contained .git directory: $gitAdmin"
}
Assert-NoReparsePath -Path $gitAdmin -StopRoot $approvedWorkspace
$gitTopLevel = [System.IO.Path]::GetFullPath((Get-GitText -Arguments @('rev-parse', '--show-toplevel')).Trim()).TrimEnd('\')
if (-not [string]::Equals($gitTopLevel, $repo, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Git top-level differs from the approved active repo: $gitTopLevel"
}
$gitDirectoryRaw = (Get-GitText -Arguments @('rev-parse', '--git-dir')).Trim()
$gitDirectory = if ([System.IO.Path]::IsPathRooted($gitDirectoryRaw)) { [System.IO.Path]::GetFullPath($gitDirectoryRaw) } else { [System.IO.Path]::GetFullPath((Join-Path $repo $gitDirectoryRaw)) }
if (-not [string]::Equals($gitDirectory.TrimEnd('\'), $gitAdmin.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Git admin directory is not self-contained at the approved path: $gitDirectory"
}
$gitCommonRaw = (Get-GitText -Arguments @('rev-parse', '--git-common-dir')).Trim()
$gitCommon = if ([System.IO.Path]::IsPathRooted($gitCommonRaw)) { [System.IO.Path]::GetFullPath($gitCommonRaw) } else { [System.IO.Path]::GetFullPath((Join-Path $repo $gitCommonRaw)) }
if (-not [string]::Equals($gitCommon.TrimEnd('\'), $gitAdmin.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Git common directory differs from the self-contained admin directory: $gitCommon"
}
$alternatesPath = Join-Path $gitAdmin 'objects\info\alternates'
if (Test-Path -LiteralPath $alternatesPath) {
    throw "Git object alternates are forbidden for the document encoding gate: $alternatesPath"
}

$gitStatusBefore = Get-GitText -Arguments @('status', '--porcelain=v2', '--branch', '--untracked-files=all')
$rawInventory = & git -C $repo -c core.quotepath=false ls-files --cached --others --exclude-standard -z -- docs 2>&1
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
Assert-NoReparsePath -Path $ledgerPath -StopRoot $approvedWorkspace
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
        Assert-NoReparsePath -Path $absolute -StopRoot $approvedWorkspace
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

$gitStatusAfter = Get-GitText -Arguments @('status', '--porcelain=v2', '--branch', '--untracked-files=all')
if ($gitStatusBefore -cne $gitStatusAfter) {
    [void]$errors.Add('Git status changed while running the read-only document encoding gate.')
}

$status = if ($errors.Count -eq 0) { 'PASS_WITH_RECORDED_LIMITATION' } else { 'FAIL' }
$result = [pscustomobject][ordered]@{
    schema_version = 1
    gate = 'I0_DOCUMENT_ENCODING'
    status = $status
    repo_root = $repo
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
