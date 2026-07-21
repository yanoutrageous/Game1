extends RefCounted
class_name MainMenuTransitionPresenter

const PROFILE_ENTER_CAVE := &"enter_cave"
const PROFILE_DESCEND := &"descend"
const PROFILE_OPEN_OVERLAY := &"open_overlay"
const PROFILE_OPEN_CONFIRM := &"open_confirm"

const DURATIONS := {
	PROFILE_ENTER_CAVE: 0.72,
	PROFILE_DESCEND: 0.78,
	PROFILE_OPEN_OVERLAY: 0.16,
	PROFILE_OPEN_CONFIRM: 0.18,
}

var _token := 0
var _profile: StringName = &""
var _elapsed := 0.0
var _duration := 0.0
var _active := false
var _reduced_motion := false


func begin(token: int, profile: StringName, reduced_motion: bool) -> Dictionary:
	if token <= 0 or not DURATIONS.has(profile):
		return {"ok": false, "reason_code": &"invalid_transition_request"}
	_token = token
	_profile = profile
	_elapsed = 0.0
	_duration = 0.0 if reduced_motion else float(DURATIONS[profile])
	_active = not reduced_motion
	_reduced_motion = reduced_motion
	var pose := _pose(1.0 if reduced_motion else 0.0)
	pose["ok"] = true
	pose["complete"] = reduced_motion
	return pose


func advance(delta: float) -> Dictionary:
	if _token <= 0:
		return {"ok": false, "reason_code": &"transition_not_started"}
	if _active:
		_elapsed = minf(_duration, _elapsed + maxf(0.0, delta))
	var progress := 1.0 if _duration <= 0.0 else clampf(_elapsed / _duration, 0.0, 1.0)
	var complete := progress >= 1.0
	if complete:
		_active = false
	var pose := _pose(progress)
	pose["ok"] = true
	pose["complete"] = complete
	return pose


func snap_to_end(token: int) -> Dictionary:
	if token != _token or token <= 0:
		return {"ok": false, "reason_code": &"stale_transition_token"}
	_elapsed = _duration
	_active = false
	_reduced_motion = true
	var pose := _pose(1.0)
	pose["ok"] = true
	pose["complete"] = true
	return pose


func cancel(token: int) -> Dictionary:
	if token != _token or token <= 0:
		return {"ok": false, "reason_code": &"stale_transition_token"}
	var previous_profile := _profile
	reset()
	return {"ok": true, "profile": previous_profile}


func reset() -> void:
	_token = 0
	_profile = &""
	_elapsed = 0.0
	_duration = 0.0
	_active = false
	_reduced_motion = false


func snapshot() -> Dictionary:
	return {
		"token": _token,
		"profile": _profile,
		"elapsed": _elapsed,
		"duration": _duration,
		"active": _active,
		"reduced_motion": _reduced_motion,
	}


func _pose(raw_progress: float) -> Dictionary:
	var progress := clampf(raw_progress, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, progress)
	var pose := {
		"token": _token,
		"profile": _profile,
		"progress": progress,
		"scene_offset": Vector2.ZERO,
		"overlay_color": Color(0.018, 0.024, 0.032, 0.0),
		"overlay_alpha": 0.0,
		"cave_activation_alpha": 0.0,
		"company_activation_alpha": 0.0,
		"character_pose": &"idle",
		"shadow_alpha": 1.0,
	}
	match _profile:
		PROFILE_ENTER_CAVE:
			pose["overlay_alpha"] = eased
			pose["cave_activation_alpha"] = lerpf(0.30, 0.66, 1.0 - absf(progress * 2.0 - 1.0))
			pose["character_pose"] = &"focus_deploy"
			pose["shadow_alpha"] = 1.0 - eased * 0.45
		PROFILE_DESCEND:
			pose["scene_offset"] = Vector2(0.0, round(48.0 * eased))
			pose["overlay_color"] = Color(0.13, 0.075, 0.025, 0.0)
			pose["overlay_alpha"] = eased
			pose["company_activation_alpha"] = lerpf(0.30, 0.58, 1.0 - absf(progress * 2.0 - 1.0))
			pose["character_pose"] = &"focus_long_term"
		PROFILE_OPEN_OVERLAY:
			pose["overlay_alpha"] = 0.48 * eased
			pose["character_pose"] = &"idle"
		PROFILE_OPEN_CONFIRM:
			pose["overlay_color"] = Color(0.16, 0.035, 0.025, 0.0)
			pose["overlay_alpha"] = 0.58 * eased
			pose["character_pose"] = &"idle"
	return pose
