param(
    [string]$RepoRoot = (Resolve-Path ".").Path
)

$ErrorActionPreference = "Stop"

function Add-Result {
    param(
        [string]$Level,
        [string]$Message
    )
    [PSCustomObject]@{
        level = $Level
        message = $Message
    }
}

$results = New-Object System.Collections.Generic.List[object]
$expectedRoot = "D:\AGAME1\_repo_cache\Game1_work"
$resolvedRoot = (Resolve-Path $RepoRoot).Path

if ($resolvedRoot -ne $expectedRoot) {
    $results.Add((Add-Result "ERROR" "repo root mismatch: $resolvedRoot"))
} else {
    $results.Add((Add-Result "OK" "repo root confirmed: $resolvedRoot"))
}

$requiredFiles = @(
    "docs/art/ART14_ART_RESOURCE_LAYERING_AND_MOTION_SPEC.md",
    "docs/art/validation/art14/UI_POSITION_INDEX.md",
    "docs/art/validation/art14/SCREENSHOT_GAP_REVIEW.md",
    "docs/art/validation/art14/SCREEN_LAYER_REQUIREMENTS.md",
    "docs/art/validation/art14/ART_ASSET_NEED_MATRIX.md",
    "docs/art/validation/art14/MOTION_AND_FEEDBACK_REQUIREMENTS.md",
    "docs/art/validation/art14/VISUAL_KEY_AND_ASSET_ID_REQUIREMENTS.md",
    "docs/art/validation/art14/RUNTIME_IMPORT_PRIORITY.md",
    "docs/art/validation/art14/REFERENCE_TO_ASSET_GAP.md"
)

foreach ($relative in $requiredFiles) {
    $path = Join-Path $resolvedRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $results.Add((Add-Result "ERROR" "missing required file: $relative"))
        continue
    }
    $length = (Get-Item -LiteralPath $path).Length
    if ($length -lt 500) {
        $results.Add((Add-Result "ERROR" "required file too small: $relative ($length bytes)"))
    } else {
        $results.Add((Add-Result "OK" "required file exists: $relative ($length bytes)"))
    }
}

$uiIndex = Join-Path $resolvedRoot "docs/art/validation/art14/UI_POSITION_INDEX.md"
if (Test-Path -LiteralPath $uiIndex) {
    $text = Get-Content -LiteralPath $uiIndex -Raw -Encoding UTF8
    for ($i = 1; $i -le 44; $i++) {
        $token = "UI-{0:D2}" -f $i
        if ($text -notmatch [regex]::Escape($token)) {
            $results.Add((Add-Result "ERROR" "UI position token missing: $token"))
        }
    }
    if ($text -match "current_code_surface") {
        $results.Add((Add-Result "OK" "UI index includes current code surface evidence"))
    } else {
        $results.Add((Add-Result "ERROR" "UI index missing current code surface evidence"))
    }
}

$summaryPath = Join-Path $resolvedRoot "docs/art/ART14_ART_RESOURCE_LAYERING_AND_MOTION_SPEC.md"
if (Test-Path -LiteralPath $summaryPath) {
    $summary = Get-Content -LiteralPath $summaryPath -Raw -Encoding UTF8
    foreach ($requiredTerm in @("Godot runtime", "ART-15", "asset_manifest.csv", "visual_key")) {
        if ($summary -notmatch [regex]::Escape($requiredTerm)) {
            $results.Add((Add-Result "ERROR" "summary missing required term: $requiredTerm"))
        }
    }
}

$art14Docs = @()
foreach ($relative in $requiredFiles) {
    $path = Join-Path $resolvedRoot $relative
    if (Test-Path -LiteralPath $path) {
        $art14Docs += Get-Content -LiteralPath $path -Raw -Encoding UTF8
    }
}
$combinedDocs = $art14Docs -join "`n"
foreach ($forbiddenPattern in @("res://D:", "res://.*AGAME1", "res://.*Base%20Art", "res://.*Draw/")) {
    if ($combinedDocs -match $forbiddenPattern) {
        $results.Add((Add-Result "ERROR" "forbidden runtime path language detected: $forbiddenPattern"))
    }
}

$statusLines = git -C $resolvedRoot status --short
$allowedArt14 = @(
    "docs/art/ART14_ART_RESOURCE_LAYERING_AND_MOTION_SPEC.md",
    "docs/art/validation/art14/",
    "tools/validate_art14_art_resource_spec.ps1"
)
$generatedPatterns = @(
    "Godot/GraytailGodot/project.godot",
    ".translation",
    ".gd.uid",
    ".import",
    ".godot"
)

foreach ($line in $statusLines) {
    $path = $line.Substring(3).Trim()
    $isArt14 = $false
    foreach ($prefix in $allowedArt14) {
        if ($path -like "$prefix*") {
            $isArt14 = $true
            break
        }
    }
    $isGenerated = $false
    foreach ($pattern in $generatedPatterns) {
        if ($path -like "*$pattern*") {
            $isGenerated = $true
            break
        }
    }
    $isKnownLegacyScreenshot = ($path -eq "docs/art/validation/art11r2/final_self_check_run_hud_interaction_after_hotfix3.png")
    if ($isArt14 -or $isGenerated -or $isKnownLegacyScreenshot) {
        continue
    }
    $results.Add((Add-Result "ERROR" "unexpected dirty path: $line"))
}

$manifestCsvStatus = $statusLines | Where-Object { $_ -match "Godot/GraytailGodot/data/assets/asset_manifest\.csv$" }
if ($manifestCsvStatus) {
    $results.Add((Add-Result "ERROR" "asset_manifest.csv is dirty"))
} else {
    $results.Add((Add-Result "OK" "asset_manifest.csv not dirty"))
}

$scriptDirty = $statusLines | Where-Object {
    $_ -match "Godot/GraytailGodot/scripts/" -and $_ -notmatch "\.gd\.uid$"
}
if ($scriptDirty) {
    foreach ($line in $scriptDirty) {
        $results.Add((Add-Result "ERROR" "Godot script dirty: $line"))
    }
} else {
    $results.Add((Add-Result "OK" "no Godot script source dirty paths"))
}

$sceneDirty = $statusLines | Where-Object {
    $_ -match "Godot/GraytailGodot/scenes/" -and $_ -notmatch "\.uid$"
}
if ($sceneDirty) {
    foreach ($line in $sceneDirty) {
        $results.Add((Add-Result "ERROR" "Godot scene dirty: $line"))
    }
} else {
    $results.Add((Add-Result "OK" "no Godot scene dirty paths"))
}

$errors = $results | Where-Object { $_.level -eq "ERROR" }
$warnings = $results | Where-Object { $_.level -eq "WARN" }

"ART-14 validation results:"
$results | ForEach-Object { "[{0}] {1}" -f $_.level, $_.message }

if ($errors.Count -gt 0) {
    "ART-14 validation failed with $($errors.Count) error(s)."
    exit 1
}

"ART-14 validation passed with $($warnings.Count) warning(s)."
exit 0
