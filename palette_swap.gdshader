shader_type canvas_item;

uniform sampler2D palette;
uniform sampler2D swap;
uniform int color_count;


uniform float darkness : hint_range(0.0, 1.0) = 0.0;          
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0; 
uniform float glitch_speed = 20.0;                          

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 shifted_uv = UV;

    if (glitch_intensity > 0.0) {
        float time_step = floor(TIME * glitch_speed);
        float glitch_line = step(1.0 - (glitch_intensity * 0.4), rand(vec2(time_step, floor(shifted_uv.y * 32.0))));
        
        if (glitch_line > 0.0) {
            shifted_uv.x += (rand(vec2(time_step, shifted_uv.x)) - 0.5) * 0.08 * glitch_intensity;
        }
    }

    vec4 current_pixel = texture(TEXTURE, shifted_uv);
    vec4 final_color = current_pixel;


    for (int i = 0; i < color_count; i++) {
        float u = (float(i) + 0.5) / float(color_count);
        float v = 0.5;
        vec2 uv = vec2(u, v);
        
        if (distance(current_pixel, texture(palette, uv)) <= 0.1) {
            final_color = texture(swap, uv);
            break;
        }
    }

    final_color.rgb = mix(final_color.rgb, vec3(0.0), darkness);


    if (glitch_intensity > 0.6 && rand(vec2(floor(TIME * 5.0), 1.0)) > 0.92) {
        final_color.rgb += vec3(0.15, 0.0, 0.1) * glitch_intensity;
    }

    COLOR = final_color;
}