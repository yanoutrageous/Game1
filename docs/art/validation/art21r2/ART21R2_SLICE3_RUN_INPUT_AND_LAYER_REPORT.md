# ART21R2 Slice 3 Run Input And Layer Report

Status: PARTIAL

This report covers the first ART21R2 execution slice applied after the baseline
lock. It does not mark the overall ART21R2 visual goal complete.

## Scope

- Preserve the existing main menu click flow: `Start Exploration` routes directly
  to Deploy Prep.
- Do not add area, map, or difficulty selection screens.
- Reduce meaningless in-run generated layers.
- Make HUD key prompts match keyboard behavior.
- Keep real `RoomLayer` / `PlayerLayer` world rendering from ART21R1.

## Code Changes

- `run_scene_input_router.gd`
  - Added `Q` -> inventory, `G` -> ground loot, and `T` -> request extract.
- `run_scene.gd`
  - Routed the new run actions to the existing inventory, ground loot, and extract
    UI handlers.
- `art10_ui_skin_kit.gd`
  - Added transparent button style helpers for image-backed hitboxes.
- `run_surface.gd`
  - Hid generated stat/backpack/status glow subpanels that were adding extra
    in-run layers.
  - Added image-backed `NinePatchRect` frames for the left information rail,
    top-right protocol card, and bottom action overlay.
  - Replaced the earlier ART21/shared frame mappings for those HUD regions with
    ART21R2 run-specific manifest assets.
  - Hid the visible `PanelContainer` backplates for the left rail, right status
    card, bottom action bar, and encounter prompt.
  - Changed bottom HUD action buttons to transparent hitboxes over the ART21
    bottom overlay image.
  - Removed bottom action button icons so the bottom bar reads as text/key
    prompts on the image strip rather than a row of large framed buttons.
  - Moved encounter option hitboxes out of the room center and into the lower
    prompt area.
  - Kept encounter option callbacks but suppresses the extra floating encounter
    `PanelContainer` backplate in the run HUD.
  - Removed the no-action placeholder panel; the encounter/action prompt is now
    hidden when there is no executable option.
- `map_overlay_panel.gd`
  - Removed generated Button `StyleBoxFlat` borders from map cells so the cell
    image assets own the visible boundary.
- `minimap_panel.gd`
  - Added a no-public-map fallback for the case where a `MiniMapViewModel`
    exists but exposes no public cells, preventing a blank rail without reading
    TruthMap or changing map rules.
  - Renders a full public-size minimap grid when width/height are available,
    filling undisclosed cells with unknown image tiles and mapping public/current
    markers to ART21 image assets without reading TruthMap.
  - Reuses manifest-backed draw-derived ART19 map64 assets for explored,
    scanned, current, exit, mine, and chest overlays instead of generating new
    minimap replacement art. Event remains on the existing ART21 generated
    marker because ART20 left `map_overlay_event_marker_64` blocked pending
    source selection.
  - Replaced the active HUD minimap explored/scanned/current/exit/mine/chest
    refs with ART21R2 32px runtime imports copied from
    `sources/draw/30_game_ready/icons/32` and recorded in the external
    `ART-21R2/_manifest/minimap_hud_cut_manifest.csv`.
- `ART21R2_DRAW_SLICE_AUDIT.md`
  - Records the draw-source purple-background scan and the ART19R1 / ART20
    slicing precedent that ART21R2 should reuse before any new art generation.

## Evidence

| Evidence | File | Result |
| --- | --- | --- |
| Window click path | `screenshots/slice3/godot_deploy_prep_after_slice3.png` | Main menu click reached Deploy Prep directly; no extra area/map/difficulty screen was inserted. |
| Logic main menu | `screenshots/slice3/godot_main_menu_after_slice3_logic.png` | Full 1280x720 viewport reference after code changes. |
| Logic deploy prep | `screenshots/slice3/godot_deploy_prep_after_slice3_logic.png` | Full deploy prep remains the direct target screen. |
| Logic long term | `screenshots/slice3/godot_long_term_after_slice3_logic.png` | Long-term page captured for family comparison; still not visually complete. |
| Logic run HUD | `screenshots/slice3/godot_run_hud_after_slice3_logic.png` | No no-action floating placeholder; real room/player layer preserved. |
| Logic Q inventory | `screenshots/slice3/godot_inventory_q_after_slice3_logic.png` | Inventory opens from the run screen. |
| Logic map overlay | `screenshots/slice3/godot_map_overlay_after_slice3_logic.png` | Map cells use image-backed hitboxes without generated Button borders. |
| Logic run HUD pass4 | `screenshots/slice3/godot_run_hud_after_slice3_image_boundary_pass4_logic.png` | Generated PanelContainer backplates are hidden for left/right/bottom HUD regions; image NinePatch frames own the visible boundary. |
| Logic Q inventory pass4 | `screenshots/slice3/godot_inventory_q_guard_after_slice3_pass4_logic.png` | Inventory route guard still works; inventory modal remains visually partial and overlaps the left rail. |
| Logic map overlay pass4 | `screenshots/slice3/godot_map_overlay_guard_after_slice3_pass4_logic.png` | Map overlay still opens after the HUD frame changes; modal remains visually partial. |
| Logic minimap fallback pass5 | `screenshots/slice3/godot_run_hud_after_slice3_minimap_fallback_pass5_logic.png` | Blank minimap state now shows an explicit no-public-map fallback; live tile readability remains unproven. |
| Logic run HUD pass6 | `screenshots/slice3/godot_run_hud_after_slice3_art21r2_asset_pass6_logic.png` | ART21R2 run-specific frame assets are manifest-backed and visible; the old center floating encounter backplate is gone. Still PARTIAL because left edge color and bottom text contrast remain weak. |
| Logic run HUD pass7 | `screenshots/slice3/godot_run_hud_after_slice3_art21r2_asset_pass7_logic.png` | Godot import now resolves the ART21R2 frame textures at runtime; the fallback green terminal edge is gone and key text is visible again. Still PARTIAL because minimap public-cell evidence and disabled key contrast remain below target. |
| Logic run HUD pass10 | `screenshots/slice3/godot_run_hud_after_slice3_minimap_public_grid_pass10_logic.png` | Standard run start path renders a full 10x10 minimap with image tiles and a current-cell marker. Still PARTIAL because tile scale/contrast remains below final UE floor. |
| Logic run HUD pass14 | `screenshots/slice3/godot_run_hud_after_slice3_minimap_draw_overlay_pass14_logic.png` | Standard run start path renders the full 10x10 public minimap and the current marker uses manifest-backed draw-derived ART19 map64 overlay assets. Still PARTIAL because minimap density/contrast and the bottom command strip remain below the UE floor. |
| Logic run HUD pass16 smoke | `screenshots/slice3/godot_run_hud_after_slice3_minimap_hud32_pass16_smoke.png` | Restarted Godot after import and confirmed the current marker renders from ART21R2 32px draw-derived HUD minimap assets rather than text fallback. Still PARTIAL because this is 856x511 smoke evidence and the 10x10 minimap remains dense. |
| Direct Deploy pass26 smoke | `screenshots/slice3/godot_after_start_explore_direct_deploy_prep_pass26_q_input_check.png` | Main menu `Start Exploration` still routes directly to Deploy Prep; no extra area/map/difficulty screen was inserted. |
| Run HUD before Q pass26 smoke | `screenshots/slice3/godot_run_hud_before_q_inventory_pass26_smoke.png` | Standard Deploy Prep -> Start Exploration path enters the live Run HUD before keyboard input validation. |
| Q inventory pass26 smoke | `screenshots/slice3/godot_run_hud_q_inventory_open_pass26_smoke.png` | Pressing `Q` in the live Run HUD opens Inventory. Input route PASS; Inventory modal remains visually partial/terminal-like. |
| M map pass26 smoke | `screenshots/slice3/godot_run_hud_m_map_open_pass26_smoke.png` | Pressing `M` after closing Inventory opens Map Overlay. Input route PASS; Map modal/cells remain visually partial and below the UE floor. |

## Current Verdict

PASS for this slice:

- `Q` now opens inventory.
- `G` and `T` are routed to their existing UI handlers.
- Main menu deploy route remains direct to Deploy Prep.
- The no-action in-run placeholder panel is removed.
- Map cell generated Button borders are removed.
- R1 duplicate fake room/player layer guards remain intact.
- Left/right/bottom HUD code backplates are hidden in the active layout, with
  image-backed frames owning those boundaries.
- The minimap rail no longer collapses to an unexplained blank when the view
  model has no public cells.
- The pass7 Run HUD capture confirms that the ART21R2 frame assets resolve at
  runtime after import, removes the extra floating encounter backplate, and keeps
  encounter buttons and callbacks routed through the existing code path.
- The pass10 Run HUD capture uses the standard run start path and proves that
  the left rail can render a public 10x10 minimap grid with current-cell marker
  from `MiniMapViewModel`/`IntelMap` data rather than TruthMap.
- The pass14 Run HUD capture confirms that the current-cell overlay can use
  existing draw-derived runtime assets from the manifest without adding generated
  replacement minimap art or reading TruthMap.
- The pass16 smoke capture confirms that the new ART21R2 32px HUD minimap
  runtime assets load after Godot import and render in the live Run HUD instead
  of falling back to text.
- The pass26 smoke captures confirm the current keyboard routes: `Q` opens
  Inventory and `M` opens Map Overlay from the live Run HUD without changing the
  main menu -> Deploy Prep flow.

PARTIAL for the larger ART21R2 target:

- Run HUD still reads below the UE visual floor. The latest pass16 smoke capture
  (`screenshots/slice3/godot_run_hud_after_slice3_minimap_hud32_pass16_smoke.png`)
  confirms the 32px draw-derived player marker loads in runtime, but minimap
  density/contrast and disabled key contrast still do not reach the target.
- MiniMap readability is still not complete. The pass16 smoke capture proves the
  live public grid path with 32px HUD imports, but the grid still needs layout,
  contrast, or dedicated state-art polish before it can be considered UE-floor.
- Bottom key text is less noisy and more legible, but still weak compared with
  the UE command strip target.
- Inventory modal opens but overlaps the left HUD rail and still uses generated
  row/button treatment.
- The pass26 `Q` capture proves the input route works, but the Inventory modal
  still reads like a terminal panel and is not a visual pass.
- The pass26 `M` capture proves the map input route works, but the Map Overlay
  still reads as a generated modal/button grid rather than UE-floor map art.
- Deploy Prep and Long Term remain mostly baseline visual quality after this
  slice.
- Main menu active path is superseded by Slice 2's physical plank-board pass,
  but that pass is still PARTIAL because text/icon fit and title integration
  remain unfinished.

## Validation

- Godot headless: exit code `0`; pre-existing resource-leak warnings still appear
  on exit.
- Godot import: required once for the new ART21R2 PNG files so `ContentDB` does
  not fall back to older terminal-frame assets; generated `.import` and `.godot`
  cache files remain uncommitted side effects.
- Godot import: required again for the ART21R2 32px minimap runtime PNG files;
  before import they fell back to text, after import pass16 shows the player
  marker image in the live Run HUD.
- Computer Use pass26 smoke: 856x511 evidence only. It validates Q/M input
  routing and direct Deploy Prep flow, not final 1280/1600/1920 visual QA.
- Draw slice audit: `ART21R2_DRAW_SLICE_AUDIT.md` records that large
  purple-background draw sheets must be sliced/cleaned through the earlier
  ART19R1 / ART20 process before runtime use. No generated replacement minimap
  art is introduced by the pass14 minimap change.
- `tools/validate_art21r2_image_boundary_ui.ps1`: expected to remain
  `PASS_STRUCTURAL_OPEN`, not visual closeout.
