extends Node

# Reference to your main WorldEnvironment node in the horror scene
var world_env: WorldEnvironment = null


#func 
enum Quality { LOW, MEDIUM, HIGH }

# --- 1. RESOLUTION / 3D SCALING ---
func set_resolution_scale(scale_value: float) -> void:
	# scale_value ranges from 0.5 to 1.0
	get_viewport().scaling_3d_scale = scale_value
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR # FSR provides crisp upscaling

# --- 2. SHADOW QUALITY ---
func set_shadow_quality(preset: Quality) -> void:
	match preset:
		Quality.LOW:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 1024)
		Quality.MEDIUM:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 2048)
		Quality.HIGH:
			RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
			RenderingServer.positional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
			ProjectSettings.set_setting("rendering/lights_and_shadows/positional_shadow/atlas_size", 4096)

# --- 3. AMBIENT OCCLUSION (SSAO) ---
func set_ssao_quality(preset: Quality) -> void:
	if not world_env or not world_env.environment:
		return
		
	match preset:
		Quality.LOW:
			world_env.environment.ssao_enabled = false
		Quality.MEDIUM:
			world_env.environment.ssao_enabled = true
			RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_LOW, true, 0.5, 2, 50.0, 300.0)
		Quality.HIGH:
			world_env.environment.ssao_enabled = true
			RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_HIGH, true, 0.5, 2, 50.0, 300.0)

# --- 4. FOG SYSTEM (VOLUMETRIC vs DEPTH) ---
func set_fog_quality(preset: Quality) -> void:
	if not world_env or not world_env.environment:
		return

	match preset:
		Quality.LOW:
			# Turn off expensive Volumetric Fog, use standard Depth Fog for atmosphere
			world_env.environment.volumetric_fog_enabled = false
			world_env.environment.fog_enabled = true
		Quality.MEDIUM, Quality.HIGH:
			world_env.environment.volumetric_fog_enabled = true
			world_env.environment.fog_enabled = false

# --- 5. ANTI-ALIASING ---
func set_anti_aliasing(mode: String) -> void:
	match mode:
		"OFF":
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			get_viewport().use_taa = false
		"FXAA":
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			get_viewport().use_taa = false
		"TAA":
			get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
			get_viewport().use_taa = true
			
# --- 6. BRIGHTNESS CONTROL ---
func set_brightness(value: float) -> void:
	# value ranges from 0.5 (Dark) to 1.5 (Bright), default is 1.0
	
	if world_env and world_env.environment:
		world_env.environment.adjustment_enabled = true
		world_env.environment.adjustment_brightness = value
