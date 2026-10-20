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

var held_object: InteractiveObject = null
var original_parent: Node3D = null
var original_scale: Vector3 = Vector3.ONE
var hold_base_basis: Basis = Basis.IDENTITY   # object's natural "in hand" rotation

# ============================================================
# INSPECT STATE
# ============================================================
var is_inspecting: bool = false
var is_direct_inspect: bool = false   # true for objects inspected without being "held" (locks, etc.)

# Free rotation, accumulated as deltas onto a running Basis — no Euler storage,
# so there is no gimbal lock and no flip at the poles, ever.
var inspect_spin_basis: Basis = Basis.IDENTITY
var original_global_transform: Transform3D = Transform3D.IDENTITY
var original_global_visbility:bool = true
var is_copy_inspect: bool = false
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

	# Rotate only while inspecting AND holding middle mouse button.
	if is_inspecting and event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			var yaw_delta = -event.relative.x * inspect_rotate_sensitivity
			var pitch_delta = -event.relative.y * inspect_rotate_sensitivity

			# Yaw around world-up first, then pitch around the object's OWN current
			# local right axis (post-yaw) — this is what makes it feel like you're
			# grabbing and turning the object itself, with zero flip/lock at any angle.
			inspect_spin_basis = Basis(Vector3.UP, yaw_delta) * inspect_spin_basis
			var local_right := inspect_spin_basis.x
			inspect_spin_basis = Basis(local_right, pitch_delta) * inspect_spin_basis

			inspect_spin_basis = inspect_spin_basis.orthonormalized()  # prevent float drift/skew over time

			get_viewport().set_input_as_handled()


# ============================================================
# PICKUP / DROP  (normal inventory-style hold)
# ============================================================
func pickup_object(object: InteractiveObject) -> void:
	held_object = object
	original_parent = object.get_parent()
	original_scale = object.scale
	is_direct_inspect = false

	object.freeze = true
	object.freeze_mode = InteractiveObject.FREEZE_MODE_KINEMATIC
	object.picked = true
	UiManager.hide_interaction()

	object.reparent(hold_position)  # reparent() preserves world transform by default

	hold_base_basis = object.hold_local_basis if "hold_local_basis" in object else Basis.IDENTITY

	object.tool_bar_ui()


func drop_object() -> void:
	if held_object == null:
		return

	if is_inspecting:
		_exit_inspect_mode()

	var obj := held_object

	obj.scale = original_scale

	var target_parent: Node3D = obj.parent_drop if ("parent_drop" in obj and obj.parent_drop and is_instance_valid(obj.parent_drop)) else get_tree().current_scene

	obj.reparent(target_parent)
	obj.freeze = false
	obj.hide_tool_bar_ui()
	obj.picked = false

	held_object = null
	original_parent = null
	is_direct_inspect = false


# ============================================================
# DIRECT INSPECT — for objects that should never be "held"
# (locks, wall carvings, fixed puzzle pieces, etc.)
# Skips inventory/hold state entirely; exiting inspect always
# fully releases the object back to its original parent/transform.
# ============================================================
func inspect_object(object: InteractiveObject) -> void:
	if held_object != null:
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	held_object = object
	original_parent = object.get_parent()
	original_scale = object.scale
	original_global_transform = object.global_transform   # <-- capture exact pose before touching anything
	original_global_visbility = object.visible   # <-- capture exact pose before touching anything
	is_direct_inspect = true

	object.freeze = true
	object.freeze_mode = InteractiveObject.FREEZE_MODE_KINEMATIC
	UiManager.hide_interaction()

	object.reparent(hold_position)
	object.tool_bar_ui()

	_enter_inspect_mode()

func inspect_object_copy(object: InteractiveObject) -> void:
	if held_object != null:
		return

	var copy := object.duplicate() as InteractiveObject
	get_tree().current_scene.add_child(copy)   # must be in tree before reparenting

	held_object = copy
	original_parent = null              # not used for copies — nothing to return to
	original_scale = copy.scale
	is_direct_inspect = true
	is_copy_inspect = true

	copy.freeze = true
	copy.freeze_mode = InteractiveObject.FREEZE_MODE_KINEMATIC
	UiManager.hide_interaction()

	copy.reparent(hold_position)
	copy.tool_bar_ui()

	_enter_inspect_mode()


func _finish_direct_inspect() -> void:
	if held_object == null:
		return

	var obj := held_object
	obj.hide_tool_bar_ui()

	if is_copy_inspect:
		obj.queue_free()   # discard the duplicate entirely, original untouched
	else:
		var target_parent: Node3D = original_parent if is_instance_valid(original_parent) else get_tree().current_scene
		obj.reparent(target_parent)
		obj.global_transform = original_global_transform
		obj.visible = original_global_visbility
		obj.scale = original_scale
		obj.freeze = false

	held_object = null
	original_parent = null
	is_direct_inspect = false
	is_copy_inspect = false
# ============================================================
# INSPECT MODE
# ============================================================
func _enter_inspect_mode() -> void:
	if held_object == null:
		return

	is_inspecting = true
	inspect_spin_basis = Basis.IDENTITY

	if player:
		player.suppress_look = true


func _exit_inspect_mode() -> void:
	var was_direct := is_direct_inspect
	is_inspecting = false

	if player:
		player.suppress_look = false

	if was_direct:
		_finish_direct_inspect()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ============================================================
# PHYSICS — purely local transform, driven per-object exported values.
# ============================================================
func _physics_process(delta: float) -> void:
	if held_object == null:
		return

	var weight = 1.0 - exp(-lerp_speed * delta)

	var target_local_pos: Vector3 = (
		held_object.inspect_local_position if is_inspecting
		else held_object.hold_local_position
	)
	held_object.position = held_object.position.lerp(target_local_pos, weight)

	if is_inspecting:
		# Direct assignment — no slerp. The rotation is already being smoothly
		# accumulated from mouse input each frame, so slerping it again just
		# introduces quaternion double-cover flip artifacts at certain angles.
		var face_basis = held_object.get_inspect_basis() if held_object.has_method("get_inspect_basis") else Basis.IDENTITY
		held_object.basis = (face_basis * inspect_spin_basis).orthonormalized()
	else:
		var target_local_basis: Basis = held_object.hold_local_basis if "hold_local_basis" in held_object else Basis.IDENTITY
		var q_cur := held_object.basis.get_rotation_quaternion()
		var q_tgt := target_local_basis.get_rotation_quaternion()
		held_object.basis = Basis(q_cur.slerp(q_tgt, weight))

	var target_scale = original_scale * (inspect_scale_mult if is_inspecting else 1.0)
	held_object.scale = held_object.scale.lerp(target_scale, weight)
