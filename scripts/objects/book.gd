extends InteractiveObject

@export var title:String = "Book"
func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity():
		return

	_player.pickup_object(self)
	UiManager.show_message("A Book...seems it missing some pages!")
func ui_interaction() -> void:
	UiManager.show_interaction(title+'\n[E]')
func hide_ui_interaction() -> void:
	UiManager.hide_interaction()
