@tool
extends InteractiveObject
class_name Slot
var holding_object:InteractiveObject = null
@onready var object_name: Label3D = $ObjectName
#@onready var mesh: MeshInstance3D = $MeshInstance3D

@export var group_name:String

@export var mesh:Node3D = null

func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity()  :
		return
	var obj = _player.holding_object()
	if holding_object and  obj:
		
		_player.drop_object()
		_player.pickup_object(holding_object)
		obj.global_position = global_position
		obj.rotation = rotation
		
		obj.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		obj.freeze = true
		hide_mesh()

		holding_object = obj
		return
	if holding_object  :
		_player.pickup_object(holding_object)
		holding_object = null
		mesh.show()
		
		return
	if _player.holding_object() == null:
		return
	
	
	if not obj.is_in_group(group_name):
		return 
	_player.drop_object()
	obj.global_position = global_position
	obj.rotation = rotation
	
	obj.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	obj.freeze = true
	hide_mesh()

	holding_object = obj
		
func hide_mesh():
	#print(mesh)
	mesh.visible = false

func hide_ui_interaction() -> void:
	if not check_interactivity():
		return
	object_name.hide()
	UiManager.hide_interaction()
func ui_interaction() -> void:
	if not check_interactivity():
		return
	if holding_object:
		object_name.text = holding_object.title
		object_name.show()
	UiManager.show_interaction()
