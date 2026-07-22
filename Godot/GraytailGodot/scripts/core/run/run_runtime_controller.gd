extends RefCounted
class_name RunRuntimeController

const CommandBusScript := preload("res://scripts/core/command/command_bus.gd")
const G41InRunRuntimeScript := preload("res://scripts/core/run/g41_in_run_runtime.gd")
const RunContextScript := preload("res://scripts/core/run/run_context.gd")
const RunStateMachineScript := preload("res://scripts/core/run/run_state_machine.gd")

const META_ACTION_PURCHASE := &"purchase"
const META_ACTION_SELL := &"sell_collectible"
const META_ACTION_RESEARCH := &"complete_research"
const META_ACTION_CLAIM := &"claim_goal"
const META_ACTION_MARK_VIEWED := &"mark_viewed"

var context
var command_bus
var in_run_runtime
var state_machine
var meta_progress_adapter
var last_meta_commit: Dictionary = {}
var _meta_action_cache: Dictionary = {}


func _init() -> void:
	context = RunContextScript.new()
	state_machine = RunStateMachineScript.new()
	command_bus = CommandBusScript.new()
	command_bus.bind_runtime_controller(self)
	command_bus.result_available.connect(_on_terminal_result_available)
	in_run_runtime = G41InRunRuntimeScript.new()
	in_run_runtime.bind(self)


func describe_ownership() -> Dictionary:
	return {
		"runtime_owner": "RunRuntimeController",
		"context_owner": "RunRuntimeController",
		"command_bus_owner": "RunRuntimeController",
		"lifecycle_owner": "RunStateMachine",
		"active_combat_owner": "G41CombatSimulation through G41InRunRuntime",
		"world_item_owner": "RunAssetLedger; room entities are read-only projections",
		"scene_owner": "RunScene orchestration only",
		"writable_context_instances": 1,
		"read_only": false,
	}


func start_demo_run(room_resolver: RoomResolver) -> Dictionary:
	var result: Dictionary = state_machine.start_demo_run(context)
	_finalize_start(result, room_resolver)
	return _with_actor(result)


func start_tutorial_run(room_resolver: RoomResolver) -> Dictionary:
	var result: Dictionary = state_machine.start_tutorial_run(context)
	_finalize_start(result, room_resolver)
	return _with_actor(result)


func start_standard_run(room_resolver: RoomResolver, run_start_config: Dictionary = {}) -> Dictionary:
	var result: Dictionary = state_machine.start_standard_run(context, run_start_config)
	_finalize_start(result, room_resolver)
	return _with_actor(result)


func request_extract(room_resolver: RoomResolver, command_id: String, actor_id: StringName) -> Dictionary:
	var result: Dictionary = state_machine.request_extract(context, room_resolver != null and room_resolver.can_extract(context), command_id, actor_id)
	return _with_actor(result)


func confirm_extract(room_resolver: RoomResolver) -> Dictionary:
	var result: Dictionary = state_machine.confirm_extract(context, room_resolver != null and room_resolver.can_extract(context))
	if bool(result.get("ok", false)) and context != null and not context.run_active:
		in_run_runtime.reset()
	return _with_actor(result)


func cancel_extract() -> Dictionary:
	return _with_actor(state_machine.cancel_extract(context))


func extract(room_resolver: RoomResolver, command_id: String, actor_id: StringName) -> Dictionary:
	var request_result := request_extract(room_resolver, command_id, actor_id)
	if context != null and context.phase == &"confirm_extract":
		return confirm_extract(room_resolver)
	return request_result


func restart_run(room_resolver: RoomResolver) -> Dictionary:
	if context == null:
		return _with_actor({"ok": false, "status": &"not_ready", "reason_code": "not_ready"})
	var result: Dictionary
	match context.mode:
		&"standard":
			result = state_machine.restart_standard_run(context, context.run_start_config.duplicate(true))
		&"tutorial":
			result = state_machine.restart_tutorial_run(context)
		&"demo":
			result = state_machine.restart_demo_run(context)
		_:
			return _with_actor({"ok": false, "status": &"restart_mode_unsupported", "reason_code": "restart_mode_unsupported"})
	_finalize_start(result, room_resolver)
	return _with_actor(result)


func bind_meta_progress_adapter(adapter) -> void:
	var adapter_changed: bool = meta_progress_adapter != adapter
	meta_progress_adapter = adapter
	last_meta_commit.clear()
	if adapter_changed:
		_clear_meta_action_cache()


func execute_meta_action(action: Dictionary) -> Dictionary:
	var request_id := _exact_meta_id(action.get("request_id", ""))
	var source_page := _exact_meta_id(action.get("source_page", ""))
	var action_id := StringName(_exact_meta_id(action.get("action", "")))
	if request_id.is_empty():
		return _meta_action_error("", source_page, action_id, "", &"missing_request_id")
	if source_page.is_empty():
		return _meta_action_error(request_id, "", action_id, "", &"missing_source_page")
	if action_id == &"":
		return _meta_action_error(request_id, source_page, &"", "", &"missing_action")
	var normalized := _normalize_meta_action(source_page, action_id, action)
	if not bool(normalized.get("ok", false)):
		return _meta_action_error(
			request_id,
			source_page,
			action_id,
			str(normalized.get("target_id", "")),
			StringName(normalized.get("status", &"invalid_meta_action"))
		)
	var payload: Dictionary = normalized.get("payload", {})
	var target_id := str(normalized.get("target_id", ""))
	if _meta_action_cache.has(request_id):
		var cached_entry: Dictionary = _meta_action_cache.get(request_id, {})
		if cached_entry.get("payload", {}) == payload:
			var duplicate_envelope: Dictionary = cached_entry.get("envelope", {}).duplicate(true)
			duplicate_envelope["duplicate"] = true
			return duplicate_envelope
		var cached_envelope: Dictionary = cached_entry.get("envelope", {})
		var conflict_summary: Dictionary = _dictionary_copy(cached_envelope.get("meta_progress_summary", {}))
		return _meta_action_error(request_id, source_page, action_id, target_id, &"request_id_conflict", conflict_summary)
	if meta_progress_adapter == null:
		return _meta_action_error(request_id, source_page, action_id, target_id, &"meta_progress_adapter_missing")
	var adapter_result := _dispatch_meta_action(payload)
	var summary := _meta_summary_after_action(adapter_result)
	var envelope := {
		"request_id": request_id,
		"source_page": source_page,
		"action": action_id,
		"target_id": target_id,
		"ok": bool(adapter_result.get("ok", false)),
		"status": StringName(adapter_result.get("status", &"ok" if bool(adapter_result.get("ok", false)) else &"failed")),
		"duplicate": false,
		"result": adapter_result.duplicate(true),
		"meta_progress_summary": summary,
	}
	_store_meta_action_result(request_id, payload, envelope)
	return envelope.duplicate(true)


func meta_progress_summary() -> Dictionary:
	if meta_progress_adapter == null:
		return {}
	return meta_progress_adapter.get_summary()


func _normalize_meta_action(source_page: String, action_id: StringName, action: Dictionary) -> Dictionary:
	var payload := {
		"source_page": source_page,
		"action": action_id,
	}
	var target_id := ""
	match action_id:
		META_ACTION_PURCHASE:
			target_id = _exact_meta_id(action.get("item_id", ""))
			if target_id.is_empty():
				return {"ok": false, "status": &"missing_target_id"}
			payload["item_id"] = target_id
		META_ACTION_SELL:
			target_id = _exact_meta_id(action.get("instance_id", ""))
			if target_id.is_empty():
				return {"ok": false, "status": &"missing_target_id"}
			payload["instance_id"] = target_id
			payload["blocked_instance_ids"] = _normalized_blocked_instance_ids(action)
		META_ACTION_RESEARCH:
			target_id = _exact_meta_id(action.get("research_id", ""))
			if target_id.is_empty():
				return {"ok": false, "status": &"missing_target_id"}
			payload["research_id"] = target_id
			payload["blocked_instance_ids"] = _normalized_blocked_instance_ids(action)
		META_ACTION_CLAIM:
			var goal_kind := _exact_meta_id(action.get("goal_kind", ""))
			var goal_id := _exact_meta_id(action.get("goal_id", ""))
			if goal_kind.is_empty() or goal_id.is_empty():
				return {"ok": false, "status": &"missing_target_id"}
			target_id = "%s:%s" % [goal_kind, goal_id]
			payload["goal_kind"] = goal_kind
			payload["goal_id"] = goal_id
		META_ACTION_MARK_VIEWED:
			target_id = _exact_meta_id(action.get("view_kind", ""))
			if target_id.is_empty():
				return {"ok": false, "status": &"missing_target_id"}
			payload["view_kind"] = target_id
		_:
			return {"ok": false, "status": &"unknown_meta_action"}
	return {
		"ok": true,
		"target_id": target_id,
		"payload": payload,
	}


func _dispatch_meta_action(payload: Dictionary) -> Dictionary:
	var action_id := StringName(payload.get("action", &""))
	var result: Variant
	match action_id:
		META_ACTION_PURCHASE:
			result = meta_progress_adapter.purchase_item(str(payload.get("item_id", "")))
		META_ACTION_SELL:
			result = meta_progress_adapter.sell_collectible(
				str(payload.get("instance_id", "")),
				_array_copy(payload.get("blocked_instance_ids", []))
			)
		META_ACTION_RESEARCH:
			result = meta_progress_adapter.complete_research(
				str(payload.get("research_id", "")),
				_array_copy(payload.get("blocked_instance_ids", []))
			)
		META_ACTION_CLAIM:
			result = meta_progress_adapter.claim_goal_reward(
				str(payload.get("goal_kind", "")),
				str(payload.get("goal_id", ""))
			)
		META_ACTION_MARK_VIEWED:
			result = meta_progress_adapter.mark_long_term_viewed(str(payload.get("view_kind", "")))
		_:
			return {"ok": false, "status": &"unknown_meta_action"}
	if result is Dictionary:
		return (result as Dictionary).duplicate(true)
	return {"ok": false, "status": &"invalid_meta_action_result"}


func _meta_summary_after_action(result: Dictionary) -> Dictionary:
	var result_summary := _dictionary_copy(result.get("summary", {}))
	if not result_summary.is_empty():
		return result_summary
	if meta_progress_adapter != null and meta_progress_adapter.has_method("get_summary"):
		var adapter_summary: Variant = meta_progress_adapter.get_summary()
		if adapter_summary is Dictionary:
			return (adapter_summary as Dictionary).duplicate(true)
	return {}


func _store_meta_action_result(request_id: String, payload: Dictionary, envelope: Dictionary) -> void:
	_meta_action_cache[request_id] = {
		"payload": payload.duplicate(true),
		"envelope": envelope.duplicate(true),
	}


func _clear_meta_action_cache() -> void:
	_meta_action_cache.clear()


func _meta_action_error(
	request_id: String,
	source_page: String,
	action_id: StringName,
	target_id: String,
	status: StringName,
	summary: Dictionary = {}
) -> Dictionary:
	return {
		"request_id": request_id,
		"source_page": source_page,
		"action": action_id,
		"target_id": target_id,
		"ok": false,
		"status": status,
		"duplicate": false,
		"result": {"ok": false, "status": status},
		"meta_progress_summary": summary.duplicate(true),
	}


func _normalized_blocked_instance_ids(action: Dictionary) -> Array[String]:
	var unique: Dictionary = {}
	for key in ["blocked_instance_ids", "selected_equipment_ids", "selected_consumable_ids"]:
		var raw_values: Variant = action.get(key, [])
		if not raw_values is Array:
			continue
		for raw_value in raw_values as Array:
			var instance_id := _exact_meta_id(raw_value)
			if not instance_id.is_empty():
				unique[instance_id] = true
	var normalized: Array[String] = []
	for raw_instance_id in unique.keys():
		normalized.append(str(raw_instance_id))
	normalized.sort()
	return normalized


func _exact_meta_id(value: Variant) -> String:
	if not (value is String or value is StringName):
		return ""
	return str(value).strip_edges()


func _array_copy(value: Variant) -> Array:
	return (value as Array).duplicate(true) if value is Array else []


func _dictionary_copy(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _on_terminal_result_available(result_snapshot: Dictionary) -> void:
	var settlement: Dictionary = result_snapshot.get("settlement", {})
	var awaiting_salvage := bool(settlement.get("requires_salvage_selection", false)) and not bool(settlement.get("finalized", false))
	if awaiting_salvage:
		last_meta_commit = {
			"ok": false,
			"status": &"awaiting_salvage_confirmation",
			"committed": false,
		}
		return
	if meta_progress_adapter == null:
		last_meta_commit = {
			"ok": false,
			"status": &"meta_progress_adapter_missing",
			"committed": false,
		}
		return
	last_meta_commit = meta_progress_adapter.apply_settlement(result_snapshot)


func debug_force_extract() -> Dictionary:
	var result := _with_actor(state_machine.force_extract(context))
	in_run_runtime.reset()
	return result


func fail_run(reason: String = "forced_failure") -> Dictionary:
	var result := _with_actor(state_machine.fail_run(context, reason))
	in_run_runtime.reset()
	return result


func confirm_failure_salvage(selected_instance_ids: Array) -> Dictionary:
	var result := _with_actor(state_machine.confirm_failure_salvage(context, selected_instance_ids))
	in_run_runtime.reset()
	return result


func abandon_run(reason: String = "player_abandoned") -> Dictionary:
	var result := _with_actor(state_machine.abandon_run(context, reason))
	in_run_runtime.reset()
	return result


func debug_force_fail(reason: String = "debug_forced_failure") -> Dictionary:
	var result: Dictionary = fail_run(reason)
	if context != null:
		context.last_message = "Debug forced failure through RunStateMachine."
	return result


func _enter_room_after_start(room_resolver: RoomResolver) -> void:
	if room_resolver != null and context != null:
		room_resolver.enter_room(context)


func _finalize_start(result: Dictionary, room_resolver: RoomResolver) -> void:
	if not bool(result.get("ok", false)):
		return
	last_meta_commit.clear()
	in_run_runtime.reset()
	_enter_room_after_start(room_resolver)


func _with_actor(result: Dictionary) -> Dictionary:
	var output := result.duplicate(true)
	if not output.has("actor_id"):
		output["actor_id"] = &"player"
	output["runtime_authority"] = "RunRuntimeController"
	return output
