extends Control

# Reference your graphics script (Autoload or child node)
@export var graphics_settings:= GraphicSettings

# --- UI Node References ---
@onready var resolution_slider: HSlider = %ResolutionSlider

@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var shadow_option: OptionButton = %ShadowOption
@onready var ssao_option: OptionButton = %SSAOOption
@onready var fog_option: OptionButton = %FogOption
@onready var aa_option: OptionButton = %AAOption


func _ready() -> void:
	_populate_dropdowns()
	_setup_signals()
	_load_initial_ui_state()
	


	

func _populate_dropdowns() -> void:
	# Populate Quality presets (LOW = 0, MEDIUM = 1, HIGH = 2)
	var quality_items: Array[String] = ["Low", "Medium", "High"]
	
	for option in [shadow_option, ssao_option, fog_option]:
		option.clear()
		for item in quality_items:
			option.add_item(item)

	# Populate Anti-Aliasing options
	aa_option.clear()
	aa_option.add_item("OFF")
	aa_option.add_item("FXAA")
	aa_option.add_item("TAA")


func _setup_signals() -> void:
	resolution_slider.value_changed.connect(_on_resolution_changed)
	shadow_option.item_selected.connect(_on_shadow_selected)
	ssao_option.item_selected.connect(_on_ssao_selected)
	fog_option.item_selected.connect(_on_fog_selected)
	aa_option.item_selected.connect(_on_aa_selected)

	brightness_slider.value_changed.connect(_on_brightness_changed)


func _load_initial_ui_state() -> void:
	# Configure Resolution Slider Range (50% to 100% scale)
	resolution_slider.min_value = 0.5
	resolution_slider.max_value = 1.0
	resolution_slider.step = 0.05
	resolution_slider.value = 1.0
	
	# Default selections
	shadow_option.selected = 1 # Medium
	ssao_option.selected = 1   # Medium
	fog_option.selected = 1    # Medium
	aa_option.selected = 1     # FXAA

	# Configure Brightness Slider Range (0.5 to 1.5, default 1.0)
	brightness_slider.min_value = 0.5
	brightness_slider.max_value = 1.5
	brightness_slider.step = 0.05
	brightness_slider.value = 1.0

# --- Signal Callbacks ---

func _on_resolution_changed(value: float) -> void:
	if graphics_settings and graphics_settings.has_method("set_resolution_scale"):
		graphics_settings.set_resolution_scale(value)


func _on_shadow_selected(index: int) -> void:
	if GraphicSettings and GraphicSettings.has_method("set_shadow_quality"):
		GraphicSettings.set_shadow_quality(index as GraphicSettings.Quality)
	#GraphicSettings.set_ssao_quality()

func _on_ssao_selected(index: int) -> void:
	if GraphicSettings and GraphicSettings.has_method("set_ssao_quality"):
		GraphicSettings.set_ssao_quality(index as GraphicSettings.Quality)


func _on_fog_selected(index: int) -> void:
	if GraphicSettings and GraphicSettings.has_method("set_fog_quality"):
		GraphicSettings.set_fog_quality(index as GraphicSettings.Quality)


func _on_aa_selected(index: int) -> void:

	if GraphicSettings and GraphicSettings.has_method("set_anti_aliasing"):
		var mode_string: String = aa_option.get_item_text(index)
		GraphicSettings.set_anti_aliasing(mode_string)

func _on_brightness_changed(value: float) -> void:
	if GraphicSettings and GraphicSettings.has_method("set_brightness"):
		GraphicSettings.set_brightness(value)
	# Or if using Autoload directly:
	# GraphicsManager.set_brightness(value)
func _on_close_button_pressed() -> void:
	hide()
