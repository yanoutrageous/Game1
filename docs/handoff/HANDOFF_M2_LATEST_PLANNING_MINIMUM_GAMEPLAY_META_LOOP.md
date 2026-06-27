# Handoff M2 Latest Planning Minimum Gameplay & Meta Loop

中文摘要：M2 将 M1 可玩闭环对齐到最新策划案的最小可玩链路，并为后续阶段留下清晰边界。

## Implemented

- DeployPrep model now routes start intent to `standard_run`.
- RunFlow start intent preview documents existing `standard_10x10` route bridge.
- RunResult snapshot is surfaced as `settlement_input`.
- Fast return command uses TruthMap `return_eligibility`.
- Minimap view model derives explored/returnable cells from eligibility.
- `standard_10x10` registers a minimum search reward modifier.
- RulePipeline exposes limited numeric modifier deltas.
- Search reward applies modifier delta before ledger effects.
- LongTerm shell/model consumes MetaProgress and latest result display-only.
- M2 validation script added.
- M2 headless minimum loop runner added for standard route, modifier, return eligibility, and RunResult/settlement input regression.

## Boundary

- No `demo_7x7`.
- No Objective / Reward / Pool expansion.
- No full LongTerm, warehouse, equipment, consumable, Rule Engine, content pool, or active-run persistence rewrite.
- No UI save writes.
- No result UI reward recalculation.
- No metadata, scene, resource, or art import changes intended for this stage.

## Known Repository Condition

Pre-existing Godot-generated metadata/project dirty may exist in the worktree. It must remain unstaged and uncommitted unless a separate metadata gate authorizes it.

## Next Gate

Recommended next step: M2 validation / commit gate with strict allowlist staging after Godot smoke confirms parser safety.
