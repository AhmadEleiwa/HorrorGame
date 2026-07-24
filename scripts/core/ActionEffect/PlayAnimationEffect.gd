extends ActionEffect
class_name PlayAnimationEffect

## Path to the AnimationPlayer relative to the scene root, and the
## animation name to play. Awaits completion before the ActionArea
## considers the effect finished.
@export var animation_player_path: NodePath
@export var animation_name: String = ""

func execute(player: Node) -> void:
	var path_str := str(animation_player_path)
	while path_str.begins_with("../"):
		path_str = path_str.trim_prefix("../")
	
	var clean_path := NodePath(path_str)
	var anim_player := player.get_tree().current_scene.get_node_or_null(clean_path) 
	print(anim_player)
	if not anim_player:
		push_warning("PlayAnimationEffect: AnimationPlayer not found at %s" % animation_player_path)
		return

	anim_player.play(animation_name)
	await anim_player.animation_finished
