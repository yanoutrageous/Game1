extends RefCounted
class_name RuntimeModalLayoutModel

const SAFE_MARGIN := 24.0


static func build(profile: Dictionary) -> Dictionary:
	var supported_size: Vector2 = profile.get("supported_size", Vector2(1366, 768))
	var actual_size: Vector2i = profile.get(
		"actual_viewport_size",
		Vector2i(int(supported_size.x), int(supported_size.y))
	)
	var width := float(maxi(1, actual_size.x))
	var height := float(maxi(1, actual_size.y))
	var left_width := clampf(width * 0.29, 360.0, 420.0)
	var right_width := clampf(width * 0.20, 268.0, 330.0)
	var modal_width := minf(
		maxf(300.0, right_width - 16.0),
		maxf(260.0, width - left_width - SAFE_MARGIN * 3.0)
	)
	var modal_left := width - modal_width - SAFE_MARGIN
	var modal_top := SAFE_MARGIN + 80.0
	var available_height := maxf(220.0, height - modal_top - SAFE_MARGIN)
	var debug_width := clampf(width * 0.24, 300.0, 380.0)
	var debug_top := SAFE_MARGIN + 70.0
	var debug_height := maxf(380.0, height - debug_top - SAFE_MARGIN)
	return {
		"event": Rect2(modal_left, modal_top, modal_width, minf(360.0, available_height)),
		"extract": _centered_rect(
			width,
			height,
			Vector2(clampf(width * 0.44, 480.0, 620.0), clampf(height * 0.42, 300.0, minf(380.0, available_height)))
		),
		"pause": _centered_rect(
			width,
			height,
			Vector2(clampf(width * 0.38, 440.0, 560.0), clampf(height * 0.56, 390.0, 500.0))
		),
		"settings": _centered_rect(
			width,
			height,
			Vector2(clampf(width * 0.56, 600.0, 780.0), clampf(height * 0.76, 510.0, 670.0))
		),
		"abandon": _centered_rect(
			width,
			height,
			Vector2(clampf(width * 0.42, 480.0, 560.0), clampf(height * 0.34, 230.0, 290.0))
		),
		"debug": Rect2(width - debug_width - SAFE_MARGIN, debug_top, debug_width, debug_height),
		"debug_scroll_minimum": Vector2(debug_width - 32.0, maxf(240.0, debug_height - 170.0)),
		"viewport": Rect2(Vector2.ZERO, Vector2(width, height)),
		"safe_margin": SAFE_MARGIN,
		"read_only": true,
	}


static func _centered_rect(width: float, height: float, requested_size: Vector2) -> Rect2:
	var safe_size := Vector2(
		minf(requested_size.x, maxf(260.0, width - SAFE_MARGIN * 2.0)),
		minf(requested_size.y, maxf(220.0, height - SAFE_MARGIN * 2.0))
	)
	return Rect2(Vector2((width - safe_size.x) * 0.5, (height - safe_size.y) * 0.5), safe_size)
