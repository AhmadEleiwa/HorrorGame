@tool
extends InteractiveObject
class_name Lamp
#@onready var lamp: MeshInstance3D = $lamp2/lamp
@onready var lamp_light: OmniLight3D = $lamp2/OmniLight3D

@export var enable:bool = true:
	set(value):
		enable=value
		#if enable:
		if is_inside_tree():
			lamp_light.visible = enable
func _ready() -> void:
	lamp_light.visible = enable
func interact(player:Player=null)->void:
	super.interact(player)
	if not check_interactivity():
		return
	enable = !enable
func ui_interaction() -> void:
	UiManager.show_interaction()
func hide_ui_interaction() -> void:
	UiManager.hide_interaction()
