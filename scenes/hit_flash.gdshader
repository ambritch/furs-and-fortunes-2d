shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    // Mix original sprite colors with white, keeping the sprite alpha intact
    vec3 mixed_color = mix(texture_color.rgb, flash_color.rgb, flash_amount);
    COLOR = vec4(mixed_color, texture_color.a);
}
