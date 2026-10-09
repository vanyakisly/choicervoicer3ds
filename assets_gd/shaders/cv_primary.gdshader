shader_type canvas_item;

// self notes:
	// value is just max(vec3.rgb)
	// saturation is just [max(vec3.rgb) - min(vec3.rgb) / max(vec3.rgb)]

uniform vec2 node_size = vec2(2.0, 1.0);

group_uniforms Button_Base;
// The edge is a gradient that should only contain colors with a hue value of 0.0 (red)
// In order to properly apply selected color, saturation is found from (1.0 - UV.g)
	// This is, the less g is, the more red and less white the color is. If g is 1.0, then the color is white
// The value, meanwhile, it literally just UV.r
uniform sampler2D edge;
// The input color assumes 100% saturation and reduces it from there (since saturation > 1.0 is just 1.0)
//uniform vec4 color : source_color = vec4(0.69, 0.816, 0.839, 1.0);
uniform vec4 color : source_color = vec4(0.682, 0.872, 0.91, 1.0);
uniform bool invert = false;
uniform float x_roundness : hint_range(0.0, 0.5) = 0.25;
uniform float y_roundness : hint_range(0.0, 0.5) = 0.25;

group_uniforms Accent_Primary;
	uniform bool use_primary = false;
	uniform bool primary_alter_hsv_value = true;
	uniform vec4 primary_color : source_color = vec4(vec3(1.0), 0.8);
	uniform float primary_falloff : hint_range(0.0, 2.0) = 1.0;
	uniform float primary_x_roundness : hint_range(0.0, 0.5) = 0.25;
	uniform float primary_y_roundness : hint_range(0.0, 0.5) = 0.25;
	uniform float primary_border_distance_cutoff : hint_range(0.0, 1.0) = 0.0;
	uniform float primary_border_softness : hint_range(0.0, 1.0) = 0.0;
	uniform bool primary_use_own_border = false;
	uniform float primary_shift_x = 0.0;
	uniform float primary_shift_y = 0.0;
	uniform float primary_scale_x = 1.0;
	uniform float primary_scale_y = 1.0;

group_uniforms Accent_Secondary;
	uniform bool use_secondary = false;
	uniform bool secondary_alter_hsv_value = true;
	uniform vec4 secondary_color : source_color = vec4(vec3(1.0), 0.8);
	uniform float secondary_falloff : hint_range(0.0, 2.0) = 1.0;
	uniform float secondary_x_roundness : hint_range(0.0, 0.5) = 0.25;
	uniform float secondary_y_roundness : hint_range(0.0, 0.5) = 0.25;
	uniform float secondary_border_distance_cutoff : hint_range(0.0, 1.0) = 0.0;
	uniform float secondary_border_softness : hint_range(0.0, 1.0) = 0.0;
	uniform bool secondary_use_own_border = false;
	uniform float secondary_shift_x = 0.0;
	uniform float secondary_shift_y = 0.0;
	uniform float secondary_scale_x = 1.0;
	uniform float secondary_scale_y = 1.0;

group_uniforms Accent_Tertiary;
	uniform bool use_tertiary = false;
	uniform bool tertiary_alter_hsv_value = true;
	uniform vec4 tertiary_color : source_color = vec4(vec3(1.0), 0.8);
	uniform float tertiary_falloff : hint_range(0.0, 2.0) = 1.0;
	uniform float tertiary_x_roundness : hint_range(0.0, 0.5) = 0.25;
	uniform float tertiary_y_roundness : hint_range(0.0, 0.5) = 0.25;
	uniform float tertiary_border_distance_cutoff : hint_range(0.0, 1.0) = 0.0;
	uniform float tertiary_border_softness : hint_range(0.0, 1.0) = 0.0;
	uniform bool tertiary_use_own_border = false;
	uniform float tertiary_shift_x = 0.0;
	uniform float tertiary_shift_y = 0.0;
	uniform float tertiary_scale_x = 1.0;
	uniform float tertiary_scale_y = 1.0;

float shift_scale_and_mirror_gradient(float canvas_value, float margin, float shift, float scale) {
	canvas_value -= shift;
	float pin = 0.5;
	canvas_value -= pin;
	canvas_value /= scale;
	canvas_value += pin;
	if (canvas_value > margin) { canvas_value = 1.0 - canvas_value; }
	canvas_value /= margin;
	canvas_value = clamp(canvas_value, 0.0, 1.0);
	return canvas_value;
}

vec2 shift_scale_and_mirror_vec2(vec2 canvas, vec2 margin, vec2 shift, vec2 scale) {
	canvas.x = shift_scale_and_mirror_gradient(canvas.x, margin.x, shift.x, scale.x);
	canvas.y = shift_scale_and_mirror_gradient(canvas.y, margin.y, shift.y, scale.y);
	canvas = clamp(vec2(1.0 - length(canvas - vec2(1.0))), 0.0, 1.0);
	return canvas;
}

vec4 layering(vec4 bottom_layer, vec4 top_layer, float top_opacity) {
	return bottom_layer * (1.0 - top_opacity) + vec4(top_layer.r, top_layer.g, top_layer.b, bottom_layer.a) * top_opacity;
}

// <foreign-functions> These two functions were gotten from elsewhere, I am not familiar with them
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
// </foreign-functions>

vec4 hsv_combine(vec4 red, vec4 col, bool apply_to_value) {
	vec3 red_hsv = rgb2hsv(red.rgb);
	vec3 col_hsv = rgb2hsv(col.rgb);
	col_hsv.x += red_hsv.r;
	col_hsv.y *= red_hsv.y;
	if (apply_to_value) { col_hsv.z *= red_hsv.z; }
	else { col_hsv.z = red_hsv.z; }
	return vec4(hsv2rgb(col_hsv), red.a * col.a);
}

vec4 inversion(vec4 input) {
	vec3 hsv = rgb2hsv(input.rgb);
	hsv.z = 1.0 - hsv.z;
	return vec4(hsv2rgb(hsv), input.a);
}


// MAIN
void fragment() {
	float aspect = node_size.x / node_size.y;

	// Transform main UV (just mirroring it horizontally & vertically)
	vec2 st = shift_scale_and_mirror_vec2(UV, vec2(x_roundness / aspect, y_roundness),
			vec2(0.0), vec2(1.0));

	// Apply the edge gradient by mapping to the mirrored UV
	vec4 gradient = textureLod(edge, st, 0.0);
	gradient = hsv_combine(gradient, color, true);
	if (invert) { gradient = inversion(gradient); }

	// Apply the primary if applicable
	if (use_primary) {
		vec4 primary_color_shifted = hsv_combine(primary_color, color, primary_alter_hsv_value);
		if (invert && primary_alter_hsv_value) { primary_color_shifted = inversion(primary_color_shifted); }
		vec2 primary = shift_scale_and_mirror_vec2(UV, vec2(primary_x_roundness / aspect, primary_y_roundness),
				vec2(primary_shift_x, primary_shift_y), vec2(primary_scale_x, primary_scale_y));
		float value = smoothstep(0.0, primary_falloff, primary.x); // My old note for this is literally "???", so dunno what this is doing atm
		if (primary_use_own_border) {
			primary_color_shifted.a*= smoothstep(primary_border_distance_cutoff, primary_border_distance_cutoff + primary_border_softness, primary.x);
		} else {
			primary_color_shifted.a*= smoothstep(primary_border_distance_cutoff, primary_border_distance_cutoff + primary_border_softness, st.x);
		}
		gradient = layering(gradient, primary_color_shifted, value * primary_color_shifted.a);
	}

	// Apply the secondary if applicable
	if (use_secondary) {
		vec4 secondary_color_shifted = hsv_combine(secondary_color, color, secondary_alter_hsv_value);
		if (invert && secondary_alter_hsv_value) { secondary_color_shifted = inversion(secondary_color_shifted); }
		vec2 secondary = shift_scale_and_mirror_vec2(UV, vec2(secondary_x_roundness / aspect, secondary_y_roundness),
				vec2(secondary_shift_x, secondary_shift_y), vec2(secondary_scale_x, secondary_scale_y));
		float value = smoothstep(0.0, secondary_falloff, secondary.x); // My old note for this is literally "???", so dunno what this is doing atm
		if (secondary_use_own_border) {
			secondary_color_shifted.a*= smoothstep(secondary_border_distance_cutoff, secondary_border_distance_cutoff + secondary_border_softness, secondary.x);
		} else {
			secondary_color_shifted.a*= smoothstep(secondary_border_distance_cutoff, secondary_border_distance_cutoff + secondary_border_softness, st.x);
		}
		gradient = layering(gradient, secondary_color_shifted, value * secondary_color_shifted.a);
	}

	// Apply the tertiary if applicable
	if (use_tertiary) {
		vec4 tertiary_color_shifted = hsv_combine(tertiary_color, color, tertiary_alter_hsv_value);
		if (invert && tertiary_alter_hsv_value) { tertiary_color_shifted = inversion(tertiary_color_shifted); }
		vec2 tertiary = shift_scale_and_mirror_vec2(UV, vec2(tertiary_x_roundness / aspect, tertiary_y_roundness),
				vec2(tertiary_shift_x, tertiary_shift_y), vec2(tertiary_scale_x, tertiary_scale_y));
		float value = smoothstep(0.0, tertiary_falloff, tertiary.x); // My old note for this is literally "???", so dunno what this is doing atm
		if (tertiary_use_own_border) {
			tertiary_color_shifted.a*= smoothstep(tertiary_border_distance_cutoff, tertiary_border_distance_cutoff + tertiary_border_softness, tertiary.x);
		} else {
			tertiary_color_shifted.a*= smoothstep(tertiary_border_distance_cutoff, tertiary_border_distance_cutoff + tertiary_border_softness, st.x);
		}
		gradient = layering(gradient, tertiary_color_shifted, value * tertiary_color_shifted.a);
	}

	COLOR = gradient;
}
