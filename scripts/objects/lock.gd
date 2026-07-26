extends InteractiveObject
class_name InteractiveLock
# --- Secret Code Config ---
# Change this in the Godot Inspector to set the correct answer!
@export var secret_code: Array[int] = [1, 2, 3] 

# Signals
signal combination_changed(combination: Array[int])
signal lock_unlocked() # Emitted when the correct code is entered


# --- Node References ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wheels: Array[MeshInstance3D] = [
	$"lock/text-1781213964465_003", # Index 0 (Row 1)
	$"lock/text-1781213964465_001", # Index 1 (Row 2)
	$"lock/text-1781213964465_002"  # Index 2 (Row 3)
]

# --- Wheel State Tracking ---
var wheel_values: Array[int] = [0, 0, 0]
var active_tweens: Dictionary = {}
var is_unlocked: bool = false

# Measured angle presets for numbers 0 through 9
const DEGREES: Array[float] = [
	-8.2,  # 0
	31.0,  # 1
	67.0,  # 2
	101.0, # 3
	132.0, # 4
	172.0, # 5
	211.0, # 6
	250.0, # 7
	285.0, # 8
	315.0  # 9
]


func interact(_player: Player = null) -> void:	
	super.interact(_player)
	#if _player and _player.interactive_view:
		#_player.interactive_view.inspect_object(self)


# --- Generic Input Handling ---
func _handle_row_click(row_idx: int) -> void:
	# Ignore clicks if animating or already unlocked
	if is_unlocked or active_tweens.get(row_idx, false):
		return
		
	active_tweens[row_idx] = true
	
	# Advance value (0-9)
	wheel_values[row_idx] = (wheel_values[row_idx] + 1) % DEGREES.size()
	
	var mesh: MeshInstance3D = wheels[row_idx]
	var target_y_deg: float = DEGREES[wheel_values[row_idx]]
	
	# Animate rotation
	var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh, "rotation_degrees:y", target_y_deg, 0.3)
	
	tween.finished.connect(func():
		active_tweens[row_idx] = false
		_on_wheel_rotated()
	)


# --- Check Solution Logic ---
func _on_wheel_rotated() -> void:
	combination_changed.emit(wheel_values)
	print("Current Combination: ", wheel_values)
	
	# Compare current combination to secret_code
	if check_code():
		is_unlocked = true
		animation_player.play("unlocked")
		lock_unlocked.emit()
		_on_lock_success()


func check_code() -> bool:
	# Returns true only if all 3 digits match the exported secret_code
	return wheel_values == secret_code


func _on_lock_success() -> void:
	# Add any visual or sound effects when unlocked (e.g. play sound, open door animation)
	pass


# --- Input Event Callbacks ---
func _on_row_1_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _is_left_click(event):
		_handle_row_click(0)

func _on_row_2_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _is_left_click(event):
		_handle_row_click(1)

func _on_row_3_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _is_left_click(event):
		_handle_row_click(2)


func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
