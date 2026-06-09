shader_type canvas_item;

uniform float speed: hint_range(0.0, 50.0, 0.1) = 10.0;
uniform vec4 color: source_color = vec4(1.0, 1.0, 1.0, 0.0);

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	COLOR.rgb += color.rgb * vec3((cos(TIME * speed) + 1.0) * 0.5);
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
