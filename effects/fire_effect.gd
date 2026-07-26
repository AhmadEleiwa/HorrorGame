@tool
extends GPUParticles3D
@onready var omni_light_3d: OmniLight3D = $OmniLight3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if emitting:
		omni_light_3d.show()
		omni_light_3d.light_energy = randf_range(0.5,1)
	else:
		omni_light_3d.hide()
