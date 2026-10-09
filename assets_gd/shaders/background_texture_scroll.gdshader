shader_type canvas_item;

uniform bool enabled = true;
uniform vec2 direction = vec2(1.0, 0.2);
uniform float speed = 1.0;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform bool warp = false;
uniform float warp_intensity = 2.0;


const vec2 WINDOW = vec2(1152.0, 648.0);
const vec2 WINDOW_CENTER = WINDOW / 2.0;

uniform vec2 texture_dimensions= vec2(32.0);  // TEST probably delete

vec2 warp_shift(vec2 input) {
	if (warp) {
		// This works specifically for the 32x32 default tiles.
		vec2 texture_dimensions_center= texture_dimensions / 2.0;
		input -= vec2(WINDOW / texture_dimensions / 2.0);
		input.y -= input.y * pow(abs(input.x), 2.0) * warp_intensity / WINDOW.y*texture_dimensions.y;


		//input += vec2(WINDOW / texture_dimensions / 2.0);

		// This works for an image that's the size of the window
		//input -= vec2(0.5);
		//input.y -= input.y * pow(abs(input.x), 2.0) * warp_intensity;
	}
	return input;
}

void fragment() {
	vec4 shift;
	if (enabled) {
		shift = texture(TEXTURE, warp_shift(UV) + (direction * TIME * speed));
	} else {
		shift = texture(TEXTURE, warp_shift(UV));
	}
	COLOR = shift * vec4(color);
}