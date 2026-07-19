extends RefCounted
class_name G41RuntimeLayout

# One production-space authority for player, obstacles, interactables and combat
# actors. Art may resize the room without making program-owned hit tests drift.
const ROOM_RECT := Rect2(Vector2(420, 170), Vector2(440, 410))


static func local_to_world(local_pos: Vector2) -> Vector2:
	return ROOM_RECT.position + Vector2(local_pos.x * ROOM_RECT.size.x, local_pos.y * ROOM_RECT.size.y)


static func local_size_to_world(local_size: Vector2) -> Vector2:
	return Vector2(local_size.x * ROOM_RECT.size.x, local_size.y * ROOM_RECT.size.y)
