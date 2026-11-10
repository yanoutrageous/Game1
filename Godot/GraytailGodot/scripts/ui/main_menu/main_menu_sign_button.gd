extends Button

var hit_polygon := PackedVector2Array()


func _has_point(point: Vector2) -> bool:
	if hit_polygon.is_empty():
		return Rect2(Vector2.ZERO, size).has_point(point)
	return Geometry2D.is_point_in_polygon(point, hit_polygon)
