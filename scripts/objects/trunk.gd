extends InteractiveObject
class_name InteractiveTrunk
@onready var lock: InteractiveLock = $Lock
@onready var lock_2: InteractiveLock = $Lock2
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var secret_code: Array[int] = [1, 2, 3] 
signal trunk_open
func _ready() -> void:
	for i in range(secret_code.size()):
		lock.secret_code[i] = secret_code[i]
		lock_2.secret_code[i] = secret_code[i]
		
func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity():
		return
	if lock.is_unlocked:
		return
	_player.interactive_view.inspect_object(lock)
	lock.show()

func ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.show_interaction("[E]")
func hide_ui_interaction() -> void:
	UiManager.hide_interaction()
func _on_lock_combination_changed(combination: Array[int]) -> void:
	for i in range(combination.size()):
		if i < lock_2.wheel_values.size():
			lock_2.set_wheel_value(i, combination[i])
	
func _on_lock_lock_unlocked() -> void:
	lock_2.freeze = false
	animation_player.play("open")
	trunk_open.emit()
