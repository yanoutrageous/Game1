extends RefCounted
class_name I3SpecialRoomPresentationModel

# Player-facing, read-only projection of the public world-object payload.  It
# deliberately has no CommandBus reference and never infers rules from labels,
# raw ids, hidden map data, or visual state.


static func build(context_kind: StringName, payload_variant: Variant) -> Dictionary:
	var payload: Dictionary = payload_variant if payload_variant is Dictionary else {}
	match context_kind:
		&"event":
			return _event(payload)
		&"mine":
			return _mine(payload)
		&"exit":
			return _exit(payload)
	return _result("附近目标", "靠近后查看。", "", false, &"neutral")


static func _event(payload: Dictionary) -> Dictionary:
	var completed := bool(payload.get("completed", false))
	var display_title := String(payload.get("display_title", "异常事件")).strip_edges()
	if display_title.is_empty():
		display_title = "异常事件"
	var title := "%s · 已处理" % display_title if completed else display_title
	var fallback := "已经处理，不会重复结算。" if completed else "查看可选处理方式与预期影响。"
	var body := String(payload.get("summary", fallback)).strip_edges()
	if body.is_empty():
		body = fallback
	var action_visible := not completed and not bool(payload.get("display_only", false))
	return _result(title, body, "查看处理方式" if action_visible else "", action_visible, &"event")


static func _mine(payload: Dictionary) -> Dictionary:
	var triggered := bool(payload.get("triggered", false))
	var title := "雷区机关 · 已失效" if triggered else "雷区机关 · 警戒"
	var body := "已触发，不会再次造成伤害。" if triggered else String(payload.get("summary", "保持距离，留意地面机关。"))
	var entry: Dictionary = payload.get("entry_result", {}) if payload.get("entry_result", {}) is Dictionary else {}
	if bool(entry.get("first_trigger", false)):
		var hp_loss := absi(int(entry.get("hp_delta", 0)))
		var pressure_gain := maxi(0, int(entry.get("pressure_delta", 0)))
		body = "生命 -%d · 压力 +%d%s" % [
			hp_loss,
			pressure_gain,
			" · 本次伤害致命" if bool(entry.get("fatal", false)) else "",
		]
	return _result(title, body, "", false, &"danger" if not triggered else &"resolved")


static func _exit(payload: Dictionary) -> Dictionary:
	var objective := String(payload.get("objective_summary", "")).strip_edges()
	if objective.is_empty():
		objective = "本次探索未设置额外委托。"
	var lines: Array[String] = [
		"预计带回 · 黑资 %d · 已锁定收益 %d" % [int(payload.get("black_coin", 0)), int(payload.get("safe_yield", 0))],
		"随身物资 · 携带 %d 件 · 负重 %d/%d" % [
			int(payload.get("inventory_count", 0)),
			int(payload.get("backpack_used", 0)),
			int(payload.get("backpack_capacity", 0)),
		],
		"现场遗留 · %d 件" % int(payload.get("room_floor_item_count", 0)),
		"目标 · %s" % objective,
	]
	var display_title := String(payload.get("display_title", "撤离信标")).strip_edges()
	if display_title.is_empty():
		display_title = "撤离信标"
	return _result(display_title, "\n".join(lines), "查看并确认撤离", true, &"exit")


static func _result(title: String, body: String, primary_text: String, primary_visible: bool, tone: StringName) -> Dictionary:
	return {
		"title": title,
		"body": body,
		"primary_text": primary_text,
		"primary_visible": primary_visible,
		"tone": tone,
		"read_only": true,
		"command_allowed": false,
		"authority": &"public_world_object_projection",
	}
