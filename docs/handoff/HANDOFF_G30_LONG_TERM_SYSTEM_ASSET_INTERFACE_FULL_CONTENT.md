# Handoff: G30 Long-Term System Asset Interface Full Content

Stage: G30-R2 Long-Term System Integration & Asset Interface Full Content Implementation.

Branch: `godot/g30-long-term-asset-interface-full-content`.

## What Changed

G30 adds the product contract and display-only Godot interface layer for LongTerm integration with the asset/reward/event surface.

Primary product contract:

- `docs/20_product/LONG_TERM_SYSTEM_ASSET_INTERFACE_FULL_CONTENT_CONTRACT.md`

Godot implementation areas:

- `Godot/GraytailGodot/scripts/core/asset/asset_domain_contract.gd`
- `Godot/GraytailGodot/scripts/core/settlement/settlement_snapshot_schema.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_config.gd`
- `Godot/GraytailGodot/scripts/ui/deploy_prep/deploy_prep_model.gd`
- `Godot/GraytailGodot/scripts/ui/long_term/`

Status / validation docs:

- `docs/10_current/CURRENT_STATE.md`
- `docs/10_current/CAPABILITY_MATRIX.yaml`
- `docs/00_governance/OPEN_DECISIONS.md`
- `docs/route_analysis/ROADMAP_G20_PLUS.md`
- `docs/INDEX.md`
- `docs/validation/G30_LONG_TERM_SYSTEM_ASSET_INTERFACE_FULL_CONTENT_VALIDATION.md`
- `Godot/GraytailGodot/docs/GODOT_CURRENT_STATUS.md`

## Implemented Content

- LongTerm six-module structure remains fixed: 目标 / 图鉴 / 研究 / 个人资历 / 抽奖 / 收藏 / 外观.
- Each module now carries module scope, secondary groups, cards, status chips, asset refs, RewardBundle preview, red_dot_policy, jump_targets, event flow preview, current landable scope, and deferred scope.
- AssetDomainContract now exposes read-only preview helpers for RewardBundle, ResourceEvent, ItemEvent, UnlockEvent, HistoryRecordEvent, ObjectiveEvent, red_dot_policy, and jump_target.
- Settlement snapshot preview includes RewardBundle and event-preview fields.
- DeployPrep config/model exposes the LongTerm asset-interface preview as a display-only consumer.
- LongTermShell shows a compact G30 interface summary without adding new action behavior.

## Boundaries

All new data is:

```text
preview_only
display_only
read_only
no_persistence
no_asset_write
no_reward_grant
```

G30 does not implement:

- real LongTerm backend
- real objective progress
- real reward claim/grant
- real gacha odds/roll/result
- real red dot clearing
- real profile progression
- real collection/cosmetic application
- real asset write
- real SaveManager
- real AssetLedger / RunAssetLedger mutation
- real CommandBus mutation
- gameplay runtime
- manual playtest

## Validation Record

- Static validation PASS.
- `git diff --check`: no whitespace error; LF/CRLF warnings only.
- Negative grep: safe hits only.
- Positive grep: G30 module/interface evidence present.
- Godot headless project-load / parser smoke PASS.
- Smoke produced no Godot metadata dirty side effects.

## Next Recommended Gate

Run unified G30-R3 audit / release confirmation. Do not merge main until that gate confirms branch state, remote state, validation record, and no forbidden path changes.
