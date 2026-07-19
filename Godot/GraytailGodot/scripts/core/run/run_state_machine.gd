extends RefCounted
class_name RunStateMachine

const TRANSITION_START := &"start"
const TRANSITION_REQUEST_EXTRACT := &"request_extract"
const TRANSITION_CONFIRM_EXTRACT := &"confirm_extract"
const TRANSITION_CANCEL_EXTRACT := &"cancel_extract"
const TRANSITION_FAIL := &"fail"
const TRANSITION_ABANDON := &"abandon"
const TRANSITION_RESTART := &"restart"


func start_run(context: RunContext, config: Dictionary) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	context.start_run(config)
	return {"ok": true, "status": &"run_started", "mode": context.mode, "transition": TRANSITION_START}


func start_demo_run(context: RunContext) -> Dictionary:
	return start_run(context, {
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
	})


func start_tutorial_run(context: RunContext) -> Dictionary:
	return start_run(context, RunConfig.tutorial_5x5())


func start_standard_run(context: RunContext, run_start_config: Dictionary = {}) -> Dictionary:
	return start_run(context, RunConfig.m7_map(run_start_config))


func request_extract(context: RunContext, can_extract: bool, command_id: String = "", actor_id: StringName = &"player") -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if not context.can_accept_command():
		return _blocked(&"blocked", "command_blocked")
	if not can_extract:
		context.blocked_reason = "cannot_extract"
		context.last_message = "Extraction requires an exit room."
		return _blocked(&"cannot_extract", "cannot_extract")
	context.phase = &"confirm_extract"
	context.last_message = "Extraction requested. Confirm or cancel."
	context.record_event(RunEventLog.EVENT_EXTRACTION_FOUND, command_id, actor_id, "run_state_machine", {"position": context.get_current_pos(), "exit_id": context.exit_id})
	return {"ok": true, "status": &"extract_requested", "transition": TRANSITION_REQUEST_EXTRACT}


func confirm_extract(context: RunContext, can_extract: bool) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase != &"confirm_extract":
		context.last_message = "No extraction request is active."
		return _blocked(&"no_extract_request", "no_extract_request")
	if not can_extract:
		context.phase = &"running"
		context.last_message = "Extraction cancelled: not on exit."
		return _blocked(&"cannot_extract", "cannot_extract")
	context.complete_extract()
	context.last_message = "Extraction complete."
	return {"ok": true, "status": &"extracted", "transition": TRANSITION_CONFIRM_EXTRACT, "result_snapshot": context.result_snapshot.duplicate(true)}


func cancel_extract(context: RunContext) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	if context.phase == &"confirm_extract":
		context.phase = &"running"
		context.last_message = "Extraction cancelled."
	return {"ok": true, "status": &"extract_cancelled", "transition": TRANSITION_CANCEL_EXTRACT}


func fail_run(context: RunContext, reason: String = "forced_failure") -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	context.fail_run(reason)
	return {"ok": true, "status": &"failure_salvage_pending", "transition": TRANSITION_FAIL, "reason": reason, "result_snapshot": context.result_snapshot.duplicate(true)}


func confirm_failure_salvage(context: RunContext, selected_instance_ids: Array) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	var settlement := context.confirm_failure_salvage(selected_instance_ids)
	if not bool(settlement.get("ok", false)):
		return settlement
	return {"ok": true, "status": &"failure_settled", "transition": TRANSITION_FAIL, "settlement": settlement, "result_snapshot": context.result_snapshot.duplicate(true)}


func abandon_run(context: RunContext, reason: String = "player_abandoned") -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	context.abandon_run(reason)
	return {"ok": true, "status": &"abandoned", "transition": TRANSITION_ABANDON, "reason": reason, "result_snapshot": context.result_snapshot.duplicate(true)}


func force_extract(context: RunContext) -> Dictionary:
	if context == null:
		return _blocked(&"not_ready", "not_ready")
	context.complete_extract()
	context.last_message = "Debug forced extraction through RunStateMachine."
	return {"ok": true, "status": &"debug_forced_extract", "transition": TRANSITION_CONFIRM_EXTRACT, "result_snapshot": context.result_snapshot.duplicate(true)}


func _blocked(status: StringName, reason: String) -> Dictionary:
	return {
		"ok": false,
		"accepted": false,
		"status": status,
		"reason_code": reason,
		"transition_authority": "RunStateMachine",
	}
