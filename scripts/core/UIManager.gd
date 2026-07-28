extends CanvasLayer

@onready var message_label: Label = $MessageLabel
@onready var interaction_ui: Label = $InteractionUI
@onready var reader_title: Label = $Reader/CenterContainer/Control/MarginContainer/VBoxContainer/title
@onready var reader_content: RichTextLabel = $Reader/CenterContainer/Control/MarginContainer/VBoxContainer/content
@onready var reader: Control = $Reader
@onready var tool_bar_label: Label = $MarginContainer/ToolBar/ToolBarLabel
@onready var tool_bar_label_2: Label = $MarginContainer/ToolBar/ToolBarLabel2
@onready var tool_bar_label_3: Label = $MarginContainer/ToolBar/ToolBarLabel3
@onready var tool_bar: HBoxContainer = $MarginContainer/ToolBar
@onready var fps: Label = $FPS


var _message_tween: Tween

func _input(event: InputEvent) -> void:
	
	if get_tree().current_scene.name == "MainMenu":
		return
	if event is InputEventKey and event.pressed  and event.keycode == KEY_ESCAPE or event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT :
		close_reader()
	
func _ready() -> void:
	message_label.visible = false
	message_label.modulate.a = 0.0

func _process(delta: float) -> void:
	fps.text = "FPS " + str(Engine.get_frames_per_second())
## Shows a message for `duration` seconds, then fades out.
## Safe to call repeatedly — a new call interrupts/replaces the current one.
func show_message(text: String, duration: float = 2.5) -> void:
	if _message_tween and _message_tween.is_running():
		_message_tween.kill()

	message_label.text = text
	message_label.visible = true
	message_label.modulate.a = 0.0

	_message_tween = create_tween()
	_message_tween.tween_property(message_label, "modulate:a", 1.0, 0.2)
	_message_tween.tween_interval(duration)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, 0.4)
	_message_tween.tween_callback(func(): message_label.visible = false)


## Instantly hides any message, skipping the fade.
func clear_message() -> void:
	if _message_tween and _message_tween.is_running():
		_message_tween.kill()
	message_label.visible = false
	message_label.modulate.a = 0.0
	
func show_interaction(text:String="[E]"):
	if text:
		interaction_ui.text = text
	interaction_ui.show()
func hide_interaction():
	interaction_ui.text = "[E]"
	interaction_ui.hide()
	
func open_reader(title:String, content:String):
	reader_title.text = title
	reader_content.text = content
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reader.show()
func close_reader():
	reader.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_button_pressed() -> void:
	close_reader()
	
	
func show_tool_bar(slot1:String="",slot2:String="",slot3:String=""):
	tool_bar_label.text = slot1
	tool_bar_label_2.text = slot2
	tool_bar_label_3.text = slot3
	
	tool_bar.show()
func hide_tool_bar():
	tool_bar.hide()

func open_menu():
	if get_tree().current_scene.name != "MainMenu":
		get_tree().paused = true
		$menu.show()
		$SettingsMenu.show()
