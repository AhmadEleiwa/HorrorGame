extends Node3D
class_name Puzzle2

@export var door_path: NodePath
@export var key_2_path: NodePath
@export var slot_teddy_path: NodePath
@export var slot_vhs_path: NodePath
@export var slot_clock_path: NodePath
@export var radio_audio_path: NodePath
@export var solve_audio_path: NodePath
@export var trunk_path: NodePath

var door: DoorWall = null
var key_2: RigidBody3D = null
var slot_teddy: Slot = null
var slot_vhs: Slot = null
var slot_clock: Slot = null
var radio_audio: AudioStreamPlayer3D = null
var solve_audio: AudioStreamPlayer3D = null
var trunk: InteractiveTrunk = null

var solved: bool = false
var room_entered: bool = false

func _resolve_node(path: NodePath) -> Node:
	if path.is_empty():
		return null
	var n = get_node_or_null(path)
	if n:
		return n
	if get_tree() and get_tree().current_scene:
		n = get_tree().current_scene.get_node_or_null(path)
		if n:
			return n
	n = get_node_or_null(NodePath("../" + str(path)))
	return n

func _ready() -> void:
	door = _resolve_node(door_path) as DoorWall
	key_2 = _resolve_node(key_2_path) as RigidBody3D
	slot_teddy = _resolve_node(slot_teddy_path) as Slot
	slot_vhs = _resolve_node(slot_vhs_path) as Slot
	slot_clock = _resolve_node(slot_clock_path) as Slot
	radio_audio = _resolve_node(radio_audio_path) as AudioStreamPlayer3D
	solve_audio = _resolve_node(solve_audio_path) as AudioStreamPlayer3D
	trunk = _resolve_node(trunk_path) as InteractiveTrunk

	if key_2:
		key_2.visible = false
		key_2.freeze = true

func on_player_enter_room() -> void:
	if room_entered:
		return
	room_entered = true

	# Slam door shut and lock
	if door:
		door.is_open = false
		door.locked = true

	# Start radio creepy audio
	if radio_audio and not radio_audio.playing:
		radio_audio.play()

	UiManager.show_message("The bedroom door slammed shut! The air feels ice cold...", 3.5)

func _process(_delta: float) -> void:
	if solved:
		return
	if not slot_teddy or not slot_vhs or not slot_clock:
		return

	var is_teddy_placed = slot_teddy.holding_object != null and (slot_teddy.holding_object.is_in_group("teddy") or slot_teddy.holding_object.name.contains("Teddy"))
	var is_vhs_placed = slot_vhs.holding_object != null and (slot_vhs.holding_object.is_in_group("vhs") or slot_vhs.holding_object.name.contains("VHS"))
	var is_clock_placed = slot_clock.holding_object != null and (slot_clock.holding_object.is_in_group("clock") or slot_clock.holding_object.name.contains("Clock"))

	if is_teddy_placed and is_vhs_placed and is_clock_placed:
		_solve_puzzle()

func _solve_puzzle() -> void:
	solved = true
	CrazyGamesSDK.happy_time()
	if radio_audio:
		radio_audio.stop()
	if solve_audio:
		solve_audio.play()

	# Disable further interactivity on the relics
	if slot_teddy.holding_object: slot_teddy.holding_object.enable_interactivity = false
	if slot_vhs.holding_object: slot_vhs.holding_object.enable_interactivity = false
	if slot_clock.holding_object: slot_clock.holding_object.enable_interactivity = false

	# Reveal and drop key_2
	if key_2:
		key_2.visible = true
		key_2.freeze = false

	# Unlock and open bedroom door
	if door:
		door.locked = false
		door.is_open = true

	UiManager.show_message("A silver key dropped onto the bedside table! The door clicked open.", 4.0)
