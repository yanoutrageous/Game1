extends PanelContainer
class_name DevDiagnosticsPanel

signal close_requested

const DEV_ONLY_POLICY := {
	"policy_id": &"g10.dev_diagnostics",
	"page_id": &"settings",
	"entry_id": &"dev_diagnostics",
	"visible": false,
	"compact_allowed": true,
	"dev_only": true,
	"reduction_group": &"diagnostics",
	"unlock_condition": &"dev_channel",
	"priority": 1,
}

var body_label: Label


func _ready() -> void:
	build()


func build() -> void:
	name = "DevDiagnosticsPanel"
	visible = false
	offset_left = 360.0
	offset_top = 92.0
	offset_right = 940.0
	offset_bottom = 620.0
	if get_child_count() > 0:
		return

	var root := VBoxContainer.new()
	root.name = "DevDiagnosticsContent"
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var header := HBoxContainer.new()
	header.name = "DevDiagnosticsHeader"
	root.add_child(header)

	var title := Label.new()
	title.name = "DevDiagnosticsTitle"
	title.text = "Dev Diagnostics"
	title.add_theme_font_size_override("font_size", 20)
	header.add_child(title)

	var close_button := Button.new()
	close_button.name = "DevDiagnosticsCloseButton"
	close_button.text = "Close"
	close_button.pressed.connect(func() -> void: close_requested.emit())
	header.add_child(close_button)

	body_label = Label.new()
	body_label.name = "DevDiagnosticsBody"
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(520, 430)
	root.add_child(body_label)


func apply_diagnostics(snapshot: Dictionary, last_result: Dictionary, ui_state: Dictionary, art_report: Dictionary) -> void:
	if body_label == null:
		build()
	var lines: Array[String] = []
	lines.append("dev_only=true / visible_by_default=false")
	lines.append("ui_page=%s | panel=%s | layout=%s" % [
		ui_state.get("page", ""),
		ui_state.get("panel", ""),
		ui_state.get("layout_profile", ""),
	])
	lines.append("last_command=%s accepted=%s reason=%s" % [
		last_result.get("command_id", ""),
		last_result.get("accepted", last_result.get("ok", "")),
		last_result.get("reason_code", last_result.get("reason", "")),
	])
	lines.append("events=%s | transactions=%s" % [
		_array_from(snapshot, "event_log").size(),
		_array_from(snapshot, "transaction_log").size(),
	])
	lines.append("black_coin=%s | gold_coin=%s | backpack=%s/%s" % [
		snapshot.get("black_coin", 0),
		snapshot.get("gold_coin", 0),
		snapshot.get("backpack_used", 0),
		snapshot.get("backpack_capacity", 0),
	])
	lines.append("art_smoke_ok=%s | missing=%s | fallback_missing=%s" % [
		art_report.get("ok", false),
		_array_from(art_report, "missing_asset_ids").size(),
		_array_from(art_report, "missing_fallback_ids").size(),
	])
	body_label.text = _join_lines(lines)


func show_panel() -> void:
	visible = true


func hide_panel() -> void:
	visible = false


func _array_from(source: Dictionary, key: String) -> Array:
	var raw: Variant = source.get(key, [])
	if raw is Array:
		return (raw as Array).duplicate(true)
	return []


func _join_lines(lines: Array[String]) -> String:
	var text := ""
	for index in range(lines.size()):
		if index > 0:
			text += "\n"
		text += lines[index]
	return text
