extends Node3D



const SCARY = preload("uid://bptgslbs5mf5i")
const NORMAL = preload("uid://dhtms468m1tw5")


# Called when the node enters the scene tree for the first time.

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player: Player = $Player



var current_animation = "None"

func _ready() -> void:
	
	$WorldEnvironment.environment  = SCARY	
	GraphicSettings.world_env = $WorldEnvironment
	animation_player.play("opening")
	
	#await  player.play_open_door_cutscene(Vector3(-6,0,0),null)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if Input.is_action_just_pressed("DEBUG-envSwape"):
		#if $WorldEnvironment.environment  == SCARY:
			#$WorldEnvironment.environment = NORMAL
		#else:
			#$WorldEnvironment.environment  = SCARY
