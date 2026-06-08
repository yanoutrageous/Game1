# AUDIT_G4_PLAYABLE_GRAYBOX_V0_1

## Scope

Audit of G3.5 runtime repair and G4 playable graybox v0.1 on branch `godot/lua-parity-p0`.

## Runtime Repair Audit

- Godot 4.6 type inference failures were repaired with explicit types and integer helper functions.
- Headless editor validation is required to pass without script errors.
- Runtime smoke validation is required to pass without script errors.
- Lua parity P0 validator remains required after the repair.

## Playable Graybox Audit

- Tutorial can be started from a player-facing `Start Tutorial 5x5` button.
- Standard can be started from a player-facing `Start Standard 10x10` button.
- Movement is available from W/A/S/D and arrow input.
- `E` searches normal/chest rooms, resolves event placeholders, and requests/confirms exit extraction.
- `Space` or `J` runs deterministic monster fight.
- `F` toggles flags.
- HUD exposes HP, Power, Pressure, Gold, Position, Room, Adjacent Mines, Search State, and Enemy/Event/Exit Hint.
- MiniMap renders public IntelMap cells with fallback text labels.
- ResultPanel exposes extracted, failed, or training complete summaries.

## Generated File Policy

- `.godot/` is not committed.
- `editor_data` is not committed.
- Cache/temp outputs are not committed.
- `.import` files are not committed by default.
- Script `.gd.uid` sidecars are treated as Godot project resource metadata, not cache.
- Godot-regenerated tracked translation resources are listed in the final self-check if present.

## Limits

- Event rooms remain placeholder interactions.
- Monster combat is deterministic command combat only.
- Real art asset migration is intentionally excluded.
- Full MetaProgress, action combat, and Deploy UI remain excluded.

## Result

G4 playable graybox v0.1 may be accepted only if static validators, headless editor, runtime smoke, and final Git scope checks pass.
