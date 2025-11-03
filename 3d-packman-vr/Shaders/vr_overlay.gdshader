shader_type canvas_item;

// Read what's already rendered this frame
uniform sampler2D screen_tex : hint_screen_texture, filter_linear, repeat_disable;

// Optional tweaks
uniform float gap : hint_range(0.0, 0.2) = 0.0; // central gap in normalized width (0 = none)
uniform bool  mirror_each = false;              // flip each half if you want

void fragment() {
    bool left = (UV.x < 0.5);

    // Map current pixel to [0..1] inside its half (accounting for optional gap near center)
    float half_start = left ? 0.0 : 0.5;
    float half_end   = left ? (0.5 - gap*0.5) : 1.0;
    float u = (UV.x - half_start) / (half_end - half_start);
    vec2 half_uv = vec2(u, UV.y);

    vec2 src_uv = half_uv;
    if (mirror_each) src_uv.x = 1.0 - src_uv.x;

    // Sample the full screen so each half shows the whole frame
    vec4 c = texture(screen_tex, src_uv);

    // Outside becomes black (when gap > 0)
    if (UV.x > (0.5 - gap*0.5) && UV.x < (0.5 + gap*0.5)) c = vec4(0.0);

    COLOR = c;
}