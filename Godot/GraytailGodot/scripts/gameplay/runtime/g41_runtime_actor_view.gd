extends Node2D
class_name G41RuntimeActorView

const ROOM_RECT := Rect2(Vector2(420, 220), Vector2(440, 360))

var actor_id: String = ""
var subject: StringName = &"unknown"
var visual_key: StringName = &"runtime.missing"
var visual_state: StringName = &"idle"
var max_hp: int = 1
var hp: int = 1
var placeholder_color := Color(0.78, 0.30, 0.30, 1.0)


func configure(next_subject: StringName, snapshot: Dictionary) -> void:
	subject = next_subject
	actor_id = String(snapshot.get("enemy_id", snapshot.get("projectile_id", snapshot.get("actor_id", actor_id))))
	visual_key = G41RuntimeVisualContract.visual_key_for(subject)
	visual_state = StringName(snapshot.get("state", &"idle"))
	max_hp = maxi(1, int(snapshot.get("max_hp", max_hp)))
	hp = clampi(int(snapshot.get("hp", hp)), 0, max_hp)
	position = local_to_world(Vector2(snapshot.get("pos", Vector2(0.5, 0.5))))
	_ensure_contract_nodes()
	_apply_placeholder()


func _ready() -> void:
	_ensure_contract_nodes()
	_apply_placeholder()


func _ensure_contract_nodes() -> void:
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


func _apply_placeholder() -> void:
	var polygon := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if polygon != null:
		polygon.color = _color_for_subject()
		polygon.polygon = _shape_for_subject()
		polygon.visible = get_node_or_null("VisualRoot/ArtVisual") == null
	var state_label := get_node_or_null("PromptAnchor/StateLabel") as Label
	if state_label != null:
		state_label.text = String(visual_state)
		state_label.visible = visual_state in [&"warning", &"aim", &"fire", &"hurt"]
	var health_fill := get_node_or_null("HealthBarAnchor/HealthFill") as ColorRect
	var health_background := get_node_or_null("HealthBarAnchor/HealthBackground") as ColorRect
	var show_health := subject in [&"slime", &"slimeling", &"bat", &"drone"] and hp > 0
	if health_background != null:
		health_background.visible = show_health
	if health_fill != null:
		health_fill.visible = show_health
		health_fill.size.x = 30.0 * float(hp) / float(max_hp)


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
	return ROOM_RECT.position + Vector2(local_pos.x * ROOM_RECT.size.x, local_pos.y * ROOM_RECT.size.y)
