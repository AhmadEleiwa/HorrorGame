extends RigidBody3D
class_name InteractiveObject
signal on_interact

@export var enable_interactivity:bool =true
@export var inspect_face_rotation_degrees: Vector3 = Vector3.ZERO  # e.g. (0, 90, 0) for papers lying at 0°

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
