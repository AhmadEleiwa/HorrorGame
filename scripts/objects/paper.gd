extends InteractiveObject
class_name InteractivePaper
@onready var ObjectName: Label3D = $ObjectName
@export var title:String = ""
@export_multiline var content:String = ""


#var gravity: float = 	ProjectSettings.get_setting("physics/3d/default_gravity")


	
func interact(player:Player=null)->void:
	super.interact(player)
	if not check_interactivity():
		return
	player.pickup_object(self)
	paper_sound()
func ui_interaction() -> void:
	if not check_interactivity():
		return
	ObjectName.text = title
	UiManager.show_interaction(title+"\n[E]")

func hide_ui_interaction() -> void:
	if not check_interactivity():
		return
	
	UiManager.hide_interaction()
	ObjectName.hide()
func read_paper():
	UiManager.open_reader(title, content)
func tool_bar_ui():
	UiManager.show_tool_bar("[LMB] READ", "[RMB] Drop", "[I] Inspect")
func hide_tool_bar_ui():
	UiManager.hide_tool_bar()


func paper_sound():
	$Sounds/paper_sound.pitch_scale = randf_range(0.8,1.2)
	$Sounds/paper_sound.play()
