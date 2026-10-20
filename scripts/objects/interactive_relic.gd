extends InteractiveObject
class_name InteractiveRelic

@export var title: String = "Relic"
@export var pickup_message: String = ""

func _ready() -> void:
	super._ready()
	add_to_group("relic")

func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity():
		return
	if _player:
		_player.pickup_object(self)
		if pickup_message != "":
			UiManager.show_message(pickup_message)

func tool_bar_ui() -> void:
	UiManager.show_tool_bar("[E] Place on Slot", "", "[RMB] Drop")

func hide_tool_bar_ui() -> void:
	UiManager.hide_tool_bar()

func ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.show_interaction(title + "\n[E] Pick up")

func hide_ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.hide_interaction()
