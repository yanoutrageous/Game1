shader_type canvas_item;
render_mode unshaded;

// Source pixels -> the shared physical sign plane. Labels retain their font UVs.
uniform mat3 plane;
uniform mat3 inverse_plane;
uniform vec2 source_origin;
uniform vec2 source_size;
uniform bool board_surface = false;
uniform sampler2D ink_surface : filter_nearest, repeat_disable;
uniform vec2 ink_origin;
uniform vec2 ink_size = vec2(1280.0, 720.0);
uniform bool ink_on_world = false;
varying vec2 projected_pixel;
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
	vec3 projected = plane * vec3(source_origin + VERTEX, 1.0);
	projected_pixel = projected.xy / projected.z;
	VERTEX = projected_pixel - source_origin;
}

void fragment() {
	vec3 source = inverse_plane * vec3(projected_pixel, 1.0);
	vec2 source_pixel = source.xy / source.z;
	if (board_surface) {
		COLOR = texture(TEXTURE, (source_pixel - source_origin) / source_size) * vertex_tint;
	} else {
		vec4 ink = texture(TEXTURE, UV) * vertex_tint;
		vec2 paint_pixel = ink_on_world ? projected_pixel : source_pixel;
		vec3 grain = texture(ink_surface, (paint_pixel - ink_origin) / ink_size).rgb;
		float lightness = dot(grain, vec3(0.299, 0.587, 0.114));
		ink.rgb *= mix(0.88, 1.03, lightness);
		COLOR = ink;
	}
}
