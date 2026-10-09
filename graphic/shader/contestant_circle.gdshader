shader_type canvas_item;


void fragment() {
	vec2 st = UV;
	vec4 tex = texture(TEXTURE, vec2(UV.x, UV.y));
	
	if (length(st - vec2(0.5)) < 0.5) {
		tex.a = 1.0;
	} else {
		tex.a = 0.0;
	}
	
	COLOR = tex;
	
}
