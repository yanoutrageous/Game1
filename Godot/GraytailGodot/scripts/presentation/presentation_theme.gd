extends RefCounted
class_name PresentationTheme

const COLOR_MAP := {
	&"ui.text": Color(0.86, 0.92, 0.88, 1.0),
	&"ui.muted": Color(0.56, 0.65, 0.63, 1.0),
	&"ui.panel": Color(0.03, 0.06, 0.07, 0.86),
	&"ui.accent": Color(0.58, 0.92, 0.80, 1.0),
	&"ui.warning": Color(0.95, 0.73, 0.32, 1.0),
	&"ui.danger": Color(0.92, 0.33, 0.26, 1.0),
	&"mini.hidden": Color(0.16, 0.19, 0.21, 1.0),
	&"mini.explored": Color(0.36, 0.48, 0.46, 1.0),
	&"mini.scanned": Color(0.30, 0.62, 0.74, 1.0),
	&"mini.flag": Color(0.94, 0.54, 0.34, 1.0),
	&"mini.player": Color(0.48, 0.93, 0.88, 1.0),
	&"mini.mine": Color(0.82, 0.22, 0.22, 1.0),
	&"mini.monster": Color(0.72, 0.26, 0.88, 1.0),
	&"mini.chest": Color(0.94, 0.72, 0.28, 1.0),
	&"mini.event": Color(0.36, 0.72, 0.96, 1.0),
	&"mini.exit": Color(0.48, 0.92, 0.42, 1.0),
	&"mini.normal": Color(0.54, 0.66, 0.62, 1.0),
}


static func color_for_key(theme_key: StringName, fallback: Color = Color.WHITE) -> Color:
	return COLOR_MAP.get(theme_key, fallback)


static func panel_color() -> Color:
	return COLOR_MAP[&"ui.panel"]


static func text_color() -> Color:
	return COLOR_MAP[&"ui.text"]


static func risk_key(adjacent_mines: int, room_type: StringName) -> StringName:
	if room_type == &"Mine":
		return &"ui.danger"
	if adjacent_mines >= 3:
		return &"ui.danger"
	if adjacent_mines >= 1:
		return &"ui.warning"
	return &"ui.accent"
