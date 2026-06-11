extends RefCounted
class_name RunModifierSpec

# G8.2 modifier contract. Modifiers rewrite rule context/results/effects, not ledger or UI.


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
