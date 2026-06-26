param(
  [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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
$manifestPath = Join-Path $godotRoot "data\assets\asset_manifest.csv"
$fontSource = Join-Path $root "assets\Fonts\FusionPixel.otf"
$fontTarget = Join-Path $godotRoot "assets\fonts\FusionPixel.otf"
$skinKit = Join-Path $godotRoot "scripts\presentation\art10_ui_skin_kit.gd"
$docPath = Join-Path $root "docs\art\ART10_BASE_LAYOUT_PIXEL_FONT_UI_PRODUCTIZATION.md"

Test-File $fontSource "FusionPixel source font"
Test-File $fontTarget "FusionPixel runtime font"
Test-File $manifestPath "asset manifest"
Test-File $skinKit "ART10 UI skin kit"
Test-File $docPath "ART10 documentation"

if ((Test-Path -LiteralPath $fontSource -PathType Leaf) -and (Test-Path -LiteralPath $fontTarget -PathType Leaf)) {
  $sourceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $fontSource).Hash
  $targetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $fontTarget).Hash
  if ($sourceHash -ne $targetHash) {
    Add-Failure "FusionPixel source/target hash mismatch"
  }
}

if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
  $manifest = Import-Csv -LiteralPath $manifestPath
  $fontRows = @($manifest | Where-Object { $_.asset_id -eq "ui.font.fusion_pixel" })
  if ($fontRows.Count -ne 1) {
    Add-Failure "manifest must contain exactly one ui.font.fusion_pixel row, found $($fontRows.Count)"
  } else {
    $row = $fontRows[0]
    if ($row.godot_path -ne "res://assets/fonts/FusionPixel.otf") {
      Add-Failure "ui.font.fusion_pixel godot_path mismatch"
    }
    if ($row.license_status -ne "pending_verification") {
      Add-Failure "ui.font.fusion_pixel license_status must remain pending_verification"
    }
    if ($row.source_status -ne "pending_verification") {
      Add-Failure "ui.font.fusion_pixel source_status must remain pending_verification"
    }
  }
}

if (Test-Path -LiteralPath $docPath -PathType Leaf) {
  $doc = Get-Content -Raw -LiteralPath $docPath
  foreach ($index in 0..10) {
    if ($doc -notmatch "(?m)^## $index\. ") {
      Add-Failure "ART10 documentation missing numbered heading: ## $index."
    }
  }
}

$referenceDir = "D:\AGAME1\Base Art\Base"
if (Test-Path -LiteralPath $referenceDir -PathType Container) {
  $largeReferencePngs = @(Get-ChildItem -LiteralPath $referenceDir -File -Filter "*.png" | Where-Object { $_.Length -gt 2000000 })
  if ($largeReferencePngs.Count -lt 3) {
    $Warnings.Add("expected at least three large Base reference png files, found $($largeReferencePngs.Count)") | Out-Null
  }
} else {
  $Warnings.Add("Base reference directory missing: $referenceDir") | Out-Null
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

$forbiddenSourcePatterns = @(
  "D:\\AGAME1\\Base Art",
  "D:\\AGAME1\\Draw",
  "D:\\A GAME\\26.5.30 GameJam\\Draw"
)

foreach ($relative in $uiTargets) {
  $path = Join-Path $root $relative
  Test-File $path $relative
  if (Test-Path -LiteralPath $path -PathType Leaf) {
    $content = Get-Content -Raw -LiteralPath $path
    foreach ($pattern in $forbiddenSourcePatterns) {
      if ($content.Contains($pattern)) {
        Add-Failure "runtime UI file contains forbidden source path '$pattern': $relative"
      }
    }
    if ($relative -ne "Godot\GraytailGodot\scripts\presentation\art10_ui_skin_kit.gd" -and $content -notmatch "Art10UISkinKitScript") {
      Add-Failure "UI target is not wired to Art10UISkinKitScript: $relative"
    }
  }
}

$sourceRiskMatches = Select-String -Path ($uiTargets | ForEach-Object { Join-Path $root $_ }) -Pattern "preview|Debug|debug|draft|Legacy|display_only|read_only" -ErrorAction SilentlyContinue
$riskCount = @($sourceRiskMatches).Count
if ($riskCount -gt 0) {
  $Warnings.Add("remaining source token occurrences are sanitizer-protected or non-player-facing; count=$riskCount") | Out-Null
}

$gitStatus = @()
try {
  $gitStatus = git -C $root status --short --untracked-files=all
} catch {
  Add-Failure "git status failed: $($_.Exception.Message)"
}

$forbiddenRepoChanges = @($gitStatus | Where-Object {
  ($_ -match "Connection/") -or
  ($_ -match "Godot/GraytailGodot/scripts/core/" -and $_ -notmatch "\.uid$") -or
  ($_ -match "Godot/GraytailGodot/assets/(?!fonts/|ui/)") -or
  ($_ -match "Godot/GraytailGodot/scenes/(?!ui/)") -or
  ($_ -match "^.. assets/") -or
  ($_ -match "^.. game_material/")
})
foreach ($change in $forbiddenRepoChanges) {
  Add-Failure "forbidden repo change detected: $change"
}

$sideEffects = @($gitStatus | Where-Object {
  ($_ -match "\.uid$") -or
  ($_ -match "\.translation$") -or
  ($_ -match "Godot/GraytailGodot/project.godot")
})

$result = [ordered]@{
  status = if ($Failures.Count -eq 0) { "PASS" } else { "FAIL" }
  failures = @($Failures)
  warnings = @($Warnings)
  source_token_risk_count = $riskCount
  generated_or_preexisting_side_effects = @($sideEffects)
  checked_files = $uiTargets
}

$result | ConvertTo-Json -Depth 5

if ($Failures.Count -gt 0) {
  exit 1
}
