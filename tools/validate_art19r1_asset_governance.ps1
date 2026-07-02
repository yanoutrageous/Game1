param(
    [switch]$VerboseOutput
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$infos = New-Object System.Collections.Generic.List[string]

function Add-Failure {
    param([string]$Message)
    [void]$failures.Add($Message)
}

function Add-Warning {
    param([string]$Message)
    [void]$warnings.Add($Message)
}

function Add-Info {
    param([string]$Message)
    [void]$infos.Add($Message)
}

function Normalize-RepoPath {
    param([string]$Path)
    return ($Path -replace "\\", "/").Trim()
}

function Test-RepoFile {
    param([string]$RelativePath)
    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure "Missing required file: $RelativePath"
    }
}

function Test-RepoDir {
    param([string]$RelativePath)
    $fullPath = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
        Add-Failure "Missing required directory: $RelativePath"
    }
}

function Read-Utf8Strict {
    param([string]$RelativePath)
    $fullPath = Join-Path $RepoRoot $RelativePath
    try {
        $bytes = [System.IO.File]::ReadAllBytes($fullPath)
        $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
        return $utf8.GetString($bytes)
    } catch {
        Add-Failure "File is not strict UTF-8 readable: $RelativePath ($($_.Exception.Message))"
        return ""
    }
}

function Test-TextClean {
    param([string]$RelativePath)
    $text = Read-Utf8Strict $RelativePath
    if ($text -eq "") {
        return
    }
    if ($text -match "\?{3,}") {
        Add-Failure "Potential question-mark mojibake found in: $RelativePath"
    }
    if ($text -match [char]0xfffd) {
        Add-Failure "Replacement character found in: $RelativePath"
    }
}

function Test-AllowedOrKnownDirtyPath {
    param([string]$Path)
    $p = Normalize-RepoPath $Path

    $allowedArt19R1Exact = @(
        "docs/art/ART19R1_UI_ASSET_GOVERNANCE_AND_CUTTING_PREP.md",
        "tools/validate_art19r1_asset_governance.ps1"
    )
    $allowedArt19R1Prefixes = @(
        "docs/art/validation/art19r1/"
    )

    if ($allowedArt19R1Exact -contains $p) {
        return "art19r1"
    }
    foreach ($prefix in $allowedArt19R1Prefixes) {
        if ($p.StartsWith($prefix)) {
            return "art19r1"
        }
    }

    $knownExact = @(
        "Godot/GraytailGodot/data/assets/asset_manifest.csv",
        "Godot/GraytailGodot/project.godot",
        "Godot/GraytailGodot/scripts/presentation/art09_manifest_asset_mapping.gd",
        "Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd",
        "Godot/GraytailGodot/scripts/presentation/presentation_mapping.gd",
        "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd",
        "Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd",
        "Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd",
        "Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd",
        "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd",
        "Godot/GraytailGodot/scripts/ui/shell/ui_layer_contract.gd",
        "docs/INDEX.md",
        "docs/README.md",
        "docs/00_governance/DOC_GOV_003_STAGE_PROCESS_MINIMAL.md",
        "docs/art/ART18R_PRODUCT_UI_BASELINE_REWORK.md",
        "docs/art/ART18R_REFERENCE_COMPARISON_AND_REWORK_TARGET.md",
        "docs/art/ART18_REFERENCE_DRIVEN_CORE_UI_PRODUCT_LAYOUT.md",
        "docs/art/ART18_REFERENCE_DRIVEN_UI_LAYOUT_TARGET.md",
        "docs/art/ART19_REAL_UI_ART_KIT_AND_CORE_SCREEN_REPLACEMENT.md",
        "tools/validate_art18_reference_driven_ui.ps1",
        "tools/validate_art18r_product_ui.ps1",
        "tools/validate_art19_real_ui_assets.ps1"
    )
    if ($knownExact -contains $p) {
        return "pre_existing"
    }

    $knownPrefixes = @(
        "Godot/GraytailGodot/assets/ui/art19/",
        "docs/art/validation/art18/",
        "docs/art/validation/art18r/",
        "docs/art/validation/art19/"
    )
    foreach ($prefix in $knownPrefixes) {
        if ($p.StartsWith($prefix)) {
            return "pre_existing"
        }
    }

    return "unknown"
}

function Test-NoForbiddenDirty {
    $statusLines = git status --porcelain
    foreach ($line in $statusLines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $path = $line.Substring(3)
        if ($path -match " -> ") {
            $path = ($path -split " -> ")[-1]
        }
        $path = Normalize-RepoPath $path

        if ($path.StartsWith("Godot/GraytailGodot/scripts/core/run/") -or
            $path.StartsWith("Godot/GraytailGodot/scripts/core/command/") -or
            $path.StartsWith("Godot/GraytailGodot/scripts/core/save/")) {
            Add-Failure "Forbidden core path is dirty: $path"
            continue
        }

        $classification = Test-AllowedOrKnownDirtyPath $path
        if ($classification -eq "pre_existing") {
            Add-Warning "Pre-existing dirty path observed, not ART19R1 output: $path"
        } elseif ($classification -eq "art19r1") {
            Add-Info "ART19R1 output path observed: $path"
        } else {
            Add-Failure "Unexpected dirty path outside ART19R1 outputs and known pre-existing dirty set: $path"
        }
    }
}

function Test-KeycapExample {
    $csvPath = Join-Path $RepoRoot "docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD_EXAMPLES.csv"
    $rows = Import-Csv -LiteralPath $csvPath
    $row = $rows | Where-Object { $_.file_name -eq "ui_shared_keycap_e_normal.png" } | Select-Object -First 1
    if ($null -eq $row) {
        Add-Failure "Missing keycap example row: ui_shared_keycap_e_normal.png"
        return
    }
    if ($row.asset_id -ne "ui.shared.keycap.e.normal") {
        Add-Failure "Keycap asset_id is incorrect: $($row.asset_id)"
    }
    if ($row.visual_key -ne "shared.keycap.e.normal") {
        Add-Failure "Keycap visual_key is incorrect: $($row.visual_key)"
    }
}

function Test-NextImportPlan {
    $csvRel = "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv"
    $csvPath = Join-Path $RepoRoot $csvRel
    $rows = Import-Csv -LiteralPath $csvPath
    if (($rows | Measure-Object).Count -lt 1) {
        Add-Failure "Next import plan is empty: $csvRel"
        return
    }

    $validStatuses = @(
        "confirmed_existing",
        "confirmed_existing_set",
        "needs_source_selection",
        "needs_visual_fit_review",
        "reserved_or_defer"
    )

    foreach ($row in $rows) {
        if ($validStatuses -notcontains $row.source_status) {
            Add-Failure "Invalid source_status for item '$($row.item)': $($row.source_status)"
        }
        if (($row.source_status -eq "needs_source_selection" -or $row.source_status -eq "needs_visual_fit_review") -and
            ($row.action -match "direct_import|import_now|ready_to_import")) {
            Add-Failure "Unresolved source item is marked as direct import: $($row.item)"
        }
    }

    $statusCounts = $rows | Group-Object source_status
    foreach ($group in $statusCounts) {
        Add-Info "source_status $($group.Name): $($group.Count)"
    }
}

function Test-NoFuzzySourcePhrases {
    $targets = @(
        "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.md",
        "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv",
        "docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD.md",
        "docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD_EXAMPLES.csv"
    )
    foreach ($target in $targets) {
        $text = Read-Utf8Strict $target
        if ($text -match "or new source|or shared primary") {
            Add-Failure "Fuzzy source candidate phrase found in: $target"
        }
    }
}

$requiredFiles = @(
    "docs/art/ART19R1_UI_ASSET_GOVERNANCE_AND_CUTTING_PREP.md",
    "docs/art/validation/art19r1/UI_SOURCE_ASSET_INVENTORY.md",
    "docs/art/validation/art19r1/UI_ASSET_SEMANTIC_CLASSIFICATION.md",
    "docs/art/validation/art19r1/UI_ASSET_SEMANTIC_CLASSIFICATION.csv",
    "docs/art/validation/art19r1/ART19_IMPORTED_ASSET_REVIEW.md",
    "docs/art/validation/art19r1/ART19_IMPORTED_ASSET_REVIEW.csv",
    "docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.md",
    "docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.csv",
    "docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD.md",
    "docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD_EXAMPLES.csv",
    "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.md",
    "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv",
    "docs/art/validation/art19r1/_slice1_summary.json",
    "docs/art/validation/art19r1/_slice2_semantic_counts.csv",
    "docs/art/validation/art19r1/_slice3_imported_asset_review_counts.csv",
    "docs/art/validation/art19r1/_slice4_component_spec_counts.csv",
    "docs/art/validation/art19r1/_slice5_next_import_plan_counts.csv",
    "tools/validate_art19r1_asset_governance.ps1"
)

$requiredDirs = @(
    "docs/art/validation/art19r1"
)

foreach ($dir in $requiredDirs) {
    Test-RepoDir $dir
}

foreach ($file in $requiredFiles) {
    Test-RepoFile $file
}

$textFilesToScan = @(
    "docs/art/ART19R1_UI_ASSET_GOVERNANCE_AND_CUTTING_PREP.md",
    "docs/art/validation/art19r1/UI_SOURCE_ASSET_INVENTORY.md",
    "docs/art/validation/art19r1/UI_ASSET_SEMANTIC_CLASSIFICATION.md",
    "docs/art/validation/art19r1/ART19_IMPORTED_ASSET_REVIEW.md",
    "docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.md",
    "docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD.md",
    "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.md",
    "docs/art/validation/art19r1/ART19_IMPORTED_ASSET_REVIEW.csv",
    "docs/art/validation/art19r1/UI_COMPONENT_CUTTING_SPEC.csv",
    "docs/art/validation/art19r1/UI_ASSET_NAMING_STANDARD_EXAMPLES.csv",
    "docs/art/validation/art19r1/NEXT_RUNTIME_IMPORT_BATCH_PLAN.csv"
)

foreach ($file in $textFilesToScan) {
    if (Test-Path -LiteralPath (Join-Path $RepoRoot $file) -PathType Leaf) {
        Test-TextClean $file
    }
}

Test-NoFuzzySourcePhrases
Test-KeycapExample
Test-NextImportPlan
Test-NoForbiddenDirty

$externalSourceRoots = @(
    "D:\AGAME1\sources\art",
    "D:\AGAME1\sources\draw"
)
foreach ($sourceRoot in $externalSourceRoots) {
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        Add-Failure "External source root missing: $sourceRoot"
    } else {
        Add-Info "External source root exists and was not written by this validator: $sourceRoot"
    }
}

Write-Host "ART19R1 asset governance validation"
Write-Host "RepoRoot: $RepoRoot"

if ($infos.Count -gt 0 -and $VerboseOutput) {
    Write-Host ""
    Write-Host "Info:"
    foreach ($item in $infos) {
        Write-Host "  - $item"
    }
}

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    foreach ($item in $warnings) {
        Write-Host "  - $item"
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Failures:"
    foreach ($item in $failures) {
        Write-Host "  - $item"
    }
    exit 1
}

Write-Host ""
Write-Host "Validation passed."
exit 0
