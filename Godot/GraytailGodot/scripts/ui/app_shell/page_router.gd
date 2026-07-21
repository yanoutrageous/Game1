extends RefCounted
class_name PageRouter

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")

const PAGE_MAIN_MENU := &"main_menu"
const PAGE_DEPLOY_PREP := &"deploy_prep"
const PAGE_DEPLOY_PLACEHOLDER := PAGE_DEPLOY_PREP
const PAGE_LONG_TERM := &"long_term"
const PAGE_LONG_TERM_PLACEHOLDER := PAGE_LONG_TERM
const PAGE_SETTINGS_PLACEHOLDER := &"settings_placeholder"
const PAGE_EXIT_CONFIRM := &"exit_confirm"
const PAGE_RUN := &"run"

const SCREEN_MAIN_MENU := &"main_menu"
const SCREEN_DEPLOY := &"deploy_shell"
const SCREEN_LONG_TERM := &"long_term_shell"
const SCREEN_SETTINGS := &"settings_shell"


static func route_for_intent(intent: Dictionary) -> Dictionary:
	var target: StringName = NavigationIntentScript.target(intent)
	match target:
		NavigationIntentScript.TARGET_DEPLOY:
			return _route(PAGE_DEPLOY_PREP, intent)
		NavigationIntentScript.TARGET_LONG_TERM:
			return _route(PAGE_LONG_TERM, intent)
		NavigationIntentScript.TARGET_SETTINGS:
			return _route(PAGE_SETTINGS_PLACEHOLDER, intent)
		NavigationIntentScript.TARGET_EXIT:
			return _route(PAGE_EXIT_CONFIRM, intent)
		NavigationIntentScript.TARGET_RUN:
			return _route(PAGE_RUN, intent)
		_:
			return _route(PAGE_MAIN_MENU, intent)


static func screen_state_for_page(page_id: StringName) -> StringName:
	match page_id:
		PAGE_MAIN_MENU:
			return SCREEN_MAIN_MENU
		PAGE_DEPLOY_PREP:
			return SCREEN_DEPLOY
		PAGE_LONG_TERM:
			return SCREEN_LONG_TERM
		PAGE_SETTINGS_PLACEHOLDER:
			return SCREEN_SETTINGS
		_:
			return &""


static func _route(page_id: StringName, intent: Dictionary) -> Dictionary:
	return {
		"page": page_id,
		"intent": intent.duplicate(true),
	}
