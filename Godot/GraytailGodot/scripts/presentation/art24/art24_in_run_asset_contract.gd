extends RefCounted
class_name Art24InRunAssetContract

const PREFIX := "visual.art24."

const ROOM_PATHS := {
	"normal": "res://assets/rooms/room_normal.png",
	"mine": "res://assets/rooms/room_mine.png",
	"chest": "res://assets/rooms/room_normal.png",
	"event": "res://assets/rooms/room_event.png",
	"monster": "res://assets/rooms/room_monster.png",
	"exit": "res://assets/rooms/room_exit.png",
}

const PROP_PATHS := {
	"chest_closed": "res://assets/props/chest_closed.png",
	"chest_open": "res://assets/props/chest_closed.png",
	"chest_open_state": "res://assets/props/chest_closed.png",
	"mine": "res://assets/props/mine_trap.png",
	"event": "res://assets/props/art07/05_yichang_hexin.png",
	"merchant": "res://assets/props/art07/04_shangren_tai.png",
	"extract_inactive": "res://assets/props/art07/01_cheli_zhuangzhi_an.png",
	"extract_active": "res://assets/props/art07/02_cheli_zhuangzhi_liang.png",
}

const PLAYER_MOTIONS := [&"idle_a", &"idle_b", &"walk_a", &"walk_b", &"hit", &"interact", &"attack_windup", &"attack_swing", &"attack_impact", &"attack_recover"]
const PLAYER_FACINGS := [&"down", &"left", &"right", &"up"]
const MONSTER_STATES := [&"idle_a", &"idle_b", &"appear", &"attack_windup", &"attack_impact", &"hit", &"defeated", &"remains"]
const LOOT_STATES := [&"emergency_bandage", &"copper_coil", &"scanner_probe", &"armor_plate", &"coin_cache", &"anomaly_shard", &"access_key", &"salvage_satchel"]


static func texture(visual_key: StringName) -> Texture2D:
	var path := path_for(visual_key)
	if path.is_empty() or not ResourceLoader.exists(path):
		path = fallback_path(visual_key)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func path_for(visual_key: StringName) -> String:
	var key := String(visual_key)
	if not key.begins_with(PREFIX):
		return ""
	var tail := key.trim_prefix(PREFIX)
	if tail.begins_with("room."):
		return String(ROOM_PATHS.get(tail.get_slice(".", 1), ROOM_PATHS["normal"]))
	if tail.begins_with("prop."):
		return String(PROP_PATHS.get(tail.get_slice(".", 1), ""))
	if tail.begins_with("actor.player."):
		var facing := tail.get_slice(".", 2)
		var motion := tail.get_slice(".", 3)
		return "res://assets/art24/actors/player/%s_%s.png" % [facing, motion]
	if tail.begins_with("actor.ironback."):
		return "res://assets/art24/actors/ironback/%s.png" % tail.get_slice(".", 2)
	for subject in ["slime", "bat", "drone"]:
		if tail.begins_with("actor.%s.ue_" % subject):
			return "res://assets/art24/actors/%s/%s.png" % [subject, tail.get_slice(".", 2)]
		if tail.begins_with("actor.%s.variant." % subject):
			return "res://assets/art24/actors/%s/%s.png" % [subject, tail.get_slice(".", 3)]
	if tail.begins_with("item.world_loot."):
		return "res://assets/art24/items/world/%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.protocol.level_"):
		return "res://assets/art24/ui/protocol/%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.item_row."):
		return "res://assets/art24/ui/item_row_%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.item_slot."):
		return "res://assets/art24/ui/item_slot_%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.tooltip."):
		return "res://assets/art24/ui/tooltip_%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.toast."):
		return "res://assets/art24/ui/toast_%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.result_banner."):
		return "res://assets/art24/ui/result_banner_%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.keycap."):
		return "res://assets/art24/ui/keycap_%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.map_tile."):
		return "res://assets/art24/ui/map_tile_%s.png" % tail.get_slice(".", 2)
	if tail.begins_with("ui.ue."):
		return "res://assets/art24/ui/ue/%s.png" % tail.get_slice(".", 2)
	if tail == "ui.left_rail":
		return "res://assets/art24/ui/left_rail.png"
	if tail == "ui.bottom_bar":
		return "res://assets/art24/ui/bottom_bar.png"
	if tail == "ui.map_frame":
		return "res://assets/art24/ui/map_frame.png"
	if tail == "ui.modal_frame":
		return "res://assets/art24/ui/modal_frame.png"
	if tail.begins_with("fx.ue_"):
		return "res://assets/art24/fx/%s.png" % tail.get_slice(".", 1)
	if tail.begins_with("fx."):
		var family := tail.get_slice(".", 1)
		var frame := tail.get_slice(".", 2)
		return "res://assets/art24/fx/%s_%s.png" % [family, frame]
	return ""


static func fallback_path(visual_key: StringName) -> String:
	var key := String(visual_key)
	if key.contains("actor.player"):
		return "res://assets/art24/actors/player/down_idle_a.png"
	if key.contains("actor.ironback"):
		return "res://assets/art24/actors/ironback/idle_a.png"
	if key.contains("actor.slime"):
		return "res://assets/art24/actors/slime/ue_idle.png"
	if key.contains("actor.bat"):
		return "res://assets/art24/actors/bat/ue_idle_0.png"
	if key.contains("actor.drone"):
		return "res://assets/art24/actors/drone/ue_idle_0.png"
	if key.contains("world_loot"):
		return "res://assets/art24/items/world/salvage_satchel.png"
	if key.contains("ui.map_tile"):
		return "res://assets/art24/ui/map_tile_unknown.png"
	if key.contains("ui"):
		return "res://assets/art24/ui/modal_frame.png"
	return "res://assets/rooms/room_normal.png"
