extends ActionEffect
class_name ToggleLightEffect

@export var light_path: NodePath
@export var enabled: bool = true

func execute(player: Node) -> void:
	var clean_path = PathFormater.get_paths(light_path)
	var light = Reteriver.get_node_safe(clean_path)
	if light is Lamp:
		print("ss")
		light.enable = enabled
		return
	if light:
		light.visible = enabled
