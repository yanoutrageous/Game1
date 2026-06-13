# G13 Resolution Layout Adaptation Validation

- Date: 2026-06-13
- Stage: G13 Fixed Resolution Layout Adaptation
- Main baseline before G13-R3: `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f`
- G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`
- G11 closeout commit: `4be0010dd68abe1b0e74966775db64f736d78e15`
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`

## Boundary

- G13 supports only fixed 16:9 tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.
- G13 does not support arbitrary aspect ratios, mobile, ultrawide, 4K, full DPI parity, complete final UI, complete settings, Deploy persistence, MetaProgress, action combat, new gameplay, new resources, or full art migration.
- G13 display settings are runtime-only and do not write save data or local persistence.
- G13 should not modify `project.godot`; window resize locking is handled at runtime through `DisplayServer`.

## Static Checks

Run after implementation from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "e90bd27|G13|G12|G11|G10" docs Godot/GraytailGodot/docs
rg -n "1280x720|1366x768|1600x900|1920x1080|2560x1440" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
rg -n "resolution|window|resizable|DisplayServer|SettingsManager|UILayoutProfile|OptionButton|ScrollContainer|autowrap|minimum_size" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
```

## Manual Checklist

Do not mark PASS unless a human or explicitly authorized runtime smoke actually plays the route.

- First startup or auto reset chooses the largest supported tier that fits the current display area.
- Display areas smaller than `1280x720` use `1280x720` and show a minimum-resolution notice.
- Settings page lists only the five supported tiers.
- Applying each tier updates the window size and the displayed status.
- Restore automatic recommendation returns to the best supported tier.
- Window drag resize is disabled; unsupported aspect ratios are not available.
- `1280x720` and `1366x768` keep HUD, MiniMap, MapOverlay, Inventory, GroundLoot, ResultPanel, tooltips, and Chinese text readable.
- `1600x900` and `1920x1080` keep standard UI density readable.
- `2560x1440` keeps text and spacing readable without starting 4K support.

## Runtime / Import Record

- Godot/editor/game/import was not run during this static implementation record.
- Do not claim runtime PASS unless a later authorized runtime/manual smoke records it.
- Known dirty whitelist: tracked `project.godot`, tracked/untracked `asset_manifest.*.translation`, and untracked `*.gd.uid`.
