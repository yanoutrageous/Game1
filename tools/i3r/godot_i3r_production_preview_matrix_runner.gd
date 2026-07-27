extends SceneTree

# Evidence generation only. Every case starts by instantiating the production
# main scene; this script never substitutes a preview-only UI scene. A rendered
# PNG proves that the route was generated, not that its visual quality passed.

const NavigationIntentScript := preload("res://scripts/ui/app_shell/navigation_intent.gd")
const Art10UISkinKitScript := preload("res://scripts/presentation/art10_ui_skin_kit.gd")
const DeployConfigScript := preload("res://scripts/ui/deploy_prep/deploy_config.gd")
const RunStartRouteAdapterScript := preload("res://scripts/core/run/run_start_route_adapter.gd")

const PASS_MARKER := "I3R_PRODUCTION_PREVIEW=PASS"
const FAIL_MARKER := "I3R_PRODUCTION_PREVIEW=FAIL"
const PRODUCTION_MAIN_SCENE := "res://scenes/main/main.tscn"
const FIXED_STANDARD_SEED := 730031
const ALLOWED_SCENES: Array[StringName] = [
	&"main_menu",
	&"settings",
	&"deploy",
	&"long_term",
	&"run",
	&"combat",
	&"inventory",
	&"map",
	&"result_success",
	&"result_failure",
	&"tutorial",
]
const ALLOWED_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]
const ALLOWED_UI_SCALE_PERCENT: Array[int] = [100, 125, 150]
const AUTHORITATIVE_PROBE_NAMES := {
	&"main_menu": [&"MainMenuBoardLabel_deploy", &"MainMenuBoardLabel_long_term", &"MainMenuBoardLabel_settings"],
	&"settings": [&"Resolution", &"UIScale", &"WindowMode"],
	&"deploy": [&"MapScaleTitle", &"MapDetailTitle", &"MapSelectAction"],
	&"long_term": [&"LongTermContentDetailTitle", &"LongTermContentRecordTitle", &"LongTermContentRecordBody"],
	&"run": [&"RunScannerTitle", &"RunMineRiskText", &"RunAction_map"],
	&"combat": [&"RunScannerTitle", &"RunMineRiskText", &"RunAction_combat"],
	&"inventory": [&"InventoryPanelTitle", &"InventorySummary", &"InventoryItemTooltip"],
	&"map": [&"Title", &"Detail", &"MapCell_3_3"],
	&"result_success": [&"ResultTitle", &"ResultSummary", &"ResultReturnDeployButton"],
	&"result_failure": [&"ResultTitle", &"ResultSummary", &"ResultReturnDeployButton"],
	&"tutorial": [&"Title", &"Message", &"ConfirmButton"],
}


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var options := _parse_options(OS.get_cmdline_user_args())
	var scene_id := StringName(String(options.get("scene", "run")))
	var physical_size := Vector2i(int(options.get("width", 1280)), int(options.get("height", 720)))
	var ui_scale_percent := int(options.get("ui-scale", 100))
	var output_argument := String(options.get("output", ""))
	var metadata_argument := String(options.get("metadata-output", ""))
	if not ALLOWED_SCENES.has(scene_id):
		_fail("unsupported scene=%s" % String(scene_id))
		return
	if not ALLOWED_RESOLUTIONS.has(physical_size):
		_fail("unsupported size=%dx%d" % [physical_size.x, physical_size.y])
		return
	if not ALLOWED_UI_SCALE_PERCENT.has(ui_scale_percent):
		_fail("unsupported ui_scale=%d" % ui_scale_percent)
		return
	if output_argument.is_empty():
		_fail("missing --output")
		return
	if metadata_argument.is_empty():
		_fail("missing --metadata-output")
		return

	var ui_scale_factor := float(ui_scale_percent) / 100.0
	root.size = physical_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	# Canvas scaling owns physical-resolution adaptation. UI readability scaling
	# must stay on the production Control path; applying it here would magnify
	# the world and background a second time and crop the logical 1280x720 view.
	root.content_scale_factor = 1.0
	root.transparent_bg = false
	if not is_equal_approx(root.content_scale_factor, 1.0):
		_fail("production canvas scale was not preserved")
		return
	Art10UISkinKitScript.set_runtime_ui_scale_factor(ui_scale_factor)

	var main_scene := load(PRODUCTION_MAIN_SCENE) as PackedScene
	if main_scene == null:
		_fail("production main.tscn could not be loaded")
		return
	var main := main_scene.instantiate()
	root.add_child(main)
	await _frames(18)
	var run_scene := main.get_node_or_null("RunScene")
	if run_scene == null:
		_fail("production RunScene is missing")
		return
	var applied_ui_scale := _apply_production_ui_scale(run_scene, ui_scale_factor)
	if applied_ui_scale <= 0.0:
		return
	var route_result: Dictionary = await _apply_scene(run_scene, scene_id)
	if not bool(route_result.get("ok", false)):
		return
	var stabilization_frames := await _wait_for_scene_stable(run_scene, scene_id, 5000)
	if stabilization_frames < 0:
		return
	await _frames(3)
	var effective_metrics_result := _build_effective_ui_metrics(run_scene, scene_id)
	if not bool(effective_metrics_result.get("ok", false)):
		_fail(String(effective_metrics_result.get("reason", "effective UI metrics could not be collected")))
		return
	var effective_ui_metrics := effective_metrics_result.get("metrics") as Dictionary
	var effective_ui_metrics_canonical := String(effective_metrics_result.get("canonical", ""))
	var effective_ui_metrics_sha256 := effective_ui_metrics_canonical.sha256_text().to_upper()
	var actual_ui_scale_score := int(effective_ui_metrics.get("actual_font_size_score", 0))
	var authoritative_ui_metrics := effective_metrics_result.get("authoritative_metrics") as Dictionary
	var authoritative_ui_metrics_canonical := String(effective_metrics_result.get("authoritative_canonical", ""))
	var authoritative_ui_metrics_sha256 := authoritative_ui_metrics_canonical.sha256_text().to_upper()
	var authoritative_ui_scale_score := int(authoritative_ui_metrics.get("actual_font_size_score", 0))
	if (
		effective_ui_metrics_sha256.is_empty()
		or actual_ui_scale_score <= 0
		or authoritative_ui_metrics_sha256.is_empty()
		or authoritative_ui_scale_score <= 0
	):
		_fail("visible/authoritative UI metrics did not produce stable hashes and positive actual scores")
		return

	var renderer_image := root.get_texture().get_image()
	if renderer_image == null:
		_fail("renderer returned no image")
		return
	var renderer_size := renderer_image.get_size()
	var logical_canvas_size := root.content_scale_size
	var capture_frame_result := _compose_physical_capture_frame(
		renderer_image,
		physical_size,
		logical_canvas_size
	)
	if not bool(capture_frame_result.get("ok", false)):
		_fail(String(capture_frame_result.get("reason", "physical capture frame composition failed")))
		return
	var image := capture_frame_result.get("image") as Image
	var letterbox_padding := capture_frame_result.get("letterbox_padding") as Dictionary
	var output_path := _absolute_path(output_argument)
	var metadata_path := _absolute_path(metadata_argument)
	for path in [output_path, metadata_path]:
		var mkdir_result := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		if mkdir_result != OK:
			_fail("output directory failed: %s" % error_string(mkdir_result))
			return
	var save_result := image.save_png(output_path)
	if save_result != OK:
		_fail("PNG save failed: %s" % error_string(save_result))
		return
	var png_sha256 := FileAccess.get_sha256(output_path).to_upper()
	var png_bytes := FileAccess.get_file_as_bytes(output_path).size()
	if png_sha256.is_empty() or png_bytes <= 0:
		_fail("PNG evidence could not be hashed")
		return

	var logical_size := Vector2i(
		int(round(run_scene.get_viewport_rect().size.x)),
		int(round(run_scene.get_viewport_rect().size.y))
	)
	var run_context = run_scene.get("run_context")
	var runtime_seed := int(run_context.get("seed_value")) if run_context != null else 0
	var metadata := {
		"schema_version": 5,
		"suite_id": "I3R_production_preview_matrix_case",
		"status": "GENERATED_REVIEW_REQUIRED",
		"visual_acceptance": "NOT_RUN",
		"visual_acceptance_notice": "PNG generation is diagnostic evidence and is not human visual signoff.",
		"production_scene_path": PRODUCTION_MAIN_SCENE,
		"production_main_instances": 1,
		"scene": String(scene_id),
		"route": String(route_result.get("route", "")),
		"stabilization_frames": stabilization_frames,
		"runtime_seed": runtime_seed,
		"physical_size": [physical_size.x, physical_size.y],
		"capture_frame_size": [image.get_width(), image.get_height()],
		"renderer_content_size": [renderer_size.x, renderer_size.y],
		"capture_frame_policy": "production_keep_aspect_physical_frame",
		"letterbox_padding": letterbox_padding,
		"logical_viewport_size": [logical_size.x, logical_size.y],
		"production_content_scale_size": [root.content_scale_size.x, root.content_scale_size.y],
		"content_scale_mode": root.content_scale_mode,
		"content_scale_aspect": root.content_scale_aspect,
		"canvas_content_scale_factor": root.content_scale_factor,
		"ui_scale_percent": ui_scale_percent,
		"ui_scale_factor": applied_ui_scale,
		"ui_scale_mode": "production_visible_authoritative_control_metrics",
		"effective_ui_metrics": effective_ui_metrics,
		"effective_ui_metrics_canonical": effective_ui_metrics_canonical,
		"effective_ui_metrics_sha256": effective_ui_metrics_sha256,
		"actual_ui_scale_score": actual_ui_scale_score,
		"authoritative_ui_metrics": authoritative_ui_metrics,
		"authoritative_ui_metrics_canonical": authoritative_ui_metrics_canonical,
		"authoritative_ui_metrics_sha256": authoritative_ui_metrics_sha256,
		"authoritative_ui_scale_score": authoritative_ui_scale_score,
		"logical_canvas_preserved": logical_size == root.content_scale_size,
		"screen_state": String(run_scene.get("screen_state")),
		"png_path": output_path,
		"png_bytes": png_bytes,
		"png_sha256": png_sha256,
	}
	var metadata_file := FileAccess.open(metadata_path, FileAccess.WRITE)
	if metadata_file == null:
		_fail("metadata open failed: %s" % error_string(FileAccess.get_open_error()))
		return
	metadata_file.store_string(JSON.stringify(metadata, "\t") + "\n")
	metadata_file.close()
	if not FileAccess.file_exists(metadata_path):
		_fail("metadata was not saved")
		return

	print(
		"%s scene=%s size=%dx%d ui_scale=%d output=%s metadata=%s"
		% [
			PASS_MARKER,
			String(scene_id),
			physical_size.x,
			physical_size.y,
			ui_scale_percent,
			output_path,
			metadata_path,
		]
	)
	quit(0)


func _compose_physical_capture_frame(
	renderer_image: Image,
	physical_size: Vector2i,
	logical_canvas_size: Vector2i
) -> Dictionary:
	var renderer_size := renderer_image.get_size()
	if logical_canvas_size.x <= 0 or logical_canvas_size.y <= 0:
		return {"ok": false, "reason": "logical canvas size is invalid"}
	var expected_scale := minf(
		float(physical_size.x) / float(logical_canvas_size.x),
		float(physical_size.y) / float(logical_canvas_size.y)
	)
	var expected_renderer_size := Vector2i(
		int(floor(float(logical_canvas_size.x) * expected_scale + 0.0001)),
		int(floor(float(logical_canvas_size.y) * expected_scale + 0.0001))
	)
	if renderer_size != expected_renderer_size:
		return {
			"ok": false,
			"reason": (
				"renderer size=%dx%d expected keep-aspect content=%dx%d physical=%dx%d"
				% [
					renderer_size.x,
					renderer_size.y,
					expected_renderer_size.x,
					expected_renderer_size.y,
					physical_size.x,
					physical_size.y,
				]
			),
		}
	var padding_size := physical_size - renderer_size
	if padding_size.x < 0 or padding_size.y < 0:
		return {
			"ok": false,
			"reason": (
				"renderer content=%dx%d exceeds physical frame=%dx%d"
				% [renderer_size.x, renderer_size.y, physical_size.x, physical_size.y]
			),
		}
	var top_left_padding := Vector2i(
		int(floor(float(padding_size.x) * 0.5)),
		int(floor(float(padding_size.y) * 0.5))
	)
	var bottom_right_padding := padding_size - top_left_padding
	var framed_image := renderer_image
	if renderer_size != physical_size:
		framed_image = Image.create(
			physical_size.x,
			physical_size.y,
			false,
			renderer_image.get_format()
		)
		framed_image.fill(Color(0.0, 0.0, 0.0, 1.0))
		framed_image.blit_rect(
			renderer_image,
			Rect2i(Vector2i.ZERO, renderer_size),
			top_left_padding
		)
	return {
		"ok": true,
		"image": framed_image,
		"letterbox_padding": {
			"left": top_left_padding.x,
			"top": top_left_padding.y,
			"right": bottom_right_padding.x,
			"bottom": bottom_right_padding.y,
		},
	}


func _apply_production_ui_scale(run_scene: Node, requested_scale: float) -> float:
	var scale_authority: Node = run_scene if run_scene.has_method("set_ui_scale_factor") else null
	if scale_authority == null:
		scale_authority = run_scene.get("ui_shell") as Node
	if scale_authority == null or not scale_authority.has_method("set_ui_scale_factor"):
		_fail("production UI scale authority is missing")
		return -1.0
	var accepted := bool(scale_authority.call("set_ui_scale_factor", requested_scale))
	if not accepted:
		_fail("production UI scale authority rejected %.2f" % requested_scale)
		return -1.0
	if not scale_authority.has_method("get_ui_scale_factor"):
		_fail("production UI scale authority cannot report applied scale")
		return -1.0
	var applied_scale := float(scale_authority.call("get_ui_scale_factor"))
	if not is_equal_approx(applied_scale, requested_scale):
		_fail("production UI scale %.2f did not match requested %.2f" % [applied_scale, requested_scale])
		return -1.0
	if not is_equal_approx(root.content_scale_factor, 1.0):
		_fail("UI scale changed the production canvas scale")
		return -1.0
	return applied_scale


func _build_effective_ui_metrics(run_scene: Node, scene_id: StringName) -> Dictionary:
	var metric_root := _effective_metric_root(run_scene, scene_id)
	if metric_root == null:
		return {
			"ok": false,
			"reason": "scene-specific metric root is missing scene=%s" % String(scene_id),
		}
	var layout_contract_result := _validate_scene_layout_contract(metric_root, scene_id)
	if not bool(layout_contract_result.get("ok", false)):
		return layout_contract_result
	var controls: Array[Dictionary] = []
	_collect_effective_text_control_metrics(metric_root, metric_root, controls)
	controls.sort_custom(_effective_metric_less)
	if controls.is_empty():
		return {
			"ok": false,
			"reason": "scene-specific metric root has no named text controls scene=%s root=%s"
				% [String(scene_id), String(metric_root.name)],
		}
	var font_size_sum := 0
	var combined_minimum_extent_milli_sum := 0
	var canonical_rows: Array = []
	for metric in controls:
		font_size_sum += int(metric.get("font_size", 0))
		var minimum_milli := metric.get("combined_minimum_size_milli", []) as Array
		if minimum_milli.size() == 2:
			combined_minimum_extent_milli_sum += int(minimum_milli[0]) + int(minimum_milli[1])
		canonical_rows.append(_effective_metric_canonical_row(metric))
	var root_path := String(run_scene.get_path_to(metric_root))
	var metrics := {
		"schema_version": 2,
		"scene": String(scene_id),
		"root_path": root_path,
		"visibility_policy": "is_visible_in_tree",
		"metric_count": controls.size(),
		"actual_font_size_score": font_size_sum,
		"combined_minimum_extent_milli_sum": combined_minimum_extent_milli_sum,
		"controls": controls,
	}
	var expected_probe_names: Array = AUTHORITATIVE_PROBE_NAMES.get(scene_id, [])
	if expected_probe_names.size() < 2 or expected_probe_names.size() > 4:
		return {
			"ok": false,
			"reason": "scene authoritative probe declaration must contain 2-4 names scene=%s"
				% String(scene_id),
		}
	var authoritative_controls: Array[Dictionary] = []
	var authoritative_canonical_rows: Array = []
	var authoritative_score := 0
	for raw_probe_name in expected_probe_names:
		var probe_name := String(raw_probe_name)
		var matching_controls: Array[Dictionary] = []
		for metric in controls:
			if String(metric.get("node_name", "")) == probe_name:
				matching_controls.append(metric)
		if matching_controls.size() != 1:
			return {
				"ok": false,
				"reason": (
					"authoritative visible probe must resolve exactly once scene=%s probe=%s matches=%d"
					% [String(scene_id), probe_name, matching_controls.size()]
				),
			}
		var probe_metric := matching_controls[0]
		var probe_rect_size := probe_metric.get("rect_size_milli", []) as Array
		if (
			probe_rect_size.size() != 2
			or int(probe_rect_size[0]) <= 0
			or int(probe_rect_size[1]) <= 0
		):
			return {
				"ok": false,
				"reason": "authoritative visible probe has a zero rect scene=%s probe=%s"
					% [String(scene_id), probe_name],
			}
		authoritative_controls.append(probe_metric)
		authoritative_canonical_rows.append(_effective_metric_canonical_row(probe_metric))
		authoritative_score += int(probe_metric.get("font_size", 0))
	var authoritative_probe_names: Array[String] = []
	for raw_probe_name in expected_probe_names:
		authoritative_probe_names.append(String(raw_probe_name))
	var authoritative_metrics := {
		"schema_version": 1,
		"scene": String(scene_id),
		"root_path": root_path,
		"visibility_policy": "is_visible_in_tree",
		"expected_probe_names": authoritative_probe_names,
		"probe_count": authoritative_controls.size(),
		"actual_font_size_score": authoritative_score,
		"probes": authoritative_controls,
	}
	# The canonical payload intentionally contains only observed Control metrics.
	# Requested/applied scale values are not part of this signature.
	var canonical := JSON.stringify([
		2,
		String(scene_id),
		root_path,
		canonical_rows,
	])
	var authoritative_canonical := JSON.stringify([
		1,
		String(scene_id),
		root_path,
		authoritative_probe_names,
		authoritative_canonical_rows,
	])
	return {
		"ok": true,
		"metrics": metrics,
		"canonical": canonical,
		"authoritative_metrics": authoritative_metrics,
		"authoritative_canonical": authoritative_canonical,
	}


func _validate_scene_layout_contract(metric_root: Control, scene_id: StringName) -> Dictionary:
	if scene_id != &"deploy":
		return {"ok": true}
	return _validate_deploy_layout_contract(metric_root)


func _validate_deploy_layout_contract(deploy_page: Control) -> Dictionary:
	var map_view := deploy_page.get("map_split_view") as Control
	if map_view == null:
		return {
			"ok": false,
			"reason": "deploy layout guard could not resolve the production map split view",
		}
	var expected_metric_rects := {
		&"MapMetricContent": Rect2(522, 426, 168, 52),
		&"MapMetricExit": Rect2(704, 426, 176, 52),
		&"MapMetricExperience": Rect2(522, 482, 358, 30),
	}
	var metric_controls: Dictionary = {}
	for raw_name in expected_metric_rects:
		var node_name := StringName(raw_name)
		var metric := map_view.get_node_or_null(NodePath(String(node_name))) as Label
		if metric == null:
			return {
				"ok": false,
				"reason": "deploy layout guard is missing metric=%s" % String(node_name),
			}
		var expected_rect := expected_metric_rects[node_name] as Rect2
		var rect_matches := _rect2_matches(metric.get_rect(), expected_rect)
		if node_name == &"MapMetricExperience":
			# Godot keeps a two-pixel font ascent floor at 150%; the declared
			# 358x30 text bounds remain authoritative and are verified below.
			# Permit only that bounded runtime floor, never an arbitrary
			# minimum-size expansion.
			rect_matches = _rect2_matches_with_height_slack(metric.get_rect(), expected_rect, 2.0)
		if not rect_matches:
			return {
				"ok": false,
				"reason": "deploy metric escaped fixed rect metric=%s expected=%s actual=%s"
					% [String(node_name), expected_rect, metric.get_rect()],
			}
		var fit_failure := _fixed_deploy_text_fit_failure(
			metric,
			expected_rect.size,
			Vector2(4, 2),
			&"deploy_map_text_bounds"
		)
		if not fit_failure.is_empty():
			return {
				"ok": false,
				"reason": "deploy metric fixed text contract failed metric=%s %s"
					% [String(node_name), fit_failure],
			}
		metric_controls[node_name] = metric
	var experience := metric_controls.get(&"MapMetricExperience") as Label
	for node_name in [&"MapMetricContent", &"MapMetricExit"]:
		var upper_metric := metric_controls.get(node_name) as Label
		if upper_metric.get_global_rect().intersects(experience.get_global_rect()):
			return {
				"ok": false,
				"reason": "deploy metric overlaps experience metric=%s upper=%s experience=%s"
					% [String(node_name), upper_metric.get_global_rect(), experience.get_global_rect()],
			}

	var scale_buttons := map_view.get("scale_buttons") as Dictionary
	var representative_scale := scale_buttons.get(&"7x7") as Button
	if representative_scale == null:
		return {
			"ok": false,
			"reason": "deploy layout guard could not resolve representative 7x7 scale control",
		}
	var scale_fit_failure := _fixed_deploy_text_fit_failure(
		representative_scale,
		Vector2(166, 70),
		Vector2(12, 8),
		&"deploy_map_text_bounds"
	)
	if not scale_fit_failure.is_empty():
		return {
			"ok": false,
			"reason": "deploy scale fixed text contract failed %s" % scale_fit_failure,
		}

	var summary_rows := deploy_page.get("summary_row_labels") as Array
	var expected_summary_rects := [
		Rect2(1010, 154, 200, 56),
		Rect2(1010, 234, 200, 56),
		Rect2(1010, 314, 200, 56),
		Rect2(1010, 394, 200, 56),
	]
	if summary_rows.size() != expected_summary_rects.size():
		return {
			"ok": false,
			"reason": "deploy summary fixed contract expected=%d actual=%d"
				% [expected_summary_rects.size(), summary_rows.size()],
		}
	for index in range(expected_summary_rects.size()):
		var summary_label := summary_rows[index] as Label
		var expected_summary_rect := expected_summary_rects[index] as Rect2
		if summary_label == null or not _rect2_matches(summary_label.get_rect(), expected_summary_rect):
			return {
				"ok": false,
				"reason": "deploy summary row escaped fixed rect index=%d expected=%s actual=%s"
					% [
						index,
						expected_summary_rect,
						summary_label.get_rect() if summary_label != null else Rect2(),
					],
			}
		if (
			summary_label.autowrap_mode != TextServer.AUTOWRAP_OFF
			or summary_label.max_lines_visible != 1
		):
			return {
				"ok": false,
				"reason": "deploy summary row is not a compact single-line control index=%d" % index,
			}
		var summary_fit_failure := _fixed_deploy_text_fit_failure(
			summary_label,
			expected_summary_rect.size,
			Vector2(4, 2),
			&"deploy_text_bounds"
		)
		if not summary_fit_failure.is_empty():
			return {
				"ok": false,
				"reason": "deploy summary fixed text contract failed index=%d %s"
					% [index, summary_fit_failure],
			}
	return {"ok": true}


func _fixed_deploy_text_fit_failure(
	control: Control,
	authoritative_bounds: Vector2,
	padding: Vector2,
	bounds_meta_name: StringName
) -> String:
	if control == null:
		return "control is missing"
	var declared_bounds: Vector2 = control.get_meta(bounds_meta_name, Vector2(-1, -1))
	if not _vector2_matches(declared_bounds, authoritative_bounds):
		return "declared_bounds=%s expected_bounds=%s" % [declared_bounds, authoritative_bounds]
	var fit := control.get_meta("deploy_text_fit", {}) as Dictionary
	if fit.is_empty() or not bool(fit.get("fits", false)):
		return "deploy_text_fit.fits is not true"
	var expected_available := Vector2(
		maxf(1.0, authoritative_bounds.x - padding.x * 2.0),
		maxf(1.0, authoritative_bounds.y - padding.y * 2.0)
	)
	var available: Vector2 = fit.get("available_size", Vector2(-1, -1))
	if not _vector2_matches(available, expected_available):
		return "available_size=%s expected_available=%s" % [available, expected_available]
	var measured: Vector2 = fit.get("measured_size", Vector2(INF, INF))
	if measured.x > expected_available.x + 0.01 or measured.y > expected_available.y + 0.01:
		return "measured_size=%s exceeds expected_available=%s" % [measured, expected_available]
	return ""


func _rect2_matches(actual: Rect2, expected: Rect2) -> bool:
	return (
		_vector2_matches(actual.position, expected.position)
		and _vector2_matches(actual.size, expected.size)
	)


func _rect2_matches_with_height_slack(
	actual: Rect2,
	expected: Rect2,
	maximum_extra_height: float
) -> bool:
	return (
		_vector2_matches(actual.position, expected.position)
		and is_equal_approx(actual.size.x, expected.size.x)
		and actual.size.y + 0.01 >= expected.size.y
		and actual.size.y <= expected.size.y + maximum_extra_height + 0.01
	)


func _vector2_matches(actual: Vector2, expected: Vector2) -> bool:
	return (
		is_equal_approx(actual.x, expected.x)
		and is_equal_approx(actual.y, expected.y)
	)


func _effective_metric_root(run_scene: Node, scene_id: StringName) -> Control:
	var ui_shell = run_scene.get("ui_shell")
	match scene_id:
		&"main_menu":
			if ui_shell != null and ui_shell.has_method("get_main_page"):
				return ui_shell.call("get_main_page") as Control
		&"settings":
			if ui_shell != null and ui_shell.has_method("get_settings_panel"):
				return ui_shell.call("get_settings_panel") as Control
		&"deploy":
			if ui_shell != null and ui_shell.has_method("get_deploy_page"):
				return ui_shell.call("get_deploy_page") as Control
		&"long_term":
			if ui_shell != null and ui_shell.has_method("get_long_term_page"):
				return ui_shell.call("get_long_term_page") as Control
		&"run", &"combat":
			return run_scene.get("run_surface") as Control
		&"inventory":
			return run_scene.get("inventory_panel") as Control
		&"map":
			return run_scene.get("map_overlay_panel") as Control
		&"result_success", &"result_failure":
			return run_scene.get("result_panel") as Control
		&"tutorial":
			return run_scene.get("tutorial_popup_panel") as Control
	return null


func _collect_effective_text_control_metrics(
	metric_root: Control,
	current: Node,
	controls: Array[Dictionary]
) -> void:
	if current is Control:
		var control := current as Control
		var font_metric := _effective_font_metric(control)
		if (
			control.is_visible_in_tree()
			and not font_metric.is_empty()
			and not String(control.name).is_empty()
		):
			var combined_minimum := control.get_combined_minimum_size()
			var custom_minimum := control.custom_minimum_size
			var rect_size := control.size
			var width_fits := rect_size.x + 0.01 >= combined_minimum.x
			var height_fits := rect_size.y + 0.01 >= combined_minimum.y
			controls.append({
				"node_path": "." if control == metric_root else String(metric_root.get_path_to(control)),
				"node_name": String(control.name),
				"control_class": control.get_class(),
				"font_metric": font_metric,
				"font_size": control.get_theme_font_size(font_metric),
				"visible_in_tree": control.is_visible_in_tree(),
				"rect_position_milli": _vector2_milli(control.position),
				"rect_size_milli": _vector2_milli(rect_size),
				"combined_minimum_size_milli": _vector2_milli(combined_minimum),
				"custom_minimum_size_milli": _vector2_milli(custom_minimum),
				"fit": {
					"width": width_fits,
					"height": height_fits,
					"both": width_fits and height_fits,
					"width_slack_milli": int(round((rect_size.x - combined_minimum.x) * 1000.0)),
					"height_slack_milli": int(round((rect_size.y - combined_minimum.y) * 1000.0)),
				},
			})
	for child in current.get_children():
		_collect_effective_text_control_metrics(metric_root, child, controls)


func _effective_font_metric(control: Control) -> StringName:
	if control is RichTextLabel:
		return &"normal_font_size"
	if (
		control is Label
		or control is Button
		or control is LineEdit
		or control is TextEdit
	):
		return &"font_size"
	return &""


func _effective_metric_canonical_row(metric: Dictionary) -> Array:
	var fit := metric.get("fit", {}) as Dictionary
	return [
		String(metric.get("node_path", "")),
		String(metric.get("node_name", "")),
		String(metric.get("control_class", "")),
		String(metric.get("font_metric", "")),
		int(metric.get("font_size", 0)),
		metric.get("rect_position_milli", []),
		metric.get("rect_size_milli", []),
		metric.get("combined_minimum_size_milli", []),
		metric.get("custom_minimum_size_milli", []),
		[
			bool(fit.get("width", false)),
			bool(fit.get("height", false)),
			bool(fit.get("both", false)),
			int(fit.get("width_slack_milli", 0)),
			int(fit.get("height_slack_milli", 0)),
		],
	]


func _vector2_milli(value: Vector2) -> Array[int]:
	return [
		int(round(value.x * 1000.0)),
		int(round(value.y * 1000.0)),
	]


func _effective_metric_less(left: Dictionary, right: Dictionary) -> bool:
	return String(left.get("node_path", "")) < String(right.get("node_path", ""))


func _apply_scene(run_scene: Node, scene_id: StringName) -> Dictionary:
	match scene_id:
		&"main_menu":
			run_scene.call("_show_main_menu")
			return {"ok": true, "route": "production_main_to_main_menu"}
		&"settings":
			run_scene.call("_show_main_menu")
			if not bool(run_scene.call("_show_settings_shell")):
				_fail("production Settings overlay did not open")
				return {"ok": false}
			return {"ok": true, "route": "production_main_to_settings_overlay"}
		&"deploy":
			run_scene.call("_show_deploy_shell", &"config")
			return {"ok": true, "route": "production_main_to_deploy_same_page"}
		&"long_term":
			run_scene.call("_show_long_term_shell", &"talent")
			return {"ok": true, "route": "production_main_to_long_term_talent"}
		&"tutorial":
			return await _start_tutorial_through_deploy(run_scene)
		&"run", &"inventory", &"map", &"result_success", &"result_failure", &"combat":
			if not await _start_fixed_standard(run_scene):
				return {"ok": false}
			match scene_id:
				&"inventory":
					run_scene.call("_show_inventory_panel")
				&"map":
					run_scene.call("_open_map_from_ui", &"i3r_production_preview_matrix")
				&"result_success", &"result_failure":
					var result_panel = run_scene.get("result_panel")
					if result_panel == null:
						_fail("production ResultPanel is missing")
						return {"ok": false}
					var result_snapshot := _result_snapshot(scene_id)
					var runtime_controller = run_scene.get("runtime_controller")
					if runtime_controller != null:
						runtime_controller.set("last_meta_commit", result_snapshot.get("meta_progress_commit", {}))
					run_scene.call("_on_result_available", result_snapshot)
				&"combat":
					if not _activate_combat(run_scene):
						return {"ok": false}
				_:
					pass
			return {
				"ok": true,
				"route": "production_standard_run_%s_fixed_seed_%d" % [String(scene_id), FIXED_STANDARD_SEED],
			}
		_:
			_fail("unsupported scene route=%s" % String(scene_id))
			return {"ok": false}


func _start_fixed_standard(run_scene: Node) -> bool:
	run_scene.call("_show_deploy_shell", &"config")
	await _frames(8)
	var ui_shell = run_scene.get("ui_shell")
	if ui_shell == null or not ui_shell.has_method("get_deploy_page"):
		_fail("production AppShell does not expose Deploy for fixed-seed setup")
		return false
	var deploy_page = ui_shell.call("get_deploy_page")
	if deploy_page == null:
		_fail("production Deploy page is missing for fixed-seed setup")
		return false
	deploy_page.call("_on_map_requested", &"classic_7x7_simple")
	await _frames(5)
	var deploy_config: Dictionary = deploy_page.call("_config")
	if String(deploy_config.get("map_config_id", "")) != "classic_7x7_simple":
		_fail("production Deploy did not accept the fixed-seed standard map")
		return false
	var run_start_preview := DeployConfigScript.build_run_start_config(deploy_config)
	run_start_preview["seed_value"] = FIXED_STANDARD_SEED
	var route_payload := RunStartRouteAdapterScript.payload_from_deploy_preview(
		run_start_preview,
		{
			"route_mode": &"standard_run",
			"entry_id": &"i3r_preview_fixed_standard",
			"uses_existing_route": true,
		}
	)
	run_scene.call(
		"_start_run_from_route",
		NavigationIntentScript.make_run(
			&"i3r_production_preview_matrix",
			route_payload
		)
	)
	await _frames(22)
	var context = run_scene.get("run_context")
	if context == null or not bool(context.get("run_active")):
		_fail(
			"production fixed-seed standard route did not start: %s"
			% JSON.stringify(run_scene.get("last_command_result"))
		)
		return false
	if int(context.get("seed_value")) != FIXED_STANDARD_SEED:
		_fail("production standard route did not preserve fixed preview seed")
		return false
	return true


func _start_tutorial_through_deploy(run_scene: Node) -> Dictionary:
	# The tutorial deliberately uses the ordinary Deploy map page and its normal
	# confirmation signal. It is not started through the legacy debug/tutorial
	# helper and therefore remains a map-catalog mode.
	run_scene.call("_show_deploy_shell", &"config")
	await _frames(8)
	var ui_shell = run_scene.get("ui_shell")
	if ui_shell == null or not ui_shell.has_method("get_deploy_page"):
		_fail("production AppShell does not expose Deploy")
		return {"ok": false}
	var deploy_page = ui_shell.call("get_deploy_page")
	if deploy_page == null:
		_fail("production Deploy page is missing")
		return {"ok": false}
	deploy_page.call("_on_map_requested", &"tutorial_5x5")
	await _frames(5)
	var selected_config: Dictionary = deploy_page.call("_config")
	if String(selected_config.get("map_config_id", "")) != "tutorial_5x5":
		_fail("tutorial map catalog selection did not commit")
		return {"ok": false}
	deploy_page.call("_on_primary_action_pressed")
	await _frames(24)
	var context = run_scene.get("run_context")
	if context == null or StringName(context.get("mode")) != &"tutorial":
		_fail("Deploy confirmation did not start tutorial map mode")
		return {"ok": false}
	if int(context.get("width")) != 5 or int(context.get("height")) != 5:
		_fail("tutorial production route is not fixed 5x5")
		return {"ok": false}
	return {"ok": true, "route": "production_deploy_map_catalog_to_tutorial_5x5"}


func _activate_combat(run_scene: Node) -> bool:
	var controller = run_scene.get("runtime_controller")
	var context = run_scene.get("run_context")
	var bus = run_scene.get("command_bus")
	if controller == null or context == null or bus == null:
		_fail("production combat authority is missing")
		return false
	# Keep the player-facing HUD truthful. The capture window is shorter than
	# the production warning/damage cycle, so no inflated engineering HP fixture
	# is needed to stabilize the image.
	context.max_hp = 100
	context.hp = 100
	var combat_pos: Vector2i = context.get_current_pos()
	context.truth_map.set_room_type(combat_pos, &"Monster")
	bus.room_resolver.enter_room(context)
	controller.in_run_runtime.sync_room(Vector2(0.50, 0.50))
	if context.current_room_type != &"Monster" or not controller.in_run_runtime.has_active_combat():
		_fail("production combat runtime did not activate")
		return false
	run_scene.call("_refresh_view_models")
	return true


func _wait_for_scene_stable(run_scene: Node, scene_id: StringName, timeout_msec: int) -> int:
	var consecutive_stable_frames := 0
	var observed_frames := 0
	var started_msec := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started_msec < timeout_msec:
		observed_frames += 1
		if _scene_is_stable(run_scene, scene_id):
			consecutive_stable_frames += 1
			if consecutive_stable_frames >= 3:
				return observed_frames
		else:
			consecutive_stable_frames = 0
		await create_timer(0.016).timeout
	_fail("scene stabilization timed out scene=%s timeout_msec=%d" % [String(scene_id), timeout_msec])
	return -1


func _scene_is_stable(run_scene: Node, scene_id: StringName) -> bool:
	var screen_state := StringName(run_scene.get("screen_state"))
	var ui_shell = run_scene.get("ui_shell")
	match scene_id:
		&"main_menu":
			if screen_state != &"main_menu" or ui_shell == null or not bool(ui_shell.get("visible")):
				return false
			var main_page = ui_shell.call("get_main_page") if ui_shell.has_method("get_main_page") else null
			return main_page != null and bool(main_page.get("visible"))
		&"settings":
			if screen_state != &"settings_shell" or ui_shell == null:
				return false
			var settings_panel = ui_shell.call("get_settings_panel") if ui_shell.has_method("get_settings_panel") else null
			return settings_panel != null and bool(settings_panel.get("visible"))
		&"deploy":
			if screen_state != &"deploy_shell" or ui_shell == null:
				return false
			var deploy_page = ui_shell.call("get_deploy_page") if ui_shell.has_method("get_deploy_page") else null
			return deploy_page != null and bool(deploy_page.get("visible"))
		&"long_term":
			if screen_state != &"long_term_shell" or ui_shell == null:
				return false
			var long_term_page = ui_shell.call("get_long_term_page") if ui_shell.has_method("get_long_term_page") else null
			if long_term_page == null or not bool(long_term_page.get("visible")):
				return false
			return (
				not bool(long_term_page.get("switch_running"))
				and StringName(long_term_page.get("transition_state")) == &"OPEN"
				and StringName(long_term_page.get("displayed_module_id")) == &"talent"
			)
		&"run":
			return screen_state == &"run" and _active_run_is_visible(run_scene)
		&"combat":
			var controller = run_scene.get("runtime_controller")
			return (
				screen_state == &"run"
				and _active_run_is_visible(run_scene)
				and controller != null
				and controller.in_run_runtime != null
				and controller.in_run_runtime.has_active_combat()
			)
		&"inventory":
			var inventory_panel = run_scene.get("inventory_panel")
			return (
				screen_state == &"run"
				and _active_run_is_visible(run_scene)
				and inventory_panel != null
				and bool(inventory_panel.get("visible"))
			)
		&"map":
			var map_panel = run_scene.get("map_overlay_panel")
			return (
				screen_state == &"run"
				and _active_run_is_visible(run_scene)
				and map_panel != null
				and bool(map_panel.get("visible"))
			)
		&"result_success", &"result_failure":
			var result_panel = run_scene.get("result_panel")
			return result_panel != null and bool(result_panel.get("visible"))
		&"tutorial":
			var context = run_scene.get("run_context")
			var tutorial_panel = run_scene.get("tutorial_popup_panel")
			return (
				screen_state == &"run"
				and context != null
				and StringName(context.get("mode")) == &"tutorial"
				and tutorial_panel != null
				and bool(tutorial_panel.get("visible"))
			)
	return false


func _active_run_is_visible(run_scene: Node) -> bool:
	var context = run_scene.get("run_context")
	var run_overlay = run_scene.get("run_overlay_root")
	return (
		context != null
		and bool(context.get("run_active"))
		and run_overlay != null
		and bool(run_overlay.get("visible"))
	)


func _result_snapshot(scene_id: StringName) -> Dictionary:
	var kept_item := _result_item(
		"i3r_preview_kept",
		"密封测绘记录盒",
		&"tier_5",
		2,
		"已从本次探索中保全，可带回仓库；长文本用于检查像素字体、换行和边框安全区。"
	)
	var second_item := _result_item(
		"i3r_preview_second",
		"旧式继电器",
		&"tier_2",
		1,
		"常见回收物，用于验证结果列表的品质颜色与双行信息。"
	)
	if scene_id == &"result_success":
		return {
			"outcome": "Extracted",
			"terminal_reason_code": &"extracted",
			"run_black_coin": 36,
			"backpack_used": 3,
			"backpack_capacity": 10,
			"settlement": {
				"outcome": "success",
				"black_coin_converted": 36,
				"gold_coin_gained": 36,
				"safe_yield": 36,
				"warehouse_items": [kept_item, second_item],
				"warehouse_lite": [kept_item, second_item],
				"salvaged_items": [],
				"lost_items": [],
				"lost_item_count": 0,
				"finalized": true,
			},
			"event_log": [],
			"transaction_log": [],
			"meta_progress_commit": {"status": &"committed"},
		}
	return {
		"outcome": "Failed",
		"terminal_reason_code": &"fatal_mine",
		"run_black_coin": 36,
		"backpack_used": 0,
		"backpack_capacity": 10,
		"settlement": {
			"outcome": "failure",
			"black_coin_lost": 36,
			"gold_coin_gained": 0,
			"warehouse_items": [],
			"salvaged_items": [],
			"lost_items": [kept_item, second_item],
			"lost_item_count": 2,
			"finalized": true,
		},
		"event_log": [],
		"transaction_log": [],
		"meta_progress_commit": {"status": &"committed"},
	}


func _result_item(instance_id: String, display_name: String, rarity: StringName, weight: int, description: String) -> Dictionary:
	return {
		"instance_id": instance_id,
		"item_id": instance_id,
		"display_name": display_name,
		"short_description": description,
		"item_type": &"collectible",
		"rarity": rarity,
		"weight": weight,
		"base_value": 20,
	}


func _absolute_path(argument: String) -> String:
	return argument if argument.is_absolute_path() else ProjectSettings.globalize_path(argument)


func _frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _parse_options(arguments: PackedStringArray) -> Dictionary:
	var result := {}
	for argument in arguments:
		var token := String(argument)
		if not token.begins_with("--") or not token.contains("="):
			continue
		var separator := token.find("=")
		result[token.substr(2, separator - 2)] = token.substr(separator + 1)
	return result


func _fail(message: String) -> void:
	push_error("%s %s" % [FAIL_MARKER, message])
	print("%s reason=%s" % [FAIL_MARKER, message.replace("\n", " ")])
	quit(2)
