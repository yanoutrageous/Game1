extends RefCounted
class_name RunFlowStateContract

# G32 read-only run lifecycle / transition snapshot contract.
# This file must not dispatch commands, persist state, grant rewards, or write assets.

const SCHEMA_VERSION := 1

const LIFECYCLE_INITIALIZED := &"initialized"
const LIFECYCLE_ACTIVE := &"active"
const LIFECYCLE_RUNNING := &"running"
const LIFECYCLE_LOCKED := &"locked"
const LIFECYCLE_CONFIRM_EXTRACT := &"confirm_extract"
const LIFECYCLE_EXTRACTED := &"extracted"
const LIFECYCLE_FAILED := &"failed"
const LIFECYCLE_ABANDONED := &"abandoned"
const LIFECYCLE_SETTLEMENT_PENDING := &"settlement_pending"

const ROOM_FLOW_ARRIVE := &"arrive"
const ROOM_FLOW_OBSERVE := &"observe"
const ROOM_FLOW_HANDLE := &"handle"
const ROOM_FLOW_LEAVE := &"leave"


static func build_flow_snapshot(context: RunContext = null, run_map_snapshot: Dictionary = {}, map_result: Dictionary = {}) -> Dictionary:
	var lifecycle: Dictionary = build_run_lifecycle(context)
	var state: Dictionary = build_run_state(context)
	var transition: Dictionary = build_room_transition(context, run_map_snapshot)
	var settlement_trigger: Dictionary = build_settlement_trigger_preview(context, map_result)
	var outcome: Dictionary = build_run_outcome_preview(context, settlement_trigger)
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunFlowSnapshot",
		"RunLifecycle": lifecycle,
		"RunState": state,
		"RoomTransition": transition,
		"RoomActionResult": build_room_action_result(context),
		"RunIntent": build_run_intent_preview(context),
		"SettlementTriggerPreview": settlement_trigger,
		"RunOutcomePreview": outcome,
		"RunResult": build_run_result_draft(context, map_result, outcome),
		"rule_effect_modifier_context_preview": _placeholder(&"rule_effect_modifier_context_preview"),
		"content_delivery_context_preview": _placeholder(&"content_delivery_context_preview"),
		"map_snapshot_ref": &"RunMapSnapshot",
		"map_result_ref": &"MapResult",
		"context_placeholders": _context_placeholders(),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_run_lifecycle(context: RunContext = null) -> Dictionary:
	var lifecycle_state: StringName = _lifecycle_state_for(context)
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunLifecycle",
		"state": lifecycle_state,
		"phase": _phase_for(context),
		"allowed_states": [
			LIFECYCLE_INITIALIZED,
			LIFECYCLE_ACTIVE,
			LIFECYCLE_RUNNING,
			LIFECYCLE_LOCKED,
			LIFECYCLE_CONFIRM_EXTRACT,
			LIFECYCLE_EXTRACTED,
			LIFECYCLE_FAILED,
			LIFECYCLE_ABANDONED,
			LIFECYCLE_SETTLEMENT_PENDING,
		],
		"run_started": _bool_from_context(context, "run_started"),
		"run_active": _bool_from_context(context, "run_active"),
		"terminal": lifecycle_state in [LIFECYCLE_EXTRACTED, LIFECYCLE_FAILED, LIFECYCLE_ABANDONED],
		"locked": lifecycle_state == LIFECYCLE_LOCKED or lifecycle_state == LIFECYCLE_CONFIRM_EXTRACT,
		"settlement_pending": lifecycle_state in [LIFECYCLE_EXTRACTED, LIFECYCLE_FAILED, LIFECYCLE_ABANDONED],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_run_state(context: RunContext = null) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunState",
		"run_id": _run_id_for(context),
		"mode": _mode_for(context),
		"phase": _phase_for(context),
		"outcome": _outcome_for(context),
		"turn": _int_from_context(context, "turn"),
		"position": _position_for(context),
		"current_room": _room_for(context),
		"run_active": _bool_from_context(context, "run_active"),
		"extracted": _bool_from_context(context, "extracted"),
		"failed": _bool_from_context(context, "failed"),
		"blocked_reason": _string_from_context(context, "blocked_reason"),
		"flow_boundary": "read-only public run state; no SaveManager or active-run persistence",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_room_transition(context: RunContext = null, run_map_snapshot: Dictionary = {}) -> Dictionary:
	var current_room_detail: Dictionary = {}
	var return_eligibility: Dictionary = {}
	if context != null and context.truth_map != null:
		current_room_detail = context.truth_map.get_room_state(context.player_pos, context.intel_map)
		return_eligibility = current_room_detail.get("return_eligibility", {})
	var flow_steps: Array[Dictionary] = [
		_flow_step(ROOM_FLOW_ARRIVE, "current room is entered or restored from existing run state"),
		_flow_step(ROOM_FLOW_OBSERVE, "public snapshot observes KnownMap / HUD / RunSurface state"),
		_flow_step(ROOM_FLOW_HANDLE, "search / interact / fight / event option / chest / exit confirm route"),
		_flow_step(ROOM_FLOW_LEAVE, "adjacent move or fast_return eligibility intent"),
	]
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RoomTransition",
		"position": _position_for(context),
		"room_type": _room_for(context),
		"room_flow": flow_steps,
		"entry_mode": &"adjacent_or_return_preview",
		"entry_source": &"existing_run_route",
		"current_room_detail": current_room_detail,
		"RoomType": _dictionary_from_variant(current_room_detail.get("RoomType", {})),
		"RoomTag": _array_from_variant(current_room_detail.get("RoomTag", [])),
		"RoomPolicy": _dictionary_from_variant(current_room_detail.get("RoomPolicy", {})),
		"RoomContentSlot": _dictionary_from_variant(current_room_detail.get("RoomContentSlot", {})),
		"EncounterEntry": _dictionary_from_variant(current_room_detail.get("EncounterEntry", {})),
		"EncounterPreview": _dictionary_from_variant(current_room_detail.get("EncounterPreview", {})),
		"RoomRulePreview": _dictionary_from_variant(current_room_detail.get("RoomRulePreview", {})),
		"RoomResolutionPreview": _dictionary_from_variant(current_room_detail.get("RoomResolutionPreview", {})),
		"return_eligibility": return_eligibility,
		"fast_return": bool(return_eligibility.get("eligible", false)),
		"illegal_target_policy": &"disabled_reason_only",
		"map_snapshot_ref": &"RunMapSnapshot" if not run_map_snapshot.is_empty() else &"unavailable",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_room_action_result(context: RunContext = null, command_result: Dictionary = {}) -> Dictionary:
	var ok: bool = bool(command_result.get("ok", false)) if not command_result.is_empty() else false
	var action_id: StringName = StringName(command_result.get("command", command_result.get("command_name", &"current_action_preview")))
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RoomActionResult",
		"action_id": action_id,
		"ok": ok,
		"status": StringName(command_result.get("status", &"preview_unavailable")),
		"disabled_reason": String(command_result.get("reason", command_result.get("blocked_reason", ""))),
		"room_type": _room_for(context),
		"supported_action_channels": [&"enter_room", &"search", &"interact", &"fight", &"event_option", &"chest_open", &"exit_confirm"],
		"reward_context_preview": _placeholder(&"reward_context_preview"),
		"rule_effect_modifier_context_preview": _placeholder(&"rule_effect_modifier_context_preview"),
		"content_delivery_context_preview": _placeholder(&"content_delivery_context_preview"),
		"objective_context_preview": _placeholder(&"objective_context_preview"),
		"room_loot_context_preview": _placeholder(&"room_loot_context_preview"),
		"RoomResolutionPreview": _room_resolution_preview_for(context),
		"RoomResultPreview": _room_result_preview_for(context),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_run_intent_preview(context: RunContext = null) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunIntent",
		"start": build_start_intent_preview(),
		"continue": build_continue_intent_preview(context),
		"abandon": build_abandon_intent_preview(context),
		"route_boundary": &"existing_run_route_only",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_start_intent_preview(payload: Dictionary = {}) -> Dictionary:
	return {
		"intent_id": &"start_existing_route",
		"target_route": &"run",
		"fallback_route_mode": StringName(payload.get("route_mode", &"demo_run")),
		"deploy_config_bridge": bool(payload.get("deploy_config_bridge", false)),
		"supported_now": true,
		"disabled_reason": &"",
		"boundary": "Uses existing demo/standard run route; does not create a real deploy-config RunBootstrapper.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func build_continue_intent_preview(context: RunContext = null) -> Dictionary:
	var has_active: bool = context != null and bool(context.run_active)
	return {
		"intent_id": &"continue_run_preview",
		"supported_now": has_active,
		"disabled_reason": &"" if has_active else &"no_active_run_persistence",
		"boundary": "Continue recovery requires future active-run persistence; this slice only reports disabled/preview state.",
		"strong_confirm_required": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func build_abandon_intent_preview(context: RunContext = null) -> Dictionary:
	var has_active: bool = context != null and bool(context.run_active)
	return {
		"intent_id": &"abandon_run_preview",
		"supported_now": false,
		"disabled_reason": &"settlement_runtime_not_connected",
		"has_active_run": has_active,
		"strong_confirm_required": has_active,
		"boundary": "Abandon is strong-confirm intent only; no real abandon settlement or persistence write.",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func build_settlement_trigger_preview(context: RunContext = null, map_result: Dictionary = {}) -> Dictionary:
	var lifecycle_state: StringName = _lifecycle_state_for(context)
	var trigger_state: StringName = LIFECYCLE_SETTLEMENT_PENDING if lifecycle_state in [LIFECYCLE_EXTRACTED, LIFECYCLE_FAILED, LIFECYCLE_ABANDONED] else &"not_ready"
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"SettlementTriggerPreview",
		"trigger_state": trigger_state,
		"source_lifecycle_state": lifecycle_state,
		"map_result_preview": map_result.duplicate(true),
		"writes_warehouse": false,
		"grants_reward": false,
		"persists_history": false,
		"boundary": "Settlement trigger is a handoff preview only.",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_run_outcome_preview(context: RunContext = null, settlement_trigger: Dictionary = {}) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunOutcomePreview",
		"outcome": _outcome_for(context),
		"lifecycle_state": _lifecycle_state_for(context),
		"settlement_trigger_state": settlement_trigger.get("trigger_state", &"not_ready"),
		"result_type": _result_type_for(context),
		"writes_assets": false,
		"advances_objectives": false,
		"grants_rewards": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_run_result_draft(context: RunContext = null, map_result: Dictionary = {}, outcome_preview: Dictionary = {}) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"RunResult",
		"draft_only": true,
		"run_id": _run_id_for(context),
		"mode": _mode_for(context),
		"outcome_preview": outcome_preview.duplicate(true),
		"map_result": map_result.duplicate(true),
		"settlement_trigger_ref": &"SettlementTriggerPreview",
		"objective_context_preview": _placeholder(&"objective_context_preview"),
		"reward_context_preview": _placeholder(&"reward_context_preview"),
		"pool_context_preview": _placeholder(&"pool_context_preview"),
		"modifier_context_preview": _placeholder(&"modifier_context_preview"),
		"rule_effect_modifier_context_preview": _placeholder(&"rule_effect_modifier_context_preview"),
		"content_delivery_context_preview": _placeholder(&"content_delivery_context_preview"),
		"room_loot_context_preview": _placeholder(&"room_loot_context_preview"),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _lifecycle_state_for(context: RunContext = null) -> StringName:
	if context == null or not bool(context.run_started):
		return LIFECYCLE_INITIALIZED
	if bool(context.failed):
		return LIFECYCLE_FAILED
	if bool(context.extracted):
		return LIFECYCLE_EXTRACTED
	if StringName(context.phase) == LIFECYCLE_CONFIRM_EXTRACT:
		return LIFECYCLE_CONFIRM_EXTRACT
	if context.has_blocking_tutorial_popup():
		return LIFECYCLE_LOCKED
	if bool(context.run_active):
		return LIFECYCLE_RUNNING
	return LIFECYCLE_ACTIVE


static func _result_type_for(context: RunContext = null) -> StringName:
	var lifecycle_state: StringName = _lifecycle_state_for(context)
	match lifecycle_state:
		LIFECYCLE_EXTRACTED:
			return &"success"
		LIFECYCLE_FAILED:
			return &"failed"
		LIFECYCLE_ABANDONED:
			return &"abandoned"
		_:
			return &"running"


static func _phase_for(context: RunContext = null) -> StringName:
	return StringName(context.phase) if context != null else &"idle"


static func _run_id_for(context: RunContext = null) -> StringName:
	return StringName(context.run_id) if context != null else &""


static func _mode_for(context: RunContext = null) -> StringName:
	return StringName(context.mode) if context != null else &""


static func _room_for(context: RunContext = null) -> StringName:
	return StringName(context.current_room_type) if context != null else &"Unknown"


static func _position_for(context: RunContext = null) -> Vector2i:
	return context.player_pos if context != null else Vector2i.ZERO


static func _outcome_for(context: RunContext = null) -> String:
	return String(context.outcome) if context != null else "Idle"


static func _bool_from_context(context: RunContext, field: String) -> bool:
	if context == null:
		return false
	match field:
		"run_started":
			return bool(context.run_started)
		"run_active":
			return bool(context.run_active)
		"extracted":
			return bool(context.extracted)
		"failed":
			return bool(context.failed)
		_:
			return false


static func _int_from_context(context: RunContext, field: String) -> int:
	if context == null:
		return 0
	match field:
		"turn":
			return int(context.turn)
		_:
			return 0


static func _string_from_context(context: RunContext, field: String) -> String:
	if context == null:
		return ""
	match field:
		"blocked_reason":
			return String(context.blocked_reason)
		_:
			return ""


static func _flow_step(step_id: StringName, summary: String) -> Dictionary:
	return {
		"step_id": step_id,
		"summary": summary,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func _context_placeholders() -> Dictionary:
	return {
		"objective": _placeholder(&"objective_context_preview"),
		"reward": _placeholder(&"reward_context_preview"),
		"pool": _placeholder(&"pool_context_preview"),
		"modifier": _placeholder(&"modifier_context_preview"),
		"rule_effect_modifier": _placeholder(&"rule_effect_modifier_context_preview"),
		"content_delivery": _placeholder(&"content_delivery_context_preview"),
		"room_loot": _placeholder(&"room_loot_context_preview"),
		"room_resolution": _placeholder(&"room_resolution_summary_preview"),
	}


static func _placeholder(context_id: StringName) -> Dictionary:
	return {
		"context_id": context_id,
		"state": &"reserved_preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _room_resolution_preview_for(context: RunContext = null) -> Dictionary:
	if context == null or context.truth_map == null:
		return {}
	var detail: Dictionary = context.truth_map.get_room_state(context.player_pos, context.intel_map)
	return _dictionary_from_variant(detail.get("RoomResolutionPreview", {}))


static func _room_result_preview_for(context: RunContext = null) -> Dictionary:
	if context == null or context.truth_map == null:
		return {}
	var detail: Dictionary = context.truth_map.get_room_state(context.player_pos, context.intel_map)
	return _dictionary_from_variant(detail.get("RoomResultPreview", {}))


static func _array_from_variant(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _dictionary_from_variant(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}
