extends "res://scripts/gameplay/interaction/g41_interactable.gd"
class_name G41GroundLootEntity

const WORLD_ITEM_ROOT := "res://assets/art24/items/world/"
const PICKUP_BEAM_ROOT := "res://assets/art24/fx/pickup_beam_"
const BEAM_FRAME_COUNT := 8
const BEAM_FRAME_SECONDS := 0.09

var item: Dictionary = {}
var beam_elapsed := 0.0
var beam_frame := 0


func configure_item(item_snapshot: Dictionary, spawn_local_pos: Vector2) -> void:
	item = item_snapshot.duplicate(true)
	var instance_id := String(item.get("instance_id", "missing_instance"))
	configure_interactable({
		"interaction_id": instance_id,
		"interaction_kind": &"ground_loot",
		"local_pos": spawn_local_pos,
		"interaction_radius": 0.14,
		"enabled": true,
		"visual_state": &"focused" if focused else &"idle",
		"prompt_text": "Pick up %s" % String(item.get("display_name", item.get("item_id", "item"))),
		"payload": {"instance_id": instance_id},
	})
	var placeholder := get_node_or_null("VisualRoot/ProgramPlaceholder") as Polygon2D
	if placeholder != null:
		placeholder.polygon = PackedVector2Array([Vector2(0, -9), Vector2(11, -2), Vector2(7, 9), Vector2(-7, 9), Vector2(-11, -2)])
	_ensure_art_visuals()
	_apply_item_visual()
	set_process(true)


func set_pickup_result(ok: bool) -> void:
	visual_state = &"pickup" if ok else &"blocked"
	_apply_visual_state()


func _process(delta: float) -> void:
	beam_elapsed += delta
	if beam_elapsed < BEAM_FRAME_SECONDS:
		return
	beam_elapsed = fmod(beam_elapsed, BEAM_FRAME_SECONDS)
	beam_frame = (beam_frame + 1) % BEAM_FRAME_COUNT
	var beam := get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
	if beam != null:
		beam.texture = load("%s%d.png" % [PICKUP_BEAM_ROOT, beam_frame]) as Texture2D


func _apply_visual_state() -> void:
	super._apply_visual_state()
	var art_visual := get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	var beam := get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
	if art_visual != null:
		art_visual.modulate = Color(1.0, 0.58, 0.52, 1.0) if visual_state == &"blocked" else (Color(1.16, 1.08, 0.76, 1.0) if focused else Color.WHITE)
		art_visual.scale = Vector2.ONE * (0.29 if focused else 0.25)
	if beam != null:
		beam.modulate = Color(1.0, 0.48, 0.32, 0.92) if visual_state == &"blocked" else Color(0.32, 0.78, 1.0, 0.90)
	var prompt := get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	if prompt != null:
		prompt.text = "[G] 地面回收 · 1件物资"
		prompt.visible = focused and enabled


func _ensure_art_visuals() -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if visual_root.get_node_or_null("PickupBeam") == null:
		var beam := Sprite2D.new()
		beam.name = "PickupBeam"
		beam.position = Vector2(0, -20)
		beam.scale = Vector2(0.72, 0.72)
		visual_root.add_child(beam)
		visual_root.move_child(beam, 0)
	if visual_root.get_node_or_null("ArtVisual") == null:
		var art_visual := Sprite2D.new()
		art_visual.name = "ArtVisual"
		art_visual.position = Vector2(0, -3)
		visual_root.add_child(art_visual)
	if get_node_or_null("PromptAnchor/LootCaption") == null:
		var caption := Label.new()
		caption.name = "LootCaption"
		caption.position = Vector2(-84, 16)
		caption.size = Vector2(168, 36)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 12)
		caption.add_theme_color_override("font_color", Color(0.90, 0.84, 0.66, 1.0))
		caption.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.04, 0.95))
		caption.add_theme_constant_override("shadow_offset_x", 1)
		caption.add_theme_constant_override("shadow_offset_y", 1)
		get_node("PromptAnchor").add_child(caption)


func _apply_item_visual() -> void:
	var art_visual := get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	if art_visual != null:
		art_visual.texture = load(_item_texture_path()) as Texture2D
	var beam := get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
	if beam != null:
		beam.texture = load("%s0.png" % PICKUP_BEAM_ROOT) as Texture2D
	var caption := get_node_or_null("PromptAnchor/LootCaption") as Label
	if caption != null:
		caption.text = "%s  ·  估值 %d" % [
			String(item.get("display_name", item.get("item_id", "回收物"))),
			int(item.get("base_value", item.get("value", 0))),
		]
	_apply_visual_state()


func _item_texture_path() -> String:
	var item_id := String(item.get("item_id", "")).to_lower()
	if item_id.contains("key"):
		return WORLD_ITEM_ROOT + "access_key.png"
	if item_id.contains("scan") or item_id.contains("goggle"):
		return WORLD_ITEM_ROOT + "scanner_probe.png"
	if item_id.contains("bag") or item_id.contains("cache"):
		return WORLD_ITEM_ROOT + "salvage_satchel.png"
	if item_id.contains("coin") or item_id.contains("receipt"):
		return WORLD_ITEM_ROOT + "coin_cache.png"
	match StringName(item.get("item_type", item.get("main_type", &"collectible"))):
		&"equipment":
			return WORLD_ITEM_ROOT + "armor_plate.png"
		&"consumable":
			return WORLD_ITEM_ROOT + "emergency_bandage.png"
		&"special":
			return WORLD_ITEM_ROOT + "anomaly_shard.png"
		_:
			return WORLD_ITEM_ROOT + "copper_coil.png"


func _placeholder_color() -> Color:
	if visual_state == &"blocked":
		return Color(0.92, 0.28, 0.25, 1.0)
	if focused:
		return Color(1.0, 0.88, 0.32, 1.0)
	return Color(0.34, 0.88, 0.78, 1.0)
