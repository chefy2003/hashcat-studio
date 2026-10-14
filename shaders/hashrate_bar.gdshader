shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// AAA Tactical Frequency Wave Bar Shader
// Acrylic translucent telemetry column with internal thermal luminescence and specular sheen.

uniform vec4 color_bottom : source_color = vec4(0.0, 0.55, 1.0, 1.0);  // Precision Cyan/Blue
uniform vec4 color_mid : source_color = vec4(0.062, 0.85, 0.58, 1.0);   // Cyber Emerald
uniform vec4 color_peak : source_color = vec4(1.0, 0.22, 0.35, 1.0);   // Ruby Core Peak

uniform float emission_energy : hint_range(0.5, 4.0) = 1.6;
uniform float max_spectrum_height : hint_range(0.5, 3.0) = 1.35;
uniform float peak_split : hint_range(0.2, 0.8) = 0.45;

varying float v_norm_height;

void vertex() {
	float height_above_base = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - NODE_POSITION_WORLD.y;
	v_norm_height = clamp(height_above_base / max_spectrum_height, 0.0, 1.0);
}

void fragment() {
	vec3 bar_color;
	if (v_norm_height < peak_split) {
		float t = v_norm_height / peak_split;
		bar_color = mix(color_bottom.rgb, color_mid.rgb, smoothstep(0.0, 1.0, t));
	} else {
		float t = (v_norm_height - peak_split) / (1.0 - peak_split);
		bar_color = mix(color_mid.rgb, color_peak.rgb, smoothstep(0.0, 1.0, t));
	}

	ALBEDO = bar_color * 0.45 + vec3(0.015, 0.025, 0.035);
	ROUGHNESS = 0.12;
	METALLIC = 0.35;
	SPECULAR = 0.92;
	EMISSION = bar_color * emission_energy;
}
