extends RefCounted
class_name Art24MapOverlayLayout


static func calculate(profile: Dictionary) -> Dictionary:
	var is_low := bool(profile.get("is_low_resolution", false))
	var is_high := bool(profile.get("is_high_resolution", false))
	var supported_size: Variant = profile.get("supported_size", Vector2i(1280, 720))
	var fallback_size := Vector2i(1280, 720)
	if supported_size is Vector2i:
		fallback_size = supported_size
	elif supported_size is Vector2:
		fallback_size = Vector2i(int(supported_size.x), int(supported_size.y))
	var actual_size: Vector2i = profile.get("actual_viewport_size", fallback_size)
	var width := float(maxi(1, actual_size.x))
	var height := float(maxi(1, actual_size.y))
	# UE uses a fullscreen dimmer and gives the scan grid the fill region.  The
	# Godot panel is therefore only a transparent layout host, not a dialog.
	var panel_width := minf(width - 48.0, 1180.0 if is_high else 1100.0)
	var top_reserve := 12.0 if is_low else 18.0
	var bottom_reserve := 12.0 if is_low else 18.0
	var safe_panel_height := maxf(360.0, height - top_reserve - bottom_reserve)
	var panel_height := safe_panel_height
	panel_width = maxf(panel_width, 760.0 if is_low else 860.0)
	var content_gap := 2.0 if is_low else 4.0
	var grid_gap := 2.0 if is_low else 3.0
	var label_padding := 3.0 if is_low else 5.0
	# UE lets the grid consume the fill region. The former 56 px detail band and
	# 40 px footer turned selection feedback into two competing toolbars.
	var title_height := 30.0 if is_low else 36.0
	# UE keeps selection/action feedback below the fill grid; it does not reserve
	# a second toolbar above it.  Keep the legacy Detail node collapsed so older
	# scene references remain compatible while the grid reclaims the space.
	var detail_height := 0.0
	# Standard/high profiles need two readable lines when feedback is appended.
	# Reserving the real minimum prevents the VBox from expanding past the
	# fullscreen safe area after a cell action.
	# Selection feedback appends a second footer line at every resolution.  Its
	# real low-resolution minimum is 42 px, so budget that value up front rather
	# than letting VBoxContainer enlarge the panel outside the safe area.
	var footer_height := 42.0 if is_low else 48.0
	var frame_vertical_padding := 12.0 if is_low else 18.0
	var frame_horizontal_padding := 32.0
	var fixed_vertical := frame_vertical_padding + title_height + detail_height + footer_height + content_gap * 3.0 + grid_gap * 9.0
	var cell_width := floorf((panel_width - frame_horizontal_padding - grid_gap * 9.0) / 10.0)
	var cell_height := floorf((panel_height - fixed_vertical) / 10.0)
	var max_cell_size := 56.0 if is_low else (88.0 if is_high else 84.0)
	var marker_size := clampf(minf(cell_width, cell_height), 40.0, max_cell_size)
	var panel_y := top_reserve + maxf(0.0, (safe_panel_height - panel_height) * 0.5)
	return {
		"panel_rect": Rect2((width - panel_width) * 0.5, panel_y, panel_width, panel_height),
		"marker_size": marker_size,
		"content_gap": content_gap,
		"grid_gap": grid_gap,
		"title_height": title_height,
		"detail_height": detail_height,
		"footer_height": footer_height,
		"label_padding": label_padding,
		"top_reserve": top_reserve,
		"bottom_reserve": bottom_reserve,
		"frame_vertical_padding": frame_vertical_padding,
		"fixed_vertical": fixed_vertical,
	}
