extends Control
class_name Hud

# UI reads HudViewModel only. UI must not read TruthMap directly.

var view_model: HUDViewModel


func apply_view_model(next_view_model: HUDViewModel) -> void:
	view_model = next_view_model
	_apply_labels()


func clear() -> void:
	view_model = null
	_apply_labels()


func _ready() -> void:
	_apply_labels()


func _apply_labels() -> void:
	var status_panel := get_node_or_null("StatusPanel") as Label
	var protocol_panel := get_node_or_null("ProtocolPanel") as Label
	var hint_panel := get_node_or_null("HintPanel") as Label

	if status_panel != null:
		status_panel.custom_minimum_size = Vector2(380, 210)
		status_panel.text = view_model.status_text if view_model != null else "HP: --"
	if protocol_panel != null:
		protocol_panel.custom_minimum_size = Vector2(380, 110)
		protocol_panel.text = view_model.protocol_text if view_model != null else "Pressure: --"
	if hint_panel != null:
		hint_panel.custom_minimum_size = Vector2(560, 100)
		hint_panel.text = view_model.hint_text if view_model != null else "Last Message: --"
