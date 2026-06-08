# MANUAL_PLAYTEST_GUIDE

## Start Tutorial 5x5

1. Open the main scene or run the project.
2. Select `Start Tutorial 5x5`.
3. Move with W/A/S/D or arrow keys.
4. Press E to search, interact, request extraction, and confirm extraction.
5. Press Space or J to fight a monster room.
6. Press F to flag the current cell.

## Tutorial Recommended Route

From spawn `(0,0)`, use this route to exercise the loop:

```text
(0,0) -> (0,1) -> (0,2) -> (0,3) -> (0,4) -> (1,4) -> (2,4) -> (3,4) -> (4,4)
```

Expected coverage:

- Number hint near mines.
- Mine trigger with non-fatal damage.
- Event placeholder.
- Monster fight.
- Chest search.
- Exit extraction and training complete result.

## Start Standard 10x10

1. Select `Start Standard 10x10`.
2. Explore with W/A/S/D or arrow keys.
3. Use E on normal/chest/event/exit rooms.
4. Use Space or J on monster rooms.
5. Continue until a random exit is discovered, then use E twice to request and confirm extraction.

## Standard Smoke Route

Because the map is generated from a fixed seed, the exact route can be replayed once discovered. For smoke testing, verify:

- The map is 10x10.
- HP, Power, Pressure, Gold, Position, Room, Adjacent Mines, and Search State update.
- MiniMap expands with movement.
- Monster fight resolves deterministically.
- ResultPanel appears after extraction or failure.

## Known limits

- Event behavior is a placeholder.
- Monster combat is deterministic command combat, not action combat.
- Real art assets are not migrated.
- Full MetaProgress and Deploy UI are not part of this stage.
