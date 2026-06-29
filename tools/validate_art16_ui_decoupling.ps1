param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$message) {
    [void]$failures.Add($message)
}

function Add-Warning([string]$message) {
    [void]$warnings.Add($message)
}

function Assert-FileExists([string]$relativePath) {
    $path = Join-Path $RepoRoot $relativePath
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Missing file: $relativePath"
        return
    }
    $item = Get-Item -LiteralPath $path
    if ($item.Length -le 0) {
        Add-Failure "Empty file: $relativePath"
    }
}

function Normalize-PathText([string]$pathText) {
    return ($pathText -replace "\\", "/").TrimEnd("/")
}

Push-Location $RepoRoot
try {
    $gitRoot = (& git rev-parse --show-toplevel).Trim()
    if ((Normalize-PathText $gitRoot) -ne (Normalize-PathText $RepoRoot)) {
        Add-Failure "Unexpected git root: $gitRoot"
    }

    Assert-FileExists "Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd"
    Assert-FileExists "docs/art/ART16_CORE_UI_DECOUPLING_AND_RELAYOUT.md"

    $requiredScreenshots = @(
        "docs/art/validation/art16/art16_main_menu_1280x720.png",
        "docs/art/validation/art16/art16_deploy_prep_1280x720.png",
        "docs/art/validation/art16/art16_long_term_1280x720.png",
        "docs/art/validation/art16/art16_run_hud_1280x720.png",
        "docs/art/validation/art16/art16_map_overlay_1280x720.png",
        "docs/art/validation/art16/art16_main_menu_1600x900.png",
        "docs/art/validation/art16/art16_deploy_prep_1600x900.png",
        "docs/art/validation/art16/art16_long_term_1600x900.png",
        "docs/art/validation/art16/art16_run_hud_1600x900.png",
        "docs/art/validation/art16/art16_main_menu_1920x1080.png",
        "docs/art/validation/art16/art16_deploy_prep_1920x1080.png",
        "docs/art/validation/art16/art16_long_term_1920x1080.png",
        "docs/art/validation/art16/art16_run_hud_1920x1080.png"
    )
    foreach ($screenshot in $requiredScreenshots) {
        Assert-FileExists $screenshot
    }

    $dirty = & git status --short
    $dirtyText = ($dirty -join "`n")
    $forbiddenDirtyPatterns = @(
        "^ M Godot/GraytailGodot/data/assets/asset_manifest\.csv$",
        "^ M Godot/GraytailGodot/project\.godot$",
        "^\?\? Godot/GraytailGodot/assets/",
        "^ M Godot/GraytailGodot/data/assets/asset_manifest\..*\.translation$",
        "^\?\? Godot/GraytailGodot/data/assets/asset_manifest\..*\.translation$",
        "^\?\? Godot/GraytailGodot/.*\.uid$"
    )
    foreach ($line in $dirty) {
        foreach ($pattern in $forbiddenDirtyPatterns) {
            if ($line -match $pattern) {
                Add-Warning "Pre-existing or generated dirty still present and must not be staged as ART-16: $line"
            }
        }
    }

    $commandSaveDiff = & git diff --numstat --ignore-cr-at-eol -- Godot/GraytailGodot/scripts/core/command Godot/GraytailGodot/scripts/core/save
    if (($commandSaveDiff | Measure-Object).Count -gt 0) {
        Add-Failure "core/command or core/save has substantive diff."
    }

    $coreRunDiff = & git diff --numstat --ignore-cr-at-eol -- Godot/GraytailGodot/scripts/core/run/run_scene.gd
    if (($coreRunDiff | Measure-Object).Count -gt 0) {
        Add-Warning "core/run/run_scene.gd has ART-16 UI mount diff; audit must confirm it is presentation-only."
    }

    $uiFiles = @(
        "Godot/GraytailGodot/scripts/ui",
        "Godot/GraytailGodot/scripts/presentation"
    )
    $hardcodeHits = & rg --fixed-strings "D:\AGAME1\Base Art" $uiFiles 2>$null
    if (($hardcodeHits | Measure-Object).Count -gt 0) {
        Add-Failure "Direct Base Art runtime path found in UI/presentation scripts."
    }
    $drawHits = & rg --fixed-strings "D:\AGAME1\Draw" $uiFiles 2>$null
    if (($drawHits | Measure-Object).Count -gt 0) {
        Add-Failure "Direct Draw runtime path found in UI/presentation scripts."
    }
    $expandIconHits = & rg "expand_icon\s*=\s*true" $uiFiles 2>$null
    if (($expandIconHits | Measure-Object).Count -gt 0) {
        Add-Failure "expand_icon = true found in UI/presentation scripts."
    }

    $visibleRiskHits = & rg "Dev Debug|command\.rejected|command\.accepted|not_searchable|message_key|display_only|read_only|fast_return" "Godot/GraytailGodot/scripts/ui" "Godot/GraytailGodot/scripts/presentation" 2>$null
    if (($visibleRiskHits | Measure-Object).Count -gt 0) {
        Add-Warning "Potential player-visible engineering copy in UI/presentation scripts:`n$($visibleRiskHits -join "`n")"
    }

    Write-Host "ART-16 validation summary"
    Write-Host "Repo root: $gitRoot"
    Write-Host "Screenshots checked: $($requiredScreenshots.Count)"
    if ($warnings.Count -gt 0) {
        Write-Host "Warnings:"
        foreach ($warning in $warnings) {
            Write-Host " - $warning"
        }
    }
    if ($failures.Count -gt 0) {
        Write-Host "Failures:"
        foreach ($failure in $failures) {
            Write-Host " - $failure"
        }
        exit 1
    }
    Write-Host "ART-16 validation passed with $($warnings.Count) warning(s)."
}
finally {
    Pop-Location
}
