param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
    Write-Error $Message
    exit 1
}

$requiredFiles = @(
    "docs/art/ART18R_REFERENCE_COMPARISON_AND_REWORK_TARGET.md",
    "docs/art/ART18R_PRODUCT_UI_BASELINE_REWORK.md",
    "docs/art/validation/art18r/art18r_main_menu_1280x720.png",
    "docs/art/validation/art18r/art18r_deploy_prep_1280x720.png",
    "docs/art/validation/art18r/art18r_long_term_1280x720.png",
    "docs/art/validation/art18r/art18r_run_hud_1280x720.png",
    "docs/art/validation/art18r/art18r_map_overlay_1280x720.png"
)

foreach ($relative in $requiredFiles) {
    $path = Join-Path $RepoRoot $relative
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing required ART18R artifact: $relative"
    }
}

$status = git -C $RepoRoot status --short
$forbiddenStatusPatterns = @(
    "^.. Godot/GraytailGodot/scripts/core/command/",
    "^.. Godot/GraytailGodot/scripts/core/save/",
    "^.. Godot/GraytailGodot/data/assets/asset_manifest\.csv"
)

foreach ($line in $status) {
    foreach ($pattern in $forbiddenStatusPatterns) {
        if ($line -match $pattern) {
            Fail "Forbidden dirty path detected: $line"
        }
    }
}

$scanFiles = @(
    "Godot/GraytailGodot/scripts/ui",
    "Godot/GraytailGodot/scripts/presentation"
)

foreach ($relative in $scanFiles) {
    $path = Join-Path $RepoRoot $relative
    if (Test-Path -LiteralPath $path) {
        $files = Get-ChildItem -LiteralPath $path -Recurse -File -Include *.gd
        $hardcoded = $files | Select-String -Pattern "D:\\AGAME1\\Base Art", "D:\\AGAME1\\Draw", "D:\\AGAME1\\sources\\art" -SimpleMatch -ErrorAction SilentlyContinue
        if ($hardcoded) {
            Fail "Runtime hardcoded external art path detected under $relative"
        }
    }
}

$uiFiles = Get-ChildItem -LiteralPath (Join-Path $RepoRoot "Godot/GraytailGodot/scripts/ui") -Recurse -File -Include *.gd
$expandIcon = $uiFiles | Select-String -Pattern "expand_icon\s*=\s*true" -ErrorAction SilentlyContinue
if ($expandIcon) {
    Fail "Button.expand_icon=true risk detected in UI scripts"
}

Write-Host "ART18R validator passed."
