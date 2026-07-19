# ART24R2 UE layout realignment plan

Status: implementation baseline

Reference authority:

- UE prototype: `D:/AGAME1/external/ue_prototype/UE/Graytail`
- Godot production code remains the functional source of truth.
- The legacy Godot presentation is not an acceptance reference for ART24.

## Objective evidence

| Area | UE prototype | Rejected Godot baseline | Correction |
|---|---:|---:|---|
| Combat room | logical 560 x 560 | 440 x 410 | one 560 x 560 authority rect for actors, collision and props |
| Player | 64 px slot in 560 px room | about 30 px visible height | about 60-64 px visible height, collision unchanged |
| Left rail | 430 px at UE design size, dense map/status/bag hierarchy | 23% rail but large dead lower area | retain responsive width; rebuild internal density and backpack block |
| Protocol | compact top-right stack | tall 232 px card | compact 220 x 166 standard card |
| Bottom hints | 720 x 40 | nearly full gameplay width, 68-82 px | centered 720 x 48 maximum strip with compact key hints |
| Expanded map | fullscreen 70% dim, ScaleToFit grid, 54 px logical cells | broad generic modal with small grid | fullscreen scan composition, approximately 500-540 px grid at 720p |
| Final result | 380 px content, 300 x 130 banner, summary, two actions | wide four-card dashboard | narrow UE-style battle report; metrics move into compact summary copy |

## Functional boundaries that must survive

- Player movement, collision, combat, chest, ground pickup and contextual prompt remain program-owned.
- Unknown map-cell flagging, explored-cell recall and close controls remain usable.
- Success, final failure and abandonment use the same result hierarchy with distinct state treatment.
- Failure salvage selection remains a dedicated pre-final result state. Capacity blocking and confirmation cannot be removed.
- Existing monster variants remain available.
- Layout metrics and asset paths are centralized so later art replacement does not require gameplay edits.

## Execution sequence

1. Freeze the UE-derived visual acceptance metrics.
2. Align combat geometry, character scale and HUD bands.
3. Align expanded map composition.
4. Align success/failure/abandon result composition while retaining salvage.
5. Run two focused visual optimization passes without changing the information structure.
6. Run automated layout/runtime regression.
7. Perform Computer Use acceptance against the frozen criteria.
8. Only after a full pass, clean generated files, commit and push.
