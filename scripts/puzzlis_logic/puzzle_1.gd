extends Node3D

@onready var lamp: Lamp = $Lamp
@onready var shadows: Node3D = $shadows

#@onready var minipuzzle_1: Node3D = $minipuzzle
@onready var minipuzzles: Node3D = $minipuzzles
@onready var slots: Node3D = $"minipuzzles/1/slots"
@onready var book: InteractiveObject = $"minipuzzles/2/Book"
@onready var slot: Slot = $"minipuzzles/1/slots/Slot"
@onready var slot_2: Slot = $"minipuzzles/1/slots/Slot2"
@onready var slot_3: Slot = $"minipuzzles/1/slots/Slot3"
@onready var slot_4: Slot = $"minipuzzles/1/slots/Slot4"
@onready var paper: InteractivePaper = $"minipuzzles/1/papers/Paper"
@onready var paper_2: InteractivePaper = $"minipuzzles/1/papers/Paper2"
@onready var paper_3: InteractivePaper = $"minipuzzles/1/papers/Paper3"
@onready var paper_4: InteractivePaper = $"minipuzzles/1/papers/Paper4"
@onready var paper_5: InteractivePaper = $"minipuzzles/1/papers/Paper5"
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var book_slot: Slot = $"minipuzzles/1/slots/BookSlot"

var current_index = -1
var length  = 3
var last_shadow:Node3D = null
var last_puzzle:Node3D = null

var puzzles_stats ={
	0:{'solved':false},
	1:{'solved':false},
	2:{'solved':false},
	
}
func _on_lamp_on_interact() -> void:
	if not 	lamp.enable:
		last_shadow = 	shadows.get_child(current_index)
		last_puzzle = minipuzzles.get_child(current_index)
		
		current_index = current_index+1 if current_index < length-1 else 0
		
		shadows.get_child(current_index).visible = true
		minipuzzles.get_child(current_index).visible = true
		book.parent_drop = minipuzzles.get_child(current_index) 
		if last_shadow != null:
			last_shadow.visible = false
		if last_puzzle != null:
			last_puzzle.visible = false

func mini_puzzle_1_logic():
	if puzzles_stats[0].solved:
		return
	var puzzle_1_solved:bool = (
		slot.holding_object == paper 
	and slot_2.holding_object == paper_2
	and slot_3.holding_object == paper_3
	and slot_4.holding_object == paper_4
	and book_slot.holding_object == book
	)
	if puzzle_1_solved :
		lamp.hide()
		puzzles_stats[0].solved = true
		animation_player.play("puzzle_1_mini_puzzle_1")
		paper.enable_interactivity = false
		paper_2.enable_interactivity = false
		paper_3.enable_interactivity = false
		paper_4.enable_interactivity = false
		paper_5.enable_interactivity = false
		book.enable_interactivity = false
		
	
func _process(delta: float) -> void:
	mini_puzzle_1_logic()

func _on_player_on_picked_object(object: InteractiveObject) -> void:
	if object is InteractivePaper:
		slots.show()


func _on_player_on_drop_object(object: InteractiveObject) -> void:
	pass
