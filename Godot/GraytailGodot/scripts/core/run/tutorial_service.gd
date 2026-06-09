extends RefCounted
class_name TutorialService

const POPUP_DEFS := {
	&"spawn_intro": {"title": "Training Start", "message": "Read mine counts, explore rooms, then extract.", "blocking": true, "once": true},
	&"number_rule": {"title": "Mine Count", "message": "Numbers show adjacent mines in the eight surrounding rooms.", "blocking": true, "once": true},
	&"mine_rule": {"title": "Mine Room", "message": "Mines hurt once. Re-entering a triggered mine is safe.", "blocking": true, "once": true, "show_after_room_effect": true},
	&"event_rule": {"title": "Event Room", "message": "Events offer trader, dice, altar, or trap outcomes.", "blocking": true, "once": true},
	&"monster_rule": {"title": "Monster Room", "message": "Fight clears a monster. Stronger threats cost HP.", "blocking": true, "once": true},
	&"chest_rule": {"title": "Chest Room", "message": "Chests pay stronger rewards and item-backed parts.", "blocking": true, "once": true},
	&"map_rule": {"title": "Map Overlay", "message": "Use the map to flag hidden rooms or return to explored safe rooms.", "blocking": true, "once": true},
	&"mine_review": {"title": "Mine Review", "message": "Confirmed mine rooms stay marked and do not trigger again.", "blocking": true, "once": true, "show_after_room_effect": true},
	&"route_rule": {"title": "Route Planning", "message": "Plan door transitions from explored rooms toward the exit.", "blocking": true, "once": true},
	&"exit_goal": {"title": "Extract", "message": "Use the exit to request and confirm extraction.", "blocking": true, "once": true},
}


static func trigger_for(context: RunContext, pos: Vector2i) -> StringName:
	if context == null or context.mode != &"tutorial":
		return &""
	var trigger_id := StringName(context.tutorial_triggers.get(context.cell_key(pos), &""))
	if trigger_id == &"":
		return &""
	if context.tutorial_shown.has(String(trigger_id)):
		return &""
	var popup_def: Dictionary = POPUP_DEFS.get(trigger_id, {"title": String(trigger_id), "message": "Tutorial: %s" % String(trigger_id), "blocking": true, "once": true})
	context.tutorial_popup = {
		"id": trigger_id,
		"title": popup_def.get("title", String(trigger_id)),
		"blocking": bool(popup_def.get("blocking", true)),
		"once": bool(popup_def.get("once", true)),
		"show_after_room_effect": bool(popup_def.get("show_after_room_effect", false)),
		"message": String(popup_def.get("message", "Tutorial: %s" % String(trigger_id))),
	}
	return trigger_id


static func confirm_popup(context: RunContext) -> void:
	if context == null:
		return
	var popup_id := String(context.tutorial_popup.get("id", ""))
	if popup_id != "" and bool(context.tutorial_popup.get("once", true)):
		context.tutorial_shown[popup_id] = true
	context.tutorial_popup = {}
