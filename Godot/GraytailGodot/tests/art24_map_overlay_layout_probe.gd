extends SceneTree

const MapOverlayLayoutScript := preload("res://scripts/presentation/art24/art24_map_overlay_layout.gd")
const UILayoutProfileScript := preload("res://scripts/ui/shell/ui_layout_profile.gd")

const RESOLUTIONS := [
	&"1280x720",
	&"1366x768",
	&"1600x900",
	&"1920x1080",
	&"2560x1440",
]


func _initialize() -> void:
	var failures: Array[String] = []
	for resolution_id: StringName in RESOLUTIONS:
		var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
		var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
		profile["actual_viewport_size"] = viewport_size
		var metrics: Dictionary = MapOverlayLayoutScript.calculate(profile)
		var panel_rect: Rect2 = metrics.get("panel_rect", Rect2())
		var marker_size := float(metrics.get("marker_size", 0.0))
		var grid_gap := float(metrics.get("grid_gap", 0.0))
		var fixed_vertical := float(metrics.get("fixed_vertical", 0.0))
		var bottom_reserve := float(metrics.get("bottom_reserve", 0.0))
		if panel_rect.position.y < float(metrics.get("top_reserve", 0.0)) - 0.5:
			failures.append("%s panel_top=%s" % [resolution_id, panel_rect.position.y])
		if panel_rect.end.y > float(viewport_size.y) - bottom_reserve + 0.5:
			failures.append("%s panel_bottom=%s safe_bottom=%s" % [resolution_id, panel_rect.end.y, float(viewport_size.y) - bottom_reserve])
		var occupied_height := fixed_vertical + marker_size * 10.0
		if occupied_height > panel_rect.size.y + 0.5:
			failures.append("%s occupied=%s panel_height=%s" % [resolution_id, occupied_height, panel_rect.size.y])
		var occupied_width := 32.0 + marker_size * 10.0 + grid_gap * 9.0
		if occupied_width > panel_rect.size.x + 0.5:
			failures.append("%s grid_width=%s panel_width=%s" % [resolution_id, occupied_width, panel_rect.size.x])
		if marker_size < 40.0:
			failures.append("%s marker_too_small=%s" % [resolution_id, marker_size])
	if failures.is_empty():
		print("ART24_MAP_OVERLAY_LAYOUT=PASS resolutions=5 cells=100 safe_bottom=reserved")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ART24_MAP_OVERLAY_LAYOUT=FAIL failures=%d" % failures.size())
		quit(2)
