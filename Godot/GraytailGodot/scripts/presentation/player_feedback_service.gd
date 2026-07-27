extends Node
class_name PlayerFeedbackService

signal cue_emitted(report: Dictionary)

const EFFECTS_BUS_NAME := &"Effects"
const REDUCE_MOTION_PROJECT_KEY := "accessibility/reduce_motion"
const HAPTICS_ENABLED_PROJECT_KEY := "accessibility/haptics_enabled"
const MAX_REMEMBERED_DOMAIN_EVENTS := 1024

const CUE_UI_CONFIRM := &"ui_confirm"
const CUE_UI_REJECT := &"ui_reject"
const CUE_SEARCH_REVEAL := &"search_reveal"
const CUE_PICKUP := &"pickup"
const CUE_CHEST_OPEN := &"chest_open"
const CUE_ITEM_RECOVERY := &"item_recovery"
const CUE_ATTACK := &"attack"
const CUE_HIT := &"hit"
const CUE_PLAYER_HURT := &"player_hurt"
const CUE_MINE_EXPLOSION := &"mine_explosion"
const CUE_ENEMY_DEATH := &"enemy_death"
const CUE_EXTRACTION_SUCCESS := &"extraction_success"
const CUE_EXTRACTION_FAILURE := &"extraction_failure"

const ROUTES := {
	CUE_UI_CONFIRM: {
		"asset_key": &"audio.sfx.click",
		"path": "res://assets/audio/sfx/sfx_click.wav",
		"pitch": 1.05,
		"weak": 0.08,
		"strong": 0.0,
		"duration": 0.04,
	},
	CUE_UI_REJECT: {
		"asset_key": &"audio.sfx.click",
		"path": "res://assets/audio/sfx/sfx_click.wav",
		"pitch": 0.78,
		"weak": 0.10,
		"strong": 0.20,
		"duration": 0.08,
	},
	CUE_SEARCH_REVEAL: {
		"asset_key": &"audio.sfx.pickup",
		"path": "res://assets/audio/sfx/sfx_pickup.wav",
		"pitch": 1.18,
		"weak": 0.10,
		"strong": 0.0,
		"duration": 0.05,
	},
	CUE_PICKUP: {
		"asset_key": &"audio.sfx.pickup",
		"path": "res://assets/audio/sfx/sfx_pickup.wav",
		"pitch": 1.0,
		"weak": 0.14,
		"strong": 0.0,
		"duration": 0.06,
	},
	CUE_CHEST_OPEN: {
		"asset_key": &"audio.sfx.pickup",
		"path": "res://assets/audio/sfx/sfx_pickup.wav",
		"pitch": 0.82,
		"weak": 0.12,
		"strong": 0.08,
		"duration": 0.08,
	},
	CUE_ITEM_RECOVERY: {
		"asset_key": &"audio.sfx.heal",
		"path": "res://assets/audio/sfx/sfx_heal.wav",
		"pitch": 1.0,
		"weak": 0.12,
		"strong": 0.0,
		"duration": 0.08,
	},
	CUE_ATTACK: {
		"asset_key": &"audio.sfx.attack",
		"path": "res://assets/audio/sfx/sfx_attack.wav",
		"pitch": 1.0,
		"weak": 0.16,
		"strong": 0.12,
		"duration": 0.07,
	},
	CUE_HIT: {
		"asset_key": &"audio.sfx.hit",
		"path": "res://assets/audio/sfx/sfx_hit.wav",
		"pitch": 1.0,
		"weak": 0.16,
		"strong": 0.24,
		"duration": 0.08,
	},
	CUE_PLAYER_HURT: {
		"asset_key": &"audio.sfx.hurt",
		"path": "res://assets/audio/sfx/sfx_hurt.wav",
		"pitch": 1.0,
		"weak": 0.24,
		"strong": 0.66,
		"duration": 0.16,
	},
	CUE_MINE_EXPLOSION: {
		"asset_key": &"audio.sfx.explosion",
		"path": "res://assets/audio/sfx/sfx_explosion.wav",
		"pitch": 1.0,
		"weak": 0.34,
		"strong": 1.0,
		"duration": 0.24,
	},
	CUE_ENEMY_DEATH: {
		"asset_key": &"audio.sfx.death",
		"path": "res://assets/audio/sfx/sfx_death.wav",
		"pitch": 1.0,
		"weak": 0.18,
		"strong": 0.36,
		"duration": 0.12,
	},
	CUE_EXTRACTION_SUCCESS: {
		"asset_key": &"audio.sfx.extract",
		"path": "res://assets/audio/sfx/sfx_extract.wav",
		"pitch": 1.0,
		"weak": 0.28,
		"strong": 0.58,
		"duration": 0.22,
	},
	CUE_EXTRACTION_FAILURE: {
		"asset_key": &"audio.sfx.death",
		"path": "res://assets/audio/sfx/sfx_death.wav",
		"pitch": 0.72,
		"weak": 0.30,
		"strong": 0.72,
		"duration": 0.26,
	},
}

var settings_manager: Node
var master_volume_percent := 80
var effects_volume_percent := 80
var haptics_enabled := true
var reduce_motion := false
var active_joypad_device := -1

var _clock: Callable
var _playback_sink: Callable
var _joypad_provider: Callable
var _vibration_sink: Callable
var _seen_domain_events: Dictionary = {}
var _seen_domain_event_order: Array[String] = []
var _history: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("player_feedback_service")
	if settings_manager != null:
		_apply_manager_settings()


func bind_settings_manager(manager: Node) -> void:
	var callbacks := {
		"settings_applied": Callable(self, "_on_settings_changed"),
		"settings_reverted": Callable(self, "_on_settings_reverted"),
		"settings_persisted": Callable(self, "_on_settings_changed"),
	}
	if settings_manager != null:
		for signal_name in callbacks:
			var old_callback: Callable = callbacks[signal_name]
			if settings_manager.has_signal(signal_name) and settings_manager.is_connected(signal_name, old_callback):
				settings_manager.disconnect(signal_name, old_callback)
	settings_manager = manager
	if settings_manager != null:
		for signal_name in callbacks:
			var new_callback: Callable = callbacks[signal_name]
			if settings_manager.has_signal(signal_name) and not settings_manager.is_connected(signal_name, new_callback):
				settings_manager.connect(signal_name, new_callback)
	_apply_manager_settings()


func set_test_adapters(
	clock: Callable = Callable(),
	playback_sink: Callable = Callable(),
	joypad_provider: Callable = Callable(),
	vibration_sink: Callable = Callable()
) -> void:
	_clock = clock
	_playback_sink = playback_sink
	_joypad_provider = joypad_provider
	_vibration_sink = vibration_sink


func set_active_joypad_device(device_id: int) -> void:
	if device_id >= 0:
		active_joypad_device = device_id


func apply_settings(settings: Dictionary) -> void:
	master_volume_percent = clampi(int(settings.get("master_volume", 80)), 0, 100)
	effects_volume_percent = clampi(int(settings.get("effects_volume", 80)), 0, 100)
	haptics_enabled = bool(settings.get("haptics_enabled", true))
	reduce_motion = bool(settings.get("reduce_motion", false))


func emit_command_result(
	result: Dictionary,
	cue_override: StringName = &"",
	event_id: String = ""
) -> Dictionary:
	if StringName(result.get("status", &"")) in [&"attack_queued", &"attack_buffered"]:
		return {"accepted": false, "reason": &"awaiting_domain_event"}
	var cue := cue_override
	if cue == &"":
		cue = CUE_UI_CONFIRM if bool(result.get("ok", result.get("accepted", false))) else CUE_UI_REJECT
	return emit_cue(cue, event_id, {
		"command_id": result.get("command_id", &""),
		"status": result.get("status", &""),
		"reason": result.get("reason", result.get("blocked_reason", &"")),
	})


func emit_cue(cue_id: StringName, event_id: String = "", metadata: Dictionary = {}) -> Dictionary:
	var route: Dictionary = ROUTES.get(cue_id, {})
	if route.is_empty():
		return {"accepted": false, "reason": &"unknown_cue", "cue_id": cue_id}
	var now := _now_msec()
	if not event_id.is_empty() and _seen_domain_events.has(event_id):
		return {
			"accepted": false,
			"reason": &"duplicate_domain_event",
			"cue_id": cue_id,
			"event_id": event_id,
		}
	if not event_id.is_empty():
		_seen_domain_events[event_id] = true
		_seen_domain_event_order.append(event_id)
		if _seen_domain_event_order.size() > MAX_REMEMBERED_DOMAIN_EVENTS:
			var released_event_id: String = _seen_domain_event_order.pop_front()
			_seen_domain_events.erase(released_event_id)

	var audio_enabled := master_volume_percent > 0 and effects_volume_percent > 0
	var device_id := _resolve_joypad_device()
	var vibration := _effective_vibration(route)
	var report := {
		"accepted": true,
		"cue_id": cue_id,
		"event_id": event_id,
		"emitted_at_msec": now,
		"asset_key": route.get("asset_key", &""),
		"path": route.get("path", ""),
		"audio_played": audio_enabled,
		"audio_suppressed": &"none" if audio_enabled else &"volume_zero",
		"master_volume": master_volume_percent,
		"effects_volume": effects_volume_percent,
		"haptics_enabled": haptics_enabled,
		"reduce_motion": reduce_motion,
		"joypad_device": device_id,
		"vibration_played": device_id >= 0 and bool(vibration.get("enabled", false)),
		"vibration": vibration,
		"metadata": metadata.duplicate(true),
	}
	if audio_enabled:
		_play_audio(route, report)
	if device_id >= 0 and bool(vibration.get("enabled", false)):
		_play_vibration(device_id, vibration, report)
	_history.append(report.duplicate(true))
	if _history.size() > 64:
		_history.pop_front()
	cue_emitted.emit(report.duplicate(true))
	return report


func route_manifest() -> Dictionary:
	return ROUTES.duplicate(true)


func history() -> Array[Dictionary]:
	return _history.duplicate(true)


func clear_history_and_deduplication() -> void:
	_history.clear()
	_seen_domain_events.clear()
	_seen_domain_event_order.clear()


func debug_snapshot() -> Dictionary:
	return {
		"master_volume": master_volume_percent,
		"effects_volume": effects_volume_percent,
		"haptics_enabled": haptics_enabled,
		"reduce_motion": reduce_motion,
		"active_joypad_device": active_joypad_device,
		"history_count": _history.size(),
		"route_count": ROUTES.size(),
	}


func _apply_manager_settings() -> void:
	if settings_manager != null and settings_manager.has_method("get_applied_settings"):
		apply_settings(settings_manager.call("get_applied_settings"))
		return
	apply_settings({
		"master_volume": 80,
		"effects_volume": 80,
		"haptics_enabled": ProjectSettings.get_setting(HAPTICS_ENABLED_PROJECT_KEY, true),
		"reduce_motion": ProjectSettings.get_setting(REDUCE_MOTION_PROJECT_KEY, false),
	})


func _on_settings_changed(settings: Dictionary) -> void:
	apply_settings(settings)


func _on_settings_reverted(settings: Dictionary, _reason: StringName) -> void:
	apply_settings(settings)


func _play_audio(route: Dictionary, report: Dictionary) -> void:
	if _playback_sink.is_valid():
		_playback_sink.call(report.duplicate(true))
		return
	if not is_inside_tree():
		return
	var stream := load(String(route.get("path", ""))) as AudioStream
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.name = "Cue_%s" % String(report.get("cue_id", &"unknown"))
	player.stream = stream
	player.bus = EFFECTS_BUS_NAME if AudioServer.get_bus_index(EFFECTS_BUS_NAME) >= 0 else &"Master"
	player.pitch_scale = clampf(float(route.get("pitch", 1.0)), 0.5, 2.0)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _effective_vibration(route: Dictionary) -> Dictionary:
	if not haptics_enabled:
		return {"enabled": false, "weak": 0.0, "strong": 0.0, "duration": 0.0}
	var weak := clampf(float(route.get("weak", 0.0)), 0.0, 1.0)
	var strong := clampf(float(route.get("strong", 0.0)), 0.0, 1.0)
	var duration := maxf(0.0, float(route.get("duration", 0.0)))
	if reduce_motion:
		weak = minf(weak, 0.12)
		strong = minf(strong, 0.12)
		duration = minf(duration, 0.08)
	return {
		"enabled": weak > 0.0 or strong > 0.0,
		"weak": weak,
		"strong": strong,
		"duration": duration,
	}


func _resolve_joypad_device() -> int:
	var connected: Array[int] = []
	if _joypad_provider.is_valid():
		var provided: Variant = _joypad_provider.call()
		if provided is PackedInt32Array:
			for device_id in provided:
				connected.append(int(device_id))
		elif provided is Array:
			for device_id in provided:
				connected.append(int(device_id))
	else:
		connected = Input.get_connected_joypads()
	if active_joypad_device >= 0 and connected.has(active_joypad_device):
		return active_joypad_device
	return int(connected[0]) if not connected.is_empty() else -1


func _play_vibration(device_id: int, vibration: Dictionary, report: Dictionary) -> void:
	if _vibration_sink.is_valid():
		_vibration_sink.call(device_id, vibration.duplicate(true), report.duplicate(true))
		return
	Input.start_joy_vibration(
		device_id,
		float(vibration.get("weak", 0.0)),
		float(vibration.get("strong", 0.0)),
		float(vibration.get("duration", 0.0))
	)


func _now_msec() -> int:
	if _clock.is_valid():
		return int(_clock.call())
	return Time.get_ticks_msec()
