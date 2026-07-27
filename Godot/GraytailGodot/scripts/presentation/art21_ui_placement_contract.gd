extends RefCounted
class_name Art21UIPlacementContract

# Runtime mirror of docs/art/validation/art21/ui_placement_contract.csv.
# This keeps ART-21 UI consumption slot-driven and manifest-backed.

const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const Art21MainMenuAssetContractScript := preload("res://scripts/presentation/art21_main_menu_asset_contract.gd")

const ART21_COMPONENT_BY_VISUAL_KEY := {
	&"shared.panel.page_frame.normal": &"ui.art21.shared.panel.page_frame.normal",
	&"shared.panel.card.normal": &"ui.art21.shared.panel.card.normal",
	&"shared.panel.slot.normal": &"ui.art21.shared.panel.slot.normal",
	&"shared.panel.status_card.normal": &"ui.art21.shared.panel.status_card.normal",
	&"shared.panel.modal.normal": &"ui.art21.shared.panel.modal.normal",
	&"shared.panel.tooltip.normal": &"ui.art21.shared.panel.tooltip.normal",
	&"shared.button.primary.normal": &"ui.art21.shared.button.primary.normal",
	&"shared.button.primary.hover": &"ui.art21.shared.button.primary.hover",
	&"shared.button.primary.pressed": &"ui.art21.shared.button.primary.pressed",
	&"shared.button.primary.disabled": &"ui.art21.shared.button.primary.disabled",
	&"shared.button.secondary.normal": &"ui.art21.shared.button.secondary.normal",
	&"shared.button.secondary.selected": &"ui.art21.shared.button.secondary.selected",
	&"shared.tab.normal": &"ui.art21.shared.tab.normal",
	&"shared.tab.selected": &"ui.art21.shared.tab.selected",
	&"main_menu.action_deck.frame": &"ui.art21.main_menu.action_deck.frame",
	&"deploy.left_character_frame.replaced": &"ui.art21.deploy.left_character_frame",
	&"deploy.route_wall.frame": &"ui.art21.deploy.route_wall.frame",
	&"deploy.summary_panel.frame": &"ui.art21.deploy.summary_panel.frame",
	&"long_term.profile_frame.replaced": &"ui.art21.long_term.profile_frame",
	&"long_term.collection_wall.frame": &"ui.art21.long_term.collection_wall.frame",
	&"long_term.detail_panel.frame": &"ui.art21.long_term.detail_panel.frame",
	&"run.gameplay_viewport.background.replaced": &"ui.art21.run.gameplay_viewport.background",
	&"run.left_info_rail.frame": &"ui.art21r2.run.left_info_rail.frame",
	&"run.status_card.frame": &"ui.art21r2.run.status_card.frame",
	&"run.bottom_overlay.frame": &"ui.art21r2.run.bottom_overlay.frame",
	&"map_overlay.cell.unknown.replaced": &"ui.art21.map.cell.unknown",
	&"map_overlay.cell.explored.replaced": &"ui.art21.map.cell.explored",
	&"map_overlay.cell.scanned.replaced": &"ui.art21.map.cell.scanned",
	&"map_overlay.cell.flagged.replaced": &"ui.art21.map.cell.flagged",
	&"map_overlay.marker.event.replaced": &"ui.art21.map.marker.event",
	&"art21r2.map_overlay.marker.event": &"ui.art21r2.map_overlay.marker.event",
	&"art21r2.map_overlay.marker.flag": &"ui.art21r2.map_overlay.marker.flag",
	&"map_overlay.marker.player": &"ui.art21.map.marker.player",
	&"map_overlay.marker.exit": &"ui.art21.map.marker.exit",
	&"map_overlay.marker.mine": &"ui.art21.map.marker.mine",
	&"map_overlay.marker.chest": &"ui.art21.map.marker.chest",
	&"inventory.panel.frame": &"ui.art21r2.modal.inventory.frame",
	&"ground_loot.panel.frame": &"ui.art21r2.modal.ground_loot.frame",
	&"result.modal.frame": &"ui.art21r2.modal.result.frame",
	&"art21r2.modal.inventory.frame": &"ui.art21r2.modal.inventory.frame",
	&"art21r2.modal.ground_loot.frame": &"ui.art21r2.modal.ground_loot.frame",
	&"art21r2.modal.result.frame": &"ui.art21r2.modal.result.frame",
	&"art21r2.modal.title_plate": &"ui.art21r2.modal.title_plate",
	&"art21r2.modal.section.panel": &"ui.art21r2.modal.section.panel",
	&"art21r2.modal.action_strip": &"ui.art21r2.modal.action_strip",
	&"art21r2.modal.item_row.normal": &"ui.art21r2.modal.item_row.normal",
	&"art21r2.modal.button.primary": &"ui.art21r2.modal.button.primary",
	&"art21r2.modal.button.secondary": &"ui.art21r2.modal.button.secondary",
	&"art21r2.modal.button.danger": &"ui.art21r2.modal.button.danger",
	&"art21r2.main_menu.title_board": &"ui.art21r2.main_menu.title_board",
	&"art21r2.main_menu.board_header": &"ui.art21r2.main_menu.board_header",
	&"art21r2.main_menu.entry_plank.deploy": &"ui.art21r2.main_menu.entry_plank.deploy",
	&"art21r2.main_menu.entry_plank.long_term": &"ui.art21r2.main_menu.entry_plank.long_term",
	&"art21r2.main_menu.entry_plank.settings": &"ui.art21r2.main_menu.entry_plank.settings",
	&"art21r2.main_menu.entry_plank.exit": &"ui.art21r2.main_menu.entry_plank.exit",
}

const SLOT_VISUAL_KEY := {
	&"main_menu.action_deck_frame": &"main_menu.action_deck.frame",
	&"deploy_prep.left_character_frame": &"deploy.left_character_frame.replaced",
	&"deploy_prep.center_route_wall": &"deploy.route_wall.frame",
	&"deploy_prep.right_summary_panel": &"deploy.summary_panel.frame",
	&"long_term.left_profile_frame": &"long_term.profile_frame.replaced",
	&"long_term.collection_wall": &"long_term.collection_wall.frame",
	&"long_term.right_detail_panel": &"long_term.detail_panel.frame",
	&"run_hud.gameplay_viewport_background": &"run.gameplay_viewport.background.replaced",
	&"run_hud.left_info_rail": &"run.left_info_rail.frame",
	&"run_hud.top_right_status_card": &"run.status_card.frame",
	&"run_hud.bottom_overlay": &"run.bottom_overlay.frame",
	&"inventory.inventory_panel_frame": &"art21r2.modal.inventory.frame",
	&"ground_loot.ground_loot_panel_frame": &"art21r2.modal.ground_loot.frame",
	&"result.result_modal_frame": &"art21r2.modal.result.frame",
}

const PANEL_VISUAL_KEY_BY_ROLE := {
	&"page_frame": &"shared.panel.page_frame.normal",
	&"card": &"shared.panel.card.normal",
	&"slot": &"shared.panel.slot.normal",
	&"status_card": &"shared.panel.status_card.normal",
	&"modal": &"shared.panel.modal.normal",
	&"tooltip": &"shared.panel.tooltip.normal",
	&"surface": &"shared.panel.page_frame.normal",
	&"deep": &"shared.panel.page_frame.normal",
	&"summary": &"shared.panel.card.normal",
	&"notice": &"shared.panel.card.normal",
	&"soft": &"shared.panel.card.normal",
	&"selected": &"shared.panel.slot.normal",
	&"panel_terminal": &"shared.panel.page_frame.normal",
	&"panel_deploy_main": &"deploy.route_wall.frame",
	&"panel_summary": &"shared.panel.card.normal",
	&"panel_highlight": &"shared.panel.slot.normal",
	&"bar_summary": &"run.bottom_overlay.frame",
}

const BUTTON_VISUAL_KEY_BY_ROLE := {
	&"primary": &"shared.button.primary.normal",
	&"secondary": &"shared.button.secondary.normal",
	&"button_confirm": &"shared.button.primary.normal",
	&"button_primary": &"shared.button.primary.normal",
	&"button_primary_hover": &"shared.button.primary.hover",
	&"button_primary_pressed": &"shared.button.primary.pressed",
	&"button_primary_disabled": &"shared.button.primary.disabled",
	&"button_dark": &"shared.button.secondary.normal",
	&"button_secondary": &"shared.button.secondary.normal",
	&"button_selected_tab": &"shared.button.secondary.selected",
	&"tab_normal": &"shared.tab.normal",
	&"tab_selected": &"shared.tab.selected",
}

const MAP_VISUAL_KEY_BY_STATE := {
	&"unknown": &"map_overlay.cell.unknown.replaced",
	&"hidden": &"map_overlay.cell.unknown.replaced",
	&"explored": &"map_overlay.cell.explored.replaced",
	&"normal": &"map_overlay.cell.explored.replaced",
	&"scanned": &"map_overlay.cell.scanned.replaced",
	&"number": &"map_overlay.cell.scanned.replaced",
	&"flagged": &"art21r2.map_overlay.marker.flag",
	&"event": &"art21r2.map_overlay.marker.event",
	&"player": &"map_overlay.marker.player",
	&"exit": &"map_overlay.marker.exit",
	&"mine": &"map_overlay.marker.mine",
	&"chest": &"map_overlay.marker.chest",
}


static func component_ref(visual_key: StringName, fallback_asset_id: StringName = &"ui.art19.panel.terminal_main", role: StringName = &"art21_component") -> Dictionary:
	return Art09ManifestAssetMappingScript.asset_ref(
		ART21_COMPONENT_BY_VISUAL_KEY.get(visual_key, &""),
		fallback_asset_id,
		role,
		visual_key,
		true
	)


static func slot_ref(screen: StringName, slot: StringName, fallback_asset_id: StringName = &"ui.art19.panel.terminal_main", role: StringName = &"art21_slot") -> Dictionary:
	var key := StringName("%s.%s" % [String(screen), String(slot)])
	return component_ref(SLOT_VISUAL_KEY.get(key, &""), fallback_asset_id, role)


static func panel_ref(role: StringName) -> Dictionary:
	return component_ref(PANEL_VISUAL_KEY_BY_ROLE.get(role, &"shared.panel.page_frame.normal"), &"ui.art19.panel.terminal_main", &"art21_panel")


static func button_ref(role: StringName) -> Dictionary:
	return component_ref(BUTTON_VISUAL_KEY_BY_ROLE.get(role, &"shared.button.secondary.normal"), &"ui.art19.button.dark", &"art21_button")


static func map_ref(state: StringName) -> Dictionary:
	return component_ref(MAP_VISUAL_KEY_BY_STATE.get(state, &"map_overlay.cell.explored.replaced"), &"ui.art19.map64.explored", &"art21_map")


static func texture_for_slot(screen: StringName, slot: StringName, fallback_asset_id: StringName = &"ui.art19.panel.terminal_main") -> Texture2D:
	return Art09ManifestAssetMappingScript.resolve_texture(slot_ref(screen, slot, fallback_asset_id))


static func texture_for_visual_key(visual_key: StringName, fallback_asset_id: StringName = &"ui.art19.panel.terminal_main") -> Texture2D:
	return Art09ManifestAssetMappingScript.resolve_texture(component_ref(visual_key, fallback_asset_id))


static func style_box_for_visual_key(visual_key: StringName, fallback_asset_id: StringName = &"ui.art19.button.dark", padding: int = 8, texture_margin: int = 18) -> StyleBoxTexture:
	var texture := texture_for_visual_key(visual_key, fallback_asset_id)
	if texture == null:
		return null
	var slice_margin := maxi(texture_margin, 0)
	var content_inset := maxi(maxi(padding, 0), slice_margin)
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = slice_margin
	style.texture_margin_top = slice_margin
	style.texture_margin_right = slice_margin
	style.texture_margin_bottom = slice_margin
	style.content_margin_left = content_inset
	style.content_margin_top = content_inset
	style.content_margin_right = content_inset
	style.content_margin_bottom = content_inset
	style.draw_center = true
	return style


static func main_menu_scene_ref(visual_key: StringName, role: StringName = &"main_menu_scene") -> Dictionary:
	return Art21MainMenuAssetContractScript.component_ref(visual_key, role)


static func main_menu_scene_texture(visual_key: StringName) -> Texture2D:
	return Art21MainMenuAssetContractScript.texture(visual_key)


static func main_menu_scene_load_group(visual_key: StringName) -> StringName:
	return Art21MainMenuAssetContractScript.load_group(visual_key)
