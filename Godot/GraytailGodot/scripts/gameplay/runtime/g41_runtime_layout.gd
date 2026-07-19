extends RefCounted
class_name G41RuntimeLayout

# One production-space authority for player, obstacles, interactables and combat
# actors. Art may resize the room without making program-owned hit tests drift.
# Match the visible square room plate.  The room textures are centered around
# (640, 360) and rendered at 0.45, which places their 560 px presentation plate
# at roughly (360, 80).  Actors and hit tests therefore share the same plate.
const ROOM_RECT := Rect2(Vector2(360, 80), Vector2(560, 560))
# Context panels are UI, not colliders. Keep them inside the canonical 1280x720
# gameplay lane: clear of the left scanner, the right protocol card and the
# bottom action bar. Godot's canvas stretch projects this reference rect at the
# other supported resolutions.
const CONTEXT_UI_RECT := Rect2(Vector2(304, 72), Vector2(820, 560))


static func context_ui_rect_for_viewport(viewport_size: Vector2) -> Rect2:
	# CONTEXT_UI_RECT is the 1280x720 authoring contract.  Context cards live in
	# the unscaled UI overlay, so scale the safe lane with that overlay instead of
	# leaving higher-resolution layouts tied to the reference pixels.
	var safe_size := Vector2(maxf(1.0, viewport_size.x), maxf(1.0, viewport_size.y))
	var normalized_position := Vector2(
		CONTEXT_UI_RECT.position.x / 1280.0,
		CONTEXT_UI_RECT.position.y / 720.0
	)
	var normalized_size := Vector2(
		CONTEXT_UI_RECT.size.x / 1280.0,
		CONTEXT_UI_RECT.size.y / 720.0
	)
	return Rect2(safe_size * normalized_position, safe_size * normalized_size)


static func local_to_world(local_pos: Vector2) -> Vector2:
	return ROOM_RECT.position + Vector2(local_pos.x * ROOM_RECT.size.x, local_pos.y * ROOM_RECT.size.y)


static func local_size_to_world(local_size: Vector2) -> Vector2:
	return Vector2(local_size.x * ROOM_RECT.size.x, local_size.y * ROOM_RECT.size.y)
