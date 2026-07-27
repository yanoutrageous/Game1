extends RefCounted
class_name Art24MapOverlayLayout


static func calculate(profile: Dictionary, grid_size: Vector2i = Vector2i(10, 10)) -> Dictionary:
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var ui_scale_factor := clampf(float(profile.get("ui_scale_factor", 1.0)), 1.0, 1.5)
	var supported_size: Variant = profile.get("supported_size", Vector2i(1280, 720))
	var fallback_size := Vector2i(1280, 720)
	if supported_size is Vector2i:
		fallback_size = supported_size
	elif supported_size is Vector2:
		fallback_size = Vector2i(int(supported_size.x), int(supported_size.y))
	var actual_size: Vector2i = profile.get("actual_viewport_size", fallback_size)
	var width := float(maxi(1, actual_size.x))
	var height := float(maxi(1, actual_size.y))
	var columns := maxi(1, grid_size.x)
	var rows := maxi(1, grid_size.y)
	var top_reserve := 12.0 if is_low else 18.0
	var bottom_reserve := 12.0 if is_low else 18.0
	var safe_panel_height := maxf(360.0, height - top_reserve - bottom_reserve)
	var available_width := maxf(320.0, width - 48.0)
	var content_gap := roundf((2.0 if is_low else 4.0) * ui_scale_factor)
	var grid_gap := 2.0 if is_low else 3.0
	# The expanded scan follows the UE hierarchy: title, dominant grid, compact
	# selection summary, explicit action, and one close-hint line.  The host is
	# transparent and tightly wraps those controls instead of imitating a
	# near-fullscreen inventory dialog.
	var title_height := roundf((30.0 if is_low else (40.0 if is_high else 36.0)) * ui_scale_factor)
	var detail_height := roundf((32.0 if is_low else (40.0 if is_high else 36.0)) * ui_scale_factor)
	# The shared pixel primary button has a real 50 px combined minimum after
	# its texture-safe content margins are applied.
	var action_height := roundf(50.0 * ui_scale_factor)
	var footer_height := roundf((24.0 if is_low else 28.0) * ui_scale_factor)
	var grid_layout_reserve := roundf(4.0 * ui_scale_factor)
	var non_grid_height := title_height + detail_height + action_height + footer_height + content_gap * 4.0 + grid_layout_reserve
	var grid_separation_width := grid_gap * float(maxi(0, columns - 1))
	var grid_separation_height := grid_gap * float(maxi(0, rows - 1))
	var cell_width := floorf((available_width - grid_separation_width) / float(columns))
	var cell_height := floorf((safe_panel_height - non_grid_height - grid_separation_height) / float(rows))
	var max_cell_size := 112.0 if is_low else (144.0 if is_high else 120.0)
	var marker_size := clampf(minf(cell_width, cell_height), 28.0, max_cell_size)
	var grid_width := marker_size * float(columns) + grid_separation_width
	var grid_height := marker_size * float(rows) + grid_separation_height
	var minimum_text_width := minf(roundf(620.0 * ui_scale_factor), available_width)
	var panel_width := minf(available_width, maxf(minimum_text_width, grid_width))
	var panel_height := minf(safe_panel_height, non_grid_height + grid_height)
	var panel_y := top_reserve + maxf(0.0, (safe_panel_height - panel_height) * 0.5)
	var fixed_vertical := non_grid_height + grid_separation_height
	return {
		"panel_rect": Rect2((width - panel_width) * 0.5, panel_y, panel_width, panel_height),
		"ui_scale_factor": ui_scale_factor,
		"marker_size": marker_size,
		"grid_width": grid_width,
		"grid_height": grid_height,
		"text_width": minimum_text_width,
		"grid_columns": columns,
		"grid_rows": rows,
		"content_gap": content_gap,
		"grid_gap": grid_gap,
		"title_height": title_height,
		"detail_height": detail_height,
		"action_height": action_height,
		"footer_height": footer_height,
		"top_reserve": top_reserve,
		"bottom_reserve": bottom_reserve,
		"frame_content_left": 0.0,
		"frame_content_top": 0.0,
		"frame_content_right": 0.0,
		"frame_content_bottom": 0.0,
		"frame_vertical_padding": 0.0,
		"grid_layout_reserve": grid_layout_reserve,
		"non_grid_height": non_grid_height,
		"fixed_vertical": fixed_vertical,
	}
