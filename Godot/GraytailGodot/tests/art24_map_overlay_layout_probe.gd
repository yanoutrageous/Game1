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
const GRID_EDGES := [5, 7, 10, 13]
const UI_SCALE_RESOLUTIONS := [&"1280x720", &"1920x1080"]
const UI_SCALES := [1.0, 1.25, 1.5]
const MIN_MARKER_SIZE_BY_EDGE := {
	5: 100.0,
	7: 75.0,
	10: 52.0,
	13: 40.0,
}


func _initialize() -> void:
	var failures: Array[String] = []
	for resolution_id: StringName in RESOLUTIONS:
		var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
		var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
		profile["actual_viewport_size"] = viewport_size
		for grid_edge: int in GRID_EDGES:
			var metrics: Dictionary = MapOverlayLayoutScript.calculate(profile, Vector2i(grid_edge, grid_edge))
			var case_id := "%s-%dx%d" % [resolution_id, grid_edge, grid_edge]
			var panel_rect: Rect2 = metrics.get("panel_rect", Rect2())
			var marker_size := float(metrics.get("marker_size", 0.0))
			var grid_width := float(metrics.get("grid_width", 0.0))
			var grid_height := float(metrics.get("grid_height", 0.0))
			var fixed_vertical := float(metrics.get("fixed_vertical", 0.0))
			var bottom_reserve := float(metrics.get("bottom_reserve", 0.0))
			if panel_rect.position.y < float(metrics.get("top_reserve", 0.0)) - 0.5:
				failures.append("%s panel_top=%s" % [case_id, panel_rect.position.y])
			if panel_rect.end.y > float(viewport_size.y) - bottom_reserve + 0.5:
				failures.append("%s panel_bottom=%s safe_bottom=%s" % [case_id, panel_rect.end.y, float(viewport_size.y) - bottom_reserve])
			var occupied_height := fixed_vertical + marker_size * float(grid_edge)
			if occupied_height > panel_rect.size.y + 0.5:
				failures.append("%s occupied=%s panel_height=%s" % [case_id, occupied_height, panel_rect.size.y])
			if grid_width > panel_rect.size.x + 0.5:
				failures.append("%s grid_width=%s panel_width=%s" % [case_id, grid_width, panel_rect.size.x])
			if grid_height < panel_rect.size.y * 0.68:
				failures.append("%s grid_not_dominant=%s panel_height=%s" % [case_id, grid_height, panel_rect.size.y])
			if panel_rect.size.x > float(viewport_size.x) * 0.65:
				failures.append("%s panel_not_tight=%s viewport_width=%s" % [case_id, panel_rect.size.x, viewport_size.x])
			var outside_lane := minf(panel_rect.position.x, float(viewport_size.x) - panel_rect.end.x)
			if outside_lane < 100.0:
				failures.append("%s outside_click_lane=%s" % [case_id, outside_lane])
			var minimum_marker := float(MIN_MARKER_SIZE_BY_EDGE.get(grid_edge, 28.0))
			if marker_size < minimum_marker:
				failures.append("%s marker_too_small=%s expected_at_least=%s" % [case_id, marker_size, minimum_marker])
	_assert_ui_scale_structure(failures)
	if failures.is_empty():
		print("ART24_MAP_OVERLAY_LAYOUT=PASS resolutions=5 grids=5,7,10,13 ui_scale=1280,1920@100,125,150 host=tight_transparent grid=dominant outside_click=wide")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("ART24_MAP_OVERLAY_LAYOUT=FAIL failures=%d" % failures.size())
		quit(2)


func _assert_ui_scale_structure(failures: Array[String]) -> void:
	for resolution_id: StringName in UI_SCALE_RESOLUTIONS:
		var previous: Dictionary = {}
		for ui_scale: float in UI_SCALES:
			var profile: Dictionary = UILayoutProfileScript.profile_for_resolution(resolution_id)
			var viewport_size: Vector2i = profile.get("supported_size", Vector2i(1280, 720))
			profile["actual_viewport_size"] = viewport_size
			profile["ui_scale_factor"] = ui_scale
			var metrics: Dictionary = MapOverlayLayoutScript.calculate(profile, Vector2i(13, 13))
			var case_id := "%s-13x13-ui%d" % [resolution_id, int(round(ui_scale * 100.0))]
			var panel_rect: Rect2 = metrics.get("panel_rect", Rect2())
			if not is_equal_approx(float(metrics.get("ui_scale_factor", 0.0)), ui_scale):
				failures.append("%s scale_not_consumed=%s" % [case_id, metrics.get("ui_scale_factor", 0.0)])
			if float(metrics.get("marker_size", 0.0)) < 28.0:
				failures.append("%s marker_below_floor=%s" % [case_id, metrics.get("marker_size", 0.0)])
			if panel_rect.position.y < float(metrics.get("top_reserve", 0.0)) - 0.5:
				failures.append("%s panel_top=%s" % [case_id, panel_rect.position.y])
			if panel_rect.end.y > float(viewport_size.y) - float(metrics.get("bottom_reserve", 0.0)) + 0.5:
				failures.append("%s panel_bottom=%s" % [case_id, panel_rect.end.y])
			for key in ["title_height", "detail_height", "action_height", "footer_height", "text_width"]:
				var current_value := float(metrics.get(key, 0.0))
				if not previous.is_empty() and current_value + 0.5 < float(previous.get(key, 0.0)):
					failures.append("%s %s_not_monotonic=%s<%s" % [case_id, key, current_value, previous.get(key, 0.0)])
			previous = metrics
