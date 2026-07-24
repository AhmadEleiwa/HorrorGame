extends ActionEffect
class_name DelayedEffect


@export var delay_time:float = 1.0
@export var action:ActionEffect
func execute(player: Node) -> void:
	await GameState.get_tree().create_timer(delay_time).timeout
	action.execute(player)
