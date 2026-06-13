# G12 Legacy Demo Core Loop Parity Validation

- Date: 2026-06-13
- Stage: G12 Legacy Demo Core Loop, Chinese Readability & Typography Parity
- Main baseline before G12-R3: `4be0010dd68abe1b0e74966775db64f736d78e15`
- G11 closeout commit: `4be0010dd68abe1b0e74966775db64f736d78e15`
- G11-R3 commit: `e261ac7d8671b59e7e72750122e6581af6ea6644`
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`

## Boundary

- G12 uses the old Demo as a core-loop and readability reference, not as a 1:1 remake target.
- G12 is not G10 or G11 continuation, and it does not start G13.
- G12 does not add new gameplay, new systems, full event library, persistence, action combat, full art migration, full UI rewrite, complete settings, complete diagnostics, or complete font system.
- G12 does not download, copy, add, or commit font files. Typography changes must use existing theme/color/font-size/line-spacing/tooltip/autowrap settings only.

## Static Checks

Run after implementation from repository root:

```powershell
git diff --stat
git diff --check
git diff --name-only
git status --short
rg -n "4be0010|e261ac7|G12|G11|G10" docs Godot/GraytailGodot/docs
rg -n "锛|鍑|鐨|鏈|绯|�|Ã|Click to open|Flagged cell|Unknown cell|Adjacent mines|Pressure:|Pending Gold|Last Action|Search complete|Monster cleared" Godot/GraytailGodot/scripts Godot/GraytailGodot/scenes
rg -n "MapOverlay|MiniMap|Inventory|GroundLoot|ResultPanel|protocol|danger|threat|reward|loot|settlement|font|theme|LabelSettings|tooltip" Godot/GraytailGodot/scripts Godot/GraytailGodot/docs docs
```

## Manual Checklist

Do not mark PASS unless a human or explicitly authorized runtime smoke actually plays the route.

- Main menu and deploy/tutorial entry are readable Chinese.
- MiniMap reads as a region scanner and click opens MapOverlay.
- MapOverlay scan/review text explains unknown, flagged, current, explored, and danger states.
- HUD shows Chinese labels for life, power, pending/safe currency, bag capacity, room, adjacent danger, search state, protocol level, pressure, phase, outcome, event/enemy/exit hint, and latest action.
- Event, chest, monster, normal search, mine, and exit feedback remains readable when reachable.
- Reward panel explains search/combat/event results, damage, currency, item count, floor loot, blocked reason, and roll.
- Inventory and GroundLoot explain capacity, empty state, item tooltip, pickup/drop, and `blocked_capacity`.
- ResultPanel explains success/failure settlement, salvage/loss, warehouse-lite movement, logs, and return paths.
- Dark-panel contrast, tooltip text, local font size, line spacing, and button text remain readable.

## Runtime / Import Record

- Godot/editor/game/import was not run during this static planning record.
- Do not claim runtime PASS unless a later authorized runtime/manual smoke records it.
- Known dirty whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
