extends ActionEffect
class_name SetVisibilityEffect

@export var path: NodePath
@export var value: bool = true

func execute(_player: Node) -> void:
	var clean_path = PathFormater.get_paths(path)
	var node:Node3D = Reteriver.get_node_safe(clean_path)
	if node:
		node.visible = value
