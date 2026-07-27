extends RefCounted
class_name TutorialService

const SemanticActionHintScript := preload("res://scripts/core/input/semantic_action_hint.gd")

const POPUP_DEFS := {
	&"spawn_intro": {
		"title": "新员工说明",
		"message_template": "欢迎入职灰尾回收。\n\n你是封锁区临时回收员。本次目标是读取区域扫描图，避开雷险，搜刮物资，并找到撤离信标。\n\n移动：{move_up} / {move_down} / {move_left} / {move_right}\n\n调度台 A-7：公司建议你带回物资。更建议你带回自己。",
		"blocking": true,
		"once": true,
		"room_scoped": false,
		"confirm_text": "开始作业",
		"confirm_action": &"ui_accept",
		"action_ids": [&"move_up", &"move_down", &"move_left", &"move_right"],
	},
	&"number_rule": {
		"title": "区域扫描图",
		"message_template": "房间数字表示周围 8 个区域中的雷险数量。\n\n上下左右和斜向都会计入数字。异常体、物资、事件和撤离信标不计入该数字。\n\n调度台 A-7：数字通常不会骗人。公司系统另行计算。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [],
	},
	&"mine_rule": {
		"title": "雷险区",
		"message_template": "雷险区会造成伤害，并提高封锁压力。封锁压力升高时，五四三二一撤离协议可能下降。\n\n已触发的雷险会被记录，再次经过不会重复触发。\n\n调度台 A-7：协议下降不是惩罚。只是公司提前声明提醒过你。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"show_after_room_effect": true,
		"action_ids": [],
	},
	&"event_rule": {
		"title": "狐狸旅商",
		"message_template": "旅商可以将异常回收物折价出售为已锁定收益。已锁定收益即使作业失败也会保留。\n\n使用 {interact} 查看当前事件选项。\n\n调度台 A-7：公司不会知道，大概。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"interact"],
	},
	&"dice_rule": {
		"title": "赌徒",
		"message_template": "赌徒会用一局骰子赌你的待结算收益。押注赢了能翻倍入账，输了则折损一部分。\n\n使用 {interact} 查看当前事件选项。\n\n调度台 A-7：公司不参与赌博。公司只统计结果。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"interact"],
	},
	&"altar_rule": {
		"title": "异常祭坛",
		"message_template": "祭坛可以献祭生命值，换取已锁定收益。献祭不会让你当场倒下，但每献一次都更贵。\n\n使用 {interact} 查看当前事件选项。\n\n调度台 A-7：虔诚也是一种成本。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"interact"],
	},
	&"trap_rule": {
		"title": "机关装置",
		"message_template": "机关需要你动手拆解。战斗力足够时拆解成功，能拿到奖励；失败会受伤并升压。\n\n使用 {interact} 查看当前事件选项。\n\n调度台 A-7：拆解手册第一页写着：先确认值不值。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"interact"],
	},
	&"monster_rule": {
		"title": "异常体区域",
		"message_template": "异常体区域可以绕行，也可以清理。靠近后使用 {attack} 攻击。清理异常体会获得奖励，但也会提高封锁压力。\n\n调度台 A-7：高收益区和高事故区通常是同一个地方。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"attack"],
	},
	&"chest_rule": {
		"title": "物资箱",
		"message_template": "发现物资箱时，使用 {interact} 开启。物资箱通常比普通搜索更有价值，但收益仍需成功撤离后结算。\n\n调度台 A-7：箱子归你，风险也归你。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"interact"],
	},
	&"map_rule": {
		"title": "区域扫描图操作",
		"message_template": "使用 {open_map} 打开区域扫描图。左键单击未知格可标记或取消标记；键盘/手柄聚焦格子后使用 {ui_accept} 执行同一操作。单击已探索且可回传的安全格即可回传。\n\n调度台 A-7：回头不是失败。失联才是。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"open_map", &"ui_accept"],
	},
	&"mine_review": {
		"title": "雷险复查",
		"message_template": "再次遇到雷险时，先观察周围数字。如果路线风险过高，可以使用 {open_map} 重新规划，或回传到已探索且可回传的安全格。\n\n调度台 A-7：第二次踩中同类风险时，系统会将其归类为经验不足。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"show_after_room_effect": true,
		"action_ids": [&"open_map"],
	},
	&"route_rule": {
		"title": "路线规划",
		"message_template": "区域扫描图可以帮助你重新规划路线。使用 {open_map} 后，可以单击已探索且可回传的安全格完成回传，适合在协议下降后调整路径。\n\n调度台 A-7：合理返程不影响绩效。失联会。",
		"blocking": false,
		"once": false,
		"room_scoped": true,
		"action_ids": [&"open_map"],
	},
	&"exit_goal": {
		"title": "撤离信标",
		"message_template": "到达撤离信标后，使用 {request_extract} 打开撤离确认。\n\n教程撤离只记录完成状态，不结算收益或回收物。五四三二一撤离协议表示当前封锁区风险；数字越低，调度台越不建议继续深入。\n\n调度台 A-7：撤离是建议。不撤离是自主选择。相关条款已说明。",
		"blocking": true,
		"once": true,
		"room_scoped": false,
		"confirm_text": "我知道了",
		"confirm_action": &"ui_accept",
		"action_ids": [&"request_extract"],
	},
}

const EVENT_POPUP_IDS := {
	&"trader": &"event_rule",
	&"dice": &"dice_rule",
	&"altar": &"altar_rule",
	&"trap": &"trap_rule",
}


static func popup_definitions() -> Dictionary:
	return POPUP_DEFS.duplicate(true)


static func popup_definition(popup_id: StringName) -> Dictionary:
	return (POPUP_DEFS.get(popup_id, {}) as Dictionary).duplicate(true)


static func trigger_for(context: RunContext, pos: Vector2i) -> StringName:
	if context == null or context.mode != &"tutorial":
		return &""
	var trigger_id := StringName(context.tutorial_triggers.get(context.cell_key(pos), &""))
	if trigger_id == &"event_rule":
		var event_type := StringName(context.event_state.get("event_type", &"trader"))
		trigger_id = StringName(EVENT_POPUP_IDS.get(event_type, &"event_rule"))
	if trigger_id == &"":
		context.tutorial_popup = {}
		return &""
	if context.tutorial_shown.has(String(trigger_id)):
		context.tutorial_popup = {}
		return &""
	var popup_def := popup_definition(trigger_id)
	if popup_def.is_empty():
		context.tutorial_popup = {}
		return &""
	var action_ids: Array[StringName] = []
	for raw_action_id in popup_def.get("action_ids", []):
		action_ids.append(StringName(raw_action_id))
	var confirm_action := StringName(popup_def.get("confirm_action", &"ui_accept"))
	context.tutorial_popup = {
		"id": trigger_id,
		"title": str(popup_def.get("title", String(trigger_id))),
		"blocking": bool(popup_def.get("blocking", false)),
		"once": bool(popup_def.get("once", false)),
		"room_scoped": bool(popup_def.get("room_scoped", true)),
		"show_after_room_effect": bool(popup_def.get("show_after_room_effect", false)),
		"message": SemanticActionHintScript.replace_tokens_compact(str(popup_def.get("message_template", "")), action_ids),
		"action_hints": _action_hints(action_ids),
		"confirm_text": str(popup_def.get("confirm_text", "继续")),
		"confirm_action": confirm_action,
		"confirm_action_hint": SemanticActionHintScript.descriptor(confirm_action),
	}
	return trigger_id


static func confirm_popup(context: RunContext) -> void:
	if context == null:
		return
	var popup_id := String(context.tutorial_popup.get("id", ""))
	if popup_id != "" and bool(context.tutorial_popup.get("once", false)):
		context.tutorial_shown[popup_id] = true
	context.tutorial_popup = {}


static func _action_hints(action_ids: Array[StringName]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action_id in action_ids:
		result.append(SemanticActionHintScript.descriptor(action_id))
	return result
