extends SceneTree

const M7ContentCatalogScript := preload("res://scripts/core/content/m7_content_catalog.gd")
const PlayerAppearanceConfigScript := preload("res://scripts/core/content/player_appearance_config.gd")
const PlayerControllerScript := preload("res://scripts/gameplay/player/player_controller.gd")
const RuntimeVisualContractScript := preload("res://scripts/gameplay/runtime/g41_runtime_visual_contract.gd")
# main.tscn owns this dependency through RunRuntimeController. An explicit
# preload prevents stale editor bytecode from producing a false PASS when the
# shared production dependency graph does not compile.
const ProductionCombatCompileGate := preload("res://scripts/gameplay/combat/g41_combat_simulation.gd")
const RunStartConfigScript := preload("res://scripts/core/run/run_start_config.gd")
const RuntimeAnimationCatalogScript := preload("res://scripts/presentation/art24/art24_runtime_animation_catalog.gd")

const PASS_MARKER := "I3R_PLAYER_MOVEMENT_APPEARANCE=PASS"
const FAIL_MARKER := "I3R_PLAYER_MOVEMENT_APPEARANCE=FAIL"

var failures: Array[String] = []
var evidence: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	_check_runtime_motion_frame_anchors()
	_check_walk_cycle_rhythm()
	_check_unowned_selection_fails_closed()
	var unknown_catalog_config := PlayerAppearanceConfigScript.default_config()
	unknown_catalog_config["selected_appearance_id"] = "graytail.unknown_owned"
	unknown_catalog_config["owned_appearance_ids"] = [
		String(PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID),
		"graytail.unknown_owned",
	]
	_check_unknown_catalog_selection_fails_closed(unknown_catalog_config)
	var default_case := await _start_production_case(PlayerAppearanceConfigScript.default_config())
	_check_default_appearance(default_case)
	await _dispose_case(default_case)

	var unknown_catalog_case := await _start_production_case(unknown_catalog_config)
	_check_unknown_catalog_production_snapshot(unknown_catalog_case)
	await _dispose_case(unknown_catalog_case)

	var field_coat_config := PlayerAppearanceConfigScript.default_config()
	field_coat_config["selected_appearance_id"] = String(PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID)
	field_coat_config["owned_appearance_ids"] = [
		String(PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID),
		String(PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID),
	]
	var selected_case := await _start_production_case(field_coat_config)
	_check_non_default_appearance(selected_case)
	_check_appearance_swap_geometry(selected_case)
	await _check_movement_direction_and_stop(selected_case)
	await _check_hurt_preserves_appearance(selected_case)
	await _check_blocked_edge_has_no_reverse_step(selected_case)
	await _dispose_case(selected_case)
	_finish()


func _check_unowned_selection_fails_closed() -> void:
	var unowned := PlayerAppearanceConfigScript.default_config()
	unowned["selected_appearance_id"] = String(PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID)
	var resolved := PlayerAppearanceConfigScript.runtime_presentation(unowned)
	_require(
		StringName(resolved.get("appearance_id", &"")) == RuntimeAnimationCatalogScript.DEFAULT_PLAYER_APPEARANCE_ID,
		"an unowned appearance selection reached the runtime presentation"
	)
	_require(
		bool(resolved.get("selection_fallback_used", false)),
		"unowned appearance fallback was not explicit"
	)


func _check_unknown_catalog_selection_fails_closed(unknown_catalog_config: Dictionary) -> void:
	var normalized := PlayerAppearanceConfigScript.normalize(unknown_catalog_config)
	var owned: Array = normalized.get("owned_appearance_ids", [])
	var resolved := PlayerAppearanceConfigScript.runtime_presentation(unknown_catalog_config)
	evidence["unknown_catalog"] = {
		"selected": String(normalized.get("selected_appearance_id", "")),
		"owned": owned.duplicate(),
		"runtime_selection": String(resolved.get("selection_id", "")),
		"runtime_appearance": String(resolved.get("appearance_id", "")),
	}
	_require(
		StringName(normalized.get("selected_appearance_id", &"")) == PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID,
		"catalog-unknown owned selection survived semantic normalization"
	)
	_require(
		not owned.has("graytail.unknown_owned"),
		"catalog-unknown owned appearance survived semantic normalization"
	)
	_require(
		owned == [String(PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID)],
		"catalog filtering did not produce the exact safe owned set"
	)
	_require(
		StringName(resolved.get("selection_id", &"")) == PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID,
		"catalog-unknown owned selection reached runtime presentation"
	)
	_require(
		bool(resolved.get("selection_fallback_used", false)),
		"catalog-unknown selected appearance did not report semantic fallback"
	)


func _start_production_case(appearance_config: Dictionary) -> Dictionary:
	var packed := load("res://scenes/main/main.tscn") as PackedScene
	_require(packed != null, "production main scene could not be loaded")
	if packed == null:
		return {}
	var main := packed.instantiate()
	root.add_child(main)
	await _frames(5)
	var run_scene := main.get_node_or_null("RunScene")
	_require(run_scene != null, "production RunScene is missing")
	if run_scene == null:
		return {"main": main}
	_require(
		run_scene.get_script() != null and run_scene.has_method("_apply_player_presentation"),
		"production RunScene script did not compile"
	)
	if run_scene.get_script() == null or not run_scene.has_method("_apply_player_presentation"):
		return {"main": main, "run_scene": run_scene}
	var adapter: Variant = run_scene.get("meta_progress_adapter")
	var bus: Variant = run_scene.get("command_bus")
	_require(adapter != null and bus != null, "production start authorities are missing")
	if adapter == null or bus == null:
		return {"main": main, "run_scene": run_scene}
	var fixture_meta: Dictionary = adapter.save_adapter.default_meta_progress()
	fixture_meta["player_appearance"] = appearance_config.duplicate(true)
	adapter.data = fixture_meta
	var summary: Dictionary = adapter.get_summary()
	var run_start := RunStartConfigScript.default_config()
	run_start["seed_value"] = 1001
	run_start["source_page"] = &"deploy_prep"
	var candidates := M7ContentCatalogScript.commission_offer_candidates(
		str(run_start.get("map_config_id", "")),
		int(summary.get("run_count", 0)),
		3
	)
	if not candidates.is_empty():
		run_start["selected_objective_id"] = StringName((candidates[0] as Dictionary).get("id", &""))
	var result: Dictionary = bus.dispatch(&"start_standard_run", {"run_start_config": run_start})
	_require(bool(result.get("ok", false)), "production standard run rejected the appearance fixture: %s" % result)
	if bool(result.get("ok", false)):
		run_scene.call("_show_run_screen")
	await _frames(5)
	return {
		"main": main,
		"run_scene": run_scene,
		"player": run_scene.get("player_controller"),
		"context": run_scene.get("run_context"),
	}


func _check_default_appearance(fixture: Dictionary) -> void:
	var player: Variant = fixture.get("player")
	var context: Variant = fixture.get("context")
	_require(player != null and context != null, "default production appearance fixtures are missing")
	if player == null or context == null:
		return
	var snapshot: Dictionary = player.presentation_snapshot()
	evidence["default"] = {
		"selection": String(snapshot.get("selection_id", "")),
		"appearance": String(snapshot.get("appearance_id", "")),
		"animation_set": String(snapshot.get("animation_set_id", "")),
		"texture": String(snapshot.get("texture_path", "")),
		"sprite_modulate": snapshot.get("sprite_modulate", Color.TRANSPARENT),
	}
	_require(
		StringName(snapshot.get("selection_id", &"")) == PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID,
		"default semantic selection did not reach the production player snapshot"
	)
	_require(
		StringName(snapshot.get("appearance_id", &"")) == RuntimeAnimationCatalogScript.DEFAULT_PLAYER_APPEARANCE_ID,
		"default owned selection was not consumed by the production player"
	)
	_require(
		StringName(snapshot.get("animation_set_id", &"")) == RuntimeAnimationCatalogScript.DEFAULT_PLAYER_ANIMATION_SET_ID,
		"default selection did not resolve the audited runtime animation set"
	)
	_require(not String(snapshot.get("texture_path", "")).is_empty(), "default production player has no applied texture")
	var default_sprite_modulate: Color = snapshot.get("sprite_modulate", Color.TRANSPARENT)
	_require(
		default_sprite_modulate.is_equal_approx(Color.WHITE),
		"default production sprite did not apply its visual profile"
	)
	var admitted: Dictionary = context.run_start_config.get("player_appearance", {})
	_require(
		StringName(admitted.get("selected_appearance_id", &"")) == PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID,
		"default semantic appearance was not frozen into the admitted run"
	)
	evidence["default_geometry"] = _player_geometry_snapshot(player)


func _check_unknown_catalog_production_snapshot(fixture: Dictionary) -> void:
	var player: Variant = fixture.get("player")
	var context: Variant = fixture.get("context")
	_require(player != null and context != null, "catalog-unknown production fixtures are missing")
	if player == null or context == null:
		return
	var admitted: Dictionary = context.run_start_config.get("player_appearance", {})
	var admitted_owned: Array = admitted.get("owned_appearance_ids", [])
	var snapshot: Dictionary = player.presentation_snapshot()
	evidence["unknown_catalog_production"] = {
		"admitted_selection": String(admitted.get("selected_appearance_id", "")),
		"admitted_owned": admitted_owned.duplicate(),
		"sprite_selection": String(snapshot.get("selection_id", "")),
		"sprite_appearance": String(snapshot.get("appearance_id", "")),
		"sprite_modulate": snapshot.get("sprite_modulate", Color.TRANSPARENT),
	}
	_require(
		StringName(admitted.get("selected_appearance_id", &"")) == PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID,
		"RunStart snapshot retained a catalog-unknown owned selection"
	)
	_require(
		admitted_owned == [String(PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID)],
		"RunStart snapshot retained a catalog-unknown owned appearance"
	)
	_require(
		StringName(snapshot.get("selection_id", &"")) == StringName(admitted.get("selected_appearance_id", &"")),
		"RunStart appearance selection and production Sprite selection diverged"
	)
	_require(
		StringName(snapshot.get("appearance_id", &"")) == RuntimeAnimationCatalogScript.DEFAULT_PLAYER_APPEARANCE_ID,
		"catalog-unknown selection did not render the safe default appearance"
	)
	var sprite_modulate: Color = snapshot.get("sprite_modulate", Color.TRANSPARENT)
	_require(sprite_modulate.is_equal_approx(Color.WHITE), "catalog-unknown selection rendered a non-default tint")


func _check_non_default_appearance(fixture: Dictionary) -> void:
	var player: Variant = fixture.get("player")
	var context: Variant = fixture.get("context")
	_require(player != null and context != null, "non-default production appearance fixtures are missing")
	if player == null or context == null:
		return
	var admitted: Dictionary = context.run_start_config.get("player_appearance", {})
	var owned: Array = admitted.get("owned_appearance_ids", [])
	_require(
		StringName(admitted.get("selected_appearance_id", &"")) == PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID,
		"non-default selected appearance was not frozen into the admitted run"
	)
	_require(
		owned.has(String(PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID)),
		"admitted non-default selection is not owned"
	)
	var snapshot: Dictionary = player.presentation_snapshot()
	evidence["field_coat"] = {
		"selection": String(snapshot.get("selection_id", "")),
		"appearance": String(snapshot.get("appearance_id", "")),
		"animation_set": String(snapshot.get("animation_set_id", "")),
		"texture": String(snapshot.get("texture_path", "")),
		"sprite_modulate": snapshot.get("sprite_modulate", Color.TRANSPARENT),
	}
	_require(
		StringName(snapshot.get("selection_id", &"")) == PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID,
		"production player snapshot lost the non-default semantic selection"
	)
	_require(
		StringName(snapshot.get("appearance_id", &"")) == &"graytail_field_coat",
		"production player ignored the admitted non-default appearance"
	)
	_require(
		StringName(snapshot.get("animation_set_id", &"")) == RuntimeAnimationCatalogScript.DEFAULT_PLAYER_ANIMATION_SET_ID,
		"non-default appearance escaped the audited runtime animation set"
	)
	_require(not String(snapshot.get("texture_path", "")).is_empty(), "non-default production player has no applied texture")
	var sprite_modulate: Color = snapshot.get("sprite_modulate", Color.TRANSPARENT)
	_require(
		sprite_modulate.is_equal_approx(PlayerAppearanceConfigScript.FIELD_COAT_VISUAL_MODULATE),
		"production Sprite2D did not apply the non-default visual profile"
	)
	_require(not sprite_modulate.is_equal_approx(Color.WHITE), "non-default Sprite2D remained visually identical to default")


func _check_runtime_motion_frame_anchors() -> void:
	var baseline_foot_row := -1
	var checked_frames := 0
	for facing in RuntimeAnimationCatalogScript.PLAYER_FACINGS:
		for motion in [&"idle_a", &"idle_b", &"walk_a", &"walk_b"]:
			var path := "%s%s_%s.png" % [
				RuntimeAnimationCatalogScript.PLAYER_ROOT,
				String(facing),
				String(motion),
			]
			var image := Image.new()
			var load_error := image.load(ProjectSettings.globalize_path(path))
			_require(load_error == OK and not image.is_empty(), "runtime movement frame is missing: %s" % path)
			if load_error != OK or image.is_empty():
				continue
			var used_rect := image.get_used_rect()
			_require(used_rect.has_area(), "runtime movement frame has no visible pixels: %s" % path)
			if not used_rect.has_area():
				continue
			var foot_row := used_rect.end.y
			if baseline_foot_row < 0:
				baseline_foot_row = foot_row
			_require(
				absi(foot_row - baseline_foot_row) <= 1,
				"runtime movement frame foot anchor drifts: %s row=%d baseline=%d" % [
					path,
					foot_row,
					baseline_foot_row,
				]
			)
			var opaque_center_x := float(used_rect.position.x) + float(used_rect.size.x) * 0.5
			_require(
				absf(opaque_center_x - float(image.get_width()) * 0.5) <= 2.0,
				"runtime movement frame horizontal anchor drifts: %s center=%.1f" % [
					path,
					opaque_center_x,
				]
			)
			checked_frames += 1
	evidence["motion_frame_anchors"] = {
		"checked": checked_frames,
		"foot_row": baseline_foot_row,
	}
	_require(checked_frames == 16, "runtime movement anchor gate did not inspect all 16 idle/walk frames")


func _check_walk_cycle_rhythm() -> void:
	var descriptor := RuntimeAnimationCatalogScript.default_player_animation_set()
	var motions: Dictionary = descriptor.get("motions", {})
	var move_frames: Array = motions.get(&"move", [])
	var frame_seconds := RuntimeAnimationCatalogScript.player_frame_duration(&"move", false, descriptor)
	var contact_count := 0
	for raw_motion in move_frames:
		if String(raw_motion).begins_with("walk_"):
			contact_count += 1
	var cycle_seconds := frame_seconds * float(move_frames.size())
	var step_interval := cycle_seconds / float(maxi(1, contact_count))
	evidence["walk_rhythm"] = {
		"frames": move_frames.duplicate(),
		"frame_seconds": frame_seconds,
		"cycle_seconds": cycle_seconds,
		"contact_count": contact_count,
		"step_interval": step_interval,
	}
	_require(move_frames.size() >= 4 and contact_count >= 2, "walk cycle lacks distinct contact/passing phases")
	_require(
		step_interval >= 0.16 and step_interval <= 0.45,
		"walk contact rhythm is mechanically fast or sluggish: interval=%.3fs" % step_interval
	)


func _check_appearance_swap_geometry(fixture: Dictionary) -> void:
	var player: Variant = fixture.get("player")
	_require(player != null, "appearance-swap geometry fixture is missing")
	if player == null:
		return
	player.set_runtime_visual_state(&"idle")
	# Compare authored/profile geometry at the same canonical idle pose. The
	# production idle pulse is transient presentation, not skin-anchor drift.
	player.call("_apply_visual")
	player.set_logical_obstacles([Rect2(0.44, 0.44, 0.12, 0.12)])
	var collision_probe := Vector2(0.5, 0.5)
	var field_geometry_before := _player_geometry_snapshot(player)
	var field_texture_before := String(player.presentation_snapshot().get("texture_path", ""))
	var collision_before := bool(player.call("_position_hits_obstacle", collision_probe))

	var default_profile := PlayerAppearanceConfigScript.runtime_presentation(PlayerAppearanceConfigScript.default_config())
	player.set_presentation_profile(
		StringName(default_profile.get("appearance_id", &"")),
		StringName(default_profile.get("animation_set_id", &"")),
		default_profile.get("animation_set", {}),
		StringName(default_profile.get("selection_id", &"")),
		default_profile.get("visual_modulate", Color.WHITE)
	)
	var default_texture := String(player.presentation_snapshot().get("texture_path", ""))
	_require(
		_player_geometry_snapshot(player) == field_geometry_before,
		"switching to the base appearance changed player/collider anchor geometry"
	)
	_require(
		bool(player.call("_position_hits_obstacle", collision_probe)) == collision_before,
		"switching to the base appearance changed logical collision"
	)

	# Exercise the replacement boundary without pretending that field_coat
	# already owns a second production asset pack. The live fixture uses the
	# audited assets under a distinct animation-set id; the path-only fixture
	# proves that a future imported pack can supply a different resource root.
	var live_fixture_id := &"i3r_replaceable_player_fixture"
	var live_fixture_source := RuntimeAnimationCatalogScript.default_player_animation_set()
	live_fixture_source["appearance_id"] = &"i3r_replaceable_player"
	var live_fixture_sets: Dictionary = {}
	live_fixture_sets[live_fixture_id] = live_fixture_source
	player.set_presentation_profile(
		&"i3r_replaceable_player",
		live_fixture_id,
		live_fixture_sets,
		&"i3r.replaceable_player",
		Color.WHITE
	)
	var live_fixture_snapshot: Dictionary = player.presentation_snapshot()
	_require(
		StringName(live_fixture_snapshot.get("animation_set_id", &"")) == live_fixture_id,
		"registered replacement animation-set id did not reach the production player"
	)
	_require(
		String(live_fixture_snapshot.get("animation_root", "")) == RuntimeAnimationCatalogScript.PLAYER_ROOT,
		"registered replacement animation set did not retain its audited live resource root"
	)
	_require(
		not String(live_fixture_snapshot.get("texture_path", "")).is_empty(),
		"registered replacement animation set did not resolve a live texture"
	)
	_require(
		_player_geometry_snapshot(player) == field_geometry_before,
		"registered replacement animation set changed player/collider anchor geometry"
	)
	_require(
		bool(player.call("_position_hits_obstacle", collision_probe)) == collision_before,
		"registered replacement animation set changed logical collision"
	)

	var projected_fixture_id := &"i3r_resource_root_fixture"
	var projected_root := "res://fixtures/i3r/player_skin/"
	var projected_fixture_source := RuntimeAnimationCatalogScript.default_player_animation_set()
	projected_fixture_source["root"] = projected_root.trim_suffix("/")
	var projected_fixture_sets: Dictionary = {}
	projected_fixture_sets[projected_fixture_id] = projected_fixture_source
	var projected_fixture := RuntimeAnimationCatalogScript.resolve_player_animation_set(
		projected_fixture_id,
		projected_fixture_sets
	)
	var projected_texture_path := RuntimeAnimationCatalogScript.player_texture_path(
		&"right",
		&"move",
		2,
		false,
		false,
		projected_fixture
	)
	_require(
		StringName(projected_fixture.get("id", &"")) == projected_fixture_id,
		"replacement animation-set descriptor lost its registered identity"
	)
	_require(
		String(projected_fixture.get("root", "")) == projected_root,
		"replacement resource root was not normalized as an independent descriptor"
	)
	_require(
		projected_texture_path == projected_root + "right_walk_b.png",
		"movement texture projection ignored the replacement resource root"
	)

	var field_config := PlayerAppearanceConfigScript.default_config()
	field_config["selected_appearance_id"] = String(PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID)
	field_config["owned_appearance_ids"] = [
		String(PlayerAppearanceConfigScript.DEFAULT_SELECTION_ID),
		String(PlayerAppearanceConfigScript.FIELD_COAT_SELECTION_ID),
	]
	var field_profile := PlayerAppearanceConfigScript.runtime_presentation(field_config)
	player.set_presentation_profile(
		StringName(field_profile.get("appearance_id", &"")),
		StringName(field_profile.get("animation_set_id", &"")),
		field_profile.get("animation_set", {}),
		StringName(field_profile.get("selection_id", &"")),
		field_profile.get("visual_modulate", Color.WHITE)
	)
	var field_geometry_after := _player_geometry_snapshot(player)
	var field_texture_after := String(player.presentation_snapshot().get("texture_path", ""))
	_require(
		field_geometry_after == field_geometry_before,
		"restoring the field-coat appearance drifted player/collider anchors"
	)
	_require(
		bool(player.call("_position_hits_obstacle", collision_probe)) == collision_before,
		"restoring the field-coat appearance changed logical collision"
	)
	_require(
		not field_texture_after.is_empty()
		and field_texture_after == field_texture_before,
		"restoring the field-coat profile lost its current runtime texture"
	)
	var collision_after := bool(player.call("_position_hits_obstacle", collision_probe))
	player.set_logical_obstacles([])
	evidence["appearance_swap"] = {
		"default_texture": default_texture,
		"field_texture": field_texture_after,
		"field_shares_base_texture": field_texture_after == default_texture,
		"replacement_set_id": String(live_fixture_snapshot.get("animation_set_id", "")),
		"replacement_root_projection": projected_texture_path,
		"geometry_stable": field_geometry_after == field_geometry_before,
		"collision_stable": collision_after == collision_before,
	}


func _check_movement_direction_and_stop(fixture: Dictionary) -> void:
	var run_scene: Variant = fixture.get("run_scene")
	var player: Variant = fixture.get("player")
	_require(run_scene != null and player != null, "movement continuity production fixture is missing")
	if run_scene == null or player == null:
		return
	var run_was_processing := bool(run_scene.is_processing())
	var player_was_processing := bool(player.is_processing())
	var reduce_motion_setting := "accessibility/reduce_motion"
	var had_reduce_motion_setting := ProjectSettings.has_setting(reduce_motion_setting)
	var previous_reduce_motion: Variant = ProjectSettings.get_setting(reduce_motion_setting) if had_reduce_motion_setting else null
	ProjectSettings.set_setting(reduce_motion_setting, false)
	run_scene.set_process(false)
	player.set_process(false)
	player.reset_local_position()
	player.local_velocity = Vector2.ZERO
	player.step_preview_remaining = 0.0
	player.set_runtime_visual_state(&"idle")

	player.play_step(Vector2.RIGHT)
	var start_pos: Vector2 = player.get_local_position()
	var move_result: Dictionary = player.move_local(Vector2.RIGHT, 0.10)
	player.call("_process", 0.11)
	var right_pos: Vector2 = player.get_local_position()
	var phase_before_turn := int(player.animation_frame)
	var elapsed_before_turn := float(player.animation_elapsed)
	_require(StringName(move_result.get("status", &"")) == &"moved", "held movement did not enter the moved state")
	_require(right_pos.x > start_pos.x, "right movement produced no rightward displacement")
	_require(player.facing == &"right", "right movement produced the wrong facing")
	_require(String(player.last_texture_path).contains("/right_"), "right movement rendered a non-right texture")
	_require(phase_before_turn > 0, "walk cycle did not advance before the direction-change fixture")

	player.play_step(Vector2.UP)
	var phase_after_turn := int(player.animation_frame)
	var elapsed_after_turn := float(player.animation_elapsed)
	_require(
		phase_after_turn == phase_before_turn
		and elapsed_after_turn + 0.0001 >= elapsed_before_turn,
		"direction change hard-reset the walk phase instead of preserving cadence"
	)
	var up_result: Dictionary = player.move_local(Vector2.UP, 0.08)
	player.call("_process", 0.0)
	_require(StringName(up_result.get("status", &"")) == &"moved", "upward direction switch did not continue movement")
	_require(player.facing == &"up", "moving upward retained the previous facing")
	_require(Vector2(player.get_facing_vector()).dot(Vector2.UP) >= 0.99, "movement vector and rendered facing diverged")
	_require(String(player.last_texture_path).contains("/up_"), "upward movement rendered a non-up texture")

	var stop_iterations := 0
	while not player.local_velocity.is_zero_approx() and stop_iterations < 30:
		player.move_local(Vector2.ZERO, 1.0 / 60.0)
		player.call("_process", 1.0 / 60.0)
		stop_iterations += 1
	var stopped_pos: Vector2 = player.get_local_position()
	_require(player.local_velocity.is_zero_approx(), "released movement did not decelerate to a deterministic stop")
	_require(player.visual_state == &"idle", "released movement did not settle into idle state")
	_require(player.facing == &"up", "stopping changed the last movement facing")
	player.call("_process", 0.12)
	var early_stop_texture := String(player.last_texture_path)
	_require(
		early_stop_texture.contains("/up_idle_"),
		"stopped player retained a walk pose beyond the 120ms settle window"
	)
	player.call("_process", 0.12)
	var settled_texture := String(player.last_texture_path)
	_require(settled_texture.contains("/up_idle_"), "stopped player never reached a facing-stable idle pose")
	var sprite := player.get_node_or_null("Sprite") as Sprite2D
	_require(
		sprite != null and absf(sprite.position.y + 20.0) <= 1.0,
		"stopped player visual anchor is unstable: %s" % (sprite.position if sprite != null else Vector2.INF)
	)
	player.move_local(Vector2.ZERO, 0.10)
	_require(player.get_local_position().is_equal_approx(stopped_pos), "idle update manufactured residual sliding")
	evidence["movement"] = {
		"right_delta": right_pos - start_pos,
		"turn_phase": [phase_before_turn, phase_after_turn],
		"turn_elapsed": [elapsed_before_turn, elapsed_after_turn],
		"stop_iterations": stop_iterations,
		"early_stop_texture": early_stop_texture,
		"settled_texture": settled_texture,
	}

	if had_reduce_motion_setting:
		ProjectSettings.set_setting(reduce_motion_setting, previous_reduce_motion)
	else:
		ProjectSettings.set_setting(reduce_motion_setting, null)
	player.set_process(player_was_processing)
	run_scene.set_process(run_was_processing)


func _player_geometry_snapshot(player: Variant) -> Dictionary:
	if player == null:
		return {}
	var sprite := player.get_node_or_null("Sprite") as Sprite2D
	var anchors: Dictionary = {}
	for anchor_name in RuntimeVisualContractScript.REQUIRED_ANCHORS:
		var anchor := player.get_node_or_null(String(anchor_name)) as Node2D
		anchors[String(anchor_name)] = anchor.position if anchor != null else Vector2.INF
	return {
		"local_position": player.get_local_position(),
		"node_position": player.position,
		"room_rect": player.room_rect,
		"sprite_position": sprite.position if sprite != null else Vector2.INF,
		"sprite_scale": sprite.scale if sprite != null else Vector2.ZERO,
		"sprite_offset": sprite.offset if sprite != null else Vector2.INF,
		"sprite_centered": sprite.centered if sprite != null else false,
		"player_radius": PlayerControllerScript.PLAYER_RADIUS,
		"anchors": anchors,
	}


func _check_hurt_preserves_appearance(fixture: Dictionary) -> void:
	var player: Variant = fixture.get("player")
	_require(player != null, "hurt appearance production fixture is missing")
	if player == null:
		return
	player.set_runtime_visual_state(&"hurt")
	await process_frame
	var hurt_snapshot: Dictionary = player.presentation_snapshot()
	var hurt_modulate: Color = hurt_snapshot.get("sprite_modulate", Color.TRANSPARENT)
	var expected_hurt_modulate := (
		PlayerAppearanceConfigScript.FIELD_COAT_VISUAL_MODULATE
		* PlayerControllerScript.HURT_FEEDBACK_MODULATE
	)
	_require(
		hurt_modulate.is_equal_approx(expected_hurt_modulate),
		"hurt feedback replaced rather than composed with the non-default appearance"
	)
	_require(
		not hurt_modulate.is_equal_approx(PlayerControllerScript.HURT_FEEDBACK_MODULATE),
		"hurt feedback erased the non-default appearance identity"
	)
	player.set_runtime_visual_state(&"idle")
	player.call("_advance_transient_state", 1.0)
	await process_frame
	var recovered_snapshot: Dictionary = player.presentation_snapshot()
	var recovered_modulate: Color = recovered_snapshot.get("sprite_modulate", Color.TRANSPARENT)
	evidence["hurt_composition"] = {
		"profile": PlayerAppearanceConfigScript.FIELD_COAT_VISUAL_MODULATE,
		"hurt": hurt_modulate,
		"recovered": recovered_modulate,
	}
	_require(
		recovered_modulate.is_equal_approx(PlayerAppearanceConfigScript.FIELD_COAT_VISUAL_MODULATE),
		"non-default appearance did not recover its exact profile tint after hurt"
	)


func _check_blocked_edge_has_no_reverse_step(fixture: Dictionary) -> void:
	var run_scene: Variant = fixture.get("run_scene")
	var player: Variant = fixture.get("player")
	var context: Variant = fixture.get("context")
	_require(run_scene != null and player != null and context != null, "blocked-edge production fixtures are missing")
	if run_scene == null or player == null or context == null:
		return
	context.player_pos = Vector2i.ZERO
	context.current_pos = Vector2i.ZERO
	player.set_local_position(Vector2(PlayerControllerScript.PLAYER_RADIUS, 0.5))
	player.local_velocity = Vector2(-0.4, 0.0)
	var before: Vector2 = player.get_local_position()
	run_scene.call("_attempt_room_transition", Vector2i.LEFT)
	await process_frame
	var after: Vector2 = player.get_local_position()
	evidence["blocked_edge"] = {
		"before": before,
		"after": after,
	}
	_require(after.is_equal_approx(before), "blocked edge manufactured a reverse displacement")
	_require(
		after.x + 0.000001 >= PlayerControllerScript.PLAYER_RADIUS,
		"blocked edge let the player cross the room boundary"
	)
	_require(player.local_velocity.is_zero_approx(), "blocked edge retained movement into the rejected boundary")


func _dispose_case(fixture: Dictionary) -> void:
	var main: Variant = fixture.get("main")
	if main != null:
		main.queue_free()
	await _frames(4)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print(
			"%s default=%s field_coat=%s motion=%s rhythm=%s anchors=%s appearance_swap=%s blocked=%s->%s unowned=fail_closed unknown_catalog=fail_closed hurt=profile_composed"
			% [
				PASS_MARKER,
				evidence.get("default", {}),
				evidence.get("field_coat", {}),
				evidence.get("movement", {}),
				evidence.get("walk_rhythm", {}),
				evidence.get("motion_frame_anchors", {}),
				evidence.get("appearance_swap", {}),
				(evidence.get("blocked_edge", {}) as Dictionary).get("before", Vector2.ZERO),
				(evidence.get("blocked_edge", {}) as Dictionary).get("after", Vector2.ZERO),
			]
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R player movement/appearance failure: " + failure)
	print("%s failures=%d evidence=%s" % [FAIL_MARKER, failures.size(), evidence])
	quit(1)
