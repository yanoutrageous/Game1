extends Node

const MotionMesh := preload("res://scripts/ui/main_menu/main_menu_motion_mesh.gd")
const SignPlane := preload("res://scripts/ui/main_menu/main_menu_sign_plane.gd")
const Hangers := preload("res://scripts/ui/main_menu/main_menu_hangers.gd")
const PLANE_SHADER := preload("res://scripts/ui/main_menu/main_menu_plane.gdshader")
const LIGHT_SHADER := preload("res://scripts/ui/main_menu/main_menu_light.gdshader")
const ASSET_ROOT := "res://assets/ui/i5/main_menu/environment/"

var layers: Array[Dictionary] = []
var moving_meshes: Array[MeshInstance2D] = []
var ambient: Array[Dictionary] = []
var leaves: Array[Polygon2D] = []
var lights: Array[ShaderMaterial] = []
var clock := 0.0
var camera_offset := Vector2.ZERO
var menu: Control
var hangers: Node2D


func setup(shell: Control) -> void:
	menu = shell
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ASSET_ROOT + "manifest.json"))
	_build_layers(manifest.layers)
	_build_motion(shell.get("animated_groups"), manifest.flag_cloth)
	_build_signs(shell.get("entry_nodes"))
	advance(0.0, bool(shell.get("reduced_motion")))


func _mesh(texture: Texture2D, dimensions: Vector2, effect: int, phase: float = 0.0) -> MeshInstance2D:
	var result := MotionMesh.new()
	result.wind_offset = phase
	result.strength = 0.65 if effect == 3 else (0.60 if effect == 4 else 1.0)
	result.configure(texture, dimensions, effect)
	if effect > 0:
		moving_meshes.append(result)
	return result


func _build_layers(definitions: Array) -> void:
	var background := menu.get_node("BackgroundRoot")
	for index in range(definitions.size()):
		var definition: Dictionary = definitions[index]
		var texture := load(ASSET_ROOT + String(definition.png)) as Texture2D
		var node: CanvasItem
		var kind := String(definition.kind)
		if definition.id == "fixed_near_world":
			var world := background.get_node("MainMenuSceneCleanPlate") as TextureRect
			world.texture = texture
			node = world
		else:
			var effect := 3 if kind == "canopy" else (4 if kind == "foreground" else 0)
			var layer := _mesh(texture, Vector2(definition.width, definition.height), effect, index * 1.73)
			layer.name = "MainMenuLayer_" + String(definition.id)
			background.add_child(layer)
			layer.position = Vector2(definition.x, definition.y)
			node = layer
		node.z_as_relative = false
		node.z_index = int(definition.z)
		layers.append({"node": node, "kind": kind, "base": Vector2(definition.x, definition.y), "depth": float(definition.depth), "phase": index * 1.73})


func _build_motion(groups: Array, flag: Dictionary) -> void:
	for index in range(groups.size()):
		var group: Dictionary = groups[index]
		var holder := group.node as TextureRect
		holder.self_modulate.a = 0.0
		holder.modulate = Color.WHITE
		holder.z_as_relative = false
		holder.z_index = 35
		var texture := holder.texture
		var effect := 2
		match String(holder.name):
			"MainMenuDungeonFlag":
				texture = load(ASSET_ROOT + String(flag.png)) as Texture2D
				holder.position = Vector2(flag.x, flag.y)
				holder.z_index = int(flag.z)
				effect = 1
			"MainMenuChimneySmoke":
				for plume_index in range(4):
					var plume := _mesh(texture, holder.size, 7, plume_index * 1.3)
					holder.add_child(plume)
					ambient.append({"kind": "smoke", "node": plume, "holder": holder, "phase": plume_index * 1.8})
				continue
			"MainMenuBirds":
				holder.z_index = 14
				effect = 8
			"MainMenuFallingLeaves":
				holder.z_index = 70
				for leaf_index in range(7):
					var leaf := Polygon2D.new()
					leaf.polygon = PackedVector2Array([Vector2(-5, 0), Vector2(-1, -3), Vector2(5, -1), Vector2(2, 3)])
					leaf.color = Color(0.68, 0.42 + leaf_index * 0.015, 0.16, 0.8)
					holder.add_child(leaf)
					leaves.append(leaf)
				ambient.append({"kind": "leaves", "holder": holder, "profile": group})
				continue
			_:
				if String(holder.name).begins_with("MainMenuLanternFlame"):
					var flame_index := int(String(holder.name).right(1))
					holder.position = [Vector2(190, 313), Vector2(421, 333), Vector2(1214, 319)][flame_index]
					effect = 6
		var mesh := _mesh(texture, holder.size, effect, index * 1.3)
		mesh.name = "ContinuousSurface"
		holder.add_child(mesh)
		if effect == 2:
			holder.z_index = 24
		elif effect == 6:
			var light := ColorRect.new()
			light.position = holder.size * 0.5 - Vector2(42, 42)
			light.size = Vector2(84, 84)
			light.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var material := ShaderMaterial.new()
			material.shader = LIGHT_SHADER
			material.set_shader_parameter("phase", index * 1.3)
			light.material = material
			holder.add_child(light)
			lights.append(material)
		if effect == 8:
			ambient.append({"kind": "birds", "node": mesh, "holder": holder, "profile": group})


func _material(node: Control, plane: Basis, surface: Texture2D, surface_rect: Rect2, board: bool = false, world: bool = false) -> void:
	var material := ShaderMaterial.new()
	material.shader = PLANE_SHADER
	material.set_shader_parameter("plane", plane)
	material.set_shader_parameter("inverse_plane", plane.inverse())
	material.set_shader_parameter("source_origin", node.position)
	material.set_shader_parameter("source_size", node.size)
	material.set_shader_parameter("board_surface", board)
	material.set_shader_parameter("ink_surface", surface)
	material.set_shader_parameter("ink_origin", surface_rect.position)
	material.set_shader_parameter("ink_size", surface_rect.size)
	material.set_shader_parameter("ink_on_world", world)
	node.material = material
	if node is Label:
		# Preserve the existing Font resource; reduce the detached sticker-like rim.
		node.add_theme_constant_override("outline_size", 1 if not world else 0)
		node.add_theme_constant_override("shadow_offset_x", 0)
		node.add_theme_constant_override("shadow_offset_y", 1 if not world else 0)


func _build_signs(entries: Dictionary) -> void:
	var plane := SignPlane.rack()
	for entry in entries.values():
		var board := entry.board as TextureRect
		var label := entry.label as Label
		_material(board, plane, board.texture, board.get_rect(), true)
		_material(label, plane, board.texture, board.get_rect())
		var hit: Rect2 = entry.base_hit_rect
		var polygon := PackedVector2Array()
		for corner in [hit.position, hit.position + Vector2(hit.size.x, 0), hit.end, hit.position + Vector2(0, hit.size.y)]:
			polygon.append(SignPlane.project(plane, corner) - hit.position)
		(entry.button as Button).set("hit_polygon", polygon)
	var world := menu.get_node("BackgroundRoot/MainMenuSceneCleanPlate") as TextureRect
	var title := menu.get_node("MainContentRoot/MainMenuTitle") as Label
	var title_face := PackedVector2Array([Vector2(160, 109), Vector2(476, 157), Vector2(474, 225), Vector2(160, 180)])
	var title_quad := SignPlane.inset(title_face, Rect2(0.065, 0.16, 0.87, 0.68))
	_material(title, SignPlane.from_rect(_title_ink_rect(title), title_quad), world.texture, world.get_rect(), false, true)
	var heading := menu.get_node("SideStatusRoot/MainMenuNoticeHeading") as Label
	var heading_face := PackedVector2Array([Vector2(80, 372), Vector2(233, 378), Vector2(233, 413), Vector2(80, 407)])
	_material(heading, SignPlane.from_rect(heading.get_rect(), SignPlane.inset(heading_face, Rect2(0.05, 0.08, 0.9, 0.84))), world.texture, world.get_rect(), false, true)
	var paper_quad := PackedVector2Array([Vector2(82, 417), Vector2(233, 422), Vector2(232, 574), Vector2(82, 576)])
	var paper_plane := SignPlane.from_rect(Rect2(82, 417, 156, 160), paper_quad)
	for label_name in ["MainMenuNoticeTitle", "MainMenuNoticeText"]:
		var label := menu.get_node("SideStatusRoot/" + label_name) as Label
		_material(label, paper_plane, world.texture, world.get_rect(), false, true)
	# Keep focus panels and their input bounds, and project their pixels onto the rack.
	for path in ["FloatingInfoRoot/MainMenuExploreFocusOutline", "FloatingInfoRoot/MainMenuUtilityFocusOutline"]:
		var focus := menu.get_node(path) as Control
		_material(focus, plane, world.texture, world.get_rect(), true)
		focus.item_rect_changed.connect(_refresh_focus_plane.bind(focus))
	hangers = Hangers.new()
	hangers.name = "MainMenuSignHangers"
	menu.get_node("PrimaryActionRoot").add_child(hangers)
	hangers.setup(entries)
	var collar := Polygon2D.new()
	collar.name = "MainMenuFrontPostCollar"
	collar.polygon = PackedVector2Array([Vector2(1114, 250), Vector2(1139, 244), Vector2(1183, 250), Vector2(1183, 277), Vector2(1140, 272), Vector2(1114, 278)])
	collar.uv = collar.polygon
	collar.texture = world.texture
	collar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	collar.z_index = 3
	menu.get_node("PrimaryActionRoot").add_child(collar)


func _title_ink_rect(label: Label) -> Rect2:
	# Fit the visible ink vertically, not the font's extra line-box space.
	# This changes only placement on the board, never the original font resource.
	var font := label.get_theme_font("font")
	var base := (font as FontVariation).base_font as FontFile
	var size := label.get_theme_font_size("font_size")
	var ink := Rect2()
	for character in label.text:
		var glyph := base.get_glyph_index(size, character.unicode_at(0), 0)
		base.render_glyph(0, Vector2i(size, 0), glyph)
		var extent := base.get_glyph_size(0, Vector2i(size, 0), glyph)
		if extent.y > 0:
			var glyph_rect := Rect2(base.get_glyph_offset(0, Vector2i(size, 0), glyph), extent)
			ink = glyph_rect if ink.size == Vector2.ZERO else ink.merge(glyph_rect)
	var baseline := label.position.y + (label.size.y - font.get_height(size)) * 0.5 + font.get_ascent(size)
	return Rect2(label.position.x, baseline + ink.position.y, label.size.x, ink.size.y)


func _refresh_focus_plane(focus: Control) -> void:
	var material := focus.material as ShaderMaterial
	material.set_shader_parameter("source_origin", focus.position)
	material.set_shader_parameter("source_size", focus.size)


func refresh_mounts() -> void:
	if hangers != null:
		hangers.refresh()


func project_rack_point(point: Vector2) -> Vector2:
	return SignPlane.project(SignPlane.rack(), point)


func advance(delta: float, reduced_motion: bool) -> void:
	if not reduced_motion:
		clock += delta
		var pointer := (menu.get_local_mouse_position() - Vector2(640, 360)) / Vector2(640, 360)
		camera_offset = camera_offset.lerp(pointer.clamp(Vector2(-1, -1), Vector2.ONE) * 0.6, 1.0 - exp(-delta * 3.0))
		for layer in layers:
			var node := layer.node as Node2D
			if node == null:
				continue
			var base: Vector2 = layer.base
			if layer.kind == "cloud":
				node.position = base + Vector2((sin(clock * 0.032 + layer.phase) - sin(layer.phase)) * 24.0, sin(clock * 0.21 + layer.phase) * 0.9)
			else:
				node.position = base + camera_offset * float(layer.depth)
		for mesh in moving_meshes:
			mesh.call("set_clock", clock)
		for material in lights:
			material.set_shader_parameter("scene_time", clock)
	for item in ambient:
		var holder := item.holder as TextureRect
		holder.visible = not reduced_motion
		if reduced_motion:
			continue
		match String(item.kind):
			"smoke":
				var progress := fmod(clock + float(item.phase), 7.2) / 7.2
				var plume := item.node as Node2D
				plume.position = Vector2(990 + sin(progress * 4.3 + float(item.phase)) * 9.0 + progress * 12, 91 - progress * 92) - holder.position
				plume.scale = Vector2.ONE * (0.37 + progress * 0.25)
				plume.modulate.a = sin(progress * PI) * 0.19
			"birds", "leaves":
				var profile: Dictionary = item.profile
				var elapsed := clock - float(profile.initial_delay)
				var duration := float(profile.active_seconds)
				var phase := fmod(maxf(0, elapsed), duration + float(profile.cooldown_seconds))
				holder.visible = elapsed >= 0 and phase < duration
				var progress := clampf(phase / duration, 0, 1)
				holder.modulate.a = smoothstep(0, 0.15, progress) * (1.0 - smoothstep(0.8, 1.0, progress)) * float(profile.base_alpha)
				if item.kind == "birds":
					holder.position = Vector2(395 + progress * 530, 70 - sin(progress * PI) * 32)
				else:
					for index in range(leaves.size()):
						var leaf := leaves[index]
						var x := 34.0 + index * 18.0 if index < 3 else 1180.0 + (index - 3) * 23.0
						leaf.position = Vector2(x + sin(clock * 1.6 + index) * 18, 180 + progress * 360 + index * 24) - holder.position
						leaf.rotation = clock * 1.8 + index
