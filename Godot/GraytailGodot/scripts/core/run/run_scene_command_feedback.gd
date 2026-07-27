extends RefCounted
class_name RunSceneCommandFeedback

const RunUIViewModel := preload("res://scripts/ui/shell/run_ui_view_model.gd")


static func apply_feedback(
	result: Dictionary,
	run_surface,
	command_result_label: Label,
	inventory_panel,
	ground_loot_panel,
	blocked_flash: Callable
) -> void:
	if run_surface != null:
		run_surface.show_command_feedback(result)
	if command_result_label != null:
		command_result_label.text = "操作提示：%s" % RunUIViewModel.command_result_text(result)
		var accepted: bool = bool(result.get("accepted", result.get("ok", true)))
		if not accepted and blocked_flash.is_valid():
			blocked_flash.call()
	if inventory_panel != null and inventory_panel.visible:
		inventory_panel.call("show_command_result", result)
	if ground_loot_panel != null and ground_loot_panel.visible:
		ground_loot_panel.call("show_command_result", result)


static func route_combat_attack_resolution(
	event: Dictionary,
	event_id: String,
	hit_cue_id: StringName,
	emit_cue: Callable,
	show_feedback: Callable
) -> void:
	if int(event.get("hit_count", 0)) > 0:
		if emit_cue.is_valid():
			emit_cue.call(hit_cue_id, event_id, event)
		return
	if not show_feedback.is_valid():
		return
	if int(event.get("blocked_count", 0)) > 0:
		show_feedback.call({
			"ok": false,
			"status": &"attack_occluded",
			"message": "攻击被障碍挡住。",
		})
		return
	show_feedback.call({
		"ok": false,
		"status": &"attack_missed",
		"message": "攻击未命中。",
	})
