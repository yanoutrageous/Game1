extends SceneTree

const SkinKit := preload("res://scripts/presentation/art10_ui_skin_kit.gd")

const DISPLAY_FONT_ASSET_ID := &"ui.font.fusion_pixel"
const DISPLAY_FONT_PATH := "res://assets/fonts/FusionPixel.otf"
const FALLBACK_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Regular.otf"
const MANIFEST_PATH := "res://data/assets/asset_manifest.csv"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var player_font := SkinKit.player_ui_font()
	_require(player_font is FontVariation, "player UI font is not a FontVariation")
	if not (player_font is FontVariation):
		_finish(null)
		return

	var variation := player_font as FontVariation
	var base_font := variation.base_font as FontFile
	_require(base_font != null, "FusionPixel base font is not a FontFile")
	if base_font == null:
		_finish(null)
		return

	_require(
		base_font.resource_path == DISPLAY_FONT_PATH,
		"base font path is not FusionPixel: %s" % base_font.resource_path
	)
	_require(
		base_font.antialiasing == TextServer.FONT_ANTIALIASING_NONE,
		"FusionPixel antialiasing must be NONE, got %s" % base_font.antialiasing
	)
	_require(
		base_font.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_DISABLED,
		"FusionPixel subpixel positioning must be DISABLED, got %s" % base_font.subpixel_positioning
	)
	_require(
		not base_font.allow_system_fallback,
		"FusionPixel must disable implicit system fallback"
	)
	_check_explicit_fallback(variation)
	_check_manifest_hash()
	_check_theme_fonts(SkinKit.player_ui_theme(), variation, base_font)
	_finish(base_font)


func _check_explicit_fallback(variation: FontVariation) -> void:
	var fallback_paths: Array[String] = []
	for fallback in variation.fallbacks:
		fallback_paths.append(fallback.resource_path)
	_require(
		fallback_paths.has(FALLBACK_FONT_PATH),
		"explicit Noto glyph fallback is missing: %s" % fallback_paths
	)


func _check_manifest_hash() -> void:
	var manifest_row := _manifest_row(DISPLAY_FONT_ASSET_ID)
	_require(not manifest_row.is_empty(), "FusionPixel asset manifest row is missing")
	if manifest_row.is_empty():
		return
	_require(
		String(manifest_row.get("godot_path", "")) == DISPLAY_FONT_PATH,
		"FusionPixel manifest path drifted: %s" % manifest_row.get("godot_path", "")
	)
	var note := String(manifest_row.get("note", ""))
	var marker_index := note.to_lower().find("sha256=")
	_require(marker_index >= 0, "FusionPixel manifest note has no sha256 registration")
	if marker_index < 0:
		return
	var registered_hash := note.substr(marker_index + len("sha256="), 64).to_lower()
	var actual_hash := FileAccess.get_sha256(DISPLAY_FONT_PATH).to_lower()
	_require(
		registered_hash.length() == 64,
		"FusionPixel manifest sha256 is malformed: %s" % registered_hash
	)
	_require(
		not actual_hash.is_empty() and actual_hash == registered_hash,
		"FusionPixel file sha256 does not match manifest: actual=%s registered=%s"
		% [actual_hash, registered_hash]
	)


func _check_theme_fonts(
	theme: Theme,
	expected_variation: FontVariation,
	expected_base: FontFile
) -> void:
	_require(theme != null, "player UI theme is missing")
	if theme == null:
		return
	for entry in [
		[&"font", &"Label"],
		[&"font", &"Button"],
		[&"normal_font", &"RichTextLabel"],
		[&"bold_font", &"RichTextLabel"],
		[&"font", &"TooltipLabel"],
		[&"font", &"PopupMenu"],
	]:
		var font_name := StringName(entry[0])
		var theme_type := StringName(entry[1])
		var resolved_font := theme.get_font(font_name, theme_type)
		var consumer := "%s/%s" % [theme_type, font_name]
		_require(
			resolved_font == expected_variation,
			"%s does not resolve the shared FontVariation" % consumer
		)
		if resolved_font is FontVariation:
			_require(
				(resolved_font as FontVariation).base_font == expected_base,
				"%s does not resolve the shared FusionPixel base" % consumer
			)


func _manifest_row(asset_id: StringName) -> Dictionary:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		failures.append(
			"asset manifest could not be opened: %s" % error_string(FileAccess.get_open_error())
		)
		return {}
	var headers := file.get_csv_line()
	while file.get_position() < file.get_length():
		var values := file.get_csv_line()
		if values.is_empty() or (values.size() == 1 and String(values[0]).strip_edges().is_empty()):
			continue
		var row: Dictionary = {}
		for index in range(mini(headers.size(), values.size())):
			row[String(headers[index])] = String(values[index])
		if StringName(row.get("asset_id", "")) == asset_id:
			return row
	return {}


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(base_font: FontFile) -> void:
	var actual_policy := "unavailable"
	if base_font != null:
		actual_policy = "antialiasing=%s subpixel=%s system_fallback=%s" % [
			base_font.antialiasing,
			base_font.subpixel_positioning,
			str(base_font.allow_system_fallback).to_lower(),
		]
	if failures.is_empty():
		print(
			"I3R_FONT_RASTER_POLICY=PASS %s primary=FusionPixel fallback=Noto theme_types=6"
			% actual_policy
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R font raster policy: " + failure)
	print(
		"I3R_FONT_RASTER_POLICY=FAIL failures=%d %s primary=FusionPixel fallback=Noto theme_types=6"
		% [failures.size(), actual_policy]
	)
	quit(1)
