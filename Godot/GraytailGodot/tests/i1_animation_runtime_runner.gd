extends SceneTree

const PlayerControllerScript := preload("res://scripts/gameplay/player/player_controller.gd")
const RuntimeActorViewScript := preload("res://scripts/gameplay/runtime/g41_runtime_actor_view.gd")
const RuntimeAnimationCatalog := preload("res://scripts/presentation/art24/art24_runtime_animation_catalog.gd")
const TextureCache := preload("res://scripts/presentation/runtime_texture_cache.gd")

const PASS_MARKER := "I1_ANIMATION_RUNTIME=PASS"
const FAIL_MARKER := "I1_ANIMATION_RUNTIME=FAIL"
const REDUCE_MOTION_SETTING := "accessibility/reduce_motion"

var failures: Array[String] = []
var had_reduce_motion_setting := false
var previous_reduce_motion_value: Variant = null


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	had_reduce_motion_setting = ProjectSettings.has_setting(REDUCE_MOTION_SETTING)
	previous_reduce_motion_value = ProjectSettings.get_setting(REDUCE_MOTION_SETTING, false)
	ProjectSettings.set_setting(REDUCE_MOTION_SETTING, false)
	_check_runtime_texture_cache()
	_check_player_state_frames_and_timing()
	_check_enemy_state_frames_and_timing()
	_check_reduced_motion_path()
	_restore_reduce_motion_setting()
	_finish()


func _check_runtime_texture_cache() -> void:
	TextureCache.clear_for_tests()
	var first = PlayerControllerScript.new()
	root.add_child(first)
	first.set_process(false)
	var second = PlayerControllerScript.new()
	root.add_child(second)
	second.set_process(false)
	var first_texture := (first.get_node("Sprite") as Sprite2D).texture
	var second_texture := (second.get_node("Sprite") as Sprite2D).texture
	var metrics: Dictionary = TextureCache.metrics()
	_require(first_texture != null and first_texture == second_texture, "player views did not share the cached texture instance")
	_require_equal(int(metrics.get("requests", -1)), 2, "cache request count")
	_require_equal(int(metrics.get("loads", -1)), 1, "cache load count")
	_require_equal(int(metrics.get("cache_hits", -1)), 1, "cache hit count")
	_require_equal(int(metrics.get("failures", -1)), 0, "cache failure count")
	_require_equal(int(metrics.get("entries", -1)), 1, "cache entry count")
	first.free()
	second.free()


func _check_player_state_frames_and_timing() -> void:
	var player = PlayerControllerScript.new()
	root.add_child(player)
	player.set_process(false)
	player.set_input_enabled(false)
	var sprite := player.get_node("Sprite") as Sprite2D

	player.set_runtime_visual_state(&"idle")
	player.call("_process", 0.0)
	_require_path(player.last_texture_path, "down_idle_a.png", "player idle frame 0")
	player.call("_process", 0.15)
	_require_path(player.last_texture_path, "down_idle_b.png", "player idle frame 1")

	player.set_runtime_visual_state(&"move")
	player.call("_process", 0.0)
	_require_path(player.last_texture_path, "down_walk_a.png", "player move frame 0")
	player.call("_process", RuntimeAnimationCatalog.player_frame_duration(&"move") * 2.0 + 0.001)
	_require_path(player.last_texture_path, "down_walk_b.png", "player move frame 1")

	player.set_runtime_visual_state(&"attack_windup")
	player.call("_process", 0.0)
	_require_path(player.last_texture_path, "down_attack_windup.png", "player attack windup")
	player.set_runtime_visual_state(&"attack_active")
	player.call("_process", 0.0)
	_require_path(player.last_texture_path, "down_attack_swing.png", "player attack active start")
	player.call("_process", 0.061)
	_require_path(player.last_texture_path, "down_attack_impact.png", "player attack active impact")
	player.set_runtime_visual_state(&"attack_recovery")
	player.call("_process", 0.0)
	_require_path(player.last_texture_path, "down_attack_recover.png", "player attack recovery")

	player.set_runtime_visual_state(&"hurt")
	player.call("_process", 0.0)
	_require_path(player.last_texture_path, "down_hit.png", "player hurt pose")
	player.set_runtime_visual_state(&"idle")
	player.call("_process", 0.05)
	_require_equal(player.visual_state, &"hurt", "player minimum hurt visibility")
	player.call("_process", 0.08)
	_require_equal(player.visual_state, &"idle", "player hurt release state")

	player.set_runtime_visual_state(&"dead")
	player.call("_process", 0.0)
	_require_path(player.last_texture_path, "down_hit.png", "player death pose")
	_require(is_equal_approx(sprite.rotation, -0.18), "player death pose was not visibly distinct")
	_require(sprite.texture != null, "player state mapping produced no runtime texture")
	player.free()


func _check_enemy_state_frames_and_timing() -> void:
	var actor = RuntimeActorViewScript.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.configure(&"bat", _enemy_snapshot(&"idle"))
	actor.call("_process", 0.0)
	_require_path(actor.last_texture_path, "bat/ue_idle_0.png", "enemy idle frame 0")
	actor.call("_process", 0.141)
	_require_path(actor.last_texture_path, "bat/ue_idle_1.png", "enemy move/idle frame timing")

	actor.configure(&"bat", _enemy_snapshot(&"active"))
	_require_path(actor.last_texture_path, "bat/ue_attack.png", "enemy attack pose")
	actor.configure(&"bat", _enemy_snapshot(&"hurt"))
	_require_path(actor.last_texture_path, "bat/hurt.png", "enemy hurt pose")
	actor.configure(&"bat", _enemy_snapshot(&"move"))
	actor.call("_process", 0.05)
	_require_equal(actor.visual_state, &"hurt", "enemy minimum hurt visibility")
	actor.call("_process", 0.08)
	_require_equal(actor.visual_state, &"move", "enemy hurt release state")
	_require_path(actor.last_texture_path, "bat/ue_idle_0.png", "enemy move pose")

	actor.configure(&"bat", _enemy_snapshot(&"dead"))
	actor.call("_process", 0.46)
	_require_equal(actor.animation_frame, 4, "enemy death terminal frame")
	_require_path(actor.last_texture_path, "bat/ue_defeated_4.png", "enemy death terminal pose")
	_require((actor.get_node("VisualRoot/ArtVisual") as Sprite2D).texture != null, "enemy state mapping produced no runtime texture")
	actor.free()


func _check_reduced_motion_path() -> void:
	ProjectSettings.set_setting(REDUCE_MOTION_SETTING, true)
	var player = PlayerControllerScript.new()
	root.add_child(player)
	player.set_process(false)
	player.set_input_enabled(false)
	player.set_runtime_visual_state(&"attack_active")
	player.call("_process", 1.0)
	_require_equal(player.animation_frame, 0, "reduced-motion player frame")
	_require(is_zero_approx(player.animation_elapsed), "reduced-motion player clock")
	_require_path(player.last_texture_path, "down_attack_impact.png", "reduced-motion attack pose")
	var player_sprite := player.get_node("Sprite") as Sprite2D
	_require(is_equal_approx(player_sprite.position.y, -20.0), "reduced-motion player retained bob motion")
	player.set_runtime_visual_state(&"move")
	player.call("_process", 1.0)
	_require_path(player.last_texture_path, "down_walk_a.png", "reduced-motion move pose")

	var actor = RuntimeActorViewScript.new()
	root.add_child(actor)
	actor.set_process(false)
	actor.configure(&"bat", _enemy_snapshot(&"dead"))
	actor.call("_process", 1.0)
	_require_equal(actor.animation_frame, 0, "reduced-motion enemy frame")
	_require(is_zero_approx(actor.animation_elapsed), "reduced-motion enemy clock")
	_require_path(actor.last_texture_path, "bat/ue_defeated_4.png", "reduced-motion death pose")
	actor.configure(&"bat", _enemy_snapshot(&"idle"))
	actor.call("_process", 1.0)
	_require_path(actor.last_texture_path, "bat/ue_idle_0.png", "reduced-motion enemy idle pose")
	var actor_sprite := actor.get_node("VisualRoot/ArtVisual") as Sprite2D
	_require(is_equal_approx(actor_sprite.position.y, -14.0), "reduced-motion enemy retained bob motion")
	player.free()
	actor.free()


func _enemy_snapshot(state: StringName) -> Dictionary:
	return {
		"enemy_id": "i1-animation-bat",
		"state": state,
		"hp": 8 if state != &"dead" else 0,
		"max_hp": 8,
		"pos": Vector2(0.5, 0.5),
	}


func _require_path(path: String, suffix: String, label: String) -> void:
	_require(path.replace("\\", "/").ends_with(suffix), "%s: expected suffix %s, got %s" % [label, suffix, path])


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _restore_reduce_motion_setting() -> void:
	ProjectSettings.set_setting(
		REDUCE_MOTION_SETTING,
		previous_reduce_motion_value if had_reduce_motion_setting else null
	)


func _finish() -> void:
	if failures.is_empty():
		print(PASS_MARKER)
		quit(0)
		return
	for failure in failures:
		push_error("I1 animation runtime failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
