extends RefCounted
class_name Art22DeployPrepAssetContract

const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")

const VISUAL_PREFIX := "deploy_prep."
const ASSET_PREFIX := "ui.art22."

const ROUTE_KEY_BY_CARD := {
	&"map_classic_edge": &"graytail_edge",
	&"map_honeycomb_trial": &"honeycomb",
	&"map_special_rule_fog": &"fog_rule",
	&"map_unlocked_route": &"classic_grid",
	&"map_target_match": &"objective_cache",
}

const ICON_KEY_BY_CARD := {
	&"purchase_first_aid": &"claim_purchase",
	&"claim_starter_gear": &"claim_receive",
	&"recycle_relic": &"claim_recycle",
	&"locked_supply": &"claim_locked",
	&"recommended_for_target": &"claim_recommended",
	&"objective_recover_cache": &"objective_recover",
	&"commission_scan_route": &"objective_scan",
	&"objective_map_match": &"objective_map_match",
	&"objective_locked_high_risk": &"objective_locked",
	&"objective_reward_summary": &"objective_reward",
}


static func component_ref(visual_key: StringName, role: StringName = &"deploy_prep_scene") -> Dictionary:
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


static func control_ref(control_id: StringName, state: StringName = &"normal") -> Dictionary:
	return component_ref(
		StringName("deploy_prep.control.%s.%s" % [String(control_id), String(state)]),
		&"deploy_prep_control"
	)


static func route_ref(card_id: StringName) -> Dictionary:
	var route_key: StringName = ROUTE_KEY_BY_CARD.get(card_id, &"classic_grid")
	return component_ref(StringName("deploy_prep.route.%s" % String(route_key)), &"deploy_prep_route_thumbnail")


static func icon_ref(card_id: StringName) -> Dictionary:
	var icon_key: StringName = ICON_KEY_BY_CARD.get(card_id, &"fallback")
	return component_ref(StringName("deploy_prep.icon.%s" % String(icon_key)), &"deploy_prep_semantic_icon")


static func card_art_ref(tab_id: StringName, card_id: StringName, filter_id: StringName = &"") -> Dictionary:
	if tab_id == &"map":
		return route_ref(card_id)
	if tab_id == &"warehouse":
		match filter_id:
			&"warehouse_equipment": return Art09ManifestAssetMappingScript.item_icon_ref(&"equipment")
			&"warehouse_consumable": return Art09ManifestAssetMappingScript.item_icon_ref(&"consumable")
			&"warehouse_collectible": return Art09ManifestAssetMappingScript.item_icon_ref(&"recovered")
			&"warehouse_special": return Art09ManifestAssetMappingScript.deploy_icon_ref(&"compass")
			_: return Art09ManifestAssetMappingScript.deploy_icon_ref(&"backpack")
	if tab_id == &"loadout":
		match filter_id:
			&"loadout_equipment": return Art09ManifestAssetMappingScript.deploy_icon_ref(&"armor")
			&"loadout_consumable": return Art09ManifestAssetMappingScript.item_icon_ref(&"consumable")
			&"loadout_bag": return Art09ManifestAssetMappingScript.deploy_icon_ref(&"backpack")
			&"loadout_permission_interface": return Art09ManifestAssetMappingScript.deploy_icon_ref(&"compass")
			&"loadout_intent": return Art09ManifestAssetMappingScript.deploy_icon_ref(&"compass")
			_: return Art09ManifestAssetMappingScript.deploy_icon_ref(&"bandage")
	return icon_ref(card_id)


static func load_group(visual_key: StringName) -> StringName:
	var key := String(visual_key)
	if key.find(".route.") >= 0:
		return &"deploy_map"
	if key.find(".icon.claim_") >= 0:
		return &"deploy_claim"
	if key.find(".icon.objective_") >= 0:
		return &"deploy_objective"
	if key.find(".danger.") >= 0:
		return &"deploy_active_run"
	if key.find(".modal_") >= 0 or key.ends_with("panel.modal_board"):
		return &"deploy_modal"
	return &"deploy_default"


static func _fallback_asset_id(visual_key: StringName) -> StringName:
	var key := String(visual_key)
	if key.find(".icon.") >= 0 or key.find(".route.") >= 0:
		return &"icon.minimap.explored"
	if key.find(".control.") >= 0:
		return &"ui.common.button.dark"
	if key.find("background") >= 0:
		return &"room.background.normal"
	return &"ui.art19.panel.deploy_main"
