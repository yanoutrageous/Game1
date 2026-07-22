extends RefCounted
class_name NavigationIntent

const TARGET_MAIN_MENU := &"main_menu"
const TARGET_DEPLOY := &"deploy_placeholder"
const TARGET_LONG_TERM := &"long_term_placeholder"
const TARGET_SETTINGS := &"settings_placeholder"
const TARGET_EXIT := &"exit_game"
const TARGET_RUN := &"run"
const LONG_TERM_DEFAULT_MODULE := &"task_archive"

const KNOWN_TARGETS := [
	TARGET_MAIN_MENU,
	TARGET_DEPLOY,
	TARGET_LONG_TERM,
	TARGET_SETTINGS,
	TARGET_EXIT,
	TARGET_RUN,
]


static func make(
	target: StringName,
	source: StringName = &"unknown",
	payload: Dictionary = {},
	requires_confirm: bool = false,
	blocked_reason: StringName = &""
) -> Dictionary:
	return {
		"target": target,
		"source": source,
		"payload": payload.duplicate(true),
		"requires_confirm": requires_confirm,
		"blocked_reason": blocked_reason,
	}


static func make_deploy(source: StringName = &"unknown", payload: Dictionary = {}) -> Dictionary:
	var deploy_payload := {
		"tab": StringName(payload.get("tab", &"map")),
		"source_page": StringName(payload.get("source_page", source)),
		"preview_only": bool(payload.get("preview_only", true)),
	}
	for key in payload.keys():
		if not deploy_payload.has(key):
			deploy_payload[key] = payload[key]
	return make(TARGET_DEPLOY, source, deploy_payload)


static func make_long_term(source: StringName = &"unknown", module_id: StringName = LONG_TERM_DEFAULT_MODULE, payload: Dictionary = {}) -> Dictionary:
	var canonical_module_id := normalize_long_term_module_id(module_id)
	var long_term_payload := {
		"module_id": canonical_module_id,
		"entry_id": canonical_module_id,
		"source_page": StringName(payload.get("source_page", source)),
		"preview_only": bool(payload.get("preview_only", true)),
	}
	for key in payload.keys():
		if not long_term_payload.has(key):
			long_term_payload[key] = payload[key]
	return make(TARGET_LONG_TERM, source, long_term_payload)


static func normalize_long_term_module_id(module_id: StringName) -> StringName:
	return LONG_TERM_DEFAULT_MODULE if module_id in [&"goals", &"tasks", &"overview", &""] else module_id


static func make_run(source: StringName = &"unknown", payload: Dictionary = {}) -> Dictionary:
	var run_payload := {
		"entry_id": StringName(payload.get("entry_id", &"quick_start_demo")),
		"entry_label": String(payload.get("entry_label", "快速开始 / Demo Run")),
		"source_page": StringName(payload.get("source_page", source)),
		"playable_route": true,
		"preview_only": false,
	}
	for key in payload.keys():
		if not run_payload.has(key):
			run_payload[key] = payload[key]
	return make(TARGET_RUN, source, run_payload)


static func target(intent: Dictionary) -> StringName:
	return StringName(intent.get("target", TARGET_MAIN_MENU))


static func source(intent: Dictionary) -> StringName:
	return StringName(intent.get("source", &"unknown"))


static func payload(intent: Dictionary) -> Dictionary:
	var raw_payload: Variant = intent.get("payload", {})
	if raw_payload is Dictionary:
		return (raw_payload as Dictionary).duplicate(true)
	return {}


static func requires_confirm(intent: Dictionary) -> bool:
	return bool(intent.get("requires_confirm", false))


static func blocked_reason(intent: Dictionary) -> StringName:
	return StringName(intent.get("blocked_reason", &""))


static func is_known_target(target_id: StringName) -> bool:
	return target_id in KNOWN_TARGETS
