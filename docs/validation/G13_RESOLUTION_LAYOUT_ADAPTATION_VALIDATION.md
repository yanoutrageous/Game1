# G13 Resolution Layout Adaptation Validation

- Date: 2026-06-13
- Stage: G13 Fixed Resolution Layout Adaptation
- Main baseline before G13-R3: `e90bd271ad2fc747051c9a49ff6a50c64e8fa49f`
- Main HEAD after G13-R3: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`
- Remote live main after G13-R3: `5afdb05fefe65031da1486507b0b39bdd2f1cea7`
- G13-R3 commit: `5afdb05 feat(godot): add fixed resolution layout support`
- G12 closeout commit: `e90bd27 docs: close G12 legacy demo parity pass`
- G12-R3 commit: `2855ca9 fix(godot): align G12 core loop readability with legacy demo`
- G11 closeout commit: `4be0010dd68abe1b0e74966775db64f736d78e15`
- G10 closeout commit: `aa19db2f1989c6ebfc22676d84b83da5c6977f64`

## Boundary

- G13 supports only fixed 16:9 tiers: `1280x720`, `1366x768`, `1600x900`, `1920x1080`, and `2560x1440`.
- G13 does not support arbitrary aspect ratios, mobile, ultrawide, 4K, full DPI parity, complete final UI, complete settings, Deploy persistence, MetaProgress, action combat, new gameplay, new resources, or full art migration.
- G13 display settings are runtime-only and do not write save data or local persistence.
- G13 should not modify `project.godot`; window resize locking is handled at runtime through `DisplayServer`.
- G13-R3 did not submit `project.godot`, resources, import products, font files, or the existing Godot dirty whitelist.
- G13 closeout is static-validation only and does not claim runtime PASS.

## Static Checks

Run after implementation from repository root:

```powershell
git diff --stat
git diff --check
git status --short
rg -n "e90bd27|G13|G12|G11|G10" docs Godot/GraytailGodot/docs
rg -n "1280x720|1366x768|1600x900|1920x1080|2560x1440" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
rg -n "resolution|window|resizable|DisplayServer|SettingsManager|UILayoutProfile|OptionButton|ScrollContainer|autowrap|minimum_size" Godot/GraytailGodot/scripts docs Godot/GraytailGodot/docs
rg -n "5afdb05|e90bd27|G13|G12|G11|G10|runtime PASS|Godot/editor/game/import|1280x720|1366x768|1600x900|1920x1080|2560x1440|DisplayServer|project.godot" docs Godot/GraytailGodot/docs
```

## G13-R3 Implementation Record

- G13-R3 completed and pushed at `5afdb05fefe65031da1486507b0b39bdd2f1cea7`.
- G13-R3 added the five fixed resolution tiers, runtime-only auto recommendation, runtime-only manual apply/reset, runtime resize locking, settings-page resolution controls, fixed-tier `UILayoutProfile` fields, and light layout adaptations for HUD, MiniMap, MapOverlay, Inventory, GroundLoot, and ResultPanel.
- G13-R3 updated this validation record and the manual playtest guide.
- Static checks covered diff/stat/check/status, fact grep, resolution-tier grep, UI/settings keyword grep, staged-range checks, and remote live main confirmation.
- G13-R3 did not run Godot/editor/game/import.
- G13-R3 did not submit `project.godot`, resources, import products, font files, or the existing Godot dirty whitelist.

## G13-R5 Closeout Record

- G13-R5 is docs-only closeout, handoff, and status alignment.
- G13-R5 does not continue feature development, UI repair, runtime/UI code changes, resource changes, import-product changes, font changes, or `project.godot` changes.
- G13 is complete, pushed, and closed after this docs-only closeout.
- Runtime behavior remains unverified in this record: DisplayServer window locking, five-tier runtime behavior, settings-page apply/reset behavior, and visual clipping still need later authorized runtime smoke or manual verification before any PASS claim.

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
