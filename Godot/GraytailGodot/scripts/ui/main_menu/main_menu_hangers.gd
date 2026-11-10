extends Node2D

const SignPlane := preload("res://scripts/ui/main_menu/main_menu_sign_plane.gd")
var segments: Array[Dictionary] = []


func setup(entries: Dictionary) -> void:
	var order := [&"deploy", &"long_term", &"settings", &"exit_game"]
	var attachments := [
		[0, 1, Vector2(149, 139), Vector2(49, 8)],
		[0, 1, Vector2(299, 139), Vector2(204, 8)],
		[1, 2, Vector2(78, 94), Vector2(56, 8)],
		[1, 2, Vector2(189, 94), Vector2(167, 8)],
		[2, 3, Vector2(58, 82), Vector2(48, 8)],
		[2, 3, Vector2(175, 82), Vector2(165, 8)],
	]
	for attachment in attachments:
		var upper: Dictionary = entries[order[attachment[0]]]
		var lower: Dictionary = entries[order[attachment[1]]]
		var upper_base: Vector2 = upper.base_board_rect.position
		var lower_base: Vector2 = lower.base_board_rect.position
		segments.append({"upper": upper.board, "lower": lower.board,
			"upper_point": SignPlane.project(SignPlane.rack(), upper_base + attachment[2]) - upper_base,
			"lower_point": SignPlane.project(SignPlane.rack(), lower_base + attachment[3]) - lower_base,
			"start": Vector2.ZERO, "end": Vector2.ZERO})
	refresh()


func refresh() -> void:
	for segment in segments:
		segment.start = (segment.upper.position + segment.upper_point).round()
		segment.end = (segment.lower.position + segment.lower_point).round()
	queue_redraw()


func _draw() -> void:
	for segment in segments:
		var start: Vector2 = segment.start
		var end: Vector2 = segment.end
		var direction := (end - start).normalized()
		var side := Vector2(-direction.y, direction.x)
		var length := start.distance_to(end)
		var count := maxi(1, roundi(length / 5.0))
		for index in range(count):
			var center := start.lerp(end, (float(index) + 0.5) / count)
			var half_length := length / count * 0.5 + 0.5
			var half_width := 1.7 if index % 2 == 0 else 0.7
			var loop := PackedVector2Array([(center - direction * half_length).round(), (center + side * half_width).round(), (center + direction * half_length).round(), (center - side * half_width).round(), (center - direction * half_length).round()])
			draw_polyline(loop, Color8(37, 37, 33), 3.0, false)
			draw_polyline(loop, Color8(106, 90, 76), 1.0, false)
			draw_line(loop[3], loop[0], Color8(190, 181, 158), 1.0, false)
