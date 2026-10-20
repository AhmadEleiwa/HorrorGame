extends InteractiveObject
class_name InteractiveLock

# --- Secret Code Config ---
@export var secret_code: Array[int] = [1, 2, 3] 

# Signals
signal combination_changed(combination: Array[int])
signal lock_unlocked()

# --- Node References ---
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var wheels: Array[MeshInstance3D] = [
	$"lock/text-1781213964465_003", # Index 0 (Row 1)
	$"lock/text-1781213964465_001", # Index 1 (Row 2)
	$"lock/text-1781213964465_002"  # Index 2 (Row 3)
]
@onready var row1: Area3D = get_node_or_null("row1")
@onready var row2: Area3D = get_node_or_null("row2")
@onready var row3: Area3D = get_node_or_null("row3")

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

func _ready() -> void:
	super._ready()
	# The root RigidBody3D should NOT intercept mouse clicks intended for the digit rows
	input_ray_pickable = false

	# Ensure row Area3Ds are pickable
	for r in [row1, row2, row3]:
		if r:
			r.input_ray_pickable = true

	# Set initial wheel rotation to match starting wheel values
	for i in range(wheels.size()):
		if i < wheel_values.size() and wheels[i]:
			wheels[i].rotation_degrees.y = DEGREES[posmod(wheel_values[i], DEGREES.size())]

func tool_bar_ui() -> void:
	UiManager.show_tool_bar("LMB: Turn Digit", "MMB: Rotate Lock", "RMB: Put Back")

func hide_tool_bar_ui() -> void:
	UiManager.hide_tool_bar()

func interact(_player: Player = null) -> void:	
	super.interact(_player)

func set_wheel_value(row_idx: int, value: int) -> void:
	if row_idx < 0 or row_idx >= wheels.size() or row_idx >= wheel_values.size():
		return
	wheel_values[row_idx] = posmod(value, DEGREES.size())
	var mesh: MeshInstance3D = wheels[row_idx]
	if mesh:
		mesh.rotation_degrees.y = DEGREES[wheel_values[row_idx]]

# --- Generic Input Handling ---
func _handle_row_click(row_idx: int) -> void:
	if is_unlocked or active_tweens.get(row_idx, false):
		return
		
	active_tweens[row_idx] = true
	
	# Advance value (0-9)
	wheel_values[row_idx] = (wheel_values[row_idx] + 1) % DEGREES.size()
	
	var mesh: MeshInstance3D = wheels[row_idx]
	if mesh:
		var target_y_deg: float = DEGREES[wheel_values[row_idx]]
		var tween: Tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(mesh, "rotation_degrees:y", target_y_deg, 0.25)
		tween.finished.connect(func():
			active_tweens[row_idx] = false
			_on_wheel_rotated()
		)
	else:
		active_tweens[row_idx] = false
		_on_wheel_rotated()

# --- Check Solution Logic ---
func _on_wheel_rotated() -> void:
	combination_changed.emit(wheel_values)
	print("Current Combination: ", wheel_values, " Target: ", secret_code)
	
	if check_code():
		is_unlocked = true
		animation_player.play("unlocked")
		lock_unlocked.emit()
		_on_lock_success()

		# Return from direct inspect view after a brief delay so player sees trunk open
		get_tree().create_timer(0.7).timeout.connect(func():
			var p = get_tree().get_first_node_in_group("player") as Player
			if p and p.interactive_view and p.interactive_view.held_object == self:
				p.interactive_view._exit_inspect_mode()
		)

func check_code() -> bool:
	return wheel_values == secret_code

func _on_lock_success() -> void:
	pass

# --- Built-in Input Event Callbacks ---
func _on_row_1_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _is_left_click(event):
		_handle_row_click(0)
		get_viewport().set_input_as_handled()

func _on_row_2_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _is_left_click(event):
		_handle_row_click(1)
		get_viewport().set_input_as_handled()

func _on_row_3_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if _is_left_click(event):
		_handle_row_click(2)
		get_viewport().set_input_as_handled()

func _is_left_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT

# --- Active Inspect Click Detection (Fallback & Precision) ---
func _input(event: InputEvent) -> void:
	if not is_instance_valid(self) or not is_visible_in_tree() or is_unlocked:
		return

	var p = get_tree().get_first_node_in_group("player") as Player
	if not (p and p.interactive_view and p.interactive_view.is_inspecting and p.interactive_view.held_object == self):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_click_digits(event.position)

func _try_click_digits(mouse_pos: Vector2) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if not cam:
		return

	# Method 1: Physics Raycast against Area3Ds
	var from: Vector3 = cam.project_ray_origin(mouse_pos)
	var to: Vector3 = from + cam.project_ray_normal(mouse_pos) * 10.0
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := space.intersect_ray(query)

	if hit and hit.has("collider"):
		var col = hit.collider
		if col == row1:
			_handle_row_click(0)
			get_viewport().set_input_as_handled()
			return
		elif col == row2:
			_handle_row_click(1)
			get_viewport().set_input_as_handled()
			return
		elif col == row3:
			_handle_row_click(2)
			get_viewport().set_input_as_handled()
			return

	# Method 2: Screen-space unproject fallback
	var rows := [row1, row2, row3]
	var best_idx := -1
	var best_dist := 65.0
	for i in range(rows.size()):
		var r = rows[i]
		if r:
			var s_pos := cam.unproject_position(r.global_position)
			var d := mouse_pos.distance_to(s_pos)
			if d < best_dist:
				best_dist = d
				best_idx = i

	if best_idx != -1:
		_handle_row_click(best_idx)
		get_viewport().set_input_as_handled()
