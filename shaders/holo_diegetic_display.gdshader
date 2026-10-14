shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque, cull_back;

// Crystal-Clear Tactical Console Display Shader
// Eliminates all foggy wash/smoke: renders pure, ultra-crisp UI text and controls
// with inky OLED contrast and a razor-sharp micro-bezel border.

uniform sampler2D terminal_texture : hint_default_black, filter_linear;

group_uniforms TerminalLook;
uniform vec4 border_color : source_color = vec4(0.0, 0.94, 1.0, 1.0);
uniform float border_thickness : hint_range(0.001, 0.02) = 0.004;
uniform float brightness_boost : hint_range(1.0, 2.5) = 1.15;

void fragment() {
	vec2 uv = UV;
	vec4 term_color = texture(terminal_texture, uv);

	// Inky dark background backing (true OLED contrast)
	vec3 oled_bg = vec3(0.015, 0.022, 0.035);

	// Razor-sharp bounding bezel frame
	vec2 edge_dist = min(uv, 1.0 - uv);
	float min_dist = min(edge_dist.x, edge_dist.y);
	float frame_line = 1.0 - smoothstep(0.0, border_thickness, min_dist);
	vec3 frame_rgb = border_color.rgb * frame_line * 2.0;

	// Composite pure crisp UI text and graphics
	vec3 final_rgb = mix(oled_bg, term_color.rgb * brightness_boost, term_color.a) + frame_rgb;

	ALBEDO = final_rgb;
	ALPHA = 1.0;
}
