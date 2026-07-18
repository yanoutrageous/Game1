extends RefCounted
class_name Art23LongTermAssetContract

const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")

const VISUAL_PREFIX := "long_term."
const ASSET_PREFIX := "ui.art23."


static func component_ref(visual_key: StringName, role: StringName = &"long_term_scene") -> Dictionary:
	return Art09ManifestAssetMappingScript.asset_ref(
		asset_id(visual_key),
		_fallback_asset_id(visual_key),
		role,
		visual_key,
		true
	)


static func texture(visual_key: StringName) -> Texture2D:
	return Art09ManifestAssetMappingScript.resolve_texture(component_ref(visual_key))


static func asset_id(visual_key: StringName) -> StringName:
	var key := String(visual_key)
	if not key.begins_with(VISUAL_PREFIX):
		return &""
	return StringName("%s%s" % [ASSET_PREFIX, key])


static func furniture_ref(module_id: StringName) -> Dictionary:
	return component_ref(StringName("long_term.furniture.%s" % String(module_id)), &"long_term_furniture")


static func module_control_ref(module_id: StringName, state: StringName = &"normal") -> Dictionary:
	return component_ref(
		StringName("long_term.control.module.%s.%s" % [String(module_id), String(state)]),
		&"long_term_primary_module"
	)


static func control_ref(control_id: StringName, state: StringName = &"normal") -> Dictionary:
	return component_ref(
		StringName("long_term.control.%s.%s" % [String(control_id), String(state)]),
		&"long_term_control"
	)


static func load_group(visual_key: StringName) -> StringName:
	var key := String(visual_key)
	if key.find(".furniture.") >= 0:
		return StringName("long_term_%s" % key.get_slice(".", 2))
	return &"long_term_default"


static func _fallback_asset_id(visual_key: StringName) -> StringName:
	var key := String(visual_key)
	if key.find("background") >= 0:
		return &"room.background.normal"
	if key.find("control") >= 0:
		return &"ui.common.button.dark"
	if key.find("furniture") >= 0:
		return &"ui.art19.panel.terminal_main"
	return &"ui.art19.panel.deploy_main"
