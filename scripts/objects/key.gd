extends InteractiveObject

@export var key_name:String="key"
@export var display_title:String=""

func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity():
		return
	GameState.add_item(key_name)
	var title = display_title if display_title != "" else key_name.replace("_", " ").capitalize()
	UiManager.show_message("Found: " + title, 3.5)
	queue_free()
func ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.show_interaction("[E]")
func hide_ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.hide_interaction()
		
