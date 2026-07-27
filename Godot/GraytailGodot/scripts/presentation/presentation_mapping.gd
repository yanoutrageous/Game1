extends RefCounted
class_name PresentationMapping

# PresentationMapping translates public game state into display metadata.
# It is the only layer that maps room/state semantics to asset ids.

const Art09ManifestAssetMappingScript := preload("res://scripts/presentation/art09_manifest_asset_mapping.gd")
const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")

const ROOM_MINIMAP_ASSET := {
	&"Spawn": &"icon.room.spawn",
	&"Normal": &"icon.room.normal",
	&"Mine": &"icon.room.mine",
	&"Chest": &"icon.room.chest",
	&"Event": &"icon.room.event",
	&"Monster": &"icon.room.monster",
	&"Exit": &"icon.room.exit",
}

const ROOM_BACKGROUND_ASSET := {
	&"Spawn": &"room.background.normal",
	&"Normal": &"room.background.normal",
	&"Mine": &"room.background.mine",
	# Chest rooms use the neutral plate plus one dynamic projected chest.  The
	# legacy chest background already contains a baked prop and would duplicate it.
	&"Chest": &"room.background.normal",
	&"Event": &"room.background.event",
	&"Monster": &"room.background.monster",
	&"Exit": &"room.background.exit",
}

const ROOM_THEME_KEY := {
	&"Spawn": &"mini.player",
	&"Normal": &"mini.normal",
	&"Mine": &"mini.mine",
	&"Chest": &"mini.chest",
	&"Event": &"mini.event",
	&"Monster": &"mini.monster",
	&"Exit": &"mini.exit",
}


static func minimap_marker_from_cell(cell: Dictionary, player_pos: Vector2i) -> Dictionary:
	var marker := cell.duplicate(true)
	var pos: Vector2i = marker.get("pos", Vector2i.ZERO)
	var is_player := pos == player_pos
	var room_type := StringName(marker.get("room_type", &"Unknown"))
	var adjacent := int(marker.get("adjacent_mines", -1))

	marker["asset_id"] = asset_id_for_minimap_cell(marker, is_player)
	marker["label"] = label_for_minimap_cell(marker, is_player)
	marker["theme_key"] = theme_key_for_minimap_cell(marker, is_player)
	marker["tooltip"] = tooltip_for_cell(room_type, adjacent, bool(marker.get("flagged", false)), bool(marker.get("revealed", false)))
	return marker


static func map_marker_state(marker: Dictionary) -> StringName:
	# Both the HUD minimap and expanded map consume this public semantic state.
	# Keep the visibility gate here so a renderer cannot accidentally distinguish
	# a hidden Mine from a hidden Monster by inspecting room_type directly.
	if bool(marker.get("is_current", false)):
		return &"player"
	if bool(marker.get("flagged", false)):
		return &"flagged"
	var known_state := StringName(marker.get("known_state", marker.get("state", &"unknown")))
	var room_type := StringName(marker.get("room_type", &"Unknown"))
	var publicly_revealed := bool(marker.get("revealed", false)) or bool(marker.get("explored", false)) or known_state in [&"explored", &"cleared"]
	var publicly_scanned := bool(marker.get("scanned", false)) or known_state == &"scanned"
	if not publicly_revealed and room_type != &"Exit":
		return &"scanned" if publicly_scanned else &"unknown"
	match room_type:
		&"Mine":
			return &"mine"
		&"Monster":
			return &"monster"
		&"Chest":
			return &"chest"
		&"Event":
			return &"event"
		&"Exit":
			return &"exit"
	return &"scanned" if publicly_scanned and not publicly_revealed else &"explored"


static func public_adjacent_mines(marker: Dictionary) -> int:
	var known_state := StringName(marker.get("known_state", marker.get("state", &"unknown")))
	var publicly_known := bool(marker.get("revealed", false)) or bool(marker.get("scanned", false)) or known_state in [&"scanned", &"explored", &"cleared"]
	var adjacent := int(marker.get("adjacent_mines", -1))
	if not publicly_known or adjacent < 0 or adjacent > 8:
		return -1
	return adjacent


static func asset_id_for_minimap_cell(cell: Dictionary, is_player: bool) -> StringName:
	var marker := cell.duplicate(true)
	marker["is_current"] = is_player
	match map_marker_state(marker):
		&"player":
			return &"icon.minimap.player"
		&"flagged":
			return &"icon.minimap.flag"
		&"unknown":
			return &"icon.minimap.unknown"
		&"scanned":
			return &"icon.minimap.scanned"
		&"mine":
			return ROOM_MINIMAP_ASSET[&"Mine"]
		&"monster":
			return ROOM_MINIMAP_ASSET[&"Monster"]
		&"chest":
			return ROOM_MINIMAP_ASSET[&"Chest"]
		&"event":
			return ROOM_MINIMAP_ASSET[&"Event"]
		&"exit":
			return ROOM_MINIMAP_ASSET[&"Exit"]
		_:
			return &"icon.minimap.explored"


static func label_for_minimap_cell(cell: Dictionary, is_player: bool) -> String:
	var marker := cell.duplicate(true)
	marker["is_current"] = is_player
	match map_marker_state(marker):
		&"player":
			return "P"
		&"flagged":
			return "F"
		&"unknown":
			return "?"
		&"scanned":
			var adjacent := public_adjacent_mines(marker)
			return str(adjacent) if adjacent >= 0 else "S"
		&"mine":
			return "M"
		&"monster":
			return "!"
		&"chest":
			return "C"
		&"event":
			return "E"
		&"exit":
			return "X"
		_:
			return "C" if bool(marker.get("cleared", false)) else "."


static func theme_key_for_minimap_cell(cell: Dictionary, is_player: bool) -> StringName:
	var marker := cell.duplicate(true)
	marker["is_current"] = is_player
	match map_marker_state(marker):
		&"player":
			return &"mini.player"
		&"flagged":
			return &"mini.flag"
		&"unknown":
			return &"mini.hidden"
		&"scanned":
			return &"mini.scanned"
	return ROOM_THEME_KEY.get(StringName(marker.get("room_type", &"Unknown")), &"mini.normal")


static func tooltip_for_cell(room_type: StringName, adjacent_mines: int, flagged: bool, revealed: bool) -> String:
	if flagged:
		return "已标记：疑似危险房间"
	if not revealed:
		return "未知房间：点击可标记"
	return "%s | 周围雷险：%d" % [_room_type_label(room_type), adjacent_mines]


static func room_visual_from_snapshot(snapshot: Dictionary) -> Dictionary:
	var room_type := StringName(snapshot.get("current_room", &"Unknown"))
	var adjacent := int(snapshot.get("adjacent_mines", 0))
	return {
		"room_type": room_type,
		"background_asset_id": ROOM_BACKGROUND_ASSET.get(room_type, &"room.background.normal"),
		"prop_asset_id": prop_asset_for_room(room_type),
		"theme_key": ROOM_THEME_KEY.get(room_type, &"mini.normal"),
		"title": _room_type_label(room_type),
		"hint": hint_for_snapshot(snapshot),
		"risk_key": PresentationTheme.risk_key(adjacent, room_type),
	}


static func prop_asset_for_room(room_type: StringName) -> StringName:
	match room_type:
		&"Mine":
			return &"prop.mine.trap"
		_:
			return &""


static func main_menu_background_ref() -> Dictionary:
	return Art09ManifestAssetMappingScript.main_menu_background_ref()


static func player_sprite_ref(state: StringName = &"idle") -> Dictionary:
	return Art09ManifestAssetMappingScript.player_sprite_ref(state)


static func main_menu_entry_icon_ref(entry_id: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.main_menu_entry_icon_ref(entry_id)


static func deploy_prep_asset_refs() -> Dictionary:
	return Art09ManifestAssetMappingScript.deploy_prep_asset_refs()


static func deploy_tab_icon_ref(tab_id: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.deploy_tab_icon_ref(tab_id)


static func deploy_card_asset_ref(card_id: StringName, category: String, filter_id: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.deploy_card_asset_ref(card_id, category, filter_id)


static func inventory_item_icon_ref(item: Dictionary) -> Dictionary:
	return Art09ManifestAssetMappingScript.inventory_item_icon_ref(item)


static func feedback_bar_ref(state: StringName = &"neutral") -> Dictionary:
	return Art09ManifestAssetMappingScript.feedback_bar_ref(state)


static func feedback_panel_ref(state: StringName = &"event") -> Dictionary:
	return Art09ManifestAssetMappingScript.feedback_panel_ref(state)


static func result_title_ref(state: StringName = &"success") -> Dictionary:
	return Art09ManifestAssetMappingScript.result_title_ref(state)


static func panel_ref(role: StringName = &"terminal") -> Dictionary:
	return Art09ManifestAssetMappingScript.panel_ref(role)


static func key_prompt_ref(action_id: StringName, rendered: bool = false) -> Dictionary:
	return Art09ManifestAssetMappingScript.key_prompt_ref(action_id, rendered)


static func art19_skin_ref(role: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.art19_skin_ref(role)


static func art19_map64_ref(state: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.art19_map64_ref(state)


static func art20_component_ref(visual_key: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.art20_component_ref(visual_key)


static func art20_keycap_ref(action_id: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.art20_keycap_ref(action_id)


static func art20_main_menu_background_ref() -> Dictionary:
	return Art09ManifestAssetMappingScript.art20_main_menu_background_ref()


static func art20_deploy_icon_ref(kind: StringName) -> Dictionary:
	return Art09ManifestAssetMappingScript.art20_deploy_icon_ref(kind)


static func hint_for_snapshot(snapshot: Dictionary) -> String:
	var interact_hint := SemanticActionHintScript.display_label(&"interact")
	var attack_hint := SemanticActionHintScript.display_label(&"attack")
	match StringName(snapshot.get("current_room", &"Unknown")):
		&"Exit":
			return "%s：请求撤离并确认" % interact_hint
		&"Monster":
			return "%s：清理异常体，注意协议压力" % attack_hint
		&"Event":
			return "%s：查看事件选项，处理后不会重复结算" % interact_hint
		&"Chest":
			return "%s：开启未登记物资箱" % interact_hint
		&"Normal":
			return "%s：搜索房间，奖励可能进入背包或落在地面" % interact_hint
		&"Mine":
			return "雷险已确认，谨慎移动"
		_:
			return "移动 / 搜索 / 区域扫描"


static func _room_type_label(room_type: StringName) -> String:
	match room_type:
		&"Spawn":
			return "出发点"
		&"Normal":
			return "普通房间"
		&"Mine":
			return "雷险房间"
		&"Chest":
			return "物资箱房间"
		&"Event":
			return "事件房间"
		&"Monster":
			return "异常体房间"
		&"Exit":
			return "撤离点"
		_:
			return String(room_type)
