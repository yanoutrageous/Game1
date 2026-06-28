extends RefCounted
class_name RunQueryFacade

# Read-only query and snapshot boundary for run state.
# UI and presentation code should consume these snapshots instead of private run state.

const EncounterResolverScript := preload("res://scripts/core/run/encounter/encounter_resolver.gd")
const RunFlowStateContractScript := preload("res://scripts/core/run/run_flow_state_contract.gd")
const RunResultBuilderScript := preload("res://scripts/core/run/run_result_builder.gd")
const RuleEffectModifierSchemaScript := preload("res://scripts/core/rules/rule_effect_modifier_schema.gd")
const ContentDeliverySchemaScript := preload("res://scripts/core/content/content_delivery_schema.gd")


func build_result_snapshot(context: RunContext) -> Dictionary:
	var ledger_snapshot: Dictionary = get_asset_snapshot(context)
	var event_log_snapshot: Array[Dictionary] = get_event_log_snapshot(context)
	var transaction_log_snapshot: Array[Dictionary] = get_transaction_log_snapshot(context)
	var run_map_snapshot := build_run_map_snapshot(context)
	var map_result := build_map_result(context)
	var run_flow_snapshot := build_run_flow_snapshot(context, run_map_snapshot, map_result)
	var run_result: Dictionary = RunResultBuilderScript.build(context, ledger_snapshot, run_map_snapshot, map_result, run_flow_snapshot)
	var current_room_detail := get_current_room_detail(context)
	var rule_summary_preview := build_rule_effect_modifier_summary(context, current_room_detail)
	var content_delivery_preview := build_content_delivery_summary(context, current_room_detail)
	var result_id := "%s:%s:%s" % [String(context.run_id), context.outcome, context.turn]
	var active_command: Dictionary = context.active_command.duplicate(true)
	var active_command_name := String(active_command.get("command_name", ""))
	var active_source := String(active_command.get("source", ""))
	return {
		"run_id": context.run_id,
		"result_id": result_id,
		"result_source_command": active_command.duplicate(true),
		"debug_command_used": context.debug_used or active_source == "debug" or active_command_name.begins_with("debug_"),
		"debug_used": context.debug_used,
		"debug_commands": context.debug_commands.duplicate(true),
		"debug_command_count": context.debug_commands.size(),
		"outcome": context.outcome,
		"extracted": context.extracted,
		"failed": context.failed,
		"abandoned": context.abandoned,
		"mode": context.mode,
		"position": context.player_pos,
		"hp": context.hp,
		"max_hp": context.max_hp,
		"power": context.power,
		"pressure": context.pressure,
		"protocol_level": context.protocol_level,
		"black_coin": ledger_snapshot.get("black_coin", context.pending_gold),
		"gold_coin": ledger_snapshot.get("gold_coin", context.safe_gold),
		"run_black_coin": ledger_snapshot.get("run_black_coin", context.pending_gold),
		"safe_yield": ledger_snapshot.get("safe_yield", context.safe_gold),
		"long_term_gold": ledger_snapshot.get("long_term_gold", 0),
		"long_term_gold_preview": ledger_snapshot.get("long_term_gold_preview", 0),
		"pending_gold": context.pending_gold,
		"safe_gold": context.safe_gold,
		"parts": context.parts,
		"backpack_capacity": ledger_snapshot.get("backpack_capacity", 0),
		"backpack_used": ledger_snapshot.get("backpack_used", 0),
		"backpack_remaining": ledger_snapshot.get("backpack_remaining", 0),
		"carried_item_count": context.carried_items.size(),
		"carried_item_value": RunInventory.get_carried_item_value(context),
		"carried_items": context.carried_items.duplicate(true),
		"inventory_items": ledger_snapshot.get("inventory_items", []),
		"equipped_items": ledger_snapshot.get("equipped_items", []),
		"room_floor_items": ledger_snapshot.get("room_floor_items", []),
		"room_floor_item_count": ledger_snapshot.get("room_floor_item_count", 0),
		"warehouse_lite": ledger_snapshot.get("warehouse_lite", []),
		"settlement_log": ledger_snapshot.get("settlement_log", []),
		"event_log": event_log_snapshot,
		"event_count": event_log_snapshot.size(),
		"transaction_log": transaction_log_snapshot,
		"transaction_count": transaction_log_snapshot.size(),
		"run_map_snapshot": run_map_snapshot,
		"map_result": map_result,
		"run_flow_snapshot": run_flow_snapshot,
		"RunLifecycle": run_flow_snapshot.get("RunLifecycle", {}),
		"RunState": run_flow_snapshot.get("RunState", {}),
		"RoomTransition": run_flow_snapshot.get("RoomTransition", {}),
		"RoomActionResult": run_flow_snapshot.get("RoomActionResult", {}),
		"RunIntent": run_flow_snapshot.get("RunIntent", {}),
		"SettlementTriggerPreview": run_flow_snapshot.get("SettlementTriggerPreview", {}),
		"RunOutcomePreview": run_flow_snapshot.get("RunOutcomePreview", {}),
		"RunResult": run_result,
		"run_result": run_result.duplicate(true),
		"settlement_input": run_result.duplicate(true),
		"SettlementInput": run_result.duplicate(true),
		"settlement_reads_run_result_only": true,
		"settlement": context.settlement_result.duplicate(true),
		"map_summary_preview": map_result.get("map_summary_preview", {}),
		"current_room_detail": current_room_detail,
		"room_common_rule_summary_preview": _room_common_rule_summary(current_room_detail),
		"room_resolution_summary_preview": map_result.get("room_resolution_summary_preview", {}),
		"rule_effect_modifier_summary_preview": rule_summary_preview,
		"content_delivery_summary_preview": content_delivery_preview,
		"RuleDefinition": rule_summary_preview.get("RuleDefinition", {}),
		"EffectPreview": rule_summary_preview.get("EffectPreview", {}),
		"EffectResultPreview": rule_summary_preview.get("EffectResultPreview", {}),
		"ModifierStackPreview": rule_summary_preview.get("ModifierStackPreview", {}),
		"ContentPool": content_delivery_preview.get("ContentPool", {}),
		"PoolResultPreview": content_delivery_preview.get("PoolResultPreview", {}),
		"objective_context_preview": run_map_snapshot.get("objective_context_preview", {}),
		"modifier_context_preview": run_map_snapshot.get("modifier_context_preview", {}),
		"pool_context_preview": content_delivery_preview.get("ContentDeliveryContext", {}),
		"room_loot_context_preview": run_map_snapshot.get("room_loot_context_preview", {}),
		"run_result_context_preview": run_map_snapshot.get("run_result_context_preview", {}),
		"status_effects": ledger_snapshot.get("status_effects", []),
		"failure_salvage": context.failure_salvage.duplicate(true),
		"stats": context.run_stats.duplicate(true),
		"final_room": context.current_room_type,
		"encounter_type": context.encounter_type,
		"encounter_tags": context.encounter_tags.duplicate(true),
		"blocked_reason": context.blocked_reason,
		"turn": context.turn,
	}


func build_status_snapshot(context: RunContext) -> Dictionary:
	var ledger_snapshot: Dictionary = get_asset_snapshot(context)
	var event_log_snapshot: Array[Dictionary] = get_event_log_snapshot(context)
	var transaction_log_snapshot: Array[Dictionary] = get_transaction_log_snapshot(context)
	var content_def_snapshot: Dictionary = get_content_def_snapshot(context)
	var run_map_snapshot := build_run_map_snapshot(context)
	var map_result_preview := build_map_result(context)
	var run_flow_snapshot := build_run_flow_snapshot(context, run_map_snapshot, map_result_preview)
	var run_result: Dictionary = RunResultBuilderScript.build(context, ledger_snapshot, run_map_snapshot, map_result_preview, run_flow_snapshot)
	var current_room_detail := get_current_room_detail(context)
	var rule_summary_preview := build_rule_effect_modifier_summary(context, current_room_detail)
	var content_delivery_preview := build_content_delivery_summary(context, current_room_detail)
	return {
		"run_id": context.run_id,
		"mode": context.mode,
		"phase": context.phase,
		"run_started": context.run_started,
		"width": context.width,
		"height": context.height,
		"player_pos": context.player_pos,
		"hp": context.hp,
		"max_hp": context.max_hp,
		"power": context.power,
		"pressure": context.pressure,
		"protocol_level": context.protocol_level,
		"black_coin": ledger_snapshot.get("black_coin", context.pending_gold),
		"gold_coin": ledger_snapshot.get("gold_coin", context.safe_gold),
		"run_black_coin": ledger_snapshot.get("run_black_coin", context.pending_gold),
		"safe_yield": ledger_snapshot.get("safe_yield", context.safe_gold),
		"long_term_gold": ledger_snapshot.get("long_term_gold", 0),
		"long_term_gold_preview": ledger_snapshot.get("long_term_gold_preview", 0),
		"pending_gold": context.pending_gold,
		"safe_gold": context.safe_gold,
		"parts": context.parts,
		"backpack_capacity": ledger_snapshot.get("backpack_capacity", 0),
		"backpack_used": ledger_snapshot.get("backpack_used", 0),
		"backpack_remaining": ledger_snapshot.get("backpack_remaining", 0),
		"inventory_items": ledger_snapshot.get("inventory_items", []),
		"equipped_items": ledger_snapshot.get("equipped_items", []),
		"room_floor_items": ledger_snapshot.get("room_floor_items", []),
		"room_floor_item_count": ledger_snapshot.get("room_floor_item_count", 0),
		"warehouse_lite": ledger_snapshot.get("warehouse_lite", []),
		"settlement_log": ledger_snapshot.get("settlement_log", []),
		"event_log": event_log_snapshot,
		"event_count": event_log_snapshot.size(),
		"transaction_log": transaction_log_snapshot,
		"transaction_count": transaction_log_snapshot.size(),
		"content_definitions": content_def_snapshot,
		"content_definition_count": content_def_snapshot.size(),
		"debug_used": context.debug_used,
		"debug_commands": context.debug_commands.duplicate(true),
		"debug_command_count": context.debug_commands.size(),
		"run_map_snapshot": run_map_snapshot,
		"map_result_preview": map_result_preview,
		"run_flow_snapshot": run_flow_snapshot,
		"RunLifecycle": run_flow_snapshot.get("RunLifecycle", {}),
		"RunState": run_flow_snapshot.get("RunState", {}),
		"RoomTransition": run_flow_snapshot.get("RoomTransition", {}),
		"RoomActionResult": run_flow_snapshot.get("RoomActionResult", {}),
		"RunIntent": run_flow_snapshot.get("RunIntent", {}),
		"SettlementTriggerPreview": run_flow_snapshot.get("SettlementTriggerPreview", {}),
		"RunOutcomePreview": run_flow_snapshot.get("RunOutcomePreview", {}),
		"RunResult": run_result,
		"SettlementInput": run_result.duplicate(true),
		"map_summary_preview": map_result_preview.get("map_summary_preview", {}),
		"current_room_detail": current_room_detail,
		"room_common_rule_summary_preview": _room_common_rule_summary(current_room_detail),
		"room_resolution_summary_preview": map_result_preview.get("room_resolution_summary_preview", {}),
		"return_eligibility": current_room_detail.get("return_eligibility", {}),
		"rule_effect_modifier_summary_preview": rule_summary_preview,
		"content_delivery_summary_preview": content_delivery_preview,
		"RuleDefinition": rule_summary_preview.get("RuleDefinition", {}),
		"EffectPreview": rule_summary_preview.get("EffectPreview", {}),
		"EffectResultPreview": rule_summary_preview.get("EffectResultPreview", {}),
		"ModifierStackPreview": rule_summary_preview.get("ModifierStackPreview", {}),
		"ContentPool": content_delivery_preview.get("ContentPool", {}),
		"PoolResultPreview": content_delivery_preview.get("PoolResultPreview", {}),
		"objective_context_preview": run_map_snapshot.get("objective_context_preview", {}),
		"modifier_context_preview": run_map_snapshot.get("modifier_context_preview", {}),
		"pool_context_preview": content_delivery_preview.get("ContentDeliveryContext", {}),
		"room_loot_context_preview": run_map_snapshot.get("room_loot_context_preview", {}),
		"run_result_context_preview": run_map_snapshot.get("run_result_context_preview", {}),
		"status_effects": ledger_snapshot.get("status_effects", []),
		"position": context.player_pos,
		"current_room": context.current_room_type,
		"encounter_type": context.encounter_type,
		"encounter_tags": context.encounter_tags.duplicate(true),
		"blocked_reason": context.blocked_reason,
		"adjacent_mines": context.current_adjacent_mines,
		"search_state": get_search_state_label(context),
		"search_state_data": get_search_state_data(context),
		"encounter_view_model": get_encounter_view_model(context),
		"encounter_result_summary": get_encounter_result_summary(context),
		"event_state": context.event_state.duplicate(true),
		"enemy_state": context.enemy_state.duplicate(true),
		"last_message": context.last_message,
		"last_reward": context.last_reward.duplicate(true),
		"outcome": context.outcome,
		"run_active": context.run_active,
		"extracted": context.extracted,
		"failed": context.failed,
		"abandoned": context.abandoned,
		"exit_id": context.exit_id,
		"tutorial_popup": context.tutorial_popup.duplicate(true),
		"result_snapshot": context.result_snapshot.duplicate(true),
		"failure_salvage": context.failure_salvage.duplicate(true),
		"stats": context.run_stats.duplicate(true),
	}


func get_asset_snapshot(context: RunContext) -> Dictionary:
	if context == null or context.asset_ledger == null:
		return {}
	return context.asset_ledger.get_public_snapshot(context.player_pos)


func get_event_log_snapshot(context: RunContext) -> Array[Dictionary]:
	if context == null or context.run_event_log == null:
		return []
	return context.run_event_log.snapshot()


func get_transaction_log_snapshot(context: RunContext) -> Array[Dictionary]:
	if context == null or context.transaction_log == null:
		return []
	return context.transaction_log.snapshot()


func get_content_def_snapshot(context: RunContext) -> Dictionary:
	if context == null or context.content_defs == null:
		return {}
	return context.content_defs.snapshot()


func build_rule_effect_modifier_summary(context: RunContext, current_room_detail: Dictionary = {}) -> Dictionary:
	var rule_id := "room.%s.preview" % String(current_room_detail.get("room_type_key", "unknown"))
	var summary := RuleEffectModifierSchemaScript.build_rule_preview_summary({
		"ok": true,
		"status": &"preview",
		"rule_result": &"room_rule_preview",
		"effects": [],
	}, {
		"rule_id": rule_id,
		"run_id": "" if context == null else String(context.run_id),
		"room_type": current_room_detail.get("room_type", &"Unknown"),
	})
	summary["RoomRulePreview"] = _dictionary_from_variant(current_room_detail.get("RoomRulePreview", {}))
	summary["RoomCondition"] = _dictionary_from_variant(current_room_detail.get("RoomCondition", {}))
	summary["RoomResolutionPreview"] = _dictionary_from_variant(current_room_detail.get("RoomResolutionPreview", {}))
	if context != null and context.rule_pipeline != null:
		var pipeline_preview: Dictionary = context.rule_pipeline.content_modifier_context_preview()
		summary["ModifierStackPreview"] = _dictionary_from_variant(pipeline_preview.get("ModifierStackPreview", summary.get("ModifierStackPreview", {})))
		summary["ModifierConflictPolicy"] = _dictionary_from_variant(pipeline_preview.get("ModifierConflictPolicy", {}))
	summary["EffectPreview"] = RuleEffectModifierSchemaScript.default_effect_preview(RuleEffectModifierSchemaScript.default_effect_descriptor(&"room.preview"))
	summary["read_only"] = true
	summary["display_only"] = true
	summary["preview"] = true
	summary["no_persistence"] = true
	return summary


func build_content_delivery_summary(context: RunContext, current_room_detail: Dictionary = {}) -> Dictionary:
	var delivery_context := {
		"context_id": "room.%s.content_delivery_preview" % String(current_room_detail.get("room_type_key", "unknown")),
		"run_id": "" if context == null else String(context.run_id),
		"room_type": current_room_detail.get("room_type", &"Unknown"),
		"encounter_type": _dictionary_from_variant(current_room_detail.get("EncounterPreview", {})).get("encounter_type", &"none"),
		"seed": 0 if context == null else int(context.seed_value),
	}
	if context != null and context.content_defs != null:
		return context.content_defs.content_delivery_preview(delivery_context)
	return ContentDeliverySchemaScript.build_content_delivery_preview({}, delivery_context)


func build_run_map_snapshot(context: RunContext) -> Dictionary:
	if context == null or context.truth_map == null:
		return _empty_run_map_snapshot()
	return context.truth_map.build_run_map_snapshot(context.intel_map, context.player_pos)


func build_map_result(context: RunContext) -> Dictionary:
	if context == null or context.truth_map == null:
		return _empty_map_result()
	return context.truth_map.build_map_result(context.intel_map, context.player_pos)


func build_run_flow_snapshot(context: RunContext, run_map_snapshot: Dictionary = {}, map_result: Dictionary = {}) -> Dictionary:
	if context == null:
		return RunFlowStateContractScript.build_flow_snapshot()
	return RunFlowStateContractScript.build_flow_snapshot(context, run_map_snapshot, map_result)


func get_current_room_detail(context: RunContext) -> Dictionary:
	if context == null or context.truth_map == null:
		return {}
	var detail := context.truth_map.get_room_state(context.player_pos, context.intel_map)
	detail["schema_kind"] = &"RoomDetailPreview"
	detail["current_room"] = true
	return detail


func _room_common_rule_summary(room_detail: Dictionary) -> Dictionary:
	return {
		"schema_kind": &"room_common_rule_summary_preview",
		"room_type": room_detail.get("room_type", &"Unknown"),
		"RoomTag": room_detail.get("RoomTag", []),
		"RoomPolicy": room_detail.get("RoomPolicy", {}),
		"RoomContentSlot": room_detail.get("RoomContentSlot", {}),
		"EncounterEntry": room_detail.get("EncounterEntry", {}),
		"EncounterPreview": room_detail.get("EncounterPreview", {}),
		"RoomRulePreview": room_detail.get("RoomRulePreview", {}),
		"RoomResolutionPreview": room_detail.get("RoomResolutionPreview", {}),
		"RoomResultPreview": room_detail.get("RoomResultPreview", {}),
		"GroundLoot": room_detail.get("GroundLoot", {}),
		"RoomLootContainer": room_detail.get("RoomLootContainer", {}),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func get_inventory_summary(context: RunContext) -> Dictionary:
	var snapshot: Dictionary = get_asset_snapshot(context)
	return {
		"backpack_capacity": snapshot.get("backpack_capacity", 0),
		"backpack_used": snapshot.get("backpack_used", 0),
		"backpack_remaining": snapshot.get("backpack_remaining", 0),
		"inventory_items": snapshot.get("inventory_items", []),
		"equipped_items": snapshot.get("equipped_items", []),
		"room_floor_items": snapshot.get("room_floor_items", []),
		"room_floor_item_count": snapshot.get("room_floor_item_count", 0),
	}


func get_encounter_summary(context: RunContext) -> Dictionary:
	if context == null:
		return {"encounter_type": &"none", "encounter_tags": []}
	var identity: Dictionary = EncounterResolverScript.get_encounter_identity(context, context.current_room_type, context.get_current_pos())
	identity["blocked_reason"] = context.blocked_reason
	return identity


func get_encounter_view_model(context: RunContext) -> Dictionary:
	return EncounterResolverScript.build_view_model(context)


func get_encounter_result_summary(context: RunContext) -> Dictionary:
	return EncounterResolverScript.build_result_summary(context)


func get_search_state_label(context: RunContext) -> String:
	if context == null:
		return "blocked"
	if context.searched_cells.has(context.cell_key(context.player_pos)):
		return "searched"
	match context.current_room_type:
		&"Normal":
			return "searchable"
		&"Chest":
			return "chest"
		_:
			return "blocked"


func get_search_state_data(context: RunContext) -> Dictionary:
	if context == null or context.truth_map == null:
		return {"can_search": false, "searched": false, "reason": "not_ready", "is_chest": false}
	var key: String = context.cell_key(context.player_pos)
	var searched: bool = context.searched_cells.has(key)
	var can_search: bool = false
	var reason: String = "blocked"
	var is_chest: bool = false
	if searched:
		reason = "searched"
	elif context.player_pos == context.truth_map.spawn_pos:
		reason = "spawn"
	elif context.current_room_type == &"Normal":
		can_search = true
		reason = "searchable"
	elif context.current_room_type == &"Chest":
		can_search = true
		reason = "chest"
		is_chest = true
	elif context.current_room_type == &"Event":
		reason = "event"
	elif context.current_room_type == &"Monster":
		reason = "monster"
	elif context.current_room_type == &"Exit":
		reason = "exit"
	elif context.current_room_type == &"Mine":
		reason = "mine"
	return {
		"can_search": can_search,
		"searched": searched,
		"reason": reason,
		"is_chest": is_chest,
	}


func _empty_run_map_snapshot() -> Dictionary:
	return {
		"schema_kind": &"RunMapSnapshot",
		"RunMap": {},
		"TruthMap": {"access": &"internal_only"},
		"KnownMap": {},
		"ScanLayer": {},
		"MarkMap": {},
		"RunMapState": {},
		"InfoReliabilityLayer": {},
		"map_summary_preview": {},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func _empty_map_result() -> Dictionary:
	return {
		"schema_kind": &"MapResult",
		"map_summary_preview": {},
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
