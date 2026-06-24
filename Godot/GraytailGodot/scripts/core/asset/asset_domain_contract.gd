extends RefCounted
class_name AssetDomainContract

const SCHEMA_VERSION := 1

const ASSET_REF_KIND := &"AssetRef"
const ASSET_CATEGORY_KIND := &"AssetCategory"
const ASSET_TAG_KIND := &"AssetTag"
const ASSET_POLICY_KIND := &"AssetPolicy"
const REWARD_BUNDLE_KIND := &"RewardBundlePreview"
const RESOURCE_EVENT_KIND := &"ResourceEventPreview"
const ITEM_EVENT_KIND := &"ItemEventPreview"
const UNLOCK_EVENT_KIND := &"UnlockEventPreview"
const HISTORY_RECORD_EVENT_KIND := &"HistoryRecordEventPreview"
const OBJECTIVE_EVENT_KIND := &"ObjectiveEventPreview"
const RED_DOT_POLICY_KIND := &"RedDotPolicyPreview"
const JUMP_TARGET_KIND := &"JumpTargetPreview"

const CATEGORY_ITEM := &"item"
const CATEGORY_RESOURCE := &"resource"
const CATEGORY_COLLECTIBLE := &"collectible"
const CATEGORY_SPECIAL := &"special"
const CATEGORY_COSMETIC_UNLOCK := &"cosmetic_unlock"
const CATEGORY_RECORD_UNLOCK := &"record_unlock"
const CATEGORIES := [
	CATEGORY_ITEM,
	CATEGORY_RESOURCE,
	CATEGORY_COLLECTIBLE,
	CATEGORY_SPECIAL,
	CATEGORY_COSMETIC_UNLOCK,
	CATEGORY_RECORD_UNLOCK,
]

const POLICY_DISPLAY_ONLY := &"display_only"
const POLICY_ALLOWED_PREVIEW := &"allowed_preview"
const POLICY_BLOCKED_REAL_ACTION := &"blocked_real_action"

const RED_DOT_MODULE_OPEN := &"open_module"
const RED_DOT_VIEW_ENTRY := &"view_entry"
const RED_DOT_REWARD_STATE := &"reward_state_preview"
const RED_DOT_MANUAL_CLEAR := &"manual_clear_preview"


static func boundary_flags() -> Dictionary:
	return {
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_asset_ref(asset_id: String = "", category: StringName = CATEGORY_ITEM) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_REF_KIND,
		"asset_id": asset_id,
		"definition_id": asset_id,
		"instance_id": "",
		"category": category,
		"display_key": "asset.%s" % asset_id if not asset_id.is_empty() else "asset.preview",
		"source_context_id": "",
		"state_tags": [],
		"quantity": 1,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_category(category_id: StringName = CATEGORY_ITEM) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_CATEGORY_KIND,
		"category_id": category_id,
		"display_key": "asset.category.%s" % str(category_id),
		"description_key": "asset.category.%s.description" % str(category_id),
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_tag(tag_id: String = "", tag_type: StringName = &"state") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_TAG_KIND,
		"tag_id": tag_id,
		"tag_type": tag_type,
		"display_key": "asset.tag.%s" % tag_id if not tag_id.is_empty() else "asset.tag.preview",
		"source_context_id": "",
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_policy(policy_id: StringName = POLICY_DISPLAY_ONLY) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": ASSET_POLICY_KIND,
		"policy_id": policy_id,
		"display_key": "asset.policy.%s" % str(policy_id),
		"can_show": true,
		"can_filter": true,
		"can_reference": true,
		"can_mutate_asset": false,
		"can_write_warehouse": false,
		"can_grant_reward": false,
		"can_run_gacha": false,
		"can_write_settlement": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
	}


static func default_reward_bundle_preview(bundle_id: String = "reward.bundle.preview", source_system: StringName = &"long_term") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": REWARD_BUNDLE_KIND,
		"bundle_id": bundle_id,
		"source_system": source_system,
		"summary": "RewardBundle preview describes reward intent only.",
		"resource_events_preview": [default_resource_event_preview()],
		"item_events_preview": [default_item_event_preview()],
		"unlock_events_preview": [default_unlock_event_preview()],
		"history_record_events_preview": [default_history_record_event_preview()],
		"objective_events_preview": [default_objective_event_preview()],
		"reward_state_preview": {
			"state": &"preview_only",
			"claim_state": &"display_only",
			"claimable": false,
			"claimed": false,
			"message": "Reward state is shown only; no claim or delivery occurs.",
		},
		"red_dot_policy": default_red_dot_policy(),
		"jump_targets": [
			default_jump_target(&"warehouse", "Open warehouse reference preview"),
			default_jump_target(&"codex", "Open codex reference preview"),
		],
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
		"no_persistence": true,
		"no_asset_write": true,
		"no_reward_grant": true,
		"no_event_dispatch": true,
	}


static func default_resource_event_preview(event_id: String = "resource.event.preview") -> Dictionary:
	return _event_preview(RESOURCE_EVENT_KIND, event_id, &"resource", "ResourceEvent preview only.")


static func default_item_event_preview(event_id: String = "item.event.preview") -> Dictionary:
	return _event_preview(ITEM_EVENT_KIND, event_id, &"item", "ItemEvent preview only.")


static func default_unlock_event_preview(event_id: String = "unlock.event.preview") -> Dictionary:
	return _event_preview(UNLOCK_EVENT_KIND, event_id, &"unlock", "UnlockEvent preview only.")


static func default_history_record_event_preview(event_id: String = "history.record.event.preview") -> Dictionary:
	return _event_preview(HISTORY_RECORD_EVENT_KIND, event_id, &"history_record", "HistoryRecordEvent preview only.")


static func default_objective_event_preview(event_id: String = "objective.event.preview") -> Dictionary:
	return _event_preview(OBJECTIVE_EVENT_KIND, event_id, &"objective", "ObjectiveEvent preview only.")


static func default_red_dot_policy(policy_id: StringName = &"red_dot.preview") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": RED_DOT_POLICY_KIND,
		"policy_id": policy_id,
		"allowed_reasons": [
			&"objective_ready",
			&"codex_new",
			&"research_available",
			&"profile_reward_preview",
			&"history_unread",
			&"gacha_result_unread",
			&"collection_new",
			&"warehouse_new_asset",
		],
		"not_recommended_reasons": [
			&"currency_sufficient_only",
			&"shop_refresh_only",
			&"hidden_objective_incomplete",
			&"already_viewed",
		],
		"clear_policy_preview": [
			RED_DOT_MODULE_OPEN,
			RED_DOT_VIEW_ENTRY,
			RED_DOT_REWARD_STATE,
			RED_DOT_MANUAL_CLEAR,
		],
		"can_clear": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
		"no_persistence": true,
	}


static func default_jump_target(target_id: StringName = &"long_term", label: String = "Jump target preview") -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": JUMP_TARGET_KIND,
		"target_id": target_id,
		"label": label,
		"entry_mode": &"display_only",
		"return_target": &"long_term",
		"display_condition": &"preview",
		"locked_reason": "",
		"can_execute": false,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
	}


static func normalize_asset_ref(data: Dictionary = {}) -> Dictionary:
	var result := default_asset_ref()
	_merge_known(result, data)
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = ASSET_REF_KIND
	result["asset_id"] = str(result.get("asset_id", ""))
	result["definition_id"] = str(result.get("definition_id", result.get("asset_id", "")))
	result["instance_id"] = str(result.get("instance_id", ""))
	result["category"] = StringName(result.get("category", CATEGORY_ITEM))
	result["display_key"] = str(result.get("display_key", "asset.preview"))
	result["state_tags"] = _array_from(result.get("state_tags", []))
	result["quantity"] = max(0, int(result.get("quantity", 1)))
	_apply_boundary_flags(result)
	return result


static func validate_asset_ref(data: Dictionary) -> Dictionary:
	var normalized := normalize_asset_ref(data)
	var warnings: Array[String] = []
	if not CATEGORIES.has(StringName(normalized.get("category", &""))):
		warnings.append("unknown_asset_category")
	if str(normalized.get("asset_id", "")).is_empty() and str(normalized.get("definition_id", "")).is_empty():
		warnings.append("missing_asset_identifier")
	if not bool(normalized.get("read_only", false)):
		warnings.append("asset_ref_must_be_read_only")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func normalize_policy(data: Dictionary = {}) -> Dictionary:
	var result := default_policy()
	_merge_known(result, data)
	result["policy_id"] = StringName(result.get("policy_id", POLICY_DISPLAY_ONLY))
	_apply_boundary_flags(result)
	result["can_mutate_asset"] = false
	result["can_write_warehouse"] = false
	result["can_grant_reward"] = false
	result["can_run_gacha"] = false
	result["can_write_settlement"] = false
	return result


static func normalize_reward_bundle_preview(data: Dictionary = {}) -> Dictionary:
	var result := default_reward_bundle_preview()
	_merge_known(result, data)
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = REWARD_BUNDLE_KIND
	result["bundle_id"] = str(result.get("bundle_id", "reward.bundle.preview"))
	result["source_system"] = StringName(result.get("source_system", &"long_term"))
	result["resource_events_preview"] = _array_from(result.get("resource_events_preview", []))
	result["item_events_preview"] = _array_from(result.get("item_events_preview", []))
	result["unlock_events_preview"] = _array_from(result.get("unlock_events_preview", []))
	result["history_record_events_preview"] = _array_from(result.get("history_record_events_preview", []))
	result["objective_events_preview"] = _array_from(result.get("objective_events_preview", []))
	result["red_dot_policy"] = normalize_red_dot_policy(_dictionary_from(result.get("red_dot_policy", {})))
	result["jump_targets"] = _normalize_jump_targets(result.get("jump_targets", []))
	_apply_boundary_flags(result)
	result["preview_only"] = true
	result["no_persistence"] = true
	result["no_asset_write"] = true
	result["no_reward_grant"] = true
	result["no_event_dispatch"] = true
	return result


static func normalize_red_dot_policy(data: Dictionary = {}) -> Dictionary:
	var result := default_red_dot_policy()
	_merge_known(result, data)
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = RED_DOT_POLICY_KIND
	result["policy_id"] = StringName(result.get("policy_id", &"red_dot.preview"))
	result["allowed_reasons"] = _array_from(result.get("allowed_reasons", []))
	result["not_recommended_reasons"] = _array_from(result.get("not_recommended_reasons", []))
	result["clear_policy_preview"] = _array_from(result.get("clear_policy_preview", []))
	result["can_clear"] = false
	_apply_boundary_flags(result)
	result["preview_only"] = true
	result["no_persistence"] = true
	return result


static func normalize_jump_target(data: Dictionary = {}) -> Dictionary:
	var result := default_jump_target()
	_merge_known(result, data)
	result["schema_version"] = SCHEMA_VERSION
	result["schema_kind"] = JUMP_TARGET_KIND
	result["target_id"] = StringName(result.get("target_id", &"long_term"))
	result["label"] = str(result.get("label", "Jump target preview"))
	result["entry_mode"] = StringName(result.get("entry_mode", &"display_only"))
	result["can_execute"] = false
	_apply_boundary_flags(result)
	result["preview_only"] = true
	return result


static func validate_reward_bundle_preview(data: Dictionary) -> Dictionary:
	var bundle := normalize_reward_bundle_preview(data)
	var warnings: Array[String] = []
	if str(bundle.get("bundle_id", "")).is_empty():
		warnings.append("missing_bundle_id")
	if not bool(bundle.get("read_only", false)):
		warnings.append("reward_bundle_must_be_read_only")
	if not bool(bundle.get("no_reward_grant", false)):
		warnings.append("reward_bundle_must_not_deliver_rewards")
	if not bool(bundle.get("no_asset_write", false)):
		warnings.append("reward_bundle_must_not_write_assets")
	return {"ok": warnings.is_empty(), "warnings": warnings}


static func _event_preview(schema_kind: StringName, event_id: String, event_type: StringName, summary: String) -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"schema_kind": schema_kind,
		"event_id": event_id,
		"event_type": event_type,
		"source_system": &"preview",
		"source_context_id": "preview.long_term",
		"asset_refs": [],
		"resource_refs": [],
		"unlock_refs": [],
		"objective_refs": [],
		"summary": summary,
		"read_only": true,
		"display_only": true,
		"preview": true,
		"preview_only": true,
		"no_persistence": true,
		"no_asset_write": true,
		"no_reward_grant": true,
		"no_event_dispatch": true,
	}


static func _normalize_jump_targets(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for entry in value:
		if entry is Dictionary:
			result.append(normalize_jump_target(entry))
	return result


static func _dictionary_from(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {}


static func _merge_known(target: Dictionary, source: Dictionary) -> void:
	for key in source.keys():
		target[key] = _copy_value(source[key])


static func _apply_boundary_flags(target: Dictionary) -> void:
	target["read_only"] = true
	target["display_only"] = true
	target["preview"] = true


static func _array_from(value: Variant) -> Array:
	if value is Array:
		return value.duplicate(true)
	return []


static func _copy_value(value: Variant) -> Variant:
	if (value is Dictionary) or (value is Array):
		return value.duplicate(true)
	return value
