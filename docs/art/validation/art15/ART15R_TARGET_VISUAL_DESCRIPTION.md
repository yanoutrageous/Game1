# ART-15R Target Visual Description

## 0. Document Position

ART-15R is a visual layer and layout rework after ART-15. It does not add new gameplay rules, does not move original art sources, and does not import directly from Base Art or Draw at runtime.

This document records the target visual direction before code changes. The target must be judged from three sources together:

- Existing runtime asset wiring in `asset_manifest.csv`, `PresentationMapping`, and ART-15 UI code.
- Current ART-15 screenshots in `docs/art/validation/art15/`.
- Base confirmed mockups and the user-provided flipped HUD sketch.

## 1. Existing Asset Correspondence Status

Existing asset correspondence has been partially organized, but it has not yet been fully translated into page composition.

Confirmed runtime-side asset groups:

- `ui_main_menu`: no-text main menu background is registered and used.
- `ui_deploy_button`, `ui_deploy_icon`, `ui_deploy_panel`: deploy buttons, icons, highlight frame, main panel, and summary panel are registered.
- `ui_key_prompt`: E / ESC / F / M / Q / T key prompts are registered.
- `ui_icon` and `ui_badge`: minimap and resource icons are registered.
- `ui_panel`: HUD and terminal panel textures are registered.
- `ui_feedback`: event prompt and dark/red feedback bars are registered.
- `ui_result`: extraction title plates are registered.
- `sprite.player.*`: four player idle sprites are registered.
- `room_background`: room backgrounds for normal, mine, chest, event, monster, and exit are registered.
- `item_consumable`, `item_equipment`, `item_recovered`, `prop`: item and prop runtime assets are registered.

Current gap:

- Several pages still rely on dark panel blocks and text structure instead of composing the registered assets into the intended layout.
- Character / hero display areas mostly use geometric placeholders instead of available player sprite assets.
- HUD has room background, minimap, key prompts, feedback, and item assets, but current layout still compresses the playable room with left and right information columns.
- Inventory and ground loot still appear as overlays inside the run HUD context rather than independent, readable item containers.

## 2. Base Confirmed Mockup Targets

### Main Menu

Target:

- Full-bleed menu atmosphere should be visible.
- Left / center should contain a convincing hero or base-entry display area, not a transparent placeholder stack.
- Right side should keep large, readable entry buttons.
- Top shortcuts and bottom key bar should remain compact.
- Announcement text should be short and separated from navigation.

Current ART-15 failure:

- Large dark narrative frames hide the background and make the screen feel like a debug panel.
- The hero block is still a transparent rectangle composition.
- Some labels and bottom hints still read like implementation notes rather than player-facing UI.

### Deploy Prep

Target:

- Follow the Base confirmed deploy composition: left character / readiness area, large central route or mission selection area, fixed right summary, and a prominent gold start button.
- The central area must be visually dominant.
- Right summary should be split into compact modules: route, loadout, consumables, risk, reward.
- Existing deploy icons and deploy panel assets should be visible and meaningful.

User flipped layout reference:

- Left column contains return/detail and long-term buttons at top, a large character display in the middle, and settings/action affordance near the bottom.
- Center column contains large top category blocks, a second row of smaller filters, a large scrollable content area, a lower detail page, and a reclaim/collect footer.
- Right column contains top equipment/status slots, a large blank summary/preview field, mid-lower continue/stop buttons, and a large start-game action.
- This means deploy prep and long-term should not collapse into text-heavy cards; they should share a strong product layout family with visible slots and a large central content region.

Current ART-15 failure:

- The page has the rough left / center / right split, but the center is still mostly text cards.
- Right panel contains dense and partially internal-looking strings.
- The left character area is still a placeholder block.
- Asset-backed buttons and panels exist but do not yet create the target productized composition.

### Long Term

Target:

- Use the same productized family as deploy prep: left profile/archive area, large central collection or record grid, fixed right detail panel.
- Center cards should use icon/title/state rather than paragraphs.
- Right details should be short modules instead of a document-like text stack.
- The page should read as an archive room / collection wall, not a technical shell.

Current ART-15 failure:

- The layout is closer than earlier stages, but still sparse and shell-like.
- The left archive profile remains mostly text and placeholder geometry.
- Center cards are too small and do not carry enough visual weight.
- Right detail is still a sequence of compact panels rather than a confident product UI.

## 3. User Flipped HUD Reference Target

The user-provided flipped HUD image is the current authoritative run HUD sketch.

Target structure:

- Left fixed narrow column:
  - top: small map.
  - middle: HP / combat power / black coin / gold.
  - bottom: backpack entry, explicitly openable later by click or interaction.
- Center:
  - largest screen area, reserved for the room and live interaction.
  - item prompts should appear near the interactable object, not only inside side logs.
  - item prompt structure should include item name and pickup / use interaction area.
- Right top:
  - compact protocol / pressure / partial influence card.
  - no full-height right information column.
- Bottom:
  - main menu return button and partial operation shortcut keys.
  - key bar should not squeeze the central room.

Current ART-15 failure:

- Current HUD still has a full-height right info column.
- The room is visually squeezed by fixed left and right panels.
- Inventory and ground loot screens are effectively HUD overlays, not clean item pages.
- The map overlay darkens the entire room too strongly.

## 4. Map Overlay Target

Target:

- Map overlay should expand the map or region scan without turning the whole game view into a black debug sheet.
- The room should remain contextually visible underneath.
- Map information should be clearly layered above the room with readable boundaries.
- The overlay should not reuse the full right-column HUD structure as its main composition.

Current ART-15 failure:

- The overlay darkens almost the whole screen and makes the room hard to read.
- It still keeps too much of the current HUD column structure visible.

## 5. Inventory And Ground Loot Target

Target:

- Inventory should be reachable as a clear item container, not only a text note in the left HUD column.
- Ground loot should show item cards near the run context with icon/name/action affordance.
- Both screens should use existing item icon mappings where available.
- They should remain visually compatible with HUD, but should not look like debug overlays.

Current ART-15 failure:

- Inventory and ground loot screenshots still show the run HUD underneath as the dominant composition.
- Item interaction is visible, but the container hierarchy is not productized enough.

## 6. ART-15R Work Priorities

1. Use existing registered runtime assets before adding anything new.
2. Replace placeholder character blocks with available `sprite.player.*` where practical.
3. Rebuild deploy prep and long-term first because both share the left / center / right product layout.
4. Rebuild run HUD and map overlay using the flipped HUD reference as the target layout.
5. Fix main menu, inventory, and ground loot after the shared visual structure is stable.
6. Validate with 1280x720 screenshots first, then 1600x900 and 1920x1080 for core screens.

## 7. Non-Goals

- No direct runtime reads from Base Art or Draw.
- No direct use of confirmed full-screen mockups as runtime backgrounds.
- No gameplay core, command, save, TruthMap, RunContext, or CommandBus semantic changes.
- No return-main, long-term, or exit-run click behavior implementation for M4-only interactions.
- No commit or push in the execution frame.

## 8. User Layout Correction After Initial Description

The later user-provided flipped references supersede the earlier rough HUD ratio. The current execution target is:

- Deploy prep and long-term use the same product layout family:
  - left column is only character / appearance display.
  - equipment, consumables, level, mainline, resources, and action buttons belong to the right fixed column.
  - top primary tabs sit in the center top and must not consume the right column.
  - secondary filters must stay in one row or behave like a horizontal strip; they must not wrap and shrink the detail/content area.
  - continue / abandon buttons sit above the large start button.
  - avoid oversized empty areas by raising the right column content and enlarging the actual center content region.
- Long-term specifically keeps a left character appearance area with a visible appearance-settings affordance, a middle archive / collection wall, and a fixed right archive column for level, mainline, qualifications, resources, and claimable rewards.
- Run HUD is not a three-column scanner/status layout:
  - left column is about 30%.
  - the remaining about 70% is the main playable room area except for bottom operation strips.
  - the protocol / pressure area is only a small top-right occluding card over the room, not a full right rail.
  - the center / right playable area must not remain mostly empty or gray; it must be room / object / interaction visual space.

Implementation note:

- These are layout proportions and visual responsibilities, not hardcoded final art-image dimensions.
- Future new art should be adjusted through manifest, PresentationMapping, and Skin Kit layout specs rather than direct Base Art / Draw paths or per-image coordinates.
