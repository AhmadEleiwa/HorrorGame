extends Control

func _on_start_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
