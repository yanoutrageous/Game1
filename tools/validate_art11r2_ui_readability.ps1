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

$statusLines = @(& git status --short)
$generatedPatterns = @(
    '\.uid$',
    '\.translation$',
    '(^|/)project\.godot$',
    '(^|/)\.godot(/|$)',
    '\.import$'
)

$allowedPatterns = @(
    '^Godot/GraytailGodot/scripts/presentation/',
    '^Godot/GraytailGodot/scripts/ui/',
    '^docs/art/ART11R2_CORE_UI_READABILITY_REWORK\.md$',
    '^docs/art/validation/art11r2(/|$)',
    '^tools/validate_art11r2_.*\.ps1$'
)

$forbiddenCodePatterns = @(
    '^Godot/GraytailGodot/scripts/core/run/.*\.gd$',
    '^Godot/GraytailGodot/scripts/core/command/.*\.gd$',
    '^Godot/GraytailGodot/scripts/core/save/.*\.gd$',
    '^Godot/GraytailGodot/data/assets/asset_manifest\.csv$'
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

    foreach ($pattern in $forbiddenCodePatterns) {
        if ($path -match $pattern) {
            Add-Error "forbidden ART-11R2 dirty path: $path"
        }
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

$playerFacingFiles = @(
    "Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd",
    "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd",
    "Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd",
    "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd",
    "Godot/GraytailGodot/scripts/ui/hud/hud_view_model.gd",
    "Godot/GraytailGodot/scripts/ui/minimap/minimap_panel.gd"
)

$engineeringWordPattern = '"[^"]*(preview|read_only|display_only|schema|interface|G24|G30|slot|no_persistence|Legacy|Debug)[^"]*"'
foreach ($file in $playerFacingFiles) {
    if (-not (Test-Path $file)) {
        Add-Error "missing player-facing UI file: $file"
        continue
    }
    $matches = Select-String -Path $file -Pattern $engineeringWordPattern
    foreach ($match in $matches) {
        Add-Warning "engineering-word review needed: $($match.Path):$($match.LineNumber)"
    }
}

$legacyHudFile = "Godot/GraytailGodot/scripts/ui/hud/hud_view_model.gd"
if (Test-Path $legacyHudFile) {
    $legacyHudLeaks = Select-String -Path $legacyHudFile -Pattern 'status_text\s*\+=|RunLifecycle:\s|RoomPolicy:\s|EncounterPreview:\s|RoomResolutionPreview:\s|Rule/Modifier:\s|ContentPool:\s|fast_return:\s|SettlementTriggerPreview:\s'
    foreach ($match in $legacyHudLeaks) {
        Add-Error "legacy HUD diagnostic copy leak: $($match.Path):$($match.LineNumber)"
    }
} else {
    Add-Error "missing legacy HUD view model: $legacyHudFile"
}

$runUIViewModelFile = "Godot/GraytailGodot/scripts/ui/shell/run_ui_view_model.gd"
if (Test-Path $runUIViewModelFile) {
    $commandFeedbackPatterns = @(
        "message_key",
        "command\.accepted",
        "command\.rejected",
        "return\s+reason_code"
    )
    $commandFeedbackLeaks = Select-String -Path $runUIViewModelFile -Pattern $commandFeedbackPatterns
    foreach ($match in $commandFeedbackLeaks) {
        Add-Error "run UI command feedback code leak: $($match.Path):$($match.LineNumber)"
    }
} else {
    Add-Error "missing run UI view model: $runUIViewModelFile"
}

$screenshotDir = "docs/art/validation/art11r2"
$requiredScreenshots = @(
    "art11r2_main_menu_1280x720.png",
    "art11r2_deploy_prep_1280x720.png",
    "art11r2_long_term_1280x720.png",
    "art11r2_run_hud_1280x720.png",
    "art11r2_main_menu_1600x900.png",
    "art11r2_deploy_prep_1600x900.png",
    "art11r2_long_term_1600x900.png",
    "art11r2_run_hud_1600x900.png",
    "art11r2_main_menu_1920x1080.png",
    "art11r2_deploy_prep_1920x1080.png",
    "art11r2_long_term_1920x1080.png",
    "art11r2_run_hud_1920x1080.png",
    "final_self_check_run_hud_after_hotfix.png",
    "final_self_check_run_hud_interaction_after_hotfix.png",
    "final_self_check_run_hud_interaction_after_hotfix3.png"
)

foreach ($name in $requiredScreenshots) {
    $path = Join-Path $screenshotDir $name
    if (-not (Test-Path $path)) {
        Add-Error "missing ART-11R2 screenshot: $path"
        continue
    }
    $item = Get-Item $path
    if ($item.Length -lt 1000) {
        Add-Error "screenshot appears too small: $path"
    }
}

$docPath = "docs/art/ART11R2_CORE_UI_READABILITY_REWORK.md"
if (-not (Test-Path $docPath)) {
    Add-Error "missing ART-11R2 document: $docPath"
}

Write-Host "ART-11R2 UI readability validation"
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
Write-Host "ART-11R2 validation passed."
exit 0
