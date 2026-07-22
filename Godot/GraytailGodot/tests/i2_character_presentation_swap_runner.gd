extends SceneTree

const CharacterPresentationCatalogScript := preload("res://scripts/presentation/character/character_presentation_catalog.gd")

const PASS_MARKER := "I2_CHARACTER_PRESENTATION_SWAP=PASS"
const FAIL_MARKER := "I2_CHARACTER_PRESENTATION_SWAP=FAIL"
const DEFAULT_ACTOR_ID := &"graytail"
const DEFAULT_APPEARANCE_ID := &"base_art21"
const DEFAULT_CLIP_ID := &"idle"
const FIXTURE_KEYS := [
	&"fixture.frame.0",
	&"fixture.frame.1",
	&"fixture.frame.2",
]
const FIXTURE_SEQUENCE := [2, 0, 1, 2, 1]
const FORBIDDEN_AUTHORITY_TOKENS := [
	"equip",
	"owned",
	"save",
	"meta",
	"inventory",
	"wallet",
	"currency",
	"purchase",
	"unlock",
	"commit",
	"transaction",
]

var failures: Array[String] = []
var fixture_textures: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_default_descriptor()
	_check_requested_identity_fallbacks()
	_check_three_frame_override()
	_check_missing_frame_bounds()
	_finish()


func _check_default_descriptor() -> void:
	var descriptor: Dictionary = CharacterPresentationCatalogScript.resolve_descriptor(
		DEFAULT_ACTOR_ID,
		DEFAULT_APPEARANCE_ID,
		DEFAULT_CLIP_ID
	)
	_require(not descriptor.is_empty(), "default descriptor is empty")
	_require_equal(descriptor.get("actor_id"), DEFAULT_ACTOR_ID, "default actor id")
	_require_equal(descriptor.get("appearance_id"), DEFAULT_APPEARANCE_ID, "default appearance id")
	_require_equal(descriptor.get("clip_id"), DEFAULT_CLIP_ID, "default clip id")
	_require_equal(descriptor.get("requested_actor_id"), DEFAULT_ACTOR_ID, "default requested actor id")
	_require_equal(descriptor.get("requested_appearance_id"), DEFAULT_APPEARANCE_ID, "default requested appearance id")
	_require_equal(descriptor.get("requested_clip_id"), DEFAULT_CLIP_ID, "default requested clip id")
	_require(not bool(descriptor.get("fallback_used", true)), "default descriptor incorrectly reports fallback")
	var visual_keys := descriptor.get("visual_keys", []) as Array
	var sequence := descriptor.get("sequence", []) as Array
	_require(not visual_keys.is_empty(), "default descriptor has no visual keys")
	_require(not sequence.is_empty(), "default descriptor has no animation sequence")
	_require(float(descriptor.get("frame_seconds", 0.0)) > 0.0, "default descriptor has invalid frame duration")
	_require(StringName(descriptor.get("fallback_visual_key", &"")) != &"", "default descriptor has no visual fallback")
	for step in range(-sequence.size() * 2, sequence.size() * 2 + 1):
		var index := CharacterPresentationCatalogScript.frame_index(descriptor, step, visual_keys.size())
		_require(index >= 0 and index < visual_keys.size(), "default frame index out of bounds at step %d: %d/%d" % [step, index, visual_keys.size()])
	var frames: Array[Texture2D] = CharacterPresentationCatalogScript.load_frames(descriptor)
	_require_equal(frames.size(), visual_keys.size(), "default audited frame load count")
	if not frames.is_empty():
		_require(CharacterPresentationCatalogScript.frame_at(frames, descriptor, sequence.size() + 3) != null, "default frame lookup returned null")
	_check_presentation_only(descriptor, "default")


func _check_requested_identity_fallbacks() -> void:
	var cases := [
		{
			"label": "actor",
			"requested": [&"missing_actor", DEFAULT_APPEARANCE_ID, DEFAULT_CLIP_ID],
		},
		{
			"label": "appearance",
			"requested": [DEFAULT_ACTOR_ID, &"missing_appearance", DEFAULT_CLIP_ID],
		},
		{
			"label": "clip",
			"requested": [DEFAULT_ACTOR_ID, DEFAULT_APPEARANCE_ID, &"missing_clip"],
		},
	]
	for case_variant in cases:
		var case := case_variant as Dictionary
		var requested := case["requested"] as Array
		var label := String(case["label"])
		var descriptor: Dictionary = CharacterPresentationCatalogScript.resolve_descriptor(
			StringName(requested[0]),
			StringName(requested[1]),
			StringName(requested[2])
		)
		_require(not descriptor.is_empty(), "%s fallback descriptor is empty" % label)
		_require_equal(descriptor.get("actor_id"), DEFAULT_ACTOR_ID, "%s fallback actor" % label)
		_require_equal(descriptor.get("appearance_id"), DEFAULT_APPEARANCE_ID, "%s fallback appearance" % label)
		_require_equal(descriptor.get("clip_id"), DEFAULT_CLIP_ID, "%s fallback clip" % label)
		_require_equal(descriptor.get("requested_actor_id"), requested[0], "%s requested actor preservation" % label)
		_require_equal(descriptor.get("requested_appearance_id"), requested[1], "%s requested appearance preservation" % label)
		_require_equal(descriptor.get("requested_clip_id"), requested[2], "%s requested clip preservation" % label)
		_require(bool(descriptor.get("fallback_used", false)), "%s fallback is not reported" % label)
		_check_presentation_only(descriptor, "%s_fallback" % label)


func _check_three_frame_override() -> void:
	var catalog := _fixture_catalog()
	var catalog_snapshot := catalog.duplicate(true)
	var descriptor: Dictionary = CharacterPresentationCatalogScript.resolve_descriptor(
		&"fixture_actor",
		&"fixture_base",
		&"idle",
		catalog
	)
	_require_equal(catalog, catalog_snapshot, "fixture catalog mutation")
	_require_equal(descriptor.get("actor_id"), &"fixture_actor", "fixture actor id")
	_require_equal(descriptor.get("appearance_id"), &"fixture_base", "fixture appearance id")
	_require_equal(descriptor.get("clip_id"), &"idle", "fixture clip id")
	_require_equal(descriptor.get("visual_keys"), FIXTURE_KEYS, "fixture visual keys")
	_require_equal(descriptor.get("sequence"), FIXTURE_SEQUENCE, "fixture arbitrary sequence")
	_require_equal(descriptor.get("frame_seconds"), 0.2, "fixture frame duration")
	_require(not bool(descriptor.get("fallback_used", true)), "fixture descriptor incorrectly reports fallback")

	var frame_zero := _make_texture(Color(0.85, 0.20, 0.16, 1.0))
	var frame_one := _make_texture(Color(0.16, 0.72, 0.28, 1.0))
	var frame_two := _make_texture(Color(0.20, 0.38, 0.88, 1.0))
	fixture_textures = {
		FIXTURE_KEYS[0]: frame_zero,
		FIXTURE_KEYS[1]: frame_one,
		FIXTURE_KEYS[2]: frame_two,
	}
	var frames: Array[Texture2D] = CharacterPresentationCatalogScript.load_frames(
		descriptor,
		Callable(self, "_resolve_fixture_texture")
	)
	_require_equal(frames.size(), 3, "fixture loaded frame count")
	var expected_indices := [2, 0, 1, 2, 1, 2, 0, 1, 2, 1]
	for step in range(expected_indices.size()):
		var index := CharacterPresentationCatalogScript.frame_index(descriptor, step, frames.size())
		_require_equal(index, expected_indices[step], "fixture sequence index at step %d" % step)
		_require(CharacterPresentationCatalogScript.frame_at(frames, descriptor, step) == frames[index], "fixture frame lookup mismatch at step %d" % step)
	_check_presentation_only(descriptor, "fixture")


func _check_missing_frame_bounds() -> void:
	var descriptor: Dictionary = CharacterPresentationCatalogScript.resolve_descriptor(
		&"fixture_actor",
		&"fixture_base",
		&"idle",
		_fixture_catalog()
	)
	var frame_zero := _make_texture(Color(0.75, 0.35, 0.10, 1.0))
	var frame_two := _make_texture(Color(0.18, 0.52, 0.82, 1.0))
	fixture_textures = {
		FIXTURE_KEYS[0]: frame_zero,
		FIXTURE_KEYS[2]: frame_two,
	}
	var substituted: Array[Texture2D] = CharacterPresentationCatalogScript.load_frames(
		descriptor,
		Callable(self, "_resolve_fixture_texture")
	)
	_require_equal(substituted.size(), 3, "single missing frame did not use visual fallback")
	if substituted.size() == 3:
		_require(substituted[1] == frame_zero, "single missing frame did not resolve to fallback texture")

	var compact_descriptor := descriptor.duplicate(true)
	compact_descriptor["fallback_visual_key"] = &"fixture.frame.missing"
	fixture_textures = {
		FIXTURE_KEYS[1]: _make_texture(Color(0.45, 0.72, 0.22, 1.0)),
		FIXTURE_KEYS[2]: frame_two,
	}
	var slot_preserved_frames: Array[Texture2D] = CharacterPresentationCatalogScript.load_frames(
		compact_descriptor,
		Callable(self, "_resolve_fixture_texture")
	)
	_require_equal(slot_preserved_frames.size(), 3, "missing first frame did not preserve semantic key slots")
	if slot_preserved_frames.size() == 3:
		_require(slot_preserved_frames[0] == slot_preserved_frames[1], "missing first frame did not use an available in-place fallback")
		_require(CharacterPresentationCatalogScript.frame_at(slot_preserved_frames, compact_descriptor, 0) == frame_two, "sequence key 2 was remapped after the first key went missing")
	for step in range(-20, 21):
		var index := CharacterPresentationCatalogScript.frame_index(compact_descriptor, step, slot_preserved_frames.size())
		_require(index >= 0 and index < slot_preserved_frames.size(), "missing-frame index out of bounds at step %d: %d/%d" % [step, index, slot_preserved_frames.size()])
		_require(CharacterPresentationCatalogScript.frame_at(slot_preserved_frames, compact_descriptor, step) != null, "missing-frame lookup returned null at step %d" % step)
	_require_equal(CharacterPresentationCatalogScript.frame_index(compact_descriptor, 7, 0), -1, "zero-frame index sentinel")
	_require(CharacterPresentationCatalogScript.frame_at([], compact_descriptor, 7) == null, "zero-frame lookup must be null")
	_check_presentation_only(compact_descriptor, "missing_frame")


func _fixture_catalog() -> Dictionary:
	return {
		"default_actor_id": &"fixture_actor",
		"actors": {
			&"fixture_actor": {
				"default_appearance_id": &"fixture_base",
				"appearances": {
					&"fixture_base": {
						"default_clip_id": &"idle",
						"clips": {
							&"idle": {
								"visual_keys": FIXTURE_KEYS,
								"sequence": FIXTURE_SEQUENCE,
								"frame_seconds": 0.2,
								"flip_h": false,
								"fallback_visual_key": FIXTURE_KEYS[0],
							},
						},
					},
				},
			},
		},
	}


func _make_texture(color: Color) -> Texture2D:
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _resolve_fixture_texture(visual_key: StringName) -> Texture2D:
	return fixture_textures.get(visual_key, null) as Texture2D


func _check_presentation_only(descriptor: Dictionary, label: String) -> void:
	for raw_key in descriptor.keys():
		var key := String(raw_key).to_lower()
		for token in FORBIDDEN_AUTHORITY_TOKENS:
			_require(not key.contains(token), "%s descriptor leaks non-presentation authority key: %s" % [label, key])


func _require_equal(actual: Variant, expected: Variant, label: String) -> void:
	_require(actual == expected, "%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("%s default=%s/%s/%s fixture_frames=3 sequence_steps=5 fallbacks=actor,appearance,clip missing_frame=bounded authority=presentation_only" % [
			PASS_MARKER,
			String(DEFAULT_ACTOR_ID),
			String(DEFAULT_APPEARANCE_ID),
			String(DEFAULT_CLIP_ID),
		])
		quit(0)
		return
	for failure in failures:
		push_error("I2 character presentation swap failure: " + failure)
	print("%s failures=%d" % [FAIL_MARKER, failures.size()])
	quit(1)
