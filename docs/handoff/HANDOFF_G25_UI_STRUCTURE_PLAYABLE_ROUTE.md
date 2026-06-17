# Handoff G25 UI Structure Playable Route

## Summary

G25 UI Structure Stabilization & Playable Route Recovery is complete on branch `godot/g25-ui-structure-playable-route`.

- Implementation commit: `ae6f2ab6abd50b51c6f8f600cb8f5cda1cda7462`.
- Static validation PASS.
- Godot headless project-load/parser smoke PASS.
- Godot smoke produced no new dirty side effects.
- `D:\AGAME1\Connection\Program\G25_UI_Structure_Stabilization_Notice.md` was written outside the repository and is not committed.

## What Changed

- MainMenu now has an explicit `快速开始 / Demo Run` current playable route entry.
- The route uses existing AppShell / NavigationIntent / PageRouter run routing and does not modify run rules.
- DeployPrep remains preview-only and explains that full deploy configuration start is not wired.
- DeployPrep and LongTerm display surfaces use clipped / summarized / scrollable presentation to reduce overlap and raw data dumps.
- Settings remains a placeholder and clearly says the full settings system is not implemented.

## Non-Goals

G25 does not implement real warehouse, reward, settlement, gacha, objective, red-dot, SaveManager, asset writing, LongTerm backend, settings backend, or art import systems.

No gameplay runtime PASS or manual playtest PASS is claimed.

## Next

After main merge, the next step should be G25 audit/evaluation or a separately authorized G26 original audit. Do not infer new feature scope from the G25 route recovery.
