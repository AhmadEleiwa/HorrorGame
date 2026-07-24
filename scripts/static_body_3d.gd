extends StaticBody3D
class_name DoorOpeningScene
@onready var ui: CanvasLayer = $"../../../../CanvasLayer"

func interact(player:Node3D):
	get_tree().change_scene_to_file("res://scenes/world_2.tscn")

func ui_interaction():
	ui.visible = true
		
func hide_ui_interaction():
	ui.visible = false
