# Handoff G34 Rule / Effect / Modifier & Content Delivery Common System

## Summary

G34-R2 lands the common schema / preview layer for rules, effects, modifiers, and content delivery. It gives map, room, encounter, RunFlow, settlement, RunSurface, HUD, and future Objective / Reward / Pool stages a shared read-only vocabulary.

## Key Files

- `Godot/GraytailGodot/scripts/core/rules/rule_effect_modifier_schema.gd`
- `Godot/GraytailGodot/scripts/core/content/content_delivery_schema.gd`
- `Godot/GraytailGodot/scripts/core/run/run_rule_pipeline.gd`
- `Godot/GraytailGodot/scripts/core/run/run_rule_service.gd`
- `Godot/GraytailGodot/scripts/core/run/run_query_facade.gd`
- `Godot/GraytailGodot/scripts/core/run/run_flow_state_contract.gd`
- `Godot/GraytailGodot/scripts/core/settlement/settlement_snapshot_schema.gd`
- `Godot/GraytailGodot/scripts/ui/run_surface/run_surface_model.gd`
- `Godot/GraytailGodot/scripts/ui/hud/hud_view_model.gd`

## Contract Fields

- RuleDefinition / RuleTrigger / RuleCondition / RuleContextSnapshot
- TargetSelector / ApplicabilityCheck / ScopePolicy
- EffectDescriptor / EffectPreview / EffectResultPreview
- ModifierProfile / ModifierStackPreview / ModifierConflictPolicy
- ContentPool / ContentEntry / ContentSelector / ContentDeliveryContext
- PoolResultPreview / FallbackPolicy / DeliveryRollPreview

## Boundaries

- `preview`: true
- `display_only`: true
- `read_only`: true
- `no_persistence`: true

No new real reward grant, drop runtime, objective progression, map mutation runtime, SaveManager persistence, CommandBus mutation, or AssetLedger / RunAssetLedger long-term write is introduced by G34.

## Validation

- Static validation: PASS.
- Godot headless project-load/parser smoke: PASS.
- Godot smoke produced no metadata dirty side effects.
- This is not gameplay runtime PASS and not manual playtest PASS.

## Recommended Next Gate

Run a unified G34-R3 audit / release gate. Future Objective / Reward / Pool subscription work should use these preview contracts but remain a separately audited stage.
