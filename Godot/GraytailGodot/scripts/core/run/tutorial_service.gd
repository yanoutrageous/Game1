extends RefCounted
class_name TutorialService


static func trigger_for(context: RunContext, pos: Vector2i) -> StringName:
	if context == null or context.mode != &"tutorial":
		return &""
	var trigger_id := StringName(context.tutorial_triggers.get(context.cell_key(pos), &""))
	if trigger_id == &"":
		return &""
	if context.tutorial_shown.has(String(trigger_id)):
		return &""
	context.tutorial_shown[String(trigger_id)] = true
	context.tutorial_popup = {
		"id": trigger_id,
		"blocking": true,
		"message": "Tutorial: %s" % String(trigger_id),
	}
	return trigger_id


static func confirm_popup(context: RunContext) -> void:
	if context == null:
		return
	context.tutorial_popup = {}
