shader_type canvas_item;

uniform sampler2D palette;
uniform sampler2D swap;
uniform int color_count;

void fragment() {
	for (int i = 0; i < color_count; i++) {
		float u = (float(i) + 0.5) / float(color_count);
		float v = 0.5;
		vec2 uv = vec2(u, v);
		
		if (distance(texture(TEXTURE, UV), texture(palette, uv)) <= 0.1) {
			COLOR = texture(swap, uv);
			//COLOR = vec4(1.0, 0.0, 0.0, 1.0);
			break;
		}
	}
	//COLOR = texture(TEXTURE, UV);
	// Called for every pixel the material is visible on.
}
