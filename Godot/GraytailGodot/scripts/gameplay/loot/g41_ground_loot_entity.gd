extends "res://scripts/gameplay/interaction/g41_interactable.gd"
class_name G41GroundLootEntity

signal feedback_finished(instance_id: String)

const ItemVisualCatalog := preload("res://scripts/presentation/art24/art24_item_visual_catalog.gd")
const ItemRarityDescriptorScript := preload("res://scripts/presentation/item_rarity_descriptor.gd")
const PICKUP_BEAM_TEXTURES := [
	preload("res://assets/art24/fx/pickup_beam_0.png"),
	preload("res://assets/art24/fx/pickup_beam_1.png"),
	preload("res://assets/art24/fx/pickup_beam_2.png"),
	preload("res://assets/art24/fx/pickup_beam_3.png"),
	preload("res://assets/art24/fx/pickup_beam_4.png"),
	preload("res://assets/art24/fx/pickup_beam_5.png"),
	preload("res://assets/art24/fx/pickup_beam_6.png"),
	preload("res://assets/art24/fx/pickup_beam_7.png"),
]
const BEAM_FRAME_COUNT := 8
const BEAM_FRAME_SECONDS := 0.09
const REVEAL_SECONDS := 0.18
const PICKUP_FEEDBACK_SECONDS := 0.24
const BLOCKED_FEEDBACK_SECONDS := 0.22

var item: Dictionary = {}
var beam_elapsed := 0.0
var beam_frame := 0
var reveal_remaining := 0.0
var pickup_feedback_remaining := 0.0
var blocked_feedback_remaining := 0.0
var retiring := false


func configure_item(projection: Dictionary) -> void:
	var first_reveal := interaction_id.is_empty()
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
	if first_reveal:
		play_reveal_feedback()
	set_process(true)


func set_pickup_result(ok: bool) -> void:
	if ok:
		begin_pickup_feedback()
		return
	if retiring:
		return
	visual_state = &"blocked"
	blocked_feedback_remaining = BLOCKED_FEEDBACK_SECONDS
	_apply_visual_state()


func play_reveal_feedback() -> void:
	if retiring:
		return
	reveal_remaining = REVEAL_SECONDS
	_apply_feedback_transform()


func begin_pickup_feedback() -> void:
	if retiring:
		return
	retiring = true
	enabled = false
	focused = false
	visual_state = &"pickup"
	reveal_remaining = 0.0
	blocked_feedback_remaining = 0.0
	pickup_feedback_remaining = PICKUP_FEEDBACK_SECONDS
	_apply_visual_state()


func is_retiring() -> bool:
	return retiring


func _process(delta: float) -> void:
	var safe_delta := maxf(delta, 0.0)
	beam_elapsed += safe_delta
	if beam_elapsed >= BEAM_FRAME_SECONDS:
		var elapsed_frames := maxi(1, int(beam_elapsed / BEAM_FRAME_SECONDS))
		beam_elapsed = fmod(beam_elapsed, BEAM_FRAME_SECONDS)
		beam_frame = (beam_frame + elapsed_frames) % BEAM_FRAME_COUNT
		var beam := get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
		if beam != null:
			beam.texture = PICKUP_BEAM_TEXTURES[beam_frame]

	if retiring:
		pickup_feedback_remaining = maxf(0.0, pickup_feedback_remaining - safe_delta)
		_apply_feedback_transform()
		if pickup_feedback_remaining <= 0.0:
			feedback_finished.emit(interaction_id)
			queue_free()
		return
	if blocked_feedback_remaining > 0.0:
		blocked_feedback_remaining = maxf(0.0, blocked_feedback_remaining - safe_delta)
		if blocked_feedback_remaining <= 0.0:
			visual_state = &"idle"
			_apply_visual_state()
	if reveal_remaining > 0.0:
		reveal_remaining = maxf(0.0, reveal_remaining - safe_delta)
		_apply_feedback_transform()


func _apply_visual_state() -> void:
	super._apply_visual_state()
	var art_visual := get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	var beam := get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
	var rarity_color := Color(ItemRarityDescriptorScript.describe_item(item).get("color", Color.WHITE))
	if art_visual != null:
		# Failure/focus feedback must not overwrite the item's rarity channel.
		art_visual.modulate = Color(1.10, 1.10, 1.06, 1.0) if focused else Color.WHITE
		art_visual.scale = Vector2.ONE * (0.21 if focused else 0.18)
	if beam != null:
		beam.modulate = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.90)
	var blocked_marker := get_node_or_null("VisualRoot/BlockedMarker") as Label
	if blocked_marker != null:
		blocked_marker.visible = visual_state == &"blocked"
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
	_apply_feedback_transform()


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
		art_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual_root.add_child(art_visual)
	if visual_root.get_node_or_null("BlockedMarker") == null:
		var blocked_marker := Label.new()
		blocked_marker.name = "BlockedMarker"
		blocked_marker.position = Vector2(-13, -22)
		blocked_marker.size = Vector2(26, 26)
		blocked_marker.text = "×"
		blocked_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blocked_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		blocked_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blocked_marker.z_index = 5
		blocked_marker.add_theme_font_size_override("font_size", 22)
		blocked_marker.add_theme_color_override("font_color", Color(1.0, 0.22, 0.16, 1.0))
		blocked_marker.add_theme_color_override("font_outline_color", Color(0.08, 0.015, 0.01, 1.0))
		blocked_marker.add_theme_constant_override("outline_size", 2)
		visual_root.add_child(blocked_marker)
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
	var resolution := ItemVisualCatalog.resolve(item, &"world_ground_drop")
	if art_visual != null:
		art_visual.texture = resolution.get("texture", null) as Texture2D
		art_visual.set_meta("item_visual_resolution", resolution.duplicate())
		art_visual.set_meta("requested_visual_key", resolution.get("requested_key", &""))
		art_visual.set_meta("resolved_visual_key", resolution.get("resolved_key", &""))
		art_visual.set_meta("resolved_texture_path", resolution.get("resolved_path", ""))
	var beam := get_node_or_null("VisualRoot/PickupBeam") as Sprite2D
	if beam != null:
		beam.texture = PICKUP_BEAM_TEXTURES[0]
		beam.set_meta("rarity_key", ItemRarityDescriptorScript.describe_item(item).get("key", &"unknown"))
	var caption := get_node_or_null("PromptAnchor/LootCaption") as Label
	if caption != null:
		caption.text = "%s  ·  估值 %d" % [
			String(item.get("display_name", item.get("item_id", "回收物"))),
			int(item.get("base_value", item.get("value", 0))),
		]
		caption.visible = false
	_apply_visual_state()


func _apply_feedback_transform() -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if retiring:
		var pickup_progress := 1.0 - clampf(pickup_feedback_remaining / PICKUP_FEEDBACK_SECONDS, 0.0, 1.0)
		visual_root.position = Vector2(0.0, -18.0 * pickup_progress)
		visual_root.scale = Vector2.ONE * (1.0 + 0.12 * pickup_progress)
		visual_root.modulate = Color(1.0, 1.0, 1.0, 1.0 - pickup_progress)
		return
	if reveal_remaining > 0.0:
		var reveal_progress := 1.0 - clampf(reveal_remaining / REVEAL_SECONDS, 0.0, 1.0)
		var eased_progress := 1.0 - pow(1.0 - reveal_progress, 3.0)
		visual_root.position = Vector2(0.0, lerpf(6.0, 0.0, eased_progress))
		visual_root.scale = Vector2.ONE * lerpf(0.72, 1.0, eased_progress)
		visual_root.modulate = Color(1.0, 1.0, 1.0, eased_progress)
		return
	visual_root.position = Vector2.ZERO
	visual_root.scale = Vector2.ONE
	visual_root.modulate = Color.WHITE


func _placeholder_color() -> Color:
	var rarity_color := Color(ItemRarityDescriptorScript.describe_item(item).get("color", Color(0.34, 0.88, 0.78, 1.0)))
	if focused:
		return rarity_color.lightened(0.16)
	return rarity_color
