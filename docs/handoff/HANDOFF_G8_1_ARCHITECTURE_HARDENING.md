# Handoff: G8.1 Architecture Hardening

## Current State

- Branch: `godot/g8-1-architecture-hardening`
- Base G8 closure commit: `717728087eea2bdabd3a9c031b0f2698cdb5737e`
- Remote: `https://github.com/yanoutrageous/Game1.git`

## Implemented

- Read-only query/snapshot boundary through `RunQueryFacade`.
- RuleResult and EffectSpec helpers in `RunRuleService`.
- Asset effect application through `RunAssetEffectHandler`.
- Minimal rule content fallback through `RunRuleContent`.
- Command envelope normalization in `CommandBus`.
- Contract-only persistence boundaries through `SaveAdapter` and `MetaProgressAdapter`.
- HUD ViewModel snapshot consumption path.
- G8.1 static validation.

## Verification Commands

Run from repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_project_structure.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_parity_p0.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_playable_graybox_v0_1.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_ui_parity_g5.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_playable_parity_g6.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_lua_ux_flow_parity_g7.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_asset_rules_g8.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Godot\GraytailGodot\tools\validate_architecture_hardening_g8_1.ps1
```

## Next Work Guidance

- Future UI work should consume snapshots/ViewModels and dispatch CommandBus commands only.
- Future skills/events should first emit EffectSpec dictionaries, then route asset effects through `RunAssetEffectHandler`.
- Future MetaProgress/Deploy persistence should attach through these adapter boundaries in a later stage and must not make UI or ledger write `user://` directly.
