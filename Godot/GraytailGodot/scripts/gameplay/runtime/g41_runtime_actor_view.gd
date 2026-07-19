extends Node2D
class_name G41RuntimeActorView

const EnemyVisualCatalog := preload("res://scripts/presentation/art24/art24_enemy_visual_catalog.gd")
const ENEMY_SHADOW_TEXTURE := preload("res://assets/ui/art21/main_menu/scene/character/shadow.png")
const Art24MotionSettingsScript := preload("res://scripts/presentation/art24/art24_motion_settings.gd")

var actor_id: String = ""
var subject: StringName = &"unknown"
var visual_key: StringName = &"runtime.missing"
var visual_state: StringName = &"idle"
var visual_variant: StringName = &"base"
var max_hp: int = 1
var hp: int = 1
var placeholder_color := Color(0.78, 0.30, 0.30, 1.0)
var contract_nodes_ready: bool = false
var last_visual_signature := ""
var last_texture_path := ""
var animation_elapsed := 0.0
var animation_frame := 0


func configure(next_subject: StringName, snapshot: Dictionary) -> void:
	var previous_subject := subject
	var previous_state := visual_state
	var previous_variant := visual_variant
	subject = next_subject
	actor_id = String(snapshot.get("enemy_id", snapshot.get("projectile_id", snapshot.get("actor_id", actor_id))))
	visual_key = G41RuntimeVisualContract.visual_key_for(subject)
	visual_state = StringName(snapshot.get("state", &"idle"))
	visual_variant = StringName(snapshot.get("visual_variant", &"base"))
	if subject != previous_subject or visual_state != previous_state or visual_variant != previous_variant:
		animation_elapsed = 0.0
		animation_frame = 0
		last_texture_path = ""
	max_hp = maxi(1, int(snapshot.get("max_hp", max_hp)))
	hp = clampi(int(snapshot.get("hp", hp)), 0, max_hp)
	position = local_to_world(Vector2(snapshot.get("pos", Vector2(0.5, 0.5))))
	if not contract_nodes_ready:
		_ensure_contract_nodes()
	_ensure_enemy_visual()
	var signature := "%s|%s|%s|%d|%d" % [String(subject), String(visual_state), String(visual_variant), hp, max_hp]
	if signature != last_visual_signature:
		last_visual_signature = signature
		_apply_placeholder()
		_apply_enemy_visual()


func _ready() -> void:
	_ensure_contract_nodes()
	_apply_placeholder()
	last_visual_signature = "%s|%s|%s|%d|%d" % [String(subject), String(visual_state), String(visual_variant), hp, max_hp]
	set_process(true)


func _process(delta: float) -> void:
	if not EnemyVisualCatalog.supports(subject):
		return
	var frame_count := EnemyVisualCatalog.frame_count(subject, visual_state, visual_variant)
	var reduce_motion := Art24MotionSettingsScript.reduce_motion_enabled()
	if reduce_motion:
		animation_elapsed = 0.0
		animation_frame = 0
	else:
		animation_elapsed += delta
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
	_apply_enemy_visual()


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
	if visual_root.get_node_or_null("ProgramPlaceholder") == null:
		var polygon := Polygon2D.new()
		polygon.name = "ProgramPlaceholder"
		visual_root.add_child(polygon)
	if get_node_or_null("HealthBarAnchor/HealthBackground") == null:
		var background := ColorRect.new()
		background.name = "HealthBackground"
		background.position = Vector2(-16, -23)
		background.size = Vector2(32, 4)
		background.color = Color(0.12, 0.07, 0.08, 0.90)
		get_node("HealthBarAnchor").add_child(background)
		var fill := ColorRect.new()
		fill.name = "HealthFill"
		fill.position = Vector2(-15, -22)
		fill.size = Vector2(30, 2)
		fill.color = Color(0.85, 0.20, 0.22, 1.0)
		get_node("HealthBarAnchor").add_child(fill)
	if get_node_or_null("PromptAnchor/StateLabel") == null:
		var label := Label.new()
		label.name = "StateLabel"
		label.position = Vector2(-42, 14)
		label.size = Vector2(84, 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		get_node("PromptAnchor").add_child(label)
	contract_nodes_ready = true


func _apply_placeholder() -> void:
	var polygon := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if polygon != null:
		polygon.color = _color_for_subject()
		polygon.polygon = _shape_for_subject()
		polygon.visible = get_node_or_null("VisualRoot/ArtVisual") == null
	var state_label := get_node_or_null("PromptAnchor/StateLabel") as Label
	if state_label != null:
		state_label.text = String(visual_state)
		# Runtime state remains available to tests and accessibility hooks, but
		# production art communicates it through poses instead of debug copy.
		state_label.visible = false
	var health_fill := get_node_or_null("HealthBarAnchor/HealthFill") as ColorRect
	var health_background := get_node_or_null("HealthBarAnchor/HealthBackground") as ColorRect
	var show_health := subject in [&"slime", &"slimeling", &"bat", &"drone"] and hp > 0
	if health_background != null:
		health_background.visible = show_health
	if health_fill != null:
		health_fill.visible = show_health
		health_fill.size.x = 30.0 * float(hp) / float(max_hp)
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
	if visual_root.get_node_or_null("ArtVisual") == null:
		var sprite := Sprite2D.new()
		sprite.name = "ArtVisual"
		visual_root.add_child(sprite)
	var polygon := visual_root.get_node_or_null("ProgramPlaceholder") as Polygon2D
	if polygon != null:
		polygon.visible = false


func _apply_enemy_visual() -> void:
	if not EnemyVisualCatalog.supports(subject):
		return
	var sprite := get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	if sprite == null:
		return
	var texture_path := EnemyVisualCatalog.texture_path(subject, visual_state, animation_frame, visual_variant)
	if texture_path != last_texture_path:
		sprite.texture = load(texture_path) as Texture2D
		last_texture_path = texture_path
	var base_scale := EnemyVisualCatalog.visual_scale(subject, visual_variant)
	var motion_phase := 0.0 if Art24MotionSettingsScript.reduce_motion_enabled() else sin(animation_elapsed / EnemyVisualCatalog.frame_duration(visual_state) * TAU)
	var active_scale := base_scale * (1.04 if visual_state in [&"warning", &"aim", &"active", &"fire"] else 1.0)
	if subject in [&"slime", &"slimeling"] and visual_state not in [&"dead", &"defeated"]:
		sprite.scale = Vector2(
			active_scale * (1.0 + motion_phase * 0.045),
			active_scale * (1.0 - motion_phase * 0.030)
		)
	else:
		sprite.scale = Vector2.ONE * active_scale
	var bob_amount := 1.6 if subject in [&"bat", &"drone"] else 0.8
	if visual_state in [&"dead", &"defeated"]:
		bob_amount = 0.0
	sprite.position = EnemyVisualCatalog.visual_offset(subject) + Vector2(0, motion_phase * bob_amount)
	if visual_state == &"hurt":
		sprite.modulate = Color(1.0, 0.58, 0.50, 1.0)
	elif visual_state in [&"warning", &"aim"]:
		var pulse := (motion_phase + 1.0) * 0.5
		sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.72, 0.42, 1.0), pulse * 0.42)
	else:
		sprite.modulate = Color.WHITE
	_apply_enemy_shadow(motion_phase, bob_amount)


func _apply_enemy_shadow(motion_phase: float, bob_amount: float) -> void:
	var shadow := get_node_or_null("VisualRoot/GroundShadow") as Sprite2D
	if shadow == null:
		return
	var base_shadow_scale := _shadow_scale()
	var hover_factor := 1.0 - absf(motion_phase) * (0.08 if bob_amount > 1.0 else 0.025)
	if subject in [&"slime", &"slimeling"] and visual_state not in [&"dead", &"defeated"]:
		hover_factor = 1.0 - motion_phase * 0.025
	shadow.scale = base_shadow_scale * hover_factor
	shadow.position = _shadow_position()
	var shadow_alpha := 0.43 if subject in [&"bat", &"drone"] else 0.56
	if visual_state in [&"dead", &"defeated"]:
		shadow_alpha *= 0.72
	shadow.modulate = Color(0.10, 0.07, 0.055, shadow_alpha)


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


func _apply_enemy_health_position() -> void:
	if not EnemyVisualCatalog.supports(subject):
		return
	var health_y := EnemyVisualCatalog.health_bar_y(subject)
	var background := get_node_or_null("HealthBarAnchor/HealthBackground") as ColorRect
	var fill := get_node_or_null("HealthBarAnchor/HealthFill") as ColorRect
	if background != null:
		background.position.y = health_y
	if fill != null:
		fill.position.y = health_y + 1.0


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
			return PackedVector2Array([Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0), Vector2(0, 5)])
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
