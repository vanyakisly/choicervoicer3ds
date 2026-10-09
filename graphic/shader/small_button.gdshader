shader_type canvas_item;


uniform sampler2D palette;
uniform vec2 node_size = vec2(1.0, 1.0);
uniform float shade_symmetry = .2;
uniform float center_size_x : hint_range(0.0, 1.0) = .5;
uniform float center_size_y : hint_range(0.0, 1.0) = .5;
uniform float center_falloff = 1.0;
uniform float center_strength = 1.0;


void fragment() {
	float aspect = node_size.x / node_size.y;
	vec2 st = UV;
	
	// Fix st's size so that the corners will be 45 degrees
	if (st.y < .5) {
		st.y /= aspect;
	} else {
		st.y = (st.y - 1.0) / aspect + 1.0;
	}
	
	// Assign the bevel shadings
	float value = 0.0;
	value += smoothstep(-.025, .025, -st.y + st.x);
	value += shade_symmetry * smoothstep(-.025, .025, (1.0 - st.x) - st.y);
	//value += shade_symmetry * step(0.0, (1.0 - st.x) - st.y);
	//if (st.y < 1.0-st.x) {
		//value = 1.0;
	//}
	//if (st.y < st.x) {
		//value += shade_symmetry;
	//}
	value /= (1.0 + shade_symmetry);
	
	// Center of the button
	vec2 sr = UV;
	if (sr.x > .5) {
		sr.x = 1.0 - sr.x; }
	if (sr.y > .5) {
		sr.y = 1.0 - sr.y; }
	sr -= vec2(center_size_x, center_size_y)/2.0;
	sr /= vec2(center_size_x, center_size_y);
	if (sr.x <= 0.0 || sr.y <= 0.0) {
		sr = vec2(0.0);
	}
	sr = vec2(min(sr.x, sr.y) * center_falloff);
	sr = clamp(sr, vec2(0.0), vec2(1.0));
	
	
	// Merge
	value = value * (1.0 - sr.r) + sr.r * center_strength * sr.r;
	
	
	// Map gradient
	vec4 gradient = textureLod(palette, vec2(value), 0.0);
	
	COLOR = gradient;
	//COLOR = vec4(sr.x, sr.y, 0.0, 1.0);
}
