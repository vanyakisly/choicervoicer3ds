shader_type canvas_item;

uniform float shift_amount = 0.0;

void vertex() {
	VERTEX.x += shift_amount;
}