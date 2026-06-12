extends RefCounted
class_name G10ArtSmokeRegistry

# G10 art smoke uses manifest asset_ids only. It must not introduce direct resource paths.

const SMOKE_ENTRIES := [
	{
		"entry_id": &"panel.status",
		"role": &"ui_panel",
		"asset_id": &"ui.hud.panel.left",
		"fallback_asset_id": &"ui.hud.panel.protocol",
		"contract": &"PresentationLayerEntry",
	},
	{
		"entry_id": &"button.dark",
		"role": &"button",
		"asset_id": &"ui.common.button.dark",
		"fallback_asset_id": &"ui.hud.bottom_bar",
		"contract": &"PresentationLayerEntry",
	},
	{
		"entry_id": &"icon.gold",
		"role": &"icon",
		"asset_id": &"ui.common.gold_icon",
		"fallback_asset_id": &"icon.minimap.explored",
		"contract": &"NavigationEntry",
	},
	{
		"entry_id": &"character.placeholder",
		"role": &"character",
		"asset_id": &"sprite.player.default",
		"fallback_asset_id": &"sprite.player.default",
		"contract": &"CharacterPresentationConfig",
	},
	{
		"entry_id": &"theme.overlay.placeholder",
		"role": &"theme_overlay",
		"asset_id": &"room.background.normal",
		"fallback_asset_id": &"room.background.event",
		"contract": &"ThemeProfile",
	},
]


static func smoke_entries() -> Array:
	return SMOKE_ENTRIES.duplicate(true)


static func build_smoke_report() -> Dictionary:
	var missing_asset_ids: Array[StringName] = []
	var missing_fallback_ids: Array[StringName] = []
	for raw_entry in SMOKE_ENTRIES:
		var entry: Dictionary = {}
		if raw_entry is Dictionary:
			entry = raw_entry
		var asset_id: StringName = StringName(entry.get("asset_id", &""))
		var fallback_asset_id: StringName = StringName(entry.get("fallback_asset_id", &""))
		if asset_id == &"" or not ContentDB.has_asset(asset_id):
			missing_asset_ids.append(asset_id)
		if fallback_asset_id == &"" or not ContentDB.has_asset(fallback_asset_id):
			missing_fallback_ids.append(fallback_asset_id)
	return {
		"ok": missing_asset_ids.is_empty() and missing_fallback_ids.is_empty(),
		"entries": smoke_entries(),
		"missing_asset_ids": missing_asset_ids,
		"missing_fallback_ids": missing_fallback_ids,
		"registry": &"manifest_asset_id_only",
	}
