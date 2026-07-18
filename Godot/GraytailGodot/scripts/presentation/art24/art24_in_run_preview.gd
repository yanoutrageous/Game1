extends Control
class_name Art24InRunPreview

signal navigation_requested(direction: int)
signal primary_navigation_requested(direction: int)

const Layout := preload("res://scripts/presentation/art24/art24_in_run_layout_contract.gd")
const Assets := preload("res://scripts/presentation/art24/art24_in_run_asset_contract.gd")

const ROOM_LABELS := {
	"normal": "普通作业间",
	"mine": "雷险作业间",
	"chest": "物资储藏间",
	"event": "异常事件间",
	"monster": "战斗遭遇间",
	"exit": "撤离信标间",
}

const PROTOCOL_TITLES := {
	5: "正常作业",
	4: "轻度警戒",
	3: "风险作业",
	2: "返程建议",
	1: "最终建议",
}

const PROTOCOL_COLORS := {
	5: Color("4ad8cb"),
	4: Color("69bc83"),
	3: Color("efa23f"),
	2: Color("e87536"),
	1: Color("d13e35"),
}

var state_id: StringName = &"room.normal.idle"
var state_data: Dictionary = {
	"room_type": "normal",
	"visual_state": "idle",
	"active_modal": "none",
	"protocol_level": 5,
	"reduce_motion": false,
}
var elapsed := 0.0
var body_font: Font
var texture_cache: Dictionary = {}
var interactive := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_font = load("res://assets/fonts/NotoSansCJKsc-Regular.otf") as Font
	set_process(true)
	queue_redraw()


func set_interactive(enabled: bool) -> void:
	interactive = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	if enabled:
		grab_focus()


func _gui_input(event: InputEvent) -> void:
	if not interactive or not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_RIGHT, KEY_D:
			navigation_requested.emit(1)
			accept_event()
		KEY_LEFT, KEY_A:
			navigation_requested.emit(-1)
			accept_event()
		KEY_PAGEUP, KEY_UP, KEY_W:
			primary_navigation_requested.emit(-1)
			accept_event()
		KEY_PAGEDOWN, KEY_DOWN, KEY_S:
			primary_navigation_requested.emit(1)
			accept_event()


func apply_state(next_state_id: StringName, next_state: Dictionary) -> void:
	state_id = next_state_id
	state_data = next_state.duplicate(true)
	elapsed = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var room_type := String(state_data.get("room_type", "normal")).to_lower()
	var visual_state := String(state_data.get("visual_state", "idle"))
	var active_modal := String(state_data.get("active_modal", "none"))
	var protocol_level := clampi(int(state_data.get("protocol_level", 5)), 1, 5)
	var reduce_motion := bool(state_data.get("reduce_motion", false))

	_draw_room(room_type, visual_state, reduce_motion)
	_draw_hud(room_type, visual_state, protocol_level)
	_draw_modal(active_modal, room_type, visual_state, protocol_level)
	if active_modal != "none" and active_modal != "map" and not active_modal.begins_with("map_"):
		_draw_protocol(protocol_level)


func _draw_room(room_type: String, visual_state: String, reduce_motion: bool) -> void:
	_draw_texture_cover(StringName("visual.art24.room.%s" % room_type), Layout.GAMEPLAY)
	draw_rect(Layout.GAMEPLAY, Color(0.025, 0.045, 0.045, 0.12), true)
	if room_type in ["mine", "monster"]:
		draw_rect(Layout.GAMEPLAY, Color(0.16, 0.025, 0.015, 0.08), true)
	elif room_type in ["event", "exit"]:
		draw_rect(Layout.GAMEPLAY, Color(0.0, 0.18, 0.17, 0.07), true)

	if not reduce_motion:
		var dust_frame := int(elapsed * 4.0) % 8
		_draw_texture(StringName("visual.art24.fx.ambient_dust.%d" % dust_frame), Layout.GAMEPLAY, Color(1, 1, 1, 0.56))

	_draw_room_prop(room_type, visual_state, reduce_motion)
	_draw_world_loot(room_type, visual_state, reduce_motion)
	_draw_player(room_type, visual_state, reduce_motion)
	_draw_combat_fx(room_type, visual_state, reduce_motion)


func _draw_room_prop(room_type: String, visual_state: String, reduce_motion: bool) -> void:
	match room_type:
		"mine":
			if visual_state in ["warning", "triggered", "resolved"]:
				_draw_texture(&"visual.art24.prop.mine", Rect2(Layout.PRIMARY_PROP_ANCHOR - Vector2(66, 66), Vector2(132, 132)))
			if visual_state == "triggered":
				var frame := 5 if reduce_motion else int(elapsed * 12.0) % 6
				_draw_texture(StringName("visual.art24.fx.mine_burst.%d" % frame), Rect2(Layout.PRIMARY_PROP_ANCHOR - Vector2(128, 128), Vector2(256, 256)))
		"chest":
			var open := visual_state in ["open", "empty"]
			if visual_state == "opening" and not reduce_motion:
				open = fmod(elapsed, 1.0) > 0.48
			var key := &"visual.art24.prop.chest_open" if open else &"visual.art24.prop.chest_closed"
			var color := Color(0.62, 0.62, 0.62, 0.78) if visual_state == "empty" else Color.WHITE
			_draw_texture(key, Rect2(Layout.PRIMARY_PROP_ANCHOR - Vector2(72, 72), Vector2(144, 144)), color)
			if visual_state == "opening":
				var frame := 4 if reduce_motion else int(elapsed * 10.0) % 6
				_draw_texture(StringName("visual.art24.fx.chest_opening.%d" % frame), Rect2(Layout.PRIMARY_PROP_ANCHOR - Vector2(96, 96), Vector2(192, 192)), Color(1, 1, 1, 0.92))
		"event":
			var pulse := 0.86 if visual_state == "resolved" else 1.0 + (0.0 if reduce_motion else sin(elapsed * 3.0) * 0.06)
			var size := Vector2(142, 142) * pulse
			_draw_texture(&"visual.art24.prop.event", Rect2(Layout.PRIMARY_PROP_ANCHOR - size * 0.5, size), Color(0.72, 1.0, 0.96, 0.72 if visual_state == "resolved" else 1.0))
		"monster":
			var monster_state := _monster_frame(visual_state, reduce_motion)
			var monster_offset := Vector2(Layout.MONSTER_SIZE.x * 0.5, Layout.MONSTER_SIZE.y * 0.8)
			_draw_texture(StringName("visual.art24.actor.ironback.%s" % monster_state), Rect2(Layout.MONSTER_ANCHOR - monster_offset, Layout.MONSTER_SIZE))
		"exit":
			var active := visual_state in ["active", "confirm", "confirmed"]
			var key := &"visual.art24.prop.extract_active" if active else &"visual.art24.prop.extract_inactive"
			_draw_texture(key, Rect2(Layout.PRIMARY_PROP_ANCHOR - Vector2(95, 95), Vector2(190, 190)))
			if active:
				var frame := 0 if reduce_motion else int(elapsed * 8.0) % 8
				_draw_texture(StringName("visual.art24.fx.beacon_pulse.%d" % frame), Rect2(Layout.PRIMARY_PROP_ANCHOR - Vector2(128, 128), Vector2(256, 256)))


func _draw_world_loot(room_type: String, visual_state: String, reduce_motion: bool) -> void:
	var show_loot := visual_state in ["loot_spawned", "loot_hover", "pickup_fly"] or String(state_id).begins_with("loot.")
	if not show_loot:
		return
	var names := ["emergency_bandage", "copper_coil", "scanner_probe"]
	for index in range(3):
		var anchor: Vector2 = Layout.LOOT_ANCHORS[index]
		if visual_state == "pickup_fly" or state_id == &"loot.pickup":
			if index == 0:
				var duration := 1.2
				var t := 1.0 if reduce_motion else clampf(fmod(elapsed, duration) / duration, 0.0, 1.0)
				anchor = anchor.lerp(Vector2(245, 566), _ease_out_cubic(t))
				if t > 0.88:
					continue
		var beam_frame := 0 if reduce_motion else int(elapsed * 8.0 + index * 2) % 8
		_draw_texture(StringName("visual.art24.fx.pickup_beam.%d" % beam_frame), Rect2(anchor - Vector2(48, 118), Vector2(96, 144)), Color(1, 1, 1, 0.78))
		_draw_texture(StringName("visual.art24.item.world_loot.%s" % names[index]), Rect2(anchor - Layout.WORLD_LOOT_SIZE * 0.5, Layout.WORLD_LOOT_SIZE))


func _draw_player(room_type: String, visual_state: String, reduce_motion: bool) -> void:
	var motion := "idle_a"
	if visual_state in ["searching", "active"] and room_type in ["normal", "event"]:
		motion = "interact"
	elif visual_state == "triggered" or (room_type == "monster" and visual_state == "hit"):
		motion = "hit"
	elif room_type == "monster" and visual_state == "attack":
		var attack_frames := ["attack_windup", "attack_swing", "attack_impact", "attack_recover"]
		motion = "attack_impact" if reduce_motion else attack_frames[int(elapsed * 8.0) % attack_frames.size()]
	elif state_id == &"motion.full":
		motion = "walk_a" if int(elapsed * 6.0) % 2 == 0 else "walk_b"
	elif not reduce_motion and int(elapsed * 2.0) % 6 == 5:
		motion = "idle_b"
	var frame := 0 if reduce_motion else int(elapsed * 8.0) % 8
	if room_type != "monster":
		_draw_texture(StringName("visual.art24.fx.scan_ring.%d" % frame), Rect2(Layout.PLAYER_ANCHOR - Vector2(96, 96), Vector2(192, 192)), Color(1, 1, 1, 0.72))
	var player_offset := Vector2(Layout.PLAYER_SIZE.x * 0.5, Layout.PLAYER_SIZE.y * 0.82)
	var player_size: Vector2 = Vector2(160, 160) if motion.begins_with("attack_") else Layout.PLAYER_SIZE
	player_offset = Vector2(player_size.x * 0.5, player_size.y * 0.82)
	_draw_texture(StringName("visual.art24.actor.player.down.%s" % motion), Rect2(Layout.PLAYER_ANCHOR - player_offset, player_size))


func _draw_combat_fx(room_type: String, visual_state: String, reduce_motion: bool) -> void:
	if room_type != "monster" or visual_state not in ["attack", "hit"]:
		return
	var frame := 4 if reduce_motion else int(elapsed * 10.0) % 6
	_draw_texture(StringName("visual.art24.fx.combat_slash.%d" % frame), Rect2(Layout.PLAYER_ANCHOR + Vector2(-18, -152), Vector2(256, 192)), Color(1, 1, 1, 0.92))


func _draw_hud(room_type: String, visual_state: String, protocol_level: int) -> void:
	_draw_texture(&"visual.art24.ui.left_rail", Layout.LEFT_RAIL)
	_draw_texture(&"visual.art24.ui.bottom_bar", Layout.BOTTOM_BAR)
	_draw_left_rail(room_type, visual_state)
	_draw_protocol(protocol_level)
	_draw_bottom_bar(room_type, visual_state)


func _draw_left_rail(room_type: String, visual_state: String) -> void:
	_draw_text("区域扫描图", Vector2(24, 36), 21, Color("e7d3a4"), 252)
	_draw_minimap()

	_draw_text("生命", Vector2(26, 346), 15, Color("dfd4bd"), 58)
	_draw_text("100 / 100", Vector2(83, 346), 15, Color("f2e6cc"), 88)
	draw_rect(Rect2(172, 333, 96, 12), Color("251b18"), true)
	draw_rect(Rect2(174, 335, 92, 8), Color("d74738"), true)
	_draw_text("战力  10", Vector2(26, 374), 15, Color("f1aa45"), 110)
	_draw_text("黑币  12", Vector2(152, 374), 15, Color("d6b15c"), 110)
	_draw_text("零件  2", Vector2(26, 402), 15, Color("b6c4bd"), 110)
	_draw_text("安全收益  8", Vector2(152, 402), 15, Color("56c4a6"), 118)
	_draw_text("已探索  7格", Vector2(26, 430), 15, Color("9ccbbd"), 120)
	_draw_text("周边雷险  3", Vector2(152, 430), 15, Color("e3884a"), 120)
	draw_line(Vector2(24, 464), Vector2(276, 464), Color(0.45, 0.39, 0.28, 0.6), 1)
	_draw_text("当前房间", Vector2(26, 492), 15, Color("c69a46"), 96)
	_draw_text(String(ROOM_LABELS.get(room_type, "未知区域")), Vector2(118, 492), 15, Color("e5dcc9"), 150)

	_draw_text("作业包摘要", Vector2(24, 536), 17, Color("dfa641"), 130)
	var summary := ["应急止血贴 ×2", "断裂铜线圈 ×1", "回收价值  8"]
	var active_modal := String(state_data.get("active_modal", "none"))
	if visual_state == "depleted":
		summary = ["当前房间已耗尽", "背包 3 / 10", "安全收益  8"]
	elif active_modal == "inventory_empty":
		summary = ["背包当前为空", "容量 0 / 10", "安全收益  8"]
	elif active_modal == "inventory_full":
		summary = ["背包容量已满", "容量 10 / 10", "请先丢弃或替换"]
	elif active_modal == "ground_loot_blocked":
		summary = ["拾取容量不足", "容量 9 / 10", "当前物品需要 2 格"]
	elif active_modal == "ground_loot_replace":
		summary = ["替换预览", "容量 10 / 10", "将放下低价值物"]
	for index in range(summary.size()):
		_draw_text("• " + summary[index], Vector2(30, 566 + index * 23), 13, Color("d8d0bd"), 235)


func _draw_minimap() -> void:
	var cell := Vector2(27, 27)
	var origin := Vector2(42, 72)
	for y in range(8):
		for x in range(8):
			var state := "unknown"
			if abs(x - 4) + abs(y - 4) <= 3:
				state = "scanned"
			if (x == 4 and y in [3, 4, 5]) or (y == 4 and x in [2, 3, 4, 5]):
				state = "explored"
			if x == 4 and y == 4:
				state = "player"
			elif x == 5 and y == 3:
				state = "danger"
			elif x == 2 and y == 4:
				state = "flagged"
			var rect := Rect2(origin + Vector2(x * cell.x, y * cell.y), cell - Vector2(2, 2))
			_draw_texture(StringName("visual.art24.ui.map_tile.%s" % state), rect)
			if state in ["scanned", "explored"] and (x + y) % 3 != 0:
				_draw_text(str((x + y) % 3 + 1), rect.position + Vector2(8, 18), 11, Color("d6ddd7"), 12, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_protocol(level: int) -> void:
	_draw_texture(StringName("visual.art24.ui.protocol.level_%d" % level), Layout.PROTOCOL)
	var color: Color = PROTOCOL_COLORS[level]
	_draw_text("安全 5  →  1 危险", Layout.PROTOCOL.position + Vector2(14, 27), 14, Color("ead5a5"), 132)
	_draw_text("协议", Layout.PROTOCOL.position + Vector2(162, 27), 14, Color("d9caaa"), 48)
	_draw_text(str(level), Layout.PROTOCOL.position + Vector2(16, 62), 34, color, 48, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text(String(PROTOCOL_TITLES[level]), Layout.PROTOCOL.position + Vector2(68, 56), 17, color, 140)
	var pressure := (5 - level) * 22 + 12
	_draw_text("封锁压力 %d / 100" % pressure, Layout.PROTOCOL.position + Vector2(68, 80), 12, Color("d8d1c0"), 144)
	draw_rect(Rect2(Layout.PROTOCOL.position + Vector2(68, 88), Vector2(142, 8)), Color("221b18"), true)
	draw_rect(Rect2(Layout.PROTOCOL.position + Vector2(70, 90), Vector2(138.0 * pressure / 100.0, 4)), color, true)
	_draw_text("高收益区，高事故区。", Layout.PROTOCOL.position + Vector2(14, 108), 11, Color("baab91"), 198)


func _draw_bottom_bar(room_type: String, visual_state: String) -> void:
	var prompt := "按 E 搜索周围物资"
	if room_type == "monster":
		prompt = "按 Space / J 清理当前威胁"
	elif room_type == "exit":
		prompt = "按 E 请求撤离，按 T 查看撤离状态"
	elif visual_state == "loot_spawned":
		prompt = "按 G 查看地面物品"
	_draw_text(prompt, Vector2(392, 670), 14, Color("e3a747"), 500, HORIZONTAL_ALIGNMENT_CENTER)
	var actions := [["WASD", "移动"], ["M", "地图"], ["E", "交互"], ["Q", "背包"], ["G", "地面"], ["SPC", "战斗"], ["T", "撤离"], ["ESC", "暂停"]]
	for index in range(actions.size()):
		var x := 12.0 + index * 157.0
		_draw_texture(&"visual.art24.ui.keycap.normal", Rect2(x, 677, 50, 36))
		_draw_text(actions[index][0], Vector2(x + 2, 700), 11, Color("e6d8b8"), 46, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_text(actions[index][1], Vector2(x + 57, 701), 12, Color("c9c0ae"), 72)


func _draw_modal(active_modal: String, room_type: String, visual_state: String, protocol_level: int) -> void:
	if active_modal == "none":
		if visual_state == "searching":
			_draw_search_progress()
		elif visual_state == "depleted":
			_draw_toast("warning", "当前房间已耗尽，没有可继续搜索的目标。")
		elif visual_state == "loot_hover":
			_draw_toast("info", "发现可回收物：按 G 打开地面物品。")
		return
	if active_modal == "map" or active_modal.begins_with("map_"):
		_draw_map_modal(active_modal)
	elif active_modal.begins_with("inventory"):
		_draw_inventory_modal(active_modal)
	elif active_modal.begins_with("ground_loot"):
		_draw_ground_loot_modal(active_modal)
	elif active_modal == "tutorial":
		_draw_tutorial_modal()
	elif active_modal == "event":
		_draw_event_modal()
	elif active_modal == "pause":
		_draw_pause_modal()
	elif active_modal.begins_with("extract"):
		_draw_extract_modal(active_modal, protocol_level)
	elif active_modal.begins_with("result"):
		_draw_result_modal(active_modal)


func _draw_map_modal(mode: String) -> void:
	draw_rect(Rect2(Vector2.ZERO, Layout.LOGICAL_SIZE), Color(0.01, 0.035, 0.055, 0.82), true)
	_draw_texture(&"visual.art24.ui.map_frame", Layout.MAP_FRAME)
	_draw_text("完整区域扫描图", Layout.MAP_FRAME.position + Vector2(40, 46), 24, Color("85e4d5"), 640, HORIZONTAL_ALIGNMENT_CENTER)
	var map_status := "区域概览 · 已探索 18 格 · 未探索区域保持隐藏"
	if mode == "map_selected":
		map_status = "已选择 (6,7) · 已探索安全格 · 可回传"
	elif mode == "map_marked":
		map_status = "已标记 (7,4) · 再次选择可取消标记"
	elif mode == "map_return":
		map_status = "回传目标 (6,7) · 安全格 · 等待确认"
	_draw_text(map_status, Layout.MAP_FRAME.position + Vector2(42, 76), 13, Color("d0c4aa"), 636, HORIZONTAL_ALIGNMENT_CENTER)
	var selected := Vector2i(6, 7)
	for y in range(10):
		for x in range(10):
			var tile_state := "unknown"
			if abs(x - 5) + abs(y - 6) < 5:
				tile_state = "scanned"
			if (x == 5 and y >= 4) or (y == 6 and x in [3, 4, 5, 6]):
				tile_state = "explored"
			if mode == "map_selected" and Vector2i(x, y) == selected:
				tile_state = "selected"
			elif mode == "map_marked" and x == 7 and y == 4:
				tile_state = "flagged"
			elif x == 5 and y == 6:
				tile_state = "player"
			elif x == 3 and y == 4:
				tile_state = "danger"
			var rect := Rect2(Layout.MAP_GRID.position + Vector2(x * 42, y * 42), Vector2(40, 40))
			_draw_texture(StringName("visual.art24.ui.map_tile.%s" % tile_state), rect)
			if tile_state in ["scanned", "explored", "selected"] and (x + y) % 2 == 0:
				_draw_text(str((x * 2 + y) % 3 + 1), rect.position + Vector2(12, 25), 13, Color("d8e3dd"), 16, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("图例", Layout.MAP_LEGEND.position + Vector2(0, 24), 18, Color("e0a64a"), 174)
	var legends := ["数字  周围雷险", "旗帜  玩家标记", "红色  高危房间", "青绿  已探索", "菱形  当前位置"]
	for index in range(legends.size()):
		_draw_text(legends[index], Layout.MAP_LEGEND.position + Vector2(0, 62 + index * 34), 13, Color("d3cbb8"), 174)
	var footer := "左键：标记/取消 · 已探索格：回传 · ESC / M：关闭"
	if mode == "map_return":
		footer = "该安全格可回传；确认后关闭地图并提交回传请求。"
	_draw_text(footer, Layout.MAP_FRAME.position + Vector2(42, 574), 12, Color("bfcac5"), 636, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_inventory_modal(mode: String) -> void:
	draw_rect(Layout.GAMEPLAY, Color(0.01, 0.025, 0.03, 0.64), true)
	_draw_texture(&"visual.art24.ui.modal_frame", Layout.GAMEPLAY_MODAL)
	_draw_text("回收背包", Layout.GAMEPLAY_MODAL.position + Vector2(34, 46), 24, Color("e6c076"), 280)
	var inventory_capacity := "0 / 10" if mode == "inventory_empty" else ("10 / 10" if mode == "inventory_full" else "4 / 10")
	_draw_text("背包  %s     黑币  12     安全收益  8     长期金币  20" % inventory_capacity, Layout.GAMEPLAY_MODAL.position + Vector2(34, 78), 14, Color("d8cfbd"), 650)
	draw_line(Layout.GAMEPLAY_MODAL.position + Vector2(34, 92), Layout.GAMEPLAY_MODAL.position + Vector2(726, 92), Color(0.5, 0.4, 0.24, 0.55), 1)
	if mode == "inventory_empty":
		_draw_text("背包为空。探索房间后，物品会先进入地面或背包。", Layout.GAMEPLAY_MODAL.position + Vector2(56, 190), 17, Color("aeb8b3"), 620, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var items := [["emergency_bandage", "急救贴 ×2", "恢复 24 生命"], ["scanner_probe", "扫描针 ×1", "扫描周边房间"], ["armor_plate", "旧背心（已装备）", "触雷伤害 -10"], ["copper_coil", "断裂铜线圈 ×1", "回收价值 8"]]
	for index in range(items.size()):
		var selected := mode in ["inventory_selected", "inventory_tooltip"] and index == 0
		var blocked := mode == "inventory_full" and index == 3
		var row_state := "blocked" if blocked else ("selected" if selected else "normal")
		var row_rect := Rect2(Layout.GAMEPLAY_MODAL.position + Vector2(52, 116 + index * 72), Vector2(620, 60))
		_draw_texture(StringName("visual.art24.ui.item_row.%s" % row_state), row_rect)
		_draw_texture(StringName("visual.art24.item.world_loot.%s" % items[index][0]), Rect2(row_rect.position + Vector2(8, -5), Vector2(68, 68)))
		_draw_text(items[index][1], row_rect.position + Vector2(84, 27), 16, Color("e1d6bf"), 260)
		_draw_text(items[index][2], row_rect.position + Vector2(84, 49), 12, Color("aebbb5"), 280)
		_draw_text("使用", row_rect.position + Vector2(446, 36), 13, Color("6ad0b7"), 64, HORIZONTAL_ALIGNMENT_CENTER)
		_draw_text("丢弃", row_rect.position + Vector2(530, 36), 13, Color("eca247"), 64, HORIZONTAL_ALIGNMENT_CENTER)
	var tip_rect := Rect2(Layout.GAMEPLAY_MODAL.position + Vector2(52, 408), Vector2(620, 100))
	if mode == "inventory_tooltip":
		_draw_texture(&"visual.art24.ui.tooltip.normal", tip_rect)
		_draw_text("急救贴", tip_rect.position + Vector2(18, 30), 17, Color("e6c076"), 160)
		_draw_text("消耗品 · 使用后恢复 24 生命。", tip_rect.position + Vector2(18, 60), 14, Color("d5cebd"), 560)
	else:
		_draw_texture(&"visual.art24.ui.tooltip.warning" if mode == "inventory_full" else &"visual.art24.ui.tooltip.normal", tip_rect)
		_draw_text("背包已满" if mode == "inventory_full" else "携带结构", tip_rect.position + Vector2(18, 30), 16, Color("e96d51") if mode == "inventory_full" else Color("e4b65d"), 150)
		var inventory_summary := "已用 10 / 10 格 · 丢弃或替换后再拾取" if mode == "inventory_full" else "消耗品 2 格  ·  材料 1 格  ·  装备 1 格  ·  空余 6 格"
		_draw_text(inventory_summary, tip_rect.position + Vector2(18, 59), 13, Color("cfd3c6"), 560)


func _draw_ground_loot_modal(mode: String) -> void:
	draw_rect(Layout.GAMEPLAY, Color(0.01, 0.025, 0.03, 0.64), true)
	_draw_texture(&"visual.art24.ui.modal_frame", Layout.GAMEPLAY_MODAL)
	_draw_text("地面回收物", Layout.GAMEPLAY_MODAL.position + Vector2(34, 46), 24, Color("74d9c7"), 280)
	var loot_capacity := "9 / 10" if mode == "ground_loot_blocked" else ("10 / 10" if mode == "ground_loot_replace" else "4 / 10")
	var loot_action := "选择后替换" if mode == "ground_loot_replace" else "选择后拾取"
	_draw_text("当前房间 3 件 · 背包 %s · %s" % [loot_capacity, loot_action], Layout.GAMEPLAY_MODAL.position + Vector2(34, 78), 14, Color("d8cfbd"), 650)
	var items := [["emergency_bandage", "急救贴 ×2", "消耗品 · 2 格"], ["copper_coil", "断裂铜线圈 ×1", "材料 · 1 格"], ["scanner_probe", "扫描针 ×1", "工具 · 1 格"]]
	for index in range(items.size()):
		var selected := mode in ["ground_loot_selected", "ground_loot_replace"] and index == 0
		var blocked := mode == "ground_loot_blocked" and index == 0
		var row_state := "blocked" if blocked else ("selected" if selected else "normal")
		var row_rect := Rect2(Layout.GAMEPLAY_MODAL.position + Vector2(52, 122 + index * 84), Vector2(620, 60))
		_draw_texture(StringName("visual.art24.ui.item_row.%s" % row_state), row_rect)
		_draw_texture(StringName("visual.art24.item.world_loot.%s" % items[index][0]), Rect2(row_rect.position + Vector2(8, -6), Vector2(70, 70)))
		_draw_text(items[index][1], row_rect.position + Vector2(88, 28), 16, Color("e2d8c2"), 260)
		_draw_text(items[index][2], row_rect.position + Vector2(88, 49), 12, Color("aebbb5"), 280)
		_draw_text("拾取", row_rect.position + Vector2(516, 37), 14, Color("69d3bb"), 76, HORIZONTAL_ALIGNMENT_CENTER)
	var tip_rect := Rect2(Layout.GAMEPLAY_MODAL.position + Vector2(52, 390), Vector2(620, 100))
	if mode == "ground_loot_blocked":
		_draw_texture(&"visual.art24.ui.tooltip.warning", tip_rect)
		_draw_text("容量不足", tip_rect.position + Vector2(18, 29), 17, Color("e96d51"), 140)
		_draw_text("急救贴需要 2 格；当前仅剩 1 格，请先放下物品。", tip_rect.position + Vector2(18, 62), 14, Color("ddd2bd"), 570)
	elif mode == "ground_loot_replace":
		_draw_texture(&"visual.art24.ui.tooltip.warning", tip_rect)
		_draw_text("替换预览", tip_rect.position + Vector2(18, 29), 17, Color("eea34b"), 140)
		_draw_text("拾取急救贴将自动放下低价值候选：断裂铜线圈。", tip_rect.position + Vector2(18, 62), 14, Color("ddd2bd"), 570)
	else:
		_draw_texture(&"visual.art24.ui.tooltip.normal", tip_rect)
		if mode == "ground_loot_selected":
			_draw_text("当前选择：急救贴", tip_rect.position + Vector2(18, 29), 17, Color("73d7c2"), 220)
			_draw_text("消耗品 · 占用 2 格 · 使用后恢复 24 生命", tip_rect.position + Vector2(18, 62), 14, Color("d4d0bf"), 570)
		else:
			_draw_text("请选择回收物", tip_rect.position + Vector2(18, 29), 17, Color("73d7c2"), 220)
			_draw_text("选中物品后显示占格、用途和拾取结果预览。", tip_rect.position + Vector2(18, 62), 14, Color("d4d0bf"), 570)
	var loot_footer := "释放容量后重试 · G / ESC 关闭" if mode == "ground_loot_blocked" else ("方向键选择 · G / ESC 关闭" if mode == "ground_loot" else "G / ESC 关闭 · Enter 拾取 · 容量不足时显示替换预览")
	_draw_text(loot_footer, Layout.GAMEPLAY_MODAL.position + Vector2(56, 524), 12, Color("b7c2bc"), 620, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_tutorial_modal() -> void:
	_draw_standard_modal("作业引导  1 / 4", "先看左侧扫描图。数字表示周围八格雷险；特殊房不计入数字。", ["WASD  移动到相邻房间", "E  搜索或交互", "M  查看完整区域图", "Q / G  管理背包与地面物品"])


func _draw_event_modal() -> void:
	_draw_standard_modal("异常事件：回收终端", "终端仍有微弱供能。选择只影响表现预览，本美术分支不执行交易。", ["锁定一件物资为安全收益", "扫描终端记录", "离开并保持当前状态"])


func _draw_pause_modal() -> void:
	_draw_standard_modal("探索暂停", "局内状态已冻结。暂停菜单不等于放弃探索。", ["继续探索", "画面 / 音效 / 减少动态", "返回出发探索（需要强确认）"])


func _draw_extract_modal(mode: String, protocol_level: int) -> void:
	var risky := mode == "extract_risky"
	var title := "撤离确认 · 高风险" if risky else "撤离确认"
	var body := "协议 %d · 黑币 12 · 安全收益 8 · 探索 7 格" % protocol_level
	var options := ["确认撤离并进入结算", "继续探索", "查看本局带出明细"]
	if risky:
		options[0] = "风险提示已确认：仍要撤离"
	_draw_standard_modal(title, body, options, true)


func _draw_result_modal(mode: String) -> void:
	draw_rect(Rect2(Vector2.ZERO, Layout.LOGICAL_SIZE), Color(0.01, 0.02, 0.025, 0.78), true)
	_draw_texture(&"visual.art24.ui.modal_frame", Layout.GAMEPLAY_MODAL)
	var result_state := "success" if mode == "result_success" else ("failure" if mode == "result_failure" else "abandoned")
	_draw_texture(StringName("visual.art24.ui.result_banner.%s" % result_state), Layout.RESULT_BANNER)
	var title: String = {"success": "撤离完成", "failure": "探索失败", "abandoned": "探索中止"}[result_state]
	var color := Color("6fd6c1") if result_state == "success" else (Color("e56a54") if result_state == "failure" else Color("e0a34d"))
	_draw_text(title, Layout.RESULT_BANNER.position + Vector2(28, 72), 32, color, 464, HORIZONTAL_ALIGNMENT_CENTER)
	var lines := ["黑币带出        12", "安全收益         8", "长期金币预览    20", "探索房间         7", "最终协议         3"]
	if result_state == "failure":
		lines = ["失败原因      生命耗尽", "安全收益保留      8", "风险物资丢失      2", "可抢救物品        1", "最终协议          1"]
	elif result_state == "abandoned":
		lines = ["中止类型      主动放弃", "安全收益保留      8", "风险物资待结算    2", "历史记录        已登记", "最终协议          2"]
	for index in range(lines.size()):
		_draw_text(lines[index], Layout.GAMEPLAY_MODAL.position + Vector2(150, 220 + index * 44), 17, Color("ddd4c1"), 460)
	_draw_text("本局物资", Layout.GAMEPLAY_MODAL.position + Vector2(54, 444), 14, Color("c6a55e"), 100)
	var result_items := [["emergency_bandage", "急救贴", "保留"], ["copper_coil", "铜线圈", "保留"], ["scanner_probe", "扫描针", "登记"]]
	for index in range(result_items.size()):
		var cell := Rect2(Layout.GAMEPLAY_MODAL.position + Vector2(150 + index * 170, 420), Vector2(154, 70))
		draw_rect(cell, Color(0.06, 0.105, 0.105, 0.88), true)
		draw_rect(cell, Color("785a2b"), false, 1.0)
		_draw_texture(StringName("visual.art24.item.world_loot.%s" % result_items[index][0]), Rect2(cell.position + Vector2(6, 4), Vector2(60, 60)))
		_draw_text(result_items[index][1], cell.position + Vector2(66, 27), 12, Color("ddd4c1"), 82)
		var item_status: String = "丢失" if result_state == "failure" and index > 0 else String(result_items[index][2])
		_draw_text(item_status, cell.position + Vector2(66, 51), 11, Color("e36b50") if item_status == "丢失" else Color("67cdb6"), 82)
	_draw_text("返回出发探索", Layout.GAMEPLAY_MODAL.position + Vector2(110, 516), 15, Color("e2ae54"), 220, HORIZONTAL_ALIGNMENT_CENTER)
	_draw_text("返回主菜单", Layout.GAMEPLAY_MODAL.position + Vector2(430, 516), 15, Color("79cdbc"), 220, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_standard_modal(title: String, body: String, options: Array, danger: bool = false) -> void:
	draw_rect(Layout.GAMEPLAY, Color(0.01, 0.025, 0.03, 0.7), true)
	_draw_texture(&"visual.art24.ui.modal_frame", Layout.GAMEPLAY_MODAL)
	_draw_text(title, Layout.GAMEPLAY_MODAL.position + Vector2(42, 58), 25, Color("e66b52") if danger else Color("e6b85f"), 676)
	_draw_text(body, Layout.GAMEPLAY_MODAL.position + Vector2(48, 118), 16, Color("d9d0bf"), 664)
	for index in range(options.size()):
		var rect := Rect2(Layout.GAMEPLAY_MODAL.position + Vector2(70, 180 + index * 84), Vector2(620, 60))
		_draw_texture(StringName("visual.art24.ui.item_row.%s" % ("blocked" if danger and index == 0 else ("selected" if index == 0 else "normal"))), rect)
		_draw_text(String(options[index]), rect.position + Vector2(24, 38), 16, Color("e2d8c4"), 572)
	_draw_text("Enter 确认 · Esc 返回", Layout.GAMEPLAY_MODAL.position + Vector2(70, 520), 13, Color("aebbb5"), 620, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_search_progress() -> void:
	var rect := Rect2(566, 548, 440, 54)
	_draw_texture(&"visual.art24.ui.toast.info", rect)
	_draw_text("正在搜索周围物资", rect.position + Vector2(18, 32), 15, Color("d9c58d"), 226)
	var t := clampf(fmod(elapsed, 1.2) / 1.2, 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(244, 22), Vector2(166, 10)), Color("241c18"), true)
	draw_rect(Rect2(rect.position + Vector2(246, 24), Vector2(162 * t, 6)), Color("42c8ba"), true)


func _draw_toast(kind: String, text: String) -> void:
	_draw_texture(StringName("visual.art24.ui.toast.%s" % kind), Layout.TOAST)
	var color := Color("e8d6a9") if kind in ["info", "warning"] else Color("dff3e9")
	_draw_text(text, Layout.TOAST.position + Vector2(18, 32), 14, color, 444, HORIZONTAL_ALIGNMENT_CENTER)


func _monster_frame(visual_state: String, reduce_motion: bool) -> String:
	match visual_state:
		"appear":
			return "appear"
		"attack":
			return "attack_impact" if reduce_motion or int(elapsed * 8.0) % 2 == 1 else "attack_windup"
		"hit":
			return "hit"
		"defeated":
			return "remains" if reduce_motion or elapsed > 0.7 else "defeated"
		_:
			return "idle_a" if reduce_motion or int(elapsed * 3.0) % 2 == 0 else "idle_b"


func _draw_texture(visual_key: StringName, rect: Rect2, modulate: Color = Color.WHITE) -> void:
	var texture := _texture(visual_key)
	if texture != null:
		draw_texture_rect(texture, rect, false, modulate)


func _draw_texture_cover(visual_key: StringName, rect: Rect2) -> void:
	var texture := _texture(visual_key)
	if texture == null:
		draw_rect(rect, Color("172324"), true)
		return
	var source_size := texture.get_size()
	var source_aspect := source_size.x / source_size.y
	var target_aspect := rect.size.x / rect.size.y
	var region := Rect2(Vector2.ZERO, source_size)
	if source_aspect > target_aspect:
		var width := source_size.y * target_aspect
		region.position.x = (source_size.x - width) * 0.5
		region.size.x = width
	else:
		var height := source_size.x / target_aspect
		region.position.y = (source_size.y - height) * 0.5
		region.size.y = height
	draw_texture_rect_region(texture, rect, region, Color(1.08, 1.08, 1.05, 1.0))


func _texture(visual_key: StringName) -> Texture2D:
	if texture_cache.has(visual_key):
		return texture_cache[visual_key] as Texture2D
	var texture := Assets.texture(visual_key)
	texture_cache[visual_key] = texture
	return texture


func _draw_text(text: String, position: Vector2, font_size: int, color: Color, width: float = -1.0, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if body_font == null:
		return
	draw_string(body_font, position, text, alignment, width, font_size, color)


func _ease_out_cubic(value: float) -> float:
	return 1.0 - pow(1.0 - value, 3.0)
