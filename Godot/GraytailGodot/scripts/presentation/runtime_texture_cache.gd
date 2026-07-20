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
