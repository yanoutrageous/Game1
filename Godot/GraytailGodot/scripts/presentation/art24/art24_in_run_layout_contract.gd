extends RefCounted
class_name Art24InRunLayoutContract

const LOGICAL_SIZE := Vector2(1280, 720)

const LEFT_RAIL := Rect2(0, 0, 300, 648)
const GAMEPLAY := Rect2(300, 0, 980, 648)
const BOTTOM_BAR := Rect2(0, 648, 1280, 72)
const PROTOCOL := Rect2(1038, 18, 230, 118)

const MINIMAP := Rect2(24, 54, 252, 252)
const LEFT_STATUS := Rect2(24, 326, 252, 176)
const LEFT_SUMMARY := Rect2(24, 518, 252, 112)

const PLAYER_ANCHOR := Vector2(785, 380)
const MONSTER_ANCHOR := Vector2(930, 312)
const PRIMARY_PROP_ANCHOR := Vector2(962, 214)
const LOOT_ANCHORS := [Vector2(920, 476), Vector2(1028, 438), Vector2(1102, 516)]

const MAP_FRAME := Rect2(280, 36, 720, 600)
const MAP_GRID := Rect2(330, 116, 420, 420)
const MAP_LEGEND := Rect2(778, 124, 174, 394)

const GAMEPLAY_MODAL := Rect2(390, 70, 760, 560)
const MODAL_CONTENT := Rect2(424, 126, 692, 438)

const TOAST := Rect2(540, 574, 480, 52)
const RESULT_BANNER := Rect2(510, 108, 520, 120)

const PLAYER_SIZE := Vector2(146, 146)
const MONSTER_SIZE := Vector2(208, 160)
const WORLD_LOOT_SIZE := Vector2(78, 78)

const MINIMUM_SAFE_EDGE := 8.0


static func scaled_rect(rect: Rect2, viewport_size: Vector2) -> Rect2:
	var scale := Vector2(viewport_size.x / LOGICAL_SIZE.x, viewport_size.y / LOGICAL_SIZE.y)
	return Rect2(rect.position * scale, rect.size * scale)


static func modal_center_error(rect: Rect2) -> float:
	return rect.get_center().distance_to(GAMEPLAY.get_center())
