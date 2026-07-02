param()

$ErrorActionPreference = "Stop"

function Fail($Message) {
    Write-Error $Message
    exit 1
}

$root = (git rev-parse --show-toplevel).Trim()
if (-not $root) {
    Fail "Unable to resolve git root."
}

$requiredFiles = @(
    "docs/art/validation/art21r1/ART21R1_VISUAL_GAP_OBSERVATION.md",
    "docs/art/validation/art21r1/ART21R1_UE_SHARED_ASSET_MATRIX.csv",
    "docs/art/validation/art21r1/ui_placement_contract_v2.csv",
    "docs/art/validation/art21r1/ART21R1_UE_PARITY_COMPARISON.md",
    "docs/art/ART21R1_UE_PARITY_FLOOR_EXISTING_ASSETS.md",
    "docs/art/ART21R1_CLOSEOUT_UE_PARITY_FLOOR.md"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing required ART21R1 file: $file"
    }
}

$requiredScreenshots = @(
    "ue_main_menu.png",
    "ue_area_select.png",
    "ue_difficulty_select.png",
    "ue_run_hud.png",
    "ue_map_overlay.png",
    "godot_main_menu_before.png",
    "godot_run_hud_before.png",
    "godot_main_menu_after.png",
    "godot_deploy_prep_after.png",
    "godot_run_hud_after.png",
    "godot_map_overlay_after.png",
    "godot_inventory_after.png",
    "godot_result_after.png"
)

$screenshotDir = Join-Path $root "docs/art/validation/art21r1/screenshots"
foreach ($name in $requiredScreenshots) {
    $path = Join-Path $screenshotDir $name
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing ART21R1 screenshot: $name"
    }
    if ((Get-Item -LiteralPath $path).Length -le 0) {
        Fail "ART21R1 screenshot is empty: $name"
    }
}

$contractPath = Join-Path $root "docs/art/validation/art21r1/ui_placement_contract_v2.csv"
$contract = Import-Csv -LiteralPath $contractPath
if ($contract.Count -lt 18) {
    Fail "ui_placement_contract_v2.csv has too few rows: $($contract.Count)"
}

$requiredColumns = @(
    "screen",
    "layer_root",
    "slot",
    "node_id",
    "visual_role",
    "text_policy",
    "backplate_policy",
    "target_rect_1280",
    "anchor_rule",
    "z_order",
    "source_reference",
    "runtime_asset",
    "asset_id",
    "visual_key",
    "consumer_script",
    "consumer_function",
    "state_trigger",
    "responsive_rule",
    "validation_screenshot"
)

$actualColumns = @($contract[0].PSObject.Properties.Name)
foreach ($column in $requiredColumns) {
    if ($actualColumns -notcontains $column) {
        Fail "Missing contract column: $column"
    }
}

$allowedTextPolicy = @("direct_on_image", "no_backplate", "badge_only", "modal_body", "hidden")
$allowedBackplatePolicy = @("none", "image_boundary", "structural_panel", "modal_only")

foreach ($row in $contract) {
    if ([string]::IsNullOrWhiteSpace($row.screen) -or [string]::IsNullOrWhiteSpace($row.slot)) {
        Fail "Contract row has empty screen or slot."
    }
    if ($allowedTextPolicy -notcontains $row.text_policy) {
        Fail "Invalid text_policy '$($row.text_policy)' for $($row.screen).$($row.slot)"
    }
    if ($allowedBackplatePolicy -notcontains $row.backplate_policy) {
        Fail "Invalid backplate_policy '$($row.backplate_policy)' for $($row.screen).$($row.slot)"
    }
    if ($row.validation_screenshot) {
        $shot = Join-Path $screenshotDir $row.validation_screenshot
        if (-not (Test-Path -LiteralPath $shot)) {
            Fail "Contract references missing screenshot: $($row.validation_screenshot)"
        }
    }
}

$requiredScreens = @("main_menu", "deploy_prep", "run_hud", "map_overlay", "inventory", "result")
foreach ($screen in $requiredScreens) {
    if (-not ($contract | Where-Object { $_.screen -eq $screen })) {
        Fail "Contract missing screen: $screen"
    }
}

if ($contract | Where-Object { $_.screen -eq "area_select" -or $_.screen -eq "difficulty_select" }) {
    Fail "Contract must not add extra Godot main-menu area/difficulty screens; deploy entry should route directly to Deploy Prep."
}

$runSurfacePath = Join-Path $root "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd"
$runSurface = Get-Content -LiteralPath $runSurfacePath -Raw
if ($runSurface -match 'slot_ref\(&"run_hud",\s*&"gameplay_viewport_background"') {
    Fail "run_surface.gd still binds room background to gameplay_viewport_background."
}

$runtimeScripts = @(
    "Godot/GraytailGodot/scripts/ui",
    "Godot/GraytailGodot/scripts/presentation"
)

foreach ($relative in $runtimeScripts) {
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }
    $matches = Get-ChildItem -LiteralPath $path -Recurse -Filter *.gd |
        Select-String -Pattern 'D:\\A GAME\\26\.6\\UE|D:\\AGAME1\\sources|D:\\AGAME1\\draw' -List
    if ($matches) {
        $first = $matches | Select-Object -First 1
        Fail "Runtime script contains forbidden external source path: $($first.Path)"
    }
}

Write-Output "ART21R1_UE_PARITY_VALIDATION=PASS_STRUCTURAL"
Write-Output "visual_closeout=PARTIAL_ue_parity_floor_partial_blockers_listed"
