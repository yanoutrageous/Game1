# Handoff: G18-align Deploy Prep Asset Attendance View

## Summary

G18-align-R2 updates the existing DeployPrep foundation so it matches the deploy-prep design direction more closely without turning it into a complete expedition, warehouse, or asset system.

Implemented scope:

- five fixed primary tabs: 地图 / 仓库 / 申领 / 出勤配置 / 作业许可
- display-only secondary labels for each tab
- asset-attendance card list and card detail preview
- warehouse attendance draft actions: 加入出勤 / 移出出勤 / 穿戴 / 卸下
- requisition preview for 补给 / 服务 / 情报 / 基础装备
- loadout preview for equipped items, carried consumables, permits, services, preset/reset wording
- permit preview for unlocked / locked / enabled / capacity / effect summary
- right-side 摘要 / 配置 / 效果 / 风险 output
- start / continue / abandon preview states with strong-confirmation wording for abandon
- read-only deploy prep projection shape through G21 `AssetProjectionSchema`

## Non-Goals

This branch does not implement:

- complete deploy prep
- complete warehouse
- real inventory mutation
- real asset event write
- event bus
- reward grant or claim
- persistence
- gacha
- settlement or history
- red dot
- real run start, continue, or abandon
- full RunScene changes
- G22

## Code Boundary

Modified code should stay inside:

- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_tab_model.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_shell.gd`

The branch must not modify:

- `Godot/GraytailGodot/scripts/core/run/**`
- `Godot/GraytailGodot/scripts/core/command/**`
- `Godot/GraytailGodot/scripts/core/content/asset_catalog.gd`
- `Godot/GraytailGodot/scripts/core/run/run_asset_ledger.gd`
- `Godot/GraytailGodot/scripts/ui/long_term/**`
- `Godot/GraytailGodot/project.godot`
- scenes, resources, imports, `.uid`, `.translation`
- Base Docs originals
- external wrong Godot path

## Validation Status

G18-align-R2 static validation should confirm:

- approved file set only
- no forbidden dependency strings in deploy prep or app shell code
- positive evidence for tabs, secondary labels, cards, right summary, strong confirmation, and projection preview
- no project or resource side effects

Godot was not run in R2. Parser smoke is deferred to the next acceptance round.

## Next Step

Recommended next step is G18-align acceptance / parser-smoke round, not G22 and not main merge. G22 remains not started.
