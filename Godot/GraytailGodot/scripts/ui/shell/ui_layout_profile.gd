extends RefCounted
class_name UILayoutProfile

const PROFILE_DESKTOP := &"desktop"
const PROFILE_NARROW := &"narrow"

const REQUIRED_FIELDS := [
	"profile_id",
	"schema_version",
	"min_width",
	"max_width",
	"compact_mode",
	"safe_area",
	"min_button_size",
	"panel_stack_policy",
	"summary_mode",
	"touch_ready",
	"deprecated_state",
]


static func desktop_profile() -> Dictionary:
	return {
		"profile_id": PROFILE_DESKTOP,
		"schema_version": 1,
		"min_width": 960,
		"max_width": 9999,
		"compact_mode": false,
		"safe_area": Rect2(0, 0, 1280, 720),
		"min_button_size": Vector2(96, 36),
		"panel_stack_policy": &"side_rails",
		"summary_mode": &"standard",
		"touch_ready": false,
		"deprecated_state": &"active",
	}


static func narrow_profile() -> Dictionary:
	return {
		"profile_id": PROFILE_NARROW,
		"schema_version": 1,
		"min_width": 0,
		"max_width": 959,
		"compact_mode": true,
		"safe_area": Rect2(0, 0, 720, 720),
		"min_button_size": Vector2(104, 42),
		"panel_stack_policy": &"single_column_overlay",
		"summary_mode": &"compact",
		"touch_ready": false,
		"deprecated_state": &"active",
	}


static func profile_for_size(viewport_size: Vector2) -> Dictionary:
	if viewport_size.x < 960.0:
		return narrow_profile()
	return desktop_profile()
