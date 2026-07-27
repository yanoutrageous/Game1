extends RefCounted
class_name WorldObjectPresentationDescriptor

const RuntimeLayout := preload("res://scripts/gameplay/runtime/g41_runtime_layout.gd")

# A single geometry contract shared by projection, rendering, collision,
# proximity and context placement. Values remain normalized to the room plate;
# viewport helpers apply the project's canvas_items + keep stretch policy.
const CONTRACT_ID := &"i3r.world_object_presentation.v1"
const REFERENCE_VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const MIN_LOCAL_SIZE := Vector2(0.001, 0.001)


static func build(values: Dictionary) -> Dictionary:
	var local_pos := Vector2(values.get("local_pos", Vector2(0.5, 0.5)))
	var ground_anchor := Vector2(values.get("ground_anchor_local", local_pos))
	var pivot := _clamped_pivot(Vector2(values.get("pivot_normalized", Vector2(0.5, 0.5))))
	var body_rect := Rect2(values.get("body_rect", Rect2(local_pos - Vector2(0.02, 0.02), Vector2(0.04, 0.04))))
	var display_size := _positive_size(Vector2(values.get("display_size_local", body_rect.size)))
	var visual_rect := Rect2(ground_anchor - display_size * pivot, display_size)
	var texture_region := _normalized_region(Rect2(values.get(
		"texture_region_normalized",
		Rect2(Vector2.ZERO, Vector2.ONE)
	)))
	var context_anchor := Vector2(values.get(
		"context_anchor_local",
		Vector2(visual_rect.get_center().x, visual_rect.position.y)
	))
	return {
		"presentation_contract": CONTRACT_ID,
		"projection_id": String(values.get("projection_id", "")),
		"interaction_kind": StringName(values.get("interaction_kind", &"unknown")),
		"local_pos": local_pos,
		"ground_anchor_local": ground_anchor,
		"pivot_normalized": pivot,
		"display_size_local": display_size,
		"visual_rect_local": visual_rect,
		"texture_region_normalized": texture_region,
		"interaction_radius": maxf(0.0, float(values.get("interaction_radius", 0.0))),
		"body_rect": body_rect,
		"context_anchor_local": context_anchor,
		"visual_state": StringName(values.get("visual_state", &"idle")),
		"visual_key": StringName(values.get("visual_key", &"runtime.missing")),
		"orientation": StringName(values.get("orientation", &"none")),
		"depth_key": StringName(values.get("depth_key", &"world.default")),
		"enabled": bool(values.get("enabled", false)),
		"prompt_text": String(values.get("prompt_text", "")),
		"payload": (values.get("payload", {}) as Dictionary).duplicate(true),
	}


static func reference_visual_rect(descriptor: Dictionary) -> Rect2:
	return _reference_rect(Rect2(descriptor.get("visual_rect_local", Rect2())))


static func reference_body_rect(descriptor: Dictionary) -> Rect2:
	return _reference_rect(Rect2(descriptor.get("body_rect", Rect2())))


static func reference_ground_anchor(descriptor: Dictionary) -> Vector2:
	return RuntimeLayout.local_to_world(Vector2(descriptor.get(
		"ground_anchor_local",
		descriptor.get("local_pos", Vector2.ZERO)
	)))


static func visual_rect_for_viewport(descriptor: Dictionary, viewport_size: Vector2) -> Rect2:
	return _reference_rect_to_viewport(reference_visual_rect(descriptor), viewport_size)


static func body_rect_for_viewport(descriptor: Dictionary, viewport_size: Vector2) -> Rect2:
	return _reference_rect_to_viewport(reference_body_rect(descriptor), viewport_size)


static func ground_anchor_for_viewport(descriptor: Dictionary, viewport_size: Vector2) -> Vector2:
	var transform := _viewport_transform(viewport_size)
	return Vector2(transform["offset"]) + reference_ground_anchor(descriptor) * float(transform["scale"])


static func _reference_rect(local_rect: Rect2) -> Rect2:
	return Rect2(
		RuntimeLayout.local_to_world(local_rect.position),
		RuntimeLayout.local_size_to_world(local_rect.size)
	)


static func _reference_rect_to_viewport(reference_rect: Rect2, viewport_size: Vector2) -> Rect2:
	var transform := _viewport_transform(viewport_size)
	var scale := float(transform["scale"])
	return Rect2(Vector2(transform["offset"]) + reference_rect.position * scale, reference_rect.size * scale)


static func _viewport_transform(viewport_size: Vector2) -> Dictionary:
	var safe_size := Vector2(maxf(1.0, viewport_size.x), maxf(1.0, viewport_size.y))
	var scale := minf(
		safe_size.x / REFERENCE_VIEWPORT_SIZE.x,
		safe_size.y / REFERENCE_VIEWPORT_SIZE.y
	)
	return {
		"scale": scale,
		"offset": (safe_size - REFERENCE_VIEWPORT_SIZE * scale) * 0.5,
	}


static func _positive_size(value: Vector2) -> Vector2:
	return Vector2(maxf(MIN_LOCAL_SIZE.x, value.x), maxf(MIN_LOCAL_SIZE.y, value.y))


static func _clamped_pivot(value: Vector2) -> Vector2:
	return Vector2(clampf(value.x, 0.0, 1.0), clampf(value.y, 0.0, 1.0))


static func _normalized_region(value: Rect2) -> Rect2:
	var region_start := Vector2(
		clampf(value.position.x, 0.0, 1.0),
		clampf(value.position.y, 0.0, 1.0)
	)
	var requested_end := value.position + _positive_size(value.size)
	var region_end := Vector2(
		clampf(requested_end.x, region_start.x + MIN_LOCAL_SIZE.x, 1.0),
		clampf(requested_end.y, region_start.y + MIN_LOCAL_SIZE.y, 1.0)
	)
	return Rect2(region_start, region_end - region_start)
