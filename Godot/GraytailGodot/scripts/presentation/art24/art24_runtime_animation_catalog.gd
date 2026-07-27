extends RefCounted
class_name Art24RuntimeAnimationCatalog

const PLAYER_ROOT := "res://assets/art24/actors/player/"
const DEFAULT_PLAYER_APPEARANCE_ID := &"graytail"
const DEFAULT_PLAYER_ANIMATION_SET_ID := &"art24_graytail_runtime"
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
const PLAYER_FRAME_DURATIONS := {
	&"idle": 0.14,
	# Four authored phases at 10 fps produce a grounded 0.40 s walk cycle:
	# each foot contacts every 0.20 s instead of mechanically cutting at 0.10 s.
	&"move": 0.10,
	&"attack_active": 0.06,
	&"attack_windup": 0.08,
	&"attack_recovery": 0.16,
	&"hurt": 0.12,
	&"dead": 0.14,
}


static func default_player_animation_set() -> Dictionary:
	return {
		"id": DEFAULT_PLAYER_ANIMATION_SET_ID,
		"appearance_id": DEFAULT_PLAYER_APPEARANCE_ID,
		"root": PLAYER_ROOT,
		"facings": PLAYER_FACINGS.duplicate(),
		"motions": PLAYER_MOTIONS.duplicate(true),
		"frame_durations": PLAYER_FRAME_DURATIONS.duplicate(true),
		"loop_states": [&"idle", &"move"],
		"source_status": &"audited_runtime",
		"read_only": true,
	}


static func resolve_player_animation_set(requested_id: StringName, registered_sets: Dictionary = {}) -> Dictionary:
	var requested: Variant = registered_sets.get(requested_id, {})
	if requested is Dictionary and not (requested as Dictionary).is_empty():
		return _normalized_animation_set(requested_id, requested as Dictionary)
	var fallback := default_player_animation_set()
	fallback["requested_id"] = requested_id
	fallback["used_fallback"] = requested_id not in [&"", DEFAULT_PLAYER_ANIMATION_SET_ID]
	return fallback


static func player_texture_path(
	facing: StringName,
	runtime_state: StringName,
	frame_index: int,
	reduced_motion: bool,
	walking_override: bool = false,
	animation_set: Dictionary = {}
) -> String:
	var descriptor := _descriptor_or_default(animation_set)
	var motion := player_motion(runtime_state, frame_index, reduced_motion, walking_override, descriptor)
	var supported_facings: Array = descriptor.get("facings", PLAYER_FACINGS)
	var resolved_facing := facing if supported_facings.has(facing) else &"down"
	return "%s%s_%s.png" % [String(descriptor.get("root", PLAYER_ROOT)), String(resolved_facing), String(motion)]


static func player_motion(
	runtime_state: StringName,
	frame_index: int,
	reduced_motion: bool,
	walking_override: bool = false,
	animation_set: Dictionary = {}
) -> StringName:
	var motions := _motions_for(animation_set)
	var effective_state := _effective_player_state(runtime_state, walking_override, motions)
	var frames: Array = motions.get(effective_state, motions.get(&"idle", PLAYER_MOTIONS[&"idle"]))
	if frames.is_empty():
		return &"idle_a"
	if reduced_motion:
		match effective_state:
			&"move": return StringName(frames[0])
			&"attack_active": return StringName(frames[frames.size() - 1])
	var bounded_index := clampi(frame_index, 0, frames.size() - 1)
	if player_loops(effective_state, animation_set):
		bounded_index = posmod(frame_index, frames.size())
	return StringName(frames[bounded_index])


static func player_frame_count(runtime_state: StringName, walking_override: bool = false, animation_set: Dictionary = {}) -> int:
	var motions := _motions_for(animation_set)
	var effective_state := _effective_player_state(runtime_state, walking_override, motions)
	return (motions.get(effective_state, motions.get(&"idle", PLAYER_MOTIONS[&"idle"])) as Array).size()


static func player_frame_duration(runtime_state: StringName, walking_override: bool = false, animation_set: Dictionary = {}) -> float:
	var motions := _motions_for(animation_set)
	var effective_state := _effective_player_state(runtime_state, walking_override, motions)
	var descriptor := _descriptor_or_default(animation_set)
	var durations: Dictionary = descriptor.get("frame_durations", PLAYER_FRAME_DURATIONS)
	return maxf(0.01, float(durations.get(effective_state, PLAYER_FRAME_DURATIONS.get(effective_state, 0.14))))


static func player_uses_walk_cycle(runtime_state: StringName, walking_override: bool = false, animation_set: Dictionary = {}) -> bool:
	return _effective_player_state(runtime_state, walking_override, _motions_for(animation_set)) == &"move"


static func player_walk_bob_offset(animation_seconds: float, reduced_motion: bool, animation_set: Dictionary = {}) -> float:
	if reduced_motion:
		return 0.0
	var cycle_seconds := player_frame_duration(&"move", false, animation_set) * float(player_frame_count(&"move", false, animation_set))
	if cycle_seconds <= 0.0:
		return 0.0
	var cycle_phase := fposmod(maxf(0.0, animation_seconds), cycle_seconds) / cycle_seconds
	# walk_a/walk_b are the two contact poses. The registered idle poses act as
	# passing poses, so both texture selection and lift share this exact phase.
	return -absf(sin(cycle_phase * TAU)) * PLAYER_MOVE_BOB_AMPLITUDE


static func player_loops(runtime_state: StringName, animation_set: Dictionary = {}) -> bool:
	var descriptor := _descriptor_or_default(animation_set)
	return runtime_state in (descriptor.get("loop_states", [&"idle", &"move"]) as Array)


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


static func _effective_player_state(runtime_state: StringName, walking_override: bool, motions: Dictionary) -> StringName:
	if walking_override and runtime_state == &"idle":
		return &"move"
	return runtime_state if motions.has(runtime_state) else &"idle"


static func _descriptor_or_default(animation_set: Dictionary) -> Dictionary:
	return default_player_animation_set() if animation_set.is_empty() else animation_set


static func _motions_for(animation_set: Dictionary) -> Dictionary:
	var descriptor := _descriptor_or_default(animation_set)
	var motions: Variant = descriptor.get("motions", PLAYER_MOTIONS)
	if motions is Dictionary and not (motions as Dictionary).is_empty():
		return motions as Dictionary
	return PLAYER_MOTIONS


static func _normalized_animation_set(animation_set_id: StringName, source: Dictionary) -> Dictionary:
	var normalized := default_player_animation_set()
	for key in source.keys():
		normalized[key] = source[key]
	normalized["id"] = animation_set_id
	var root := String(normalized.get("root", PLAYER_ROOT)).strip_edges()
	if root == "":
		root = PLAYER_ROOT
	if not root.ends_with("/"):
		root += "/"
	normalized["root"] = root
	normalized["motions"] = _motions_for(normalized).duplicate(true)
	normalized["facings"] = (normalized.get("facings", PLAYER_FACINGS) as Array).duplicate()
	normalized["read_only"] = true
	normalized["used_fallback"] = false
	return normalized
