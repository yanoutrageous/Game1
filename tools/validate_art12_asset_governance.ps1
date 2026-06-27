$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $RepoRoot

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Error([string]$Message) {
    $errors.Add($Message) | Out-Null
}

function Add-Warning([string]$Message) {
    $warnings.Add($Message) | Out-Null
}

function Normalize-RepoPath([string]$PathValue) {
    return $PathValue.Replace('\', '/').TrimEnd('/')
}

$gitRoot = (& git rev-parse --show-toplevel).Trim()
if ((Normalize-RepoPath $gitRoot) -ne (Normalize-RepoPath $RepoRoot.Path)) {
    Add-Error "git root mismatch: $gitRoot"
}

$staged = @(& git diff --cached --name-only)
if ($staged.Count -gt 0) {
    foreach ($path in $staged) {
        Add-Error "staged file is not allowed in ART-12 execution: $path"
    }
}

$requiredDocs = @(
    "docs/art/ART12_ART_ASSET_GOVERNANCE_AND_PRODUCTIZATION_BACKLOG.md",
    "docs/art/validation/art12/ASSET_INVENTORY_SUMMARY.md",
    "docs/art/validation/art12/DRAW_BASE_ART_DIFF.md",
    "docs/art/validation/art12/BASE_ART_REGISTRY_AUDIT.md",
    "docs/art/validation/art12/UI_PRODUCTIZATION_ASSET_GAP.md",
    "docs/art/validation/art12/RUNTIME_IMPORT_CANDIDATE_PLAN.md",
    "docs/art/validation/art12/QUARANTINE_DRY_RUN.md"
)

foreach ($path in $requiredDocs) {
    if (-not (Test-Path $path)) {
        Add-Error "missing ART-12 document: $path"
    }
}

if (-not (Test-Path "tools/validate_art12_asset_governance.ps1")) {
    Add-Error "missing ART-12 validation script"
}

$statusLines = @(& git status --short)
$generatedPatterns = @(
    '\.uid$',
    '\.translation$',
    '(^|/)project\.godot$',
    '(^|/)\.godot(/|$)',
    '\.import$'
)

$allowedArt12Patterns = @(
    '^docs/art/ART12_ART_ASSET_GOVERNANCE_AND_PRODUCTIZATION_BACKLOG\.md$',
    '^docs/art/validation/art12(/|$)',
    '^tools/validate_art12_asset_governance\.ps1$'
)

$forbiddenDirtyPatterns = @(
    '^Godot/GraytailGodot/scripts/',
    '^Godot/GraytailGodot/scenes/',
    '^Godot/GraytailGodot/assets/',
    '^Godot/GraytailGodot/data/assets/asset_manifest\.csv$',
    '^Draw(/|$)',
    '^Base Art(/|$)',
    '^Connection(/|$)'
)

foreach ($line in $statusLines) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    $path = $line.Substring(3).Replace('\', '/')

    $isGenerated = $false
    foreach ($pattern in $generatedPatterns) {
        if ($path -match $pattern) {
            $isGenerated = $true
            break
        }
    }
    if ($isGenerated) {
        Add-Warning "generated side effect present and excluded from ART-12成果: $path"
        continue
    }

    $isAllowedArt12 = $false
    foreach ($pattern in $allowedArt12Patterns) {
        if ($path -match $pattern) {
            $isAllowedArt12 = $true
            break
        }
    }
    if (-not $isAllowedArt12) {
        Add-Error "unexpected dirty path for ART-12: $path"
    }

    foreach ($pattern in $forbiddenDirtyPatterns) {
        if ($path -match $pattern) {
            Add-Error "forbidden dirty path for ART-12: $path"
        }
    }
}

$art12Docs = @()
foreach ($path in $requiredDocs) {
    if (Test-Path $path) {
        $art12Docs += $path
    }
}

$promisePattern = '\b(status|manifest_status|review_status)\b\s*[:=|]\s*(approved|final|runtime_ready)\b|\b(approved|final|runtime_ready)\b\s*[:=|]\s*(true|yes|pass|ready)\b'
$safeContextPattern = 'not_ready|not_generated_final|dry-run|forbidden|not allowed|risk|check|no current promise'
foreach ($doc in $art12Docs) {
    $matches = Select-String -Path $doc -Pattern $promisePattern -CaseSensitive:$false
    foreach ($match in $matches) {
        if ($match.Line -notmatch $safeContextPattern) {
            Add-Error "possible approved/final/runtime_ready current promise: $($match.Path):$($match.LineNumber)"
        }
    }
}

$quarantineDoc = "docs/art/validation/art12/QUARANTINE_DRY_RUN.md"
if (Test-Path $quarantineDoc) {
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $quarantineDoc
    if ($content -notmatch 'NOT_DELETION_AUTHORIZATION') {
        Add-Error "quarantine dry-run document must include NOT_DELETION_AUTHORIZATION marker"
    }
} else {
    Add-Error "missing quarantine dry-run document"
}

Write-Host "ART-12 asset governance validation"
Write-Host "git root: $gitRoot"
Write-Host "status entries: $($statusLines.Count)"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    foreach ($warning in $warnings) {
        Write-Host "- $warning"
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:"
    foreach ($errorItem in $errors) {
        Write-Host "- $errorItem"
    }
    exit 1
}

Write-Host ""
Write-Host "ART-12 validation passed."
exit 0
