extends RefCounted
class_name RunRulePipeline

# G8.2 minimum RulePipeline. It reserves stable protocol hooks without adding new gameplay.
# Protocol markers: RuleRequest, RuleContext, DefaultRuleResult, ModifierSpec application,
# Final RuleResult, produced EffectSpec, produced Event, produced Transaction.

var next_rule_sequence: int = 1
var next_modifier_sequence: int = 1
var modifiers: Array[Dictionary] = []


func make_rule_request(rule_id: StringName, actor_id: StringName = &"player", source: String = "", payload: Dictionary = {}, command_id: String = "") -> Dictionary:
	var sequence := next_rule_sequence
	next_rule_sequence += 1
	return {
		"rule_request_id": "rule_%04d_%s" % [sequence, String(rule_id)],
		"rule_id": rule_id,
		"actor_id": actor_id,
		"source": source,
		"payload": payload.duplicate(true),
		"command_id": command_id,
		"sequence": sequence,
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
	}


func register_modifier(spec: Dictionary) -> Dictionary:
	var next_spec := spec.duplicate(true)
	if not next_spec.has("sequence") or int(next_spec.get("sequence", 0)) <= 0:
		next_spec["sequence"] = next_modifier_sequence
		next_modifier_sequence += 1
	modifiers.append(next_spec)
	modifiers.sort_custom(RunModifierSpec.compare_stable)
	return next_spec.duplicate(true)


func apply_modifiers(rule_context: Dictionary, default_rule_result: Dictionary) -> Dictionary:
	var final_result := default_rule_result.duplicate(true)
	var applied: Array[Dictionary] = []
	var rule_id := StringName(rule_context.get("rule_id", &""))
	var stable_modifiers := modifiers.duplicate(true)
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
	return final_result


func resolve(context: RunContext, rule_id: StringName, payload: Dictionary, default_rule_result: Dictionary, command: Dictionary = {}) -> Dictionary:
	var request := make_rule_request(rule_id, StringName(command.get("actor_id", &"player")), String(command.get("source", "")), payload, String(command.get("command_id", "")))
	var rule_context := make_rule_context(context, request)
	var final_result := apply_modifiers(rule_context, default_rule_result)
	final_result["rule_context"] = rule_context
	return final_result
