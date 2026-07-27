extends RefCounted
class_name PlayerAppearanceConfig

const CONFIG_SCHEMA_VERSION := 1
const DEFAULT_SELECTION_ID := &"graytail.base"
const FIELD_COAT_SELECTION_ID := &"graytail.field_coat"
const DEFAULT_APPEARANCE_ID := &"graytail"
const DEFAULT_ANIMATION_SET_ID := &"art24_graytail_runtime"
const DEFAULT_VISUAL_MODULATE := Color.WHITE
# No second audited in-run sprite sheet exists yet. The field-coat selection is
# therefore an explicit material/tint profile, not a claim that coat pixels
# already exist in the repository.
const FIELD_COAT_VISUAL_MODULATE := Color(0.78, 0.88, 0.72, 1.0)
const RUNTIME_PROFILES := {
	DEFAULT_SELECTION_ID: {
		"appearance_id": DEFAULT_APPEARANCE_ID,
		"animation_set_id": DEFAULT_ANIMATION_SET_ID,
		"visual_modulate": DEFAULT_VISUAL_MODULATE,
	},
	FIELD_COAT_SELECTION_ID: {
		"appearance_id": &"graytail_field_coat",
		"animation_set_id": DEFAULT_ANIMATION_SET_ID,
		"visual_modulate": FIELD_COAT_VISUAL_MODULATE,
	},
}


static func default_config() -> Dictionary:
	return {
		"schema_version": CONFIG_SCHEMA_VERSION,
		"actor_id": "graytail",
		"selected_appearance_id": String(DEFAULT_SELECTION_ID),
		"owned_appearance_ids": [String(DEFAULT_SELECTION_ID)],
	}


static func normalize(value: Variant) -> Dictionary:
	var source := value as Dictionary if value is Dictionary else {}
	var owned_ids: Array[String] = []
	var seen: Dictionary = {}
	var raw_owned: Variant = source.get("owned_appearance_ids", [])
	if raw_owned is Array:
		for raw_id in raw_owned as Array:
			var appearance_id := str(raw_id).strip_edges()
			if (
				appearance_id.is_empty()
				or seen.has(appearance_id)
				or not RUNTIME_PROFILES.has(StringName(appearance_id))
			):
				continue
			seen[appearance_id] = true
			owned_ids.append(appearance_id)
	var default_id := String(DEFAULT_SELECTION_ID)
	if not seen.has(default_id):
		owned_ids.append(default_id)
		seen[default_id] = true
	var requested_id := str(source.get("selected_appearance_id", default_id)).strip_edges()
	var selected_id := requested_id if seen.has(requested_id) else default_id
	owned_ids.sort()
	return {
		"schema_version": CONFIG_SCHEMA_VERSION,
		"actor_id": "graytail",
		"selected_appearance_id": selected_id,
		"owned_appearance_ids": owned_ids,
	}


static func runtime_presentation(value: Variant) -> Dictionary:
	var source := value as Dictionary if value is Dictionary else {}
	var requested_id := StringName(source.get("selected_appearance_id", DEFAULT_SELECTION_ID))
	var normalized := normalize(value)
	var selection_id := StringName(normalized.get("selected_appearance_id", DEFAULT_SELECTION_ID))
	var catalog_fallback_used := not RUNTIME_PROFILES.has(selection_id)
	var resolved_selection_id := DEFAULT_SELECTION_ID if catalog_fallback_used else selection_id
	var profile := (RUNTIME_PROFILES[resolved_selection_id] as Dictionary).duplicate(true)
	return {
		"selection_id": resolved_selection_id,
		"appearance_id": StringName(profile.get("appearance_id", DEFAULT_APPEARANCE_ID)),
		"animation_set_id": StringName(profile.get("animation_set_id", DEFAULT_ANIMATION_SET_ID)),
		"animation_set": {},
		"visual_modulate": profile.get("visual_modulate", DEFAULT_VISUAL_MODULATE),
		"owned_appearance_ids": (normalized.get("owned_appearance_ids", []) as Array).duplicate(),
		"selection_fallback_used": requested_id != selection_id,
		"catalog_fallback_used": catalog_fallback_used,
		"read_only": true,
	}
