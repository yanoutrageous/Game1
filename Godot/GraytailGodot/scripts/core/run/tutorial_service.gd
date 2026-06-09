extends RefCounted
class_name TutorialService

const POPUP_DEFS := {
	&"spawn_intro": {"title": "训练开始", "message": "左上角查看雷险数字，WASD 在房间内移动，抵达出口后撤离。", "blocking": true, "once": true},
	&"number_rule": {"title": "雷险数字", "message": "数字表示周围 8 个房间内的地雷数量。异常体、物资箱、事件和信标不计入。", "blocking": true, "once": true},
	&"mine_rule": {"title": "地雷房间", "message": "地雷只会伤害一次。触发后再次进入该房间不会重复爆炸。", "blocking": true, "once": true, "show_after_room_effect": true},
	&"event_rule": {"title": "事件房间", "message": "事件可能是旅商、骰局、祭坛或机关。按 E 查看选项。", "blocking": true, "once": true},
	&"monster_rule": {"title": "异常体", "message": "Space/J 处理异常体。战力不足时会损失生命。", "blocking": true, "once": true},
	&"chest_rule": {"title": "物资箱", "message": "物资箱提供更高回收收益。按 E 开启。", "blocking": true, "once": true},
	&"map_rule": {"title": "区域扫描图", "message": "按 M 打开地图。隐藏格可插旗，已探索安全格可快速返回。", "blocking": true, "once": true},
	&"mine_review": {"title": "地雷复盘", "message": "确认过的地雷会留在地图上，之后可以从这里规划路线。", "blocking": true, "once": true, "show_after_room_effect": true},
	&"route_rule": {"title": "路线规划", "message": "只有走到门口或边界时才会切换房间。先观察，再推进。", "blocking": true, "once": true},
	&"exit_goal": {"title": "撤离信标", "message": "到达出口后按 E 请求撤离，再确认结算。", "blocking": true, "once": true},
}


static func trigger_for(context: RunContext, pos: Vector2i) -> StringName:
	if context == null or context.mode != &"tutorial":
		return &""
	var trigger_id := StringName(context.tutorial_triggers.get(context.cell_key(pos), &""))
	if trigger_id == &"":
		return &""
	if context.tutorial_shown.has(String(trigger_id)):
		return &""
	var popup_def: Dictionary = POPUP_DEFS.get(trigger_id, {"title": String(trigger_id), "message": "教程：%s" % String(trigger_id), "blocking": true, "once": true})
	context.tutorial_popup = {
		"id": trigger_id,
		"title": popup_def.get("title", String(trigger_id)),
		"blocking": bool(popup_def.get("blocking", true)),
		"once": bool(popup_def.get("once", true)),
		"show_after_room_effect": bool(popup_def.get("show_after_room_effect", false)),
		"message": String(popup_def.get("message", "教程：%s" % String(trigger_id))),
	}
	return trigger_id


static func confirm_popup(context: RunContext) -> void:
	if context == null:
		return
	var popup_id := String(context.tutorial_popup.get("id", ""))
	if popup_id != "" and bool(context.tutorial_popup.get("once", true)):
		context.tutorial_shown[popup_id] = true
	context.tutorial_popup = {}
