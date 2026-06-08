$ErrorActionPreference = 'Stop'

$ProjectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)

$RequiredFiles = @(
    'project.godot',
    'scenes/main/main.tscn',
    'scenes/run/run_scene.tscn',
    'scenes/room/room_scene.tscn',
    'scenes/ui/hud/hud.tscn',
    'scenes/ui/minimap/minimap_panel.tscn',
    'scenes/ui/result/result_panel.tscn',
    'scenes/player/player.tscn',
    'scenes/interactables/chest_placeholder.tscn',
    'scenes/interactables/exit_beacon_placeholder.tscn',
    'scripts/core/run/game_kernel.gd',
    'scripts/core/run/run_context.gd',
    'scripts/core/map/truth_map.gd',
    'scripts/core/intel/intel_map.gd',
    'scripts/core/map/minefield_service.gd',
    'scripts/core/run/room_resolver.gd',
    'scripts/core/command/command_bus.gd',
    'scripts/core/content/content_db.gd',
    'scripts/core/settings/settings_manager.gd',
    'scripts/ui/minimap/minimap_view_model.gd',
    'scripts/ui/hud/hud_view_model.gd',
    'scripts/ui/minimap/minimap_panel.gd',
    'scripts/ui/hud/hud.gd',
    'scripts/ui/result/result_panel.gd',
    'scripts/gameplay/player/player_controller.gd',
    'scripts/gameplay/rooms/room_scene_controller.gd',
    'scripts/gameplay/interactables/chest_placeholder.gd',
    'scripts/gameplay/interactables/exit_beacon_placeholder.gd',
    'data/assets/asset_manifest.csv',
    'docs/ASSET_IMPORT_RULES.md',
    'docs/ASSET_TRANSFER_T0_CHECKLIST.md',
    'docs/ASSET_ID_NAMING.md',
    'docs/GODOT_READY_FOR_ASSET_TRANSFER.md'
)

$Failures = @()

foreach ($RelativePath in $RequiredFiles) {
    $FullPath = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $RelativePath))
    if (-not ($FullPath -eq $ProjectRoot -or $FullPath.StartsWith($ProjectRoot + [System.IO.Path]::DirectorySeparatorChar))) {
        $Failures += "outside project: $RelativePath"
        continue
    }

    if (-not [System.IO.File]::Exists($FullPath)) {
        $Failures += "missing: $RelativePath"
    }
}

if ($Failures.Count -gt 0) {
    Write-Output 'PROJECT_STRUCTURE_VALIDATION=FAIL'
    foreach ($Failure in $Failures) {
        Write-Output $Failure
    }
    exit 1
}

Write-Output 'PROJECT_STRUCTURE_VALIDATION=PASS'
Write-Output "PROJECT_ROOT=$ProjectRoot"
Write-Output "CHECKED_FILES=$($RequiredFiles.Count)"
