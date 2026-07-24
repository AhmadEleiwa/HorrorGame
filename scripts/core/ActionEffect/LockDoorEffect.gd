extends ActionEffect
class_name LockDoorEffect

## Path to the AnimationPlayer relative to the scene root, and the
## animation name to play. Awaits completion before the ActionArea
## considers the effect finished.
@export var door_path: NodePath
@export var locked: bool = false

func execute(player: Node) -> void:

	var clean_path := PathFormater.get_paths(door_path)
	var door := Reteriver.get_node_safe(clean_path) as DoorWall

	if not door:
		push_warning("PlayAnimationEffect: AnimationPlayer not found at %s" % door_path)
		return

	door.locked = locked
