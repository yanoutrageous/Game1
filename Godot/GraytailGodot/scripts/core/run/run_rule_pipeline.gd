extends RefCounted
class_name RunRulePipeline

# G8.2 minimum RulePipeline. It reserves stable protocol hooks without adding new gameplay.
# Protocol markers: RuleRequest, RuleContext, DefaultRuleResult, ModifierSpec application,
# Final RuleResult, produced EffectSpec, produced Event, produced Transaction.

var next_rule_sequence: int = 1
var next_modifier_sequence: int = 1
var modifiers: Array[Dictionary] = []

const RuleEffectModifierSchemaScript := preload("res://scripts/core/rules/rule_effect_modifier_schema.gd")


func make_rule_request(rule_id: StringName, actor_id: StringName = &"player", source: String = "", payload: Dictionary = {}, command_id: String = "") -> Dictionary:
	var sequence: int = next_rule_sequence
	next_rule_sequence += 1
	var rule_definition: Dictionary = RuleEffectModifierSchemaScript.default_rule_definition(String(rule_id), &"run_rule_request")
	return {
		"rule_request_id": "rule_%04d_%s" % [sequence, String(rule_id)],
		"rule_id": rule_id,
		"actor_id": actor_id,
		"source": source,
		"payload": payload.duplicate(true),
		"command_id": command_id,
		"sequence": sequence,
		"RuleDefinition": rule_definition,
		"RuleTrigger": rule_definition.get("RuleTrigger", {}),
		"TargetSelector": rule_definition.get("TargetSelector", {}),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func make_rule_context(context: RunContext, request: Dictionary) -> Dictionary:
	return {
		"request": request.duplicate(true),
		"rule_request_id": String(request.get("rule_request_id", "")),
		"rule_id": StringName(request.get("rule_id", &"")),
		"actor_id": StringName(request.get("actor_id", &"player")),
		"source": String(request.get("source", "")),
		"command_id": String(request.get("command_id", "")),
		"run_id": &"" if context == null else context.run_id,
		"position": Vector2i.ZERO if context == null else context.get_current_pos(),
		"modifiers": modifiers.duplicate(true),
		"RuleContextSnapshot": RuleEffectModifierSchemaScript.default_rule_context_snapshot(String(request.get("rule_request_id", ""))),
		"ApplicabilityCheck": RuleEffectModifierSchemaScript.default_applicability_check(),
		"ScopePolicy": RuleEffectModifierSchemaScript.default_scope_policy(),
		"ModifierStackPreview": RunModifierSpec.stack_preview(modifiers),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func register_modifier(spec: Dictionary) -> Dictionary:
	var next_spec: Dictionary = spec.duplicate(true)
	if not next_spec.has("sequence") or int(next_spec.get("sequence", 0)) <= 0:
		next_spec["sequence"] = next_modifier_sequence
		next_modifier_sequence += 1
	next_spec["ModifierProfile"] = RunModifierSpec.make_profile_preview(next_spec)
	next_spec["read_only"] = true
	next_spec["display_only"] = true
	next_spec["preview"] = true
	next_spec["no_persistence"] = true
	modifiers.append(next_spec)
	modifiers.sort_custom(RunModifierSpec.compare_stable)
	return next_spec.duplicate(true)


func apply_modifiers(rule_context: Dictionary, default_rule_result: Dictionary) -> Dictionary:
	var final_result: Dictionary = default_rule_result.duplicate(true)
	var applied: Array[Dictionary] = []
	var rule_id: StringName = StringName(rule_context.get("rule_id", &""))
	var stable_modifiers: Array = modifiers.duplicate(true)
	stable_modifiers.sort_custom(RunModifierSpec.compare_stable)
	for modifier in stable_modifiers:
		if StringName(modifier.get("target_rule", &"")) != rule_id:
			continue
		applied.append(modifier.duplicate(true))
	final_result["rule_request_id"] = String(rule_context.get("rule_request_id", ""))
	final_result["applied_modifiers"] = applied
	final_result["produced_effects"] = final_result.get("effects", []).duplicate(true)
	final_result["produced_events"] = final_result.get("produced_events", []).duplicate(true)
	final_result["produced_transactions"] = final_result.get("produced_transactions", []).duplicate(true)
	final_result["RulePreviewSummary"] = RuleEffectModifierSchemaScript.build_rule_preview_summary(final_result, rule_context)
	final_result["EffectResultPreview"] = RuleEffectModifierSchemaScript.build_effect_result_summary(_array_from(final_result.get("effect_results", [])), _array_from(final_result.get("produced_effects", [])), String(final_result.get("blocked_reason", "")))
	final_result["ModifierStackPreview"] = RunModifierSpec.stack_preview(applied)
	final_result["read_only_preview_summary"] = true
	return final_result


func resolve(context: RunContext, rule_id: StringName, payload: Dictionary, default_rule_result: Dictionary, command: Dictionary = {}) -> Dictionary:
	var request: Dictionary = make_rule_request(rule_id, StringName(command.get("actor_id", &"player")), String(command.get("source", "")), payload, String(command.get("command_id", "")))
	var rule_context: Dictionary = make_rule_context(context, request)
	var final_result: Dictionary = apply_modifiers(rule_context, default_rule_result)
	final_result["rule_context"] = rule_context
	return final_result


func preview_summary(rule_result: Dictionary = {}) -> Dictionary:
	return RuleEffectModifierSchemaScript.build_rule_preview_summary(rule_result, _dictionary_from(rule_result.get("rule_context", {})))


func content_modifier_context_preview() -> Dictionary:
	return {
		"schema_kind": &"rule_modifier_content_context_preview",
		"ModifierStackPreview": RunModifierSpec.stack_preview(modifiers),
		"ModifierConflictPolicy": RunModifierSpec.conflict_policy_preview(),
		"modifier_count": modifiers.size(),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
