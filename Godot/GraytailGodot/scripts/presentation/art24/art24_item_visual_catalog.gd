extends RefCounted
class_name Art24ItemVisualCatalog

const RuntimeTextureCacheScript := preload("res://scripts/presentation/runtime_texture_cache.gd")

# ART24R2 keeps one semantic item-to-texture mapping for every in-run surface.
# Runtime bindings stay on manifest-registered ART24/ART25 outputs while this
# isolated catalog remains free of ContentDB and UI skin dependencies.

const ART24_WORLD_ROOT := "res://assets/art24/items/world/"
const ART25_ITEM_ROOT := "res://assets/ui/art25/content/long_term/item/"
const ART24_WORLD_IDS := [
	"access_key",
	"anomaly_shard",
	"armor_plate",
	"coin_cache",
	"copper_coil",
	"emergency_bandage",
	"salvage_satchel",
	"scanner_probe",
]

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
	return texture_path_for_visual_key(visual_key(item))


static func visual_key(item: Dictionary) -> StringName:
	var item_id := String(item.get("item_id", "")).to_lower()
	if ITEM_TEXTURES.has(item_id):
		var mapped_name := String(ITEM_TEXTURES[item_id]).get_file().get_basename()
		return StringName("visual.art24.item.world_loot.%s" % mapped_name)
	if ART24_WORLD_IDS.has(item_id):
		return StringName("visual.art24.item.world_loot.%s" % item_id)
	if ART25_ITEM_IDS.has(item_id):
		return StringName("art25.long_term.item.%s" % item_id)
	return _fallback_visual_key(_item_type(item))


static func texture_path_for_visual_key(key: StringName) -> String:
	var exact_path := _exact_texture_path_for_visual_key(key)
	if not exact_path.is_empty():
		return exact_path
	return String(TYPE_FALLBACKS["collectible"])


static func _exact_texture_path_for_visual_key(key: StringName) -> String:
	var token := String(key)
	var art24_prefix := "visual.art24.item.world_loot."
	if token.begins_with(art24_prefix):
		var art24_id := token.trim_prefix(art24_prefix)
		if ART24_WORLD_IDS.has(art24_id):
			return ART24_WORLD_ROOT + art24_id + ".png"
	var art25_prefix := "art25.long_term.item."
	if token.begins_with(art25_prefix):
		var art25_id := token.trim_prefix(art25_prefix)
		if ART25_ITEM_IDS.has(art25_id):
			return ART25_ITEM_ROOT + art25_id + ".png"
	return ""


static func resolve(item: Dictionary, consumer: StringName = &"unspecified") -> Dictionary:
	var item_id := String(item.get("item_id", "")).to_lower()
	var item_type := _item_type(item)
	var explicit_mapping := has_explicit_mapping(item_id)
	var requested_key := _requested_visual_key(item_id)
	var requested_path := _exact_texture_path_for_visual_key(requested_key)
	var resolved_key := visual_key(item)
	var resolved_path := _exact_texture_path_for_visual_key(resolved_key)
	var fallback_used := not explicit_mapping
	var reason := &"explicit_mapping" if explicit_mapping else &"item_type_fallback"
	var texture := (
		RuntimeTextureCacheScript.texture(resolved_path)
		if not resolved_path.is_empty()
		else null
	)
	if texture == null:
		var fallback_key := _fallback_visual_key(item_type)
		var fallback_path := _exact_texture_path_for_visual_key(fallback_key)
		if resolved_key != fallback_key or resolved_path != fallback_path:
			resolved_key = fallback_key
			resolved_path = fallback_path
			texture = RuntimeTextureCacheScript.texture(resolved_path)
			fallback_used = true
			reason = &"requested_texture_unresolved"
		elif fallback_used:
			reason = &"fallback_texture_unresolved" if texture == null else reason
		else:
			reason = &"requested_texture_unresolved"
	var texture_size := texture.get_size() if texture != null else Vector2.ZERO
	return {
		"item_id": item_id,
		"item_type": item_type,
		"consumer": consumer,
		"requested_key": requested_key,
		"requested_path": requested_path,
		"resolved_key": resolved_key,
		"resolved_path": resolved_path,
		"resolved_size": texture_size,
		"explicit_mapping": explicit_mapping,
		"fallback_used": fallback_used,
		"reason": reason,
		"texture": texture,
		"resolved": texture != null and texture_size.x > 0.0 and texture_size.y > 0.0,
	}


static func texture_for(item: Dictionary) -> Texture2D:
	return resolve(item).get("texture", null) as Texture2D


static func texture_for_visual_key(key: StringName) -> Texture2D:
	return RuntimeTextureCacheScript.texture(texture_path_for_visual_key(key))


static func has_explicit_mapping(item_id: String) -> bool:
	var normalized_id := item_id.to_lower()
	return (
		ITEM_TEXTURES.has(normalized_id)
		or ART24_WORLD_IDS.has(normalized_id)
		or ART25_ITEM_IDS.has(normalized_id)
	)


static func _requested_visual_key(item_id: String) -> StringName:
	if ITEM_TEXTURES.has(item_id):
		var mapped_name := String(ITEM_TEXTURES[item_id]).get_file().get_basename()
		return StringName("visual.art24.item.world_loot.%s" % mapped_name)
	if ART24_WORLD_IDS.has(item_id):
		return StringName("visual.art24.item.world_loot.%s" % item_id)
	if ART25_ITEM_IDS.has(item_id):
		return StringName("art25.long_term.item.%s" % item_id)
	return StringName("item.request.%s" % (item_id if not item_id.is_empty() else "unknown"))


static func _fallback_visual_key(item_type: String) -> StringName:
	var fallback_path := String(TYPE_FALLBACKS.get(item_type, TYPE_FALLBACKS["collectible"]))
	return StringName("visual.art24.item.world_loot.%s" % fallback_path.get_file().get_basename())


static func _item_type(item: Dictionary) -> String:
	var item_type := String(item.get("item_type", item.get("main_type", "collectible"))).to_lower()
	return item_type if TYPE_FALLBACKS.has(item_type) else "collectible"
