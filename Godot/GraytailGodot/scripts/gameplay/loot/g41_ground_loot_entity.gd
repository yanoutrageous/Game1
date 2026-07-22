extends "res://scripts/gameplay/interaction/g41_interactable.gd"
class_name G41GroundLootEntity

const ItemVisualCatalog := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const PICKUP_BEAM_ROOT := "res://assets/art24/fx/pickup_beam_"
const BEAM_FRAME_COUNT := 8
const BEAM_FRAME_SECONDS := 0.09

var item: Dictionary = {}
var beam_elapsed := 0.0
var beam_frame := 0


func configure_item(projection: Dictionary) -> void:
	var projection_payload: Dictionary = projection.get("payload", {})
	item = (projection_payload.get("item", {}) as Dictionary).duplicate(true)
	var descriptor := projection.duplicate(true)
	descriptor["visual_state"] = &"focused" if focused else &"idle"
	configure_interactable(descriptor)
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
		art_visual.scale = Vector2.ONE * (0.21 if focused else 0.18)
	if beam != null:
		beam.modulate = Color(1.0, 0.48, 0.32, 0.92) if visual_state == &"blocked" else Color(0.32, 0.78, 1.0, 0.90)
	var prompt := get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	if prompt != null:
		prompt.text = "[G] 地面回收 · 1件物资"
		# The proximity context popup is the only interaction copy. Keeping a
		# second floating label on every floor item recreated the fixed clutter
		# that ART24R2 is removing.
		prompt.visible = false
	var caption := get_node_or_null("PromptAnchor/LootCaption") as Label
	if caption != null:
		caption.visible = false


func _ensure_art_visuals() -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if visual_root.get_node_or_null("PickupBeam") == null:
		var beam := Sprite2D.new()
		beam.name = "PickupBeam"
		beam.position = Vector2(0, -20)
		beam.scale = Vector2(0.45, 0.45)
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
		art_visual.texture = ItemVisualCatalog.texture_for_visual_key(visual_key)
	var beam := get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
	if beam != null:
		beam.texture = load("%s0.png" % PICKUP_BEAM_ROOT) as Texture2D
	var caption := get_node_or_null("PromptAnchor/LootCaption") as Label
	if caption != null:
		caption.text = "%s  ·  估值 %d" % [
			String(item.get("display_name", item.get("item_id", "回收物"))),
			int(item.get("base_value", item.get("value", 0))),
		]
		caption.visible = false
	_apply_visual_state()


func _placeholder_color() -> Color:
	if visual_state == &"blocked":
		return Color(0.92, 0.28, 0.25, 1.0)
	if focused:
		return Color(1.0, 0.88, 0.32, 1.0)
	return Color(0.34, 0.88, 0.78, 1.0)
