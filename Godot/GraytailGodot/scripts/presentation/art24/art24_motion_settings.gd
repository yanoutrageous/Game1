extends RefCounted
class_name Art24MotionSettings


static func reduce_motion_enabled() -> bool:
	if ProjectSettings.has_setting("accessibility/reduce_motion"):
		return bool(ProjectSettings.get_setting("accessibility/reduce_motion"))
	if ProjectSettings.has_setting("display/window/reduce_motion"):
		return bool(ProjectSettings.get_setting("display/window/reduce_motion"))
	return false
