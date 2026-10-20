extends InteractiveObject
class_name PushBook

signal book_pressed(book_id: int)

@export var book_id: int = 0
@export var book_title: String = "Ancient Grimoire"
@export var roman_numeral: String = "I"
@export var spine_color: Color = Color(0.8, 0.2, 0.2)

@onready var spine_label: Label3D = get_node_or_null("SpineLabel")
@onready var click_audio: AudioStreamPlayer3D = get_node_or_null("ClickAudio")

var is_pushed: bool = false
var original_local_pos: Vector3 = Vector3.ZERO
var original_local_rot: Vector3 = Vector3.ZERO

func _ready() -> void:
	super._ready()
	original_local_pos = position
	original_local_rot = rotation_degrees
	if spine_label:
		spine_label.text = roman_numeral + "\n" + book_title
		spine_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		spine_label.outline_size = 4
		spine_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)

	# Tint the book cover mesh to match the book's color theme
	var book_mesh_node = get_node_or_null("book")
	if book_mesh_node:
		var mi: MeshInstance3D = null
		for child in book_mesh_node.get_children():
			if child is MeshInstance3D:
				mi = child
				break
			for sub in child.get_children():
				if sub is MeshInstance3D:
					mi = sub
					break
		if mi:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = spine_color
			mat.roughness = 0.45
			mi.material_override = mat

func interact(_player: Player = null) -> void:
	super.interact(_player)
	if not check_interactivity() or is_pushed:
		return

	push_in()

func push_in() -> void:
	if is_pushed:
		return
	is_pushed = true

	if click_audio:
		click_audio.play()

	var t = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Push inward along local -Z and slight tilt
	t.tween_property(self, "position:z", original_local_pos.z - 0.12, 0.2)
	t.parallel().tween_property(self, "rotation_degrees:x", original_local_rot.x - 4.0, 0.2)

	book_pressed.emit(book_id)

func reset_book() -> void:
	if not is_pushed:
		return
	is_pushed = false

	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "position", original_local_pos, 0.3)
	t.parallel().tween_property(self, "rotation_degrees", original_local_rot, 0.3)

func ui_interaction() -> void:
	if not check_interactivity() or is_pushed:
		return
	UiManager.show_interaction("[E] Push " + book_title)

func hide_ui_interaction() -> void:
	if not check_interactivity():
		return
	UiManager.hide_interaction()
