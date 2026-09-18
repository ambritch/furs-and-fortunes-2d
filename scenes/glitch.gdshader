shader_type canvas_item;

uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    
    if (glitch_intensity > 0.0) {
        // Horizontal offset slicing
        float slice = floor(uv.y * 20.0);
        float offset = (random(vec2(slice, TIME)) - 0.5) * 0.1 * glitch_intensity;
        uv.x += offset;
        
        // RGB Color Splitting
        vec4 red = texture(TEXTURE, uv + vec2(0.01 * glitch_intensity, 0.0));
        vec4 green = texture(TEXTURE, uv);
        vec4 blue = texture(TEXTURE, uv - vec2(0.01 * glitch_intensity, 0.0));
        
        COLOR = vec4(red.r, green.g, blue.b, green.a);
    } else {
        COLOR = texture(TEXTURE, uv);
    }
}