extends ActionEffect
class_name OpenCloseDoorEffect

## Path to the AnimationPlayer relative to the scene root, and the
## animation name to play. Awaits completion before the ActionArea
## considers the effect finished.
@export var door_path: NodePath
@export var open: bool = false

func execute(player: Node) -> void:
	var path_str := str(door_path)
	while path_str.begins_with("../"):
		path_str = path_str.trim_prefix("../")
	
	var clean_path := NodePath(path_str)
	var door := player.get_tree().current_scene.get_node_or_null(clean_path) as DoorWall

	if not door:
		push_warning("PlayAnimationEffect: AnimationPlayer not found at %s" % door_path)
		return
	print(open)
	door.is_open = open
