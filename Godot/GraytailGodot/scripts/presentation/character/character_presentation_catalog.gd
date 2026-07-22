extends RefCounted
class_name CharacterPresentationCatalog

# I2.4B out-of-run presentation catalog. This maps semantic character clips to
# already-audited ART21 visual keys only; it does not represent ownership,
# equipment, save data, or gameplay state.
const Art21MainMenuAssetContractScript := preload("res://scripts/presentation/art21_main_menu_asset_contract.gd")

const DEFAULT_ACTOR_ID := &"graytail"
const DEFAULT_APPEARANCE_ID := &"base_art21"
const DEFAULT_CLIP_ID := &"idle"

const DEFAULT_IDLE_KEYS := [
	&"main_menu.scene.character.idle.00",
	&"main_menu.scene.character.idle.01",
	&"main_menu.scene.character.idle.02",
	&"main_menu.scene.character.idle.03",
	&"main_menu.scene.character.idle.04",
	&"main_menu.scene.character.idle.05",
	&"main_menu.scene.character.idle.06",
	&"main_menu.scene.character.idle.07",
]

const CATALOG := {
	"default_actor_id": DEFAULT_ACTOR_ID,
	"actors": {
		DEFAULT_ACTOR_ID: {
			"default_appearance_id": DEFAULT_APPEARANCE_ID,
			"appearances": {
				DEFAULT_APPEARANCE_ID: {
					"default_clip_id": DEFAULT_CLIP_ID,
					"clips": {
						&"idle": {
							"visual_keys": DEFAULT_IDLE_KEYS,
							"sequence": [0, 0, 1, 1, 2, 1, 0, 0, 0, 3, 3, 0, 0, 4, 5, 4, 0, 0],
							"frame_seconds": 0.32,
							"flip_h": false,
							"fallback_visual_key": &"main_menu.scene.character.idle.00",
						},
						&"look": {
							"visual_keys": DEFAULT_IDLE_KEYS,
							"sequence": [0, 6, 6, 7, 7, 6, 0],
							"frame_seconds": 0.42,
							"flip_h": false,
							"fallback_visual_key": &"main_menu.scene.character.idle.00",
						},
						&"focus_deploy": {
							"visual_keys": [&"main_menu.scene.character.focus.01"],
							"sequence": [0],
							"frame_seconds": 0.32,
							"flip_h": true,
							"fallback_visual_key": &"main_menu.scene.character.idle.00",
						},
						&"focus_long_term": {
							"visual_keys": [&"main_menu.scene.character.focus.02"],
							"sequence": [0],
							"frame_seconds": 0.32,
							"flip_h": false,
							"fallback_visual_key": &"main_menu.scene.character.idle.00",
						},
						&"walk_dungeon": {
							"visual_keys": [
								&"main_menu.scene.character.walk_dungeon.00",
								&"main_menu.scene.character.walk_dungeon.01",
								&"main_menu.scene.character.walk_dungeon.02",
								&"main_menu.scene.character.walk_dungeon.03",
							],
							"sequence": [0, 1, 2, 3],
							"frame_seconds": 0.12,
							"flip_h": false,
							"fallback_visual_key": &"main_menu.scene.character.walk_dungeon.00",
						},
					},
				},
			},
		},
	},
}


static func resolve_descriptor(
	actor_id: StringName = DEFAULT_ACTOR_ID,
	appearance_id: StringName = DEFAULT_APPEARANCE_ID,
	clip_id: StringName = DEFAULT_CLIP_ID,
	catalog_override: Dictionary = {}
) -> Dictionary:
	var source_catalog: Dictionary = CATALOG if catalog_override.is_empty() else catalog_override
	var resolved := _resolve_from_catalog(source_catalog, actor_id, appearance_id, clip_id)
	if resolved.is_empty() and not catalog_override.is_empty():
		resolved = _resolve_from_catalog(CATALOG, actor_id, appearance_id, clip_id)
	return resolved


static func load_frames(descriptor: Dictionary, texture_resolver: Callable = Callable()) -> Array[Texture2D]:
	var visual_keys := descriptor.get("visual_keys", []) as Array
	var frames: Array[Texture2D] = []
	frames.resize(visual_keys.size())
	var fallback_key := StringName(descriptor.get("fallback_visual_key", &""))
	var first_available: Texture2D = null
	for index in range(visual_keys.size()):
		var raw_key: Variant = visual_keys[index]
		var visual_key := StringName(raw_key)
		var texture := _resolve_texture(visual_key, texture_resolver)
		if texture == null and fallback_key != &"" and fallback_key != visual_key:
			texture = _resolve_texture(fallback_key, texture_resolver)
		if texture != null:
			frames[index] = texture
			if first_available == null:
				first_available = texture
	if first_available == null:
		return []
	# Preserve one slot per semantic visual key. Compressing missing keys changes
	# the meaning of sequence indices (for example, key 2 would become slot 0).
	# A missing slot therefore reuses an available audited frame in-place.
	for index in range(frames.size()):
		if frames[index] == null:
			frames[index] = first_available
	return frames


static func frame_index(descriptor: Dictionary, step: int, available_frame_count: int = -1) -> int:
	var frame_count := available_frame_count
	if frame_count < 0:
		frame_count = (descriptor.get("visual_keys", []) as Array).size()
	if frame_count <= 0:
		return -1
	var sequence := descriptor.get("sequence", []) as Array
	if sequence.is_empty():
		return posmod(step, frame_count)
	var sequence_step := posmod(step, sequence.size())
	return posmod(int(sequence[sequence_step]), frame_count)


static func frame_at(frames: Array, descriptor: Dictionary, step: int) -> Texture2D:
	var index := frame_index(descriptor, step, frames.size())
	if index < 0:
		return null
	return frames[index] as Texture2D


static func _resolve_from_catalog(
	source_catalog: Dictionary,
	requested_actor_id: StringName,
	requested_appearance_id: StringName,
	requested_clip_id: StringName
) -> Dictionary:
	var actors_variant: Variant = source_catalog.get("actors", {})
	if not (actors_variant is Dictionary):
		return {}
	var actors := actors_variant as Dictionary
	var default_actor_id := StringName(source_catalog.get("default_actor_id", DEFAULT_ACTOR_ID))
	var actor_id := requested_actor_id if actors.has(requested_actor_id) else default_actor_id
	if not actors.has(actor_id) or not (actors[actor_id] is Dictionary):
		return {}
	var actor := actors[actor_id] as Dictionary

	var appearances_variant: Variant = actor.get("appearances", {})
	if not (appearances_variant is Dictionary):
		return {}
	var appearances := appearances_variant as Dictionary
	var default_appearance_id := StringName(actor.get("default_appearance_id", DEFAULT_APPEARANCE_ID))
	var appearance_id := requested_appearance_id if appearances.has(requested_appearance_id) else default_appearance_id
	if not appearances.has(appearance_id) or not (appearances[appearance_id] is Dictionary):
		return {}
	var appearance := appearances[appearance_id] as Dictionary

	var clips_variant: Variant = appearance.get("clips", {})
	if not (clips_variant is Dictionary):
		return {}
	var clips := clips_variant as Dictionary
	var default_clip_id := StringName(appearance.get("default_clip_id", DEFAULT_CLIP_ID))
	var clip_id := requested_clip_id if clips.has(requested_clip_id) else default_clip_id
	var clip := _normalized_clip(clips.get(clip_id, {}))
	if clip.is_empty() and clip_id != default_clip_id:
		clip_id = default_clip_id
		clip = _normalized_clip(clips.get(clip_id, {}))
	if clip.is_empty():
		return {}

	clip["requested_actor_id"] = requested_actor_id
	clip["requested_appearance_id"] = requested_appearance_id
	clip["requested_clip_id"] = requested_clip_id
	clip["actor_id"] = actor_id
	clip["appearance_id"] = appearance_id
	clip["clip_id"] = clip_id
	clip["fallback_used"] = (
		actor_id != requested_actor_id
		or appearance_id != requested_appearance_id
		or clip_id != requested_clip_id
	)
	return clip


static func _normalized_clip(raw_clip: Variant) -> Dictionary:
	if not (raw_clip is Dictionary):
		return {}
	var source := raw_clip as Dictionary
	var keys_variant: Variant = source.get("visual_keys", [])
	if not (keys_variant is Array):
		return {}
	var visual_keys: Array = []
	for raw_key in keys_variant as Array:
		var key := StringName(raw_key)
		if key != &"":
			visual_keys.append(key)
	if visual_keys.is_empty():
		return {}

	var sequence: Array = []
	var sequence_variant: Variant = source.get("sequence", [])
	if sequence_variant is Array:
		for raw_index in sequence_variant as Array:
			sequence.append(int(raw_index))
	if sequence.is_empty():
		sequence = range(visual_keys.size())
	var fallback_visual_key := StringName(source.get("fallback_visual_key", visual_keys[0]))
	if fallback_visual_key == &"":
		fallback_visual_key = StringName(visual_keys[0])
	return {
		"visual_keys": visual_keys,
		"sequence": sequence,
		"frame_seconds": maxf(0.01, float(source.get("frame_seconds", 0.32))),
		"flip_h": bool(source.get("flip_h", false)),
		"fallback_visual_key": fallback_visual_key,
	}


static func _resolve_texture(visual_key: StringName, texture_resolver: Callable) -> Texture2D:
	if visual_key == &"":
		return null
	if texture_resolver.is_valid():
		return texture_resolver.call(visual_key) as Texture2D
	return Art21MainMenuAssetContractScript.texture(visual_key)
