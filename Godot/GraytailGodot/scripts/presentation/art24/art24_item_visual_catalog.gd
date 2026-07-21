extends RefCounted
class_name Art24ItemVisualCatalog

const RuntimeTextureCacheScript := preload("res://scripts/presentation/runtime_texture_cache.gd")

# ART24R2 keeps one semantic item-to-texture mapping for every in-run surface.
# Runtime bindings stay on manifest-registered ART24/ART25 outputs while this
# isolated catalog remains free of ContentDB and UI skin dependencies.

const ART24_WORLD_ROOT := "res://assets/art24/items/world/"
const ART25_ITEM_ROOT := "res://assets/ui/art25/content/long_term/item/"

const ART25_ITEM_IDS := [
	"eq_old_vest",
	"eq_edge_opener",
	"eq_recovery_bag",
	"eq_goggles",
	"eq_signal_pin",
	"eq_insulated_sleeve",
	"con_ration",
	"con_med_patch",
	"con_tape_roll",
	"con_scan_pin",
	"con_calm_candy",
	"con_stabilizer",
	"col_01",
	"col_02",
	"col_03",
	"col_04",
	"col_05",
	"col_06",
	"col_07",
	"col_08",
	"col_09",
	"col_10",
	"col_11",
	"col_12",
	"col_13",
	"col_14",
	"col_15",
	"col_16",
	"col_17",
	"col_18",
	"col_19",
	"col_20",
	"col_21",
	"col_22",
	"col_23",
	"col_24",
	"mon_old_gear_set",
	"mon_broken_patrol_badge",
	"mon_overheated_core",
	"mon_loader_black_box",
	"mon_abnormal_instruction",
	"sp_altar_residue",
]

const ITEM_TEXTURES := {
	# ART25 has no dedicated trader-receipt output. The audited ART24 coin cache
	# preserves the currency/receipt meaning without reopening an unregistered
	# raw source binding.
	"sp_trader_receipt": ART24_WORLD_ROOT + "coin_cache.png",
}

const TYPE_FALLBACKS := {
	"equipment": ART24_WORLD_ROOT + "armor_plate.png",
	"consumable": ART24_WORLD_ROOT + "emergency_bandage.png",
	"collectible": ART24_WORLD_ROOT + "salvage_satchel.png",
	"special": ART24_WORLD_ROOT + "anomaly_shard.png",
}


static func texture_path(item: Dictionary) -> String:
	var item_id := String(item.get("item_id", "")).to_lower()
	if ITEM_TEXTURES.has(item_id):
		return String(ITEM_TEXTURES[item_id])
	if ART25_ITEM_IDS.has(item_id):
		return ART25_ITEM_ROOT + item_id + ".png"
	var item_type := String(item.get("item_type", item.get("main_type", "collectible"))).to_lower()
	return String(TYPE_FALLBACKS.get(item_type, TYPE_FALLBACKS["collectible"]))


static func texture_for(item: Dictionary) -> Texture2D:
	return RuntimeTextureCacheScript.texture(texture_path(item))


static func has_explicit_mapping(item_id: String) -> bool:
	var normalized_id := item_id.to_lower()
	return ITEM_TEXTURES.has(normalized_id) or ART25_ITEM_IDS.has(normalized_id)
