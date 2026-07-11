param()

$ErrorActionPreference = "Stop"

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-ErrorMessage([string]$Message) {
    $script:errors.Add($Message) | Out-Null
}

function Add-WarningMessage([string]$Message) {
    $script:warnings.Add($Message) | Out-Null
}

function Test-PathLike([string]$Path, [string[]]$Prefixes) {
    foreach ($prefix in $Prefixes) {
        if ($Path -like "$prefix*") {
            return $true
        }
    }
    return $false
}

$repoRoot = (git rev-parse --show-toplevel).Trim()
$expectedRoot = "D:/AGAME1/active/Game1_work"
if ($repoRoot -ne $expectedRoot) {
    Add-ErrorMessage "unexpected git root: $repoRoot"
}
Set-Location $repoRoot

Write-Output "ART-13 in-run UI validation"
Write-Output "git root: $repoRoot"

$docPath = "docs/art/ART13_IN_RUN_UI_REWORK_AND_LUA_RESOURCE_ALIGNMENT.md"
if (-not (Test-Path $docPath)) {
    Add-ErrorMessage "missing ART-13 document: $docPath"
}

$requiredScreenshots = @(
    "docs/art/validation/art13/baseline_hud_normal.png",
    "docs/art/validation/art13/baseline_map_overlay.png",
    "docs/art/validation/art13/baseline_inventory.png",
    "docs/art/validation/art13/baseline_ground_loot.png",
    "docs/art/validation/art13/slice1_hud_normal_1280x720_window.png",
    "docs/art/validation/art13/slice2_map_overlay_1280x720_window.png",
    "docs/art/validation/art13/slice4_inventory_1280x720_window.png",
    "docs/art/validation/art13/slice4_ground_loot_1280x720_window.png",
    "docs/art/validation/art13/final_hud_1280x720.png",
    "docs/art/validation/art13/final_search_feedback_1280x720.png",
    "docs/art/validation/art13/final_inventory_1280x720.png",
    "docs/art/validation/art13/final_ground_loot_1280x720.png",
    "docs/art/validation/art13/final_map_overlay_1280x720.png",
    "docs/art/validation/art13/final_hud_1600x900.png",
    "docs/art/validation/art13/final_inventory_or_ground_loot_1600x900.png",
    "docs/art/validation/art13/final_map_overlay_1600x900.png",
    "docs/art/validation/art13/final_hud_1920x1080.png",
    "docs/art/validation/art13/final_map_overlay_1920x1080.png"
)

foreach ($shot in $requiredScreenshots) {
    if (-not (Test-Path $shot)) {
        Add-ErrorMessage "missing screenshot: $shot"
        continue
    }
    $item = Get-Item $shot
    if ($item.Length -lt 1024) {
        Add-ErrorMessage "screenshot is too small: $shot ($($item.Length) bytes)"
    }
}

$statusLines = @(git status --short)
$allowedArt13Prefixes = @(
    "Godot/GraytailGodot/scripts/ui/run_surface/",
    "Godot/GraytailGodot/scripts/ui/hud/",
    "Godot/GraytailGodot/scripts/ui/shell/",
    "Godot/GraytailGodot/scripts/ui/minimap/",
    "Godot/GraytailGodot/scripts/ui/map_overlay/",
    "Godot/GraytailGodot/scripts/ui/inventory/",
    "Godot/GraytailGodot/scripts/ui/ground_loot/",
    "Godot/GraytailGodot/scripts/ui/result/",
    "Godot/GraytailGodot/scripts/presentation/",
    "Godot/GraytailGodot/assets/ui/",
    "Godot/GraytailGodot/assets/rooms/",
    "Godot/GraytailGodot/assets/props/",
    "Godot/GraytailGodot/assets/characters/",
    "Godot/GraytailGodot/assets/items/",
    "Godot/GraytailGodot/data/assets/asset_manifest.csv",
    "tools/validate_art13_",
    "docs/art/ART13_",
    "docs/art/validation/art13/"
)
$forbiddenPrefixes = @(
    "Godot/GraytailGodot/scripts/core/run/",
    "Godot/GraytailGodot/scripts/core/command/",
    "Godot/GraytailGodot/scripts/core/save/",
    "D:/AGAME1/Draw",
    "D:/AGAME1/Base Art",
    "D:/AGAME1/Connection"
)
$generatedPatterns = @(
    "project.godot",
    ".godot/",
    ".import",
    ".uid",
    ".translation"
)

foreach ($line in $statusLines) {
    if ($line.Length -lt 4) {
        continue
    }
    $path = $line.Substring(3).Trim()
    $path = $path -replace "\\", "/"
    if (Test-PathLike $path $forbiddenPrefixes) {
        Add-ErrorMessage "forbidden dirty path: $path"
        continue
    }
    if (Test-PathLike $path $allowedArt13Prefixes) {
        continue
    }
    $isGenerated = $false
    foreach ($pattern in $generatedPatterns) {
        if ($path -like "*$pattern*") {
            $isGenerated = $true
            break
        }
    }
    if ($isGenerated) {
        Add-WarningMessage "generated side effect dirty path: $path"
    } elseif ($path -like "docs/art/validation/art11r2/*") {
        Add-WarningMessage "non-ART13 hotfix artifact present: $path"
    } else {
        Add-WarningMessage "non-ART13 dirty path requires review: $path"
    }
}

$manifestPath = "Godot/GraytailGodot/data/assets/asset_manifest.csv"
if (-not (Test-Path $manifestPath)) {
    Add-ErrorMessage "missing manifest: $manifestPath"
} else {
    try {
        $manifestRows = @(Import-Csv $manifestPath)
        $duplicateIds = $manifestRows |
            Where-Object { $_.asset_id -and $_.asset_id.Trim() -ne "" } |
            Group-Object asset_id |
            Where-Object { $_.Count -gt 1 }
        foreach ($dup in $duplicateIds) {
            Add-ErrorMessage "duplicate asset_id in manifest: $($dup.Name)"
        }

        $manifestDirty = $statusLines | Where-Object { $_ -match "Godot/GraytailGodot/data/assets/asset_manifest\.csv" }
        if ($manifestDirty) {
            foreach ($row in $manifestRows) {
                $godotPath = [string]$row.godot_path
                if ($godotPath.StartsWith("res://")) {
                    $relative = $godotPath.Substring(6).Replace("/", "\")
                    $localPath = Join-Path "Godot/GraytailGodot" $relative
                    if (-not (Test-Path $localPath)) {
                        Add-ErrorMessage "manifest godot_path missing on disk: $godotPath"
                    }
                }
            }
        } else {
            Add-WarningMessage "asset_manifest.csv unchanged; path-existence check limited to parse and duplicate-id validation"
        }
    } catch {
        Add-ErrorMessage "manifest parse failed: $($_.Exception.Message)"
    }
}

$scanRoots = @(
    "Godot/GraytailGodot/scripts/ui/run_surface",
    "Godot/GraytailGodot/scripts/ui/hud",
    "Godot/GraytailGodot/scripts/ui/shell",
    "Godot/GraytailGodot/scripts/ui/minimap",
    "Godot/GraytailGodot/scripts/ui/map_overlay",
    "Godot/GraytailGodot/scripts/ui/inventory",
    "Godot/GraytailGodot/scripts/ui/ground_loot",
    "Godot/GraytailGodot/scripts/ui/result",
    "Godot/GraytailGodot/scripts/presentation"
)
$gdFiles = @()
foreach ($root in $scanRoots) {
    if (Test-Path $root) {
        $gdFiles += Get-ChildItem -Path $root -Recurse -File -Filter "*.gd"
    }
}

if ($gdFiles.Count -gt 0) {
    $hardcodeMatches = Select-String -Path $gdFiles.FullName -Pattern "D:\\AGAME1\\(Base Art|Draw|Connection)|D:/AGAME1/(Base Art|Draw|Connection)|\.uasset" -AllMatches
    foreach ($match in $hardcodeMatches) {
        Add-ErrorMessage "forbidden runtime source reference: $($match.Path):$($match.LineNumber)"
    }

    $expandIconMatches = Select-String -Path $gdFiles.FullName -Pattern "expand_icon\s*=\s*true" -AllMatches
    foreach ($match in $expandIconMatches) {
        Add-ErrorMessage "expand_icon=true risk: $($match.Path):$($match.LineNumber)"
    }

    $blockingCopyPatterns = @(
        "command\.rejected",
        "command\.accepted",
        "message_key",
        "Action complete",
        "Action blocked",
        "Map overlay placeholder"
    )
    foreach ($pattern in $blockingCopyPatterns) {
        $matches = Select-String -Path $gdFiles.FullName -Pattern $pattern -AllMatches
        foreach ($match in $matches) {
            if ($match.Path -like "*scripts\presentation\art10_ui_skin_kit.gd") {
                Add-WarningMessage "sanitizer-token review '$pattern': $($match.Path):$($match.LineNumber)"
            } else {
                Add-ErrorMessage "blocking engineering copy risk '$pattern': $($match.Path):$($match.LineNumber)"
            }
        }
    }

    $warningCopyPatterns = @(
        "display_only",
        "read_only",
        "Rule/Modifier",
        "ContentPool:",
        "RoomPolicy:",
        "SettlementTriggerPreview:"
    )
    foreach ($pattern in $warningCopyPatterns) {
        $matches = Select-String -Path $gdFiles.FullName -Pattern $pattern -AllMatches
        foreach ($match in $matches) {
            Add-WarningMessage "engineering-word review needed '$pattern': $($match.Path):$($match.LineNumber)"
        }
    }
}

Write-Output ""
Write-Output "Status entries: $($statusLines.Count)"
Write-Output "Required screenshots: $($requiredScreenshots.Count)"

if ($warnings.Count -gt 0) {
    Write-Output ""
    Write-Output "Warnings:"
    foreach ($warning in $warnings) {
        Write-Output "- $warning"
    }
}

if ($errors.Count -gt 0) {
    Write-Output ""
    Write-Output "Errors:"
    foreach ($err in $errors) {
        Write-Output "- $err"
    }
    exit 1
}

Write-Output ""
Write-Output "ART-13 validation passed with $($warnings.Count) warning(s)."
