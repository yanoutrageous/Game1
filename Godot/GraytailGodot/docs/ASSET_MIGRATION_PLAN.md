# Asset Migration Plan

## G5 Status

G5 migrates only audited repository-local assets into the Godot project. It does not copy videos, music, fonts, deploy UI, or unknown-license bulk folders.

## Godot Asset Layout

- `assets/ui/minimap`: player marker, unknown/scanned/explored cells, flag, room icons, number icons.
- `assets/ui/hud`: left panel, protocol panel, bottom bar, mine-risk tag, bar frame, warning bar.
- `assets/ui/common`: reusable dark button and gold icon.
- `assets/player`: default idle-facing player sprites.
- `assets/rooms`: normal, mine, chest, event, monster, exit room backgrounds.
- `assets/props`: chest, mine trap, gold pile props.

## Manifest Contract

`data/assets/asset_manifest.csv` remains compatible with the existing required columns:

- `asset_id`
- `godot_path`
- `usage`

G5 adds optional metadata columns for presentation mapping:

- `theme_key`
- `presentation_role`
- `state`
- `variant`
- `source_status`

Empty `godot_path` is allowed only when `replacement_needed=true`.

## Deferred

- Video files.
- Music and SFX except manifest placeholders.
- Fonts until license and import behavior are separately approved.
- Full Deploy UI asset set.
- Unknown-license or oversized temporary assets.
