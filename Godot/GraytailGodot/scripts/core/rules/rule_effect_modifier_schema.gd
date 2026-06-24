extends RefCounted
class_name RuleEffectModifierSchema

# G34 read-only schema helpers for rule/effect/modifier preview contracts.
# This file must not grant rewards, mutate assets, dispatch commands, or persist state.

const SCHEMA_VERSION := 1


static func default_rule_definition(rule_id: String = "rule.preview", trigger_id: StringName = &"manual_preview") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RuleDefinition",
		"rule_id": rule_id,
		"display_key": "rule.%s.label" % rule_id,
		"RuleTrigger": default_rule_trigger(trigger_id),
		"RuleCondition": default_rule_condition(),
		"TargetSelector": default_target_selector(),
		"ApplicabilityCheck": default_applicability_check(),
		"ScopePolicy": default_scope_policy(),
		"EffectPreview": default_effect_preview(),
		"priority": 100,
		"layer": &"base",
		"blocked_reason": "",
		"filter_reason": "",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func normalize_rule_definition(data: Dictionary = {}) -> Dictionary:
	var result := _merge(default_rule_definition(str(data.get("rule_id", "rule.preview"))), data)
	result["RuleTrigger"] = _merge(default_rule_trigger(), _dictionary_from(result.get("RuleTrigger", {})))
	result["RuleCondition"] = _merge(default_rule_condition(), _dictionary_from(result.get("RuleCondition", {})))
	result["TargetSelector"] = _merge(default_target_selector(), _dictionary_from(result.get("TargetSelector", {})))
	result["ApplicabilityCheck"] = _merge(default_applicability_check(), _dictionary_from(result.get("ApplicabilityCheck", {})))
	result["ScopePolicy"] = _merge(default_scope_policy(), _dictionary_from(result.get("ScopePolicy", {})))
	result["EffectPreview"] = _merge(default_effect_preview(), _dictionary_from(result.get("EffectPreview", {})))
	result["read_only"] = true
	result["display_only"] = true
	result["preview"] = true
	result["no_persistence"] = true
	return result


static func validate_rule_definition(data: Dictionary = {}) -> Dictionary:
	var warnings: Array[String] = []
	if str(data.get("rule_id", "")).strip_edges() == "":
		warnings.append("missing_rule_id")
	if not bool(data.get("read_only", false)):
		warnings.append("rule_definition_must_be_read_only")
	if not bool(data.get("display_only", false)):
		warnings.append("rule_definition_must_be_display_only")
	if not bool(data.get("preview", false)):
		warnings.append("rule_definition_must_be_preview")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func default_rule_trigger(trigger_id: StringName = &"manual_preview") -> Dictionary:
	return {
		"schema_kind": &"RuleTrigger",
		"trigger_id": trigger_id,
		"trigger_channel": &"preview",
		"source_context": &"run_local",
		"deterministic_seed_ref": &"rule_context.seed",
		"event_runtime_connected": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_rule_condition(condition_id: String = "condition.always_preview") -> Dictionary:
	return {
		"schema_kind": &"RuleCondition",
		"condition_id": condition_id,
		"condition_type": &"preview_only",
		"required_context_keys": [],
		"filter_reason": "",
		"blocked_reason": "",
		"expression_runtime_connected": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_rule_context_snapshot(context_id: String = "context.preview") -> Dictionary:
	return {
		"schema_kind": &"RuleContextSnapshot",
		"context_id": context_id,
		"run_id": "",
		"room_type": &"Unknown",
		"room_tags": [],
		"encounter_type": &"none",
		"map_context_ref": &"RunMapSnapshot",
		"run_flow_context_ref": &"RunFlowSnapshot",
		"settlement_context_ref": &"SettlementTriggerPreview",
		"objective_context_preview": _context_placeholder(&"objective_context_preview"),
		"reward_context_preview": _context_placeholder(&"reward_context_preview"),
		"pool_context_preview": _context_placeholder(&"pool_context_preview"),
		"modifier_context_preview": _context_placeholder(&"modifier_context_preview"),
		"seed": 0,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_target_selector(selector_id: String = "target.current_room") -> Dictionary:
	return {
		"schema_kind": &"TargetSelector",
		"selector_id": selector_id,
		"target_scope": &"current_room",
		"target_ref": &"RoomState",
		"selection_preview": [],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_applicability_check(ok: bool = true, blocked_reason: String = "") -> Dictionary:
	return {
		"schema_kind": &"ApplicabilityCheck",
		"ok": ok,
		"filter_reason": blocked_reason,
		"blocked_reason": blocked_reason,
		"reason_code": &"ok" if ok else &"blocked_preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_scope_policy() -> Dictionary:
	return {
		"schema_kind": &"ScopePolicy",
		"scope_id": &"run_local_preview",
		"applies_to": [&"room", &"encounter", &"run_flow", &"settlement_preview"],
		"writes_assets": false,
		"grants_reward": false,
		"advances_objective": false,
		"mutates_map": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_effect_descriptor(effect_type: StringName = &"effect.preview") -> Dictionary:
	return {
		"schema_kind": &"EffectDescriptor",
		"effect_type": effect_type,
		"display_key": "effect.%s.preview" % str(effect_type).replace(".", "_"),
		"target_selector": default_target_selector(),
		"payload_schema_preview": {},
		"result_preview_ref": &"EffectResultPreview",
		"writes_assets": false,
		"grants_reward": false,
		"advances_objective": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_effect_preview(effect_descriptor: Dictionary = {}) -> Dictionary:
	var descriptor := default_effect_descriptor()
	if not effect_descriptor.is_empty():
		descriptor = _merge(descriptor, effect_descriptor)
	return {
		"schema_kind": &"EffectPreview",
		"EffectDescriptor": descriptor,
		"effect_label": str(descriptor.get("display_key", "effect.preview")),
		"blocked_reason": "",
		"result_preview": default_effect_result_preview(descriptor),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_effect_result_preview(effect_descriptor: Dictionary = {}, blocked_reason: String = "") -> Dictionary:
	return {
		"schema_kind": &"EffectResultPreview",
		"effect_type": StringName(effect_descriptor.get("effect_type", &"effect.preview")),
		"ok": blocked_reason == "",
		"blocked_reason": blocked_reason,
		"result_label": "effect.result.preview",
		"resource_delta_preview": {},
		"item_delta_preview": [],
		"objective_delta_preview": _context_placeholder(&"objective_delta_preview"),
		"map_mutation_preview": _context_placeholder(&"map_mutation_preview"),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_modifier_profile(modifier_id: String = "modifier.preview") -> Dictionary:
	return {
		"schema_kind": &"ModifierProfile",
		"modifier_id": modifier_id,
		"display_key": "modifier.%s.label" % modifier_id,
		"source": &"preview",
		"scope": &"run_local",
		"duration": {"duration_type": &"preview", "remaining": -1},
		"priority": 100,
		"layer": &"base",
		"stack_rule": &"replace",
		"conflict_tags": [],
		"remove_condition_preview": _context_placeholder(&"remove_condition_preview"),
		"affected_targets_preview": [],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_modifier_stack_preview(modifiers: Array = []) -> Dictionary:
	var normalized: Array = []
	for modifier in modifiers:
		if modifier is Dictionary:
			normalized.append(_modifier_profile_from(modifier))
	return {
		"schema_kind": &"ModifierStackPreview",
		"modifiers": normalized,
		"modifier_count": normalized.size(),
		"applied_modifier_preview": normalized,
		"ModifierConflictPolicy": default_modifier_conflict_policy(),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_modifier_conflict_policy() -> Dictionary:
	return {
		"schema_kind": &"ModifierConflictPolicy",
		"priority_policy": &"lower_priority_first",
		"layering_policy": &"phase_then_priority_then_sequence",
		"conflict_policy": &"preview_no_runtime_resolution",
		"suppression_policy": &"reserved_preview",
		"replacement_policy": &"reserved_preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_rule_preview_summary(rule_result: Dictionary = {}, rule_context: Dictionary = {}) -> Dictionary:
	var rule_id := str(rule_context.get("rule_id", rule_result.get("rule_result", "rule.preview")))
	var blocked := str(rule_result.get("blocked_reason", rule_result.get("reason", "")))
	var effect_results := _array_from(rule_result.get("effect_results", []))
	var effects := _array_from(rule_result.get("effects", rule_result.get("produced_effects", [])))
	return {
		"schema_kind": &"RulePreviewSummary",
		"RuleDefinition": normalize_rule_definition(default_rule_definition(rule_id)),
		"RuleContextSnapshot": _rule_context_from(rule_context),
		"EffectResultPreview": build_effect_result_summary(effect_results, effects, blocked),
		"ModifierStackPreview": default_modifier_stack_preview(_array_from(rule_result.get("applied_modifiers", rule_context.get("modifiers", [])))),
		"ok": bool(rule_result.get("ok", blocked == "")),
		"status": StringName(rule_result.get("status", rule_result.get("rule_result", &"preview"))),
		"blocked_reason": blocked,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_effect_result_summary(effect_results: Array = [], effects: Array = [], blocked_reason: String = "") -> Dictionary:
	var items: Array = []
	for effect in effects:
		if effect is Dictionary:
			items.append(default_effect_result_preview(default_effect_descriptor(StringName(effect.get("type", &"effect.preview"))), blocked_reason))
	for result in effect_results:
		if result is Dictionary:
			var descriptor := default_effect_descriptor(StringName(result.get("effect_type", &"effect.preview")))
			var preview := default_effect_result_preview(descriptor, str(result.get("blocked_reason", result.get("reason", ""))))
			preview["ok"] = bool(result.get("ok", true))
			preview["raw_status"] = result.get("status", &"preview")
			items.append(preview)
	return {
		"schema_kind": &"EffectResultPreview",
		"items": items,
		"effect_count": items.size(),
		"blocked_reason": blocked_reason,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_modifier_summary(modifiers: Array = []) -> Dictionary:
	return default_modifier_stack_preview(modifiers)


static func _rule_context_from(rule_context: Dictionary) -> Dictionary:
	var snapshot := default_rule_context_snapshot(str(rule_context.get("rule_request_id", "context.preview")))
	snapshot["run_id"] = str(rule_context.get("run_id", ""))
	snapshot["room_type"] = StringName(rule_context.get("room_type", &"Unknown"))
	snapshot["seed"] = int(rule_context.get("seed", 0))
	return snapshot


static func _modifier_profile_from(source: Dictionary) -> Dictionary:
	var profile := default_modifier_profile(str(source.get("modifier_id", "modifier.preview")))
	profile["source"] = source.get("source", profile.get("source", &"preview"))
	profile["duration"] = _dictionary_from(source.get("duration", profile.get("duration", {})))
	profile["priority"] = int(source.get("priority", profile.get("priority", 100)))
	profile["layer"] = source.get("phase", source.get("layer", profile.get("layer", &"base")))
	profile["stack_rule"] = source.get("stack_rule", profile.get("stack_rule", &"replace"))
	profile["conflict_tags"] = _array_from(source.get("conflict_tags", []))
	profile["affected_targets_preview"] = [source.get("target_rule", &"")]
	return profile


static func _context_placeholder(context_id: StringName) -> Dictionary:
	return {
		"context_id": context_id,
		"state": &"reserved_preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in overlay.keys():
		result[key] = _copy_value(overlay[key])
	return result


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _copy_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
