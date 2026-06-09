# G5 Asset UI Parity Audit

## Audited Asset Sources

- `assets/Textures/generated/icons/32`
- `assets/ui/hud`
- `assets/ui/common`
- `assets/Textures`
- `assets/Textures/generated/props`

## Migrated Godot Targets

- `Godot/GraytailGodot/assets/ui/minimap`
- `Godot/GraytailGodot/assets/ui/hud`
- `Godot/GraytailGodot/assets/ui/common`
- `Godot/GraytailGodot/assets/player`
- `Godot/GraytailGodot/assets/rooms`
- `Godot/GraytailGodot/assets/props`

## Deferred Sources

- Videos.
- Music and SFX assets except manifest placeholders.
- Fonts.
- Deploy UI.
- Unknown-license bulk assets.

## Boundary Audit

- Core rule scripts do not load textures or hard-code asset file paths.
- UI scripts do not directly read TruthMap.
- IntelMap exposes public semantics; PresentationMapping assigns display metadata.
