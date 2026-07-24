extends ActionEffect
class_name SetFlagEffect

@export var flag_name: String = ""
@export var value: bool = true

func execute(_player: Node) -> void:
	GameState.set_flag(flag_name, value)
