# ART24R2 UE layout Computer Use acceptance criteria

Frozen ID: `ART24R2-UE-LAYOUT-CU-FROZEN-1`

Frozen before the next Computer Use completion audit. These criteria supersede the rejected visual baseline in `ART24R2_FINAL_COMPUTER_USE_ACCEPTANCE_CRITERIA.md`; functional state coverage from that document still applies.

## Reference and viewport

- Visual reference: `D:/AGAME1/external/ue_prototype/UE/Graytail/Source/Graytail/UI`.
- Primary audit viewport: 1280 x 720.
- Layout probes must also pass at 1366 x 768, 1600 x 900, 1920 x 1080 and 2560 x 1440.
- No element may clip, overlap another primary band, or create an unintended second interaction layer.

## A. In-run composition

- The combat authority rect is square and presents approximately 560 x 560 logical pixels at the primary viewport.
- The player's visible standing height is 58-66 px at the primary viewport (roughly 10-12% of the combat room height). Collision radius is unchanged.
- The character, monsters, props, hit effects and contextual prompts share the same room authority rect.
- Left rail width remains responsive at approximately 23% (292-430 px), but its map, status and backpack blocks form a continuous hierarchy without a large unexplained blank lower half.
- Protocol information is a compact top-right stack, no taller than 180 px at 1280 x 720.
- The bottom hint strip is centered under the combat room, no wider than 720 px and no taller than 50 px at 1280 x 720. It reads as one hotbar, not seven unrelated large buttons.
- The combat room remains the dominant visual area; HUD bands must not make it look like filler.

## B. Expanded map

- Opening the map creates a fullscreen dimmed scanning layer, not a generic centered window.
- The 10 x 10 grid is the dominant element and occupies at least 500 x 500 px including gaps at 1280 x 720.
- Title is centered above the grid. Selection/status and control hints are centered below it and do not reduce the grid below the minimum.
- Overview, selected cell, flag/unflag, explored-cell recall feedback, combat-blocked recall and close all remain readable and operable.

## C. Result states

- Success, final failure and abandonment use a narrow centered report with an approximately 380 px content column.
- A prominent state banner is approximately 300 x 130 px and is visually dominant over body copy.
- Final states show a compact centered summary and two primary actions. The former four-card dashboard is not present.
- Success, failure and abandonment are distinguishable by banner, frame/accent and copy hierarchy without moving the main controls.
- Failure salvage pending is a dedicated pre-final state. Candidate selection, selected state, capacity-disabled state and confirm action all remain visible and usable; completing it transitions to the final failure report.

## D. Motion and transitions

- Opening/closing map and showing result preserves input blocking and does not leak clicks to the room.
- Existing panel-open motion is retained or improved, with reduced-motion behavior preserved.
- Player idle/walk/attack/hurt frames remain animated and visually stable at the corrected scale.

## E. Completion gate

- Automated ART24 map, result, run-surface and G41 runtime probes pass.
- Every applicable primary/secondary state in the ART24 matrix is checked in the running Godot build using Computer Use.
- Any failure reopens implementation. ART24 is complete only after the full Computer Use audit passes this frozen standard.
