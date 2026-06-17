shader_type canvas_item;

uniform sampler2D palette;
uniform sampler2D swap;
uniform int color_count;

uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.5;
uniform float TIME_SCALE : hint_range(0.0, 10.0) = 1.0;

uniform float block_size_pixels = 16.0;
uniform float max_glitch_distance_blocks = 1000.0;
uniform float safe_zone_radius_blocks = 0.0;
uniform float glitch_growth_rate : hint_range(0.1, 10.0) = 4.0;

varying vec2 world_position;

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
}

void fragment() {
    float object_dist_pixels = distance(world_position, vec2(0.0, 0.0));
    float object_dist_blocks = object_dist_pixels / block_size_pixels;
    
    float distance_factor = smoothstep(safe_zone_radius_blocks, max_glitch_distance_blocks, object_dist_blocks);
    distance_factor = pow(distance_factor, glitch_growth_rate);
    
    float effect_strength = distance_factor * glitch_intensity;
    
    float stepped_time = floor(TIME * TIME_SCALE * 10.0);
    vec2 distorted_uv = UV;
    
    if (effect_strength > 0.0) {
        float slice_y = floor(UV.y * 16.0); 
        float line_noise = random(vec2(slice_y, stepped_time));
        
        if (line_noise < 0.2 * effect_strength) {
            float displacement = (random(vec2(stepped_time)) - 0.5) * 0.15 * effect_strength;
            distorted_uv.x += displacement;
            distorted_uv.x = clamp(distorted_uv.x, 0.001, 0.999);
        }
    }
    
    vec4 current_color = texture(TEXTURE, distorted_uv);
    
    if (effect_strength > 0.01) {
        float r_offset = 0.03 * effect_strength * sin(stepped_time);
        vec2 r_uv = vec2(clamp(distorted_uv.x + r_offset, 0.001, 0.999), distorted_uv.y);
        vec2 b_uv = vec2(clamp(distorted_uv.x - r_offset, 0.001, 0.999), distorted_uv.y);
        
        current_color.r = texture(TEXTURE, r_uv).r;
        current_color.b = texture(TEXTURE, b_uv).b;
    }

    bool matched = false;
    for (int i = 0; i < color_count; i++) {
        float u = (float(i) + 0.5) / float(color_count);
        float v = 0.5;
        vec2 pal_uv = vec2(u, v);
        
        if (distance(current_color, texture(palette, pal_uv)) <= 0.1) {
            COLOR = texture(swap, pal_uv);
            matched = true;
            break;
        }
    }
    
    if (!matched) {
        COLOR = current_color;
    }
}