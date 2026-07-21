extends RefCounted
class_name Art24RuntimeAnimationCatalog

const PLAYER_ROOT := "res://assets/art24/actors/player/"
const PLAYER_FACINGS: Array[StringName] = [&"down", &"left", &"right", &"up"]
const PLAYER_MOTIONS := {
	&"idle": [&"idle_a", &"idle_b"],
	&"move": [&"walk_a", &"walk_b"],
	&"attack_windup": [&"attack_windup"],
	&"attack_active": [&"attack_swing", &"attack_impact"],
	&"attack_recovery": [&"attack_recover"],
	&"hurt": [&"hit"],
	&"dead": [&"hit"],
}


static func player_texture_path(
	facing: StringName,
	runtime_state: StringName,
	frame_index: int,
	reduced_motion: bool,
	walking_override: bool = false
) -> String:
	var motion := player_motion(runtime_state, frame_index, reduced_motion, walking_override)
	return "%s%s_%s.png" % [PLAYER_ROOT, String(facing), String(motion)]


static func player_motion(
	runtime_state: StringName,
	frame_index: int,
	reduced_motion: bool,
	walking_override: bool = false
) -> StringName:
	var effective_state := _effective_player_state(runtime_state, walking_override)
	if reduced_motion:
		match effective_state:
			&"move": return &"walk_a"
			&"attack_active": return &"attack_impact"
	var frames: Array = PLAYER_MOTIONS.get(effective_state, PLAYER_MOTIONS[&"idle"])
	if frames.is_empty():
		return &"idle_a"
	var bounded_index := clampi(frame_index, 0, frames.size() - 1)
	if player_loops(effective_state):
		bounded_index = posmod(frame_index, frames.size())
	return StringName(frames[bounded_index])


static func player_frame_count(runtime_state: StringName, walking_override: bool = false) -> int:
	var effective_state := _effective_player_state(runtime_state, walking_override)
	return (PLAYER_MOTIONS.get(effective_state, PLAYER_MOTIONS[&"idle"]) as Array).size()


static func player_frame_duration(runtime_state: StringName, walking_override: bool = false) -> float:
	match _effective_player_state(runtime_state, walking_override):
		&"move": return 0.10
		&"attack_active": return 0.06
		&"attack_windup": return 0.08
		&"attack_recovery": return 0.16
		&"hurt": return 0.12
	return 0.14


static func player_loops(runtime_state: StringName) -> bool:
	return runtime_state in [&"idle", &"move"]


static func minimum_visible_seconds(runtime_state: StringName) -> float:
	return 0.12 if runtime_state == &"hurt" else 0.0


static func production_texture_paths() -> Array[String]:
	var unique_motions: Dictionary = {}
	for raw_frames in PLAYER_MOTIONS.values():
		for raw_motion in raw_frames as Array:
			unique_motions[StringName(raw_motion)] = true
	var result: Array[String] = []
	for facing in PLAYER_FACINGS:
		for raw_motion in unique_motions.keys():
			result.append("%s%s_%s.png" % [PLAYER_ROOT, String(facing), String(raw_motion)])
	result.sort()
	return result


static func _effective_player_state(runtime_state: StringName, walking_override: bool) -> StringName:
	if walking_override and runtime_state == &"idle":
		return &"move"
	return runtime_state if PLAYER_MOTIONS.has(runtime_state) else &"idle"
