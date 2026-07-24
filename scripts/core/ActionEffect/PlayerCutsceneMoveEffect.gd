extends ActionEffect
class_name PlayerCutsceneMoveEffect

@export var direction: Vector3 = Vector3.FORWARD
@export var speed: float = 2.0
@export var duration: float = 1.5
@export var release_control_after: bool = true

func execute(player: Node) -> void:
	if not player.has_method("cutscene_move"):
		push_warning("PlayerCutsceneMoveEffect: player has no cutscene_move method")
		return

	player.cutscene_move(direction, speed)
	await player.get_tree().create_timer(duration).timeout
	player.cutscene_stop()

	if release_control_after:
		player.cutscene_end()
