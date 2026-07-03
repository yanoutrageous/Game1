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
    "docs/art/validation/art21r2/ART21R2_SLICE6_MAP_OVERLAY_TILE_REPORT.md",
    "docs/art/validation/art21r2/ART21R2_SLICE6_MODAL_FRAME_REPORT.md",
    "docs/art/validation/art21r2/ART21R2_SLICE6_MODAL_CONTROL_REPORT.md",
    "docs/art/validation/art21r2/ART21R2_SLICE6_MODAL_SECTION_REPORT.md",
    "docs/art/validation/art21r2/ART21R2_SLICE6_MODAL_MAIN_GAME_CENTER_REPORT.md",
    "docs/art/validation/art21r2/ART21R2_SLICE6_DEPLOY_LONGTERM_ART19_SURFACE_REPORT.md",
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
    "screenshots/slice3/godot_run_hud_after_slice3_minimap_draw_overlay_pass14_logic.png",
    "screenshots/slice3/godot_run_hud_after_slice3_minimap_hud32_pass16_smoke.png",
    "screenshots/slice3/godot_after_start_explore_direct_deploy_prep_pass26_q_input_check.png",
    "screenshots/slice3/godot_run_hud_before_q_inventory_pass26_smoke.png",
    "screenshots/slice3/godot_run_hud_q_inventory_open_pass26_smoke.png",
    "screenshots/slice3/godot_run_hud_m_map_open_pass26_smoke.png",
    "screenshots/slice6/godot_map_overlay_art19_map64_pass27_smoke.png",
    "screenshots/slice6/godot_map_overlay_art19_map64_selected_pass27_smoke.png",
    "screenshots/slice6/godot_map_overlay_zujian3_panel_frame_pass36_smoke.png",
    "screenshots/slice6/godot_inventory_zujian3_modal_frame_pass28_smoke.png",
    "screenshots/slice6/godot_ground_loot_zujian3_modal_frame_pass28_smoke.png",
    "screenshots/slice6/godot_result_zujian3_modal_frame_pass28_smoke.png",
    "screenshots/slice6/godot_inventory_zujian3_modal_controls_pass29_smoke.png",
    "screenshots/slice6/godot_ground_loot_zujian3_modal_controls_pass29_smoke.png",
    "screenshots/slice6/godot_result_zujian3_modal_controls_pass30_smoke.png",
    "screenshots/slice6/godot_inventory_zujian3_modal_sections_pass31_smoke.png",
    "screenshots/slice6/godot_ground_loot_zujian3_modal_sections_pass31_smoke.png",
    "screenshots/slice6/godot_result_zujian3_modal_sections_pass32_smoke.png",
    "screenshots/slice6/godot_deploy_prep_direct_from_main_pass34_smoke.png",
    "screenshots/slice6/godot_run_hud_modal_seed_pass34_smoke.png",
    "screenshots/slice6/godot_inventory_nonempty_main_game_center_pass34_smoke.png",
    "screenshots/slice6/godot_ground_loot_nonempty_main_game_center_pass34_smoke.png",
    "screenshots/slice6/godot_result_main_game_center_pass34_smoke.png",
    "screenshots/slice6/godot_main_menu_art19_inner_surfaces_pass35_smoke.png",
    "screenshots/slice6/godot_deploy_prep_art19_inner_surfaces_pass35_smoke.png",
    "screenshots/slice6/godot_long_term_art19_inner_surfaces_pass35_smoke.png",
    "screenshots/slice6/godot_run_hud_from_deploy_art19_inner_surfaces_pass35_smoke.png"
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
    "map_overlay.map_cell_explored",
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
    "minimap_hud_cut_manifest.csv",
    "map_overlay_event_marker_64",
    "candidate crop with purple remnants is not runtime-ready evidence",
    "Applied ART21R2 Map Overlay Tile Pass",
    "ui.art19.map64.*",
    "godot_map_overlay_zujian3_panel_frame_pass36_smoke.png",
    "Applied ART21R2 Modal Frame Pass",
    "modal_cut_dry_run_plan.csv",
    "purple-like pixels from 3690 to 0",
    "Applied ART21R2 Modal Control Pass",
    "modal_control_cut_dry_run_plan.csv",
    "purple-like pixels 1297 -> 0",
    "purple-like pixels 1184 -> 0",
    "Applied ART21R2 Modal Section Pass",
    "modal_section_cut_dry_run_plan.csv",
    "purple-like pixels 1199 -> 0",
    "purple-like pixels 1534 -> 0",
    "Applied ART21R2 Modal Main-Game-Center Pass",
    "No new generated art was introduced",
    "non-empty modal rows and left-rail-safe placement",
    "Applied ART21R2 Deploy LongTerm ART19 Surface Pass",
    "Start Exploration direct Deploy Prep route remained unchanged",
    "godot_deploy_prep_art19_inner_surfaces_pass35_smoke.png",
    "godot_long_term_art19_inner_surfaces_pass35_smoke.png",
    "deploy and long-term inner surfaces use ART19 draw-derived image style boxes"
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

$deployPrepPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd"
$deployPrep = Get-Content -LiteralPath $deployPrepPath -Raw
$requiredDeployPrepSurfacePatterns = @(
    'apply_image_button_ref',
    'make_image_frame_panel',
    'art19_skin_ref',
    'button_confirm',
    '_on_start_preview_pressed'
)
foreach ($pattern in $requiredDeployPrepSurfacePatterns) {
    if ($deployPrep -notmatch $pattern) {
        Fail "deploy_prep_shell.gd missing ART19 image surface pattern: $pattern"
    }
}

$longTermPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/long_term/long_term_shell.gd"
$longTerm = Get-Content -LiteralPath $longTermPath -Raw
$requiredLongTermSurfacePatterns = @(
    'apply_image_button_ref',
    'make_image_frame_panel',
    'art19_skin_ref',
    'panel_deploy_main',
    'panel_highlight'
)
foreach ($pattern in $requiredLongTermSurfacePatterns) {
    if ($longTerm -notmatch $pattern) {
        Fail "long_term_shell.gd missing ART19 image surface pattern: $pattern"
    }
}

$skinKitPath = Join-Path $root "Godot/GraytailGodot/scripts/presentation/art10_ui_skin_kit.gd"
$skinKit = Get-Content -LiteralPath $skinKitPath -Raw
$requiredSkinKitSurfacePatterns = @(
    'style_box_from_asset_ref',
    'apply_image_button_ref',
    'make_image_frame_panel'
)
foreach ($pattern in $requiredSkinKitSurfacePatterns) {
    if ($skinKit -notmatch $pattern) {
        Fail "art10_ui_skin_kit.gd missing shared image surface helper: $pattern"
    }
}

$slice6DeployLongTermReport = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_SLICE6_DEPLOY_LONGTERM_ART19_SURFACE_REPORT.md") -Raw
$requiredSlice6DeployLongTermPatterns = @(
    "PARTIAL",
    "No new generated art was introduced",
    "No new draw slicing was required",
    "ART19 assets",
    "DeployStartButton",
    "directly to Deploy Prep",
    "godot_deploy_prep_art19_inner_surfaces_pass35_smoke.png",
    "godot_long_term_art19_inner_surfaces_pass35_smoke.png",
    "godot_run_hud_from_deploy_art19_inner_surfaces_pass35_smoke.png",
    "not visually complete"
)
foreach ($pattern in $requiredSlice6DeployLongTermPatterns) {
    if ($slice6DeployLongTermReport -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 Slice 6 Deploy/LongTerm report missing required evidence: $pattern"
    }
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

$requiredRunSceneSmokePatterns = @(
    'ART21R2_MODAL_ITEM_SMOKE_FLAG',
    '--art21r2-seed-modal-items',
    '_seed_art21r2_modal_smoke_items_if_requested',
    'debug_spawn_test_item_floor',
    'debug_spawn_test_item_backpack',
    'OS\.get_cmdline_user_args'
)
foreach ($pattern in $requiredRunSceneSmokePatterns) {
    if ($runScene -notmatch $pattern) {
        Fail "run_scene.gd missing ART21R2 debug-smoke seed guard: $pattern"
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
    'ui\.art21r2\.modal\.inventory\.frame',
    'ui\.art21r2\.modal\.ground_loot\.frame',
    'ui\.art21r2\.modal\.result\.frame',
    'art21r2\.modal\.inventory\.frame',
    'art21r2\.modal\.ground_loot\.frame',
    'art21r2\.modal\.result\.frame',
    'art21r2\.modal\.title_plate',
    'art21r2\.modal\.section\.panel',
    'art21r2\.modal\.action_strip',
    'art21r2\.modal\.item_row\.normal',
    'art21r2\.modal\.button\.primary',
    'art21r2\.modal\.button\.secondary',
    'art21r2\.modal\.button\.danger',
    'style_box_for_visual_key',
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
    'ui.art21r2.minimap.hud.player',
    'ui.art21r2.minimap.hud.explored',
    'ui.art21r2.minimap.hud.scanned',
    'ui.art21r2.modal.inventory.frame',
    'ui.art21r2.modal.ground_loot.frame',
    'ui.art21r2.modal.result.frame',
    'ui.art21r2.modal.item_row.normal',
    'ui.art21r2.modal.button.primary',
    'ui.art21r2.modal.button.secondary',
    'ui.art21r2.modal.button.danger',
    'ui.art21r2.modal.title_plate',
    'ui.art21r2.modal.section.panel',
    'ui.art21r2.modal.action_strip',
    'ui.art19.map64.player',
    'ui.art19.map64.unknown',
    'ui.art19.map64.explored',
    'ui.art19.map64.scanned',
    'ui.art19.map64.mine',
    'ui.art19.map64.chest',
    'ui.art19.map64.exit'
)
foreach ($assetId in $requiredManifestIds) {
    if ($manifest -notmatch [regex]::Escape($assetId)) {
        Fail "asset_manifest.csv missing ART21R2 run HUD asset id: $assetId"
    }
}

$requiredRuntimeAssets = @(
    "Godot/GraytailGodot/assets/ui/art21r2/minimap/ui_art21r2_minimap_hud_player_32.png",
    "Godot/GraytailGodot/assets/ui/art21r2/minimap/ui_art21r2_minimap_hud_explored_32.png",
    "Godot/GraytailGodot/assets/ui/art21r2/minimap/ui_art21r2_minimap_hud_scanned_32.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_inventory_frame.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_ground_loot_frame.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_result_frame.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_item_row_normal.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_button_primary.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_button_secondary.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_button_danger.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_title_plate.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_section_panel.png",
    "Godot/GraytailGodot/assets/ui/art21r2/modal/ui_art21r2_modal_action_strip.png",
    "Godot/GraytailGodot/assets/ui/art19/map64/player_marker_64.png",
    "Godot/GraytailGodot/assets/ui/art19/map64/unknown_cell_64.png",
    "Godot/GraytailGodot/assets/ui/art19/map64/explored_cell_64.png",
    "Godot/GraytailGodot/assets/ui/art19/map64/scanned_cell_64.png",
    "Godot/GraytailGodot/assets/ui/art19/map64/mine_icon_64.png",
    "Godot/GraytailGodot/assets/ui/art19/map64/chest_icon_64.png",
    "Godot/GraytailGodot/assets/ui/art19/map64/exit_icon_64.png"
)
foreach ($assetPath in $requiredRuntimeAssets) {
    $fullPath = Join-Path $root $assetPath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Fail "Missing ART21R2 runtime minimap HUD asset: $assetPath"
    }
    if ((Get-Item -LiteralPath $fullPath).Length -le 0) {
        Fail "ART21R2 runtime minimap HUD asset is empty: $assetPath"
    }
}

$modalCutToolPath = Join-Path $root "tools/art21r2_cut_modal_assets.py"
if (-not (Test-Path -LiteralPath $modalCutToolPath -PathType Leaf)) {
    Fail "Missing ART21R2 modal cut tool: tools/art21r2_cut_modal_assets.py"
}
$modalCutTool = Get-Content -LiteralPath $modalCutToolPath -Raw
$requiredModalToolPatterns = @(
    'modal_cut_dry_run_plan.csv',
    '--write-runtime',
    '--force',
    'dark_purple_fringe',
    'ui.art21r2.modal.inventory.frame',
    'ui.art21r2.modal.ground_loot.frame',
    'ui.art21r2.modal.result.frame'
)
foreach ($pattern in $requiredModalToolPatterns) {
    if ($modalCutTool -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 modal cut tool missing required pattern: $pattern"
    }
}

$modalManifestRoot = "D:\AGAME1\sources\art\ART-21R2\_manifest"
$requiredModalManifestFiles = @(
    "modal_staging_manifest.csv",
    "modal_cut_dry_run_plan.csv",
    "modal_cut_manifest.csv",
    "modal_cut_summary.json"
)
foreach ($file in $requiredModalManifestFiles) {
    $path = Join-Path $modalManifestRoot $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "Missing ART21R2 modal manifest file: $path"
    }
    if ((Get-Item -LiteralPath $path).Length -le 0) {
        Fail "ART21R2 modal manifest file is empty: $path"
    }
}

$modalCutRows = @(Import-Csv -LiteralPath (Join-Path $modalManifestRoot "modal_cut_manifest.csv"))
if ($modalCutRows.Count -ne 3) {
    Fail "ART21R2 modal cut manifest must have exactly 3 rows: $($modalCutRows.Count)"
}
$requiredModalAssetIds = @(
    "ui.art21r2.modal.inventory.frame",
    "ui.art21r2.modal.ground_loot.frame",
    "ui.art21r2.modal.result.frame"
)
foreach ($assetId in $requiredModalAssetIds) {
    $row = $modalCutRows | Where-Object { $_.asset_id -eq $assetId }
    if (-not $row) {
        Fail "ART21R2 modal cut manifest missing asset id: $assetId"
    }
    if ($row.status -ne "runtime_written") {
        Fail "ART21R2 modal cut manifest row is not runtime_written: $assetId"
    }
    if ($row.purple_like_after -ne "0") {
        Fail "ART21R2 modal cut manifest row still has purple-like pixels: $assetId"
    }
    if ($row.cut_sha256 -ne "7CBB46D500EE5E620BD10152BC7F6FDA9D0199958C5A7666482035CFCD1F1104") {
        Fail "ART21R2 modal cut manifest row has unexpected cut hash: $assetId"
    }
}

$modalSummary = Get-Content -LiteralPath (Join-Path $modalManifestRoot "modal_cut_summary.json") -Raw
if ($modalSummary -notmatch '"write_runtime": true' -or $modalSummary -notmatch '"purple_like_after": 0') {
    Fail "ART21R2 modal cut summary must record runtime write and purple cleanup."
}

$inventoryPanelPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd"
$inventoryPanel = Get-Content -LiteralPath $inventoryPanelPath -Raw
if ($inventoryPanel -notmatch 'texture_margin_left\s*=\s*38' -or $inventoryPanel -notmatch 'content_margin_left\s*=\s*30') {
    Fail "InventoryPanel must use ART21R2 modal 9-slice margins."
}
if ($inventoryPanel -notmatch '_main_game_modal_rect' -or $inventoryPanel -notmatch 'UILayerContractScript\.run_left_width') {
    Fail "InventoryPanel must center runtime modals in the main gameplay region."
}
$groundLootPanelPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd"
$groundLootPanel = Get-Content -LiteralPath $groundLootPanelPath -Raw
if ($groundLootPanel -notmatch 'texture_margin_left\s*=\s*38' -or $groundLootPanel -notmatch 'content_margin_left\s*=\s*30') {
    Fail "GroundLootPanel must use ART21R2 modal 9-slice margins."
}
if ($groundLootPanel -notmatch '_main_game_modal_rect' -or $groundLootPanel -notmatch 'UILayerContractScript\.run_left_width') {
    Fail "GroundLootPanel must center runtime modals in the main gameplay region."
}
$resultPanelPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/result/result_panel.gd"
$resultPanel = Get-Content -LiteralPath $resultPanelPath -Raw
if ($resultPanel -notmatch 'NinePatchRect' -or $resultPanel -notmatch 'patch_margin_left\s*=\s*38') {
    Fail "ResultPanel must use a NinePatchRect ART21R2 modal frame."
}
if ($resultPanel -notmatch '_main_game_modal_rect' -or $resultPanel -notmatch 'UILayerContractScript\.run_left_width') {
    Fail "ResultPanel must center runtime modals in the main gameplay region."
}
if ($resultPanel -match 'backdrop\s*=\s*ColorRect\.new\(\)') {
    Fail "ResultPanel must not recreate the legacy visible ColorRect backdrop."
}
if ($resultPanel -notmatch 'backdrop\.visible\s*=\s*false') {
    Fail "ResultPanel must hide any legacy Backdrop ColorRect."
}

$slice6ModalReport = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_SLICE6_MODAL_FRAME_REPORT.md") -Raw
$requiredSlice6ModalPatterns = @(
    "Status",
    "PARTIAL",
    "modal_staging_manifest.csv",
    "modal_cut_dry_run_plan.csv",
    "purple/fringe count",
    "godot_inventory_zujian3_modal_frame_pass28_smoke.png",
    "godot_ground_loot_zujian3_modal_frame_pass28_smoke.png",
    "godot_result_zujian3_modal_frame_pass28_smoke.png",
    "Pause -> Exit current run"
)
foreach ($pattern in $requiredSlice6ModalPatterns) {
    if ($slice6ModalReport -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 Slice 6 Modal Frame report missing required evidence: $pattern"
    }
}

$modalControlToolPath = Join-Path $root "tools/art21r2_cut_modal_control_assets.py"
if (-not (Test-Path -LiteralPath $modalControlToolPath -PathType Leaf)) {
    Fail "Missing ART21R2 modal control cut tool: tools/art21r2_cut_modal_control_assets.py"
}
$modalControlTool = Get-Content -LiteralPath $modalControlToolPath -Raw
$requiredModalControlToolPatterns = @(
    'modal_control_cut_dry_run_plan.csv',
    'Zujian3_candidate_005.png',
    'Zujian3_candidate_008.png',
    'ui.art21r2.modal.item_row.normal',
    'ui.art21r2.modal.button.primary',
    'ui.art21r2.modal.button.secondary',
    'ui.art21r2.modal.button.danger'
)
foreach ($pattern in $requiredModalControlToolPatterns) {
    if ($modalControlTool -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 modal control cut tool missing required pattern: $pattern"
    }
}

$requiredModalControlManifestFiles = @(
    "modal_control_staging_manifest.csv",
    "modal_control_cut_dry_run_plan.csv",
    "modal_control_cut_manifest.csv",
    "modal_control_cut_summary.json"
)
foreach ($file in $requiredModalControlManifestFiles) {
    $path = Join-Path $modalManifestRoot $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "Missing ART21R2 modal control manifest file: $path"
    }
    if ((Get-Item -LiteralPath $path).Length -le 0) {
        Fail "ART21R2 modal control manifest file is empty: $path"
    }
}

$modalControlRows = @(Import-Csv -LiteralPath (Join-Path $modalManifestRoot "modal_control_cut_manifest.csv"))
if ($modalControlRows.Count -ne 4) {
    Fail "ART21R2 modal control cut manifest must have exactly 4 rows: $($modalControlRows.Count)"
}
$requiredModalControlAssetIds = @(
    "ui.art21r2.modal.item_row.normal",
    "ui.art21r2.modal.button.primary",
    "ui.art21r2.modal.button.secondary",
    "ui.art21r2.modal.button.danger"
)
foreach ($assetId in $requiredModalControlAssetIds) {
    $row = $modalControlRows | Where-Object { $_.asset_id -eq $assetId }
    if (-not $row) {
        Fail "ART21R2 modal control cut manifest missing asset id: $assetId"
    }
    if ($row.status -ne "runtime_written") {
        Fail "ART21R2 modal control cut manifest row is not runtime_written: $assetId"
    }
    if ($row.purple_like_after -ne "0") {
        Fail "ART21R2 modal control cut manifest row still has purple-like pixels: $assetId"
    }
}
$modalControlSummary = Get-Content -LiteralPath (Join-Path $modalManifestRoot "modal_control_cut_summary.json") -Raw
if ($modalControlSummary -notmatch '"write_runtime": true' -or $modalControlSummary -notmatch '"purple_like_after": 0') {
    Fail "ART21R2 modal control cut summary must record runtime write and purple cleanup."
}

foreach ($scriptAndPattern in @(
    @($inventoryPanel, 'art21r2\.modal\.item_row\.normal'),
    @($inventoryPanel, 'art21r2\.modal\.button\.danger'),
    @($groundLootPanel, 'art21r2\.modal\.item_row\.normal'),
    @($groundLootPanel, 'art21r2\.modal\.button\.primary'),
    @($resultPanel, 'art21r2\.modal\.button\.primary'),
    @($resultPanel, 'style_box_for_visual_key')
)) {
    if ($scriptAndPattern[0] -notmatch $scriptAndPattern[1]) {
        Fail "ART21R2 modal control consumer missing pattern: $($scriptAndPattern[1])"
    }
}

$slice6ModalControlReport = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_SLICE6_MODAL_CONTROL_REPORT.md") -Raw
$requiredSlice6ModalControlPatterns = @(
    "PARTIAL",
    "modal_control_staging_manifest.csv",
    "modal_control_cut_dry_run_plan.csv",
    "1297",
    "1184",
    "godot_inventory_zujian3_modal_controls_pass29_smoke.png",
    "godot_ground_loot_zujian3_modal_controls_pass29_smoke.png",
    "godot_result_zujian3_modal_controls_pass30_smoke.png",
    "non-empty inventory or ground-loot item rows",
    "weak contrast"
)
foreach ($pattern in $requiredSlice6ModalControlPatterns) {
    if ($slice6ModalControlReport -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 Slice 6 Modal Control report missing required evidence: $pattern"
    }
}

$modalSectionToolPath = Join-Path $root "tools/art21r2_cut_modal_section_assets.py"
if (-not (Test-Path -LiteralPath $modalSectionToolPath -PathType Leaf)) {
    Fail "Missing ART21R2 modal section cut tool: tools/art21r2_cut_modal_section_assets.py"
}
$modalSectionTool = Get-Content -LiteralPath $modalSectionToolPath -Raw
$requiredModalSectionToolPatterns = @(
    'modal_section_cut_dry_run_plan.csv',
    'Zujian3_candidate_012.png',
    'Zujian3_candidate_010.png',
    'ui.art21r2.modal.title_plate',
    'ui.art21r2.modal.section.panel',
    'ui.art21r2.modal.action_strip'
)
foreach ($pattern in $requiredModalSectionToolPatterns) {
    if ($modalSectionTool -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 modal section cut tool missing required pattern: $pattern"
    }
}

$requiredModalSectionManifestFiles = @(
    "modal_section_staging_manifest.csv",
    "modal_section_cut_dry_run_plan.csv",
    "modal_section_cut_manifest.csv",
    "modal_section_cut_summary.json"
)
foreach ($file in $requiredModalSectionManifestFiles) {
    $path = Join-Path $modalManifestRoot $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "Missing ART21R2 modal section manifest file: $path"
    }
    if ((Get-Item -LiteralPath $path).Length -le 0) {
        Fail "ART21R2 modal section manifest file is empty: $path"
    }
}

$modalSectionRows = @(Import-Csv -LiteralPath (Join-Path $modalManifestRoot "modal_section_cut_manifest.csv"))
if ($modalSectionRows.Count -ne 3) {
    Fail "ART21R2 modal section cut manifest must have exactly 3 rows: $($modalSectionRows.Count)"
}
$requiredModalSectionAssetIds = @(
    "ui.art21r2.modal.title_plate",
    "ui.art21r2.modal.section.panel",
    "ui.art21r2.modal.action_strip"
)
foreach ($assetId in $requiredModalSectionAssetIds) {
    $row = $modalSectionRows | Where-Object { $_.asset_id -eq $assetId }
    if (-not $row) {
        Fail "ART21R2 modal section cut manifest missing asset id: $assetId"
    }
    if ($row.status -ne "runtime_written") {
        Fail "ART21R2 modal section cut manifest row is not runtime_written: $assetId"
    }
    if ($row.purple_like_after -ne "0") {
        Fail "ART21R2 modal section cut manifest row still has purple-like pixels: $assetId"
    }
}
$modalSectionSummary = Get-Content -LiteralPath (Join-Path $modalManifestRoot "modal_section_cut_summary.json") -Raw
if ($modalSectionSummary -notmatch '"write_runtime": true' -or $modalSectionSummary -notmatch '"purple_like_after": 0') {
    Fail "ART21R2 modal section cut summary must record runtime write and purple cleanup."
}

foreach ($scriptAndPattern in @(
    @($inventoryPanel, 'art21r2\.modal\.title_plate'),
    @($inventoryPanel, 'art21r2\.modal\.section\.panel'),
    @($groundLootPanel, 'art21r2\.modal\.title_plate'),
    @($groundLootPanel, 'art21r2\.modal\.section\.panel'),
    @($resultPanel, 'art21r2\.modal\.action_strip'),
    @($resultPanel, 'AUTOWRAP_WORD_SMART')
)) {
    if ($scriptAndPattern[0] -notmatch $scriptAndPattern[1]) {
        Fail "ART21R2 modal section consumer missing pattern: $($scriptAndPattern[1])"
    }
}

$slice6ModalSectionReport = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_SLICE6_MODAL_SECTION_REPORT.md") -Raw
$requiredSlice6ModalSectionPatterns = @(
    "PARTIAL",
    "modal_section_staging_manifest.csv",
    "modal_section_cut_dry_run_plan.csv",
    "1199",
    "1534",
    "godot_inventory_zujian3_modal_sections_pass31_smoke.png",
    "godot_ground_loot_zujian3_modal_sections_pass31_smoke.png",
    "godot_result_zujian3_modal_sections_pass32_smoke.png",
    "pass31 was corrected in pass32",
    "non-empty item-row live evidence"
)
foreach ($pattern in $requiredSlice6ModalSectionPatterns) {
    if ($slice6ModalSectionReport -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 Slice 6 Modal Section report missing required evidence: $pattern"
    }
}

$slice6ModalCenterReport = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_SLICE6_MODAL_MAIN_GAME_CENTER_REPORT.md") -Raw
$requiredSlice6ModalCenterPatterns = @(
    "PARTIAL",
    "--art21r2-seed-modal-items",
    "debug-smoke seed",
    "main gameplay region",
    "without covering the left information rail",
    "godot_deploy_prep_direct_from_main_pass34_smoke.png",
    "godot_run_hud_modal_seed_pass34_smoke.png",
    "godot_inventory_nonempty_main_game_center_pass34_smoke.png",
    "godot_ground_loot_nonempty_main_game_center_pass34_smoke.png",
    "godot_result_main_game_center_pass34_smoke.png",
    "not natural loot progression completion",
    "NOT_COMPLETE_R2_PARTIAL"
)
foreach ($pattern in $requiredSlice6ModalCenterPatterns) {
    if ($slice6ModalCenterReport -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 Slice 6 Modal Main-Game-Center report missing required evidence: $pattern"
    }
}

$mapOverlayPath = Join-Path $root "Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd"
$mapOverlay = Get-Content -LiteralPath $mapOverlayPath -Raw
if ($mapOverlay -notmatch 'transparent_style_box') {
    Fail "map_overlay_panel.gd should use transparent hitboxes for image-backed map cells."
}
if ($mapOverlay -notmatch '_map_overlay_asset_ref_for_marker') {
    Fail "map_overlay_panel.gd should route map overlay cells through the ART21R2 asset ref helper."
}
if ($mapOverlay -notmatch 'art19_map64_ref') {
    Fail "map_overlay_panel.gd should use draw-derived ART19 64px assets for large map overlay cells."
}
if ($mapOverlay -notmatch 'ART21R2_MAP_PANEL_FRAME_VISUAL_KEY' -or $mapOverlay -notmatch 'style_box_for_visual_key') {
    Fail "map_overlay_panel.gd should use an ART21R2 image-backed modal frame for the centered map panel."
}

$slice6MapOverlayReport = Get-Content -LiteralPath (Join-Path $validationRoot "ART21R2_SLICE6_MAP_OVERLAY_TILE_REPORT.md") -Raw
$requiredSlice6MapOverlayPatterns = @(
    "Status: PARTIAL",
    "art19_map64_ref",
    "godot_map_overlay_art19_map64_pass27_smoke.png",
    "godot_map_overlay_art19_map64_selected_pass27_smoke.png",
    "godot_map_overlay_zujian3_panel_frame_pass36_smoke.png",
    "Zujian3 modal frame",
    "No generated replacement art was introduced"
)
foreach ($pattern in $requiredSlice6MapOverlayPatterns) {
    if ($slice6MapOverlayReport -notmatch [regex]::Escape($pattern)) {
        Fail "ART21R2 Slice 6 Map Overlay report missing required evidence: $pattern"
    }
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
    'ui\.art21r2\.minimap\.hud\.player',
    'ui\.art21r2\.minimap\.hud\.explored'
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
