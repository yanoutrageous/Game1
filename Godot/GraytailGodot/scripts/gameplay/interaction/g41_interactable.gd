extends Node2D
class_name G41Interactable

var interaction_id: String = ""
var interaction_kind: StringName = &"unknown"
var local_pos := Vector2(0.5, 0.5)
var interaction_radius: float = 0.15
var enabled: bool = true
var focused: bool = false
var visual_state: StringName = &"idle"
var prompt_text: String = "Interact"
var payload: Dictionary = {}


func configure_interactable(data: Dictionary) -> void:
	interaction_id = String(data.get("interaction_id", interaction_id))
	interaction_kind = StringName(data.get("interaction_kind", interaction_kind))
	local_pos = Vector2(data.get("local_pos", local_pos))
	interaction_radius = maxf(0.01, float(data.get("interaction_radius", interaction_radius)))
	enabled = bool(data.get("enabled", enabled))
	visual_state = StringName(data.get("visual_state", visual_state))
	prompt_text = String(data.get("prompt_text", prompt_text))
	payload = (data.get("payload", {}) as Dictionary).duplicate(true)
	position = local_to_world(local_pos)
	_ensure_contract_nodes()
	_apply_visual_state()


func distance_to_local(point: Vector2) -> float:
	return local_pos.distance_to(point)


func can_interact_from(point: Vector2) -> bool:
	return enabled and distance_to_local(point) <= interaction_radius


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
		"interaction_id": interaction_id,
		"interaction_kind": interaction_kind,
		"local_pos": local_pos,
		"interaction_radius": interaction_radius,
		"enabled": enabled,
		"focused": focused,
		"visual_state": visual_state,
		"prompt_text": prompt_text,
		"payload": payload.duplicate(true),
	}


func _ready() -> void:
	position = local_to_world(local_pos)
	_ensure_contract_nodes()
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
		get_node("PromptAnchor").add_child(label)


func _apply_visual_state() -> void:
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.color = _placeholder_color()
		placeholder.visible = get_node_or_null("VisualRoot/ArtVisual") == null
	var prompt := get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	if prompt != null:
		prompt.text = "[E] %s" % prompt_text
		prompt.visible = focused and enabled


func _placeholder_color() -> Color:
	if not enabled:
		return Color(0.32, 0.32, 0.34, 0.85)
	if focused:
		return Color(1.0, 0.82, 0.30, 1.0)
	return Color(0.45, 0.70, 0.88, 1.0)


static func local_to_world(value: Vector2) -> Vector2:
	return G41RuntimeLayout.local_to_world(value)
