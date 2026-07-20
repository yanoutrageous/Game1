extends RefCounted
class_name ContentDBAccess

# Keeps reusable scripts independent from the compile-time autoload identifier.
# The project metadata gate still verifies that the ContentDB autoload exists and
# initializes; callers simply resolve that runtime service through the scene tree.


static func has_asset(asset_id: StringName) -> bool:
	var content_db := _resolve_content_db()
	return content_db != null and content_db.has_method("has_asset") and bool(content_db.call("has_asset", asset_id))


static func get_asset_ref(asset_id: StringName) -> Resource:
	var content_db := _resolve_content_db()
	if content_db == null or not content_db.has_method("get_asset_ref"):
		return null
	var resource: Variant = content_db.call("get_asset_ref", asset_id)
	return resource as Resource if resource is Resource else null


static func _resolve_content_db() -> Node:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return null
	return (main_loop as SceneTree).root.get_node_or_null("ContentDB")
