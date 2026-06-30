param()

$ErrorActionPreference = "Stop"

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) {
    $script:failures.Add($Message) | Out-Null
}

function Add-Warning([string]$Message) {
    $script:warnings.Add($Message) | Out-Null
}

function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Add-Failure "Missing file: $Path"
        return
    }
    $item = Get-Item -LiteralPath $Path
    if ($item.Length -le 0) {
        Add-Failure "Empty file: $Path"
    }
}

$repoRoot = (git rev-parse --show-toplevel).Trim()
if ($repoRoot -replace "\\", "/" -ne "D:/AGAME1/_repo_cache/Game1_work") {
    Add-Failure "Unexpected git root: $repoRoot"
}

$requiredDocs = @(
    "docs/art/ART15_CORE_ART_ASSET_PRODUCTION_AND_VISUAL_REPLACEMENT.md",
    "docs/art/validation/art15/ART15_ASSET_MATCH_MATRIX.md",
    "docs/art/validation/art15/ART15_EXISTING_RUNTIME_ASSET_REUSE.md",
    "docs/art/validation/art15/ART15_SOURCE_CANDIDATE_DEDUP_REVIEW.md",
    "docs/art/validation/art15/ART15_RUNTIME_IMPORT_REPORT.md",
    "docs/art/validation/art15/ART15_VISUAL_KEY_WIRING_REPORT.md",
    "docs/art/validation/art15/ART15_CORE_SCREEN_REPLACEMENT_REPORT.md",
    "docs/art/validation/art15/ART15_MOTION_FEEDBACK_IMPLEMENTATION_REPORT.md"
)

foreach ($doc in $requiredDocs) {
    Require-File $doc
}

$requiredScreenshots = @(
    "docs/art/validation/art15/art15_main_menu_1280x720.png",
    "docs/art/validation/art15/art15_deploy_prep_1280x720.png",
    "docs/art/validation/art15/art15_long_term_1280x720.png",
    "docs/art/validation/art15/art15_run_hud_1280x720.png",
    "docs/art/validation/art15/art15_map_overlay_1280x720.png",
    "docs/art/validation/art15/art15_inventory_1280x720.png",
    "docs/art/validation/art15/art15_ground_loot_1280x720.png",
    "docs/art/validation/art15/art15_main_menu_1600x900.png",
    "docs/art/validation/art15/art15_deploy_prep_1600x900.png",
    "docs/art/validation/art15/art15_run_hud_1600x900.png",
    "docs/art/validation/art15/art15_map_overlay_1600x900.png",
    "docs/art/validation/art15/art15_main_menu_1920x1080.png",
    "docs/art/validation/art15/art15_deploy_prep_1920x1080.png",
    "docs/art/validation/art15/art15_run_hud_1920x1080.png",
    "docs/art/validation/art15/art15_map_overlay_1920x1080.png"
)

foreach ($screenshot in $requiredScreenshots) {
    Require-File $screenshot
}

$manifestPath = "Godot/GraytailGodot/data/assets/asset_manifest.csv"
Require-File $manifestPath
$manifestRows = Import-Csv -LiteralPath $manifestPath

$allIds = @($manifestRows | ForEach-Object { $_.asset_id })
$duplicateIds = $allIds | Group-Object | Where-Object { $_.Count -gt 1 }
if ($duplicateIds.Count -gt 0) {
    Add-Failure ("Duplicate asset_id values: " + (($duplicateIds | ForEach-Object { $_.Name }) -join ", "))
}

$newAssetIds = @(
    "ui.feedback.bar.dark",
    "ui.feedback.bar.red",
    "ui.feedback.event_prompt",
    "ui.result.title.extract_confirm",
    "ui.result.title.extraction_success",
    "ui.result.title.signal_lost"
)

foreach ($assetId in $newAssetIds) {
    $matches = @($manifestRows | Where-Object { $_.asset_id -eq $assetId })
    if ($matches.Count -ne 1) {
        Add-Failure "Expected exactly one manifest row for $assetId, got $($matches.Count)"
        continue
    }
    $row = $matches[0]
    if ($row.source_status -ne "staged_pending_review") {
        Add-Failure "Unexpected source_status for ${assetId}: $($row.source_status)"
    }
    if ($row.license_status -ne "internal_staged") {
        Add-Failure "Unexpected license_status for ${assetId}: $($row.license_status)"
    }
    if ($row.godot_path -notlike "res://*") {
        Add-Failure "Non-res godot_path for ${assetId}: $($row.godot_path)"
        continue
    }
    $localPath = $row.godot_path -replace "^res://", "Godot/GraytailGodot/"
    if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
        Add-Failure "Missing runtime asset for ${assetId}: $localPath"
    }
}

$scriptFiles = Get-ChildItem -LiteralPath "Godot/GraytailGodot/scripts" -Recurse -File -Filter "*.gd"
$hardcodeMatches = @($scriptFiles | Select-String -Pattern "D:\\AGAME1|D:/AGAME1|Base Art|Draw\\|Draw/|A GAME")
if ($hardcodeMatches.Count -gt 0) {
    Add-Failure "Found external runtime hardcode in scripts."
    foreach ($match in $hardcodeMatches | Select-Object -First 20) {
        Add-Failure ("  {0}:{1}: {2}" -f $match.Path, $match.LineNumber, $match.Line.Trim())
    }
}

$coreDiff = @(git diff --name-only -- `
    "Godot/GraytailGodot/scripts/core/run" `
    "Godot/GraytailGodot/scripts/core/command" `
    "Godot/GraytailGodot/scripts/core/save")
if ($coreDiff.Count -gt 0) {
    Add-Failure ("Tracked core/run-command-save diff exists: " + ($coreDiff -join ", "))
}

$statusLines = @(git status --short)
$generatedSideEffects = @($statusLines | Where-Object {
    $_ -match "\.translation$" -or
    $_ -match "\.gd\.uid$" -or
    $_ -match "\.import$" -or
    $_ -match "\.godot" -or
    $_ -match "project\.godot"
})
if ($generatedSideEffects.Count -gt 0) {
    Add-Warning ("Generated side effects present: " + $generatedSideEffects.Count)
}

if ($warnings.Count -gt 0) {
    Write-Host "WARNINGS:"
    foreach ($warning in $warnings) {
        Write-Host " - $warning"
    }
}

if ($failures.Count -gt 0) {
    Write-Host "FAILURES:"
    foreach ($failure in $failures) {
        Write-Host " - $failure"
    }
    exit 1
}

Write-Host "ART-15 validation passed."
exit 0
