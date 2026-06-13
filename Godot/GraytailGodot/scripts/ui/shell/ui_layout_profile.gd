extends RefCounted
class_name UILayoutProfile

const PROFILE_DESKTOP := &"desktop"
const PROFILE_NARROW := &"narrow"
const RESOLUTION_1280 := &"1280x720"
const RESOLUTION_1366 := &"1366x768"
const RESOLUTION_1600 := &"1600x900"
const RESOLUTION_1920 := &"1920x1080"
const RESOLUTION_2560 := &"2560x1440"
const SUPPORTED_RESOLUTION_SIZES := {
	RESOLUTION_1280: Vector2i(1280, 720),
	RESOLUTION_1366: Vector2i(1366, 768),
	RESOLUTION_1600: Vector2i(1600, 900),
	RESOLUTION_1920: Vector2i(1920, 1080),
	RESOLUTION_2560: Vector2i(2560, 1440),
}

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
	"resolution_id",
	"supported_size",
	"ui_scale",
	"density_mode",
	"is_low_resolution",
	"is_high_resolution",
]


static func desktop_profile() -> Dictionary:
	return profile_for_resolution(RESOLUTION_1280)


static func profile_for_resolution(resolution_id: StringName) -> Dictionary:
	var supported_size: Vector2i = SUPPORTED_RESOLUTION_SIZES.get(resolution_id, Vector2i(1280, 720))
	var is_low := supported_size.y <= 768
	var is_high := supported_size.y >= 1440
	var density_mode := &"compact" if is_low else (&"spacious" if is_high else &"standard")
	var ui_scale := 0.94 if supported_size == Vector2i(1280, 720) else (0.97 if supported_size == Vector2i(1366, 768) else (1.12 if is_high else 1.0))
	return {
		"profile_id": PROFILE_DESKTOP,
		"schema_version": 1,
		"min_width": supported_size.x,
		"max_width": supported_size.x,
		"compact_mode": is_low,
		"safe_area": Rect2(Vector2.ZERO, Vector2(supported_size.x, supported_size.y)),
		"min_button_size": Vector2(104, 34) if is_low else (Vector2(124, 40) if is_high else Vector2(110, 36)),
		"panel_stack_policy": &"side_rails",
		"summary_mode": &"standard",
		"touch_ready": false,
		"deprecated_state": &"active",
		"resolution_id": resolution_id,
		"supported_size": supported_size,
		"ui_scale": ui_scale,
		"density_mode": density_mode,
		"is_low_resolution": is_low,
		"is_high_resolution": is_high,
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
		"resolution_id": &"unsupported_narrow",
		"supported_size": Vector2i(720, 720),
		"ui_scale": 0.9,
		"density_mode": &"compact",
		"is_low_resolution": true,
		"is_high_resolution": false,
	}


static func profile_for_size(viewport_size: Vector2) -> Dictionary:
	if viewport_size.x < 960.0:
		return narrow_profile()
	return profile_for_resolution(resolution_id_for_size(Vector2i(int(viewport_size.x), int(viewport_size.y))))


static func resolution_id_for_size(size: Vector2i) -> StringName:
	var best_id := RESOLUTION_1280
	for resolution_id in [RESOLUTION_1280, RESOLUTION_1366, RESOLUTION_1600, RESOLUTION_1920, RESOLUTION_2560]:
		var candidate_size: Vector2i = SUPPORTED_RESOLUTION_SIZES[resolution_id]
		if candidate_size.x <= size.x and candidate_size.y <= size.y:
			best_id = resolution_id
	return best_id
