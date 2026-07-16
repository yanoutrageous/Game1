# ART21 Main Menu Scene Reconstruction Closeout

Status: CLOSED / PASS

## 中文结论

ART21“主菜单场景全量重构”已经完成。Godot 中的主菜单已从通用面板式 UI
替换为场景式界面：左侧地牢与“灰尾回收”招牌、公告牌和浣熊主角，右侧公司
建筑与四个入口均已落地。中文文字由引擎渲染；角色、木牌、旗帜、横幅和灯火
使用 clean plate 上的独立图层；导航、设置覆盖层、退出确认、最小动效和减少动效
契约均保留。按用户要求，本次关闭不使用 Computer Use。

## Requirement Audit

| Gate | Evidence | Result |
| --- | --- | --- |
| Scene assembled in Godot | `MainMenuShell` mounts the clean plate, engine labels, layered character, four boards, focus linkage and ten motion groups | PASS |
| Required visible content | Dungeon, title sign, notice board, character, company and exactly four entries are present in the captures and runtime runner | PASS |
| Legacy generic menu removed | Dedicated validator rejects the old action deck, top summary, role panel and meta frame | PASS |
| Navigation and confirmation unchanged | Deploy / Long Term / Settings / Exit targets, `requires_confirm`, F1/F2 and AppShell routing are covered by runtime and G39 checks | PASS |
| Runtime asset contract | 152 unique rows with source crop, runtime asset, rect, anchor, pivot, z-layer, consumer, load group, hash and mount status | PASS |
| Source/fallback boundary | Accepted composite is evidence-only; 85 unused assets are explicit `deferred_not_mounted`; source atlases are not runtime consumers | PASS |
| Texture budget | 66 live/interaction-reachable rows decode to 10.40 MiB; gate 128 MiB, target 96 MiB | PASS |
| Multi-resolution visual QA | 1280x720 default/Long Term/settings/exit plus 1600x900 and 1920x1080 default captures | PASS |
| Interaction and minimum motion | Focus/hover/pressed offsets, character idle/focus, flags, banners, flames, smoke, birds, leaves, fades and reduced-motion fallbacks | PASS |
| Repository scope | Isolated worktree only; no commit/push; no runtime import sidecars; unrelated `project.godot` and compiled translation rewrites removed | PASS |

## Runtime and Asset Summary

- Runtime root: `Godot/GraytailGodot/assets/ui/art21/main_menu/scene/`
- Runtime assets: 152 PNG files.
- Live or interaction-reachable rows: 66.
- Explicitly deferred/unmounted rows: 85.
- Accepted composite evidence rows: 1.
- Conservative default decoded memory: 10,906,816 bytes / 10.40 MiB.
- All runtime output hashes and dimensions are in
  `docs/art/validation/art21/main_menu_runtime_asset_report.csv`.
- Placement and mount metadata are in
  `docs/art/validation/art21/main_menu_runtime_asset_contract.csv`.
- Motion disposition is in
  `docs/art/validation/art21/main_menu_motion_contract.csv`.

## Validation Results

| Check | Result |
| --- | --- |
| `Godot/GraytailGodot/tests/art21_main_menu_runtime_runner.gd` | `ART21_MAIN_MENU_RUNTIME=PASS entries=4 overlays=2 transitions=2 shortcuts=2 motion_groups=10` |
| `tools/validate_art21_main_menu_scene.ps1` | PASS |
| `tools/validate_art21_ui_placement_contract.ps1` | PASS |
| `tools/validate_art20_ui_asset_pipeline.ps1` | PASS |
| `tools/validate_art21r1_ue_parity.ps1` | `PASS_STRUCTURAL` |
| `tools/validate_g39_navigation_boundary.ps1` | PASS |
| `tools/validate_art17_core_screen_layering.ps1` | PASS |
| `git diff --check` | PASS |

The ART21R1 script continues to describe historical UE-parity floor work as
partial; its structural check passes and its unrelated screen-level residuals
do not contradict the completed ART21 main-menu reconstruction.

## Runtime Captures

- [1280x720 default / Deploy focus](validation/art21/art21_main_menu_1280x720_default.png)
- [1280x720 Long Term focus](validation/art21/art21_main_menu_1280x720_long_term.png)
- [1280x720 settings overlay](validation/art21/art21_main_menu_1280x720_settings.png)
- [1280x720 exit confirmation](validation/art21/art21_main_menu_1280x720_exit.png)
- [1600x900 default](validation/art21/art21_main_menu_1600x900_default.png)
- [1920x1080 default](validation/art21/art21_main_menu_1920x1080_default.png)

Static visual inspection passed for text clipping, checkerboard/separator
residue, transparent-edge contamination, duplicate architecture, menu direction
semantics, character scale, critical entrance visibility, and 16:9 framing.

## Non-blocking Future Polish

The current puddle sheet, whole-canopy/ivy sheets, full-paper motion and legacy
four-frame walk sheets remain intentionally unmounted. They may be replaced by
highlight-only puddles, local foliage tips, corner-only paper movement and
six-to-eight-frame route walks in a later explicitly named stage. They are not
required for ART21 closure and do not create hidden runtime dependencies.

## Publish Audit (2026-07-16)

- The local branch base and
  `origin/art/art21r1-ue-parity-existing-assets` both resolve to
  `3dbb843e34f16a9a10b7122a0e094c457a7057c6`; no upstream divergence was found.
- The dedicated ART21 scene and placement validators, ART20 pipeline regression,
  ART21R1 structural regression, G39 navigation boundary, ART17 layering,
  Python builder compilation, sidecar exclusion and `git diff --check` passed.
- Godot had regenerated 203 `.import` files under the ART20/ART21 runtime asset
  roots. They were verified as generated sidecars, removed, and the asset gates
  were rerun successfully.
- One `project.godot` rewrite and seven compiled asset-manifest translation
  rewrites are local Godot 4.6 editor side effects. They are not ART21 changes,
  were not modified by the audit, and are excluded from the publish scope.
- ART21 remains the latest closed art stage. Per project-stage authority, I0 is
  the latest closed non-art stage; the active and closed indexes now state this
  without fabricating I0 evidence that is not present on this branch.
- The audit did not use Computer Use or launch Godot.

## Verification Policy

The user explicitly disabled Computer Use for this phase. No Computer Use
acceptance claim is made, and the closeout does not depend on it.
