extends Node3D

@onready var lamp: Lamp = $Lamp
@onready var shadows: Node3D = $shadows
var current_index = -1
var length  = 3
var last_shadow:Node3D = null
#@onready var minipuzzle_1: Node3D = $minipuzzle
@onready var minipuzzles: Node3D = $minipuzzles
@onready var slots: Node3D = $"minipuzzles/1/slots"

var last_puzzle:Node3D = null
func _on_lamp_on_interact() -> void:
	if not 	lamp.enable:
		last_shadow = 	shadows.get_child(current_index)
		last_puzzle = minipuzzles.get_child(current_index)
		
		current_index = current_index+1 if current_index < length-1 else 0
		
		shadows.get_child(current_index).visible = true
		minipuzzles.get_child(current_index).visible = true
		
		if last_shadow != null:
			last_shadow.visible = false
		if last_puzzle != null:
			last_puzzle.visible = false

func mini_puzzle_1_logic():
	pass
	


func _on_player_on_picked_object(object: InteractiveObject) -> void:
	if object is InteractivePaper:
		slots.show()


func _on_player_on_drop_object(object: InteractiveObject) -> void:
	pass
