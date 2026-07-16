# ART21 Main Menu Motion Audit

Status: PASS; required ART21 motion, interaction feedback, and reduced-motion behavior are live and validated.

## Why the Earlier Motion Looked Unnatural

The first prototype advanced unrelated four-frame sheets on one fast clock.
Smoke, birds, leaves, flags, and other effects changed at the same instant, so
the scene read as a group of swapping textures rather than independent objects.
Several prototype sheets also replaced complete rectangular scene regions or
whole character poses while their static counterparts remained baked into the
background. Those two conditions caused the fast rhythm, visible popping, and
strong pasted-texture impression reported during review.

## Live Corrections

- The accepted composition is now represented by a master-matched clean plate.
  Character, menu boards, flag cloth, company banners, and flame cores are no
  longer baked into the live background.
- Character idle uses an eight-frame master-matched atlas on a common 190x216
  canvas. Every frame shares the same foot baseline. Holds in the 0.32-second
  sequence create a roughly 2.5-second breathing phrase instead of constant
  whole-body motion.
- Character focus uses stable directional poses: Deploy faces the dungeon and
  Long Term faces the company. Settings and Exit do not trigger location motion.
- Dungeon flag, main company banner, and side banners use separate ping-pong
  clocks at 0.32, 0.38, and 0.44 seconds. Their phases are not synchronized.
- Lantern flame cores use a local 0.22-second ping-pong loop while fixtures stay
  fixed. There is no full-lantern scale or position motion.
- Smoke uses a low-alpha 0.62-second cadence. Birds and leaves are occasional
  events with long rests rather than constant loops.
- Both location routes use a 1.10-second full-canvas code fade. The rectangular
  prototype masks and white-flash transition are not mounted.
- Utility focus uses a ring-free two-pixel code border fitted to the current
  board. The decorative hooks remain part of the board art and do not move.

## Deliberately Deferred Optional Polish

Puddle shimmer, whole-canopy motion, whole-ivy motion, full notice-paper motion,
and the two four-frame walking sheets remain unmounted. They are not required
for the complete ART21 interaction contract and would reintroduce sliding,
rectangular replacement, or unstable Chinese text. Future polish must use
highlight-only puddle art, local foliage tips, corner-only paper motion, or a
six-to-eight-frame walk with a verified cadence.

## Reduce-Motion Contract

Reduced motion freezes flags, banners, flames, and the character at their
stable first frame; hides smoke, birds, and leaves; and routes location
selection without the animated fade. Menu focus and overlay state remain clear.

The authoritative per-object disposition is recorded in
`main_menu_motion_contract.csv`.

## Verification Boundary

The user requested that no Computer Use validation run during this phase so the
computer remains available. Validation therefore uses background Godot tests,
hidden capture processes, and static image inspection. Final visual acceptance
is a manual user review of the versioned captures.
