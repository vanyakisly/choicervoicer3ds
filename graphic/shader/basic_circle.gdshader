shader_type canvas_item;

uniform vec4 color : source_color;
uniform float start : hint_range(0.0, 1.0) = .5;
uniform float end : hint_range(0.0, 1.0) = 1.0;
uniform float falloff = .05;

group_uniforms animation;
uniform float spin_speed = 10.0;
uniform float pivot_offset = 0.0;


mat2 rotate(float _angle) {
	return mat2(
			vec2(cos(_angle), -sin(_angle)),
			vec2(sin(_angle), cos(_angle)));
}


void fragment() {
	vec2 st = UV;
	float value;
	
	//st = rotate((TIME * 3.1415)) * st;
	
	vec2 pivot_rotate = rotate((TIME * 3.1415 * spin_speed)) * vec2(pivot_offset/2.0);
	
	value = 2.0 * length(st - (vec2(.5, .5) + pivot_rotate));
	if (value < start) {
		value = smoothstep(start - falloff, start, value);
	}
	else if (value > end - falloff) {
		value = 1.0 - smoothstep(end - falloff, end, value);
	} else {
		value = 1.0;
	}
	
	COLOR = vec4(vec3(color.r, color.g, color.b), value * color.a);
}

