extends RefCounted
class_name ContentDeliverySchema

# G34 content delivery preview schema. It describes pool selection results without
# granting rewards, writing assets, or persisting any state.

const SCHEMA_VERSION := 1


static func default_content_pool(pool_id: String = "pool.preview") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"ContentPool",
		"pool_id": pool_id,
		"display_key": "content_pool.%s.label" % pool_id,
		"entries": [default_content_entry()],
		"ContentSelector": default_content_selector(),
		"ContentDeliveryContext": default_content_delivery_context(),
		"FallbackPolicy": default_fallback_policy(),
		"deterministic_seed": 0,
		"filter_reasons": [],
		"applied_modifier_preview": [],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_content_entry(entry_id: String = "entry.preview") -> Dictionary:
	return {
		"schema_kind": &"ContentEntry",
		"entry_id": entry_id,
		"content_id": "",
		"content_kind": &"preview",
		"weight": 1,
		"tags": [],
		"filter_reason": "",
		"blocked_reason": "",
		"result_preview": default_pool_result_preview(),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_content_selector(selector_id: String = "selector.preview") -> Dictionary:
	return {
		"schema_kind": &"ContentSelector",
		"selector_id": selector_id,
		"selection_mode": &"deterministic_roll_preview",
		"seed_ref": &"ContentDeliveryContext.seed",
		"filter_policy": &"reason_code_preview",
		"selected_entries_preview": [],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_content_delivery_context(context_id: String = "delivery.context.preview") -> Dictionary:
	return {
		"schema_kind": &"ContentDeliveryContext",
		"context_id": context_id,
		"source": &"run_local_preview",
		"run_id": "",
		"room_type": &"Unknown",
		"encounter_type": &"none",
		"rule_ref": &"RuleDefinition",
		"modifier_stack_ref": &"ModifierStackPreview",
		"objective_context_preview": _context_placeholder(&"objective_context_preview"),
		"reward_context_preview": _context_placeholder(&"reward_context_preview"),
		"pool_context_preview": _context_placeholder(&"pool_context_preview"),
		"seed": 0,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_pool_result_preview(pool_id: String = "pool.preview") -> Dictionary:
	return {
		"schema_kind": &"PoolResultPreview",
		"pool_id": pool_id,
		"selected_content_ids": [],
		"blocked_entries": [],
		"fallback_used": false,
		"fallback_reason": "",
		"DeliveryRollPreview": default_delivery_roll_preview(),
		"writes_assets": false,
		"grants_reward": false,
		"advances_objective": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_fallback_policy() -> Dictionary:
	return {
		"schema_kind": &"FallbackPolicy",
		"fallback_mode": &"empty_preview_result",
		"fallback_content_id": "",
		"reason_code": &"no_candidate",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func default_delivery_roll_preview(seed: int = 0, roll_index: int = 0) -> Dictionary:
	return {
		"schema_kind": &"DeliveryRollPreview",
		"seed": seed,
		"roll_index": roll_index,
		"roll_value_preview": 0,
		"deterministic": true,
		"filter_reason": "",
		"applied_modifier_record": [],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_content_delivery_preview(pool: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var normalized_pool := normalize_content_pool(pool)
	var delivery_context := _merge(default_content_delivery_context(), context)
	var result_preview := default_pool_result_preview(str(normalized_pool.get("pool_id", "pool.preview")))
	result_preview["DeliveryRollPreview"] = default_delivery_roll_preview(int(delivery_context.get("seed", 0)))
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": &"ContentDeliveryPreview",
		"ContentPool": normalized_pool,
		"ContentSelector": _dictionary_from(normalized_pool.get("ContentSelector", default_content_selector())),
		"ContentDeliveryContext": delivery_context,
		"PoolResultPreview": result_preview,
		"FallbackPolicy": _dictionary_from(normalized_pool.get("FallbackPolicy", default_fallback_policy())),
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func build_registry_pool_preview(snapshot: Dictionary = {}) -> Dictionary:
	var entries: Array = []
	for content_id in snapshot.keys():
		var content_def: Dictionary = _dictionary_from(snapshot[content_id])
		var entry := default_content_entry(str(content_id))
		entry["content_id"] = str(content_id)
		entry["content_kind"] = StringName(content_def.get("kind", &"preview"))
		entry["tags"] = _array_from(content_def.get("tags", []))
		entries.append(entry)
	var pool := default_content_pool("registry.content_defs.preview")
	pool["entries"] = entries
	pool["entry_count"] = entries.size()
	pool["display_key"] = "content_pool.registry.preview"
	return pool


static func normalize_content_pool(data: Dictionary = {}) -> Dictionary:
	var result := _merge(default_content_pool(str(data.get("pool_id", "pool.preview"))), data)
	var normalized_entries: Array = []
	for entry in _array_from(result.get("entries", [])):
		if entry is Dictionary:
			normalized_entries.append(_merge(default_content_entry(str(entry.get("entry_id", "entry.preview"))), entry))
	result["entries"] = normalized_entries
	result["ContentSelector"] = _merge(default_content_selector(), _dictionary_from(result.get("ContentSelector", {})))
	result["ContentDeliveryContext"] = _merge(default_content_delivery_context(), _dictionary_from(result.get("ContentDeliveryContext", {})))
	result["FallbackPolicy"] = _merge(default_fallback_policy(), _dictionary_from(result.get("FallbackPolicy", {})))
	result["read_only"] = true
	result["display_only"] = true
	result["preview"] = true
	result["no_persistence"] = true
	return result


static func validate_content_pool(data: Dictionary = {}) -> Dictionary:
	var warnings: Array[String] = []
	if str(data.get("pool_id", "")).strip_edges() == "":
		warnings.append("missing_pool_id")
	if not bool(data.get("read_only", false)):
		warnings.append("content_pool_must_be_read_only")
	if not bool(data.get("display_only", false)):
		warnings.append("content_pool_must_be_display_only")
	if not bool(data.get("preview", false)):
		warnings.append("content_pool_must_be_preview")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _context_placeholder(context_id: StringName) -> Dictionary:
	return {
		"context_id": context_id,
		"state": &"reserved_preview",
		"read_only": true,
		"display_only": true,
		"preview": true,
		"no_persistence": true,
	}


static func _merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in overlay.keys():
		result[key] = _copy_value(overlay[key])
	return result


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate(true)
	return []


static func _copy_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value
