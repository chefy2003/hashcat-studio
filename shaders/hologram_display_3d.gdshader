shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D screen_viewport_texture : source_color, filter_linear_mipmap;
uniform vec4 holo_tint : source_color = vec4(0.0, 0.94, 1.0, 1.0); // Neon Cyan #00f0ff
uniform float tint_mix : hint_range(0.0, 1.0) = 0.12;
uniform float scanline_frequency : hint_range(50.0, 800.0) = 280.0;
uniform float scanline_speed : hint_range(0.0, 5.0) = 0.8;
uniform float scanline_intensity : hint_range(0.0, 0.5) = 0.12;
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.5;
uniform float fresnel_intensity : hint_range(0.0, 2.0) = 0.7;
uniform float curvature : hint_range(0.0, 0.2) = 0.03;
uniform float alpha_boost : hint_range(0.0, 1.0) = 0.96;

vec2 curve_uv(vec2 uv) {
	vec2 centered = uv - 0.5;
	float dist = dot(centered, centered);
	return uv + centered * dist * curvature;
}

void fragment() {
	vec2 uv = curve_uv(UV);
	
	// Boundary check for subtle CRT/Curved bulge
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		discard;
	}

	vec4 tex = texture(screen_viewport_texture, uv);

	// Subtle animated horizontal scanlines
	float scanline = sin((uv.y + TIME * scanline_speed * 0.02) * scanline_frequency) * 0.5 + 0.5;
	float scanline_factor = 1.0 - (scanline * scanline_intensity);

	// Fresnel rim glow
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power) * fresnel_intensity;

	// Tinting & color blending
	vec3 col = mix(tex.rgb, holo_tint.rgb, tint_mix);
	col *= scanline_factor;
	col += holo_tint.rgb * fresnel;

	ALBEDO = col;
	ALPHA = clamp(tex.a * alpha_boost + fresnel * 0.4, 0.0, 1.0);
}
