extends RefCounted
class_name RunModifierSpec

# G8.2 modifier contract. Modifiers rewrite rule context/results/effects, not ledger or UI.

const RuleEffectModifierSchemaScript := preload("res://scripts/core/rules/rule_effect_modifier_schema.gd")


static func make(modifier_id: String, source: String, priority: int, phase: StringName, target_rule: StringName, operation: StringName, value: Variant, duration: Dictionary = {}, stack_rule: StringName = &"replace", conflict_tags: Array = [], reason: String = "", sequence: int = 0) -> Dictionary:
	return {
		"modifier_id": modifier_id,
		"source": source,
		"priority": priority,
		"phase": phase,
		"target_rule": target_rule,
		"operation": operation,
		"value": value,
		"duration": duration.duplicate(true),
		"stack_rule": stack_rule,
		"conflict_tags": conflict_tags.duplicate(true),
		"reason": reason,
		"sequence": sequence,
	}


static func compare_stable(a: Dictionary, b: Dictionary) -> bool:
	var phase_a: String = String(a.get("phase", &""))
	var phase_b: String = String(b.get("phase", &""))
	if phase_a != phase_b:
		return phase_a < phase_b
	var priority_a: int = int(a.get("priority", 0))
	var priority_b: int = int(b.get("priority", 0))
	if priority_a != priority_b:
		return priority_a < priority_b
	return int(a.get("sequence", 0)) < int(b.get("sequence", 0))


static func make_profile_preview(spec: Dictionary = {}) -> Dictionary:
	var modifier_id: String = String(spec.get("modifier_id", "modifier.preview"))
	var profile: Dictionary = RuleEffectModifierSchemaScript.default_modifier_profile(modifier_id)
	profile["source"] = spec.get("source", profile.get("source", &"preview"))
	profile["priority"] = int(spec.get("priority", profile.get("priority", 100)))
	profile["layer"] = spec.get("phase", spec.get("layer", profile.get("layer", &"base")))
	profile["stack_rule"] = spec.get("stack_rule", profile.get("stack_rule", &"replace"))
	profile["conflict_tags"] = _array_from(spec.get("conflict_tags", []))
	profile["affected_targets_preview"] = [spec.get("target_rule", &"")]
	profile["duration"] = _dictionary_from(spec.get("duration", profile.get("duration", {})))
	return profile


static func stack_preview(modifiers: Array = []) -> Dictionary:
	var profiles: Array = []
	for modifier in modifiers:
		if modifier is Dictionary:
			profiles.append(make_profile_preview(modifier))
	return RuleEffectModifierSchemaScript.default_modifier_stack_preview(profiles)


static func conflict_policy_preview() -> Dictionary:
	return RuleEffectModifierSchemaScript.default_modifier_conflict_policy()


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
