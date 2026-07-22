extends RefCounted
class_name Art24RuntimeAnimationCatalog

const PLAYER_ROOT := "res://assets/art24/actors/player/"
const PLAYER_FACINGS: Array[StringName] = [&"down", &"left", &"right", &"up"]
const PLAYER_MOVE_PHASES: Array[StringName] = [&"walk_a", &"idle_a", &"walk_b", &"idle_b"]
const PLAYER_MOVE_BOB_AMPLITUDE := 1.8
const PLAYER_MOTIONS := {
	&"idle": [&"idle_a", &"idle_b"],
	&"move": PLAYER_MOVE_PHASES,
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
		# Four registered poses retain the original 0.20-second stride cycle.
		&"move": return 0.05
		&"attack_active": return 0.06
		&"attack_windup": return 0.08
		&"attack_recovery": return 0.16
		&"hurt": return 0.12
	return 0.14


static func player_uses_walk_cycle(runtime_state: StringName, walking_override: bool = false) -> bool:
	return _effective_player_state(runtime_state, walking_override) == &"move"


static func player_walk_bob_offset(animation_seconds: float, reduced_motion: bool) -> float:
	if reduced_motion:
		return 0.0
	var cycle_seconds := player_frame_duration(&"move") * float(PLAYER_MOVE_PHASES.size())
	if cycle_seconds <= 0.0:
		return 0.0
	var cycle_phase := fposmod(maxf(0.0, animation_seconds), cycle_seconds) / cycle_seconds
	# walk_a/walk_b are the two contact poses. The registered idle poses act as
	# passing poses, so both texture selection and lift share this exact phase.
	return -absf(sin(cycle_phase * TAU)) * PLAYER_MOVE_BOB_AMPLITUDE


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
