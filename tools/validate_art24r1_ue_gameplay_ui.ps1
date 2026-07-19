param(
    [string]$RepoRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$failures = New-Object System.Collections.Generic.List[string]

function Add-Failure([string]$Message) {
    $script:failures.Add($Message) | Out-Null
}

function Require-File([string]$Path) {
    if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot $Path))) {
        Add-Failure "missing file: $Path"
    }
}

function Require-Pattern([string]$Path, [string]$Pattern, [string]$Label) {
    $fullPath = Join-Path $RepoRoot $Path
    if (-not (Test-Path -LiteralPath $fullPath)) {
        Add-Failure "missing file: $Path"
        return
    }
    $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
    if ($content -notmatch $Pattern) {
        Add-Failure "missing evidence: $Label in $Path"
    }
}

$requiredFiles = @(
    "docs/art/ART24R1_UE_PARITY_GAMEPLAY_REWORK_PLAN.md",
    "docs/validation/ART24R1_PRODUCTION_FLOW_DIAGNOSTIC_CRITERIA.md",
    "docs/validation/ART24R1_INITIAL_COMPUTER_USE_AUDIT.md",
    "docs/validation/ART24R1_FINAL_COMPUTER_USE_ACCEPTANCE_CRITERIA.md",
    "docs/validation/ART24R1_FINAL_COMPUTER_USE_AUDIT.md",
    "Godot/GraytailGodot/scripts/gameplay/loot/g41_ground_loot_entity.gd",
    "Godot/GraytailGodot/scripts/gameplay/runtime/g41_runtime_layout.gd",
    "Godot/GraytailGodot/scripts/ui/loot_result/loot_result_panel.gd",
    "Godot/GraytailGodot/assets/art24/ui/modal_frame.png",
    "Godot/GraytailGodot/assets/art24/ui/map_frame.png",
    "Godot/GraytailGodot/assets/art24/ui/left_rail.png",
    "Godot/GraytailGodot/assets/art24/ui/bottom_bar.png",
    "Godot/GraytailGodot/assets/art24/fx/pickup_beam_0.png",
    "Godot/GraytailGodot/assets/art24/actors/player/down_idle_a.png",
    "Godot/GraytailGodot/assets/art24/actors/player/down_walk_a.png",
    "Godot/GraytailGodot/assets/art24/actors/player/down_walk_b.png"
)

foreach ($file in $requiredFiles) {
    Require-File $file
}

Require-Pattern "Godot/GraytailGodot/project.godot" 'run/main_scene\s*=\s*"res://scenes/main/main\.tscn"' "production main scene"
Require-Pattern "Godot/GraytailGodot/scripts/core/run/run_scene.gd" 'LootResultPanelScript.*loot_result_panel\.gd' "production loot result panel preload"
Require-Pattern "Godot/GraytailGodot/scripts/core/run/run_scene.gd" 'G41RoomRuntimeViewScript.*g41_room_runtime_view\.gd' "G41 production room runtime preload"
Require-Pattern "Godot/GraytailGodot/scripts/core/run/run_scene.gd" 'room_runtime_view\.configure_room\(snapshot\)' "G41 room snapshot binding"
Require-Pattern "Godot/GraytailGodot/scripts/core/run/run_scene.gd" 'replace_item_requested' "real replace action wiring"
Require-Pattern "Godot/GraytailGodot/scripts/core/run/run_scene.gd" '_direction_from_key_event|move_local\(step_direction' "visible movement input bridge"
Require-Pattern "Godot/GraytailGodot/scripts/gameplay/player/player_controller.gd" 'walk_cycle.*idle_a.*walk_a.*walk_b.*idle_b' "four-stage movement cycle"
Require-Pattern "Godot/GraytailGodot/scripts/gameplay/player/player_controller.gd" 'set_room_rect|place_from_entry|_transition_for_next_pos' "room-local movement and transition"
Require-Pattern "Godot/GraytailGodot/scripts/gameplay/runtime/g41_room_runtime_view.gd" '_sync_ground_loot|room_floor_items' "G41 snapshot-driven world loot spawning"
Require-Pattern "Godot/GraytailGodot/scripts/gameplay/loot/g41_ground_loot_entity.gd" 'PickupBeam|pickup_beam_|base_value' "G41 world loot art binding"
Require-Pattern "Godot/GraytailGodot/scripts/gameplay/runtime/g41_runtime_layout.gd" 'ROOM_RECT|local_to_world' "shared production-space layout authority"
Require-Pattern "Godot/GraytailGodot/scripts/ui/loot_result/loot_result_panel.gd" 'show_result' "loot result entry point"
Require-Pattern "Godot/GraytailGodot/scripts/ui/loot_result/loot_result_panel.gd" '_add_item_card' "UE-style loot result item hierarchy"
Require-Pattern "Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd" 'ScrollContainer' "ground loot scroll layout"
Require-Pattern "Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd" 'pickup_item_requested' "ground loot pickup action"
Require-Pattern "Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd" 'replace_item_requested' "ground loot replace action"
Require-Pattern "Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd" 'ScrollContainer' "inventory scroll layout"
Require-Pattern "Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd" 'use_item_requested' "inventory use action"
Require-Pattern "Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd" 'drop_item_requested' "inventory drop action"
Require-Pattern "Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd" 'assets/art24/ui/map_frame\.png|map_tile_' "ART24 full map presentation"
Require-Pattern "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd" 'assets/art24/ui/left_rail\.png|assets/art24/ui/bottom_bar\.png|_apply_ue_readability_tokens' "UE-oriented HUD presentation"

$runtimeRoots = @(
    "Godot/GraytailGodot/scripts/core/run/run_scene.gd",
    "Godot/GraytailGodot/scripts/gameplay/player/player_controller.gd",
    "Godot/GraytailGodot/scripts/gameplay/loot/g41_ground_loot_entity.gd",
    "Godot/GraytailGodot/scripts/gameplay/runtime/g41_runtime_layout.gd",
    "Godot/GraytailGodot/scripts/ui/loot_result/loot_result_panel.gd",
    "Godot/GraytailGodot/scripts/ui/ground_loot/ground_loot_panel.gd",
    "Godot/GraytailGodot/scripts/ui/inventory/inventory_panel.gd",
    "Godot/GraytailGodot/scripts/ui/map_overlay/map_overlay_panel.gd",
    "Godot/GraytailGodot/scripts/ui/run_surface/run_surface.gd"
)

foreach ($relative in $runtimeRoots) {
    $fullPath = Join-Path $RepoRoot $relative
    if (-not (Test-Path -LiteralPath $fullPath)) {
        continue
    }
    $externalPath = Select-String -LiteralPath $fullPath -Pattern 'D:\\UE|D:\\AGAME1\\external|yanoutrageous/Game' -AllMatches
    if ($externalPath) {
        Add-Failure "runtime contains external reference path: $relative"
    }
}

$runSceneContent = Get-Content -LiteralPath (Join-Path $RepoRoot "Godot/GraytailGodot/scripts/core/run/run_scene.gd") -Raw -Encoding UTF8
if ($runSceneContent -match 'WorldLootPresenter|world_loot_presenter') {
    Add-Failure "duplicate legacy world loot presenter remains beside G41 runtime"
}

$forbiddenSpecs = @(
    ":(glob)Godot/GraytailGodot/**/*.translation",
    ":(glob)Godot/GraytailGodot/**/*.import",
    ":(glob)Godot/GraytailGodot/**/*.uid",
    ":(glob)Godot/GraytailGodot/.godot/**"
)
$forbiddenDiff = git -C $RepoRoot diff --name-only -- $forbiddenSpecs
foreach ($path in $forbiddenDiff) {
    Add-Failure "forbidden generated metadata diff: $path"
}

$untracked = git -C $RepoRoot ls-files --others --exclude-standard
foreach ($path in $untracked) {
    if ($path -match '^Godot/GraytailGodot/.*\.(translation|import|uid)$' -or $path -match '^Godot/GraytailGodot/\.godot/') {
        Add-Failure "forbidden untracked generated metadata: $path"
    }
}

if ($failures.Count -gt 0) {
    Write-Host "ART24R1_UE_GAMEPLAY_UI_VALIDATION=FAIL"
    foreach ($failure in $failures) {
        Write-Host "FAIL: $failure"
    }
    exit 1
}

Write-Host "ART24R1_UE_GAMEPLAY_UI_VALIDATION=PASS_STRUCTURAL"
Write-Host "Production route, movement, UE-oriented HUD, loot result, world loot, inventory/ground loot, map and metadata boundaries are present."
