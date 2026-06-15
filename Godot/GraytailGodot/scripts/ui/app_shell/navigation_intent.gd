extends RefCounted
class_name NavigationIntent

const TARGET_MAIN_MENU := &"main_menu"
const TARGET_DEPLOY := &"deploy_placeholder"
const TARGET_LONG_TERM := &"long_term_placeholder"
const TARGET_SETTINGS := &"settings_placeholder"
const TARGET_EXIT := &"exit_game"
const TARGET_RUN := &"run"

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
