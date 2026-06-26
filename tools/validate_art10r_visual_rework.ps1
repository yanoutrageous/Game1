param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$GodotExe = "D:\Godot\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe",
  [switch]$Capture
)

$ErrorActionPreference = "Stop"

function Add-Failure {
  param([string]$Message)
  $script:Failures.Add($Message) | Out-Null
}

function Test-File {
  param([string]$Path, [string]$Label)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    Add-Failure "$Label missing: $Path"
  }
}

$Failures = New-Object System.Collections.Generic.List[string]
$Warnings = New-Object System.Collections.Generic.List[string]
$root = (Resolve-Path -LiteralPath $RepoRoot).Path
$godotRoot = Join-Path $root "Godot\GraytailGodot"
$validationDir = Join-Path $root "docs\art\validation\art10r"
$manifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$skinKitPath = Join-Path $godotRoot "scripts\presentation\art10_ui_skin_kit.gd"
$docPath = Join-Path $root "docs\art\ART10R_BASE_CONFIRMED_UI_VISUAL_REWORK.md"
$fontPath = Join-Path $godotRoot "assets\fonts\FusionPixel.otf"

if (-not (Test-Path -LiteralPath $validationDir -PathType Container)) {
  New-Item -ItemType Directory -Path $validationDir | Out-Null
}

if ($Capture) {
  if (-not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    Add-Failure "Godot executable missing: $GodotExe"
  } else {
    $captureScript = @'
extends SceneTree

const OUTPUT_DIR := "res://../../docs/art/validation/art10r"
const MAIN_SCENE := "res://scenes/main/main.tscn"

func _initialize() -> void:
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	get_root().size = Vector2i(1280, 720)
	var main_scene := load(MAIN_SCENE)
	if main_scene == null:
		push_error("main scene missing")
		quit(2)
		return
	var main: Node = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	await process_frame
	await _capture("art10r_main_menu.png")
	var run_scene := get_root().find_child("RunScene", true, false)
	if run_scene != null:
		if run_scene.has_method("_show_deploy_shell"):
			run_scene.call("_show_deploy_shell", &"config")
			await process_frame
			await process_frame
			await _capture("art10r_deploy_prep.png")
		if run_scene.has_method("_show_long_term_shell"):
			run_scene.call("_show_long_term_shell", &"goals")
			await process_frame
			await process_frame
			await _capture("art10r_long_term.png")
		if run_scene.has_method("_show_run_screen"):
			run_scene.call("_show_run_screen")
			await process_frame
			await process_frame
			await _capture("art10r_run_hud.png")
	quit()

func _capture(file_name: String) -> void:
	await process_frame
	var image := get_root().get_texture().get_image()
	var path := ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, file_name])
	var err := image.save_png(path)
	if err != OK:
		push_error("capture failed: %s" % path)
'@
    $tempScript = Join-Path $env:TEMP "art10r_visual_capture.gd"
    Set-Content -LiteralPath $tempScript -Encoding utf8 -Value $captureScript
    & $GodotExe --path $godotRoot --script $tempScript --no-header --quit-after 300
    if ($LASTEXITCODE -ne 0) {
      Add-Failure "Godot capture run failed with exit code $LASTEXITCODE"
    }
  }
}

Test-File $fontPath "FusionPixel runtime font"
Test-File $manifestPath "asset manifest"
Test-File $skinKitPath "ART10/10R skin kit"
Test-File $docPath "ART10R documentation"

if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
  $manifest = Import-Csv -LiteralPath $manifestPath
  $ids = @{}
  foreach ($row in $manifest) {
    if ($ids.ContainsKey($row.asset_id)) {
      Add-Failure "duplicate asset_id in manifest: $($row.asset_id)"
    } else {
      $ids[$row.asset_id] = $true
    }
  }
  $fontRows = @($manifest | Where-Object { $_.asset_id -eq "ui.font.fusion_pixel" })
  if ($fontRows.Count -ne 1) {
    Add-Failure "ui.font.fusion_pixel row count must be 1, found $($fontRows.Count)"
  }
}

$uiTargets = @(
  "Godot\GraytailGodot\scripts\presentation\art10_ui_skin_kit.gd",
  "Godot\GraytailGodot\scripts\ui\main_menu\main_menu_shell.gd",
  "Godot\GraytailGodot\scripts\ui\deploy_prep\deploy_prep_shell.gd",
  "Godot\GraytailGodot\scripts\ui\long_term\long_term_shell.gd",
  "Godot\GraytailGodot\scripts\ui\run_surface\run_surface.gd",
  "Godot\GraytailGodot\scripts\ui\hud\hud.gd",
  "Godot\GraytailGodot\scripts\ui\inventory\inventory_panel.gd",
  "Godot\GraytailGodot\scripts\ui\ground_loot\ground_loot_panel.gd"
)

foreach ($relative in $uiTargets) {
  $path = Join-Path $root $relative
  Test-File $path $relative
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $content = Get-Content -Raw -LiteralPath $path
    foreach ($pattern in @("D:\AGAME1\Base Art", "D:\AGAME1\Draw", "D:\A GAME\26.5.30 GameJam\Draw")) {
      if ($content.Contains($pattern)) {
        Add-Failure "runtime UI file contains forbidden source path '$pattern': $relative"
      }
    }
  }
}

if (Test-Path -LiteralPath $docPath -PathType Leaf) {
  $doc = Get-Content -Raw -LiteralPath $docPath
  foreach ($index in 0..11) {
    if ($doc -notmatch "(?m)^## $index\. ") {
      Add-Failure "ART10R documentation missing numbered heading: ## $index."
    }
  }
}

$expectedScreens = @(
  "art10r_main_menu.png",
  "art10r_deploy_prep.png",
  "art10r_long_term.png",
  "art10r_run_hud.png"
)
foreach ($screen in $expectedScreens) {
  $path = Join-Path $validationDir $screen
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    $Warnings.Add("final screenshot missing or not generated yet: $screen") | Out-Null
  }
}

$riskMatches = Select-String -Path ($uiTargets | ForEach-Object { Join-Path $root $_ }) -Pattern "preview|Debug|debug|draft|Legacy|display_only|read_only" -ErrorAction SilentlyContinue
$riskCount = @($riskMatches).Count
if ($riskCount -gt 0) {
  $Warnings.Add("source token risk remains; review sanitizer/player-visible paths; count=$riskCount") | Out-Null
}

$gitStatus = @()
try {
  $gitStatus = git -C $root status --short --untracked-files=all
} catch {
  Add-Failure "git status failed: $($_.Exception.Message)"
}

$forbiddenChanges = @($gitStatus | Where-Object {
  ($_ -match "Connection/") -or
  ($_ -match "Godot/GraytailGodot/scripts/core/(run|command|save)/" -and $_ -notmatch "\.uid$") -or
  ($_ -match "^.. assets/") -or
  ($_ -match "^.. game_material/")
})
foreach ($change in $forbiddenChanges) {
  Add-Failure "forbidden repo change detected: $change"
}

$sideEffects = @($gitStatus | Where-Object {
  ($_ -match "\.uid$") -or
  ($_ -match "\.translation$") -or
  ($_ -match "Godot/GraytailGodot/project.godot") -or
  ($_ -match "\.import$") -or
  ($_ -match "Godot/GraytailGodot/\.godot/")
})

$result = [ordered]@{
  status = if ($Failures.Count -eq 0) { "PASS" } else { "FAIL" }
  failures = @($Failures)
  warnings = @($Warnings)
  source_token_risk_count = $riskCount
  generated_or_preexisting_side_effects = @($sideEffects)
}

$result | ConvertTo-Json -Depth 6

if ($Failures.Count -gt 0) {
  exit 1
}
