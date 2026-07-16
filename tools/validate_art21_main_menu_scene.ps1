param()

$ErrorActionPreference = "Stop"

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-TextContains {
    param([string]$Text, [string]$Needle, [string]$Context)
    Assert-Condition $Text.Contains($Needle) "$Context is missing required token: $Needle"
}

function Get-PngDimensions {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    Assert-Condition ($bytes.Length -ge 24) "PNG is too short: $Path"
    $signature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
    for ($index = 0; $index -lt $signature.Length; $index++) {
        Assert-Condition ($bytes[$index] -eq $signature[$index]) "Invalid PNG signature: $Path"
    }
    $width = [System.BitConverter]::ToUInt32([byte[]]($bytes[19], $bytes[18], $bytes[17], $bytes[16]), 0)
    $height = [System.BitConverter]::ToUInt32([byte[]]($bytes[23], $bytes[22], $bytes[21], $bytes[20]), 0)
    return @([int]$width, [int]$height)
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$godotRoot = Join-Path $repoRoot "Godot\GraytailGodot"
$validationRoot = Join-Path $repoRoot "docs\art\validation\art21"
$assetRoot = Join-Path $godotRoot "assets\ui\art21\main_menu\scene"
$manifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$reportCsvPath = Join-Path $validationRoot "main_menu_runtime_asset_report.csv"
$reportJsonPath = Join-Path $validationRoot "main_menu_runtime_asset_report.json"
$contractPath = Join-Path $validationRoot "main_menu_runtime_asset_contract.csv"
$motionContractPath = Join-Path $validationRoot "main_menu_motion_contract.csv"
$motionAuditPath = Join-Path $validationRoot "ART21_MAIN_MENU_MOTION_AUDIT.md"
$contractScriptPath = Join-Path $godotRoot "scripts\presentation\art21_main_menu_asset_contract.gd"
$placementScriptPath = Join-Path $godotRoot "scripts\presentation\art21_ui_placement_contract.gd"
$mainModelPath = Join-Path $godotRoot "scripts\ui\main_menu\main_menu_model.gd"
$mainShellPath = Join-Path $godotRoot "scripts\ui\main_menu\main_menu_shell.gd"
$appShellPath = Join-Path $godotRoot "scripts\ui\app_shell\app_shell.gd"
$captureRunnerPath = Join-Path $godotRoot "tests\art21_main_menu_capture_runner.gd"
$closeoutDocPath = Join-Path $repoRoot "docs\art\ART21_CLOSEOUT_MAIN_MENU_SCENE_RECONSTRUCTION.md"
$activeStageIndexPath = Join-Path $repoRoot "docs\50_stages\active\STAGE_INDEX.md"
$closedStageIndexPath = Join-Path $repoRoot "docs\50_stages\closed\STAGE_INDEX.md"

$requiredFiles = @(
    $manifestPath,
    $reportCsvPath,
    $reportJsonPath,
    $contractPath,
    $motionContractPath,
    $motionAuditPath,
    $contractScriptPath,
    $placementScriptPath,
    $mainModelPath,
    $mainShellPath,
    $appShellPath,
    $captureRunnerPath,
    $closeoutDocPath,
    $activeStageIndexPath,
    $closedStageIndexPath
)
foreach ($path in $requiredFiles) {
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing ART21 main-menu file: $path"
}

$reportRows = @(Import-Csv -LiteralPath $reportCsvPath)
$contractRows = @(Import-Csv -LiteralPath $contractPath)
$motionRows = @(Import-Csv -LiteralPath $motionContractPath)
$manifestRows = @(Import-Csv -LiteralPath $manifestPath)
$report = Get-Content -LiteralPath $reportJsonPath -Raw | ConvertFrom-Json

Assert-Condition ($reportRows.Count -eq 152) "Expected 152 generated runtime assets, got $($reportRows.Count)."
Assert-Condition ($contractRows.Count -eq 152) "Expected 152 main-menu contract rows, got $($contractRows.Count)."
Assert-Condition ($motionRows.Count -eq 17) "Expected 17 motion audit rows, got $($motionRows.Count)."
Assert-Condition ([int]$report.schema_version -eq 3) "Expected clean-plate main-menu report schema 3."
Assert-Condition ([int]$report.asset_count -eq 152) "Runtime report asset_count mismatch."
Assert-Condition ([bool]$report.budget_pass) "Runtime report texture budget failed."
Assert-Condition ([double]$report.decoded_mib_default_load -le 128.0) "Default decoded texture load exceeds 128 MiB."
Assert-Condition ([double]$report.decoded_mib_default_load -le 96.0) "Default decoded texture load exceeds the 96 MiB ART21 target."
Assert-Condition ($report.default_load_policy -eq "asset_level_live_and_interaction_reachable_worst_case") "Runtime report does not use the asset-level conservative load policy."
Assert-Condition ([int]$report.default_load_asset_count -eq 66) "Expected 66 live or interaction-reachable default assets."
Assert-Condition ($report.source_pack_id -eq "main_menu_asset_pack/ready_to_migrate") "Portable source-pack identifier is missing."
Assert-Condition ($report.source_scope -eq "external_explicit_input_not_runtime_authority") "External source scope is not explicit."
Assert-Condition ([string]::IsNullOrWhiteSpace([string]$report.source_root)) "Versioned report must not contain a machine-specific source_root."
Assert-Condition ($report.runtime_root -eq "res://assets/ui/art21/main_menu/scene") "Unexpected runtime_root in report."
Assert-Condition ($report.render_strategy -eq "master_matched_clean_plate_plus_interactive_overlays") "Clean-plate render strategy is not declared."

$expectedGroups = [ordered]@{
    "main_menu_evidence" = 1
    "main_menu_master" = 1
    "main_menu_default" = 44
    "main_menu_character_idle" = 8
    "main_menu_character_focus" = 4
    "main_menu_character_walk_dungeon" = 4
    "main_menu_character_walk_company" = 4
    "main_menu_modal" = 2
    "main_menu_settings" = 16
    "main_menu_focus" = 8
    "main_menu_environment" = 36
    "main_menu_ambient_active" = 16
    "main_menu_transition_cave" = 4
    "main_menu_transition_company" = 4
}
foreach ($group in $expectedGroups.Keys) {
    $actual = @($reportRows | Where-Object { $_.load_group -eq $group }).Count
    Assert-Condition ($actual -eq $expectedGroups[$group]) "Load-group count mismatch for ${group}: expected $($expectedGroups[$group]), got $actual."
}

$duplicateKeys = @($reportRows | Group-Object visual_key | Where-Object { $_.Count -gt 1 })
$duplicateIds = @($reportRows | Group-Object asset_id | Where-Object { $_.Count -gt 1 })
$duplicatePaths = @($reportRows | Group-Object runtime_path | Where-Object { $_.Count -gt 1 })
Assert-Condition ($duplicateKeys.Count -eq 0) "Duplicate main-menu visual_key values found."
Assert-Condition ($duplicateIds.Count -eq 0) "Duplicate main-menu asset_id values found."
Assert-Condition ($duplicatePaths.Count -eq 0) "Duplicate main-menu runtime paths found."

$requiredContractColumns = @("runtime_rect", "anchor", "pivot", "z_layer", "runtime_status", "default_load")
foreach ($column in $requiredContractColumns) {
    Assert-Condition ($contractRows[0].PSObject.Properties.Name -contains $column) "Runtime contract is missing required placement column: $column"
}
$liveContractRows = @($contractRows | Where-Object { $_.default_load -eq "true" })
$deferredContractRows = @($contractRows | Where-Object { $_.runtime_status -eq "deferred_not_mounted" })
$evidenceContractRows = @($contractRows | Where-Object { $_.runtime_status -eq "evidence_only" })
Assert-Condition ($liveContractRows.Count -eq 66) "Expected 66 live or interaction-reachable placement rows."
Assert-Condition ($deferredContractRows.Count -eq 85) "Expected 85 explicitly deferred placement rows."
Assert-Condition ($evidenceContractRows.Count -eq 1) "Expected one evidence-only accepted composite row."
Assert-Condition (@($liveContractRows | Where-Object { $_.runtime_rect -eq "not_mounted" -or $_.anchor -eq "n/a" -or $_.pivot -eq "n/a" -or [string]::IsNullOrWhiteSpace($_.z_layer) }).Count -eq 0) "A live placement row lacks rect, anchor, pivot, or z-layer metadata."
Assert-Condition (@($evidenceContractRows | Where-Object { $_.default_load -eq "true" }).Count -eq 0) "Evidence-only master entered the default runtime load."
$defaultDecodedFromRows = [long](($reportRows | Where-Object { $_.default_load -eq "true" } | Measure-Object decoded_bytes -Sum).Sum)
Assert-Condition ($defaultDecodedFromRows -eq [long]$report.decoded_bytes_default_load) "Asset-level default decoded budget does not match report rows."

$manifestById = @{}
foreach ($row in $manifestRows) { $manifestById[$row.asset_id] = $row }
foreach ($row in $reportRows) {
    Assert-Condition ($manifestById.ContainsKey($row.asset_id)) "Generated asset is absent from asset_manifest.csv: $($row.asset_id)"
    $manifestRow = $manifestById[$row.asset_id]
    Assert-Condition ($manifestRow.godot_path -eq $row.runtime_path) "Manifest/runtime path mismatch for $($row.asset_id)."
    Assert-Condition ($manifestRow.source_status -eq "art21_main_menu_runtime_$($row.source_status)") "Manifest source_status mismatch for $($row.asset_id)."
    $localPath = Join-Path $godotRoot ($row.runtime_path.Substring(6) -replace "/", "\")
    Assert-Condition (Test-Path -LiteralPath $localPath -PathType Leaf) "Generated PNG is missing: $localPath"
    Assert-Condition ((Get-Item -LiteralPath $localPath).Length -eq [long]$row.file_bytes) "Generated PNG byte size mismatch: $($row.asset_id)"
    $hash = (Get-FileHash -LiteralPath $localPath -Algorithm SHA256).Hash
    Assert-Condition ($hash -eq $row.sha256) "Generated PNG hash mismatch: $($row.asset_id)"
}

$generatedRuntimeSidecars = @(Get-ChildItem -LiteralPath $assetRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -like "*.import" -or $_.Name -like "*.uid" -or $_.Name -like "*.translation"
})
Assert-Condition ($generatedRuntimeSidecars.Count -eq 0) "Generated import side effects found inside the ART21 main-menu runtime asset set."

$canonicalCount = @($reportRows | Where-Object { $_.source_status -eq "canonical" }).Count
$generatedBoardRows = @($reportRows | Where-Object { $_.source_status -eq "generated_master_matched_board_atlas" })
$generatedCharacterRows = @($reportRows | Where-Object { $_.source_status -eq "generated_master_matched_character_atlas" })
$cleanPlateRows = @($reportRows | Where-Object { $_.source_status -eq "generated_master_matched_clean_plate" })
$evidenceMasterRows = @($reportRows | Where-Object { $_.source_status -eq "promoted_composite_master" })
Assert-Condition ($canonicalCount -eq 122) "Expected 122 canonical source rows, got $canonicalCount."
Assert-Condition ($generatedBoardRows.Count -eq 16) "Expected 16 master-matched menu-board states, got $($generatedBoardRows.Count)."
Assert-Condition ($generatedCharacterRows.Count -eq 12) "Expected 12 master-matched character idle/focus frames, got $($generatedCharacterRows.Count)."
Assert-Condition ($cleanPlateRows.Count -eq 1 -and $cleanPlateRows[0].visual_key -eq "main_menu.scene.background.scene_clean_plate") "Live clean plate is missing or ambiguous."
Assert-Condition ($evidenceMasterRows.Count -eq 1 -and $evidenceMasterRows[0].visual_key -eq "main_menu.scene.background.scene_master") "Accepted composition evidence master is missing or ambiguous."
foreach ($row in @($generatedBoardRows | Where-Object { $_.visual_key -like "main_menu.scene.menu.long_term.*" })) {
    Assert-Condition ([int]$row.width -gt (2 * [int]$row.height)) "Long-term board is not clearly non-directional/rectangular: $($row.visual_key)"
}
Assert-Condition (@($reportRows | Where-Object { $_.source_status -match "fallback|ambiguous|placeholder|reference_only" }).Count -eq 0) "Fallback, ambiguous, placeholder, or reference-only art entered the ART21 runtime set."

$liveMotionRows = @($motionRows | Where-Object { $_.runtime_state -eq "final_live_tuned" })
$codeMotionRows = @($motionRows | Where-Object { $_.runtime_state -eq "final_live_code" })
$deferredMotionRows = @($motionRows | Where-Object { $_.runtime_state -eq "deferred_optional" })
Assert-Condition ($liveMotionRows.Count -eq 8) "Expected eight tuned live artwork motions."
Assert-Condition ($codeMotionRows.Count -eq 3) "Expected three final code-driven feedback motions."
Assert-Condition ($deferredMotionRows.Count -eq 6) "Expected six optional polish motions to remain deferred."
foreach ($motionId in @("smoke", "birds", "leaves", "dungeon_flag", "company_banner", "lantern_flame", "character_idle", "character_focus")) {
    Assert-Condition (@($liveMotionRows | Where-Object { $_.motion_id -eq $motionId }).Count -eq 1) "Live tuned motion is missing: $motionId"
}
foreach ($motionId in @("transition_cave", "transition_company", "focus_rect")) {
    Assert-Condition (@($codeMotionRows | Where-Object { $_.motion_id -eq $motionId }).Count -eq 1) "Final code motion is missing: $motionId"
}
Assert-Condition (@($motionRows | Where-Object { [string]::IsNullOrWhiteSpace($_.acceptance) }).Count -eq 0) "Motion contract contains an empty acceptance rule."

$requiredVisualKeys = @(
    "main_menu.scene.background.scene_clean_plate",
    "main_menu.scene.background.scene_master",
    "main_menu.scene.background.sky",
    "main_menu.scene.architecture.dungeon_base",
    "main_menu.scene.architecture.company_base",
    "main_menu.scene.character.idle.00",
    "main_menu.scene.character.focus.01",
    "main_menu.scene.character.walk_dungeon.00",
    "main_menu.scene.character.walk_company.00",
    "main_menu.scene.environment.notice.frame",
    "main_menu.scene.menu.explore.normal",
    "main_menu.scene.menu.explore.focused",
    "main_menu.scene.menu.long_term.normal",
    "main_menu.scene.menu.settings.normal",
    "main_menu.scene.menu.exit.normal",
    "main_menu.scene.menu.modal.panel",
    "main_menu.scene.menu.settings_control.0.0",
    "main_menu.scene.fx.cave_activation",
    "main_menu.scene.fx.company_activation",
    "main_menu.scene.transition.cave.00",
    "main_menu.scene.transition.company.00"
)
foreach ($key in $requiredVisualKeys) {
    Assert-Condition (@($reportRows | Where-Object { $_.visual_key -eq $key }).Count -eq 1) "Required visual key is missing or duplicated: $key"
}

$mainModelText = Get-Content -LiteralPath $mainModelPath -Raw
$mainShellText = Get-Content -LiteralPath $mainShellPath -Raw
$appShellText = Get-Content -LiteralPath $appShellPath -Raw
$placementText = Get-Content -LiteralPath $placementScriptPath -Raw
$contractScriptText = Get-Content -LiteralPath $contractScriptPath -Raw

$entryRoutes = [ordered]@{
    "deploy" = "TARGET_DEPLOY"
    "long_term" = "TARGET_LONG_TERM"
    "settings" = "TARGET_SETTINGS"
    "exit_game" = "TARGET_EXIT"
}
foreach ($entryId in $entryRoutes.Keys) {
    Assert-TextContains $mainModelText ('"id": &"' + $entryId + '"') "main_menu_model.gd"
    Assert-TextContains $mainModelText ("NavigationIntentScript." + $entryRoutes[$entryId]) "main_menu_model.gd"
    Assert-TextContains $mainShellText ('&"' + $entryId + '"') "main_menu_shell.gd"
    Assert-TextContains $mainShellText ('"MainMenuEntry_%s"') "main_menu_shell.gd"
}
Assert-TextContains $mainModelText '"requires_confirm": true' "main_menu_model.gd"
Assert-TextContains $mainShellText "navigation_intent_requested.emit(intent)" "main_menu_shell.gd"
Assert-TextContains $mainShellText "KEY_F1" "main_menu_shell.gd"
Assert-TextContains $mainShellText "KEY_F2" "main_menu_shell.gd"

$sceneTokens = @(
    "MainMenuSceneCleanPlate",
    "MainMenuTitle",
    "MainMenuNoticeText",
    "MainMenuCharacter",
    "MainMenuDungeonFlag",
    "MainMenuCompanyBanner",
    "MainMenuLanternFlame",
    "MainMenuCaveFocusGlow",
    "MainMenuChimneySmoke",
    "MainMenuBirds",
    "MainMenuFallingLeaves",
    "AMBIENT_PROFILES",
    "PERSISTENT_MOTION_PROFILES",
    "CHARACTER_IDLE_SEQUENCE",
    "_update_ambient_motion",
    "event_travel",
    "TRANSITION_DURATION := 1.10",
    "transition_texture = ColorRect.new()",
    "reduced_motion",
    "TEXTURE_FILTER_NEAREST"
)
foreach ($token in $sceneTokens) { Assert-TextContains $mainShellText $token "main_menu_shell.gd" }
foreach ($forbiddenMotionToken in @("MainMenuIntegratedSceneMaster", "MainMenuPuddleShimmer", "environment_elapsed", "transition_elapsed >= 0.62", "main_menu.scene.transition.cave", "main_menu.scene.transition.company", "main_menu.scene.fx.focus_rect")) {
    Assert-Condition (-not $mainShellText.Contains($forbiddenMotionToken)) "Prototype or synchronized motion remains live: $forbiddenMotionToken"
}

Assert-Condition (-not $mainShellText.Contains("`t_build_architecture_scene()")) "Legacy full split-layer architecture call is active and can reintroduce collage seams."
foreach ($requiredBuildCall in @("`t_build_brand_sign()", "`t_build_character_scene()", "`t_build_notice_board()", "`t_build_environment_motion()")) {
    Assert-TextContains $mainShellText $requiredBuildCall "main_menu_shell.gd"
}

$forbiddenLegacyTokens = @("MainMenuActionDeck", "MainMenuTopSummary", "MainMenuRolePanel", "MainMenuMetaFrame")
foreach ($token in $forbiddenLegacyTokens) {
    Assert-Condition (-not $mainShellText.Contains($token)) "Legacy panel-shell token remains in the reconstructed scene: $token"
}

$overlayTokens = @(
    "SettingsOverlay",
    "SettingsOverlayDim",
    "SettingsModalPanel",
    "ExitConfirmDialog",
    "ExitConfirmDim",
    "ExitConfirmModalPanel",
    "main_menu.scene.menu.modal.panel",
    "main_menu.scene.menu.modal.button"
)
foreach ($token in $overlayTokens) { Assert-TextContains $appShellText $token "app_shell.gd" }
Assert-TextContains $placementText "Art21MainMenuAssetContract" "art21_ui_placement_contract.gd"
foreach ($key in $reportRows.visual_key) { Assert-TextContains $contractScriptText $key "art21_main_menu_asset_contract.gd" }

$captures = [ordered]@{
    "art21_main_menu_1280x720_default.png" = @(1280, 720)
    "art21_main_menu_1280x720_long_term.png" = @(1280, 720)
    "art21_main_menu_1280x720_settings.png" = @(1280, 720)
    "art21_main_menu_1280x720_exit.png" = @(1280, 720)
    "art21_main_menu_1600x900_default.png" = @(1600, 900)
    "art21_main_menu_1920x1080_default.png" = @(1920, 1080)
}
$captureHashes = @()
foreach ($name in $captures.Keys) {
    $path = Join-Path $validationRoot $name
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "Missing live capture: $name"
    Assert-Condition ((Get-Item -LiteralPath $path).Length -gt 100000) "Live capture is unexpectedly small: $name"
    $dimensions = Get-PngDimensions $path
    Assert-Condition ($dimensions[0] -eq $captures[$name][0] -and $dimensions[1] -eq $captures[$name][1]) "Live capture dimensions mismatch for ${name}: $($dimensions[0])x$($dimensions[1])."
    $captureHashes += (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
Assert-Condition (@($captureHashes | Sort-Object -Unique).Count -eq $captures.Count) "One or more ART21 capture states/resolutions are duplicate images."

$captureRunnerText = Get-Content -LiteralPath $captureRunnerPath -Raw
foreach ($state in @("default", "long_term", "settings", "exit")) {
    Assert-TextContains $captureRunnerText $state "art21_main_menu_capture_runner.gd"
}

$closeoutText = Get-Content -LiteralPath $closeoutDocPath -Raw
$activeStageText = Get-Content -LiteralPath $activeStageIndexPath -Raw
$closedStageText = Get-Content -LiteralPath $closedStageIndexPath -Raw
foreach ($token in @("Status: CLOSED / PASS", "Runtime assets: 152 PNG files", "10.40 MiB", "Computer Use")) {
    Assert-TextContains $closeoutText $token "ART21 closeout"
}
Assert-TextContains $activeStageText "ART21 closed; successor not yet named" "active stage index"
Assert-TextContains $closedStageText "ART21 | closed / main-menu scene reconstruction" "closed stage index"

$activeFiles = @($mainModelPath, $mainShellPath, $appShellPath, $contractScriptPath, $placementScriptPath, $reportJsonPath, $contractPath, $motionContractPath, $motionAuditPath)
foreach ($path in $activeFiles) {
    $text = Get-Content -LiteralPath $path -Raw
    Assert-Condition (-not $text.Contains("D:\AGAME1")) "Active ART21 file contains historical-machine path authority: $path"
}

$status = @(git -C $repoRoot status --short)
$staged = @($status | Where-Object { $_ -match "^[MADRCU]" })
Assert-Condition ($staged.Count -eq 0) "ART21 validator expects unstaged work before an explicitly authorized commit."

Write-Host "ART21 main-menu scene validation passed."
Write-Host "runtime_assets=$($reportRows.Count)"
Write-Host "canonical_assets=$canonicalCount"
Write-Host "generated_board_states=$($generatedBoardRows.Count)"
Write-Host "generated_character_frames=$($generatedCharacterRows.Count)"
Write-Host "clean_plates=$($cleanPlateRows.Count)"
Write-Host "evidence_scene_masters=$($evidenceMasterRows.Count)"
Write-Host "default_decoded_mib=$($report.decoded_mib_default_load)"
Write-Host "live_captures=$($captures.Count)"
Write-Host "motion_rows=$($motionRows.Count)"
Write-Host "live_tuned_motion=$($liveMotionRows.Count)"
Write-Host "final_code_motion=$($codeMotionRows.Count)"
Write-Host "deferred_optional_motion=$($deferredMotionRows.Count)"
Write-Host "routes=deploy,long_term,settings,exit_game"
