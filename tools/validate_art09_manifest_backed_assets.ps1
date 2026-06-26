$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$manifestPath = Join-Path $repoRoot "Godot\GraytailGodot\data\assets\asset_manifest.csv"
$godotRoot = Join-Path $repoRoot "Godot\GraytailGodot"

$requiredAssetIds = @(
    "ui.key_prompt.e",
    "ui.key_prompt.esc",
    "ui.key_prompt.f",
    "ui.key_prompt.m",
    "ui.key_prompt.q",
    "ui.key_prompt.t",
    "ui.deploy.button.back_main",
    "ui.deploy.button.confirm_deploy_large",
    "ui.deploy.button.nav_loadout",
    "ui.deploy.button.nav_recovery",
    "ui.deploy.button.nav_requisition",
    "ui.deploy.button.nav_talent_selected",
    "ui.deploy.button.nav_warehouse",
    "ui.deploy.button.key_or_arrow_small_button",
    "ui.deploy.icon.armor",
    "ui.deploy.icon.backpack",
    "ui.deploy.icon.bandage",
    "ui.deploy.icon.compass",
    "ui.deploy.panel.frame_highlight",
    "ui.deploy.panel.deploy_main_blank",
    "ui.deploy.panel.deploy_summary_blank",
    "item.consumable.medkit",
    "item.consumable.syringe",
    "item.equipment.flashlight",
    "item.equipment.goggles",
    "item.recovered.ore",
    "ui.main_menu.background.no_text"
)

$fallbackAssetIds = @(
    "icon.minimap.explored",
    "ui.common.button.dark",
    "ui.hud.panel.protocol",
    "room.background.normal"
)

$failures = New-Object System.Collections.Generic.List[string]

if (!(Test-Path -LiteralPath $manifestPath)) {
    throw "Missing asset manifest: $manifestPath"
}

$records = @(Import-Csv -LiteralPath $manifestPath)
$duplicateIds = @($records | Group-Object asset_id | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
if ($duplicateIds.Count -gt 0) {
    $failures.Add("duplicate asset_id values: $($duplicateIds -join ', ')")
}

$recordById = @{}
foreach ($record in $records) {
    if ($record.asset_id -and !$recordById.ContainsKey($record.asset_id)) {
        $recordById[$record.asset_id] = $record
    }
}

foreach ($assetId in ($requiredAssetIds + $fallbackAssetIds)) {
    if (!$recordById.ContainsKey($assetId)) {
        $failures.Add("missing required asset_id: $assetId")
        continue
    }
    $godotPath = [string]$recordById[$assetId].godot_path
    if (!$godotPath.StartsWith("res://assets/")) {
        $failures.Add("asset_id has non-assets godot_path: $assetId -> $godotPath")
        continue
    }
    $relative = $godotPath.Substring("res://".Length).Replace("/", "\")
    $absolute = Join-Path $godotRoot $relative
    if (!(Test-Path -LiteralPath $absolute)) {
        $failures.Add("asset_id points to missing file: $assetId -> $godotPath")
    }
}

$forbiddenWiring = @($requiredAssetIds | Where-Object {
    $_ -like "prop.art07.*" -or
    $_ -like "map_icon*" -or
    $_ -like "map_tile*" -or
    $_ -like "*sprite*" -or
    $_ -like "*visual_target*"
})
if ($forbiddenWiring.Count -gt 0) {
    $failures.Add("forbidden category entered ART09 wiring list: $($forbiddenWiring -join ', ')")
}

$sourceFiles = @(
    "Godot\GraytailGodot\scripts\presentation\art09_manifest_asset_mapping.gd",
    "Godot\GraytailGodot\scripts\presentation\presentation_mapping.gd",
    "Godot\GraytailGodot\scripts\ui\main_menu\main_menu_model.gd",
    "Godot\GraytailGodot\scripts\ui\main_menu\main_menu_shell.gd",
    "Godot\GraytailGodot\scripts\ui\deploy_prep\deploy_config.gd",
    "Godot\GraytailGodot\scripts\ui\deploy_prep\deploy_prep_model.gd",
    "Godot\GraytailGodot\scripts\ui\deploy_prep\deploy_prep_shell.gd",
    "Godot\GraytailGodot\scripts\ui\deploy_prep\deploy_tab_model.gd",
    "Godot\GraytailGodot\scripts\ui\inventory\inventory_panel.gd"
)
foreach ($sourceFile in $sourceFiles) {
    $path = Join-Path $repoRoot $sourceFile
    if (!(Test-Path -LiteralPath $path)) {
        $failures.Add("missing ART09 source file for validation: $sourceFile")
        continue
    }
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -match "res://assets/") {
        $failures.Add("hardcoded res://assets path found in ART09 source file: $sourceFile")
    }
}

if ($failures.Count -gt 0) {
    Write-Host "ART09 manifest-backed asset validation failed"
    foreach ($failure in $failures) {
        Write-Host "- $failure"
    }
    exit 1
}

Write-Host "ART09 manifest-backed asset validation passed"
Write-Host "required_asset_ids=$($requiredAssetIds.Count)"
Write-Host "fallback_asset_ids=$($fallbackAssetIds.Count)"
