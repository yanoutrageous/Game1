extends RefCounted
class_name MetaActionRequestId


static func generate(source_prefix: StringName) -> String:
	var prefix := str(source_prefix).strip_edges()
	if prefix.is_empty():
		prefix = "meta"
	var nonce := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s:%s" % [prefix, nonce]
