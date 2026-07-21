extends RefCounted
class_name RuntimeTextureCache

# Runtime actor views request the same small frame set every render tick. Keep
# an explicit strong reference per resource path so each bitmap is resolved
# once and the cache behavior remains measurable by the I1 runtime gate.

static var _textures: Dictionary = {}
static var _request_count := 0
static var _load_count := 0
static var _cache_hit_count := 0
static var _failure_count := 0


static func texture(path: String) -> Texture2D:
	_request_count += 1
	if _textures.has(path):
		var cached := _textures[path] as Texture2D
		if cached != null:
			_cache_hit_count += 1
			return cached
		_textures.erase(path)
	_load_count += 1
	var resource := ResourceLoader.load(path, "Texture2D") as Texture2D
	if resource == null:
		_failure_count += 1
		return null
	_textures[path] = resource
	return resource


static func prewarm(raw_paths: Array[String]) -> Dictionary:
	var unique_paths: Dictionary = {}
	var rejected_paths: Array[String] = []
	for raw_path in raw_paths:
		var path := String(raw_path).strip_edges()
		if path.is_empty():
			rejected_paths.append(path)
			continue
		unique_paths[path] = true
	var declared_paths: Array[String] = []
	for raw_path in unique_paths.keys():
		declared_paths.append(String(raw_path))
	declared_paths.sort()
	var loaded := 0
	var already_cached := 0
	var missing_paths: Array[String] = []
	var failure_paths: Array[String] = []
	for path in declared_paths:
		if not ResourceLoader.exists(path, "Texture2D"):
			missing_paths.append(path)
			continue
		var was_cached := contains(path)
		if was_cached:
			already_cached += 1
			continue
		if texture(path) == null:
			failure_paths.append(path)
		else:
			loaded += 1
	var cached := 0
	for path in declared_paths:
		if contains(path):
			cached += 1
	var ok := (
		cached == declared_paths.size()
		and missing_paths.is_empty()
		and failure_paths.is_empty()
		and rejected_paths.is_empty()
	)
	return {
		"ok": ok,
		"declared": declared_paths.size(),
		"declared_paths": declared_paths,
		"loaded": loaded,
		"already_cached": already_cached,
		"cached": cached,
		"missing": missing_paths.size(),
		"missing_paths": missing_paths,
		"failures": failure_paths.size(),
		"failure_paths": failure_paths,
		"rejected": rejected_paths.size(),
		"rejected_paths": rejected_paths,
	}


static func contains(path: String) -> bool:
	return _textures.has(path) and _textures[path] is Texture2D


static func metrics() -> Dictionary:
	return {
		"requests": _request_count,
		"loads": _load_count,
		"cache_hits": _cache_hit_count,
		"failures": _failure_count,
		"entries": _textures.size(),
	}


static func clear_for_tests() -> void:
	_textures.clear()
	_request_count = 0
	_load_count = 0
	_cache_hit_count = 0
	_failure_count = 0
