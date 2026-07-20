extends RefCounted
class_name RunStateMachine

const TRANSITION_RESET := &"reset"
const TRANSITION_START := &"start"
const TRANSITION_REQUEST_EXTRACT := &"request_extract"
const TRANSITION_CONFIRM_EXTRACT := &"confirm_extract"
const TRANSITION_CANCEL_EXTRACT := &"cancel_extract"
const TRANSITION_FAIL := &"fail"
const TRANSITION_CONFIRM_FAILURE := &"confirm_failure_salvage"
const TRANSITION_ABANDON := &"abandon"
const TRANSITION_RESTART := &"restart"

const PHASE_IDLE := &"idle"
const PHASE_RUNNING := &"running"
const PHASE_CONFIRM_EXTRACT := &"confirm_extract"
const PHASE_FAILURE_SALVAGE := &"failure_salvage"
const PHASE_FAILED := &"failed"
const PHASE_EXTRACTED := &"extracted"
const PHASE_ABANDONED := &"abandoned"

const ACTIVE_PHASES: Array[StringName] = [PHASE_RUNNING, PHASE_CONFIRM_EXTRACT]
const ABANDONABLE_PHASES: Array[StringName] = [PHASE_RUNNING, PHASE_CONFIRM_EXTRACT, PHASE_FAILURE_SALVAGE]
const STARTABLE_PHASES: Array[StringName] = [PHASE_IDLE, PHASE_FAILED, PHASE_EXTRACTED, PHASE_ABANDONED]


func reset_context(context: RunContext) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	context._reset_data()
	return _write_phase(context, PHASE_IDLE, TRANSITION_RESET, [], true)


func start_run(context: RunContext, config: Dictionary) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase not in STARTABLE_PHASES:
		return _blocked_transition(&"active_run_exists", "active_run_exists", context.phase, PHASE_RUNNING, TRANSITION_START)
	context._initialize_run(config)
	var transition_result := _write_phase(context, PHASE_RUNNING, TRANSITION_START, STARTABLE_PHASES)
	if not bool(transition_result.get("ok", false)):
		return transition_result
	return {"ok": true, "status": &"run_started", "mode": context.mode, "transition": TRANSITION_START}


func restart_run(context: RunContext, config: Dictionary) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase not in ACTIVE_PHASES:
		return _blocked_transition(&"restart_not_active", "restart_not_active", context.phase, PHASE_RUNNING, TRANSITION_RESTART)
	context._initialize_run(config)
	var transition_result := _write_phase(context, PHASE_RUNNING, TRANSITION_RESTART, ACTIVE_PHASES, true)
	if not bool(transition_result.get("ok", false)):
		return transition_result
	return {"ok": true, "status": &"run_restarted", "mode": context.mode, "transition": TRANSITION_RESTART}


func start_demo_run(context: RunContext) -> Dictionary:
	return start_run(context, _demo_config())


func restart_demo_run(context: RunContext) -> Dictionary:
	return restart_run(context, _demo_config())


func _demo_config() -> Dictionary:
	return {
		"id": &"demo_s1",
		"mode": &"demo",
		"seed": 1001,
		"width": 7,
		"height": 7,
		"mine_hits_are_fatal": false,
		"reveal_on_move": true,
		"move_requires_revealed": false,
		"manual_map": {
			"spawn": Vector2i(3, 3),
			"mines": [Vector2i(2, 2), Vector2i(4, 2), Vector2i(5, 5)],
			"events": [Vector2i(5, 1)],
			"monsters": [Vector2i(1, 5)],
			"chests": [Vector2i(1, 1)],
			"exits": [{"pos": Vector2i(6, 6), "exit_id": &"demo_exit", "random_exit": false}],
		},
	}


func start_tutorial_run(context: RunContext) -> Dictionary:
	return start_run(context, RunConfig.tutorial_5x5())


func restart_tutorial_run(context: RunContext) -> Dictionary:
	return restart_run(context, RunConfig.tutorial_5x5())


func start_standard_run(context: RunContext, run_start_config: Dictionary = {}) -> Dictionary:
	return start_run(context, RunConfig.m7_map(run_start_config))


func restart_standard_run(context: RunContext, run_start_config: Dictionary = {}) -> Dictionary:
	return restart_run(context, RunConfig.m7_map(run_start_config))


func request_extract(context: RunContext, can_extract: bool, command_id: String = "", actor_id: StringName = &"player") -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if not context.can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if not can_extract:
		context.blocked_reason = "cannot_extract"
		context.last_message = "Extraction requires an exit room."
		return _blocked(&"cannot_extract", "cannot_extract")
	var transition_result := _write_phase(context, PHASE_CONFIRM_EXTRACT, TRANSITION_REQUEST_EXTRACT, [PHASE_RUNNING])
	if not bool(transition_result.get("ok", false)):
		return transition_result
	context.last_message = "Extraction requested. Confirm or cancel."
	context.record_event(RunEventLog.EVENT_EXTRACTION_FOUND, command_id, actor_id, "run_state_machine", {"position": context.get_current_pos(), "exit_id": context.exit_id})
	return {"ok": true, "status": &"extract_requested", "transition": TRANSITION_REQUEST_EXTRACT}


func confirm_extract(context: RunContext, can_extract: bool) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase != PHASE_CONFIRM_EXTRACT:
		context.last_message = "No extraction request is active."
		return _blocked_transition(&"no_extract_request", "no_extract_request", context.phase, PHASE_EXTRACTED, TRANSITION_CONFIRM_EXTRACT)
	if not can_extract:
		var cancel_result := _write_phase(context, PHASE_RUNNING, TRANSITION_CANCEL_EXTRACT, [PHASE_CONFIRM_EXTRACT])
		if not bool(cancel_result.get("ok", false)):
			return cancel_result
		context.last_message = "Extraction cancelled: not on exit."
		return _blocked(&"cannot_extract", "cannot_extract")
	var transition_result := _write_phase(context, PHASE_EXTRACTED, TRANSITION_CONFIRM_EXTRACT, [PHASE_CONFIRM_EXTRACT])
	if not bool(transition_result.get("ok", false)):
		return transition_result
	context._apply_extract()
	context.last_message = "Extraction complete."
	return {"ok": true, "status": &"extracted", "transition": TRANSITION_CONFIRM_EXTRACT, "result_snapshot": context.result_snapshot.duplicate(true)}


func cancel_extract(context: RunContext) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase == PHASE_CONFIRM_EXTRACT:
		var transition_result := _write_phase(context, PHASE_RUNNING, TRANSITION_CANCEL_EXTRACT, [PHASE_CONFIRM_EXTRACT])
		if not bool(transition_result.get("ok", false)):
			return transition_result
		context.last_message = "Extraction cancelled."
	return {"ok": true, "status": &"extract_cancelled", "transition": TRANSITION_CANCEL_EXTRACT}


func fail_run(context: RunContext, reason: String = "forced_failure") -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	var transition_result := _write_phase(context, PHASE_FAILURE_SALVAGE, TRANSITION_FAIL, ACTIVE_PHASES)
	if not bool(transition_result.get("ok", false)):
		return transition_result
	context._apply_failure(reason)
	return {"ok": true, "status": &"failure_salvage_pending", "transition": TRANSITION_FAIL, "reason": reason, "result_snapshot": context.result_snapshot.duplicate(true)}


func confirm_failure_salvage(context: RunContext, selected_instance_ids: Array) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase != PHASE_FAILURE_SALVAGE or not context.failed:
		return _blocked_transition(&"not_awaiting_salvage", "failure_salvage_not_pending", context.phase, PHASE_FAILED, TRANSITION_CONFIRM_FAILURE, "reason")
	var settlement := context._settle_failure_salvage(selected_instance_ids)
	if not bool(settlement.get("ok", false)):
		return settlement
	var transition_result := _write_phase(context, PHASE_FAILED, TRANSITION_CONFIRM_FAILURE, [PHASE_FAILURE_SALVAGE])
	if not bool(transition_result.get("ok", false)):
		return transition_result
	context._finalize_failure_salvage(settlement)
	return {"ok": true, "status": &"failure_settled", "transition": TRANSITION_CONFIRM_FAILURE, "settlement": settlement, "result_snapshot": context.result_snapshot.duplicate(true)}


func abandon_run(context: RunContext, reason: String = "player_abandoned") -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	var transition_result := _write_phase(context, PHASE_ABANDONED, TRANSITION_ABANDON, ABANDONABLE_PHASES)
	if not bool(transition_result.get("ok", false)):
		return transition_result
	context._apply_abandon(reason)
	return {"ok": true, "status": &"abandoned", "transition": TRANSITION_ABANDON, "reason": reason, "result_snapshot": context.result_snapshot.duplicate(true)}


func complete_extract(context: RunContext) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	var transition_result := _write_phase(context, PHASE_EXTRACTED, TRANSITION_CONFIRM_EXTRACT, ACTIVE_PHASES)
	if not bool(transition_result.get("ok", false)):
		return transition_result
	context._apply_extract()
	context.last_message = "Extraction complete."
	return {"ok": true, "status": &"extracted", "transition": TRANSITION_CONFIRM_EXTRACT, "result_snapshot": context.result_snapshot.duplicate(true)}


func force_extract(context: RunContext) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	var transition_result := _write_phase(context, PHASE_EXTRACTED, TRANSITION_CONFIRM_EXTRACT, ACTIVE_PHASES)
	if not bool(transition_result.get("ok", false)):
		return transition_result
	context._apply_extract()
	context.last_message = "Debug forced extraction through RunStateMachine."
	return {"ok": true, "status": &"debug_forced_extract", "transition": TRANSITION_CONFIRM_EXTRACT, "result_snapshot": context.result_snapshot.duplicate(true)}


func _write_phase(context: RunContext, next_phase: StringName, transition: StringName, allowed_from: Array[StringName], allow_same: bool = false) -> Dictionary:
	var previous_phase: StringName = context.phase
	if previous_phase == next_phase:
		if allow_same:
			return _transition_ok(previous_phase, next_phase, transition)
		return _blocked_transition(&"invalid_phase_transition", "invalid_phase_transition", previous_phase, next_phase, transition)
	if not allowed_from.is_empty() and previous_phase not in allowed_from:
		return _blocked_transition(&"invalid_phase_transition", "invalid_phase_transition", previous_phase, next_phase, transition)
	context.phase = next_phase
	return _transition_ok(previous_phase, next_phase, transition)


func _transition_ok(previous_phase: StringName, next_phase: StringName, transition: StringName) -> Dictionary:
	return {
		"ok": true,
		"from_phase": previous_phase,
		"to_phase": next_phase,
		"transition": transition,
		"transition_authority": "RunStateMachine",
	}


func _blocked_transition(status: StringName, reason: String, previous_phase: StringName, next_phase: StringName, transition: StringName, reason_key: String = "reason_code") -> Dictionary:
	var result := _blocked(status, reason)
	result[reason_key] = reason
	result["from_phase"] = previous_phase
	result["to_phase"] = next_phase
	result["transition"] = transition
	return result


func _blocked(status: StringName, reason: String) -> Dictionary:
	return {
		"ok": false,
		"accepted": false,
		"status": status,
		"reason_code": reason,
		"transition_authority": "RunStateMachine",
	}
