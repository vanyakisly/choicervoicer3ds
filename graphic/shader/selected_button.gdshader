shader_type canvas_item;

uniform vec2 node_size = vec2(1.0, 1.0);
uniform float x_margin : hint_range(0.0, 0.5) = 0.25;
uniform float y_margin : hint_range(0.0, 0.5) = 0.25;
uniform float margin_percent : hint_range(0.0, 1.0) = .5;
uniform vec3 color : source_color = vec3(1.0, 0.0, 0.0);


void fragment() {
	float aspect = node_size.x / node_size.y;
	float xa_margin = x_margin / aspect;
	vec2 st = UV;
	
	
	if (st.x > .5) {
		st.x = 1.0 - st.x;
	}
	if (st.y > .5) {
		st.y = 1.0 - st.y;
	}
	
	float value = 0.0;
	
	if ((st.x > xa_margin * margin_percent && st.y < y_margin * margin_percent) && st.x < xa_margin) {
		value = 1.0;
	}
	else if ((st.x < xa_margin * margin_percent && st.y > y_margin * margin_percent) && st.y < y_margin) {
		value = 1.0;
	}
	else if (st.x < xa_margin * margin_percent && st.y < y_margin * margin_percent) {
		value = 1.0;
	}
	
	COLOR = vec4(color, value);
}