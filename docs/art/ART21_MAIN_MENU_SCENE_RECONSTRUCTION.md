# ART21 Main Menu Scene Reconstruction

Status: closed; implementation, runtime evidence, static visual QA, and repository validation passed.

## Goal

ART21 reconstructs the complete scene-based main menu while preserving the
existing routes. Earlier ART21 placement-contract and ART21R1 parity work are
supporting slices of this same stage, not later stages.

## Live Scene Architecture

The live 1280x720 composition uses a master-matched clean plate plus small,
independently controlled overlays:

1. clean environment plate with the accepted dungeon/company composition;
2. engine-rendered title, notice copy, and four menu labels;
3. layered character idle/focus art with a stable contact shadow;
4. four independent menu-board textures and invisible hit areas;
5. flag, banner, flame, smoke, bird, and leaf motion groups;
6. dungeon/company focus linkage and full-canvas route fades;
7. settings and exit overlays under the shared UI layer contract.

The accepted composite remains versioned as evidence but is not mounted at
runtime. This avoids both the former collage seams and duplicate baked objects.
The title, notice text, and menu copy are never burned into raster assets.

## Runtime Asset Contract

- Generated runtime assets: 152 PNG files.
- Canonical handoff-derived assets: 122.
- Master-matched menu-board states: 16.
- Master-matched character idle/focus frames: 12.
- Master-matched clean plate: 1.
- Accepted composite evidence master: 1.
- Conservative live/interaction-reachable decoded texture load: 10.40 MiB.
- Default-load asset rows: 66; evidence-only master rows: 1; explicitly
  deferred/unmounted rows: 85.
- Every runtime row records source crop, runtime rect, anchor, pivot, z-layer,
  consumer, load group, and mount status.
- Source identity and every output are recorded by SHA-256.
- Reports contain no personal absolute source path.

The audited builder is `tools/art21_build_main_menu_runtime.py`. It requires
the explicit source pack, clean plate, character atlas, and menu-board atlas.
Generated runtime assets live under
`Godot/GraytailGodot/assets/ui/art21/main_menu/scene/`.

## Interaction Coverage

- `出发探索` is the primary left-pointing entry and preserves the deploy route.
- `长期系统` is a non-directional rectangular company entry and preserves the
  long-term route.
- `设置` opens the settings overlay.
- `退出游戏` opens the exit confirmation overlay.
- F1/F2 shortcuts, keyboard focus neighbours, mouse focus, pressed states, and
  reduced-motion behavior remain covered by the runtime runner.

## Motion Coverage

Character breathing, blink, tail/ear variation, location focus response,
dungeon flag, company banners, lantern flame cores, smoke, travelling birds,
occasional leaves, menu feedback, two route fades, settings overlay, and exit
confirmation are live. Puddles, full foliage replacement, whole-paper motion,
and four-frame walking prototypes remain optional and intentionally unmounted.
See `docs/art/validation/art21/ART21_MAIN_MENU_MOTION_AUDIT.md`.

## Closeout Result

The runtime runner, asset/hash validator, placement contract, navigation
boundary, UI layering, ART20 pipeline, ART21R1 structural regression, six fresh
captures, sidecar exclusion, and `git diff --check` passed. Generated Godot
`.import`, `.uid`, and `.translation` side effects are absent from ART20/ART21
runtime asset directories. Unrelated editor rewrites of `project.godot` and
compiled translation files were removed from this stage's diff.

The user requested that this phase not use Computer Use. Closeout therefore
uses the already-produced background runtime evidence, versioned screenshots,
static image inspection, and repository validators. Computer Use is not a
closeout dependency for this stage.
