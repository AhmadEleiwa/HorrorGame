shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, particle_trails;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    float glow = smoothstep(0.5, 0.0, dist);
    ALBEDO = vec3(1.0, 0.95, 0.8);
    ALPHA = glow * 0.5;
    // no "unshaded" — let it respond to the SpotLight3D falling on it
}