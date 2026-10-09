shader_type canvas_item;

uniform vec2 direction = vec2(1.0, 0.2);
uniform float speed = 1.0;
uniform vec3 color:source_color;

void fragment() {
	vec4 shift;
	shift = texture(TEXTURE, vec2(UV.x, UV.y) + (direction * TIME * speed));
	COLOR = shift * vec4(color, 1.0);
}