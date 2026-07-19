extends RefCounted
class_name Art24ItemVisualCatalog

# ART24R2 keeps one semantic item-to-texture mapping for every in-run surface.
# This script deliberately has no ContentDB or UI skin dependency so isolated
# gameplay runners can load it without bootstrapping the application shell.

const RECOVERED_ROOT := "res://assets/items/recovered/"
const EQUIPMENT_ROOT := "res://assets/items/equipment/"
const CONSUMABLE_ROOT := "res://assets/items/consumable/"
const LOADOUT_ROOT := "res://assets/items/loadout/"
const LEGACY_WORLD_ROOT := "res://assets/art24/items/world/"

const ITEM_TEXTURES := {
	"eq_old_vest": LEGACY_WORLD_ROOT + "armor_plate.png",
	"eq_edge_opener": EQUIPMENT_ROOT + "item_equipment_flashlight.png",
	"eq_recovery_bag": LEGACY_WORLD_ROOT + "salvage_satchel.png",
	"eq_goggles": EQUIPMENT_ROOT + "item_equipment_goggles.png",
	"eq_signal_pin": LOADOUT_ROOT + "salvage_magnet.png",
	"eq_insulated_sleeve": EQUIPMENT_ROOT + "item_equipment_flashlight.png",
	"con_ration": LEGACY_WORLD_ROOT + "emergency_bandage.png",
	"con_med_patch": CONSUMABLE_ROOT + "item_consumable_medkit.png",
	"con_tape_roll": LEGACY_WORLD_ROOT + "emergency_bandage.png",
	"con_scan_pin": LEGACY_WORLD_ROOT + "scanner_probe.png",
	"con_calm_candy": CONSUMABLE_ROOT + "item_consumable_syringe.png",
	"con_stabilizer": CONSUMABLE_ROOT + "item_consumable_syringe.png",
	"col_01": RECOVERED_ROOT + "item_recovered_ore.png",
	"col_02": LOADOUT_ROOT + "company_badge.png",
	"col_03": RECOVERED_ROOT + "fluorescent_shard.png",
	"col_04": RECOVERED_ROOT + "data_disk.png",
	"col_05": RECOVERED_ROOT + "broken_copper_wire.png",
	"col_06": RECOVERED_ROOT + "dead_battery.png",
	"col_07": RECOVERED_ROOT + "data_disk.png",
	"col_08": RECOVERED_ROOT + "old_gear.png",
	"col_09": RECOVERED_ROOT + "sealed_core_shard.png",
	"col_10": RECOVERED_ROOT + "broken_terminal.png",
	"col_11": RECOVERED_ROOT + "old_gauge.png",
	"col_12": RECOVERED_ROOT + "old_gear.png",
	"col_13": RECOVERED_ROOT + "broken_terminal.png",
	"col_14": RECOVERED_ROOT + "damaged_circuit.png",
	"col_15": RECOVERED_ROOT + "damaged_circuit.png",
	"col_16": RECOVERED_ROOT + "blackbox_tag.png",
	"col_17": LEGACY_WORLD_ROOT + "access_key.png",
	"col_18": RECOVERED_ROOT + "dim_capacitor.png",
	"col_19": RECOVERED_ROOT + "whisper_wick.png",
	"col_20": RECOVERED_ROOT + "anomaly_core_shard.png",
	"col_21": RECOVERED_ROOT + "static_lens.png",
	"col_22": RECOVERED_ROOT + "data_disk.png",
	"col_23": RECOVERED_ROOT + "blackbox_tag.png",
	"col_24": RECOVERED_ROOT + "sealed_core_shard.png",
	"mon_old_gear_set": RECOVERED_ROOT + "old_gear.png",
	"mon_broken_patrol_badge": LOADOUT_ROOT + "company_badge.png",
	"mon_overheated_core": RECOVERED_ROOT + "anomaly_core_shard.png",
	"mon_loader_black_box": RECOVERED_ROOT + "blackbox_tag.png",
	"mon_abnormal_instruction": RECOVERED_ROOT + "data_disk.png",
	"sp_altar_residue": LOADOUT_ROOT + "anomaly_fang.png",
	"sp_trader_receipt": LOADOUT_ROOT + "lucky_coin.png",
}

const TYPE_FALLBACKS := {
	"equipment": LEGACY_WORLD_ROOT + "armor_plate.png",
	"consumable": LEGACY_WORLD_ROOT + "emergency_bandage.png",
	"collectible": RECOVERED_ROOT + "item_recovered_ore.png",
	"special": RECOVERED_ROOT + "anomaly_core_shard.png",
}


static func texture_path(item: Dictionary) -> String:
	var item_id := String(item.get("item_id", "")).to_lower()
	if ITEM_TEXTURES.has(item_id):
		return String(ITEM_TEXTURES[item_id])
	var item_type := String(item.get("item_type", item.get("main_type", "collectible"))).to_lower()
	return String(TYPE_FALLBACKS.get(item_type, TYPE_FALLBACKS["collectible"]))


static func texture_for(item: Dictionary) -> Texture2D:
	return load(texture_path(item)) as Texture2D


static func has_explicit_mapping(item_id: String) -> bool:
	return ITEM_TEXTURES.has(item_id.to_lower())
