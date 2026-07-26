extends RigidBody3D
class_name InteractiveObject
signal on_interact


@export_group("Hold Pose")
@export var hold_local_position: Vector3 = Vector3(-0.5, -0.3, 0.2)
@export var hold_local_basis: Basis = Basis.IDENTITY

@export_group("Inspect Pose")
@export var inspect_local_position: Vector3 = Vector3(0, 0.5, 0)
@export var inspect_face_rotation_degrees: Vector3 = Vector3.ZERO

@export_group("Drop")
@export var enable_interactivity:bool =true

## When it true  Rrturn to origin parent node, to local scene if false
@export var parent_drop:Node3D = null
func _ready() -> void:
	if not parent_drop:
		parent_drop = get_parent()
var picked:bool = false

func get_inspect_basis() -> Basis:
	return Basis.from_euler(inspect_face_rotation_degrees * (PI / 180.0))
	
func check_interactivity():
	if not is_visible_in_tree() or not enable_interactivity :
		return false
	return true
func interact(_player: Player = null) -> void:
	on_interact.emit()
func ui_interaction() -> void:
	pass

func hide_ui_interaction() -> void:
	pass
	
func tool_bar_ui():
	pass
func hide_tool_bar_ui():
	pass
