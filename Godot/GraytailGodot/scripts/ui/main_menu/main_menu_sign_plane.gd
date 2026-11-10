extends RefCounted

const RACK_RECT := Rect2(790, 181, 370, 422)


static func quad_transform(quad: PackedVector2Array) -> Basis:
	var delta := quad[0] - quad[1] + quad[2] - quad[3]
	var edge_a := quad[1] - quad[2]
	var edge_b := quad[3] - quad[2]
	var denominator := edge_a.cross(edge_b)
	var g := delta.cross(edge_b) / denominator
	var h := edge_a.cross(delta) / denominator
	var x := quad[1] - quad[0] + quad[1] * g
	var y := quad[3] - quad[0] + quad[3] * h
	return Basis(Vector3(x.x, x.y, g), Vector3(y.x, y.y, h), Vector3(quad[0].x, quad[0].y, 1.0))


static func from_rect(rect: Rect2, quad: PackedVector2Array) -> Basis:
	var normalize := Basis(Vector3(1.0 / rect.size.x, 0, 0), Vector3(0, 1.0 / rect.size.y, 0), Vector3(-rect.position.x / rect.size.x, -rect.position.y / rect.size.y, 1))
	return quad_transform(quad) * normalize


static func project(transform: Basis, point: Vector2) -> Vector2:
	var result := transform * Vector3(point.x, point.y, 1)
	return Vector2(result.x, result.y) / result.z


static func inset(quad: PackedVector2Array, area: Rect2) -> PackedVector2Array:
	var transform := quad_transform(quad)
	var result := PackedVector2Array()
	for point in [area.position, area.position + Vector2(area.size.x, 0), area.end, area.position + Vector2(0, area.size.y)]:
		result.append(project(transform, point))
	return result


static func rack() -> Basis:
	return from_rect(RACK_RECT, PackedVector2Array([Vector2(790, 181), Vector2(1160, 200.68), Vector2(1160, 572.04), Vector2(790, 603)]))
