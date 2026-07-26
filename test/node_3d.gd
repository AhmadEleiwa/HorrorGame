extends Node3D


func _on_lock_lock_unlocked() -> void:
	print("unlocked")
	$Player.interactive_view._finish_direct_inspect()
