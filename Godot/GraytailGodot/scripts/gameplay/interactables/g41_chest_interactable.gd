extends "res://scripts/gameplay/interaction/g41_interactable.gd"
class_name G41ChestInteractable

const OPENING_SECONDS := 0.28
const AssetContract := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")
const RuntimeLayout := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")
const OPENING_FX_FRAMES := 6

var opening_remaining: float = 0.0
var container_open: bool = false
var authority_opened: bool = false


func configure_chest(projection: Dictionary) -> void:
	var projected_state := StringName(projection.get("visual_state", &"closed"))
	var projected_opened := projected_state == &"opened"
	authority_opened = projected_opened
	# A view refresh may happen while the result-driven opening FX is playing.
	# Preserve that presentation timer, but never infer authority from it.
	if visual_state != &"opening":
		visual_state = &"opened" if projected_opened else &"closed"
		container_open = projected_opened
		opening_remaining = 0.0
	var descriptor := projection.duplicate(true)
	descriptor["enabled"] = true
	descriptor["visual_state"] = visual_state
	configure_interactable(descriptor)
	_ensure_art_visuals()
	_apply_visual_state()


func build_search_intent() -> Dictionary:
	if authority_opened or visual_state in [&"opening", &"opened"]:
		return {
			"accepted": true,
			"interaction_id": interaction_id,
			"interaction_kind": &"chest",
			"intent": &"inspect_opened_chest",
			"payload": payload.duplicate(true),
		}
	return {
		"accepted": enabled,
		"interaction_id": interaction_id,
		"interaction_kind": &"chest",
		"intent": &"search_current_room",
		"payload": payload.duplicate(true),
	}


func apply_search_result(ok: bool) -> void:
	if not ok:
		visual_state = &"closed"
		authority_opened = false
		container_open = false
		enabled = true
		opening_remaining = 0.0
		_apply_visual_state()
		return
	authority_opened = true
	container_open = true
	visual_state = &"opening"
	enabled = true
	opening_remaining = OPENING_SECONDS
	_apply_visual_state()


func advance(delta: float) -> void:
	if visual_state != &"opening":
		return
	opening_remaining = maxf(0.0, opening_remaining - maxf(0.0, delta))
	if opening_remaining > 0.0:
		_apply_visual_state()
		return
	# Animation completion only settles presentation.  It cannot emit a command
	# or mutate the authoritative room/ledger state.
	visual_state = &"opened" if authority_opened else &"closed"
	enabled = true
	_apply_visual_state()


func mark_opened(animate: bool = false) -> void:
	authority_opened = true
	container_open = true
	if animate:
		apply_search_result(true)
	else:
		visual_state = &"opened"
		enabled = true
		opening_remaining = 0.0
		_apply_visual_state()


func is_opened() -> bool:
	return authority_opened


func is_container_open() -> bool:
	return authority_opened and container_open


func _ensure_art_visuals() -> void:
	var visual_root := get_node_or_null("VisualRoot") as Node2D
	if visual_root == null:
		return
	if visual_root.get_node_or_null("ArtVisual") == null:
		var art_visual := Sprite2D.new()
		art_visual.name = "ArtVisual"
		art_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual_root.add_child(art_visual)
	if visual_root.get_node_or_null("OpeningFx") == null:
		var opening_fx := Sprite2D.new()
		opening_fx.name = "OpeningFx"
		opening_fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		opening_fx.visible = false
		visual_root.add_child(opening_fx)


func _apply_visual_state() -> void:
	super._apply_visual_state()
	var art_visual := get_node_or_null("VisualRoot/ArtVisual") as Sprite2D
	var opening_fx := get_node_or_null("VisualRoot/OpeningFx") as Sprite2D
	if art_visual != null:
		var stable_visual_key := &"visual.art24.prop.chest_open_state" if authority_opened else &"visual.art24.prop.chest_closed"
		visual_key = stable_visual_key
		art_visual.texture = AssetContract.texture(stable_visual_key)
		if art_visual.texture == null:
			art_visual.texture = AssetContract.texture(&"visual.art24.prop.chest_closed")
		art_visual.modulate = Color(1.08, 0.94, 0.70, 1.0) if focused else Color.WHITE
		_apply_art_geometry(art_visual, stable_visual_key)
		art_visual.rotation = 0.0
		if authority_opened:
			art_visual.modulate = Color(1.06, 0.96, 0.76, 1.0) if focused else Color.WHITE
	if opening_fx != null:
		opening_fx.visible = visual_state == &"opening"
		if opening_fx.visible:
			var progress := 1.0 - clampf(opening_remaining / OPENING_SECONDS, 0.0, 1.0)
			var frame := mini(OPENING_FX_FRAMES - 1, int(progress * float(OPENING_FX_FRAMES)))
			opening_fx.texture = AssetContract.texture(StringName("visual.art24.fx.chest_opening.%d" % frame))
			_apply_opening_fx_geometry(opening_fx)
	# The parent fallback decision is texture-based. Re-evaluate it after this
	# subtype has assigned the stable chest texture.
	super._apply_visual_state()
	var prompt := get_node_or_null("PromptAnchor/InteractionPrompt") as Label
	if prompt != null:
		prompt.visible = false


func _apply_art_geometry(sprite: Sprite2D, stable_visual_key: StringName) -> void:
	if sprite.texture == null:
		return
	var art_presentation := AssetContract.world_presentation_for(stable_visual_key)
	pivot_normalized = Vector2(art_presentation.get("pivot_normalized", pivot_normalized))
	display_size_local = Vector2(art_presentation.get("display_size_local", display_size_local))
	visual_rect_local = Rect2(ground_anchor_local - display_size_local * pivot_normalized, display_size_local)
	var desired_size := RuntimeLayout.local_size_to_world(display_size_local)
	var texture_size := sprite.texture.get_size()
	sprite.scale = Vector2(
		desired_size.x / maxf(1.0, texture_size.x),
		desired_size.y / maxf(1.0, texture_size.y)
	)
	var ground_offset := RuntimeLayout.local_to_world(ground_anchor_local) - RuntimeLayout.local_to_world(local_pos)
	sprite.position = ground_offset + Vector2(
		(0.5 - pivot_normalized.x) * desired_size.x,
		(0.5 - pivot_normalized.y) * desired_size.y
	)


func _apply_opening_fx_geometry(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	var art_presentation := AssetContract.world_presentation_for(visual_key)
	var fx_footprint_local := Vector2(art_presentation.get("fx_footprint_local", display_size_local))
	var chest_size := RuntimeLayout.local_size_to_world(fx_footprint_local)
	var desired_fx_size := Vector2.ONE * maxf(chest_size.x, chest_size.y) * 1.20
	var texture_size := sprite.texture.get_size()
	sprite.scale = Vector2(
		desired_fx_size.x / maxf(1.0, texture_size.x),
		desired_fx_size.y / maxf(1.0, texture_size.y)
	)
	var ground_offset := RuntimeLayout.local_to_world(ground_anchor_local) - RuntimeLayout.local_to_world(local_pos)
	sprite.position = ground_offset + Vector2(0.0, -fx_footprint_local.y * RuntimeLayout.ROOM_RECT.size.y * 0.58)


func _placeholder_color() -> Color:
	match visual_state:
		&"opening":
			return Color(1.0, 0.75, 0.22, 1.0)
		&"opened":
			return Color(0.42, 0.31, 0.18, 0.82)
	return Color(0.72, 0.43, 0.18, 1.0) if not focused else Color(1.0, 0.84, 0.32, 1.0)
