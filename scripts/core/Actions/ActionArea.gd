extends Area3D
class_name ActionArea

enum TriggerMode { ON_ENTER, ON_INTERACT }

@export var enable:bool = true
@export var trigger_mode: TriggerMode = TriggerMode.ON_ENTER
@export var conditions: Array[ActionCondition] = []
@export var actions: Array[ActionEffect] = []
@export var fail_feedback: ActionEffect
@export var one_shot: bool = true


var _completed: bool = false
var _player_inside: Node = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = body

	if trigger_mode == TriggerMode.ON_ENTER:
		_try_trigger(body)


func _on_body_exited(body: Node) -> void:
	if body == _player_inside:
		_player_inside = null


func _unhandled_input(event: InputEvent) -> void:
	if trigger_mode != TriggerMode.ON_INTERACT:
		return
	if not _player_inside:
		return
	if event.is_action_pressed("interact"):
		_try_trigger(_player_inside)


func _try_trigger(player: Node) -> void:
	if one_shot and _completed :
		return
	if not enable:
		return 
	if not _conditions_met():
		if fail_feedback:
			fail_feedback.execute(player)
		return

	_completed = true
	await _run_action(player)


func _conditions_met() -> bool:
	for condition in conditions:
		if condition and not condition.is_met():
			return false
	return true


func _run_action(player: Node) -> void:
	if not enable:
		return
	if actions:
		for action in actions:
			await action.execute(player)
