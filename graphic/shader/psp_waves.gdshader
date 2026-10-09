shader_type canvas_item;

float wave(vec2 uv, float inv_size, float period, float inv_amplitude, float x_offset, float y_offset, float flip, float speed, float time){
    float wv = ((uv.y - y_offset) * inv_size) - (sin(((x_offset + uv.x) / period) + (speed * time)) / inv_amplitude);
    if (abs(wv) > 0.6){
        wv = 0.0;
    }
    return flip * wv;
}

uniform vec4 kolor : source_color = vec4(1.0);

void fragment() {
    // Normalized pixel coordinates (from 0 to 1)
	//vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 uv = UV;

    // Background color
    float col = ((uv.x + uv.y) / 3.0);

    // Waves
    col += clamp(wave(uv, 4.0, 1.0, 3.0, 0.0, 0.4, 1.0, -0.1, TIME), 0.0, 0.4);
    col += clamp(wave(uv, 4.0, 0.4, 1.0, 0.0, 0.5, 1.0, 0.1, TIME), 0.0, 0.4);
    col += clamp(wave(uv, 4.0, 0.2, 6.0, 3.0, 0.3, -1.0, 0.13, TIME), 0.0, 0.4);
    col += clamp(wave(uv, 4.0, 0.15, 7.0, 4.0, 0.4, -1.0, -0.18, TIME), 0.0, 0.4);

    // Output to screen
    COLOR = vec4(kolor.rgb, kolor.a * col);
}
