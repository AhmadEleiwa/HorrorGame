extends InteractiveObject
@onready var lock: InteractiveLock = $Lock
@onready var lock_2: InteractiveLock = $Lock2
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var secret_code: Array[int] = [1, 2, 3] 
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


func _on_lock_combination_changed(combination: Array[int]) -> void:
	if lock_2.wheel_values[0] < combination[0]:
		lock_2._handle_row_click(0)
	if lock_2.wheel_values[1] < combination[1]:
		lock_2._handle_row_click(1)
	if lock_2.wheel_values[2] < combination[2]:
		lock_2._handle_row_click(2)
	


func _on_lock_lock_unlocked() -> void:
	lock_2.freeze = false
	animation_player.play("open")
