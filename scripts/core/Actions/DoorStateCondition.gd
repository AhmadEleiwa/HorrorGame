extends ActionCondition
class_name DoorStateCondition
@export var door_path: NodePath
@export var is_open: bool = false
func is_met() -> bool:
	var clean_path = PathFormater.get_paths(door_path)
	var node = Reteriver.get_node_safe( clean_path)
	if not node:
		return false
	return (node as DoorWall ).is_open ==is_open
