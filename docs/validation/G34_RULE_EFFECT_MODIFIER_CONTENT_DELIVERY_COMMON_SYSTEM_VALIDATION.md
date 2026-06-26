# G34 Rule / Effect / Modifier & Content Delivery Common System Validation

## 中文结论摘要（DOC-GOV-001）

G34 记录规则、效果、Modifier 与内容投放通用系统的 preview / display-only 内容。它说明 RuleDefinition、RuleTrigger、EffectDescriptor、EffectPreview、ModifierProfile、ContentPool、ContentEntry、DeliveryRollPreview 等公共预览结构；不实现完整规则引擎、脚本语言、AI Director、真实奖励/掉落、目标进度、地图 runtime mutation、持久化、AssetLedger / RunAssetLedger 长期写入、CommandBus mutation、gameplay runtime PASS 或 manual playtest PASS。

本验证摘要只概括原 validation 的验证对象、边界和未声明项。具体 PASS/命令以原 validation 正文为准；不得把 parser/headless smoke 写成 gameplay runtime PASS 或 manual playtest PASS。


## Scope

G34-R2 implements the common rule / effect / modifier / content delivery foundation as contract, schema, limited adapter, and display-only consumer alignment.

Modified areas are limited to:

- `docs/20_product/RULE_EFFECT_MODIFIER_CONTENT_DELIVERY_COMMON_SYSTEM_CONTRACT.md`
- current status / route / index docs
- `Godot/GraytailGodot/scripts/core/rules/**`
- `Godot/GraytailGodot/scripts/core/content/**`
- allowed `core/run`, `core/map`, `core/settlement`, `ui/run_surface`, and `ui/hud` display-only adapters

## Implemented Contract Surface

- RuleDefinition
- RuleTrigger
- RuleCondition
- RuleContextSnapshot
- TargetSelector
- ApplicabilityCheck
- ScopePolicy
- EffectDescriptor
- EffectPreview
- EffectResultPreview
- ModifierProfile
- ModifierStackPreview
- ModifierConflictPolicy
- ContentPool
- ContentEntry
- ContentSelector
- ContentDeliveryContext
- PoolResultPreview
- FallbackPolicy
- DeliveryRollPreview

## Adapter Boundary

Existing run-local rule and effect paths keep their current semantics. G34 only adds preview summary fields such as `RulePreviewSummary`, `EffectResultPreview`, `ModifierStackPreview`, `ContentDeliveryPreview`, `ContentPool`, and `PoolResultPreview`.

## Display-Only Consumers

RunQueryFacade exposes public snapshot fields. RunFlow, Settlement, RunSurface, and HUD read display-only summaries for rule label, modifier count, content pool source, blocked reason, and result preview.

## Validation Results

- Static validation: PASS.
- `git diff --check`: no whitespace error; LF/CRLF warnings only.
- Negative grep safe-hit review: PASS. Hits were existing runtime/preload/UI construction code, existing run systems outside the G34 delta, display text, and preview/no_persistence fields.
- Positive grep evidence: PASS for RuleDefinition, RuleTrigger, RuleCondition, RuleContextSnapshot, TargetSelector, ApplicabilityCheck, EffectDescriptor, EffectPreview, EffectResultPreview, ModifierProfile, ModifierStackPreview, ModifierConflictPolicy, ContentPool, ContentEntry, ContentSelector, ContentDeliveryContext, PoolResultPreview, FallbackPolicy, DeliveryRollPreview, and preview/display-only/read-only fields.
- Godot headless project-load/parser smoke: PASS.
- Godot smoke metadata side effects: none observed.

## Not Claimed

- No gameplay runtime PASS is claimed.
- No manual playtest PASS is claimed.
- G34 does not implement a complete Rule engine runtime, script language, AI Director, real rewards, real drops, objective progress, map mutation runtime, SaveManager, persistence, AssetLedger / RunAssetLedger long-term writes, or CommandBus mutation.
