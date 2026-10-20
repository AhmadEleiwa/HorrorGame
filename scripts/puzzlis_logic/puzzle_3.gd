extends Node3D
class_name Puzzle3

signal puzzle_solved

@export var door_path: NodePath
@export var secret_bookshelf_path: NodePath
@export var secret_doorway_trigger_path: NodePath
@export var monster_jumpscare_path: NodePath

@export var grind_audio_path: NodePath
@export var success_sound_path: NodePath
@export var error_sound_path: NodePath
@export var scare_audio_path: NodePath
@export var snarl_audio_path: NodePath
@export var secret_light_path: NodePath

@export var books: Array[PushBook] = []

# Target sequence: Book 2 (Azure), Book 1 (Crimson), Book 3 (Emerald), Book 4 (Gilded)
@export var target_sequence: Array[int] = [2, 1, 3, 4]

var door: DoorWall = null
var secret_bookshelf: Node3D = null
var secret_doorway_trigger: Area3D = null
var monster_jumpscare: Node3D = null

var grind_audio: AudioStreamPlayer3D = null
var success_sound: AudioStreamPlayer3D = null
var error_sound: AudioStreamPlayer3D = null
var scare_audio: AudioStreamPlayer3D = null
var snarl_audio: AudioStreamPlayer3D = null
var secret_light: OmniLight3D = null

var current_sequence: Array[int] = []
var is_solved: bool = false
var room_entered: bool = false
var cutscene_active: bool = false
var is_resetting: bool = false

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
	secret_bookshelf = _resolve_node(secret_bookshelf_path) as Node3D
	secret_doorway_trigger = _resolve_node(secret_doorway_trigger_path) as Area3D
	monster_jumpscare = _resolve_node(monster_jumpscare_path) as Node3D

	grind_audio = _resolve_node(grind_audio_path) as AudioStreamPlayer3D
	success_sound = _resolve_node(success_sound_path) as AudioStreamPlayer3D
	error_sound = _resolve_node(error_sound_path) as AudioStreamPlayer3D
	scare_audio = _resolve_node(scare_audio_path) as AudioStreamPlayer3D
	snarl_audio = _resolve_node(snarl_audio_path) as AudioStreamPlayer3D
	secret_light = _resolve_node(secret_light_path) as OmniLight3D

	if monster_jumpscare:
		monster_jumpscare.visible = false

	if secret_light:
		secret_light.visible = false

	if secret_doorway_trigger:
		secret_doorway_trigger.body_entered.connect(_on_secret_doorway_body_entered)

	# Connect books
	for b in books:
		if b:
			b.book_pressed.connect(_on_book_pressed)

	# Hide background book stacks on the middle shelf row so the 4 puzzle grimoires stand unobstructed
	if secret_bookshelf and secret_bookshelf.has_node("Books"):
		var books_node = secret_bookshelf.get_node("Books")
		for child_name in ["bookStack6", "bookStack8", "bookStack35"]:
			if books_node.has_node(child_name):
				books_node.get_node(child_name).visible = false

func on_player_enter_room() -> void:
	if room_entered:
		return
	room_entered = true

	# Slam study door shut behind player
	if door:
		door.is_open = false
		door.locked = true

	UiManager.show_message("The study door slammed shut! A faint grinding sound echoed behind the walls...", 4.0)

func _on_book_pressed(book_id: int) -> void:
	if is_solved or is_resetting:
		return

	var expected_idx = current_sequence.size()
	if expected_idx < target_sequence.size() and target_sequence[expected_idx] == book_id:
		current_sequence.append(book_id)
		print("Correct book pressed: ", book_id, " (Progress: ", current_sequence.size(), "/", target_sequence.size(), ")")

		if current_sequence.size() == target_sequence.size():
			_solve_puzzle()
	else:
		# Wrong order
		print("Incorrect book pressed! Expected: ", target_sequence[expected_idx], " Got: ", book_id)
		_trigger_sequence_reset()

func _trigger_sequence_reset() -> void:
	is_resetting = true
	current_sequence.clear()

	if error_sound:
		error_sound.play()

	UiManager.show_message("The mechanism clicked shut... the books reset.", 2.5)

	# Wait a short moment then pop books back out
	await get_tree().create_timer(0.4).timeout
	for b in books:
		if b:
			b.reset_book()
	is_resetting = false

func _solve_puzzle() -> void:
	is_solved = true
	CrazyGamesSDK.happy_time()

	if success_sound:
		success_sound.play()

	if grind_audio:
		grind_audio.play()

	UiManager.show_message("The ancient gears engage! The hidden wall is opening...", 4.0)

	# Slide the secret bookshelf to reveal the hidden wall opening
	if secret_bookshelf:
		var t = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		# Slide bookcase along Z by -2.0 meters
		t.tween_property(secret_bookshelf, "position:z", secret_bookshelf.position.z - 2.0, 2.2)

	if secret_light:
		secret_light.visible = true
		var t_light = create_tween().set_loops()
		t_light.tween_property(secret_light, "light_energy", 1.4, 0.8)
		t_light.tween_property(secret_light, "light_energy", 0.7, 0.8)

	puzzle_solved.emit()

func _on_secret_doorway_body_entered(body: Node) -> void:
	if not is_solved or cutscene_active:
		return

	if body.is_in_group("player") or body is Player:
		_start_final_cutscene(body as Player)

func _start_final_cutscene(player: Player) -> void:
	cutscene_active = true

	if not player:
		player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return

	# Lock player controls
	player.control_mode = Player.ControlMode.CUTSCENE
	player.suppress_look = true
	if player.interactive_view and player.interactive_view.held_object:
		player.interactive_view.drop_object()

	# Start creepy snarl / breath behind player
	if snarl_audio:
		snarl_audio.play()

	# Spawn monster directly behind the player near the study entrance
	if monster_jumpscare:
		monster_jumpscare.visible = true
		var spawn_pos = player.global_position + (player.global_transform.basis.z * 3.2)
		spawn_pos.y = 0.84
		monster_jumpscare.global_position = spawn_pos
		monster_jumpscare.look_at(player.camera.global_position, Vector3.UP)
		monster_jumpscare.rotate_y(PI)
		monster_jumpscare.rotation.x = 0
		monster_jumpscare.rotation.z = 0
		monster_jumpscare.scale = Vector3(0.35, 0.35, 0.35)

	# Heavy heartbeat surge
	player.is_scared = true

	# Wait a beat for the audio to register
	await get_tree().create_timer(0.6).timeout

	# Whip player camera around 180 degrees to face the beast!
	var target_yaw = player.rotation.y + PI
	var t_turn = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_turn.tween_property(player, "rotation:y", target_yaw, 0.5)
	t_turn.parallel().tween_property(player.head, "rotation:x", deg_to_rad(5), 0.4)
	await t_turn.finished

	# The monster lunges straight into the camera!
	if scare_audio:
		scare_audio.play()

	if monster_jumpscare:
		monster_jumpscare.look_at(player.camera.global_position, Vector3.UP)
		monster_jumpscare.rotate_y(PI)
		monster_jumpscare.scale = Vector3(0.35, 0.35, 0.35)
		var target_face = player.camera.global_position - player.camera.global_transform.basis.z * 0.35
		target_face.y -= 0.2
		var t_leap = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		t_leap.tween_property(monster_jumpscare, "global_position", target_face, 0.32)
		t_leap.parallel().tween_property(monster_jumpscare, "scale", Vector3(0.65, 0.65, 0.65), 0.32)
		await t_leap.finished

	# Trigger bloody red flash & ending screen
	CrazyGamesSDK.gameplay_stop()
	CrazyGamesSDK.happy_time()
	UiManager.trigger_ending(
		false,
		"THE BEAST HAS AWOKEN",
		"You uncovered the hidden sanctum behind the wall...\nbut you were never meant to leave this house alive.\n\nThank you for playing!"
	)
