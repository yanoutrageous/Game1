extends RefCounted
class_name G41RuntimeLayout

# One production-space authority for player, obstacles, interactables and combat
# actors. Art may resize the room without making program-owned hit tests drift.
# Match the visible square room plate.  The room textures are centered around
# (640, 360) and rendered at 0.45, which places their 560 px presentation plate
# at roughly (360, 80).  Actors and hit tests therefore share the same plate.
const ROOM_RECT := Rect2(Vector2(360, 80), Vector2(560, 560))
const CONTEXT_FEEDBACK_RESERVE_HEIGHT := 60.0
# Context panels are UI, not colliders. Their live safe lane is calculated from
# the same visible rails/footer proportions used by the run surface; a fixed
# 1280x720 rectangle previously extended through the feedback and key frames.


static func context_ui_rect_for_viewport(viewport_size: Vector2) -> Rect2:
	var safe_size := Vector2(maxf(1.0, viewport_size.x), maxf(1.0, viewport_size.y))
	var is_low := safe_size.y <= 768.0
	var is_high := safe_size.y >= 1440.0
	var margin := 10.0 if is_low else 12.0
	var left_width := clampf(safe_size.x * 0.23, 292.0, 430.0)
	var key_height := 40.0 if is_low else (50.0 if is_high else 44.0)
	var mine_risk_height := 40.0 if is_low else (50.0 if is_high else 44.0)
	var key_top := safe_size.y - key_height - 8.0
	var mine_risk_top := key_top - mine_risk_height - 4.0
	var safe_left := left_width + margin
	# The protocol card occupies only the upper-right corner. Reserving its width
	# for the entire screen forced every contextual card back over the room.
	# The card itself is returned separately as a hard exclusion rectangle.
	var safe_right := safe_size.x - margin
	var safe_top := maxf(48.0, safe_size.y * 0.08)
	# A contextual card may remain visible while a blocked-action toast is
	# shown. Reserve the complete toast lane plus an eight-pixel breathing gap
	# instead of letting the two framed surfaces cover each other.
	var safe_bottom := mine_risk_top - CONTEXT_FEEDBACK_RESERVE_HEIGHT
	return Rect2(
		Vector2(safe_left, safe_top),
		Vector2(maxf(1.0, safe_right - safe_left), maxf(1.0, safe_bottom - safe_top))
	)


static func context_reserved_rects_for_viewport(viewport_size: Vector2) -> Array[Rect2]:
	var safe_size := Vector2(maxf(1.0, viewport_size.x), maxf(1.0, viewport_size.y))
	var is_low := safe_size.y <= 768.0
	var margin := 10.0 if is_low else 12.0
	var ue_reference_scale := clampf(minf(safe_size.x / 1920.0, safe_size.y / 1080.0), 0.60, 1.34)
	var card_width := clampf(204.0 * ue_reference_scale, 152.0 if is_low else 164.0, 274.0)
	var card_height := clampf(122.0 * ue_reference_scale, 104.0 if is_low else 112.0, 164.0)
	return [
		Rect2(
			Vector2(safe_size.x - card_width - margin, margin),
			Vector2(card_width, card_height)
		),
	]


static func local_to_world(local_pos: Vector2) -> Vector2:
	return ROOM_RECT.position + Vector2(local_pos.x * ROOM_RECT.size.x, local_pos.y * ROOM_RECT.size.y)


static func local_size_to_world(local_size: Vector2) -> Vector2:
	return Vector2(local_size.x * ROOM_RECT.size.x, local_size.y * ROOM_RECT.size.y)
