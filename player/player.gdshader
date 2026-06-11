shader_type canvas_item;

uniform vec4 base_color: source_color;
uniform vec4 gradient_color: source_color;


void fragment() {
	COLOR.rgb = mix(base_color.rgb, gradient_color.rgb, SCREEN_UV.x * 0.5 / SCREEN_UV.y);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
