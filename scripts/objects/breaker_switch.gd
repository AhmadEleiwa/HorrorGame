extends InteractiveObject
class_name BreakerSwitch

signal switched(switch_id: int, is_on: bool)

@export var switch_id: int = 1
@export var switch_color: Color = Color(1.0, 0.2, 0.2)
@export var switch_name: String = "Switch"

var is_on: bool = false
@onready var light: OmniLight3D = $OmniLight3D
@onready var switch_mesh: Node3D = $lightSwitch
@onready var switch_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	super._ready()
	if light:
		light.light_color = switch_color
		light.light_energy = 0.1

func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity():
		return
	is_on = not is_on
	_update_visuals()
	if switch_sound:
		switch_sound.pitch_scale = 1.1 if is_on else 0.9
		switch_sound.play()
	switched.emit(switch_id, is_on)

func reset_switch() -> void:
	is_on = false
	_update_visuals()

func _update_visuals() -> void:
	if light:
		light.light_energy = 1.5 if is_on else 0.1
	if switch_mesh:
		# Slight tilt to show flipped position
		switch_mesh.rotation_degrees.x = 25.0 if is_on else -25.0

func ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.show_interaction(switch_name + "\n[E] Flip")

func hide_ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.hide_interaction()
