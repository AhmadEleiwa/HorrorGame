extends Resource
class_name Reteriver

static func get_node_safe(path:NodePath):
	
	return GameState.get_tree().current_scene.get_node_or_null(path)
