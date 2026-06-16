extends RefCounted
class_name PageRouter

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")

const PAGE_MAIN_MENU := &"main_menu"
const PAGE_DEPLOY_PREP := &"deploy_prep"
const PAGE_DEPLOY_PLACEHOLDER := PAGE_DEPLOY_PREP
const PAGE_LONG_TERM_PLACEHOLDER := &"long_term_placeholder"
const PAGE_SETTINGS_PLACEHOLDER := &"settings_placeholder"
const PAGE_EXIT_CONFIRM := &"exit_confirm"
const PAGE_RUN := &"run"


static func route_for_intent(intent: Dictionary) -> Dictionary:
	var target: StringName = NavigationIntentScript.target(intent)
	match target:
		NavigationIntentScript.TARGET_DEPLOY:
			return _route(PAGE_DEPLOY_PREP, intent)
		NavigationIntentScript.TARGET_LONG_TERM:
			return _route(PAGE_LONG_TERM_PLACEHOLDER, intent)
		NavigationIntentScript.TARGET_SETTINGS:
			return _route(PAGE_SETTINGS_PLACEHOLDER, intent)
		NavigationIntentScript.TARGET_EXIT:
			return _route(PAGE_EXIT_CONFIRM, intent)
		NavigationIntentScript.TARGET_RUN:
			return _route(PAGE_RUN, intent)
		_:
			return _route(PAGE_MAIN_MENU, intent)


static func _route(page_id: StringName, intent: Dictionary) -> Dictionary:
	return {
		"page": page_id,
		"intent": intent.duplicate(true),
	}
