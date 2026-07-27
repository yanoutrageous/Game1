extends Node2D
class_name G41RuntimeActorView

const EnemyVisualCatalog := preload("res://scripts/presentation/art24/art24_enemy_visual_catalog.gd")
const ENEMY_SHADOW_TEXTURE := preload("res://assets/ui/art21/main_menu/scene/character/shadow.png")
const PROJECTILE_TEXTURE := preload("res://assets/art24/fx/ue_bat_bolt.png")
const Art24MotionSettingsScript := preload("res://scripts/presentation/art24/art24_motion_settings.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const APPEARANCE_DURATION := 0.32
const APPEARANCE_FIRST_FRAME_ALPHA := 0.72
const APPEARANCE_FIRST_FRAME_SCALE := 0.72
const APPEARANCE_LIFT_PIXELS := 9.0
const ENTRY_CUE_COLOR := Color(1.0, 0.68, 0.26, 0.42)
const PROJECTILE_SOURCE_FORWARD := Vector2.UP

var actor_id: String = ""
var subject: StringName = &"unknown"
var visual_key: StringName = &"runtime.missing"
var visual_state: StringName = &"idle"
var visual_variant: StringName = &"base"
var max_hp: int = 1
var hp: int = 1
var enemy_name: String = ""
var enemy_power: int = -1
var placeholder_color := Color(0.78, 0.30, 0.30, 1.0)
var contract_nodes_ready: bool = false
var last_visual_signature := ""
var last_texture_path := ""
var last_texture_subject: StringName = &""
var last_texture_state: StringName = &""
var last_texture_variant: StringName = &""
var last_texture_frame := -1
var animation_elapsed := 0.0
var animation_frame := 0
var pending_visual_state: StringName = &""
var transient_state_remaining := 0.0
var appearance_remaining := 0.0
var art_sprite: Sprite2D
var ground_shadow: Sprite2D
var entry_cue: Polygon2D
var placeholder_polygon: Polygon2D
var state_label: Label
var health_fill: ColorRect
var health_background: ColorRect
var identity_label: Label
var cached_visual_scale := 1.0
var cached_visual_offset := Vector2.ZERO
var cached_shadow_scale := Vector2.ONE
var cached_shadow_position := Vector2.ZERO
var enemy_visual_enabled := false
var projectile_visual_radius := 0.0

const ENEMY_STATUS_Z := 80


func configure(next_subject: StringName, snapshot: Dictionary) -> void:
	var previous_subject := subject
	var previous_variant := visual_variant
	var previous_actor_id := actor_id
	var previous_visual_state := visual_state
	var next_actor_id := String(snapshot.get("enemy_id", snapshot.get("projectile_id", snapshot.get("actor_id", actor_id))))
	var next_is_enemy := EnemyVisualCatalog.supports(next_subject)
	enemy_visual_enabled = next_is_enemy
	var next_visual_state := StringName(snapshot.get("state", &"idle"))
	subject = next_subject
	actor_id = next_actor_id
	visual_key = G41RuntimeVisualContract.visual_key_for(subject)
	visual_variant = StringName(snapshot.get("visual_variant", &"base"))
	max_hp = maxi(1, int(snapshot.get("max_hp", max_hp)))
	hp = clampi(int(snapshot.get("hp", hp)), 0, max_hp)
	enemy_name = String(snapshot.get("enemy_name", ""))
	enemy_power = int(snapshot.get("enemy_power", -1))
	position = local_to_world(Vector2(snapshot.get("pos", Vector2(0.5, 0.5))))
	if not contract_nodes_ready:
		_ensure_contract_nodes()
	# Projectiles use a fixed presentation-only polygon. Keep their moving world
	# position and public state current without paying the enemy animation,
	# texture-selection, and formatted-signature path for every projectile on
	# every frame.
	if not next_is_enemy:
		visual_state = next_visual_state
		if subject != previous_subject or visual_variant != previous_variant:
			pending_visual_state = &""
			transient_state_remaining = 0.0
			animation_elapsed = 0.0
			animation_frame = 0
			_apply_placeholder()
		elif visual_state != previous_visual_state and state_label != null:
			state_label.text = String(visual_state)
			state_label.visible = false
		return
	var starts_enemy_appearance := previous_actor_id == "" or previous_actor_id != next_actor_id or not EnemyVisualCatalog.supports(previous_subject)
	if subject != previous_subject or visual_variant != previous_variant:
		_refresh_cached_geometry()
		pending_visual_state = &""
		visual_state = next_visual_state
		transient_state_remaining = EnemyVisualCatalog.minimum_visible_seconds(visual_state)
		animation_elapsed = 0.0
		animation_frame = 0
		_invalidate_texture_selection()
	else:
		_request_visual_state(next_visual_state)
	_ensure_enemy_visual()
	if starts_enemy_appearance:
		_start_appearance_envelope()
	var signature := "%s|%s|%s|%d|%d|%s|%d" % [
		String(subject),
		String(visual_state),
		String(visual_variant),
		hp,
		max_hp,
		enemy_name,
		enemy_power,
	]
	if signature != last_visual_signature:
		last_visual_signature = signature
		_apply_placeholder()
		_apply_enemy_visual()


func configure_projectile(snapshot: Dictionary) -> void:
	var previous_subject := subject
	var previous_state := visual_state
	var previous_radius := projectile_visual_radius
	subject = &"projectile"
	enemy_visual_enabled = false
	actor_id = String(snapshot.get("projectile_id", actor_id))
	visual_state = StringName(snapshot.get("state", &"active"))
	projectile_visual_radius = maxf(0.0, float(snapshot.get("visual_radius", snapshot.get("radius", 0.0))))
	position = local_to_world(Vector2(snapshot.get("pos", Vector2(0.5, 0.5))))
	if not contract_nodes_ready:
		_ensure_contract_nodes()
	_ensure_projectile_visual(snapshot)
	if previous_subject != subject:
		visual_key = G41RuntimeVisualContract.visual_key_for(subject)
		visual_variant = &"base"
		pending_visual_state = &""
		transient_state_remaining = 0.0
		animation_elapsed = 0.0
		animation_frame = 0
		_apply_placeholder()
	elif visual_state != previous_state and state_label != null:
		state_label.text = String(visual_state)
		state_label.visible = false
	if not is_equal_approx(previous_radius, projectile_visual_radius):
		_apply_projectile_geometry(snapshot)
	_apply_placeholder()


func _ready() -> void:
	_ensure_contract_nodes()
	_apply_placeholder()
	last_visual_signature = "%s|%s|%s|%d|%d|%s|%d" % [
		String(subject),
		String(visual_state),
		String(visual_variant),
		hp,
		max_hp,
		enemy_name,
		enemy_power,
	]
	set_process(true)


func _process(delta: float) -> void:
	if not enemy_visual_enabled:
		return
	_advance_transient_state(delta)
	var frame_count := EnemyVisualCatalog.frame_count(subject, visual_state, visual_variant)
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	if reduce_motion:
		animation_elapsed = 0.0
		animation_frame = 0
		appearance_remaining = 0.0
	else:
		animation_elapsed += delta
		if appearance_remaining > 0.0:
			appearance_remaining = maxf(0.0, appearance_remaining - maxf(delta, 0.0))
	var frame_duration := EnemyVisualCatalog.frame_duration(visual_state)
	var next_frame := 0 if reduce_motion else int(animation_elapsed / frame_duration)
	if EnemyVisualCatalog.loops(visual_state):
		next_frame %= maxi(frame_count, 1)
	else:
		next_frame = mini(next_frame, maxi(frame_count - 1, 0))
	if next_frame != animation_frame:
		animation_frame = next_frame
	# UE's base slime has a single idle bitmap. Keep that authoritative source,
	# but animate its transform so it does not freeze while multi-frame bat and
	# drone sets continue to use their real frames. No texture is reloaded while
	# the path is unchanged.
	var motion_phase := 0.0 if reduce_motion else sin(animation_elapsed / frame_duration * TAU)
	_apply_enemy_visual_frame(reduce_motion, motion_phase)
	if appearance_remaining <= 0.0 and entry_cue != null and entry_cue.visible:
		entry_cue.visible = false


func appearance_snapshot() -> Dictionary:
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	return {
		"duration": APPEARANCE_DURATION,
		"remaining": appearance_remaining,
		"progress": _appearance_progress(reduce_motion),
		"phase": &"arrival" if appearance_remaining > 0.0 and not reduce_motion else EnemyVisualCatalog.presentation_phase(visual_state),
		"cue_visible": entry_cue != null and entry_cue.visible,
		"reduced_motion": reduce_motion,
		"presentation_only": true,
	}


func presentation_snapshot() -> Dictionary:
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	return {
		"actor_id": actor_id,
		"authority_state": visual_state,
		"phase": &"arrival" if appearance_remaining > 0.0 and not reduce_motion else EnemyVisualCatalog.presentation_phase(visual_state),
		"queued_authority_state": pending_visual_state,
		"minimum_visible_remaining": transient_state_remaining,
		"reduced_motion": reduce_motion,
		"presentation_only": true,
	}


func _start_appearance_envelope() -> void:
	appearance_remaining = 0.0 if Art24MotionSettingsScript.reduce_motion_enabled() else APPEARANCE_DURATION


func _request_visual_state(next_state: StringName) -> void:
	if next_state in [&"dead", &"defeated"] or (next_state == &"hurt" and visual_state != &"hurt"):
		pending_visual_state = &""
		_set_visual_state_now(next_state)
		return
	if transient_state_remaining > 0.0 and next_state != visual_state:
		pending_visual_state = next_state
		return
	pending_visual_state = &""
	_set_visual_state_now(next_state)


func _set_visual_state_now(next_state: StringName) -> void:
	if visual_state == next_state:
		return
	visual_state = next_state
	animation_elapsed = 0.0
	animation_frame = 0
	_invalidate_texture_selection()
	transient_state_remaining = EnemyVisualCatalog.minimum_visible_seconds(visual_state)


func _advance_transient_state(delta: float) -> void:
	if transient_state_remaining <= 0.0:
		return
	transient_state_remaining = maxf(0.0, transient_state_remaining - delta)
	if transient_state_remaining > 0.0 or pending_visual_state == &"":
		return
	var next_state := pending_visual_state
	pending_visual_state = &""
	_set_visual_state_now(next_state)
	last_visual_signature = ""
	_apply_placeholder()


func _ensure_contract_nodes() -> void:
	if contract_nodes_ready:
		return
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		visual_root = Node2D.new()
		visual_root.name = "VisualRoot"
		add_child(visual_root)
	for anchor_name: StringName in G41RuntimeVisualContract.REQUIRED_ANCHORS:
		if anchor_name == &"VisualRoot" or get_node_or_null(String(anchor_name)) != null:
			continue
		var anchor := Node2D.new()
		anchor.name = String(anchor_name)
		add_child(anchor)
	var health_bar_anchor := get_node_or_null("HealthBarAnchor") as Node2D
	if health_bar_anchor != null:
		# Combat status is screen-readable HUD, not world decoration. Keep it
		# above slash/telegraph and foreground props even when the enemy sprite
		# itself is depth-sorted behind the altar or a doorway.
		health_bar_anchor.z_as_relative = false
		health_bar_anchor.z_index = ENEMY_STATUS_Z
	if visual_root.get_node_or_null("ProgramPlaceholder") == null:
		var polygon := Polygon2D.new()
		polygon.name = "ProgramPlaceholder"
		visual_root.add_child(polygon)
	if get_node_or_null("HealthBarAnchor/HealthBackground") == null:
		var background := ColorRect.new()
		background.name = "HealthBackground"
		background.position = Vector2(-36, -30)
		background.size = Vector2(72, 7)
		background.color = Color(0.035, 0.026, 0.024, 0.96)
		get_node("HealthBarAnchor").add_child(background)
		var fill := ColorRect.new()
		fill.name = "HealthFill"
		fill.position = Vector2(-35, -29)
		fill.size = Vector2(70, 5)
		fill.color = Color(0.88, 0.24, 0.20, 1.0)
		get_node("HealthBarAnchor").add_child(fill)
	if get_node_or_null("HealthBarAnchor/IdentityLabel") == null:
		var identity := Label.new()
		identity.name = "IdentityLabel"
		identity.position = Vector2(-48, -48)
		identity.size = Vector2(96, 15)
		identity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		identity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		identity.autowrap_mode = TextServer.AUTOWRAP_OFF
		identity.clip_text = false
		identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Art10UISkinKitScript.apply_composition_label(
			identity,
			&"status",
			10,
			Color(0.96, 0.86, 0.58, 1.0)
		)
		identity.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
		identity.add_theme_constant_override("outline_size", 3)
		get_node("HealthBarAnchor").add_child(identity)
	if get_node_or_null("PromptAnchor/StateLabel") == null:
		var label := Label.new()
		label.name = "StateLabel"
		label.position = Vector2(-42, 14)
		label.size = Vector2(84, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		get_node("PromptAnchor").add_child(label)
	placeholder_polygon = visual_root.get_node_or_null("ProgramPlaceholder") as Polygon2D
	state_label = get_node_or_null("PromptAnchor/StateLabel") as Label
	health_fill = get_node_or_null("HealthBarAnchor/HealthFill") as ColorRect
	health_background = get_node_or_null("HealthBarAnchor/HealthBackground") as ColorRect
	identity_label = get_node_or_null("HealthBarAnchor/IdentityLabel") as Label
	contract_nodes_ready = true


func _apply_placeholder() -> void:
	if placeholder_polygon != null:
		placeholder_polygon.color = _color_for_subject()
		placeholder_polygon.polygon = _shape_for_subject()
		placeholder_polygon.visible = art_sprite == null
	if state_label != null:
		state_label.text = String(visual_state)
		# Runtime state remains available to tests and accessibility hooks, but
		# production art communicates it through poses instead of debug copy.
		state_label.visible = false
	var show_health := subject in [&"slime", &"slimeling", &"bat", &"drone"] and hp > 0
	if health_background != null:
		health_background.visible = show_health
	if health_fill != null:
		health_fill.visible = show_health
		var inner_width := _enemy_health_bar_width() - 2.0
		health_fill.size.x = inner_width * float(hp) / float(max_hp)
	if identity_label != null:
		identity_label.visible = show_health and enemy_power >= 0 and not enemy_name.is_empty()
		if identity_label.visible:
			identity_label.text = (
				"%s  战力 %d" % [enemy_name, enemy_power]
				if subject != &"slimeling"
				else "幼体  %d" % enemy_power
			)
	_apply_enemy_health_position()


func _ensure_enemy_visual() -> void:
	if not EnemyVisualCatalog.supports(subject):
		return
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if visual_root.get_node_or_null("GroundShadow") == null:
		var shadow := Sprite2D.new()
		shadow.name = "GroundShadow"
		shadow.texture = ENEMY_SHADOW_TEXTURE
		shadow.position = _shadow_position()
		shadow.scale = _shadow_scale()
		shadow.modulate = Color(0.10, 0.07, 0.055, 0.58)
		shadow.z_index = -1
		visual_root.add_child(shadow)
		visual_root.move_child(shadow, 0)
	ground_shadow = visual_root.get_node_or_null("GroundShadow") as Sprite2D
	if visual_root.get_node_or_null("EntryCue") == null:
		var cue := Polygon2D.new()
		cue.name = "EntryCue"
		cue.polygon = _ellipse_points(25.0, 9.0, 28)
		cue.color = ENTRY_CUE_COLOR
		cue.z_index = -2
		cue.visible = false
		visual_root.add_child(cue)
		visual_root.move_child(cue, 0)
	entry_cue = visual_root.get_node_or_null("EntryCue") as Polygon2D
	if visual_root.get_node_or_null("ArtVisual") == null:
		var sprite := Sprite2D.new()
		sprite.name = "ArtVisual"
		visual_root.add_child(sprite)
	art_sprite = visual_root.get_node_or_null("ArtVisual") as Sprite2D
	if placeholder_polygon != null:
		placeholder_polygon.visible = false


func _ensure_projectile_visual(snapshot: Dictionary) -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if visual_root.get_node_or_null("ArtVisual") == null:
		var sprite := Sprite2D.new()
		sprite.name = "ArtVisual"
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual_root.add_child(sprite)
	art_sprite = visual_root.get_node_or_null("ArtVisual") as Sprite2D
	if art_sprite == null:
		return
	art_sprite.texture = PROJECTILE_TEXTURE
	art_sprite.visible = true
	art_sprite.modulate = Color.WHITE
	last_texture_path = PROJECTILE_TEXTURE.resource_path
	_apply_projectile_geometry(snapshot)
	if placeholder_polygon != null:
		placeholder_polygon.visible = false


func _apply_projectile_geometry(snapshot: Dictionary) -> void:
	if art_sprite == null or art_sprite.texture == null:
		return
	var radius_pixels := G41RuntimeLayout.local_size_to_world(
		Vector2(projectile_visual_radius, projectile_visual_radius)
	)
	var diameter := maxf(4.0, radius_pixels.x * 2.0)
	var source_size := art_sprite.texture.get_size()
	var uniform_scale := diameter / maxf(1.0, maxf(source_size.x, source_size.y))
	art_sprite.scale = Vector2.ONE * uniform_scale
	art_sprite.position = Vector2.ZERO
	var velocity := Vector2(snapshot.get("velocity", Vector2.ZERO))
	if velocity.length_squared() > 0.000001:
		art_sprite.rotation = PROJECTILE_SOURCE_FORWARD.angle_to(velocity.normalized())
	else:
		art_sprite.rotation = 0.0


func _apply_enemy_visual() -> void:
	if not EnemyVisualCatalog.supports(subject):
		return
	if art_sprite == null:
		return
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	var motion_phase := 0.0 if reduce_motion else sin(animation_elapsed / EnemyVisualCatalog.frame_duration(visual_state) * TAU)
	_apply_enemy_visual_frame(reduce_motion, motion_phase)


func _apply_enemy_visual_frame(reduce_motion: bool, motion_phase: float) -> void:
	var texture_frame := EnemyVisualCatalog.reduced_motion_frame(subject, visual_state, visual_variant) if reduce_motion else animation_frame
	if (
		last_texture_subject != subject
		or last_texture_state != visual_state
		or last_texture_variant != visual_variant
		or last_texture_frame != texture_frame
	):
		var texture_path := EnemyVisualCatalog.texture_path(subject, visual_state, texture_frame, visual_variant)
		var texture := EnemyVisualCatalog.texture_for(subject, visual_state, texture_frame, visual_variant)
		if texture != null:
			art_sprite.texture = texture
			last_texture_path = texture_path
			last_texture_subject = subject
			last_texture_state = visual_state
			last_texture_variant = visual_variant
			last_texture_frame = texture_frame
	var active_scale := cached_visual_scale * (1.04 if visual_state in [&"warning", &"aim", &"active", &"fire"] else 1.0)
	if subject in [&"slime", &"slimeling"] and visual_state not in [&"dead", &"defeated"]:
		art_sprite.scale = Vector2(
			active_scale * (1.0 + motion_phase * 0.045),
			active_scale * (1.0 - motion_phase * 0.030)
		)
	else:
		art_sprite.scale = Vector2.ONE * active_scale
	var bob_amount := 1.6 if subject in [&"bat", &"drone"] else 0.8
	if visual_state in [&"dead", &"defeated"]:
		bob_amount = 0.0
	art_sprite.position = cached_visual_offset + Vector2(0, motion_phase * bob_amount)
	if visual_state == &"hurt":
		art_sprite.modulate = Color(1.0, 0.58, 0.50, 1.0)
	elif visual_state in [&"warning", &"aim"]:
		var pulse := (motion_phase + 1.0) * 0.5
		art_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.72, 0.42, 1.0), pulse * 0.42)
	elif visual_state == &"cooldown":
		art_sprite.modulate = Color(0.84, 0.88, 0.82, 1.0)
	elif visual_state in [&"dead", &"defeated"]:
		art_sprite.modulate = Color(0.76, 0.72, 0.68, 0.92)
	else:
		art_sprite.modulate = Color.WHITE
	_apply_enemy_shadow(motion_phase, bob_amount)
	# The entry envelope is finished during the 300-frame formal warmup. Avoid
	# paying its transform/node lookup cost for every enemy on every later frame.
	if appearance_remaining > 0.0:
		_apply_appearance_envelope(art_sprite, reduce_motion)


func _apply_appearance_envelope(sprite: Sprite2D, reduce_motion: bool) -> void:
	var progress := _appearance_progress(reduce_motion)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	var scale_factor := lerpf(APPEARANCE_FIRST_FRAME_SCALE, 1.0, eased)
	var alpha_factor := lerpf(APPEARANCE_FIRST_FRAME_ALPHA, 1.0, eased)
	sprite.scale *= scale_factor
	sprite.position.y -= lerpf(APPEARANCE_LIFT_PIXELS, 0.0, eased)
	sprite.modulate.a *= alpha_factor
	if ground_shadow != null:
		ground_shadow.scale *= lerpf(0.82, 1.0, eased)
		ground_shadow.modulate.a *= alpha_factor
	if entry_cue != null:
		entry_cue.visible = not reduce_motion and progress < 1.0
		entry_cue.scale = Vector2.ONE * lerpf(0.64, 1.28, eased)
		entry_cue.modulate = Color(1.0, 1.0, 1.0, 1.0 - eased)


func _appearance_progress(reduce_motion: bool) -> float:
	if reduce_motion or APPEARANCE_DURATION <= 0.0:
		return 1.0
	return clampf(1.0 - appearance_remaining / APPEARANCE_DURATION, 0.0, 1.0)


func _apply_enemy_shadow(motion_phase: float, bob_amount: float) -> void:
	if ground_shadow == null:
		return
	var base_shadow_scale := cached_shadow_scale
	var hover_factor := 1.0 - absf(motion_phase) * (0.08 if bob_amount > 1.0 else 0.025)
	if subject in [&"slime", &"slimeling"] and visual_state not in [&"dead", &"defeated"]:
		hover_factor = 1.0 - motion_phase * 0.025
	ground_shadow.scale = base_shadow_scale * hover_factor
	ground_shadow.position = cached_shadow_position
	var shadow_alpha := 0.43 if subject in [&"bat", &"drone"] else 0.56
	if visual_state in [&"dead", &"defeated"]:
		shadow_alpha *= 0.72
	ground_shadow.modulate = Color(0.10, 0.07, 0.055, shadow_alpha)


func _shadow_scale() -> Vector2:
	var width_scale := 0.24
	match subject:
		&"slimeling": width_scale = 0.15
		&"bat": width_scale = 0.23
		&"drone": width_scale = 0.21
	if visual_variant != &"base":
		width_scale *= 0.88
	return Vector2(width_scale, maxf(width_scale * 0.82, 0.10))


func _shadow_position() -> Vector2:
	match subject:
		&"slimeling": return Vector2(0, 9)
		&"bat": return Vector2(0, 10)
		&"drone": return Vector2(0, 9)
	return Vector2(0, 12)


func _refresh_cached_geometry() -> void:
	cached_visual_scale = EnemyVisualCatalog.visual_scale(subject, visual_variant)
	cached_visual_offset = EnemyVisualCatalog.visual_offset(subject)
	cached_shadow_scale = _shadow_scale()
	cached_shadow_position = _shadow_position()


func _invalidate_texture_selection() -> void:
	last_texture_path = ""
	last_texture_subject = &""
	last_texture_state = &""
	last_texture_variant = &""
	last_texture_frame = -1


func _apply_enemy_health_position() -> void:
	if not EnemyVisualCatalog.supports(subject):
		return
	var health_y := EnemyVisualCatalog.health_bar_y(subject)
	var bar_width := _enemy_health_bar_width()
	var bar_height := 6.0 if subject == &"slimeling" else 7.0
	if health_background != null:
		health_background.position = Vector2(-bar_width * 0.5, health_y)
		health_background.size = Vector2(bar_width, bar_height)
	if health_fill != null:
		health_fill.position = Vector2(-bar_width * 0.5 + 1.0, health_y + 1.0)
		health_fill.size.y = bar_height - 2.0
	if identity_label != null:
		var identity_width := 60.0 if subject == &"slimeling" else 96.0
		identity_label.position = Vector2(-identity_width * 0.5, health_y - 17.0)
		identity_label.size = Vector2(identity_width, 15.0)


func _enemy_health_bar_width() -> float:
	return 54.0 if subject == &"slimeling" else 72.0


func _ellipse_points(radius_x: float, radius_y: float, point_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(maxi(point_count, 3)):
		var angle := TAU * float(index) / float(maxi(point_count, 3))
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _shape_for_subject() -> PackedVector2Array:
	match subject:
		&"slime":
			return PackedVector2Array([Vector2(-16, 10), Vector2(-13, -8), Vector2(0, -15), Vector2(13, -8), Vector2(16, 10)])
		&"slimeling":
			return PackedVector2Array([Vector2(-10, 7), Vector2(-8, -6), Vector2(0, -10), Vector2(8, -6), Vector2(10, 7)])
		&"bat":
			return PackedVector2Array([Vector2(-20, -5), Vector2(-7, -10), Vector2(0, 3), Vector2(7, -10), Vector2(20, -5), Vector2(8, 9), Vector2(-8, 9)])
		&"drone":
			return PackedVector2Array([Vector2(-14, -12), Vector2(14, -12), Vector2(18, 0), Vector2(14, 12), Vector2(-14, 12), Vector2(-18, 0)])
		&"projectile":
			var radius_pixels := G41RuntimeLayout.local_size_to_world(
				Vector2(projectile_visual_radius, projectile_visual_radius)
			)
			return _ellipse_points(maxf(2.0, radius_pixels.x), maxf(2.0, radius_pixels.y), 16)
	return PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])


func _color_for_subject() -> Color:
	match subject:
		&"slime":
			return Color(0.32, 0.78, 0.42, 1.0)
		&"slimeling":
			return Color(0.52, 0.92, 0.48, 1.0)
		&"bat":
			return Color(0.58, 0.34, 0.78, 1.0)
		&"drone":
			return Color(0.92, 0.58, 0.20, 1.0)
		&"projectile":
			return Color(1.0, 0.78, 0.28, 1.0)
	return placeholder_color


static func local_to_world(local_pos: Vector2) -> Vector2:
	return G41RuntimeLayout.local_to_world(local_pos)
