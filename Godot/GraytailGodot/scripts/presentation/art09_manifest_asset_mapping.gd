extends RefCounted
class_name Art09ManifestAssetMapping

# ART-09 keeps runtime wiring manifest-backed: UI receives asset_id metadata,
# then resolves through ContentDB instead of constructing res:// paths.

const FALLBACK_ICON := &"icon.minimap.explored"
const FALLBACK_BUTTON := &"ui.common.button.dark"
const FALLBACK_PANEL := &"ui.hud.panel.protocol"
const FALLBACK_BACKGROUND := &"room.background.normal"

const MAIN_MENU_BACKGROUND := &"ui.main_menu.background.no_text"
const PLAYER_SPRITE_DEFAULT := &"sprite.player.default"

const PANEL_ASSET_BY_ROLE := {
	&"terminal": &"ui.panel.terminal_main",
	&"hud_left": &"ui.hud.panel.left",
	&"protocol": &"ui.hud.panel.protocol",
	&"bottom_bar": &"ui.hud.bottom_bar",
	&"warning": &"ui.hud.bar.warning",
	&"frame": &"ui.hud.bar.frame",
}

const KEY_PROMPT_BY_ACTION := {
	&"interact": &"ui.key_prompt.e",
	&"cancel": &"ui.key_prompt.esc",
	&"inspect": &"ui.key_prompt.f",
	&"map": &"ui.key_prompt.m",
	&"quick": &"ui.key_prompt.q",
	&"toggle": &"ui.key_prompt.t",
}

const DEPLOY_BUTTON_BY_ROLE := {
	&"back_main": &"ui.deploy.button.back_main",
	&"confirm": &"ui.deploy.button.confirm_deploy_large",
	&"loadout": &"ui.deploy.button.nav_loadout",
	&"recovery": &"ui.deploy.button.nav_recovery",
	&"requisition": &"ui.deploy.button.nav_requisition",
	&"talent": &"ui.deploy.button.nav_talent_selected",
	&"warehouse": &"ui.deploy.button.nav_warehouse",
	&"small": &"ui.deploy.button.key_or_arrow_small_button",
}

const DEPLOY_ICON_BY_ROLE := {
	&"armor": &"ui.deploy.icon.armor",
	&"backpack": &"ui.deploy.icon.backpack",
	&"bandage": &"ui.deploy.icon.bandage",
	&"compass": &"ui.deploy.icon.compass",
}

const DEPLOY_PANEL_BY_ROLE := {
	&"highlight": &"ui.deploy.panel.frame_highlight",
	&"main": &"ui.deploy.panel.deploy_main_blank",
	&"summary": &"ui.deploy.panel.deploy_summary_blank",
}

const ITEM_ICON_BY_KIND := {
	&"consumable": &"item.consumable.medkit",
	&"medkit": &"item.consumable.medkit",
	&"syringe": &"item.consumable.syringe",
	&"equipment": &"item.equipment.flashlight",
	&"flashlight": &"item.equipment.flashlight",
	&"goggles": &"item.equipment.goggles",
	&"recovered": &"item.recovered.ore",
	&"ore": &"item.recovered.ore",
}

const FEEDBACK_ASSET_BY_STATE := {
	&"neutral": &"ui.feedback.bar.dark",
	&"success": &"ui.feedback.bar.dark",
	&"ready": &"ui.feedback.bar.dark",
	&"search": &"ui.feedback.event_prompt",
	&"event": &"ui.feedback.event_prompt",
	&"reward": &"ui.feedback.event_prompt",
	&"warning": &"ui.feedback.bar.red",
	&"danger": &"ui.feedback.bar.red",
	&"blocked": &"ui.feedback.bar.red",
}

const RESULT_TITLE_BY_STATE := {
	&"extract_confirm": &"ui.result.title.extract_confirm",
	&"success": &"ui.result.title.extraction_success",
	&"failure": &"ui.result.title.signal_lost",
	&"failed": &"ui.result.title.signal_lost",
	&"signal_lost": &"ui.result.title.signal_lost",
	&"abandon": &"ui.result.title.signal_lost",
	&"abandoned": &"ui.result.title.signal_lost",
}


static func asset_ref(asset_id: StringName, fallback_asset_id: StringName, role: StringName, state: StringName = &"", rendered: bool = true) -> Dictionary:
	return {
		"asset_id": asset_id,
		"fallback_asset_id": fallback_asset_id,
		"presentation_role": role,
		"state": state,
		"manifest_backed": true,
		"manifest_backed_but_not_rendered_yet": not rendered,
	}


static func main_menu_background_ref() -> Dictionary:
	return asset_ref(MAIN_MENU_BACKGROUND, FALLBACK_BACKGROUND, &"main_menu_background", &"no_text")


static func player_sprite_ref(state: StringName = &"idle") -> Dictionary:
	return asset_ref(PLAYER_SPRITE_DEFAULT, PLAYER_SPRITE_DEFAULT, &"player_sprite", state)


static func key_prompt_ref(action_id: StringName, rendered: bool = false) -> Dictionary:
	var asset_id: StringName = KEY_PROMPT_BY_ACTION.get(action_id, &"")
	return asset_ref(asset_id, FALLBACK_BUTTON, &"ui_key_prompt", action_id, rendered)


static func deploy_button_ref(role: StringName) -> Dictionary:
	return asset_ref(DEPLOY_BUTTON_BY_ROLE.get(role, &""), FALLBACK_BUTTON, &"deploy_button", role)


static func deploy_icon_ref(role: StringName) -> Dictionary:
	return asset_ref(DEPLOY_ICON_BY_ROLE.get(role, &""), FALLBACK_ICON, &"deploy_icon", role)


static func deploy_panel_ref(role: StringName) -> Dictionary:
	return asset_ref(DEPLOY_PANEL_BY_ROLE.get(role, &""), FALLBACK_PANEL, &"deploy_panel", role)


static func item_icon_ref(kind: StringName) -> Dictionary:
	return asset_ref(ITEM_ICON_BY_KIND.get(kind, ITEM_ICON_BY_KIND[&"consumable"]), FALLBACK_ICON, &"item_icon", kind)


static func feedback_bar_ref(state: StringName = &"neutral") -> Dictionary:
	return asset_ref(FEEDBACK_ASSET_BY_STATE.get(state, FEEDBACK_ASSET_BY_STATE[&"neutral"]), FALLBACK_PANEL, &"feedback_bar", state)


static func feedback_panel_ref(state: StringName = &"event") -> Dictionary:
	return asset_ref(FEEDBACK_ASSET_BY_STATE.get(state, FEEDBACK_ASSET_BY_STATE[&"event"]), FALLBACK_PANEL, &"feedback_panel", state)


static func result_title_ref(state: StringName = &"success") -> Dictionary:
	return asset_ref(RESULT_TITLE_BY_STATE.get(state, RESULT_TITLE_BY_STATE[&"success"]), FALLBACK_PANEL, &"result_title_plate", state)


static func panel_ref(role: StringName = &"terminal") -> Dictionary:
	return asset_ref(PANEL_ASSET_BY_ROLE.get(role, PANEL_ASSET_BY_ROLE[&"terminal"]), FALLBACK_PANEL, &"panel_texture", role)


static func deploy_prep_asset_refs() -> Dictionary:
	return {
		"buttons": {
			"back_main": deploy_button_ref(&"back_main"),
			"confirm": deploy_button_ref(&"confirm"),
			"loadout": deploy_button_ref(&"loadout"),
			"warehouse": deploy_button_ref(&"warehouse"),
			"small": deploy_button_ref(&"small"),
		},
		"icons": {
			"map": deploy_icon_ref(&"compass"),
			"warehouse": deploy_icon_ref(&"backpack"),
			"claim": deploy_icon_ref(&"bandage"),
			"objective": deploy_icon_ref(&"compass"),
			"loadout": deploy_icon_ref(&"armor"),
		},
		"panels": {
			"main": deploy_panel_ref(&"main"),
			"summary": deploy_panel_ref(&"summary"),
			"highlight": deploy_panel_ref(&"highlight"),
		},
		"key_prompts": {
			"interact": key_prompt_ref(&"interact", false),
			"cancel": key_prompt_ref(&"cancel", false),
			"inspect": key_prompt_ref(&"inspect", false),
			"map": key_prompt_ref(&"map", false),
			"quick": key_prompt_ref(&"quick", false),
			"toggle": key_prompt_ref(&"toggle", false),
		},
		"item_icons": {
			"consumable": item_icon_ref(&"consumable"),
			"equipment": item_icon_ref(&"equipment"),
			"recovered": item_icon_ref(&"recovered"),
		},
	}


static func deploy_tab_icon_ref(tab_id: StringName) -> Dictionary:
	match tab_id:
		&"map":
			return deploy_icon_ref(&"compass")
		&"warehouse":
			return deploy_icon_ref(&"backpack")
		&"claim":
			return deploy_icon_ref(&"bandage")
		&"objective":
			return deploy_icon_ref(&"compass")
		&"loadout":
			return deploy_icon_ref(&"armor")
		_:
			return deploy_icon_ref(&"compass")


static func deploy_card_asset_ref(card_id: StringName, category: String, filter_id: StringName) -> Dictionary:
	var id_text := String(card_id).to_lower()
	if id_text.find("first_aid") >= 0 or id_text.find("consumable") >= 0:
		return item_icon_ref(&"medkit")
	if id_text.find("syringe") >= 0:
		return item_icon_ref(&"syringe")
	if id_text.find("ore") >= 0 or id_text.find("recover") >= 0:
		return item_icon_ref(&"recovered")
	if id_text.find("vest") >= 0 or id_text.find("equipment") >= 0:
		return item_icon_ref(&"equipment")
	if filter_id == &"warehouse_equipment" or category.to_lower().find("equipment") >= 0:
		return item_icon_ref(&"equipment")
	if filter_id == &"warehouse_consumable" or category.to_lower().find("consumable") >= 0:
		return item_icon_ref(&"consumable")
	if filter_id == &"loadout_map":
		return deploy_icon_ref(&"compass")
	if filter_id == &"loadout_bag":
		return deploy_icon_ref(&"backpack")
	return deploy_icon_ref(&"compass")


static func inventory_item_icon_ref(item: Dictionary) -> Dictionary:
	var explicit_asset := StringName(item.get("asset_id", &""))
	if String(explicit_asset).begins_with("item."):
		return asset_ref(explicit_asset, FALLBACK_ICON, &"item_icon", &"explicit")
	var item_id := String(item.get("item_id", item.get("definition_id", ""))).to_lower()
	var item_type := String(item.get("item_type", item.get("category", ""))).to_lower()
	if item_id.find("syringe") >= 0:
		return item_icon_ref(&"syringe")
	if item_id.find("ore") >= 0 or item_type.find("recovered") >= 0:
		return item_icon_ref(&"recovered")
	if item_id.find("goggles") >= 0:
		return item_icon_ref(&"goggles")
	if item_id.find("flashlight") >= 0:
		return item_icon_ref(&"flashlight")
	if item_type.find("equipment") >= 0:
		return item_icon_ref(&"equipment")
	if item_type.find("consumable") >= 0:
		return item_icon_ref(&"consumable")
	return item_icon_ref(&"consumable")


static func resolve_texture(asset_ref: Dictionary) -> Texture2D:
	var asset_id := StringName(asset_ref.get("asset_id", &""))
	var texture := _texture_for(asset_id)
	if texture != null:
		return texture
	return _texture_for(StringName(asset_ref.get("fallback_asset_id", &"")))


static func _texture_for(asset_id: StringName) -> Texture2D:
	if asset_id == &"":
		return null
	var resource := ContentDB.get_asset_ref(asset_id)
	if resource is Texture2D:
		return resource as Texture2D
	return null
