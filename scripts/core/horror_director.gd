extends Node
class_name HorrorDirector

@export var level_root: Node3D
@export var player: Player

# Puzzle References
@export var puzzle_1: Node3D
@export var puzzle_2: Node3D
@export var puzzle_3: Node3D

# Doors
@export var front_door: DoorWall
@export var door_4: DoorWall   # Upstairs study
@export var door_5: DoorWall   # Room 1 (Puzzle 1)
@export var door_6: DoorWall   # Corridor door (key_1)
@export var door_9: DoorWall   # Room 2 (Bedroom)

# Sounds
@export var ambience_player: AudioStreamPlayer
@export var jumpscare_audio: AudioStreamPlayer3D
@export var weird_audio: AudioStreamPlayer3D
@export var monster_jumpscare_node: Node3D

var escape_active: bool = false
var front_door_triggered: bool = false
var ambient_timer: float = 0.0
var next_ambient_time: float = 20.0

const CREEPY_SOUNDS := [
	"res://assets/sounds/footsteps-wood-1.mp3",
	"res://assets/sounds/footsteps-wood-3.mp3",
	"res://assets/sounds/freesound_community-glass-bottle-clink-90671.mp3",
	"res://assets/sounds/door-close.mp3"
]

func _ready() -> void:
	# Auto-discover nodes if not assigned via inspector
	if not player:
		player = get_tree().get_first_node_in_group("player") as Player
		if not player and get_parent():
			player = get_parent().get_node_or_null("Player") as Player
	if get_parent():
		if not puzzle_1: puzzle_1 = get_parent().get_node_or_null("Puzzle1")
		if not puzzle_2: puzzle_2 = get_parent().get_node_or_null("Puzzle2Room")
		if not puzzle_3: puzzle_3 = get_parent().get_node_or_null("Puzzle3Room")
		if not door_4: door_4 = get_parent().get_node_or_null("House/wall_doors/DoorWall4") as DoorWall
		if not door_5: door_5 = get_parent().get_node_or_null("House/wall_doors/DoorWall5") as DoorWall
		if not door_6: door_6 = get_parent().get_node_or_null("House/wall_doors/DoorWall6") as DoorWall
		if not door_9: door_9 = get_parent().get_node_or_null("House/wall_doors/DoorWall9") as DoorWall
		if not front_door: front_door = get_parent().get_node_or_null("House/wall_doors/DoorWall") as DoorWall
		if not ambience_player: ambience_player = get_parent().get_node_or_null("sounds/ambience") as AudioStreamPlayer
		if not jumpscare_audio: jumpscare_audio = get_parent().get_node_or_null("sounds/jumbscare") as AudioStreamPlayer3D
		if not weird_audio: weird_audio = get_parent().get_node_or_null("sounds/WeirdSounds") as AudioStreamPlayer3D
		if not monster_jumpscare_node: monster_jumpscare_node = get_parent().get_node_or_null("chararacter/char3")

	next_ambient_time = randf_range(15.0, 30.0)
	GameState.flag_changed.connect(_on_flag_changed)

	if monster_jumpscare_node:
		monster_jumpscare_node.visible = false

	# Ensure front door starts non-interactable until escape phase
	if front_door:
		front_door.interactable = false

func _process(delta: float) -> void:
	ambient_timer += delta
	if ambient_timer >= next_ambient_time:
		ambient_timer = 0.0
		next_ambient_time = randf_range(20.0, 40.0)
		_trigger_random_ambient_event()

	if escape_active and not front_door_triggered and front_door:
		# Check if player has key_final and is near front door
		if GameState.has_item("key_final"):
			if not front_door.interactable:
				front_door.interactable = true
				front_door.locked = true
				front_door.open_with_key = "key_final"
				front_door.lockedUIMessage = "Locked! Use the Master Iron Key!"

			# Check if front door is opened
			if front_door.is_open and not front_door_triggered:
				front_door_triggered = true
				_trigger_final_jumpscare()

func _trigger_random_ambient_event() -> void:
	if not player or escape_active:
		return

	var roll = randi() % 4
	match roll:
		0:
			# Distant footstep
			if weird_audio:
				weird_audio.global_position = player.global_position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
				var sfx = load(CREEPY_SOUNDS.pick_random())
				if sfx:
					weird_audio.stream = sfx
					weird_audio.volume_db = -12.0
					weird_audio.play()
		1:
			# Flashlight flicker
			if player.flashlight:
				player.flashlight.light_energy = 0.1
				await get_tree().create_timer(0.08).timeout
				player.flashlight.light_energy = 1.0
				await get_tree().create_timer(0.05).timeout
				player.flashlight.light_energy = 0.2
				await get_tree().create_timer(0.07).timeout
				player.flashlight.light_energy = 1.0
		2:
			# Heartbeat surge
			player.is_scared = true
			await get_tree().create_timer(4.0).timeout
			player.is_scared = false
		3:
			# Ghostly whisper message
			var whispers = [
				"He watches from the ceiling...",
				"Did you hear the footsteps upstairs?",
				"Don't look into the mirrors...",
				"The clock stopped ticking for a reason..."
			]
			UiManager.show_message(whispers.pick_random(), 2.8)

func _on_flag_changed(flag_name: String, value: bool) -> void:
	if flag_name == "escape_phase" and value:
		escape_active = true
		if front_door:
			front_door.interactable = true
			front_door.locked = true
			front_door.open_with_key = "key_final"
		if player:
			player.is_scared = true

func _on_area_corridor_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body is Player:
		on_corridor_entered()

func _on_area_bedroom_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body is Player:
		on_bedroom_entered()

func _on_area_study_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body is Player:
		on_study_entered()

func on_corridor_entered() -> void:
	# Called when player unlocks DoorWall6 and enters the bedroom corridor
	if door_9 and door_9.locked:
		door_9.locked = false
		if door_9.has_method("open_slowly"):
			door_9.open_slowly(3.5)
		else:
			door_9.is_open = true
		UiManager.show_message("A door down the hall slowly opened on its own...", 3.5)

func on_bedroom_entered() -> void:
	# Called when player steps into the bedroom
	if puzzle_2:
		puzzle_2.on_player_enter_room()

func on_study_entered() -> void:
	# Called when player enters upstairs master study
	if puzzle_3:
		puzzle_3.on_player_enter_room()

func _trigger_final_jumpscare() -> void:
	if player:
		player.control_mode = Player.ControlMode.CUTSCENE

	# Spawn monster directly in player's face
	if monster_jumpscare_node:
		monster_jumpscare_node.visible = true
		monster_jumpscare_node.global_position = player.camera.global_position - player.camera.global_transform.basis.z * 0.8
		monster_jumpscare_node.global_position.y -= 0.6
		monster_jumpscare_node.look_at(player.camera.global_position, Vector3.UP)

	# Ear-splitting jumpscare scream
	if jumpscare_audio:
		jumpscare_audio.play()

	# Trigger UI jumpscare flash and game over ending screen
	UiManager.trigger_ending(true)
