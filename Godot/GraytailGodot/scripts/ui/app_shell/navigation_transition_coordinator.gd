extends RefCounted
class_name NavigationTransitionCoordinator

const STATE_IDLE := &"idle"
const STATE_PREPARING := &"preparing"
const STATE_PLAYING := &"playing"
const STATE_COMMITTING := &"committing"

const PROFILE_ENTER_CAVE := &"enter_cave"
const PROFILE_DESCEND := &"descend"
const PROFILE_OPEN_OVERLAY := &"open_overlay"
const PROFILE_OPEN_CONFIRM := &"open_confirm"
const PROFILE_IDS: Array[StringName] = [
	PROFILE_ENTER_CAVE,
	PROFILE_DESCEND,
	PROFILE_OPEN_OVERLAY,
	PROFILE_OPEN_CONFIRM,
]

const OUTCOME_NONE := &"none"
const OUTCOME_COMMITTED := &"committed"
const OUTCOME_CANCELLED := &"cancelled"
const OUTCOME_FAILED := &"failed"

var _state: StringName = STATE_IDLE
var _last_issued_token := 0
var _active_token := 0
var _active_request: Dictionary = {}
var _commit_issued := false
var _commit_count := 0
var _current_page: StringName = &""
var _current_focus_id: StringName = &""
var _last_result: Dictionary = {
	"token": 0,
	"outcome": OUTCOME_NONE,
	"reason_code": &"",
	"page": &"",
	"focus_id": &"",
	"commit_count": 0,
	"recovery": {},
}


static func profile_ids() -> Array[StringName]:
	return PROFILE_IDS.duplicate()


static func is_known_profile(profile_id: StringName) -> bool:
	return PROFILE_IDS.has(profile_id)


func is_busy() -> bool:
	return _state != STATE_IDLE


func active_token() -> int:
	return _active_token


func request_transition(
	source_page: StringName,
	target_page: StringName,
	profile_id: StringName,
	source_focus_id: StringName = &"",
	reduced_motion: bool = false,
	payload: Dictionary = {}
) -> Dictionary:
	if is_busy():
		return _rejected(&"transition_busy", _active_token)
	if source_page == &"":
		return _rejected(&"source_page_required")
	if target_page == &"":
		return _rejected(&"target_page_required")
	if not is_known_profile(profile_id):
		return _rejected(&"unknown_transition_profile")

	_last_issued_token += 1
	_active_token = _last_issued_token
	_active_request = {
		"token": _active_token,
		"source_page": source_page,
		"target_page": target_page,
		"source_focus_id": source_focus_id,
		"profile_id": profile_id,
		"reduced_motion": reduced_motion,
		"payload": payload.duplicate(true),
	}
	_commit_issued = false
	_commit_count = 0
	_current_page = source_page
	_current_focus_id = source_focus_id
	_state = STATE_PREPARING
	return _accepted()


func mark_prepared(token: int, prepared: bool = true, reason_code: StringName = &"prepare_failed") -> Dictionary:
	var rejection := _validate(token, [STATE_PREPARING])
	if not rejection.is_empty():
		return rejection
	if not prepared:
		return _finish(OUTCOME_FAILED, reason_code)
	_state = STATE_PLAYING
	return _accepted()


func mark_playback_finished(token: int) -> Dictionary:
	var rejection := _validate(token, [STATE_PLAYING])
	if not rejection.is_empty():
		return rejection
	_state = STATE_COMMITTING
	return _accepted()


func set_reduced_motion(token: int, enabled: bool) -> Dictionary:
	var rejection := _validate(token, [STATE_PREPARING, STATE_PLAYING, STATE_COMMITTING])
	if not rejection.is_empty():
		return rejection
	var changed := bool(_active_request.get("reduced_motion", false)) != enabled
	_active_request["reduced_motion"] = enabled
	var result := _accepted()
	result["profile_changed"] = changed
	return result


func take_commit(token: int) -> Dictionary:
	var rejection := _validate(token, [STATE_COMMITTING])
	if not rejection.is_empty():
		return rejection
	if _commit_issued:
		return _rejected(&"commit_already_issued", token)
	_commit_issued = true
	_commit_count = 1
	var result := _accepted()
	result["commit_request"] = _active_request.duplicate(true)
	return result


func resolve_commit(token: int, committed: bool, reason_code: StringName = &"commit_failed") -> Dictionary:
	var rejection := _validate(token, [STATE_COMMITTING])
	if not rejection.is_empty():
		return rejection
	if not _commit_issued:
		return _rejected(&"commit_not_issued", token)
	if not committed:
		return _finish(OUTCOME_FAILED, reason_code)
	return _finish(OUTCOME_COMMITTED, &"")


func cancel(token: int, reason_code: StringName = &"cancelled") -> Dictionary:
	var rejection := _validate(token, [STATE_PREPARING, STATE_PLAYING, STATE_COMMITTING])
	if not rejection.is_empty():
		return rejection
	if _state == STATE_COMMITTING and _commit_issued:
		return _rejected(&"commit_in_flight", token)
	return _finish(OUTCOME_CANCELLED, reason_code)


func fail_transition(token: int, reason_code: StringName = &"transition_failed") -> Dictionary:
	var rejection := _validate(token, [STATE_PREPARING, STATE_PLAYING, STATE_COMMITTING])
	if not rejection.is_empty():
		return rejection
	return _finish(OUTCOME_FAILED, reason_code)


func snapshot() -> Dictionary:
	var active := _active_request.duplicate(true)
	return {
		"state": _state,
		"busy": is_busy(),
		"last_issued_token": _last_issued_token,
		"active_token": _active_token,
		"current_page": _current_page,
		"current_focus_id": _current_focus_id,
		"source_page": StringName(active.get("source_page", &"")),
		"target_page": StringName(active.get("target_page", &"")),
		"source_focus_id": StringName(active.get("source_focus_id", &"")),
		"profile_id": StringName(active.get("profile_id", &"")),
		"reduced_motion": bool(active.get("reduced_motion", false)),
		"payload": (active.get("payload", {}) as Dictionary).duplicate(true),
		"commit_issued": _commit_issued,
		"commit_count": _commit_count,
		"last_result": _last_result.duplicate(true),
	}


func _validate(token: int, expected_states: Array) -> Dictionary:
	if token <= 0 or token != _active_token or _state == STATE_IDLE:
		return _rejected(&"stale_transition_token", token)
	if not expected_states.has(_state):
		return _rejected(&"invalid_transition_state", token)
	return {}


func _finish(outcome: StringName, reason_code: StringName) -> Dictionary:
	var finished_token := _active_token
	var source_page := StringName(_active_request.get("source_page", &""))
	var target_page := StringName(_active_request.get("target_page", &""))
	var source_focus_id := StringName(_active_request.get("source_focus_id", &""))
	var recovered := outcome != OUTCOME_COMMITTED
	_current_page = source_page if recovered else target_page
	_current_focus_id = source_focus_id if recovered else &""
	_last_result = {
		"token": finished_token,
		"outcome": outcome,
		"reason_code": reason_code,
		"page": _current_page,
		"focus_id": _current_focus_id,
		"commit_count": _commit_count,
		"recovery": {
			"available": recovered,
			"page": source_page if recovered else &"",
			"focus_id": source_focus_id if recovered else &"",
		},
	}
	_state = STATE_IDLE
	_active_token = 0
	_active_request.clear()
	_commit_issued = false
	_commit_count = 0
	var result := _accepted()
	result["token"] = finished_token
	result["outcome"] = outcome
	result["last_result"] = _last_result.duplicate(true)
	return result


func _accepted() -> Dictionary:
	return {
		"ok": true,
		"token": _active_token,
		"state": _state,
		"snapshot": snapshot(),
	}


func _rejected(reason_code: StringName, token: int = 0) -> Dictionary:
	return {
		"ok": false,
		"token": token,
		"state": _state,
		"reason_code": reason_code,
		"snapshot": snapshot(),
	}
