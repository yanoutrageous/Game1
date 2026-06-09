extends Control
class_name TutorialPopupPanel

signal confirmed

var popup: Dictionary = {}


func apply_popup(next_popup: Dictionary) -> void:
	popup = next_popup.duplicate(true)
	_refresh()


func _ready() -> void:
	_refresh()
	var button := get_node_or_null("Panel/Content/ConfirmButton") as Button
	if button != null:
		button.pressed.connect(func() -> void: confirmed.emit())


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		confirmed.emit()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	visible = not popup.is_empty()
	var title := get_node_or_null("Panel/Content/Title") as Label
	var message := get_node_or_null("Panel/Content/Message") as Label
	var button := get_node_or_null("Panel/Content/ConfirmButton") as Button

	if title != null:
		title.add_theme_color_override("font_color", PresentationTheme.color_for_key(&"ui.accent"))
		title.text = "Tutorial: %s" % String(popup.get("id", ""))
	if message != null:
		message.add_theme_color_override("font_color", PresentationTheme.text_color())
		message.text = String(popup.get("message", ""))
	if button != null:
		button.text = "Confirm"
