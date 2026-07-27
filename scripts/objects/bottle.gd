extends InteractiveObject
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var min_impact_velocity: float = 1.0 # Minimum speed needed to clink
@export var max_impact_velocity: float = 8.0  # Speed for maximum volume

var pre_impact_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	# Store the speed right before the physics engine stops the body on collision
	pre_impact_velocity = linear_velocity

func _on_body_entered(_body: Node) -> void:
	# Measure how fast the bottle was traveling right BEFORE hitting the ground/table
	var impact_speed: float = pre_impact_velocity.length()
	
	if impact_speed >= min_impact_velocity:
		# Scale sound volume based on how hard it landed
		var volume: float = remap(impact_speed, min_impact_velocity, max_impact_velocity, -18.0, 0.0)
		audio_player.volume_db = clamp(volume, -24.0, 4.0)
		
		# Slight pitch tweak so every drop sounds unique
		audio_player.pitch_scale = randf_range(0.92, 1.08)
		audio_player.play()
