extends RefCounted
class_name RoomEncounterCommonRuleSchema

# G33 room type / tag / encounter common rule schema.
# This file only builds read-only preview dictionaries. It must not mutate room,
# reward, objective, settlement, asset, or persistence state.

const SCHEMA_VERSION := 1
const RuleEffectModifierSchemaScript := preload("res://scripts/core/rules/rule_effect_modifier_schema.gd")
const ContentDeliverySchemaScript := preload("res://scripts/core/content/content_delivery_schema.gd")

const ROOM_SPAWN := &"Spawn"
const ROOM_NORMAL := &"Normal"
const ROOM_MINE := &"Mine"
const ROOM_MONSTER := &"Monster"
const ROOM_COMBAT := &"Combat"
const ROOM_CHEST := &"Chest"
const ROOM_EVENT := &"Event"
const ROOM_EXIT := &"Exit"
const ROOM_BOSS := &"Boss"
const ROOM_SPECIAL_RULE := &"SpecialRule"
const ROOM_UNKNOWN := &"Unknown"

const ENCOUNTER_NONE := &"empty"
const ENCOUNTER_SEARCH := &"search_result"
const ENCOUNTER_COMBAT := &"combat"
const ENCOUNTER_TREASURE := &"treasure"
const ENCOUNTER_EVENT_CHOICE := &"event_choice"
const ENCOUNTER_MERCHANT := &"merchant"
const ENCOUNTER_RECYCLE_TERMINAL := &"recycle_terminal"
const ENCOUNTER_EVACUATION := &"evacuation"
const ENCOUNTER_RULE_MODIFIER := &"rule_modifier"
const ENCOUNTER_BOSS := &"boss"
const ENCOUNTER_MINE := &"mine_hazard"


static func build_room_contract(room_type: StringName, pos: Vector2i = Vector2i.ZERO, room_state: Dictionary = {}) -> Dictionary:
	var normalized_type: StringName = normalize_room_type(room_type)
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RoomCommonRuleContract",
		"RoomType": room_type_profile(normalized_type),
		"RoomTag": room_tags_for(normalized_type),
		"RoomPolicy": room_policy_for(normalized_type),
		"RoomState": room_state_preview(normalized_type, pos, room_state),
		"RoomContentSlot": room_content_slot_for(normalized_type),
		"EncounterEntry": encounter_entry_for(normalized_type, pos),
		"EncounterPreview": encounter_preview_for(normalized_type, pos),
		"RoomRulePreview": room_rule_preview_for(normalized_type),
		"RoomCondition": room_condition_for(normalized_type),
		"RoomResolutionPreview": room_resolution_preview_for(normalized_type, room_state),
		"RoomResultPreview": room_result_preview_for(normalized_type),
		"GroundLoot": ground_loot_preview_for(normalized_type),
		"RoomLootContainer": room_loot_container_preview_for(normalized_type),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func normalize_room_type(room_type: StringName) -> StringName:
	match room_type:
		ROOM_SPAWN, ROOM_NORMAL, ROOM_MINE, ROOM_MONSTER, ROOM_COMBAT, ROOM_CHEST, ROOM_EVENT, ROOM_EXIT, ROOM_BOSS, ROOM_SPECIAL_RULE:
			return room_type
		_:
			return ROOM_UNKNOWN


static func room_type_profile(room_type: StringName) -> Dictionary:
	var normalized_type: StringName = normalize_room_type(room_type)
	return {
		"schema_kind": &"RoomType",
		"room_type": normalized_type,
		"type_key": room_type_key(normalized_type),
		"display_key": "room.type.%s" % String(room_type_key(normalized_type)),
		"exclusive_base_type": true,
		"future_composite_via": [&"tag", &"encounter", &"condition", &"modifier"],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func room_type_key(room_type: StringName) -> StringName:
	match room_type:
		ROOM_SPAWN:
			return &"spawn"
		ROOM_NORMAL:
			return &"normal"
		ROOM_MINE:
			return &"mine"
		ROOM_MONSTER, ROOM_COMBAT:
			return &"combat"
		ROOM_CHEST:
			return &"chest"
		ROOM_EVENT:
			return &"event"
		ROOM_EXIT:
			return &"exit"
		ROOM_BOSS:
			return &"boss"
		ROOM_SPECIAL_RULE:
			return &"special_rule"
		_:
			return &"unknown"


static func room_tags_for(room_type: StringName) -> Array:
	match normalize_room_type(room_type):
		ROOM_SPAWN:
			return [&"function.spawn", &"trigger.none", &"repeat.revisit_allowed", &"risk.safe", &"settlement.none"]
		ROOM_NORMAL:
			return [&"function.search", &"trigger.search", &"repeat.one_shot_reward", &"risk.low", &"reward.search"]
		ROOM_MINE:
			return [&"function.hazard", &"trigger.enter", &"repeat.one_shot_trigger", &"risk.danger", &"reward.none"]
		ROOM_MONSTER, ROOM_COMBAT:
			return [&"function.combat", &"trigger.enter_or_interact", &"repeat.clear_once", &"risk.combat", &"reward.combat"]
		ROOM_CHEST:
			return [&"function.loot", &"trigger.search", &"repeat.one_shot_reward", &"risk.locked_or_trap_preview", &"reward.chest"]
		ROOM_EVENT:
			return [&"function.event", &"trigger.interact", &"repeat.event_defined", &"risk.variable", &"reward.event"]
		ROOM_EXIT:
			return [&"function.evacuation", &"trigger.confirm", &"repeat.revisit_allowed", &"risk.safe", &"settlement.evacuation"]
		ROOM_BOSS:
			return [&"function.boss", &"trigger.enter_or_interact", &"repeat.clear_once", &"risk.boss", &"reward.boss_preview"]
		ROOM_SPECIAL_RULE:
			return [&"function.rule_modifier", &"trigger.enter_or_interact", &"repeat.rule_defined", &"risk.special_rule", &"reward.rule_preview"]
		_:
			return [&"function.unknown", &"trigger.unknown", &"repeat.unknown", &"risk.unknown", &"reward.unknown"]


static func room_policy_for(room_type: StringName) -> Dictionary:
	match normalize_room_type(room_type):
		ROOM_SPAWN:
			return _policy(&"free", &"none", &"not_searchable", &"return_allowed", &"none", &"already_safe", &"revisit_allowed", &"none", &"none", &"none")
		ROOM_MINE:
			return _policy(&"enter_allowed", &"trigger_once_on_enter", &"not_searchable", &"return_after_explored", &"none", &"triggered_marks_resolved", &"one_shot_trigger", &"failure_or_damage_preview", &"hazard_context", &"none")
		ROOM_MONSTER, ROOM_COMBAT:
			return _policy(&"enter_allowed", &"encounter_required", &"blocked_until_cleared", &"return_after_explored", &"combat_reward_preview", &"clear_after_combat", &"clear_once", &"combat_summary_preview", &"combat_objective_context", &"none")
		ROOM_CHEST:
			return _policy(&"enter_allowed", &"search_required", &"searchable_once", &"return_after_explored", &"room_loot_container_preview", &"opened_or_depleted", &"loot_once", &"loot_summary_preview", &"loot_objective_context", &"none")
		ROOM_EVENT:
			return _policy(&"enter_allowed", &"interact_required", &"event_policy", &"return_after_explored", &"event_defined_preview", &"event_resolution_defined", &"event_defined", &"event_summary_preview", &"event_objective_context", &"event_may_mutate_map_preview")
		ROOM_EXIT:
			return _policy(&"enter_allowed", &"confirm_extract", &"not_searchable", &"return_allowed", &"extraction_preview", &"evacuation_trigger", &"revisit_allowed", &"run_result_summary_preview", &"evacuation_objective_context", &"none")
		ROOM_BOSS:
			return _policy(&"enter_condition_preview", &"boss_encounter_preview", &"blocked_until_cleared", &"return_after_explored", &"boss_reward_preview", &"clear_after_boss", &"clear_once", &"boss_summary_preview", &"boss_objective_context", &"boss_map_mutation_preview")
		ROOM_SPECIAL_RULE:
			return _policy(&"rule_condition_preview", &"rule_modifier_preview", &"rule_defined", &"return_after_explored", &"rule_defined_preview", &"rule_resolution_preview", &"rule_defined", &"rule_summary_preview", &"rule_objective_context", &"rule_map_mutation_preview")
		_:
			return _policy(&"unknown", &"unknown", &"unknown", &"blocked_until_known", &"unknown", &"unknown", &"unknown", &"unknown", &"unknown", &"unknown")


static func room_state_preview(room_type: StringName, pos: Vector2i = Vector2i.ZERO, source_state: Dictionary = {}) -> Dictionary:
	return {
		"schema_kind": &"RoomState",
		"room_type": normalize_room_type(room_type),
		"pos": pos,
		"state_flags": _state_flags_from(source_state),
		"unknown": StringName(source_state.get("known_state", &"unknown")) == &"unknown",
		"scanned": bool(source_state.get("scanned", false)),
		"explored": bool(source_state.get("explored", false)),
		"searched": bool(source_state.get("searched", false)),
		"triggered": bool(source_state.get("triggered", false)),
		"opened": bool(source_state.get("opened", false)),
		"cleared": bool(source_state.get("cleared", false)),
		"depleted": bool(source_state.get("depleted", false)),
		"locked": bool(source_state.get("locked", false)),
		"blocked": bool(source_state.get("blocked", false)),
		"failed": bool(source_state.get("failed", false)),
		"exhausted": bool(source_state.get("exhausted", false)),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func room_content_slot_for(room_type: StringName) -> Dictionary:
	var encounter_type: StringName = encounter_type_for(room_type)
	return {
		"schema_kind": &"RoomContentSlot",
		"slot_id": &"primary_encounter",
		"room_type": normalize_room_type(room_type),
		"encounter_type": encounter_type,
		"ground_loot_ref": &"GroundLoot",
		"room_loot_container_ref": &"RoomLootContainer",
		"additional_slots_preview": [&"hidden_encounter", &"conditional_encounter", &"chain_encounter"],
		"single_primary_encounter_now": true,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func encounter_type_for(room_type: StringName) -> StringName:
	match normalize_room_type(room_type):
		ROOM_NORMAL:
			return ENCOUNTER_SEARCH
		ROOM_MINE:
			return ENCOUNTER_MINE
		ROOM_MONSTER, ROOM_COMBAT:
			return ENCOUNTER_COMBAT
		ROOM_CHEST:
			return ENCOUNTER_TREASURE
		ROOM_EVENT:
			return ENCOUNTER_EVENT_CHOICE
		ROOM_EXIT:
			return ENCOUNTER_EVACUATION
		ROOM_BOSS:
			return ENCOUNTER_BOSS
		ROOM_SPECIAL_RULE:
			return ENCOUNTER_RULE_MODIFIER
		_:
			return ENCOUNTER_NONE


static func encounter_entry_for(room_type: StringName, pos: Vector2i = Vector2i.ZERO) -> Dictionary:
	var encounter_type: StringName = encounter_type_for(room_type)
	return {
		"schema_kind": &"EncounterEntry",
		"entry_id": "room_%d_%d_%s" % [pos.x, pos.y, String(room_type_key(room_type))],
		"room_type": normalize_room_type(room_type),
		"encounter_type": encounter_type,
		"entry_trigger": room_policy_for(room_type).get("trigger_policy", &"unknown"),
		"entry_state": &"preview_available" if encounter_type != ENCOUNTER_NONE else &"empty",
		"decoupled_from_room_type": true,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func encounter_preview_for(room_type: StringName, pos: Vector2i = Vector2i.ZERO) -> Dictionary:
	var encounter_type: StringName = encounter_type_for(room_type)
	return {
		"schema_kind": &"EncounterPreview",
		"encounter_type": encounter_type,
		"room_type": normalize_room_type(room_type),
		"pos": pos,
		"display_key": "encounter.%s.preview" % String(encounter_type),
		"option_channel_preview": option_channel_for(encounter_type),
		"merchant_preview_only": encounter_type in [ENCOUNTER_MERCHANT, ENCOUNTER_RECYCLE_TERMINAL],
		"combat_runtime_connected": false,
		"event_chain_runtime_connected": false,
		"room_loot_runtime_connected": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func option_channel_for(encounter_type: StringName) -> StringName:
	match encounter_type:
		ENCOUNTER_SEARCH:
			return &"search"
		ENCOUNTER_TREASURE:
			return &"open_or_search"
		ENCOUNTER_COMBAT, ENCOUNTER_BOSS:
			return &"combat_option_preview"
		ENCOUNTER_EVENT_CHOICE, ENCOUNTER_MERCHANT, ENCOUNTER_RECYCLE_TERMINAL:
			return &"event_option_preview"
		ENCOUNTER_EVACUATION:
			return &"confirm_extract"
		ENCOUNTER_RULE_MODIFIER:
			return &"rule_preview"
		ENCOUNTER_MINE:
			return &"hazard_trigger"
		_:
			return &"none"


static func room_rule_preview_for(room_type: StringName) -> Dictionary:
	var policy: Dictionary = room_policy_for(room_type)
	return {
		"schema_kind": &"RoomRulePreview",
		"room_type": normalize_room_type(room_type),
		"policy_ref": &"RoomPolicy",
		"entry_policy": policy.get("entry_policy", &"unknown"),
		"trigger_policy": policy.get("trigger_policy", &"unknown"),
		"search_policy": policy.get("search_policy", &"unknown"),
		"repeat_policy": policy.get("repeat_policy", &"unknown"),
		"RuleDefinition": RuleEffectModifierSchemaScript.default_rule_definition("room.%s.preview" % String(room_type_key(room_type)), &"room_policy_preview"),
		"EffectPreview": RuleEffectModifierSchemaScript.default_effect_preview(RuleEffectModifierSchemaScript.default_effect_descriptor(&"room.preview")),
		"ModifierStackPreview": RuleEffectModifierSchemaScript.default_modifier_stack_preview(),
		"ContentDeliveryContext": ContentDeliverySchemaScript.default_content_delivery_context("room.%s.content_preview" % String(room_type_key(room_type))),
		"rule_engine_runtime_connected": false,
		"modifier_context_preview": _context_placeholder(&"modifier_context_preview"),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func room_condition_for(room_type: StringName) -> Dictionary:
	return {
		"schema_kind": &"RoomCondition",
		"room_type": normalize_room_type(room_type),
		"entry_condition": room_policy_for(room_type).get("entry_policy", &"unknown"),
		"clear_condition": room_policy_for(room_type).get("clear_policy", &"unknown"),
		"objective_condition_preview": _context_placeholder(&"objective_context_preview"),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func room_resolution_preview_for(room_type: StringName, source_state: Dictionary = {}) -> Dictionary:
	return {
		"schema_kind": &"RoomResolutionPreview",
		"room_type": normalize_room_type(room_type),
		"room_state_delta": {
			"triggered": bool(source_state.get("triggered", false)),
			"cleared": bool(source_state.get("cleared", false)),
			"searched": bool(source_state.get("searched", false)),
			"depleted": bool(source_state.get("depleted", false)),
		},
		"encounter_state_delta": {
			"encounter_type": encounter_type_for(room_type),
			"resolution_state": &"preview_only",
		},
		"loot_generated": false,
		"objective_delta": _context_placeholder(&"objective_delta_preview"),
		"effect_result_preview": RuleEffectModifierSchemaScript.default_effect_result_preview(RuleEffectModifierSchemaScript.default_effect_descriptor(&"room.resolution_preview")),
		"pool_result_preview": ContentDeliverySchemaScript.default_pool_result_preview("room.%s.pool_preview" % String(room_type_key(room_type))),
		"map_mutation": room_policy_for(room_type).get("map_mutation_policy", &"none"),
		"failure_trigger": normalize_room_type(room_type) == ROOM_MINE,
		"evacuation_trigger": normalize_room_type(room_type) == ROOM_EXIT,
		"run_log_entry": "RoomResolutionPreview is a draft handoff only.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func room_result_preview_for(room_type: StringName) -> Dictionary:
	return {
		"schema_kind": &"RoomResultPreview",
		"room_type": normalize_room_type(room_type),
		"room_resolution_ref": &"RoomResolutionPreview",
		"run_result_delta_preview": {
			"room_state_delta": &"reserved",
			"encounter_state_delta": &"reserved",
			"loot_generated": false,
			"objective_delta": &"reserved",
			"map_mutation": room_policy_for(room_type).get("map_mutation_policy", &"none"),
		},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func ground_loot_preview_for(room_type: StringName) -> Dictionary:
	return {
		"schema_kind": &"GroundLoot",
		"room_type": normalize_room_type(room_type),
		"semantic_boundary": "Room-local item presence; not player backpack and not long-term warehouse.",
		"runtime_connected": false,
		"items": [],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func room_loot_container_preview_for(room_type: StringName) -> Dictionary:
	return {
		"schema_kind": &"RoomLootContainer",
		"room_type": normalize_room_type(room_type),
		"container_policy": room_policy_for(room_type).get("loot_policy", &"none"),
		"runtime_connected": false,
		"generated_items_preview": [],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func room_resolution_summary_preview(room_state: Dictionary = {}) -> Dictionary:
	var room_type: StringName = normalize_room_type(StringName(room_state.get("room_type", ROOM_UNKNOWN)))
	return {
		"schema_kind": &"room_resolution_summary_preview",
		"room_type": room_type,
		"RoomTag": _array_from_variant(room_state.get("RoomTag", room_tags_for(room_type))),
		"RoomPolicy": _dictionary_from_variant(room_state.get("RoomPolicy", room_policy_for(room_type))),
		"EncounterPreview": _dictionary_from_variant(room_state.get("EncounterPreview", encounter_preview_for(room_type))),
		"RoomResolutionPreview": _dictionary_from_variant(room_state.get("RoomResolutionPreview", room_resolution_preview_for(room_type, room_state))),
		"RoomResultPreview": _dictionary_from_variant(room_state.get("RoomResultPreview", room_result_preview_for(room_type))),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_common_rule_summary() -> Dictionary:
	return {
		"schema_kind": &"room_type_tag_encounter_common_rule_summary",
		"room_types": [ROOM_SPAWN, ROOM_NORMAL, ROOM_MINE, ROOM_MONSTER, ROOM_CHEST, ROOM_EVENT, ROOM_EXIT, ROOM_BOSS, ROOM_SPECIAL_RULE],
		"tag_namespaces": [&"function", &"trigger", &"repeat", &"risk", &"reward", &"objective", &"settlement"],
		"encounter_types": [ENCOUNTER_SEARCH, ENCOUNTER_COMBAT, ENCOUNTER_TREASURE, ENCOUNTER_EVENT_CHOICE, ENCOUNTER_MERCHANT, ENCOUNTER_RECYCLE_TERMINAL, ENCOUNTER_EVACUATION, ENCOUNTER_RULE_MODIFIER, ENCOUNTER_BOSS, ENCOUNTER_MINE, ENCOUNTER_NONE],
		"RoomContentSlot": &"preview_schema",
		"RoomRulePreview": &"preview_schema",
		"RuleDefinition": &"preview_schema",
		"RuleCondition": &"preview_schema",
		"EffectPreview": &"preview_schema",
		"ModifierStackPreview": &"preview_schema",
		"ContentDeliveryContext": &"preview_schema",
		"RoomResolutionPreview": &"preview_schema",
		"GroundLoot": &"semantic_boundary_only",
		"RoomLootContainer": &"semantic_boundary_only",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _policy(
	entry_policy: StringName,
	trigger_policy: StringName,
	search_policy: StringName,
	return_policy: StringName,
	loot_policy: StringName,
	clear_policy: StringName,
	repeat_policy: StringName,
	settlement_policy: StringName,
	objective_policy: StringName,
	map_mutation_policy: StringName
) -> Dictionary:
	return {
		"schema_kind": &"RoomPolicy",
		"entry_policy": entry_policy,
		"trigger_policy": trigger_policy,
		"search_policy": search_policy,
		"return_policy": return_policy,
		"loot_policy": loot_policy,
		"clear_policy": clear_policy,
		"repeat_policy": repeat_policy,
		"settlement_policy": settlement_policy,
		"objective_policy": objective_policy,
		"map_mutation_policy": map_mutation_policy,
		"visibility_policy": &"known_map_only",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _state_flags_from(source_state: Dictionary) -> Array[StringName]:
	var flags: Array[StringName] = []
	for flag in [&"unknown", &"scanned", &"explored", &"searched", &"triggered", &"opened", &"cleared", &"depleted", &"locked", &"blocked", &"failed", &"exhausted"]:
		if bool(source_state.get(String(flag), false)):
			flags.append(flag)
	if flags.is_empty():
		flags.append(StringName(source_state.get("known_state", &"unknown")))
	return flags


static func _context_placeholder(context_id: StringName) -> Dictionary:
	return {
		"context_id": context_id,
		"state": &"reserved_preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
