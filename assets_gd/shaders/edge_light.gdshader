shader_type spatial;

uniform sampler2D albedo_texture : source_color;
uniform int edge_size=5;
uniform vec2 pixel_size;

void fragment() {
	vec4 image=texture(albedo_texture,UV);
	
	bool is_near_transparency=true;
	for (int x=-edge_size;x<edge_size;x++){
		for (int y=-edge_size;y<edge_size;y++){
			if (texture(albedo_texture,UV+pixel_size*vec2(float(x),float(y))).a > 0.05){
				is_near_transparency=true;
				break;
			}
		}
		if(is_near_transparency){break;}
	}
	
	
	if (is_near_transparency) {
		ALBEDO = texture(albedo_texture, UV).rgb;
	} else {
		ALBEDO = vec3(0.0, 0.0, 0.0);
	}
	ALPHA=texture(albedo_texture,UV).a;
}