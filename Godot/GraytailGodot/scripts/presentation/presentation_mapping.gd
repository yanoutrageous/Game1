extends RefCounted
class_name PresentationMapping

# PresentationMapping translates public game state into display metadata.
# It is the only layer that maps room/state semantics to asset ids.

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
	&"Chest": &"room.background.chest",
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


static func asset_id_for_minimap_cell(cell: Dictionary, is_player: bool) -> StringName:
	if is_player:
		return &"icon.minimap.player"
	if bool(cell.get("flagged", false)):
		return &"icon.minimap.flag"
	if not bool(cell.get("revealed", false)):
		return &"icon.minimap.unknown"
	if bool(cell.get("cleared", false)):
		return &"icon.room.cleared"

	var adjacent := int(cell.get("adjacent_mines", -1))
	if adjacent >= 1 and adjacent <= 3:
		return StringName("icon.minimap.number.%d" % adjacent)

	var room_type := StringName(cell.get("room_type", &"Unknown"))
	return ROOM_MINIMAP_ASSET.get(room_type, &"icon.room.normal")


static func label_for_minimap_cell(cell: Dictionary, is_player: bool) -> String:
	if is_player:
		return "P"
	if bool(cell.get("flagged", false)):
		return "F"
	if not bool(cell.get("revealed", false)):
		return "?"
	if bool(cell.get("cleared", false)):
		return "C"

	match StringName(cell.get("room_type", &"Unknown")):
		&"Spawn":
			return "G"
		&"Mine":
			return "M"
		&"Chest":
			return "C"
		&"Event":
			return "E"
		&"Monster":
			return "!"
		&"Exit":
			return "X"
		_:
			var adjacent := int(cell.get("adjacent_mines", -1))
			return str(adjacent) if adjacent >= 0 else "."


static func theme_key_for_minimap_cell(cell: Dictionary, is_player: bool) -> StringName:
	if is_player:
		return &"mini.player"
	if bool(cell.get("flagged", false)):
		return &"mini.flag"
	if not bool(cell.get("revealed", false)):
		return &"mini.hidden"
	if int(cell.get("adjacent_mines", -1)) > 0:
		return &"mini.scanned"
	return ROOM_THEME_KEY.get(StringName(cell.get("room_type", &"Unknown")), &"mini.normal")


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
		&"Chest":
			return &"prop.chest.closed"
		_:
			return &""


static func hint_for_snapshot(snapshot: Dictionary) -> String:
	match StringName(snapshot.get("current_room", &"Unknown")):
		&"Exit":
			return "E：请求撤离并确认"
		&"Monster":
			return "Space/J：清理异常体，注意协议压力"
		&"Event":
			return "E：查看事件选项，处理后不会重复结算"
		&"Chest":
			return "E：开启未登记物资箱"
		&"Normal":
			return "E：搜索房间，奖励可能进入背包或落在地面"
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
