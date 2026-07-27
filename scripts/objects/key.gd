extends InteractiveObject

@export var key_name:String="key"

func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity():
		return
	GameState.add_item(key_name)
	queue_free()
func ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.show_interaction("[E]")
func hide_ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.hide_interaction()
		
