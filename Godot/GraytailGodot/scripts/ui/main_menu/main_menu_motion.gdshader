shader_type canvas_item;
render_mode unshaded;

uniform vec2 dimensions = vec2(1.0);
uniform int effect = 0;
uniform float scene_time = 0.0;
uniform float phase = 0.0;
uniform float strength = 1.0;
uniform float hover_amount = 0.0;
uniform vec2 cloth_pin = vec2(32.0,98.0);
varying vec4 vertex_tint;

void vertex() {
	vertex_tint = COLOR;
	vec2 p = VERTEX;
	vec2 n = p / dimensions;
	float t = scene_time;
	float wind = sin(t*1.8+phase) + 0.32*sin(t*3.1+phase*1.7);
	if (effect == 1) { // Flag: pole side remains fixed, wave travels towards the tip.
		float free_end = smoothstep(cloth_pin.x,cloth_pin.y,p.x);
		VERTEX.y += free_end*(sin(t*3.4-n.x*6.0+phase)*4.4 + sin(t*1.7-n.x*3.0)*1.3)*strength;
		VERTEX.x += free_end*sin(t*2.3-n.x*4.5+phase)*1.4*strength;
	} else if (effect == 2) { // Hanging fabric: top bar is pinned.
		float free_end = smoothstep(0.13,0.92,n.y);
		VERTEX.x += free_end*(sin(t*2.5-n.y*5.2+phase)*4.1 + wind*1.1)*strength;
		VERTEX.y += free_end*sin(t*2.0-n.y*4.2+phase)*1.25*strength;
	} else if (effect == 3) { // Canopy: the lower attachment stays comparatively still.
		float tip = 0.2+0.8*(1.0-smoothstep(0.05,0.98,n.y));
		VERTEX.x += tip*(sin(t*1.6+p.y*0.026+phase)*2.2 + sin(t*2.7+p.x*0.036)*0.8)*strength;
		VERTEX.y += tip*sin(t*2.1+p.x*0.034+phase)*1.4*strength;
	} else if (effect == 4) { // Grass and foreground leaves pinned at their roots.
		float tip = 1.0-smoothstep(0.12,0.96,n.y);
		VERTEX.x += tip*(sin(t*2.2+p.y*0.05+phase)*3.6 + wind)*strength;
		VERTEX.y += tip*sin(t*1.8+p.x*0.065+phase)*1.7*strength;
	} else if (effect == 6) { // Flame base remains in its lantern.
		float tip = 1.0-smoothstep(0.15,0.86,n.y);
		VERTEX.x += tip*(sin(t*7.0+n.y*8.0+phase)*1.65+sin(t*11.0+phase)*0.55);
		VERTEX.y -= tip*(0.8+sin(t*5.0+phase)*1.2);
	} else if (effect == 7) { // Smoke warps inside the moving plume.
		VERTEX.x += sin(t*1.5+n.y*7.0+phase)*(1.0-n.y)*3.0;
		VERTEX.y += sin(t*1.2+n.x*5.0+phase)*1.1;
	} else if (effect == 8) { // Bird wings flutter continuously, independent of flight path.
		VERTEX.y += sin(t*9.0+n.x*23.0+phase)*1.8;
	}
}

void fragment() {
	vec4 paint = texture(TEXTURE,UV);
	if (effect == 6) {
		paint.rgb *= 1.0+sin(scene_time*6.3+phase)*0.045;
	}
	paint.rgb *= 1.0+hover_amount*0.055;
	COLOR = vertex_tint * paint;
}
