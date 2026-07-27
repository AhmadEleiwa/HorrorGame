extends CharacterBody3D
class_name Player

# ============================================================
# NODE REFERENCES
# ============================================================
@onready var animation_tree: AnimationTree = $Character_01/AnimationTree
@onready var flashlight: SpotLight3D = $head/flashlight
@onready var camera: Camera3D = $head/Camera3D
@onready var head: Node3D = $head
@onready var footstep: AudioStreamPlayer3D = $audio/Footstep
@onready var ambience: AudioStreamPlayer = $audio/Ambience  # optional
@onready var interactive_view: InteractiveView = $InteractiveView
@onready var ray_cast_3d: RayCast3D = %RayCast3D

# ============================================================
# AUDIO ASSETS
# ============================================================
const FOOTSTEP_WOOD: Array[AudioStream] = [
	preload("uid://crbgwo7ltpqw3"),
	preload("uid://crnmx6oluhpyn"),
	preload("uid://b5s8anialu0mh"),
]

# ============================================================
# MOVEMENT STATES & CONFIG
# ============================================================
enum State { IDLE, CROUCH, WALK, SPRINT }
var current_state: State = State.IDLE

const STATE_CONFIG := {
	State.CROUCH: {"speed": 1.0, "vol_min": -28.0, "vol_max": -24.0, "bob_freq": 1.8, "bob_mult": 1.0},
	State.WALK:   {"speed": 2.0, "vol_min": -16.0, "vol_max": -12.0, "bob_freq": 2.4, "bob_mult": 1.0},
	State.SPRINT: {"speed": 5.0, "vol_min": -2.0,  "vol_max": 2.0,   "bob_freq": 3.2, "bob_mult": 1.8},
}

# ============================================================
# CONTROL MODE
# ============================================================
enum ControlMode { PLAYER, CUTSCENE }
var control_mode: ControlMode = ControlMode.PLAYER

var _cutscene_direction: Vector3 = Vector3.ZERO
var _cutscene_speed: float = 0.0

# ============================================================
# CAMERA / HEAD MECHANICS
# ============================================================
const MOUSE_SENSITIVITY = 0.003
const CROUCH_HEIGHT_OFFSET = 0.35
const HEAD_LERP_SPEED = 10.0
const CAM_LERP_SPEED = 10.0

const BOB_AMP_Y = 0.05
const BOB_AMP_X = 0.05
const SCARED_BOB_MULT = 2.5

var bob_time = 0.0
var last_step_phase = 0.0
var default_cam_pos: Vector3
var origin_head_y: float

const BREATH_AMP = 0.01
const BREATH_FREQ = 0.5
const SCARED_BREATH_MULT = 1.8
var breath_time = 0.0

const FOV_DEFAULT = 75.0
const FOV_SPRINT = 85.0
const FOV_LERP_SPEED = 5.0

# ============================================================
# GAMEPLAY STATE
# ============================================================
var is_scared = false
var last_interacted_object: Object = null

@export var blend_speed = 15.0
var walk_val = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var suppress_look: bool = false

signal on_picked_object(object:InteractiveObject)
signal on_drop_object(object:InteractiveObject)

# ============================================================
# LIFECYCLE
# ============================================================
func _ready() -> void:
	origin_head_y = head.position.y
	default_cam_pos = camera.position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if footstep:
		footstep.stream = FOOTSTEP_WOOD.pick_random()

	_start_flicker_loop()


func _unhandled_input(event: InputEvent) -> void:
	if control_mode == ControlMode.CUTSCENE:
		return

	if event is InputEventMouseMotion and not suppress_look:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
		UiManager.open_menu()


func _physics_process(delta: float) -> void:
	handle_interactions()
	#print("ss")
	if not is_on_floor():
		velocity.y -= gravity * delta

	match control_mode:
		ControlMode.PLAYER:
			_process_player_movement(delta)
		ControlMode.CUTSCENE:
			_process_cutscene_movement(delta)

	move_and_slide()

	_handle_camera_bob(delta)
	_handle_breathing(delta)
	_handle_fov(delta)
	_handle_animation(delta)
	_update_animation_tree()


# ============================================================
# NORMAL PLAYER MOVEMENT
# ============================================================
func _process_player_movement(delta: float) -> void:
	var input_dir := _get_input_direction()
	_update_movement_state(input_dir)
	_apply_movement(delta, input_dir)


func _get_input_direction() -> Vector2:
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	return input_dir


func _update_movement_state(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		current_state = State.IDLE
	elif Input.is_key_pressed(KEY_CTRL):
		current_state = State.CROUCH
	elif Input.is_key_pressed(KEY_SHIFT):
		current_state = State.SPRINT
	else:
		current_state = State.WALK


func _apply_movement(delta: float, input_dir: Vector2) -> void:
	var target_head_y = origin_head_y - (CROUCH_HEIGHT_OFFSET if current_state == State.CROUCH else 0.0)
	head.position.y = lerpf(head.position.y, target_head_y, HEAD_LERP_SPEED * delta)

	if current_state == State.IDLE:
		var idle_speed = STATE_CONFIG[State.WALK]["speed"]
		velocity.x = move_toward(velocity.x, 0, idle_speed)
		velocity.z = move_toward(velocity.z, 0, idle_speed)
		return

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed = STATE_CONFIG[current_state]["speed"]
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


# ============================================================
# CUTSCENE MOVEMENT — driven by AnimationPlayer Call Method Tracks
# ============================================================

## Call from an AnimationPlayer Call Method Track.
## direction is WORLD space, e.g. Vector3(0, 0, -1). Player moves this way
## at this speed every physics frame until cutscene_stop() is called from
## a later keyframe.
func cutscene_move(direction: Vector3, speed: float = 2.0) -> void:
	control_mode = ControlMode.CUTSCENE
	_cutscene_direction = direction.normalized()
	_cutscene_speed = speed
	current_state = State.WALK


## Call from a Call Method Track to halt movement mid-cutscene
## (player stays in CUTSCENE mode, just standing still — e.g. waiting
## for a door to finish opening before continuing).
func cutscene_stop() -> void:
	_cutscene_direction = Vector3.ZERO
	_cutscene_speed = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	current_state = State.IDLE


## Call from the final Call Method Track key to hand control back
## to the player at the end of the cutscene.
func cutscene_end() -> void:
	cutscene_stop()
	control_mode = ControlMode.PLAYER


func _process_cutscene_movement(_delta: float) -> void:
	velocity.x = _cutscene_direction.x * _cutscene_speed
	velocity.z = _cutscene_direction.z * _cutscene_speed


# ============================================================
# CAMERA BOB + FOOTSTEPS
# ============================================================
func _handle_camera_bob(delta: float) -> void:
	if current_state == State.IDLE or not is_on_floor():
		bob_time = 0.0
		last_step_phase = 0.0
		_lerp_camera_to(default_cam_pos, delta)
		return

	var config = STATE_CONFIG[current_state]
	var bob_mult = SCARED_BOB_MULT if is_scared else config["bob_mult"]

	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	bob_time += delta * horizontal_speed

	var target = default_cam_pos + Vector3(
		sin(bob_time * config["bob_freq"] * 0.5) * BOB_AMP_X * bob_mult,
		sin(bob_time * config["bob_freq"]) * BOB_AMP_Y * bob_mult,
		0.0
	)
	_lerp_camera_to(target, delta)

	var step_phase = sin(bob_time * config["bob_freq"])
	if step_phase < -0.8 and last_step_phase >= -0.8:
		_play_footstep()
	last_step_phase = step_phase


func _lerp_camera_to(target: Vector3, delta: float) -> void:
	camera.position.x = lerpf(camera.position.x, target.x, CAM_LERP_SPEED * delta)
	camera.position.y = lerpf(camera.position.y, target.y, CAM_LERP_SPEED * delta)


func _play_footstep() -> void:
	if not footstep or not is_on_floor() or current_state == State.IDLE:
		return

	var config = STATE_CONFIG[current_state]
	var is_crouching = current_state == State.CROUCH

	footstep.stream = FOOTSTEP_WOOD.pick_random()
	footstep.volume_db = randf_range(config["vol_min"], config["vol_max"])
	footstep.pitch_scale = randf_range(
		0.85 if is_crouching else 0.92,
		0.98 if is_crouching else 1.08
	)
	footstep.play()


# ============================================================
# BREATHING SWAY + AMBIENT AUDIO
# ============================================================
func _handle_breathing(delta: float) -> void:
	breath_time += delta

	var freq = BREATH_FREQ * (SCARED_BREATH_MULT if is_scared else 1.0)
	var amp = BREATH_AMP * (SCARED_BREATH_MULT if is_scared else 1.0)
	var breath_wave = sin(breath_time * freq)

	camera.position.y += breath_wave * amp
	camera.position.x += cos(breath_time * freq * 0.7) * amp * 0.5

	_update_ambience(breath_wave)


func _update_ambience(breath_wave: float) -> void:
	if not ambience:
		return

	var base_db = -40.0
	var scared_db = -22.0
	var swell = (breath_wave + 1.0) * 0.5

	var target_db = lerpf(base_db, scared_db, 1.0 if is_scared else 0.0)
	ambience.volume_db = target_db + swell * 4.0


# ============================================================
# FOV
# ============================================================
func _handle_fov(delta: float) -> void:
	var target_fov = FOV_SPRINT if current_state == State.SPRINT else FOV_DEFAULT
	camera.fov = lerpf(camera.fov, target_fov, FOV_LERP_SPEED * delta)


# ============================================================
# INTERACTION
# ============================================================
func handle_interactions() -> void:
	if control_mode != ControlMode.PLAYER:
		_clear_previous_interaction()
		return

	if not ray_cast_3d.is_colliding():
		_clear_previous_interaction()
		return

	var collider = ray_cast_3d.get_collider()

	if collider != last_interacted_object:
		_clear_previous_interaction()
		if collider.has_method("ui_interaction"):
			collider.ui_interaction()
		last_interacted_object = collider

	if Input.is_action_just_pressed("interact") and collider.has_method("interact"):
		collider.interact(self)
		 

func _clear_previous_interaction() -> void:

	
	if last_interacted_object and last_interacted_object.has_method("hide_ui_interaction"):
		last_interacted_object.hide_ui_interaction()
	last_interacted_object = null

func pickup_object(object:InteractiveObject):
	if interactive_view.held_object:
		interactive_view.drop_object()
	on_picked_object.emit(object)
	interactive_view.pickup_object(object)
func drop_object():
	on_drop_object.emit(interactive_view.held_object)
	interactive_view.drop_object()
	
func holding_object() -> InteractiveObject:
	return interactive_view.held_object
# ============================================================
# ANIMATION
# ============================================================
func _handle_animation(delta: float) -> void:
	var target_val = 0.0 if current_state == State.IDLE else 1.0
	walk_val = lerpf(walk_val, target_val, blend_speed * delta)


func _update_animation_tree() -> void:
	if animation_tree:
		animation_tree["parameters/walk 2/blend_amount"] = walk_val


# ============================================================
# FLASHLIGHT FLICKER
# ============================================================
func _start_flicker_loop() -> void:
	while true:
		await get_tree().create_timer(randf_range(2.0, 8.0)).timeout
		var flickers = randi_range(1, 3)
		for i in flickers:
			flashlight.light_energy = randf_range(0.1, 0.5)
			await get_tree().create_timer(randf_range(0.03, 0.08)).timeout
			flashlight.light_energy = 1.0
			await get_tree().create_timer(randf_range(0.02, 0.06)).timeout
