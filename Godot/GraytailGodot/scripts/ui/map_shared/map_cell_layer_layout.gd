extends RefCounted
class_name MapCellLayerLayout

const BASE_Z := 0
const SEMANTIC_Z := 20
const COUNT_Z := 30
const FOCUS_Z := 40
const CELL_SAFE_INSET := 2.0
const SEMANTIC_BADGE_GAP := 2.0


static func calculate(cell_size: Vector2, has_count_badge: bool) -> Dictionary:
	var safe_size := Vector2(
		maxf(1.0, cell_size.x - CELL_SAFE_INSET * 2.0),
		maxf(1.0, cell_size.y - CELL_SAFE_INSET * 2.0)
	)
	var safe_rect := Rect2(Vector2.ONE * CELL_SAFE_INSET, safe_size)
	var short_edge := minf(cell_size.x, cell_size.y)
	var semantic_rect: Rect2
	var count_rect := Rect2()
	if has_count_badge:
		var badge_side := clampf(roundf(short_edge * 0.30), 12.0, 18.0)
		badge_side = minf(badge_side, maxf(1.0, minf(safe_rect.size.x, safe_rect.size.y)))
		count_rect = Rect2(
			safe_rect.end - Vector2.ONE * badge_side,
			Vector2.ONE * badge_side
		)
		var available_size := Vector2(
			maxf(1.0, count_rect.position.x - SEMANTIC_BADGE_GAP - safe_rect.position.x),
			maxf(1.0, count_rect.position.y - SEMANTIC_BADGE_GAP - safe_rect.position.y)
		)
		var semantic_side := maxf(1.0, minf(available_size.x, available_size.y))
		semantic_rect = Rect2(
			safe_rect.position + (available_size - Vector2.ONE * semantic_side) * 0.5,
			Vector2.ONE * semantic_side
		)
	else:
		var semantic_inset := maxf(3.0, roundf(short_edge * 0.10))
		semantic_rect = Rect2(
			safe_rect.position + Vector2.ONE * semantic_inset,
			Vector2(
				maxf(1.0, safe_rect.size.x - semantic_inset * 2.0),
				maxf(1.0, safe_rect.size.y - semantic_inset * 2.0)
			)
		)
	return {
		"cell_rect": Rect2(Vector2.ZERO, cell_size),
		"safe_rect": safe_rect,
		"base_rect": safe_rect,
		"semantic_rect": semantic_rect,
		"count_rect": count_rect,
		"focus_rect": Rect2(Vector2.ONE, Vector2(maxf(1.0, cell_size.x - 2.0), maxf(1.0, cell_size.y - 2.0))),
		"base_z": BASE_Z,
		"semantic_z": SEMANTIC_Z,
		"count_z": COUNT_Z,
		"focus_z": FOCUS_Z,
	}


static func apply_rect(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
