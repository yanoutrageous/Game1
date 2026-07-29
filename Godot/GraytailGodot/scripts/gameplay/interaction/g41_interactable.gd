extends Node2D
class_name G41Interactable

const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const RuntimeInputProfileScript := preload("res://scripts/core/input/runtime_input_profile.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")

var interaction_id: String = ""
var interaction_kind: StringName = &"unknown"
var local_pos := Vector2(0.5, 0.5)
var interaction_radius: float = 0.15
var body_rect := Rect2(Vector2(0.46, 0.46), Vector2(0.08, 0.08))
var context_anchor_local := Vector2(0.5, 0.42)
var presentation_contract: StringName = &""
var ground_anchor_local := Vector2(0.5, 0.5)
var pivot_normalized := Vector2(0.5, 0.5)
var display_size_local := Vector2(0.08, 0.08)
var visual_rect_local := Rect2(Vector2(0.46, 0.46), Vector2(0.08, 0.08))
var visual_key: StringName = &"runtime.missing"
var orientation: StringName = &"none"
var depth_key: StringName = &"world.default"
var enabled: bool = true
var focused: bool = false
var visual_state: StringName = &"idle"
var prompt_text: String = "Interact"
var payload: Dictionary = {}


func configure_interactable(data: Dictionary) -> void:
	interaction_id = String(data.get("projection_id", data.get("interaction_id", interaction_id)))
	interaction_kind = StringName(data.get("interaction_kind", interaction_kind))
	local_pos = Vector2(data.get("local_pos", local_pos))
	interaction_radius = maxf(0.0, float(data.get("interaction_radius", interaction_radius)))
	body_rect = Rect2(data.get("body_rect", body_rect))
	context_anchor_local = Vector2(data.get("context_anchor_local", local_pos))
	presentation_contract = StringName(data.get("presentation_contract", presentation_contract))
	ground_anchor_local = Vector2(data.get("ground_anchor_local", local_pos))
	pivot_normalized = Vector2(data.get("pivot_normalized", pivot_normalized))
	display_size_local = Vector2(data.get("display_size_local", body_rect.size))
	visual_rect_local = Rect2(data.get(
		"visual_rect_local",
		Rect2(ground_anchor_local - display_size_local * pivot_normalized, display_size_local)
	))
	visual_key = StringName(data.get("visual_key", visual_key))
	orientation = StringName(data.get("orientation", orientation))
	depth_key = StringName(data.get("depth_key", depth_key))
	enabled = bool(data.get("enabled", enabled))
	visual_state = StringName(data.get("visual_state", visual_state))
	prompt_text = String(data.get("prompt_text", prompt_text))
	payload = (data.get("payload", {}) as Dictionary).duplicate(true)
	position = local_to_world(local_pos)
	z_index = _z_index_for_depth(depth_key)
	_ensure_contract_nodes()
	_apply_visual_state()


func distance_to_local(point: Vector2) -> float:
	return local_pos.distance_to(point)


func can_interact_from(point: Vector2) -> bool:
	return enabled and distance_to_local(point) <= interaction_radius


func get_context_anchor_world() -> Vector2:
	return local_to_world(context_anchor_local)


func set_focused(next_focused: bool) -> void:
	focused = next_focused and enabled
	_apply_visual_state()


func build_interaction_request() -> Dictionary:
	return {
		"accepted": enabled,
		"interaction_id": interaction_id,
		"interaction_kind": interaction_kind,
		"payload": payload.duplicate(true),
		"visual_state": visual_state,
	}


func build_snapshot() -> Dictionary:
	return {
		"projection_id": interaction_id,
		"interaction_id": interaction_id,
		"interaction_kind": interaction_kind,
		"local_pos": local_pos,
		"interaction_radius": interaction_radius,
		"body_rect": body_rect,
		"context_anchor_local": context_anchor_local,
		"presentation_contract": presentation_contract,
		"ground_anchor_local": ground_anchor_local,
		"pivot_normalized": pivot_normalized,
		"display_size_local": display_size_local,
		"visual_rect_local": visual_rect_local,
		"visual_key": visual_key,
		"orientation": orientation,
		"depth_key": depth_key,
		"enabled": enabled,
		"focused": focused,
		"visual_state": visual_state,
		"prompt_text": prompt_text,
		"payload": payload.duplicate(true),
		"visual_resolution": visual_resolution_snapshot(),
	}


func _ready() -> void:
	add_to_group(RuntimeInputProfileScript.HINT_CONSUMER_GROUP)
	position = local_to_world(local_pos)
	_ensure_contract_nodes()
	_apply_visual_state()


func refresh_input_hints() -> void:
	_apply_visual_state()


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
		polygon.polygon = PackedVector2Array([Vector2(-14, -12), Vector2(14, -12), Vector2(14, 12), Vector2(-14, 12)])
		visual_root.add_child(polygon)
	if get_node_or_null("PromptAnchor/InteractionPrompt") == null:
		var label := Label.new()
		label.name = "InteractionPrompt"
		label.position = Vector2(-72, -43)
		label.size = Vector2(144, 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		Art10UISkinKitScript.apply_player_ui_font(label, &"display")
		get_node("PromptAnchor").add_child(label)


func _apply_visual_state() -> void:
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.color = _placeholder_color()
		placeholder.visible = not has_resolved_art_visual()
		placeholder.set_meta("fallback_reason", &"art_texture_unresolved" if placeholder.visible else &"none")
	var prompt := get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	if prompt != null:
		var interact_hint := SemanticActionHintScript.current_binding_label(&"interact")
		prompt.text = (
			"%s %s" % [interact_hint, prompt_text]
			if not interact_hint.is_empty()
			else prompt_text
		)
		prompt.visible = focused and enabled


func has_resolved_art_visual() -> bool:
	var art_visual := get_node_or_null("VisualRoot/ArtVisual")
	if art_visual is Sprite2D:
		var sprite := art_visual as Sprite2D
		return sprite.visible and sprite.texture != null and sprite.modulate.a >= 0.25
	if art_visual is TextureRect:
		var texture_rect := art_visual as TextureRect
		return texture_rect.visible and texture_rect.texture != null and texture_rect.modulate.a >= 0.25
	return false


func has_visible_collision_correspondence() -> bool:
	if has_resolved_art_visual():
		return true
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	return placeholder != null and placeholder.visible and placeholder.color.a >= 0.25


func visual_resolution_snapshot() -> Dictionary:
	var art_visual := get_node_or_null("VisualRoot/ArtVisual")
	var texture: Texture2D = null
	var visible := false
	if art_visual is Sprite2D:
		texture = (art_visual as Sprite2D).texture
		visible = (art_visual as Sprite2D).visible
	elif art_visual is TextureRect:
		texture = (art_visual as TextureRect).texture
		visible = (art_visual as TextureRect).visible
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	return {
		"visual_key": visual_key,
		"texture_resolved": texture != null,
		"resolved_texture_path": texture.resource_path if texture != null else "",
		"resolved_texture_size": texture.get_size() if texture != null else Vector2.ZERO,
		"art_visible": visible,
		"fallback_visible": placeholder != null and placeholder.visible,
		"collision_correspondence_visible": has_visible_collision_correspondence(),
	}


func _placeholder_color() -> Color:
	if not enabled:
		return Color(0.32, 0.32, 0.34, 0.85)
	if focused:
		return Color(1.0, 0.82, 0.30, 1.0)
	return Color(0.45, 0.70, 0.88, 1.0)


static func local_to_world(value: Vector2) -> Vector2:
	return G41RuntimeLayout.local_to_world(value)


static func _z_index_for_depth(value: StringName) -> int:
	match value:
		# Mine grates are embedded in the room floor. At the shared z=0 the
		# earlier RoomLayer draws them before the later PlayerLayer, matching
		# the UE floor-hazard ordering while transient burst FX stays above.
		&"world.interactable.mine":
			return 0
		&"world.interactable.loot":
			return 32
		&"world.interactable.chest":
			return 24
		&"world.door":
			return 4
	return 16
