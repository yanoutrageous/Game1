param(
    [string]$RepoRoot = (Resolve-Path ".").Path
)

$ErrorActionPreference = "Stop"

function Add-Failure {
    param([string]$Message)
    $script:Failures += $Message
    Write-Host "[FAIL] $Message"
}

function Add-Warning {
    param([string]$Message)
    $script:Warnings += $Message
    Write-Host "[WARN] $Message"
}

function Assert-Exists {
    param([string]$RelativePath)
    $path = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "$RelativePath missing"
        return
    }
    $item = Get-Item -LiteralPath $path
    if ($item.PSIsContainer -eq $false -and $item.Length -le 0) {
        Add-Failure "$RelativePath is empty"
    }
}

function Normalize-PathText {
    param([string]$PathText)
    return (($PathText.TrimEnd("\") -replace "\\", "/").ToLowerInvariant())
}

$script:Failures = @()
$script:Warnings = @()

Push-Location $RepoRoot
try {
    $gitRoot = (& git rev-parse --show-toplevel).Trim()
    $expectedRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    if ((Normalize-PathText $gitRoot) -ne (Normalize-PathText $expectedRoot)) {
        Add-Failure "git root mismatch: $gitRoot"
    }

    Assert-Exists "docs/art/validation/art15/ART15R_TARGET_VISUAL_DESCRIPTION.md"
    Assert-Exists "docs/art/validation/art15/ART15R_VISUAL_LAYER_PROBLEM_REVIEW.md"
    Assert-Exists "docs/art/ART15R_VISUAL_LAYER_AND_LAYOUT_REWORK.md"

    $requiredShots = @(
        "docs/art/validation/art15/art15r_main_menu_1280x720.png",
        "docs/art/validation/art15/art15r_deploy_prep_1280x720.png",
        "docs/art/validation/art15/art15r_long_term_1280x720.png",
        "docs/art/validation/art15/art15r_run_hud_1280x720.png",
        "docs/art/validation/art15/art15r_map_overlay_1280x720.png",
        "docs/art/validation/art15/art15r_inventory_1280x720.png",
        "docs/art/validation/art15/art15r_ground_loot_1280x720.png",
        "docs/art/validation/art15/art15r_deploy_prep_1600x900.png",
        "docs/art/validation/art15/art15r_long_term_1600x900.png",
        "docs/art/validation/art15/art15r_run_hud_1600x900.png",
        "docs/art/validation/art15/art15r_deploy_prep_1920x1080.png",
        "docs/art/validation/art15/art15r_long_term_1920x1080.png",
        "docs/art/validation/art15/art15r_run_hud_1920x1080.png"
    )
    foreach ($shot in $requiredShots) {
        Assert-Exists $shot
    }

    $directSourcePatterns = @("D:\\AGAME1\\Base Art", "D:/AGAME1/Base Art", "D:\\AGAME1\\Draw", "D:/AGAME1/Draw")
    $uiFiles = Get-ChildItem -Path (Join-Path $RepoRoot "Godot/GraytailGodot/scripts/ui"), (Join-Path $RepoRoot "Godot/GraytailGodot/scripts/presentation") -Recurse -File -Include *.gd
    foreach ($file in $uiFiles) {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($pattern in $directSourcePatterns) {
            if ($text.Contains($pattern)) {
                Add-Failure "direct external art path in $($file.FullName)"
            }
        }
    }

    $forbiddenChangedPrefixes = @(
        "Godot/GraytailGodot/scripts/core/run/",
        "Godot/GraytailGodot/scripts/core/command/",
        "Godot/GraytailGodot/scripts/core/save/",
        "D:/AGAME1/Base Art",
        "D:/AGAME1/Draw",
        "D:/AGAME1/Connection"
    )
    $statusLines = & git status --short
    foreach ($line in $statusLines) {
        $normalized = ($line.Substring(3) -replace "\\", "/")
        foreach ($prefix in $forbiddenChangedPrefixes) {
            if ($normalized.StartsWith($prefix)) {
                Add-Warning "forbidden or generated boundary path appears dirty: $normalized"
            }
        }
    }

    $playerRiskPatterns = @(
        "command.rejected",
        "reason code",
        "M3R_minimal",
        "selected_equ",
        "no full dep",
        "projection_type",
        "Dev Debug"
    )
    $runtimeUiFiles = Get-ChildItem -Path (Join-Path $RepoRoot "Godot/GraytailGodot/scripts/ui") -Recurse -File -Include *.gd |
        Where-Object { $_.FullName -notmatch "scripts\\ui\\deploy_prep\\deploy_config.gd" }
    foreach ($file in $runtimeUiFiles) {
        $text = Get-Content -LiteralPath $file.FullName -Raw
        foreach ($pattern in $playerRiskPatterns) {
            if ($text.Contains($pattern)) {
                Add-Warning "possible player-facing internal string '$pattern' in $($file.FullName)"
            }
        }
    }

    $runSurfacePath = Join-Path $RepoRoot "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd"
    $runSurfaceText = Get-Content -LiteralPath $runSurfacePath -Raw
    foreach ($requiredLayerMarker in @("LAYER_ROOM_BACKGROUND", "LAYER_BOTTOM_BAR", "LAYER_OVERLAY", "func _apply_layer_order")) {
        if (-not $runSurfaceText.Contains($requiredLayerMarker)) {
            Add-Failure "run_surface missing explicit layer marker: $requiredLayerMarker"
        }
    }

    $mapOverlayPath = Join-Path $RepoRoot "Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd"
    $mapOverlayText = Get-Content -LiteralPath $mapOverlayPath -Raw
    if ($mapOverlayText.Contains('tooltip_text = String(marker.get("detail_text"')) {
        Add-Failure "MapOverlay marker detail still leaks through native tooltip"
    }

    $miniMapPath = Join-Path $RepoRoot "Godot/GraytailGodot/scripts/ui/minimap/minimap_panel.gd"
    $miniMapText = Get-Content -LiteralPath $miniMapPath -Raw
    if ($miniMapText.Contains('tooltip_text = String(marker.get("tooltip"')) {
        Add-Failure "MiniMap marker tooltip can still cover the room view"
    }

    if ($script:Warnings.Count -gt 0) {
        Write-Host "ART15R validation completed with warnings: $($script:Warnings.Count)"
    }
    if ($script:Failures.Count -gt 0) {
        Write-Host "ART15R validation failed: $($script:Failures.Count)"
        exit 1
    }
    Write-Host "ART15R validation passed"
}
finally {
    Pop-Location
}
