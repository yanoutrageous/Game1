param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$issues = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Issue([string]$Message) {
    $issues.Add($Message) | Out-Null
}

function Add-Warning([string]$Message) {
    $warnings.Add($Message) | Out-Null
}

function Test-File([string]$RelativePath) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $RelativePath))) {
        Add-Issue "Missing required file: $RelativePath"
    }
}

function Select-Rg([string]$Pattern, [string[]]$Paths) {
    $result = & rg --line-number --fixed-strings --glob '!*.uid' --glob '!*.translation' $Pattern @Paths 2>$null
    if ($LASTEXITCODE -eq 0) {
        return $result
    }
    return @()
}

function Get-GitDiffNameOnly([string[]]$Paths) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $result = & git diff --name-only -- @Paths 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
        return @()
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

function Get-GitStatusShort([string[]]$Paths) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $result = & git status --short -- @Paths 2>$null
        if ($LASTEXITCODE -eq 0) {
            return $result
        }
        return @()
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
}

Push-Location $RepoRoot
try {
    Test-File "docs/art/ART17_CORE_SCREEN_LAYER_LANDING_AND_GAMESTAGE_REWORK.md"
    $screenshots = @(
        "docs/art/validation/art17/art17_main_menu_1280x720.png",
        "docs/art/validation/art17/art17_deploy_prep_1280x720.png",
        "docs/art/validation/art17/art17_long_term_1280x720.png",
        "docs/art/validation/art17/art17_run_hud_1280x720.png",
        "docs/art/validation/art17/art17_map_overlay_1280x720.png",
        "docs/art/validation/art17/art17_main_menu_max_final.png",
        "docs/art/validation/art17/art17_deploy_max_final.png",
        "docs/art/validation/art17/art17_long_term_max_final.png",
        "docs/art/validation/art17/art17_run_hud_max_final.png",
        "docs/art/validation/art17/art17_map_overlay_max_final.png"
    )
    foreach ($shot in $screenshots) {
        Test-File $shot
        $shotPath = Join-Path $RepoRoot $shot
        if ((Test-Path -LiteralPath $shotPath) -and ((Get-Item -LiteralPath $shotPath).Length -le 0)) {
            Add-Issue "Empty screenshot: $shot"
        }
    }

    $contractFile = "Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd"
    $runFile = "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd"
    foreach ($rootName in @(
        "BackgroundRoot",
        "DecorationRoot",
        "CharacterRoot",
        "MainContentRoot",
        "SideStatusRoot",
        "PrimaryActionRoot",
        "FloatingInfoRoot",
        "OverlayRoot",
        "ModalRoot",
        "RunGameStageRoot",
        "RunRoomViewportRoot",
        "RunLeftInfoRailRoot",
        "RunTopRightStatusRoot",
        "RunActionOverlayRoot",
        "RunOverlayRoot",
        "RunModalRoot"
    )) {
        $hits = Select-Rg $rootName @($contractFile, $runFile, "Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd", "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd", "Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd")
        if ($hits.Count -eq 0) {
            Add-Issue "Layer root not found in UI scripts: $rootName"
        }
    }

    $highZ = & rg --line-number "z_index\s*=\s*(2[0-9]{2,}|[3-9][0-9]{2,})" "Godot/GraytailGodot/scripts/ui" "Godot/GraytailGodot/scripts/presentation" 2>$null
    if ($LASTEXITCODE -eq 0 -and $highZ.Count -gt 0) {
        Add-Issue "High z_index bypass found:`n$($highZ -join "`n")"
    }

    $expandIcon = & rg --line-number "expand_icon\s*=\s*true" "Godot/GraytailGodot/scripts/ui" "Godot/GraytailGodot/scripts/presentation" 2>$null
    if ($LASTEXITCODE -eq 0 -and $expandIcon.Count -gt 0) {
        Add-Issue "expand_icon=true found:`n$($expandIcon -join "`n")"
    }

    $runtimeHardcodes = & rg --line-number "D:\\AGAME1\\Base Art|D:\\AGAME1\\Draw|D:\\AGAME1\\Connection" "Godot/GraytailGodot/scripts/ui" "Godot/GraytailGodot/scripts/presentation" 2>$null
    if ($LASTEXITCODE -eq 0 -and $runtimeHardcodes.Count -gt 0) {
        Add-Issue "Forbidden external runtime path hardcode found:`n$($runtimeHardcodes -join "`n")"
    }

    $coreSemanticDiff = Get-GitDiffNameOnly @("Godot/GraytailGodot/scripts/core/command", "Godot/GraytailGodot/scripts/core/save")
    if ($coreSemanticDiff.Count -gt 0) {
        Add-Issue "Tracked command/save core diff exists:`n$($coreSemanticDiff -join "`n")"
    }

    $runSceneDiff = Get-GitDiffNameOnly @("Godot/GraytailGodot/scripts/core/run/run_scene.gd")
    if ($runSceneDiff.Count -gt 0) {
        Add-Warning "run_scene.gd has tracked diff; audit must confirm it is UI mount only."
    }

    $manifestDiff = Get-GitDiffNameOnly @("Godot/GraytailGodot/data/assets/asset_manifest.csv")
    if ($manifestDiff.Count -gt 0) {
        Add-Warning "asset_manifest.csv is dirty; this validator treats it as pre-existing and not an ART-17 target."
    }

    $generatedStatus = Get-GitStatusShort @("Godot/GraytailGodot/project.godot", "Godot/GraytailGodot/*.translation", "Godot/GraytailGodot/**/*.uid", "Godot/GraytailGodot/.godot")
    if ($generatedStatus.Count -gt 0) {
        Add-Warning "Generated side effects present and must stay out of ART-17 commit:`n$($generatedStatus -join "`n")"
    }
}
finally {
    Pop-Location
}

foreach ($warning in $warnings) {
    Write-Host "WARNING: $warning"
}

if ($issues.Count -gt 0) {
    foreach ($issue in $issues) {
        Write-Host "ERROR: $issue"
    }
    exit 1
}

Write-Host "ART-17 core screen layering validation passed."
exit 0
