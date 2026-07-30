extends RefCounted
class_name RuntimeModalLayoutModel

const UILayerContractScript := preload("res://scripts/ui/shell/ui_layer_contract.gd")

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
	# The diagnostic rail must remain a docked inspection surface, not a second
	# full-height HUD.  The upper reserve clears the protocol card and the lower
	# reserve keeps the production action dock fully usable.
	var debug_width := clampf(width * 0.24, 260.0, 360.0)
	var status_size := UILayerContractScript.run_status_card_size(profile)
	var status_margin := 10.0 if bool(profile.get("is_low_resolution", false)) else 12.0
	var protocol_bottom := status_margin + status_size.y
	var debug_top := maxf(height * 0.15, protocol_bottom + 12.0)
	debug_top = clampf(debug_top, SAFE_MARGIN + 84.0, maxf(SAFE_MARGIN + 84.0, height - 300.0))
	var footer := UILayerContractScript.run_footer_geometry(profile)
	var debug_bottom_limit := float(footer.get("key_top", height - 72.0)) - 12.0
	var debug_height := clampf(height * 0.70, 340.0, 560.0)
	debug_height = minf(debug_height, maxf(260.0, debug_bottom_limit - debug_top))
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
		# This is a usability floor, not a requested panel height. The scroll
		# expands into all remaining rail space; keeping the minimum independent
		# of the rail height lets enlarged header/status text consume its needed
		# space without pushing the rail through the production action dock.
		"debug_scroll_minimum": Vector2(debug_width - 32.0, 96.0),
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
