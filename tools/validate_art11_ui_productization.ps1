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

$statusLines = & git status --short
$generatedPatterns = @(
    '\.uid$',
    '\.translation$',
    '(^|/)project\.godot$',
    '(^|/)\.godot(/|$)',
    '\.import$'
)

$allowedPatterns = @(
    '^Godot/GraytailGodot/scripts/core/settings/settings_manager\.gd$',
    '^Godot/GraytailGodot/scripts/presentation/',
    '^Godot/GraytailGodot/scripts/ui/',
    '^Godot/GraytailGodot/scenes/ui/',
    '^Godot/GraytailGodot/assets/ui/',
    '^Godot/GraytailGodot/assets/fonts/',
    '^Godot/GraytailGodot/data/assets/asset_manifest\.csv$',
    '^docs/art/',
    '^tools/validate_art11_.*\.ps1$'
)

$forbiddenCodePatterns = @(
    '^Godot/GraytailGodot/scripts/core/run/.*\.gd$',
    '^Godot/GraytailGodot/scripts/core/command/.*\.gd$',
    '^Godot/GraytailGodot/scripts/core/save/.*\.gd$'
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
        Add-Warning "generated side effect present: $path"
        continue
    }

    $isAllowed = $false
    foreach ($pattern in $allowedPatterns) {
        if ($path -match $pattern) {
            $isAllowed = $true
            break
        }
    }
    if (-not $isAllowed) {
        Add-Error "unexpected dirty path: $path"
    }
    foreach ($pattern in $forbiddenCodePatterns) {
        if ($path -match $pattern) {
            Add-Error "forbidden gameplay code path modified: $path"
        }
    }
}

$scanRoots = @(
    "Godot/GraytailGodot/scripts/ui",
    "Godot/GraytailGodot/scripts/presentation"
)

foreach ($root in $scanRoots) {
    if (Test-Path $root) {
        $hardcoded = Get-ChildItem -Path $root -Recurse -Filter "*.gd" | Select-String -Pattern 'D:\\AGAME1\\(Base Art|Draw|Connection)'
        foreach ($match in $hardcoded) {
            Add-Error "external runtime path hardcode: $($match.Path):$($match.LineNumber)"
        }
        $expandIcon = Get-ChildItem -Path $root -Recurse -Filter "*.gd" | Select-String -Pattern 'expand_icon\s*=\s*true'
        foreach ($match in $expandIcon) {
            Add-Error "uncontrolled button icon expansion: $($match.Path):$($match.LineNumber)"
        }
    }
}

$screenshotDir = "docs/art/validation/art11"
$requiredScreenshots = @(
    "art11_main_menu_1280x720.png",
    "art11_deploy_prep_1280x720.png",
    "art11_long_term_1280x720.png",
    "art11_run_hud_1280x720.png",
    "art11_main_menu_1600x900.png",
    "art11_deploy_prep_1600x900.png",
    "art11_long_term_1600x900.png",
    "art11_run_hud_1600x900.png",
    "art11_main_menu_1920x1080.png",
    "art11_deploy_prep_1920x1080.png",
    "art11_long_term_1920x1080.png",
    "art11_run_hud_1920x1080.png"
)

foreach ($name in $requiredScreenshots) {
    $path = Join-Path $screenshotDir $name
    if (-not (Test-Path $path)) {
        Add-Error "missing ART-11 screenshot: $path"
    }
}

$docPath = "docs/art/ART11_UI_PRODUCTIZATION_SYSTEM_AND_CORE_SCREENS.md"
if (-not (Test-Path $docPath)) {
    Add-Error "missing ART-11 document: $docPath"
}

Write-Host "ART-11 UI productization validation"
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
Write-Host "ART-11 validation passed."
exit 0
