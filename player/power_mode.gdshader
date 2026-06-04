shader_type canvas_item;

uniform sampler2D channel0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 red_displacement = fract(UV.xy + vec2(TIME * 0.01, 0.0));
	float red_derived = texture(channel0, fract(UV.xy + red_displacement)).x;
	vec2 blue_displacement = fract(UV.xy + vec2(0.0, TIME * 0.01));
	float blue_derived = texture(channel0, fract(UV.xy + blue_displacement)).x;
	
	
	COLOR.r = texture(channel0, fract(UV.xy + vec2(red_derived, red_derived) * 0.1)).x;
	COLOR.b = texture(channel0, UV.xy + vec2(blue_derived, blue_derived)).x;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
