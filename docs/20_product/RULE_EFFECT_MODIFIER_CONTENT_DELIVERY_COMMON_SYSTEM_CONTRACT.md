# G34 Rule / Effect / Modifier & Content Delivery Common System Contract

## 中文摘要（DOC-GOV-001）

G34 记录规则、效果、Modifier 与内容投放通用系统的 preview / display-only 内容。它说明 RuleDefinition、RuleTrigger、EffectDescriptor、EffectPreview、ModifierProfile、ContentPool、ContentEntry、DeliveryRollPreview 等公共预览结构；不实现完整规则引擎、脚本语言、AI Director、真实奖励/掉落、目标进度、地图 runtime mutation、持久化、AssetLedger / RunAssetLedger 长期写入、CommandBus mutation、gameplay runtime PASS 或 manual playtest PASS。

本摘要只解释既有英文 contract 内容，不新增玩法规则，不扩大验证结论。


G34 implements the foundation contract for the common rule, effect, modifier, and content delivery layer. The primary planning source is the read-only Base Docs file `规则、效果、Modifier 与内容投放通用系统策划案.md`.

This stage is a schema / preview / adapter foundation. It is not a complete Rule engine runtime, not a reward runtime, not a drop runtime, not objective progression, and not persistence.

## 1. Stage Positioning

- Establish shared vocabulary for map, room, encounter, RunFlow, settlement, and later Objective / Reward / Pool consumers.
- Keep all new surfaces `preview`, `display_only`, `read_only`, and `no_persistence`.
- Allow limited adapters around existing run-local rule services so current results can expose summary previews.
- Do not expand `CommandBus`, `AssetLedger`, `RunAssetLedger`, SaveManager, scene/resource loading, or persistence.

## 2. Rule Contract

`RuleDefinition` describes a declarative rule identity and preview surface:

- `RuleTrigger`: trigger channel, deterministic seed reference, source context.
- `RuleCondition`: condition id, required context keys, filter reason, blocked reason.
- `RuleContextSnapshot`: run id, room type, room tags, encounter type, map/runflow/settlement refs, objective/reward/pool/modifier placeholders.
- `TargetSelector`: target scope and selected target preview.
- `ApplicabilityCheck`: ok / blocked reason / filter reason.
- `ScopePolicy`: allowed scope, and explicit false flags for asset writes, reward grant, objective advance, and map mutation.

G34 does not implement a scripting language, expression engine, nested rule chain, or AI Director.

## 3. Effect Contract

`EffectDescriptor` describes an effect identity and payload preview. `EffectPreview` and `EffectResultPreview` expose display summaries:

- effect label and effect type
- blocked reason
- resource / item / objective / map mutation preview buckets
- result preview, not runtime mutation

Existing run-local effects may still execute through older code paths. G34 only adds summary fields around those results; it does not change their gameplay semantics.

## 4. Modifier Contract

`ModifierProfile` and `ModifierStackPreview` reserve:

- source, scope, duration, priority, layer, stack rule
- conflict tags
- remove condition preview
- affected target preview
- applied modifier preview

`ModifierConflictPolicy` records priority, layering, conflict, suppression, and replacement policies as preview-only vocabulary. G34 does not implement a complete conflict solver.

## 5. Content Delivery Contract

`ContentPool`, `ContentEntry`, `ContentSelector`, and `ContentDeliveryContext` describe content delivery without issuing drops or rewards.

`PoolResultPreview` and `DeliveryRollPreview` reserve:

- deterministic seed and roll index
- selected ids
- blocked entries
- fallback state and fallback reason
- filter reasons
- applied modifier record

`FallbackPolicy` returns empty preview results when no candidate is available. It never grants items, currency, objectives, or gacha results.

## 6. Cross-System Alignment

G34 aligns with earlier foundations:

- G33 `RoomRulePreview`, `RoomCondition`, and `RoomResolutionPreview` may reference rule/effect/modifier/content previews.
- G32 `RunFlowSnapshot`, `SettlementTriggerPreview`, and `RunOutcomePreview` reserve rule/effect/modifier/content delivery context fields.
- G31 map / room snapshots remain the context source for room type and known state.
- Settlement receives only effect/result and content pool summary preview fields.
- RunSurface / HUD show rule labels, modifier counts, pool source, blocked reason, and result preview as display-only text.

Future Objective / Reward / Pool systems may subscribe to these context fields in a separate audited stage.

## 7. UI Display Boundary

UI consumers may display:

- rule label
- modifier chip / modifier count
- content pool source
- blocked reason
- effect/result preview

UI consumers must not execute rules, choose rewards, mutate map truth, grant items, write objectives, clear red dots, or persist data.

## 8. Explicit Non-Goals

G34 does not implement:

- complete Rule engine runtime
- script or expression language
- nested rule chains or AI Director
- real reward grant
- real drops
- real objective progression
- real RoomLoot / GroundLoot runtime expansion
- real map mutation runtime
- real battle skill effects
- SaveManager or active-run persistence
- AssetLedger / RunAssetLedger long-term writes
- CommandBus mutation expansion
- FileAccess / `user://` persistence
- debugging simulator or batch simulation tools
- art/resource import

## 9. Validation Boundary

Validation for this stage may include static validation and Godot headless project-load/parser smoke. Parser smoke only means the project loads and scripts parse; it is not gameplay runtime PASS and not manual playtest PASS.
