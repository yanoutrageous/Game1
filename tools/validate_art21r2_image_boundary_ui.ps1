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

$validationRoot = Join-Path $root "docs/art/validation/art21r2"
$requiredFiles = @(
    "docs/art/validation/art21r2/ART21R2_TARGET_VISUAL_LOCK.md",
    "docs/art/validation/art21r2/ART21R2_SLOT_GAP_MATRIX.csv",
    "docs/art/validation/art21r2/ui_placement_contract_v3.csv",
    "docs/art/validation/art21r2/ART21R2_SLICE2_MAIN_MENU_PHYSICAL_BOARD_REPORT.md",
    "docs/art/validation/art21r2/ART21R2_SLICE3_RUN_INPUT_AND_LAYER_REPORT.md",
    "docs/art/validation/art21r2/ART21R2_DRAW_SLICE_AUDIT.md"
)

foreach ($file in $requiredFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "Missing required ART21R2 file: $file"
    }
}

$requiredScreenshots = @(
    "screenshots/baseline/godot_main_menu_baseline.png",
    "screenshots/baseline/godot_deploy_prep_baseline.png",
    "screenshots/baseline/godot_long_term_baseline.png",
    "screenshots/baseline/godot_run_hud_baseline.png",
    "screenshots/baseline/godot_map_overlay_baseline.png",
    "screenshots/baseline/godot_inventory_button_baseline.png",
    "screenshots/baseline/godot_result_baseline.png",
    "screenshots/baseline/ue_main_menu_reference.png",
    "screenshots/baseline/ue_run_hud_reference.png",
    "screenshots/baseline/ue_map_overlay_reference.png",
    "screenshots/slice2/godot_main_menu_after_slice2_logic.png",
    "screenshots/slice2/godot_deploy_prep_from_main_click_slice2_logic.png",
    "screenshots/slice2/godot_run_hud_extra_layers_blocker_slice2_logic.png",
    "screenshots/slice3/godot_deploy_prep_after_slice3.png",
    "screenshots/slice3/godot_main_menu_after_slice3_logic.png",
    "screenshots/slice3/godot_deploy_prep_after_slice3_logic.png",
    "screenshots/slice3/godot_long_term_after_slice3_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_logic.png",
    "screenshots/slice3/godot_inventory_q_after_slice3_logic.png",
    "screenshots/slice3/godot_map_overlay_after_slice3_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_image_boundary_pass4_logic.png",
    "screenshots/slice3/godot_inventory_q_guard_after_slice3_pass4_logic.png",
    "screenshots/slice3/godot_map_overlay_guard_after_slice3_pass4_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_minimap_fallback_pass5_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_art21r2_asset_pass6_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_art21r2_asset_pass7_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_minimap_public_grid_pass10_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_minimap_draw_overlay_pass14_logic.png"
)

foreach ($screenshot in $requiredScreenshots) {
    $path = Join-Path $validationRoot $screenshot
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "Missing ART21R2 screenshot: $screenshot"
    }
    if ((Get-Item -LiteralPath $path).Length -le 0) {
        Fail "ART21R2 screenshot is empty: $screenshot"
    }
}

$contractPath = Join-Path $validationRoot "ui_placement_contract_v3.csv"
$contract = @(Import-Csv -LiteralPath $contractPath)
if ($contract.Count -lt 28) {
    Fail "ui_placement_contract_v3.csv has too few rows: $($contract.Count)"
}

$requiredColumns = @(
    "screen",
    "layer",
    "slot",
    "node_id",
    "visual_role",
    "visual_authority",
    "forbid_generated_backplate",
    "text_surface",
    "button_surface",
    "state_art",
    "runtime_asset",
    "asset_id",
    "visual_key",
    "consumer_script",
    "consumer_function",
    "reference_target",
    "acceptance_screenshot",
    "status",
    "remaining_gap"
)

$actualColumns = @($contract[0].PSObject.Properties.Name)
foreach ($column in $requiredColumns) {
    if ($actualColumns -notcontains $column) {
        Fail "Missing ART21R2 contract column: $column"
    }
}

$allowedAuthorities = @("image", "code_scrim_exception")
$allowedStatuses = @(
    "baseline_fail",
    "r1_partial",
    "pass_existing_guard",
    "modal_exception",
    "evidence_pending",
    "planned",
    "r2_partial",
    "r2_pass"
)

foreach ($row in $contract) {
    if ([string]::IsNullOrWhiteSpace($row.screen) -or [string]::IsNullOrWhiteSpace($row.slot)) {
        Fail "Contract row has empty screen or slot."
    }
    if ($allowedAuthorities -notcontains $row.visual_authority) {
        Fail "Invalid visual_authority '$($row.visual_authority)' for $($row.screen).$($row.slot)"
    }
    if ($row.visual_authority -eq "code_scrim_exception" -and $row.slot -ne "modal_dimmer") {
        Fail "Only modal_dimmer may use code_scrim_exception: $($row.screen).$($row.slot)"
    }
    if ($row.forbid_generated_backplate -ne "true") {
        Fail "forbid_generated_backplate must be true for $($row.screen).$($row.slot)"
    }
    if ($row.visual_role -match "structural_panel|code_generated_panel") {
        Fail "P0 contract row still uses vague/generated visual_role: $($row.screen).$($row.slot)"
    }
    if ($allowedStatuses -notcontains $row.status) {
        Fail "Invalid status '$($row.status)' for $($row.screen).$($row.slot)"
    }
    if ([string]::IsNullOrWhiteSpace($row.reference_target)) {
        Fail "Missing reference_target for $($row.screen).$($row.slot)"
    }
    if ($row.acceptance_screenshot) {
        $shot = Join-Path $validationRoot $row.acceptance_screenshot
        if (-not (Test-Path -LiteralPath $shot -PathType Leaf)) {
            Fail "Contract references missing screenshot: $($row.acceptance_screenshot)"
        }
    }
}

$requiredScreens = @("main_menu", "deploy_prep", "long_term", "run_hud", "map_overlay", "inventory", "ground_loot", "result")
foreach ($screen in $requiredScreens) {
    if (-not ($contract | Where-Object { $_.screen -eq $screen })) {
        Fail "Contract missing screen: $screen"
    }
}

if ($contract | Where-Object { $_.screen -eq "area_select" -or $_.screen -eq "difficulty_select" }) {
    Fail "ART21R2 must not add area_select or difficulty_select screens to the Godot main-menu route."
}

$requiredSlots = @(
    "main_menu.action_deck_frame",
    "main_menu.deploy_entry",
    "deploy_prep.left_character_frame",
    "deploy_prep.center_route_wall",
    "deploy_prep.right_summary_panel",
    "long_term.left_profile_frame",
    "long_term.collection_wall",
    "long_term.right_detail_panel",
    "run_hud.room_world",
    "run_hud.left_info_rail",
    "run_hud.protocol_card",
    "run_hud.bottom_overlay",
    "run_hud.keyboard_q_inventory",
    "map_overlay.map_panel",
    "map_overlay.map_cell_unknown",
    "map_overlay.map_marker_event",
    "inventory.inventory_panel_frame",
    "ground_loot.ground_loot_panel_frame",
    "result.result_modal_frame"
)

foreach ($slotKey in $requiredSlots) {
    $parts = $slotKey.Split(".")
    $screen = $parts[0]
    $slot = $parts[1]
    if (-not ($contract | Where-Object { $_.screen -eq $screen -and $_.slot -eq $slot })) {
        Fail "Missing required ART21R2 P0 slot: $slotKey"
    }
}

$gapPath = Join-Path $validationRoot "ART21R2_SLOT_GAP_MATRIX.csv"
$gaps = @(Import-Csv -LiteralPath $gapPath)
if ($gaps.Count -lt 16) {
    Fail "ART21R2 gap matrix has too few rows: $($gaps.Count)"
}
if (-not ($gaps | Where-Object { $_.status -eq "baseline_fail" })) {
    Fail "Gap matrix must preserve baseline_fail rows; ART21R2 is not visually complete at baseline."
}

$targetLock = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_TARGET_VISUAL_LOCK.md") -Raw
if ($targetLock -notmatch "NOT_COMPLETE_BASELINE") {
    Fail "Target visual lock must state NOT_COMPLETE_BASELINE before closeout."
}
if ($targetLock -notmatch "directly to Deploy Prep") {
    Fail "Target visual lock must preserve direct Start Exploration -> Deploy Prep routing."
}

$drawSliceAudit = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_DRAW_SLICE_AUDIT.md") -Raw
$requiredDrawAuditPatterns = @(
    "Existing Slice Process To Reuse",
    "tools/art20_cut_ui_assets.py",
    "magenta-background root sheets",
    "map_overlay_event_marker_64",
    "candidate crop with purple remnants is not runtime-ready evidence"
)
foreach ($pattern in $requiredDrawAuditPatterns) {
    if ($drawSliceAudit -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 draw slice audit missing required process evidence: $pattern"
    }
}

$mainMenuPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/main_menu/main_menu_shell.gd"
$mainMenu = Get-Content -LiteralPath $mainMenuPath -Raw
if ($mainMenu -match "area_select|difficulty_select") {
    Fail "main_menu_shell.gd contains an unexpected area/difficulty selection route."
}
if ($mainMenu -notmatch '_build_physical_menu_panel\(\)\s*\r?\n\s*return') {
    Fail "main_menu_shell.gd active menu path must use the physical board before the legacy terminal deck."
}
if ($mainMenu -notmatch 'MainMenuPhysicalEntry_%s') {
    Fail "main_menu_shell.gd must name physical menu entries for route/screenshot evidence."
}
if ($mainMenu -notmatch 'apply_transparent_button_token') {
    Fail "main_menu_shell.gd should use transparent hitboxes on the physical board."
}
if ($mainMenu -notmatch 'button\.pressed\.connect\(func\(\) -> void: _emit_entry\(entry\)\)') {
    Fail "main_menu_shell.gd must preserve entry pressed -> _emit_entry route logic."
}

$runSurfacePath = Join-Path $root "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd"
$runSurface = Get-Content -LiteralPath $runSurfacePath -Raw
if ($runSurface -match 'slot_ref\(&"run_hud",\s*&"gameplay_viewport_background"') {
    Fail "run_surface.gd must not restore the duplicate gameplay_viewport_background fake room layer."
}

$runSurfaceGuards = @(
    'center_backdrop\.visible\s*=\s*false',
    'room_background_layer\.visible\s*=\s*false',
    'player_sprite_layer\.visible\s*=\s*false',
    'room_glow_layer\.visible\s*=\s*false',
    'left_backdrop\.visible\s*=\s*false',
    'right_backdrop\.visible\s*=\s*false',
    'bottom_backdrop\.visible\s*=\s*false',
    'encounter_backdrop\.visible\s*=\s*false'
)

foreach ($guard in $runSurfaceGuards) {
    if ($runSurface -notmatch $guard) {
        Fail "run_surface.gd is missing duplicate-world-layer guard: $guard"
    }
}

$routerPath = Join-Path $root "Godot/GraytailGodot/scripts/core/run/run_scene_input_router.gd"
$router = Get-Content -LiteralPath $routerPath -Raw
$requiredRouterPatterns = @(
    'ACTION_OPEN_INVENTORY',
    'ACTION_OPEN_GROUND_LOOT',
    'ACTION_REQUEST_EXTRACT',
    'KEY_Q',
    'KEY_G',
    'KEY_T'
)
foreach ($pattern in $requiredRouterPatterns) {
    if ($router -notmatch $pattern) {
        Fail "run_scene_input_router.gd missing run input route: $pattern"
    }
}

$runScenePath = Join-Path $root "Godot/GraytailGodot/scripts/core/run/run_scene.gd"
$runScene = Get-Content -LiteralPath $runScenePath -Raw
$requiredRunScenePatterns = @(
    'ACTION_OPEN_INVENTORY',
    '_show_inventory_panel\(\)',
    'ACTION_OPEN_GROUND_LOOT',
    '_show_ground_loot_panel\(\)',
    'ACTION_REQUEST_EXTRACT',
    '_request_extract_from_ui\(\)'
)
foreach ($pattern in $requiredRunScenePatterns) {
    if ($runScene -notmatch $pattern) {
        Fail "run_scene.gd missing run action handler: $pattern"
    }
}

if ($runSurface -notmatch 'apply_transparent_button') {
    Fail "run_surface.gd should use transparent image-backed action hitboxes."
}
if ($runSurface -notmatch 'Art21RunLeftInfoRail') {
    Fail "run_surface.gd should provide an image-backed left information rail."
}
if ($runSurface -notmatch '_add_nine_patch_from_ref') {
    Fail "run_surface.gd should use image-backed NinePatch frames for HUD regions."
}
if ($runSurface -notmatch 'button\.icon\s*=\s*null') {
    Fail "run_surface.gd should not restore noisy bottom action button icons in the R2 HUD pass."
}
if ($runSurface -notmatch 'encounter_backdrop\.visible\s*=\s*false') {
    Fail "run_surface.gd should not restore the extra floating encounter backplate."
}
if ($runSurface -notmatch 'slot_ref\(&"run_hud",\s*&"left_info_rail"') {
    Fail "run_surface.gd should resolve the left information rail through the ART21R2 slot contract."
}

$placementPath = Join-Path $root "Godot/GraytailGodot/scripts/presentation/art21_ui_placement_contract.gd"
$placement = Get-Content -LiteralPath $placementPath -Raw
$requiredPlacementPatterns = @(
    'ui\.art21r2\.run\.left_info_rail\.frame',
    'ui\.art21r2\.run\.status_card\.frame',
    'ui\.art21r2\.run\.bottom_overlay\.frame',
    'run_hud\.left_info_rail'
)
foreach ($pattern in $requiredPlacementPatterns) {
    if ($placement -notmatch $pattern) {
        Fail "art21_ui_placement_contract.gd missing ART21R2 run HUD mapping: $pattern"
    }
}

$manifestPath = Join-Path $root "Godot/GraytailGodot/data/assets/asset_manifest.csv"
$manifest = Get-Content -LiteralPath $manifestPath -Raw
$requiredManifestIds = @(
    'ui.art21r2.run.left_info_rail.frame',
    'ui.art21r2.run.status_card.frame',
    'ui.art21r2.run.bottom_overlay.frame',
    'ui.art19.map64.player',
    'ui.art19.map64.explored',
    'ui.art19.map64.scanned'
)
foreach ($assetId in $requiredManifestIds) {
    if ($manifest -notmatch [regex]::Escape($assetId)) {
        Fail "asset_manifest.csv missing ART21R2 run HUD asset id: $assetId"
    }
}

$mapOverlayPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd"
$mapOverlay = Get-Content -LiteralPath $mapOverlayPath -Raw
if ($mapOverlay -notmatch 'transparent_style_box') {
    Fail "map_overlay_panel.gd should use transparent hitboxes for image-backed map cells."
}

$miniMapPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/minimap/minimap_panel.gd"
$miniMap = Get-Content -LiteralPath $miniMapPath -Raw
if ($miniMap -notmatch 'UNKNOWN_CELL_ASSET_ID') {
    Fail "minimap_panel.gd should provide an image-backed unknown-cell fallback."
}
if ($miniMap -notmatch 'PLAYER_MARKER_ASSET_ID') {
    Fail "minimap_panel.gd should provide an image-backed current-cell marker."
}
if ($miniMap -notmatch 'view_model\.room_markers\.is_empty\(\)') {
    Fail "minimap_panel.gd should handle empty public marker sets explicitly."
}
if ($miniMap -notmatch '_public_marker_or_unknown') {
    Fail "minimap_panel.gd should render a full public grid without reading TruthMap."
}
if ($miniMap -notmatch 'EXPAND_IGNORE_SIZE') {
    Fail "minimap_panel.gd should scale map tile textures to minimap cells."
}
$requiredMiniMapPatterns = @(
    '_base_asset_id_for_marker',
    '_overlay_asset_id_for_marker',
    'ui\.art19\.map64\.player',
    'ui\.art19\.map64\.explored'
)
foreach ($pattern in $requiredMiniMapPatterns) {
    if ($miniMap -notmatch $pattern) {
        Fail "minimap_panel.gd missing draw-derived minimap overlay evidence: $pattern"
    }
}

Write-Output "ART21R2_IMAGE_BOUNDARY_VALIDATION=PASS_STRUCTURAL_OPEN"
Write-Output "visual_closeout=NOT_COMPLETE_R2_PARTIAL"
Write-Output "contract_rows=$($contract.Count)"
Write-Output "gap_rows=$($gaps.Count)"
