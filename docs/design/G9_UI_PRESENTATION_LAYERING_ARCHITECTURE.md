# G9 UI Presentation Layering Architecture

## Summary

G9 revises the UI art direction from background theme switching into a low-coupling presentation layer stack: a fixed base background plus independent overlay layers. The base background provides a stable base-space composition. Map themes, character outfits, props, atmospheric effects, foreground effects, and panel skins are layered through Presentation Overlay contracts.

This stage does not implement the full UI shell, import real art, or change gameplay rules. It defines the architecture, schemas, and validation boundary that later UI and art branches can consume.

## Layer Stack

1. Base Background Layer
   - Fixed base-space background.
   - Provides stable composition and large spatial anchors.
   - Does not contain map-specific information, character outfits, UI state, or gameplay state.
   - Can be replaced in a major visual revision, but should not change per map.

2. Theme Overlay Layer
   - Selected by `theme_id` or `map_id`.
   - Represents map atmosphere such as color grade, lighting, fog, ruins, mine warmth, or lab cold light.
   - Carries presentation only and never decides gameplay.

3. Scene Prop Overlay Layer
   - Selected by map, task, event phase, or base presentation state.
   - Examples include flags, crates, map markers, instruments, warning signs, and distant props.
   - Supports multiple entries, visibility toggles, and z-order changes.

4. Character Layer
   - Left-side character display.
   - Driven by `character_id`, `outfit_id`, `pose_id`, and `equipment_overlay_ids`.
   - Not baked into the base background.

5. Character Overlay Layer
   - Cosmetics, outfit pieces, equipment visuals, and status effects.
   - Reserved for later personal outfit work.
   - Does not implement a complete outfit system in this stage.

6. Foreground FX Layer
   - Particles, fog, edge light, warning flashes, and protocol atmosphere.
   - Can react to theme, risk level, or expedition state.
   - Does not participate in gameplay checks and can be reduced or hidden.

7. UI Panel Layer
   - Main page, expedition page, long-term page, right summary, center panel, and top tabs.
   - Panels must not depend on details baked inside a background image.
   - Expanding or collapsing the center panel changes occlusion and visible area only.

8. Popup / Tooltip Layer
   - Popups, item tooltips, blocked reasons, confirmations, and tutorial blockers.
   - Always above ordinary panels.
   - Decoupled from background and character layers.

## Contract Interfaces

`ThemeProfile` fields:

```text
theme_id
schema_version
display_name_key
base_background_id
color_grade_id
lighting_overlay_id
ambient_vfx_ids
prop_overlay_ids
foreground_overlay_ids
panel_skin_id
map_icon_theme_id
risk_overlay_policy
fallback_theme_id
tags
deprecated_state
```

`PresentationLayerEntry` fields:

```text
layer_id
schema_version
kind
asset_id
fallback_asset_id
z_index
anchor
offset
scale
opacity
blend_mode
tint
parallax_factor
visibility_condition
interactive
blocks_input
occlusion_policy
reduction_group
tags
deprecated_state
```

`CharacterPresentationConfig` fields:

```text
character_id
schema_version
display_name_key
base_sprite_id
portrait_id
default_pose_id
available_pose_ids
outfit_overlay_ids
equipment_overlay_ids
status_overlay_ids
anchor
scale
fallback_character_id
tags
deprecated_state
```

`OutfitPresentationDef` fields:

```text
outfit_id
schema_version
character_id
display_name_key
overlay_asset_ids
slot
rarity
unlock_condition
compatible_pose_ids
tags
deprecated_state
```

`PanelState` fields:

```text
page_id
panel_id
expanded_state
last_selected_tab
compact_mode
summary_mode
remember_state
animation_profile_id
```

`UIVisibilityPolicy` fields:

```text
policy_id
page_id
entry_id
visible
compact_allowed
dev_only
reduction_group
unlock_condition
priority
```

`NavigationEntry` fields:

```text
entry_id
schema_version
label_key
icon_id
page
target_panel
category
is_primary
is_visible
unlock_condition
sort_order
dev_only
```

`ShortcutEntry` fields:

```text
shortcut_id
schema_version
source_page
target_page
target_panel
label_key
icon_id
is_pinned
priority
last_used_sequence
visibility_condition
```

`ExpeditionSummaryViewModel` fields:

```text
loadout_items
consumables
capacity_current
capacity_max
run_effects
risk_warnings
blocked_reason
tracked_objective
recommended_route
theme_id
```

`LongTermSummaryViewModel` fields:

```text
profile_level
profile_exp
next_reward
permanent_bonus
task_progress
codex_progress
achievement_progress
research_progress
tracked_objective
```

The contract-only GDScript stub is `Godot/GraytailGodot/scripts/presentation/presentation_layer_contracts.gd`. It provides schema fields, placeholder examples, and helper constants only. It does not extend `Node`, register an Autoload, preload or load resources, use `FileAccess`, write `user://`, or connect to any scene.

## Relation To G8.2 Protocols

- Core gameplay provides semantic IDs such as `map_id`, `theme_id`, `character_id`, `outfit_id`, `panel_state`, `risk_level`, and `tracked_objective_id`.
- Presentation resolves semantic IDs into `ThemeProfile`, `PresentationLayerEntry`, and character presentation contracts.
- UI reads only ViewModel/snapshot data and dispatches CommandBus commands for state changes.
- Quick navigation can change page or panel focus, but equipment changes, expedition confirmation, item operations, and other gameplay changes must use Command / CommandResult.
- Presentation contracts must not read or write `RunContext`, `RunAssetLedger`, `TruthMap`, or MetaProgress internals.

## Relation To Three-Page UI

- Main page: routing hub, stable base background, primary navigation, character stage, and compact summaries.
- Expedition page: loadout, consumables, route/risk summary, theme preview, and right-side `ExpeditionSummaryViewModel`.
- Long-term page: task, codex, achievement, profile, and research shell through `LongTermSummaryViewModel`.

The central panel can expand or collapse without changing gameplay state. Expanded panels prioritize readability. Collapsed panels expose more background, theme overlays, character, and props.

## Future Art Import

This stage imports no real art. Later art integration should only add or replace:

- `asset_id`
- resource path definitions inside the asset catalog or equivalent art registry
- layer config
- `ThemeProfile`
- `CharacterPresentationConfig`
- panel skin definitions

Art import must not rewrite core rules, rebuild the main background for every map, or bypass Command / Query protocols.

## UI Reduction

Every overlay, entry, shortcut, and summary should be reducible through:

- `reduction_group`
- `compact_allowed`
- `summary_mode`
- `visibility_condition`

If the UI becomes too dense, later branches should hide, fold, or downgrade layers and entries instead of redesigning the whole screen.

## Non-Goals

- No full UI shell navigation.
- No complete main page, expedition page, or long-term page.
- No real art import.
- No complete background switching.
- No complete character system or outfit system.
- No complete Inventory, GroundLoot, or Settlement UI.
- No full MetaProgress.
- No Deploy persistence.
- No action combat.
- No new gameplay content.
