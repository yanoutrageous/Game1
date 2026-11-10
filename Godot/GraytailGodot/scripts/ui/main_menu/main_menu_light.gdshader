shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float scene_time = 0.0;
uniform float phase = 0.0;

void fragment() {
	float radius = length((UV - vec2(0.5)) * 2.0);
	float glow = pow(max(0.0, 1.0 - radius), 2.1) * (0.09 + sin(scene_time * 4.0 + phase) * 0.012);
	COLOR = vec4(1.0, 0.52, 0.16, glow);
}
