@tool
extends StaticBody3D
class_name DoorWall

## Assign the door node in the Inspector or leave empty to auto-find.
@export var door_node: Door

## Assign your AnimationPlayer and CanvasLayer in the Inspector.
@export var anim_player: AnimationPlayer
@export var ui: CanvasLayer
@export_multiline var lockedUIMessage:String = "It's Locked"
@export var interactable: bool = true

@export var is_open: bool = false:
	set(value):
		is_open = value
		if is_open:
			locked = false
		_sync_state()

@export var locked: bool = false:
	set(value):
		locked = value
		if locked and is_open:
			is_open = false
			_sync_state()
@export var open_with_key:String = ""
var is_slow_opening: bool = false

func open_slowly(duration: float = 3.5) -> void:
	if is_open:
		return
	is_slow_opening = true
	locked = false
	is_open = true
	is_slow_opening = false
	if anim_player and anim_player.has_animation("open"):
		var speed = 0.333 / max(duration, 0.1)
		anim_player.play("open", -1, speed)
		var audio = get_node_or_null("audio/AudioStreamPlayer3D") as AudioStreamPlayer3D
		if audio:
			audio.pitch_scale = 0.65
			audio.play()
func _ready() -> void:
	# Fallback auto-discovery if exports aren't manually set
	if not door_node:
		door_node = _find_child_door(self)
	if not anim_player and has_node("AnimationPlayer"):
		anim_player = $AnimationPlayer
	if not ui and has_node("CanvasLayer"):
		ui = $CanvasLayer

	#_sync_state()

func _sync_state() -> void:
	if not is_node_ready():
		return
		
	if door_node and door_node.has_method("update"):
		door_node.update()

# Recursively searches children for a Door instance without relying on brittle node paths
func _find_child_door(parent_node: Node) -> Door:
	for child in parent_node.get_children():
		if child is Door:
			return child
		var sub_child := _find_child_door(child)
		if sub_child:
			return sub_child
	return null
func ui_interaction() -> void:
	UiManager.show_interaction()

func hide_ui_interaction() -> void:
	UiManager.hide_interaction()
