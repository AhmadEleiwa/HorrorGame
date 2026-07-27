@tool
extends StaticBody3D
class_name Door

## Reference to the main DoorWall controller.
## Automatically found if left empty.
@export var wall: DoorWall
@onready var key_lock_sound: AudioStreamPlayer3D = $"../../../../audio/key-lock-sound"

func _ready() -> void:
	if not wall:
		wall = _find_parent_wall(get_parent())
		
	if wall.is_open:
		wall.anim_player.play("instance_open")
	else:
		wall.anim_player.play("RESET")
		

func update() -> void:
	if not wall:
		wall = _find_parent_wall(get_parent())
	if not wall or not wall.anim_player:
		return
	if wall.is_open:
		wall.anim_player.play("open")
	else:
		wall.anim_player.play("close")

func interact(_player: Player = null) -> void:
	if not wall or not wall.interactable:
		return
	if wall.open_with_key != "" and GameState.has_item(wall.open_with_key ) and  wall.locked:
		key_lock_sound.play()
		wall.locked  = false
		await get_tree().create_timer(1.1).timeout
	if wall.locked:
		#if wall.lockedUIMessage:
		UiManager.show_message(wall.lockedUIMessage) if wall.lockedUIMessage else UiManager.show_message("It's locked!") 
			
		return

	wall.is_open = not wall.is_open

func ui_interaction() -> void:
	if wall and wall.interactable and wall.ui:
		wall.ui.visible = true

func hide_ui_interaction() -> void:
	if wall and wall.ui:
		wall.ui.visible = false

# Recursively finds the DoorWall ancestor up the tree
func _find_parent_wall(current_node: Node) -> DoorWall:
	while current_node:
		if current_node is DoorWall:
			return current_node as DoorWall
		current_node = current_node.get_parent()
	return null
