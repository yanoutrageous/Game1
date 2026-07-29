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
	var display_font := SkinKit.pixel_font()
	var readable_font := SkinKit.readable_font()
	_require(display_font is FontVariation, "display font is not a FontVariation")
	_require(readable_font is FontVariation, "readable font is not a FontVariation")
	if not (display_font is FontVariation) or not (readable_font is FontVariation):
		_finish(null)
		return

	var display_variation := display_font as FontVariation
	var readable_variation := readable_font as FontVariation
	var base_font := display_variation.base_font as FontFile
	var readable_base := readable_variation.base_font as FontFile
	_require(base_font != null, "FusionPixel base font is not a FontFile")
	_require(readable_base != null, "Noto readable base font is not a FontFile")
	if base_font == null or readable_base == null:
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
	_require(readable_base.resource_path == FALLBACK_FONT_PATH, "readable base path is not Noto CJK")
	_require(readable_base.antialiasing == TextServer.FONT_ANTIALIASING_GRAY, "Noto readable antialiasing is not grayscale")
	_require(readable_base.subpixel_positioning == TextServer.SUBPIXEL_POSITIONING_AUTO, "Noto readable subpixel positioning is not automatic")
	_require(not readable_base.allow_system_fallback, "Noto readable font must disable implicit system fallback")
	_check_explicit_fallback(display_variation, FALLBACK_FONT_PATH)
	_check_explicit_fallback(readable_variation, DISPLAY_FONT_PATH)
	_check_manifest_hash()
	_check_theme_fonts(SkinKit.player_ui_theme(), display_variation, readable_variation)
	_finish(base_font)


func _check_explicit_fallback(variation: FontVariation, expected_path: String) -> void:
	var fallback_paths: Array[String] = []
	for fallback in variation.fallbacks:
		fallback_paths.append(fallback.resource_path)
	_require(
		fallback_paths.has(expected_path),
		"explicit glyph fallback is missing (%s): %s" % [expected_path, fallback_paths]
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
	display_variation: FontVariation,
	readable_variation: FontVariation
) -> void:
	_require(theme != null, "player UI theme is missing")
	if theme == null:
		return
	for entry in [
		[&"font", &"Label", readable_variation],
		[&"font", &"Button", readable_variation],
		[&"normal_font", &"RichTextLabel", readable_variation],
		[&"bold_font", &"RichTextLabel", readable_variation],
		[&"font", &"TooltipLabel", readable_variation],
		[&"font", &"PopupMenu", readable_variation],
	]:
		var font_name := StringName(entry[0])
		var theme_type := StringName(entry[1])
		var expected_variation := entry[2] as FontVariation
		var resolved_font := theme.get_font(font_name, theme_type)
		var consumer := "%s/%s" % [theme_type, font_name]
		_require(
			resolved_font == expected_variation,
			"%s does not resolve its role-specific FontVariation" % consumer
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
			"I3R_FONT_RASTER_POLICY=PASS %s display=FusionPixel readable=Noto theme_types=6"
			% actual_policy
		)
		quit(0)
		return
	for failure in failures:
		push_error("I3R font raster policy: " + failure)
	print(
		"I3R_FONT_RASTER_POLICY=FAIL failures=%d %s display=FusionPixel readable=Noto theme_types=6"
		% [failures.size(), actual_policy]
	)
	quit(1)
