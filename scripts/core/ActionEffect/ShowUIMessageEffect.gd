extends ActionEffect
class_name ShowUIMessageEffect

@export_multiline var message: String = ""
@export var duration: float = 2.5

func execute(_player: Node) -> void:
	UiManager.show_message(message, duration)
