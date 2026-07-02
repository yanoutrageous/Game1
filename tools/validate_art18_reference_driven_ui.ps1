param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) {
    $failures.Add($Message) | Out-Null
}

function Test-RequiredPath([string]$RelativePath) {
    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "Missing required path: $RelativePath"
    }
}

Test-RequiredPath "docs/art/ART18_REFERENCE_DRIVEN_UI_LAYOUT_TARGET.md"
Test-RequiredPath "docs/art/ART18_REFERENCE_DRIVEN_CORE_UI_PRODUCT_LAYOUT.md"

$requiredScreenshots = @(
    "docs/art/validation/art18/baseline_main_menu.png",
    "docs/art/validation/art18/baseline_deploy_prep.png",
    "docs/art/validation/art18/baseline_long_term.png",
    "docs/art/validation/art18/baseline_run_hud.png",
    "docs/art/validation/art18/baseline_map_overlay.png",
    "docs/art/validation/art18/art18_main_menu_1280x720.png",
    "docs/art/validation/art18/art18_deploy_prep_1280x720.png",
    "docs/art/validation/art18/art18_long_term_1280x720.png",
    "docs/art/validation/art18/art18_run_hud_1280x720.png",
    "docs/art/validation/art18/art18_map_overlay_1280x720.png"
)

foreach ($shot in $requiredScreenshots) {
    Test-RequiredPath $shot
}

$status = & git -C $Root status --short
$forbiddenDirtyPatterns = @(
    "^\s*M\s+D:\\AGAME1\\Draw",
    "^\s*M\s+D:\\AGAME1\\sources\\draw",
    "^\s*M\s+D:\\AGAME1\\sources\\art",
    "^\s*M\s+D:\\AGAME1\\handoff\\connection",
    "Godot/GraytailGodot/scripts/core/command/",
    "Godot/GraytailGodot/scripts/core/save/",
    "Godot/GraytailGodot/data/assets/asset_manifest.csv"
)

foreach ($line in $status) {
    foreach ($pattern in $forbiddenDirtyPatterns) {
        if ($line -match $pattern) {
            Add-Failure "Forbidden dirty path detected: $line"
        }
    }
}

$uiTargets = @(
    "Godot/GraytailGodot/scripts/ui",
    "Godot/GraytailGodot/scripts/presentation"
)

$uiFiles = @()
foreach ($target in $uiTargets) {
    $path = Join-Path $Root $target
    if (Test-Path -LiteralPath $path) {
        $uiFiles += Get-ChildItem -LiteralPath $path -Recurse -File -Include *.gd
    }
}

if ($uiFiles.Count -gt 0) {
    $expandIconHits = Select-String -Path ($uiFiles.FullName) -Pattern "expand_icon\s*=\s*true" -ErrorAction SilentlyContinue
    if ($expandIconHits) {
        Add-Failure "Button.expand_icon=true found in UI code."
    }

    $runtimeSourceHardcodeHits = Select-String -Path ($uiFiles.FullName) -Pattern "D:\\AGAME1\\(Base Art|Draw|sources\\art|sources\\draw)" -ErrorAction SilentlyContinue
    if ($runtimeSourceHardcodeHits) {
        Add-Failure "Runtime UI hardcodes external art/source path."
    }

    $playerLeakPattern = '"[^"]*(command\.rejected|message_key)[^"]*"'
    $playerLeakHits = Select-String -Path ($uiFiles.FullName) -Pattern $playerLeakPattern -ErrorAction SilentlyContinue
    if ($playerLeakHits) {
        Add-Failure "Potential player-facing engineering text found in UI strings."
    }
}

if ($failures.Count -gt 0) {
    Write-Host "ART-18 validation failed:"
    foreach ($failure in $failures) {
        Write-Host "- $failure"
    }
    exit 1
}

Write-Host "ART-18 validation passed."
