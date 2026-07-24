extends Node3D
class_name InteractiveView

# ============================================================
# NODE REFERENCES
# ============================================================
@export var raycast: RayCast3D
@export var hold_position: Node3D       # child of Camera3D — object parents here
@export var player: Player

# ============================================================
# HOLD / INSPECT CONFIG
# ============================================================
@export var lerp_speed: float = 20.0
@export var inspect_rotate_sensitivity: float = 0.01
@export var inspect_scale_mult: float = 1.2

# Local-space poses (relative to hold_position)
@export var hold_local_position: Vector3 = Vector3.ZERO
@export var inspect_local_position: Vector3 = Vector3(0	, 0.5, 0)  # pulled closer to camera

var held_object: InteractiveObject = null
var original_parent: Node3D = null
var original_scale: Vector3 = Vector3.ONE
var hold_base_basis: Basis = Basis.IDENTITY   # object's natural "in hand" rotation

# ============================================================
# INSPECT STATE
# ============================================================
var is_inspecting: bool = false
var inspect_basis: Basis = Basis.IDENTITY   # accumulated free-spin, purely local

const MAX_INSPECT_PITCH := deg_to_rad(85.0)
var inspect_yaw: float = 0.0
var inspect_pitch: float = 0.0


# ============================================================
# INPUT
# ============================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("read_paper") and held_object is InteractivePaper:
		held_object.read_paper()

	if held_object == null:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_inspecting:
			_exit_inspect_mode()
		else:
			drop_object()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("zoom_inspect"):
		if is_inspecting:
			_exit_inspect_mode()
		else:
			_enter_inspect_mode()
		get_viewport().set_input_as_handled()

	# Consume mouse motion while inspecting so it never reaches Player's look code.
	if is_inspecting and event is InputEventMouseMotion:
		inspect_yaw -= event.relative.x * inspect_rotate_sensitivity
		inspect_pitch -= event.relative.y * inspect_rotate_sensitivity
		inspect_pitch = clamp(inspect_pitch, -MAX_INSPECT_PITCH, MAX_INSPECT_PITCH)
		get_viewport().set_input_as_handled()


# ============================================================
# PICKUP / DROP  (actual reparenting happens here)
# ============================================================
func pickup_object(object: InteractiveObject) -> void:
	held_object = object
	original_parent = object.get_parent()
	original_scale = object.scale

	object.freeze = true
	object.freeze_mode = InteractiveObject.FREEZE_MODE_KINEMATIC
	object.picked = true
	UiManager.hide_interaction()

	# Reparent — Godot keeps world transform stable during reparent if you
	# use `reparent()` (Godot 4.3+), which is exactly what we want here.
	object.reparent(hold_position)

	# Base "in hand" rotation: use the object's own defined natural hold pose,
	# or identity if you don't need one.
	hold_base_basis = object.hold_local_basis if "hold_local_basis" in object else Basis.IDENTITY

	object.tool_bar_ui()


func drop_object(return_to_original_parent: bool = true) -> void:
	if held_object == null:
		return

	if is_inspecting:
		_exit_inspect_mode()

	held_object.scale = original_scale
	
	var target_parent: Node3D = original_parent if (return_to_original_parent and is_instance_valid(original_parent)) else get_tree().current_scene
	
	held_object.reparent(target_parent)  # or wherever dropped items should live
	held_object.freeze = false
	held_object.hide_tool_bar_ui()
	held_object.picked = false
	held_object = null


# ============================================================
# INSPECT MODE
# ============================================================
func _enter_inspect_mode() -> void:
	if held_object == null:
		return

	is_inspecting = true
	inspect_yaw = 0.0
	inspect_pitch = 0.0

	if player:
		player.suppress_look = true  # camera/head frozen -> local rotation IS world rotation, no drift


func _exit_inspect_mode() -> void:
	is_inspecting = false

	if player:
		player.suppress_look = false


# ============================================================
# PHYSICS — purely LOCAL transform now, since object is parented.
# No global_position / global_basis math needed at all.
# ============================================================
func _physics_process(delta: float) -> void:
	if held_object == null:
		return

	var weight = 1.0 - exp(-lerp_speed * delta)

	#var target_local_pos = inspect_local_position if is_inspecting else hold_local_position
	var target_local_pos = Vector3(-0.1	, -0.5, 0) if is_inspecting else Vector3(-0.5	, -0.3, 0.2)
	held_object.position = held_object.position.lerp(target_local_pos, weight)

	var target_local_basis: Basis
	if is_inspecting:
		var face_basis = held_object.get_inspect_basis() if held_object.has_method("get_inspect_basis") else Basis.IDENTITY
		var spin_basis = Basis(Vector3.UP, inspect_yaw) * Basis(Vector3.RIGHT, inspect_pitch)
		target_local_basis = face_basis * spin_basis
	else:
		target_local_basis = hold_base_basis

	held_object.basis = held_object.basis.slerp(target_local_basis, weight)

	var target_scale = original_scale * (inspect_scale_mult if is_inspecting else 1.0)
	held_object.scale = held_object.scale.lerp(target_scale, weight)
