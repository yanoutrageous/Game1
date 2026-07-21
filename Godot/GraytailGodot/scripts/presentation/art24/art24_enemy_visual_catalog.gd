extends RefCounted
class_name Art24EnemyVisualCatalog

const ACTOR_ROOT := "res://assets/art24/actors/"
const ENEMY_SUBJECTS := [&"slime", &"slimeling", &"bat", &"drone"]
const TextureCache := preload("res://scripts/presentation/runtime_texture_cache.gd")


static func supports(subject: StringName) -> bool:
	return subject in ENEMY_SUBJECTS


static func texture_path(subject: StringName, runtime_state: StringName, frame_index: int = 0, visual_variant: StringName = &"base") -> String:
	var asset_subject := &"slime" if subject == &"slimeling" else subject
	var directory := "%s%s/" % [ACTOR_ROOT, String(asset_subject)]
	if visual_variant != &"base":
		return "%s%s.png" % [directory, _generated_variant_frame(runtime_state, frame_index)]
	if runtime_state in [&"dead", &"defeated"]:
		return "%sue_defeated_%d.png" % [directory, mini(frame_index, 4)]
	if runtime_state == &"hurt":
		return "%shurt.png" % directory
	if runtime_state in [&"active", &"fire"]:
		return "%sue_attack.png" % directory
	if runtime_state in [&"warning", &"aim"]:
		if asset_subject == &"drone":
			return "%sue_warning_%d.png" % [directory, frame_index % 2]
		return "%sue_warning.png" % directory
	if subject == &"slimeling":
		return "%sue_slimeling_idle.png" % directory
	if asset_subject in [&"bat", &"drone"]:
		return "%sue_idle_%d.png" % [directory, frame_index % 4]
	return "%sue_idle.png" % directory


static func texture_for(subject: StringName, runtime_state: StringName, frame_index: int = 0, visual_variant: StringName = &"base") -> Texture2D:
	return TextureCache.texture(texture_path(subject, runtime_state, frame_index, visual_variant))


static func frame_count(subject: StringName, runtime_state: StringName, visual_variant: StringName = &"base") -> int:
	if visual_variant != &"base":
		return 2 if runtime_state not in [&"warning", &"aim", &"active", &"fire", &"hurt", &"dead", &"defeated"] else 1
	if runtime_state in [&"dead", &"defeated"]:
		return 5
	if runtime_state in [&"warning", &"aim"] and subject == &"drone":
		return 2
	if runtime_state in [&"warning", &"aim", &"active", &"fire", &"hurt"]:
		return 1
	if subject in [&"bat", &"drone"]:
		return 4
	return 1


static func frame_duration(runtime_state: StringName) -> float:
	if runtime_state in [&"dead", &"defeated"]:
		return 0.09
	if runtime_state in [&"warning", &"aim", &"active", &"fire"]:
		return 0.11
	return 0.14


static func loops(runtime_state: StringName) -> bool:
	return runtime_state not in [&"dead", &"defeated"]


static func reduced_motion_frame(subject: StringName, runtime_state: StringName, visual_variant: StringName = &"base") -> int:
	if runtime_state in [&"dead", &"defeated"] and visual_variant == &"base":
		return frame_count(subject, runtime_state, visual_variant) - 1
	return 0


static func minimum_visible_seconds(runtime_state: StringName) -> float:
	return 0.12 if runtime_state == &"hurt" else 0.0


static func production_texture_paths() -> Array[String]:
	var unique_paths: Dictionary = {}
	for subject in ENEMY_SUBJECTS:
		for runtime_state: StringName in [&"idle", &"hurt", &"active", &"warning", &"defeated"]:
			for frame_index in range(frame_count(subject, runtime_state, &"base")):
				unique_paths[texture_path(subject, runtime_state, frame_index, &"base")] = true
	var result: Array[String] = []
	for raw_path in unique_paths.keys():
		result.append(String(raw_path))
	result.sort()
	return result


static func visual_scale(subject: StringName, visual_variant: StringName = &"base") -> float:
	if visual_variant != &"base":
		match subject:
			&"slimeling": return 0.12
			&"bat": return 0.16
			&"drone": return 0.17
		return 0.18
	match subject:
		&"slimeling": return 0.20
		&"bat": return 0.32
		&"drone": return 0.27
	return 0.35


static func visual_offset(subject: StringName) -> Vector2:
	match subject:
		&"bat": return Vector2(0, -14)
		&"drone": return Vector2(0, -12)
		&"slimeling": return Vector2(0, -3)
	return Vector2(0, -5)


static func health_bar_y(subject: StringName) -> float:
	return -20.0 if subject == &"slimeling" else -30.0


static func _generated_variant_frame(runtime_state: StringName, frame_index: int) -> String:
	match runtime_state:
		&"warning", &"aim": return "warning"
		&"active", &"fire": return "attack"
		&"hurt": return "hurt"
		&"dead", &"defeated": return "defeated"
	return "idle_b" if frame_index % 2 == 1 else "idle_a"
